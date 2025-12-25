import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/presentation/tenant/home/screens/tenant_home_provisional_screen/controllers/tenant_home_provisional_controller.dart';
import 'package:belluga_now/presentation/tenant/home/screens/tenant_home_provisional_screen/widgets/agenda_section/home_agenda_section.dart';
import 'package:belluga_now/presentation/tenant/home/screens/tenant_home_provisional_screen/widgets/home_app_bar.dart';
import 'package:belluga_now/presentation/tenant/home/screens/tenant_home_provisional_screen/widgets/home_my_events_carousel.dart';
import 'package:belluga_now/presentation/tenant/home/screens/tenant_home_screen/widgets/favorite_section/favorites_section_builder.dart';
import 'package:belluga_now/presentation/tenant/schedule/screens/event_search_screen/models/invite_filter.dart';
import 'package:belluga_now/presentation/tenant/widgets/belluga_bottom_navigation_bar.dart';
import 'package:belluga_now/presentation/tenant/widgets/section_header.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

class TenantHomeProvisionalScreen extends StatefulWidget {
  const TenantHomeProvisionalScreen({super.key});

  @override
  State<TenantHomeProvisionalScreen> createState() =>
      _TenantHomeProvisionalScreenState();
}

class _TenantHomeProvisionalScreenState
    extends State<TenantHomeProvisionalScreen> {
  final TenantHomeProvisionalController _controller =
      GetIt.I.get<TenantHomeProvisionalController>();

  @override
  void initState() {
    super.initState();
    _controller.init();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: const BellugaBottomNavigationBar(currentIndex: 0),
      body: SafeArea(
        top: false,
        child: HomeAgendaSection(
          builder: (context, slots) {
            return NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) => [
                HomeAppBar(
                  userAddressStreamValue: _controller.userAddressStreamValue,
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SectionHeader(
                          title: 'Seus Favoritos',
                          onPressed: () {},
                        ),
                        const FavoritesSectionBuilder(),
                        const SizedBox(height: 12),
                      HomeMyEventsCarousel(
                        myEventsFilteredStreamValue:
                            _controller.myEventsFilteredStreamValue,
                        onSeeAll: _openConfirmedAgenda,
                        distanceLabelProvider:
                            _controller.distanceLabelForMyEvent,
                      ),
                      ],
                    ),
                  ),
                ),
                slots.header,
              ],
              body: slots.body,
            );
          },
        ),
      ),
    );
  }

  void _openConfirmedAgenda() {
    context.router.push(
      EventSearchRoute(inviteFilter: InviteFilter.confirmedOnly),
    );
  }

}
