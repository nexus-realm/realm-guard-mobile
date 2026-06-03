import 'package:flutter/material.dart';

import '../../data/profile_colors.dart';

/// Pastille ronde représentant un profil : couleur de la palette (si définie)
/// + initiale du nom, sinon une icône générique.
class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    required this.name,
    required this.colorValue,
    this.radius = 20,
    super.key,
  });

  final String name;
  final int? colorValue;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final color = ProfileColors.fromValue(colorValue);
    final initial = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : '?';
    return CircleAvatar(
      radius: radius,
      backgroundColor: color ?? Theme.of(context).colorScheme.surface,
      child: color == null
          ? Icon(Icons.person, size: radius)
          : Text(
              initial,
              style: TextStyle(
                color: Colors.black,
                fontSize: radius * 0.8,
                fontWeight: FontWeight.bold,
              ),
            ),
    );
  }
}
