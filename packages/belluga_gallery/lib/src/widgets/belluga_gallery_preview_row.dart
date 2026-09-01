import 'package:flutter/material.dart';

import '../gallery_item.dart';
import '../gallery_youtube_player.dart';
import 'gallery_item_preview.dart';

final class BellugaGalleryPreviewRow extends StatelessWidget {
  const BellugaGalleryPreviewRow({
    required this.items,
    required this.onItemSelected,
    this.height,
    this.itemWidth,
    super.key,
  });

  final List<GalleryItem> items;
  final ValueChanged<int> onItemSelected;
  final double? height;
  final double? itemWidth;

  @override
  Widget build(BuildContext context) {
    const gap = 12.0;
    return LayoutBuilder(
      builder: (context, constraints) {
        final responsiveSlotWidth = ((constraints.maxWidth - (gap * 2)) / 2.8)
            .clamp(92.0, 148.0);
        final slotWidth = itemWidth ?? responsiveSlotWidth;
        final rowHeight = height ?? (slotWidth * 1.55).clamp(156.0, 220.0);

        return SizedBox(
          height: rowHeight,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (context, index) => const SizedBox(width: gap),
            itemBuilder: (context, index) {
              final item = items[index];
              final width = item is GalleryYoutubePlayer
                  ? (slotWidth * 2) + gap
                  : slotWidth;
              return SizedBox(
                width: width,
                child: GalleryItemPreview(
                  key: Key('bellugaGalleryPreview_${item.itemId}'),
                  item: item,
                  onTap: () => onItemSelected(index),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
