import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:flutter/material.dart';

class BellugaBottomNavigationBar extends StatelessWidget {
  const BellugaBottomNavigationBar({
    super.key,
    required this.currentIndex,
  });

  final int currentIndex;

  static const double _navHeight = 64;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return NavigationBarTheme(
      data: NavigationBarThemeData(
        height: _navHeight,
        backgroundColor: scheme.surface,
        elevation: 0,
        indicatorColor: scheme.primaryContainer.withValues(alpha: 0.8),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => theme.textTheme.labelSmall?.copyWith(
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? scheme.onPrimaryContainer
                : scheme.onSurfaceVariant,
          ),
        ),
      ),
      child: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) => _onItemTapped(context, index),
        animationDuration: Duration.zero,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'Agenda',
          ),
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: 'Mapa',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_outlined),
            selectedIcon: Icon(Icons.menu),
            label: 'Menu',
          ),
        ],
      ),
    );
  }

  void _onItemTapped(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.router.replaceAll([const TenantHomeRoute()]);
        break;
      default:
        context.router.replaceAll([
          if (index == 1) const ScheduleRoute(),
          if (index == 2) const CityMapRoute(),
          if (index == 3) const TenantMenuRoute(),
        ]);
    }
  }
}
