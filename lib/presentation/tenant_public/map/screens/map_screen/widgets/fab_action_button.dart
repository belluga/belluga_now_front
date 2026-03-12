import 'package:flutter/material.dart';

class FabActionButton extends StatelessWidget {
  const FabActionButton({
    super.key,
    required this.label,
    this.heroId,
    this.icon,
    this.iconWidget,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.onTap,
    required this.condensed,
  });

  final String label;
  final String? heroId;
  final IconData? icon;
  final Widget? iconWidget;
  final Color backgroundColor;
  final Color foregroundColor;
  final VoidCallback? onTap;
  final bool condensed;

  @override
  Widget build(BuildContext context) {
    final resolvedIcon = iconWidget ??
        Icon(
          icon ?? Icons.tune,
          color: foregroundColor,
        );
    final heroIdentity =
        heroId ?? '${label.hashCode}-${icon?.codePoint ?? label.hashCode}';
    if (condensed) {
      return FloatingActionButton.small(
        heroTag: 'condensed-$heroIdentity',
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        elevation: 0.5,
        onPressed: onTap,
        child: resolvedIcon,
      );
    }
    return FloatingActionButton.extended(
      heroTag: 'expanded-$heroIdentity',
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      elevation: 0.5,
      onPressed: onTap,
      icon: resolvedIcon,
      label: Text(label),
    );
  }
}
