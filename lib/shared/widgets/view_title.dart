import 'package:flutter/material.dart';

import 'neon_box_decoration.dart';

class ViewTitle extends StatelessWidget {
  final String title;
  final String topTitle;

  const ViewTitle({super.key, required this.title, this.topTitle = ""});

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: 4,
            decoration: NeonBoxDecoration.neonBoxDecoration,
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (topTitle.trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(topTitle.toUpperCase(), semanticsLabel: topTitle, style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 4),
                ],
                Text(title.toUpperCase(), semanticsLabel: title, style: Theme.of(context).textTheme.titleLarge),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
