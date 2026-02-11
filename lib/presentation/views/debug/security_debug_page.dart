import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../core/security/key_derivator.dart';
import '../../../core/security/salt_manager.dart';

class SecurityDebugPage extends StatefulWidget {
  const SecurityDebugPage({super.key});

  @override
  State<SecurityDebugPage> createState() => _SecurityDebugPageState();
}

class _SecurityDebugPageState extends State<SecurityDebugPage> {
  // États pour l'affichage
  String _logs = "Initialisation...\n";
  bool _isLoading = false;

  // Données temporaires
  Uint8List? _loadedSalt;

  // Contrôleur
  final _passwordController = TextEditingController(text: "TestPassword123!");

  void _log(String message) {
    setState(() {
      _logs += "${DateTime.now().second}s: $message\n";
    });
  }

  // --- TEST 1: LE SEL (SALT) ---
  Future<void> _testSalt() async {
    setState(() => _isLoading = true);
    try {
      _log("--- TEST SALT ---");
      final salt = await SaltManager.getOrGenerateSalt();
      _loadedSalt = salt;
      _log("Succès ! Sel récupéré (longueur: ${salt.length})");
      _log("Base64: ${base64Encode(salt).substring(0, 10)}...");
    } catch (e) {
      _log("ERREUR SALT: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // --- TEST 2: ARGON2 (DERIVATION) ---
  Future<void> _testArgon2() async {
    if (_loadedSalt == null) {
      _log("Erreur: Chargez le sel d'abord !");
      return;
    }
    setState(() => _isLoading = true);
    try {
      _log("--- TEST ARGON2 ---");
      _log("Début du hachage (Patientez... CPU intensif)");

      final stopwatch = Stopwatch()..start();

      final key = await KeyDerivator.deriveKeyFromPassword(
        _passwordController.text,
        _loadedSalt!,
      );

      final keyBytes = await key.extractBytes();
      final hexKey = keyBytes
          .map((b) => b.toRadixString(16).padLeft(2, '0'))
          .join();

      stopwatch.stop();

      _log("Succès ! Clé générée en ${stopwatch.elapsedMilliseconds}ms");
      _log("Clé Hex (Partial): ${hexKey.substring(0, 10)}...");
    } catch (e) {
      _log("ERREUR ARGON2: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Security Lab 🧪")),
      body: Column(
        children: [
          // Zone de contrôles
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    TextField(
                      controller: _passwordController,
                      decoration: const InputDecoration(
                        labelText: "Mot de passe maître",
                      ),
                      obscureText: true,
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      children: [
                        ElevatedButton(
                          onPressed: _isLoading ? null : _testSalt,
                          child: const Text("1. Sel"),
                        ),
                        ElevatedButton(
                          onPressed: _isLoading ? null : _testArgon2,
                          child: const Text("2. Argon2"),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          if (_isLoading) const LinearProgressIndicator(),

          // Zone de logs
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              child: SingleChildScrollView(
                reverse: true, // Scrolle vers le bas auto
                child: Text(
                  _logs,
                  style: const TextStyle(
                    color: Colors.greenAccent,
                    fontFamily: 'Courier',
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
