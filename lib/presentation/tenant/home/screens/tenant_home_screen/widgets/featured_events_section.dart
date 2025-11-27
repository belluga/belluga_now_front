import 'package:belluga_now/domain/venue_event/projections/venue_event_resume.dart';
import 'package:belluga_now/presentation/tenant/home/screens/tenant_home_screen/controllers/tenant_home_controller.dart';
import 'package:belluga_now/presentation/tenant/widgets/carousel_event_card.dart';
import 'package:belluga_now/presentation/tenant/widgets/stream_value_section.dart';
import 'package:flutter/material.dart';

class FeaturedEventsSection extends StatelessWidget {
  const FeaturedEventsSection({
    super.key,
    required this.controller,
  });

  final TenantHomeController controller;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final cardWidth = width * 0.8;
    final cardHeight = cardWidth * 9 / 16;

    return StreamValueSection<VenueEventResume>(
      title: 'Seus eventos',
      stream: controller.myEventsStreamValue,
      loading: SizedBox(
        height: width * 0.8 * 9 / 16,
        child: const Center(child: CircularProgressIndicator()),
      ),
      empty: const EmptyMyEventsState(),
      onSeeAll: () {}, // no-op for now
      headerPadding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      contentSpacing: EdgeInsets.zero,
      contentBuilder: (context, events) {
        return SizedBox(
          height: cardHeight,
          child: CarouselView(
            itemExtent: cardWidth,
            itemSnapping: true,
            children:
                events.map((event) => CarouselEventCard(event: event)).toList(),
          ),
        );
      },
    );
  }
}

class EmptyMyEventsState extends StatelessWidget {
  const EmptyMyEventsState({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 200,
      child: Center(
        child: Text(
          'Você ainda não confirmou presença em nenhum evento.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
