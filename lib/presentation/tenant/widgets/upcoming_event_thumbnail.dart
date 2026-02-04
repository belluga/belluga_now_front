import 'package:belluga_now/presentation/common/widgets/belluga_network_image.dart';
import 'package:flutter/material.dart';

class UpcomingEventThumbnail extends StatelessWidget {
  const UpcomingEventThumbnail({super.key, required this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        width: 96,
        height: 96,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (imageUrl != null)
              BellugaNetworkImage(
                imageUrl!,
                fit: BoxFit.cover,
                placeholder: Container(
                  color: colorScheme.surfaceContainerHigh,
                  child: const Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ),
                errorWidget: Container(
                  color: colorScheme.surfaceContainerHigh,
                  child: Icon(
                    Icons.image_not_supported_outlined,
                    color: colorScheme.onSurfaceVariant,
                    size: 32,
                  ),
                ),
              )
            else
              Container(
                color: colorScheme.surfaceContainerHigh,
                child: Icon(
                  Icons.image,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withValues(alpha: 0.45),
                    Colors.transparent,
                  ],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
