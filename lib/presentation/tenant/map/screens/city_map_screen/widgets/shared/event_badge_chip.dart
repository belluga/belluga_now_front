import 'package:flutter/material.dart';

class EventBadgeChip extends StatelessWidget {
  const EventBadgeChip({
    super.key,
    required this.label,
    required this.color,
    this.dimmed = false,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
  });

  final String label;
  final Color color;
  final bool dimmed;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final effectiveColor = dimmed ? color.withOpacity(0.85) : color;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: effectiveColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: scheme.surface, width: 2),
      ),
      child: Padding(
        padding: padding,
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
        ),
      ),
    );
  }
}
