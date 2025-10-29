import 'package:belluga_now/presentation/view_models/favorite_item_data.dart';
import 'package:flutter/material.dart';

class FavoriteChip extends StatelessWidget {
  const FavoriteChip({super.key, required this.item});

  final FavoriteItemData item;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(radius: 37);
  }
}
