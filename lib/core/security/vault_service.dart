import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../database/app_database.dart';
import '../exceptions/vault_unlock_exception.dart';
import '../sync/crdt_device_id_store.dart';
import '../sync/crdt_ffi.dart';
import '../sync/mutex.dart';
import '../sync/pending_delta_store.dart';
import '../sync/vault_crdt.dart';
import '../sync/vault_doc_store.dart';
import '../sync/vault_seed.dart';
import 'biometric_storage_service.dart';
import 'key_derivator.dart';
import 'salt_manager.dart';
import 'vault_key_crypto.dart';
import 'vault_migrator.dart';
import 'wrapped_vault_key_store.dart';

/// Issue d'une récupération de coffre depuis le backup serveur.
enum RecoverVaultResult {
  /// Coffre récupéré et installé.
  success,

  /// Le mot de passe maître ne désenrobe pas la clé sauvegardée.
  wrongMasterPassword,

  /// Un coffre existe déjà sur cet appareil : rien n'a été touché.
  vaultAlreadyExists,

  /// Échec technique (installation).
  failure,
}

/// Issue d'un changement de mot de passe maître.
enum ChangePasswordResult {
  /// Mot de passe changé, base re-chiffrée.
  success,

  /// Coffre verrouillé : impossible de changer le mot de passe.
  vaultLocked,

  /// L'ancien mot de passe fourni est incorrect.
  wrongCurrentPassword,

  /// Échec technique du re-chiffrement (la base reste sous l'ancienne clé).
  failure,
}

class VaultService {
  /// Constructeur **génératif** (sous-classable pour les tests). Les défauts sont
  /// des `const` canoniques : les expressions répétées désignent la même instance,
  /// et le migrateur partage donc le même chiffreur/store que les champs.
  VaultService({
    VaultKeyCrypto? vaultKeyCrypto,
    WrappedVaultKeyStore? wrappedKeyStore,
    BiometricStorageService? biometricService,
    CrdtFfi? crdtFfi,
    CrdtDeviceIdStore? crdtDeviceIdStore,
  }) : _vaultKeyCrypto = vaultKeyCrypto ?? const FrbVaultKeyCrypto(),
       _wrappedKeyStore =
           wrappedKeyStore ??
           const SecureWrappedVaultKeyStore(FlutterSecureStorage()),
       _biometricService = biometricService ?? BiometricStorageService(),
       _crdtFfi = crdtFfi ?? const FrbCrdtFfi(),
       _crdtDeviceIdStore =
           crdtDeviceIdStore ??
           const SecureCrdtDeviceIdStore(FlutterSecureStorage()),
       _migrator = VaultMigrator(
         vaultKeyCrypto ?? const FrbVaultKeyCrypto(),
         wrappedKeyStore ??
             const SecureWrappedVaultKeyStore(FlutterSecureStorage()),
       );

  AppDatabase? _database;
  // Clé qui a ouvert la session courante (la VaultKey une fois le coffre migré).
  List<int>? _currentKey;
  final VaultKeyCrypto _vaultKeyCrypto;
  final WrappedVaultKeyStore _wrappedKeyStore;
  final BiometricStorageService _biometricService;
  final VaultMigrator _migrator;
  final CrdtFfi _crdtFfi;
  final CrdtDeviceIdStore _crdtDeviceIdStore;
  // Session CRDT de la session courante (write-through de la synchro). Construite
  // paresseusement à la première écriture, remise à zéro à la fermeture.
  VaultCrdt? _vaultCrdt;
  // Verrou partagé (par session) sérialisant les RMW du doc CRDT entre les
  // écritures locales (VaultCrdt) et le moteur de sync (SyncEngine).
  Mutex? _docLock;

  /// Verrou du doc CRDT de la session courante (à passer au `SyncEngine` pour
  /// sérialiser tirages et écritures locales). `null` si aucune session.
  Mutex? get docLock => _docLock;
  // Notifié après chaque mutation locale du coffre (via le write-through CRDT) :
  // permet à la couche de synchro de déclencher un push sans coupler le chemin
  // d'écriture au moteur de sync.
  final _LocalMutations _mutations = _LocalMutations();

  /// S'abonner pour être notifié après chaque écriture locale (push réactif).
  Listenable get onLocalMutation => _mutations;

  /// Ouverture initiale ou manuelle avec le mot de passe maître. Migre le coffre
  /// vers le modèle VaultKey au premier déverrouillage (cf. [VaultMigrator]).
  Future<void> unlockWithMasterPassword(String masterPassword) async {
    try {
      final files = await VaultFiles.resolve();
      await _migrator.heal(files);

      final salt = await SaltManager.getOrGenerateSalt();
      final kek = await _deriveKeyBytes(masterPassword, salt);

      final wrapped = await _wrappedKeyStore.read();
      if (wrapped == null) {
        // Coffre v1 non migré : la KEK est encore la clé du coffre.
        await openDatabaseWithKey(kek);
        final vaultKey = await _migrator.migrate(
          kek,
          DriftMigrationDb(_database!),
          files,
        );
        _currentKey = List<int>.unmodifiable(vaultKey);
        await _persistKeyForBiometricsIfEnabled(vaultKey);
      } else {
        // Coffre migré : désenrober la VaultKey (échoue si mot de passe faux).
        final vaultKey = _vaultKeyCrypto.unwrap(kek, wrapped);
        await openDatabaseWithKey(vaultKey);
        await _persistKeyForBiometricsIfEnabled(vaultKey);
      }
    } catch (e) {
      if (e is VaultUnlockException) rethrow;
      throw VaultUnlockException(e);
    }
  }

  /// Stocke (ou efface) la clé de déverrouillage rapide selon la préférence de
  /// l'utilisateur. Non critique : toute erreur est ignorée pour ne pas
  /// compromettre un déverrouillage par ailleurs réussi.
  Future<void> _persistKeyForBiometricsIfEnabled(List<int> keyBytes) async {
    try {
      if (await _biometricService.isBiometricEnabled()) {
        await _biometricService.saveDerivedKey(keyBytes);
      } else {
        await _biometricService.clearDerivedKey();
      }
    } catch (_) {
      // Persistance biométrique non critique : on ignore les échecs.
    }
  }

  /// Ouverture rapide via biométrie. Retourne l'issue précise pour que
  /// l'appelant distingue un échec réel d'une annulation / indisponibilité.
  Future<BiometricUnlockStatus> unlockWithBiometrics() async {
    final files = await VaultFiles.resolve();
    await _migrator.heal(files);

    final (status, keyBytes) = await _biometricService
        .getDerivedKeyWithBiometrics("Déverrouillez Realm Guard");

    if (status != BiometricUnlockStatus.success || keyBytes == null) {
      return status;
    }

    try {
      final wrapped = await _wrappedKeyStore.read();
      if (wrapped == null) {
        // Cache pré-migration = KEK = clé du coffre v1 : ouvrir puis migrer.
        await openDatabaseWithKey(keyBytes);
        final vaultKey = await _migrator.migrate(
          keyBytes,
          DriftMigrationDb(_database!),
          files,
        );
        _currentKey = List<int>.unmodifiable(vaultKey);
        await _persistKeyForBiometricsIfEnabled(vaultKey);
      } else {
        // Cache post-migration = VaultKey = clé du coffre.
        await openDatabaseWithKey(keyBytes);
      }
      return BiometricUnlockStatus.success;
    } catch (_) {
      return BiometricUnlockStatus.failed; // Demande le mot de passe
    }
  }

  /// Installe une **VaultKey reçue par pairing** sur ce nouvel appareil : protège la
  /// clé au repos sous une KEK dérivée d'un **secret local** ([localPassword], propre
  /// à cet appareil — ce n'est pas le mot de passe maître du compte), puis crée le
  /// coffre chiffré avec elle.
  ///
  /// **Ordre critique** : la wrapped-VK est écrite **avant** la création de la base.
  /// Un crash entre les deux laisse la VaultKey **récupérable** (au prochain
  /// lancement, le mot de passe local la désenrobe et la base est créée). L'ordre
  /// inverse perdrait définitivement la clé du coffre.
  ///
  /// **Refuse d'écraser un coffre existant** (wrapped-VK ou fichier de base présent).
  Future<void> installPairedVaultKey({
    required List<int> vaultKey,
    required String localPassword,
  }) async {
    try {
      final files = await VaultFiles.resolve();
      if (await _wrappedKeyStore.read() != null || await files.vaultExists()) {
        throw StateError('Un coffre existe déjà sur cet appareil.');
      }

      final salt = await SaltManager.getOrGenerateSalt();
      final kek = await _deriveKeyBytes(localPassword, salt);

      // 1. Durabiliser d'abord : la VaultKey doit rester récupérable en cas de crash.
      await _wrappedKeyStore.write(_vaultKeyCrypto.wrap(kek, vaultKey));

      // 2. Créer le coffre chiffré avec la VaultKey reçue.
      await openDatabaseWithKey(vaultKey);

      // 3. Cache biométrique (best-effort, selon la préférence utilisateur).
      await _persistKeyForBiometricsIfEnabled(vaultKey);
    } catch (e) {
      if (e is VaultUnlockException) rethrow;
      throw VaultUnlockException(e);
    }
  }

  /// Récupère le coffre depuis le **backup serveur**, sur un appareil sans autre
  /// appareil disponible.
  ///
  /// [wrappedVaultKey] est la VaultKey enrobée par la KEK d'origine, et [backupSalt]
  /// le sel qui a servi à la dériver. Ce sel est **transitoire** : il ne sert qu'à
  /// redériver la KEK pour désenrober. Une fois la VaultKey en main, l'installation
  /// locale repart sur un sel neuf — seule la VaultKey doit être conservée à
  /// l'identique.
  ///
  /// Réutilise [installPairedVaultKey] : même ordre critique (wrapped-VK écrite avant
  /// la base) et même garde-fou anti-écrasement.
  Future<RecoverVaultResult> recoverVaultFromBackup({
    required Uint8List wrappedVaultKey,
    required Uint8List backupSalt,
    required String masterPassword,
  }) async {
    final List<int> vaultKey;
    try {
      // Sel du **backup**, pas le sel local : c'est la seule KEK qui ouvre ce blob.
      final kek = await _deriveKeyBytes(masterPassword, backupSalt);
      vaultKey = _vaultKeyCrypto.unwrap(kek, wrappedVaultKey);
    } catch (_) {
      // L'AEAD ne distingue pas « mauvais mot de passe » de « blob altéré » : côté
      // utilisateur, la cause plausible est le mot de passe maître.
      return RecoverVaultResult.wrongMasterPassword;
    }

    try {
      await installPairedVaultKey(
        vaultKey: vaultKey,
        localPassword: masterPassword,
      );
      return RecoverVaultResult.success;
    } catch (e) {
      if (e is VaultUnlockException && e.cause is StateError) {
        return RecoverVaultResult.vaultAlreadyExists;
      }
      return RecoverVaultResult.failure;
    }
  }

  Future<void> openDatabaseWithKey(List<int> keyBytes) async {
    try {
      _database = AppDatabase(keyBytes);
      await _database!.customSelect('SELECT 1').get();
      _currentKey = List<int>.unmodifiable(keyBytes);
    } catch (e) {
      _database?.close();
      _database = null;
      _currentKey = null;
      throw VaultUnlockException(e);
    }
  }

  /// Change le mot de passe maître en **ré-enrobant la VaultKey** sous la nouvelle
  /// KEK. La clé du coffre ne change pas → aucun re-chiffrement de la base, le cache
  /// biométrique reste valide, et un futur appareil pairé n'est pas affecté.
  ///
  /// Le coffre doit être déverrouillé. L'[currentPassword] est vérifié en tentant
  /// de désenrober la VaultKey stockée.
  Future<ChangePasswordResult> changeMasterPassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (_database == null || _currentKey == null) {
      return ChangePasswordResult.vaultLocked;
    }

    try {
      final wrapped = await _wrappedKeyStore.read();
      if (wrapped == null) return ChangePasswordResult.failure;

      final salt = await SaltManager.getOrGenerateSalt();

      // Vérifie l'ancien mot de passe : sa KEK doit désenrober la VaultKey stockée.
      final currentKek = await _deriveKeyBytes(currentPassword, salt);
      final List<int> vaultKey;
      try {
        vaultKey = _vaultKeyCrypto.unwrap(currentKek, wrapped);
      } catch (_) {
        return ChangePasswordResult.wrongCurrentPassword;
      }

      // Ré-enrobe la VaultKey sous la nouvelle KEK (même sel : non secret).
      final newKek = await _deriveKeyBytes(newPassword, salt);
      await _wrappedKeyStore.write(_vaultKeyCrypto.wrap(newKek, vaultKey));

      return ChangePasswordResult.success;
    } catch (_) {
      return ChangePasswordResult.failure;
    }
  }

  Future<List<int>> _deriveKeyBytes(String password, Uint8List salt) async {
    final secretKey = await KeyDerivator.deriveKeyFromPassword(password, salt);
    return secretKey.extractBytes();
  }

  /// Ferme la base et oublie la clé en mémoire. **Attendable** : à utiliser
  /// avant toute suppression des fichiers du coffre, pour garantir que la
  /// connexion SQLCipher est totalement fermée (aucun fragment -wal/-shm laissé
  /// par un checkpoint concurrent).
  Future<void> closeVault() async {
    final db = _database;
    _database = null;
    _currentKey = null;
    _vaultCrdt = null;
    _docLock = null;
    await db?.close();
  }

  /// Session CRDT de la session courante (write-through de la synchronisation),
  /// construite **paresseusement** au premier accès et mise en cache. Sème le doc
  /// depuis les lignes existantes s'il n'existe pas encore (migration v1 → doc).
  ///
  /// **Best-effort et non fatal** : le doc CRDT est un artefact *fantôme* (les
  /// lectures restent servies par drift). Tout échec — y compris un coffre
  /// verrouillé — renvoie `null` sans perturber le coffre ; on réessaie à la
  /// prochaine écriture / au prochain déverrouillage.
  Future<VaultCrdt?> ensureCrdtSession() async {
    if (_vaultCrdt != null) return _vaultCrdt;
    final db = _database;
    final key = _currentKey;
    if (db == null || key == null) return null;
    try {
      final store = DriftVaultDocStore(db);
      final lock = _docLock ??= Mutex();
      final crdt = VaultCrdt(
        ffi: _crdtFfi,
        store: store,
        pending: DriftPendingDeltaStore(db),
        vaultKey: Uint8List.fromList(key),
        deviceId: await _crdtDeviceIdStore.getOrCreate(),
        onChanged: _mutations.ping,
        lock: lock,
        // Sauvegarde du doc + enfilement des deltas dans une même transaction.
        transaction: (action) => db.transaction(action),
      );
      await _seedCrdtIfNeeded(db, store, crdt);
      _vaultCrdt = crdt;
      return crdt;
    } catch (_) {
      return null;
    }
  }

  /// Sème le doc CRDT depuis les lignes drift existantes, une seule fois (si le
  /// doc n'existe pas encore et que le coffre n'est pas vide).
  Future<void> _seedCrdtIfNeeded(
    AppDatabase db,
    VaultDocStore store,
    VaultCrdt crdt,
  ) async {
    if (await store.load() != null) return;
    final profiles = await db.select(db.profiles).get();
    final credentials = await db.select(db.credentials).get();
    final totps = await db.select(db.totps).get();
    if (profiles.isEmpty && credentials.isEmpty && totps.isEmpty) return;
    await crdt.seed(
      buildSeedEntries(
        profiles: profiles,
        credentials: credentials,
        totps: totps,
      ),
    );
  }

  /// Verrouille activement le coffre. Fermeture best-effort non bloquante :
  /// l'état « verrouillé » ([isUnlocked] == false) est effectif immédiatement.
  void lockVault() {
    unawaited(closeVault());
  }

  /// Indique si le coffre est actuellement déverrouillé (DB ouverte en mémoire).
  bool get isUnlocked => _database != null;

  /// La **VaultKey** de la session courante (clé racine du coffre), exposée pour le
  /// pairing d'appareil (l'appareil source la scelle vers le nouvel appareil).
  /// `null` si le coffre est verrouillé.
  List<int>? get vaultKey => _currentKey;

  AppDatabase get db {
    if (_database == null) throw Exception("Vault is locked!");
    return _database!;
  }
}

/// Notifie ses abonnés à chaque mutation locale du coffre. Expose [ping] car
/// `notifyListeners` est protégé.
class _LocalMutations extends ChangeNotifier {
  void ping() => notifyListeners();
}
