import 'package:flutter/material.dart';

import 'package:belluga_now/presentation/view_models/favorite_item_data.dart';
import 'package:belluga_now/presentation/tenant/widgets/favorite_chip.dart';

class FavoritesStrip extends StatelessWidget {
  const FavoritesStrip({
    super.key,
    required this.items,
    this.pinFirst = false,
    this.height = 118,
    this.spacing = 12,
  });

  final List<FavoriteItemData> items;
  final bool pinFirst;
  final double height;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    final pinned = pinFirst && items.isNotEmpty ? items.first : null;
    final scrollItems =
        pinned == null ? items : items.sublist(1); // omit pinned from list view

    return SizedBox(
      height: height,
      child: Row(
        children: [
          if (pinned != null)
            Padding(
              padding: EdgeInsets.only(right: spacing),
              child: FavoriteChip(item: pinned),
            ),
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: scrollItems.length,
              padding: EdgeInsets.only(
                left: pinFirst ? 0 : spacing,
                right: spacing,
              ),
              separatorBuilder: (_, __) => SizedBox(width: spacing),
              itemBuilder: (context, index) => FavoriteChip(
                item: scrollItems[index],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
