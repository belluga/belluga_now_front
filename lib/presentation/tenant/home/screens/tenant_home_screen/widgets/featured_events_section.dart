import 'package:belluga_now/domain/venue_event/projections/venue_event_resume.dart';
import 'package:belluga_now/presentation/tenant/home/screens/tenant_home_screen/controllers/tenant_home_controller.dart';
import 'package:belluga_now/presentation/tenant/widgets/carousel_event_card.dart';
import 'package:flutter/material.dart';
import 'package:stream_value/core/stream_value_builder.dart';

class FeaturedEventsSection extends StatelessWidget {
  const FeaturedEventsSection({
    super.key,
    required this.controller,
  });

  final TenantHomeController controller;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return StreamValueBuilder<List<VenueEventResume>?>(
      streamValue: controller.featuredEventsStreamValue,
      onNullWidget: SizedBox(
        height: width * 0.8 * 9 / 16,
        child: const Center(child: CircularProgressIndicator()),
      ),
      builder: (context, events) {
        final items = events ?? const <VenueEventResume>[];
        if (items.isEmpty) {
          return const EmptyFeaturedEventsState();
        }

        final cardWidth = width * 0.8;
        final cardHeight = cardWidth * 9 / 16;

        return SizedBox(
          height: cardHeight,
          child: CarouselView(
            itemExtent: cardWidth,
            itemSnapping: true,
            children:
                items.map((event) => CarouselEventCard(event: event)).toList(),
          ),
        );
      },
    );
  }
}

class EmptyFeaturedEventsState extends StatelessWidget {
  const EmptyFeaturedEventsState({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 200,
      child: Center(
        child: Text(
          'Nenhum evento em destaque.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
