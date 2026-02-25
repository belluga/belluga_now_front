import 'package:flutter/material.dart';

class EventInfoRow extends StatelessWidget {
  const EventInfoRow({
    super.key,
    required this.icon,
    required this.label,
    this.color,
  });

  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final resolvedColor = color ?? Theme.of(context).colorScheme.onSurface;
    final text = Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: resolvedColor,
            fontWeight: FontWeight.w500,
          ),
    );

    final iconWidget = Icon(
      icon,
      size: 18,
      color: resolvedColor.withValues(alpha: 0.9),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final hasBoundedWidth = constraints.maxWidth.isFinite;

        // If the available width can't even fit the icon + spacing, skip rendering to avoid overflows.
        if (hasBoundedWidth && constraints.maxWidth < 32) {
          return const SizedBox.shrink();
        }

        if (!hasBoundedWidth) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              iconWidget,
              const SizedBox(width: 8),
              Flexible(
                fit: FlexFit.loose,
                child: text,
              ),
            ],
          );
        }

        final maxWidth = constraints.maxWidth;
        final cappedWidth = maxWidth.clamp(60.0, 320.0);

        return ConstrainedBox(
          constraints: BoxConstraints(maxWidth: cappedWidth),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              iconWidget,
              const SizedBox(width: 8),
              Flexible(
                fit: FlexFit.loose,
                child: text,
              ),
            ],
          ),
        );
      },
    );
  }
}
