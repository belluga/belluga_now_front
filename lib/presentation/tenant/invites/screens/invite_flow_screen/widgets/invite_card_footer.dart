import 'package:flutter/material.dart';

class InviteCardFooter extends StatelessWidget {
  const InviteCardFooter({
    super.key,
    required this.eventName,
    required this.message,
    required this.tags,
    required this.isPreview,
  });

  final String eventName;
  final String message;
  final List<String> tags;
  final bool isPreview;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          eventName,
          style: theme.textTheme.titleLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          message,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: isPreview ? Colors.white60 : Colors.white70,
          ),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: tags
              .map(
                (tag) => Chip(
                  label: Text('#$tag'),
                  backgroundColor: Colors.black.withValues(alpha: 0.35),
                  shape: const StadiumBorder(),
                  labelStyle: theme.textTheme.labelMedium?.copyWith(
                    color: Colors.white,
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}
