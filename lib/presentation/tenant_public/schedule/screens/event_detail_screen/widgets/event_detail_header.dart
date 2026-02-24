import 'dart:ui';

import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/domain/schedule/event_type_model.dart';
import 'package:belluga_now/presentation/shared/widgets/belluga_network_image.dart';
import 'package:belluga_now/presentation/tenant_public/schedule/screens/event_detail_screen/widgets/event_type_chip.dart';
import 'package:flutter/material.dart';

class EventDetailHeader extends StatelessWidget {
  const EventDetailHeader({
    super.key,
    required this.title,
    required this.coverImage,
    required this.type,
    this.expandedHeight = 340,
  });

  final String title;
  final String coverImage;
  final EventTypeModel type;
  final double expandedHeight;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SliverAppBar(
      pinned: true,
      expandedHeight: expandedHeight,
      backgroundColor: colorScheme.surface,
      foregroundColor: Colors.white, // Always white text on top of image
      stretch: true,
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.3),
          shape: BoxShape.circle,
        ),
        child: IconButton(
          icon: const Icon(Icons.arrow_back, size: 20),
          onPressed: () => context.router.pop(),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [
          StretchMode.zoomBackground,
          StretchMode.blurBackground,
        ],
        titlePadding: EdgeInsets.zero,
        title: _buildTitle(context),
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Hero Image
            Hero(
              tag: 'event_cover_$coverImage',
              child: BellugaNetworkImage(
                coverImage,
                fit: BoxFit.cover,
                errorWidget: Container(
                  color: colorScheme.surfaceContainerHigh,
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.image_not_supported_outlined,
                    size: 48,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
            // Gradient Overlay
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.2),
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.4),
                    Colors.black.withValues(alpha: 0.8),
                  ],
                  stops: const [0.0, 0.3, 0.7, 1.0],
                ),
              ),
            ),
            // Type Chip
            Positioned(
              top: kToolbarHeight + 40,
              left: 20,
              child: EventTypeChip(type: type),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTitle(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 0.0, sigmaY: 0.0),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.black.withValues(alpha: 0.0),
              ],
            ),
          ),
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20, // Slightly smaller for pinned state
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}
