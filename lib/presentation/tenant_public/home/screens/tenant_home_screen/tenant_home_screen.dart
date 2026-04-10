import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/support/back_surface_kind.dart';
import 'package:belluga_now/application/router/support/deterministic_route_back_policy.dart';
import 'package:belluga_now/application/router/support/route_back_policy.dart';
import 'package:belluga_now/application/router/support/route_back_spec.dart';
import 'package:belluga_now/application/router/support/route_no_history_outcome.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/presentation/tenant_public/home/screens/tenant_home_screen/controllers/tenant_home_controller.dart';
import 'package:belluga_now/presentation/tenant_public/home/screens/tenant_home_screen/models/home_location_status_state.dart';
import 'package:belluga_now/presentation/tenant_public/home/screens/tenant_home_screen/widgets/agenda_section/home_agenda_section.dart';
import 'package:belluga_now/presentation/tenant_public/home/screens/tenant_home_screen/widgets/home_app_bar.dart';
import 'package:belluga_now/presentation/tenant_public/home/screens/tenant_home_screen/widgets/home_my_events_carousel.dart';
import 'package:belluga_now/presentation/tenant_public/home/screens/tenant_home_screen/widgets/favorite_section/favorites_section_builder.dart';
import 'package:belluga_now/presentation/tenant_public/home/screens/tenant_home_screen/widgets/invites_banner/invites_banner_builder.dart';
import 'package:belluga_now/presentation/tenant_public/schedule/screens/event_search_screen/models/invite_filter.dart';
import 'package:belluga_now/presentation/tenant_public/widgets/belluga_bottom_navigation_bar.dart';
import 'package:belluga_now/presentation/tenant_public/widgets/section_header.dart';
import 'package:belluga_now/presentation/shared/widgets/route_back_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value_builder.dart';

class TenantHomeScreen extends StatefulWidget {
  const TenantHomeScreen({super.key});

  @override
  State<TenantHomeScreen> createState() => _TenantHomeScreenState();
}

class _TenantHomeScreenState extends State<TenantHomeScreen> {
  final TenantHomeController _controller = GetIt.I.get<TenantHomeController>();

  @override
  void initState() {
    super.initState();
    _controller.init();
  }

  @override
  Widget build(BuildContext context) {
    final backPolicy = _buildBackPolicy(context);
    return RouteBackScope(
      backPolicy: backPolicy,
      child: Scaffold(
        bottomNavigationBar: const BellugaBottomNavigationBar(currentIndex: 0),
        body: SafeArea(
          top: false,
          child: HomeAgendaSection(
            builder: (context, slots) {
              return NestedScrollView(
                controller: _controller.scrollController,
                headerSliverBuilder: (context, innerBoxIsScrolled) => [
                  StreamValueBuilder<HomeLocationStatusState?>(
                    streamValue: _controller.homeLocationStatusStreamValue,
                    onNullWidget: _buildHomeAppBar(null),
                    builder: (context, status) => _buildHomeAppBar(status),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SectionHeader(
                            title: 'Seus Favoritos',
                          ),
                          const FavoritesSectionBuilder(),
                          InvitesBannerBuilder(
                            margin: const EdgeInsets.only(top: 12),
                            onPressed: () {
                              context.router.push(const InviteFlowRoute());
                            },
                          ),
                          const SizedBox(height: 12),
                          StreamValueBuilder(
                            streamValue:
                                _controller.myEventsFilteredStreamValue,
                            builder: (context, events) {
                              return HomeMyEventsCarousel(
                                events: events,
                                onSeeAll: _openConfirmedAgenda,
                                distanceLabelProvider:
                                    _controller.distanceLabelForMyEvent,
                              );
                            },
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
      ),
    );
  }

  void _openConfirmedAgenda() {
    context.router.push(
      EventSearchRoute(inviteFilter: InviteFilter.confirmedOnly),
    );
  }

  Widget _buildHomeAppBar(HomeLocationStatusState? status) {
    return HomeAppBar(
      appData: _controller.appData,
      locationStatus: status,
      onLocationStatusTap: () => _showHomeLocationOriginDialog(status),
    );
  }

  Future<void> _showHomeLocationOriginDialog(
    HomeLocationStatusState? status,
  ) async {
    if (status == null) {
      return;
    }
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(status.dialogTitle),
        content: Text(status.dialogMessage),
        actions: [
          TextButton(
            onPressed: () => context.router.maybePop(),
            child: const Text('Entendi'),
          ),
        ],
      ),
    );
  }

  RouteBackPolicy _buildBackPolicy(BuildContext context) {
    return DeterministicRouteBackPolicy(
      context.router,
      spec: RouteBackSpec(
        surfaceKind: BackSurfaceKind.rootOpenable,
        consumeLocalStateIfNeeded: _consumeScrollBackIfNeeded,
        noHistoryOutcome: RouteNoHistoryOutcome.requestExit(_requestExit),
        reentrancyKey: TenantHomeRoute.name,
      ),
    );
  }

  Future<bool> _consumeScrollBackIfNeeded() async {
    final scrollController = _controller.scrollController;
    if (scrollController.hasClients && scrollController.offset > 0) {
      await scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
      return true;
    }

    return false;
  }

  Future<void> _requestExit() async {
    final shouldExit = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Sair do app?'),
            content: const Text('Deseja fechar o aplicativo agora?'),
            actions: [
              TextButton(
                onPressed: () => context.router.pop(false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => context.router.pop(true),
                child: const Text('Sair'),
              ),
            ],
          ),
        ) ??
        false;

    if (shouldExit) {
      _performExitNavigation();
    }
  }

  void _performExitNavigation() {
    SystemNavigator.pop();
  }
}
