import 'package:flutter/material.dart';

class PoiCardSecondaryAction {
  const PoiCardSecondaryAction({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
}
