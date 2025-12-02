import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/presentation/common/widgets/main_logo.dart';
import 'package:belluga_now/presentation/tenant/home/screens/tenant_home_screen/controllers/tenant_home_controller.dart';
import 'package:belluga_now/presentation/tenant/home/screens/tenant_home_screen/widgets/favorite_section/favorites_section_builder.dart';
import 'package:belluga_now/presentation/tenant/home/screens/tenant_home_screen/widgets/invites_banner_builder.dart';
import 'package:belluga_now/presentation/tenant/home/screens/tenant_home_screen/widgets/upcoming_events_section.dart';
import 'package:belluga_now/presentation/tenant/widgets/belluga_bottom_navigation_bar.dart';
import 'package:belluga_now/presentation/tenant/widgets/carousel_card.dart';
import 'package:belluga_now/presentation/tenant/widgets/carousel_section.dart';
import 'package:belluga_now/presentation/tenant/widgets/event_details.dart';
import 'package:belluga_now/presentation/tenant/widgets/section_header.dart';
import 'package:belluga_now/presentation/tenant/widgets/animated_search_button.dart';
import 'package:belluga_now/presentation/tenant/schedule/screens/event_search_screen/models/invite_filter.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:belluga_now/domain/venue_event/projections/venue_event_resume.dart';

class TenantHomeScreen extends StatefulWidget {
  const TenantHomeScreen({super.key});

  @override
  State<TenantHomeScreen> createState() => _TenantHomeScreenState();
}

class _TenantHomeScreenState extends State<TenantHomeScreen> {
  late final TenantHomeController _controller =
      GetIt.I.get<TenantHomeController>();

  @override
  void initState() {
    super.initState();
    _controller.init();
  }

  @override
  Widget build(BuildContext context) {

    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: SizedBox(
          width: double.infinity,
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              const Padding(
                padding: EdgeInsets.only(left: 16),
                child: MainLogo(),
              ),
              Positioned(
                right: 0,
                child: AnimatedSearchButton(
                  onTap: () {
                    context.router.push(EventSearchRoute());
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () {},
            tooltip: 'Notificações',
          ),
          const SizedBox(width: 8),
        ],
      ),
      bottomNavigationBar: const BellugaBottomNavigationBar(currentIndex: 0),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 150),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(
                title: 'Seus Favoritos',
                onPressed: () {},
              ),
              FavoritesSectionBuilder(controller: _controller),
              const SizedBox(height: 8),
              InvitesBannerBuilder(
                onPressed: _openInviteFlow,
                margin: const EdgeInsets.only(bottom: 16),
              ),
              CarouselSection<VenueEventResume>(
                title: 'Seus Eventos',
                streamValue: _controller.myEventsStreamValue,
                loading: SizedBox(
                  height: width * 0.8 * 9 / 16,
                  child: const Center(child: CircularProgressIndicator()),
                ),
                empty: const SizedBox.shrink(),
                onSeeAll: _openMyEventsConfirmed,
                sectionPadding: const EdgeInsets.only(bottom: 16),
                contentSpacing: EdgeInsets.zero,
                cardBuilder: (event) => CarouselCard(
                  imageUri: event.imageUri,
                  contentOverlay: EventDetails(event: event),
                ),
              ),
              SectionHeader(
                title: 'Próximos Eventos',
                onPressed: _openUpcomingEvents,
              ),
              const SizedBox(height: 8),
              UpcomingEventsSection(
                controller: _controller,
                onExplore: _openUpcomingEvents,
                onEventSelected: _openEventDetailSlug,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openInviteFlow() {
    context.router.push(const InviteFlowRoute());
  }

  void _openMyEventsConfirmed() {
    _openSearchWithFilter(InviteFilter.confirmedOnly);
  }

  void _openUpcomingEvents() {
    _openSearchWithFilter(InviteFilter.none);
  }

  void _openEventDetailSlug(String slug) {
    context.router.push(ImmersiveEventDetailRoute(eventSlug: slug));
  }

  void _openSearchWithFilter(InviteFilter filter) {
    context.router.push(
      EventSearchRoute(
        inviteFilter: filter,
        startSearchActive: false,
      ),
    );
  }
}
