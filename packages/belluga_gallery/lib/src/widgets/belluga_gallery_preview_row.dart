import 'package:flutter/material.dart';

import '../gallery_item.dart';
import 'gallery_item_preview.dart';

final class BellugaGalleryPreviewRow extends StatelessWidget {
  const BellugaGalleryPreviewRow({
    required this.items,
    required this.onItemSelected,
    this.height = 120,
    this.itemWidth = 176,
    super.key,
  });

  final List<GalleryItem> items;
  final ValueChanged<int> onItemSelected;
  final double height;
  final double itemWidth;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final item = items[index];
          return SizedBox(
            width: itemWidth,
            child: GalleryItemPreview(
              key: Key('bellugaGalleryPreview_${item.itemId}'),
              item: item,
              onTap: () => onItemSelected(index),
            ),
          );
        },
      ),
    );
  }
}
