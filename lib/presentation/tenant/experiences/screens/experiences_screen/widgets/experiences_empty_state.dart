import 'package:flutter/material.dart';

class ExperiencesEmptyState extends StatelessWidget {
  const ExperiencesEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.travel_explore,
            size: 40,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 8),
          Text(
            'Nenhuma experiencia encontrada.',
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
