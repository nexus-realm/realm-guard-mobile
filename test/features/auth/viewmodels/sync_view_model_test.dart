import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:realmguard/features/auth/data/auth_exception.dart';
import 'package:realmguard/features/auth/viewmodels/sync_view_model.dart';

import '../../../support/auth_test_doubles.dart';

void main() {
  /// Construit le VM avec un backup qui réussit (coffre présent) par défaut.
  ({SyncViewModel vm, List<Uint8List> backedUp}) build(
    FakeAuthService auth, {
    bool vaultExists = true,
  }) {
    final backedUp = <Uint8List>[];
    final vm = SyncViewModel(
      authService: auth,
      backupVaultKey: (exportKey) async {
        if (!vaultExists) return false;
        backedUp.add(exportKey);
        return true;
      },
    );
    return (vm: vm, backedUp: backedUp);
  }

  test(
    'submit : le login sauvegarde la VaultKey avec la clé exportée',
    () async {
      final auth = FakeAuthService();
      final (:vm, :backedUp) = build(auth);

      await vm.submit(username: 'alice', password: 'Motdepasse1!');

      expect(vm.isLoggedIn, isTrue);
      expect(vm.error, isNull);
      // C'est bien la clé exportée du login qui scelle le backup.
      expect(backedUp, [auth.exportKey]);
      expect(vm.vaultKeyBackedUp, isTrue);
    },
  );

  test('submit sans coffre créé → connecté mais pas de backup', () async {
    final auth = FakeAuthService();
    final (:vm, :backedUp) = build(auth, vaultExists: false);

    await vm.submit(username: 'alice', password: 'Motdepasse1!');

    expect(vm.isLoggedIn, isTrue);
    expect(backedUp, isEmpty);
    expect(vm.vaultKeyBackedUp, isFalse);
  });

  test('register puis login enchaînés', () async {
    final auth = FakeAuthService();
    final (:vm, :backedUp) = build(auth);
    vm.setMode(AuthMode.register);

    await vm.submit(username: 'bob', password: 'Motdepasse1!');

    expect(auth.registeredUsernames, ['bob']);
    expect(auth.loggedInUsernames, ['bob']);
    expect(vm.vaultKeyBackedUp, isTrue);
  });

  test("échec d'auth → message, ni session ni backup", () async {
    final auth = FakeAuthService()
      ..failure = const AuthException.usernameTaken();
    final (:vm, :backedUp) = build(auth);
    vm.setMode(AuthMode.register);

    await vm.submit(username: 'alice', password: 'Motdepasse1!');

    expect(vm.isLoggedIn, isFalse);
    expect(vm.error, "Ce nom d'utilisateur est déjà pris.");
    expect(backedUp, isEmpty);
  });

  test(
    'register refuse un mot de passe faible sans appeler le serveur',
    () async {
      final auth = FakeAuthService();
      final (:vm, backedUp: _) = build(auth);
      vm.setMode(AuthMode.register);

      await vm.submit(username: 'alice', password: 'court');

      expect(vm.error, isNotNull);
      expect(vm.isLoggedIn, isFalse);
      expect(auth.registeredUsernames, isEmpty);
    },
  );

  test('register refuse un nom d\'utilisateur invalide', () async {
    final auth = FakeAuthService();
    final (:vm, backedUp: _) = build(auth);
    vm.setMode(AuthMode.register);

    await vm.submit(username: 'a b', password: 'Motdepasse1!');

    expect(vm.error, isNotNull);
    expect(auth.registeredUsernames, isEmpty);
  });

  test('login n\'impose aucun format (compte préexistant)', () async {
    final auth = FakeAuthService();
    final (:vm, backedUp: _) = build(auth);
    // Mode login par défaut : un identifiant « court » doit passer côté client.
    await vm.submit(username: 'ab', password: 'court');

    expect(vm.error, isNull);
    expect(vm.isLoggedIn, isTrue);
    expect(auth.loggedInUsernames, ['ab']);
  });

  test('initialize remonte le statut de backup quand connecté', () async {
    final auth = FakeAuthService()
      ..loggedIn = true
      ..hasBackup = true;
    final (:vm, backedUp: _) = build(auth);

    await vm.initialize();

    expect(vm.isLoggedIn, isTrue);
    expect(vm.vaultKeyBackedUp, isTrue);
  });

  test('logout réinitialise session et statut de backup', () async {
    final auth = FakeAuthService();
    final (:vm, backedUp: _) = build(auth);
    await vm.submit(username: 'alice', password: 'Motdepasse1!');

    await vm.logout();

    expect(vm.isLoggedIn, isFalse);
    expect(vm.vaultKeyBackedUp, isFalse);
  });
}
