import 'package:flutter/material.dart';

class FabActionButton extends StatelessWidget {
  const FabActionButton({
    super.key,
    required this.label,
    this.icon,
    this.iconWidget,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.onTap,
    required this.condensed,
  });

  final String label;
  final IconData? icon;
  final Widget? iconWidget;
  final Color backgroundColor;
  final Color foregroundColor;
  final VoidCallback onTap;
  final bool condensed;

  @override
  Widget build(BuildContext context) {
    final resolvedIcon = iconWidget ??
        Icon(
          icon ?? Icons.tune,
          color: foregroundColor,
        );
    final heroSuffix = icon?.codePoint ?? label.hashCode;
    if (condensed) {
      return FloatingActionButton.small(
        heroTag: 'condensed-${label.hashCode}-$heroSuffix',
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        elevation: 0.5,
        onPressed: onTap,
        child: resolvedIcon,
      );
    }
    return FloatingActionButton.extended(
      heroTag: 'expanded-${label.hashCode}-$heroSuffix',
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      elevation: 0.5,
      onPressed: onTap,
      icon: resolvedIcon,
      label: Text(label),
    );
  }
}
