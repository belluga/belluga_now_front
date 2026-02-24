import 'package:flutter/material.dart';

class MenuSection {
  const MenuSection({required this.title, required this.actions});

  final String title;
  final List<MenuAction> actions;
}

class MenuAction {
  const MenuAction({
    required this.icon,
    required this.label,
    required this.helper,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String helper;
  final VoidCallback onTap;
}
