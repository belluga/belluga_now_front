import 'package:belluga_now/domain/favorite/projections/favorite_resume.dart';
import 'package:flutter/material.dart';

class FavoriteChipImage extends StatelessWidget {
  const FavoriteChipImage({super.key, required this.item});

  final FavoriteResume item;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (item.assetPath != null) {
      return Image.asset(
        item.assetPath!,
        fit: BoxFit.cover,
      );
    }

    final imageUrl = item.imageUri?.toString();
    if (imageUrl == null) {
      return Container(
        color: colorScheme.surfaceContainerHighest,
        child: Icon(
          Icons.image_not_supported_outlined,
          color: colorScheme.onSurfaceVariant,
        ),
      );
    }

    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          color: colorScheme.surfaceContainerHighest,
          child: const Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        );
      },
      errorBuilder: (_, __, ___) => Container(
        color: colorScheme.surfaceContainerHighest,
        child: Icon(
          Icons.image_not_supported_outlined,
          color: colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
