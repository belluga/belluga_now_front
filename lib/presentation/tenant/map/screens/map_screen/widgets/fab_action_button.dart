import 'package:flutter/material.dart';

class FabActionButton extends StatelessWidget {
  const FabActionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.onTap,
    required this.condensed,
  });

  final String label;
  final IconData icon;
  final Color backgroundColor;
  final Color foregroundColor;
  final VoidCallback onTap;
  final bool condensed;

  @override
  Widget build(BuildContext context) {
    if (condensed) {
      return FloatingActionButton.small(
        heroTag: 'condensed-${label.hashCode}-${icon.codePoint}',
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        elevation: 0.5,
        onPressed: onTap,
        child: Icon(icon),
      );
    }
    return FloatingActionButton.extended(
      heroTag: 'expanded-${label.hashCode}-${icon.codePoint}',
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      elevation: 0.5,
      onPressed: onTap,
      icon: Icon(icon),
      label: Text(label),
    );
  }
}
