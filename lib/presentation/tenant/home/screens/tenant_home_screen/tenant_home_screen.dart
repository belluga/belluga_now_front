import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/presentation/common/widgets/main_logo.dart';
import 'package:belluga_now/presentation/tenant/home/screens/tenant_home_screen/controllers/tenant_home_controller.dart';
import 'package:belluga_now/presentation/tenant/home/screens/tenant_home_screen/widgets/favorites_section.dart';
import 'package:belluga_now/presentation/tenant/home/screens/tenant_home_screen/widgets/featured_events_section.dart';
import 'package:belluga_now/presentation/tenant/home/screens/tenant_home_screen/widgets/invites_banner_builder.dart';
import 'package:belluga_now/presentation/tenant/home/screens/tenant_home_screen/widgets/upcoming_events_section.dart';
import 'package:belluga_now/presentation/tenant/widgets/belluga_bottom_navigation_bar.dart';
import 'package:belluga_now/presentation/tenant/widgets/floating_action_button_custom.dart';
import 'package:belluga_now/presentation/tenant/widgets/section_header.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

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
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: const MainLogo(),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {},
            tooltip: 'Buscar',
          ),
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () {},
            tooltip: 'Notificações',
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: const FloatingActionButtonCustom(),
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
              FavoritesSection(controller: _controller),
              const SizedBox(height: 8),
              InvitesBannerBuilder(
                onPressed: _openInviteFlow,
                margin: const EdgeInsets.only(bottom: 16),
              ),
              SectionHeader(
                title: 'Seus Eventos',
                onPressed: _openMyEvents,
              ),
              FeaturedEventsSection(controller: _controller),
              const SizedBox(height: 16),
              SectionHeader(
                title: 'Próximos Eventos',
                onPressed: _openMyEvents,
              ),
              const SizedBox(height: 16),
              UpcomingEventsSection(
                controller: _controller,
                onExplore: _openMyEvents,
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

  void _openMyEvents() {
    context.router.push(const ScheduleRoute());
  }

  void _openEventDetailSlug(String slug) {
    context.router.push(EventDetailRoute(slug: slug));
  }
}
