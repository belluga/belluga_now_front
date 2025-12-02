import 'package:flutter/material.dart';

class SectionHeader extends StatelessWidget {
  const SectionHeader(
      {super.key, required this.title, required this.onPressed});

  final String title;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Text(
          title,
          // Adjusted style to match design's hierarchy
          style: theme.textTheme.titleLarge,
        ),
        IconButton(
          onPressed: onPressed,
          icon: const Icon(Icons.arrow_forward),
          tooltip: 'Ver mais',
        ),
      ],
    );
  }
}
