import 'package:flutter/material.dart';

class ImmersiveHeroAction {
  const ImmersiveHeroAction({
    required this.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.activeIcon,
    this.isPrimary = false,
    this.isActive = false,
    this.isLoading = false,
    this.foregroundColor,
    this.activeForegroundColor,
  });

  final Key key;
  final String label;
  final IconData icon;
  final IconData? activeIcon;
  final VoidCallback? onPressed;
  final bool isPrimary;
  final bool isActive;
  final bool isLoading;
  final Color? foregroundColor;
  final Color? activeForegroundColor;

  IconData get resolvedIcon {
    if (isActive && activeIcon != null) {
      return activeIcon!;
    }
    return icon;
  }

  Color? get resolvedForegroundColor {
    if (isActive && activeForegroundColor != null) {
      return activeForegroundColor;
    }
    return foregroundColor;
  }
}
