import 'package:flutter/material.dart';

import '../gallery_item.dart';
import '../gallery_photo.dart';
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
              return _GalleryPreviewSlot(
                key: ValueKey(item.itemId),
                item: item,
                slotWidth: slotWidth,
                gap: gap,
                onTap: () => onItemSelected(index),
              );
            },
          ),
        );
      },
    );
  }
}

final class _GalleryPreviewSlot extends StatefulWidget {
  const _GalleryPreviewSlot({
    required this.item,
    required this.slotWidth,
    required this.gap,
    required this.onTap,
    super.key,
  });

  final GalleryItem item;
  final double slotWidth;
  final double gap;
  final VoidCallback onTap;

  @override
  State<_GalleryPreviewSlot> createState() => _GalleryPreviewSlotState();
}

final class _GalleryPreviewSlotState extends State<_GalleryPreviewSlot> {
  ImageStream? _imageStream;
  ImageStreamListener? _imageStreamListener;
  bool? _isHorizontal;

  String get _previewUrl {
    final item = widget.item;
    return item is GalleryPhoto
        ? item.previewUrl
        : (item as GalleryYoutubePlayer).thumbnailUrl;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resolvePreviewProportion();
  }

  @override
  void didUpdateWidget(covariant _GalleryPreviewSlot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_previewUrlFor(oldWidget.item) != _previewUrl) {
      _isHorizontal = null;
      _resolvePreviewProportion();
    }
  }

  @override
  void dispose() {
    _removeImageStreamListener();
    super.dispose();
  }

  void _resolvePreviewProportion() {
    _removeImageStreamListener();
    final url = _previewUrl;
    if (url.isEmpty) {
      return;
    }

    final stream = NetworkImage(
      url,
    ).resolve(createLocalImageConfiguration(context));
    late final ImageStreamListener listener;
    listener = ImageStreamListener((imageInfo, synchronousCall) {
      if (!identical(_imageStream, stream)) {
        return;
      }
      final isHorizontal = imageInfo.image.width > imageInfo.image.height;
      if (_isHorizontal != isHorizontal) {
        if (synchronousCall) {
          _isHorizontal = isHorizontal;
        } else {
          setState(() => _isHorizontal = isHorizontal);
        }
      }
    }, onError: (error, stackTrace) {});
    _imageStream = stream;
    _imageStreamListener = listener;
    stream.addListener(listener);
  }

  void _removeImageStreamListener() {
    final stream = _imageStream;
    final listener = _imageStreamListener;
    if (stream != null && listener != null) {
      stream.removeListener(listener);
    }
    _imageStream = null;
    _imageStreamListener = null;
  }

  static String _previewUrlFor(GalleryItem item) => item is GalleryPhoto
      ? item.previewUrl
      : (item as GalleryYoutubePlayer).thumbnailUrl;

  @override
  Widget build(BuildContext context) {
    final defaultsToHorizontal = widget.item is GalleryYoutubePlayer;
    final isHorizontal = _isHorizontal ?? defaultsToHorizontal;
    final width = isHorizontal
        ? (widget.slotWidth * 2) + widget.gap
        : widget.slotWidth;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      width: width,
      child: GalleryItemPreview(
        key: Key('bellugaGalleryPreview_${widget.item.itemId}'),
        item: widget.item,
        onTap: widget.onTap,
      ),
    );
  }
}
