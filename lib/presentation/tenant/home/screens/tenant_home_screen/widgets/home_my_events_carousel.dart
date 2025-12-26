import 'package:belluga_now/domain/venue_event/projections/venue_event_resume.dart';
import 'package:belluga_now/presentation/tenant/home/screens/tenant_home_screen/widgets/my_events_carousel_card.dart';
import 'package:belluga_now/presentation/tenant/home/screens/tenant_home_screen/widgets/see_more_my_events_card.dart';
import 'package:belluga_now/presentation/tenant/widgets/carousel_section.dart';
import 'package:flutter/material.dart';
import 'package:stream_value/core/stream_value.dart';

class HomeMyEventsCarousel extends StatelessWidget {
  const HomeMyEventsCarousel({
    super.key,
    required this.myEventsFilteredStreamValue,
    required this.onSeeAll,
    required this.distanceLabelProvider,
  });

  final StreamValue<List<VenueEventResume>> myEventsFilteredStreamValue;
  final VoidCallback onSeeAll;
  final String? Function(VenueEventResume) distanceLabelProvider;

  @override
  Widget build(BuildContext context) {
    return CarouselSection<VenueEventResume>(
      title: 'Meus Eventos',
      streamValue: myEventsFilteredStreamValue,
      maxItems: 5,
      overflowTrailing: SeeMoreMyEventsCard(
        onTap: onSeeAll,
      ),
      headerPadding: EdgeInsets.zero,
      sectionPadding: EdgeInsets.zero,
      onSeeAll: onSeeAll,
      onTitleTap: onSeeAll,
      cardBuilder: (event) {
        return MyEventsCarouselCard(
          event: event,
          isConfirmed: true,
          pendingInvitesCount: 0,
          distanceLabel: distanceLabelProvider(event),
        );
      },
    );
  }
}
