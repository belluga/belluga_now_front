import 'package:belluga_now/presentation/tenant/widgets/date_badge.dart';
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: 16 / 9,
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
                              Colors.black.withOpacity(0.75),
                              Colors.black.withOpacity(0.1),
                            ],
                            begin: Alignment.bottomCenter,
                            end: Alignment.center,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              AnimatedSwitcher(
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
            ],
          ),
        );
      },
    );
  }
}
