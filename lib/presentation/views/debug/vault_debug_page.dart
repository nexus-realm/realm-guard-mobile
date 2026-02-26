import 'package:flutter/material.dart';
import 'package:drift/drift.dart' as drift;

import '../../../core/database/app_database.dart';
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
  String _statusMessage = "Entrez un mot de passe pour créer/ouvrir le coffre.";
  int _entryCount = 0;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

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
      await _vaultService.unlockVault(password);

      // Si on arrive ici, la DB est ouverte avec succès !
      await _refreshEntryCount();

      setState(() {
        _isUnlocked = true;
        _statusMessage = "Succès ! Coffre-fort déverrouillé.\nEntrées : $_entryCount";
      });
    } catch (e) {
      setState(() {
        _isUnlocked = false;
        _statusMessage = "Erreur : Mot de passe incorrect ou erreur DB.\nDétails: $e";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _addTestEntry() async {
    if (!_isUnlocked) return;

    try {
      await _vaultService.db.into(_vaultService.db.vaultEntries).insert(
        const VaultEntriesCompanion(
          title: drift.Value("Test Entry"),
          encryptedData: drift.Value("données_super_secrètes_ici"),
        ),
      );

      await _refreshEntryCount();
      setState(() {
        _statusMessage = "Entrée ajoutée avec succès !\nNouvelles entrées : $_entryCount";
      });
    } catch (e) {
      setState(() => _statusMessage = "Erreur lors de l'ajout : $e");
    }
  }

  Future<void> _refreshEntryCount() async {
    // Compte le nombre de lignes dans la table
    final count = await _vaultService.db.vaultEntries.count().getSingle();
    _entryCount = count;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test du Coffre-fort'),
        backgroundColor: _isUnlocked ? Colors.green : Colors.blueGrey,
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
                labelText: 'Mot de passe Maître',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.password),
              ),
              obscureText: true,
              enabled: !_isLoading && !_isUnlocked, // On désactive si c'est ouvert
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (!_isUnlocked)
              ElevatedButton(
                onPressed: _unlockVault,
                child: const Text('Déverrouiller / Créer'),
              ),
            if (_isUnlocked) ...[
              ElevatedButton(
                onPressed: _addTestEntry,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: const Text('Ajouter une entrée de test (Drift)'),
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