import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/presentation/common/widgets/main_logo.dart';
import 'package:flutter/material.dart';

class NavTabDefinition {
  const NavTabDefinition({
    required this.icon,
    required this.label,
    required this.appBarBuilder,
    this.showFab = false,
  });

  final IconData icon;
  final String label;
  final PreferredSizeWidget? Function(BuildContext) appBarBuilder;
  final bool showFab;
}

List<NavTabDefinition> navTabDefinitions() {
  return [
    NavTabDefinition(
      icon: Icons.home_outlined,
      label: 'Inicio',
      showFab: true,
      appBarBuilder: (context) => AppBar(
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
    ),
    NavTabDefinition(
      icon: Icons.calendar_month_outlined,
      label: 'Agenda',
      appBarBuilder: (context) => AppBar(
        titleSpacing: 16,
        automaticallyImplyLeading: false,
        title: const MainLogo(),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => context.pushRoute(const EventSearchRoute()),
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
    ),
    NavTabDefinition(
      icon: Icons.shopping_basket_outlined,
      label: 'Mercado',
      appBarBuilder: _placeholderAppBar,
    ),
    NavTabDefinition(
      icon: Icons.travel_explore_outlined,
      label: 'Experiencias',
      appBarBuilder: _placeholderAppBar,
    ),
    NavTabDefinition(
      icon: Icons.menu_outlined,
      label: 'Menu',
      appBarBuilder: _placeholderAppBar,
    ),
  ];
}

PreferredSizeWidget _placeholderAppBar(BuildContext context) => AppBar(
      titleSpacing: 16,
      title: const MainLogo(),
    );
