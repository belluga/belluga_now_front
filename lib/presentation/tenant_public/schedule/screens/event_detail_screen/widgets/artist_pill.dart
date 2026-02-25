import 'package:flutter/material.dart';

class EventArtistPill extends StatelessWidget {
  const EventArtistPill({
    super.key,
    required this.name,
    required this.highlight,
  });

  final String name;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final foreground =
        highlight ? colorScheme.onPrimary : colorScheme.onSurface;
    final background = highlight
        ? colorScheme.primary
        : colorScheme.surfaceContainerHighest;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: background,
        border: highlight
            ? null
            : Border.all(color: colorScheme.outlineVariant, width: 1),
      ),
      child: Text(
        highlight ? '$name ★' : name,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: foreground,
        ),
      ),
    );
  }
}
