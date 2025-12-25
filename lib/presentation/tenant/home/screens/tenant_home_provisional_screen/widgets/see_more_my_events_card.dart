import 'package:flutter/material.dart';

class SeeMoreMyEventsCard extends StatelessWidget {
  const SeeMoreMyEventsCard({
    super.key,
    required this.onTap,
  });

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      color: colorScheme.surfaceContainerHighest,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.more_horiz, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Ver mais',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
