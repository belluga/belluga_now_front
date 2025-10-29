import 'package:flutter/material.dart';

class FavoriteItemData {
  const FavoriteItemData({
    required this.icon,
    this.isPrimary = false,
  });

  final IconData icon;
  final bool isPrimary;
}