import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';

import '../../../core/database/app_database.dart';
import '../../../core/security/biometric_storage_service.dart';
import '../../../core/security/vault_service.dart';

class VaultDebugPage extends StatefulWidget {
  const VaultDebugPage({super.key});

  @override
  State<VaultDebugPage> createState() => _VaultDebugPageState();
}

class _VaultDebugPageState extends State<VaultDebugPage> {
  final VaultService _vaultService = VaultService();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _isUnlocked = false;
  String _statusMessage = "Entrez un mot de passe ou utilisez la biométrie.";
  int _entryCount = 0;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  /// Déverrouillage classique (et sauvegarde de la clé pour la biométrie)
  Future<void> _unlockVault() async {
    final password = _passwordController.text;
    if (password.isEmpty) {
      setState(() => _statusMessage = "Le mot de passe ne peut pas être vide.");
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = "Dérivation de la clé en cours...";
    });

    try {
      await _vaultService.unlockWithMasterPassword(password);
      await _refreshEntryCount();

      setState(() {
        _isUnlocked = true;
        _statusMessage =
            "Succès ! Coffre-fort déverrouillé par mot de passe.\nClé sauvegardée pour la biométrie.\nEntrées : $_entryCount";
      });
    } catch (e) {
      setState(() {
        _isUnlocked = false;
        _statusMessage =
            "Erreur : Mot de passe incorrect ou erreur DB.\nDétails: $e";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Nouveau : Déverrouillage par biométrie
  Future<void> _unlockWithBiometrics() async {
    setState(() {
      _isLoading = true;
      _statusMessage = "Attente de l'authentification biométrique...";
    });

    try {
      final status = await _vaultService.unlockWithBiometrics();

      if (status == BiometricUnlockStatus.success) {
        await _refreshEntryCount();
        setState(() {
          _isUnlocked = true;
          _statusMessage =
              "Succès ! Coffre-fort déverrouillé via Biométrie.\nEntrées : $_entryCount";
        });
      } else {
        setState(() {
          _isUnlocked = false;
          _statusMessage =
              "Échec biométrique ou aucune clé sauvegardée.\nVeuillez utiliser le mot de passe maître.";
        });
      }
    } catch (e) {
      setState(() {
        _isUnlocked = false;
        _statusMessage = "Erreur lors de la biométrie : $e";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Nouveau : Permet de refermer le coffre pour tester à nouveau
  void _lockVault() {
    _vaultService.lockVault();
    setState(() {
      _isUnlocked = false;
      _entryCount = 0;
      _passwordController.clear();
      _statusMessage = "Coffre verrouillé manuellement.";
    });
  }

  Future<void> _addTestEntry() async {
    if (!_isUnlocked) return;

    try {
      await _vaultService.db
          .into(_vaultService.db.credentials)
          .insert(
            const CredentialsCompanion(
              title: drift.Value("Test Entry"),
              notes: drift.Value("données_super_secrètes_ici"),
            ),
          );

      await _refreshEntryCount();
      setState(() {
        _statusMessage =
            "Entrée ajoutée avec succès !\nNouvelles entrées : $_entryCount";
      });
    } catch (e) {
      setState(() => _statusMessage = "Erreur lors de l'ajout : $e");
    }
  }

  Future<void> _refreshEntryCount() async {
    final count = await _vaultService.db.credentials.count().getSingle();
    _entryCount = count;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test du Coffre-fort'),
        backgroundColor: _isUnlocked ? Colors.green : Colors.blueGrey,
        actions: [
          if (_isUnlocked)
            IconButton(
              icon: const Icon(Icons.lock_outline),
              tooltip: 'Verrouiller le coffre',
              onPressed: _lockVault,
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(
              _isUnlocked ? Icons.lock_open : Icons.lock,
              size: 80,
              color: _isUnlocked ? Colors.green : Colors.grey,
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'Mot de passe maître',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.password),
              ),
              obscureText: true,
              enabled: !_isLoading && !_isUnlocked,
            ),
            const SizedBox(height: 16),

            // --- Section des boutons ---
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (!_isUnlocked) ...[
              ElevatedButton.icon(
                onPressed: _unlockVault,
                icon: const Icon(Icons.key),
                label: const Text('Déverrouiller (Mot de passe)'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _unlockWithBiometrics,
                icon: const Icon(Icons.fingerprint),
                label: const Text('Déverrouiller (Biométrie)'),
              ),
            ],

            if (_isUnlocked) ...[
              ElevatedButton.icon(
                onPressed: _addTestEntry,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                icon: const Icon(Icons.add),
                label: const Text('Ajouter une entrée de test (Drift)'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _lockVault,
                style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                icon: const Icon(Icons.lock),
                label: const Text('Verrouiller le coffre'),
              ),
            ],

            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _statusMessage,
                style: const TextStyle(fontSize: 16, color: Colors.black87),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
