import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/domain/app_data/app_data.dart';
import 'package:belluga_now/presentation/tenant/home/screens/tenant_home_screen/controllers/tenant_home_controller.dart';
import 'package:belluga_now/presentation/tenant/home/screens/tenant_home_screen/widgets/agenda_section/controllers/tenant_home_agenda_controller.dart';
import 'package:belluga_now/presentation/tenant/home/screens/tenant_home_screen/widgets/agenda_section/home_agenda_section.dart';
import 'package:belluga_now/presentation/tenant/home/screens/tenant_home_screen/widgets/home_app_bar.dart';
import 'package:belluga_now/presentation/tenant/home/screens/tenant_home_screen/widgets/home_my_events_carousel.dart';
import 'package:belluga_now/presentation/tenant/home/screens/tenant_home_screen/widgets/favorite_section/controllers/favorites_section_controller.dart';
import 'package:belluga_now/presentation/tenant/home/screens/tenant_home_screen/widgets/favorite_section/favorites_section_builder.dart';
import 'package:belluga_now/presentation/tenant/home/screens/tenant_home_screen/widgets/invites_banner/controllers/invites_banner_builder_controller.dart';
import 'package:belluga_now/presentation/tenant/home/screens/tenant_home_screen/widgets/invites_banner/invites_banner_builder.dart';
import 'package:belluga_now/presentation/tenant/schedule/screens/event_search_screen/models/invite_filter.dart';
import 'package:belluga_now/presentation/tenant/widgets/belluga_bottom_navigation_bar.dart';
import 'package:belluga_now/presentation/tenant/widgets/section_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
 

class TenantHomeScreen extends StatefulWidget {
  const TenantHomeScreen({super.key});

  @override
  State<TenantHomeScreen> createState() => _TenantHomeScreenState();
}

class _TenantHomeScreenState extends State<TenantHomeScreen> {
  final TenantHomeController _controller =
      GetIt.I.get<TenantHomeController>();
  final FavoritesSectionController _favoritesController =
      GetIt.I.get<FavoritesSectionController>();
  final InvitesBannerBuilderController _invitesBannerController =
      GetIt.I.get<InvitesBannerBuilderController>();
  final TenantHomeAgendaController _homeAgendaController =
      GetIt.I.get<TenantHomeAgendaController>();
  final AppData _appData = GetIt.I.get<AppData>();

  @override
  void initState() {
    super.initState();
    _controller.init();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          return;
        }
        _handleBackPressed();
      },
      child: Scaffold(
        bottomNavigationBar: const BellugaBottomNavigationBar(currentIndex: 0),
        body: SafeArea(
          top: false,
          child: HomeAgendaSection(
            controller: _homeAgendaController,
            builder: (context, slots) {
              return NestedScrollView(
                controller: _controller.scrollController,
                headerSliverBuilder: (context, innerBoxIsScrolled) => [
                  HomeAppBar(
                    appData: _appData,
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
                          FavoritesSectionBuilder(
                            controller: _favoritesController,
                          ),
                          InvitesBannerBuilder(
                            margin: const EdgeInsets.only(top: 12),
                            onPressed: () {
                              context.router.push(const InviteFlowRoute());
                            },
                            controller: _invitesBannerController,
                          ),
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
      ),
    );
  }

  void _openConfirmedAgenda() {
    context.router.push(
      EventSearchRoute(inviteFilter: InviteFilter.confirmedOnly),
    );
  }

  Future<bool> _handleBackPressed() async {
    final scrollController = _controller.scrollController;
    if (scrollController.hasClients && scrollController.offset > 0) {
      await scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
      return false;
    }

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
      await SystemNavigator.pop();
    }

    return false;
  }
}
