import 'package:flutter/material.dart';

import '../gallery_item.dart';
import '../gallery_photo.dart';
import '../gallery_youtube_player.dart';

final class GalleryItemPreview extends StatelessWidget {
  const GalleryItemPreview({
    required this.item,
    required this.onTap,
    super.key,
  });

  final GalleryItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final currentItem = item;
    final imageUrl = currentItem is GalleryPhoto
        ? currentItem.previewUrl
        : (currentItem as GalleryYoutubePlayer).thumbnailUrl;

    return Semantics(
      button: true,
      label: item is GalleryYoutubePlayer ? 'Abrir vídeo' : 'Abrir foto',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              _NetworkGalleryImage(url: imageUrl),
              if (item is GalleryYoutubePlayer)
                const ColoredBox(
                  color: Color(0x33000000),
                  child: Center(
                    child: Icon(
                      Icons.play_circle_fill,
                      color: Colors.white,
                      size: 46,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

final class _NetworkGalleryImage extends StatelessWidget {
  const _NetworkGalleryImage({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) {
      return const ColoredBox(
        color: Color(0xFFE4E4E4),
        child: Center(child: Icon(Icons.broken_image_outlined)),
      );
    }
    return Image.network(
      url,
      fit: BoxFit.cover,
      frameBuilder: (context, child, frame, synchronous) =>
          synchronous || frame != null
          ? child
          : const ColoredBox(color: Color(0xFFE4E4E4)),
      errorBuilder: (context, error, stackTrace) => const ColoredBox(
        color: Color(0xFFE4E4E4),
        child: Center(child: Icon(Icons.broken_image_outlined)),
      ),
    );
  }
}
