import 'package:flutter/material.dart';

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    required this.onPressed,
    this.onTitleTap,
  });

  final String title;
  final VoidCallback onPressed;
  final VoidCallback? onTitleTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTitleTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(
              title,
              style: theme.textTheme.titleLarge,
            ),
          ),
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
