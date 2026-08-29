import 'package:belluga_now/domain/upcoming_ocurrence/projections/upcoming_ocurrence_resume.dart';
import 'package:belluga_now/presentation/tenant_public/home/screens/tenant_home_screen/widgets/my_events_carousel_card.dart';
import 'package:belluga_now/presentation/tenant_public/home/screens/tenant_home_screen/widgets/see_more_my_events_card.dart';
import 'package:belluga_now/presentation/tenant_public/widgets/carousel_section.dart';
import 'package:flutter/material.dart';
class HomeMyEventsCarousel extends StatelessWidget {
  const HomeMyEventsCarousel({
    super.key,
    required this.events,
    required this.onSeeAll,
    required this.distanceLabelProvider,
  });

  final List<UpcomingOcurrenceResume> events;
  final VoidCallback onSeeAll;
  final String? Function(UpcomingOcurrenceResume) distanceLabelProvider;

  @override
  Widget build(BuildContext context) {
    return CarouselSection<UpcomingOcurrenceResume>(
      title: 'Meus Eventos',
      items: events,
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
