import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Bienvenue sur la page d\'accueil !'),
          OutlinedButton(onPressed: () {
            context.goNamed('vaultDebug');
          }, child: const Text("Tester le coffre-fort (Debug)")),
        ],
      ),
    );
  }
}
