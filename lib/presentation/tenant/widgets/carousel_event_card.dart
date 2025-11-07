import 'package:belluga_now/presentation/tenant/widgets/event_details.dart';
import 'package:belluga_now/presentation/view_models/event_card_data.dart';
import 'package:flutter/material.dart';

class CarouselEventCard extends StatelessWidget {
  const CarouselEventCard({super.key, required this.data});

  final EventCardData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final targetWidth = MediaQuery.of(context).size.width * 0.8;
        final isFullSize = constraints.maxWidth >= targetWidth * 0.8;

        return SizedBox(
          width: constraints.maxWidth,
          child: AspectRatio(
            aspectRatio: 16 / 11,
            child: Card(
              elevation: 3,
              clipBehavior: Clip.antiAlias,
              color: theme.colorScheme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    data.imageUrl,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(
                        child: Icon(Icons.broken_image, size: 48),
                      );
                    },
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          theme.colorScheme.onSurface,
                          theme.colorScheme.onSurface.withValues(alpha: 0.45),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.55, 1.0],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      ),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      switchInCurve: Curves.easeOut,
                      switchOutCurve: Curves.easeIn,
                      transitionBuilder: (child, animation) => FadeTransition(
                        opacity: animation,
                        child: SizeTransition(
                          sizeFactor: animation,
                          axisAlignment: -1,
                          child: child,
                        ),
                      ),
                      child: isFullSize
                          ? EventDetails(eventCardData: data)
                          : const SizedBox(
                              key: ValueKey('empty'),
                              height: 0,
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
