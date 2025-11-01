import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/presentation/common/widgets/main_logo.dart';
import 'package:belluga_now/presentation/tenant/widgets/belluga_bottom_navigation_bar.dart';
import 'package:belluga_now/presentation/tenant/widgets/floating_action_button_custom.dart';
import 'package:flutter/material.dart';

@RoutePage(name: 'TenantTabsRoute')
class TenantTabsRoutePage extends StatelessWidget {
  const TenantTabsRoutePage({super.key});

  @override
  Widget build(BuildContext context) {
    return AutoTabsRouter(
      routes: const [
        TenantHomeRoute(),
        ScheduleRoute(),
      ],
      builder: (context, child) {
        final tabsRouter = AutoTabsRouter.of(context);
        final theme = Theme.of(context);

        return AnimatedBuilder(
          animation: tabsRouter,
          builder: (context, _) {
            final config = _tabConfigForIndex(context, tabsRouter.activeIndex);
            final body = config.useSafeArea
                ? SafeArea(top: true, bottom: false, child: child)
                : child;

            return Scaffold(
              backgroundColor:
                  config.backgroundColor ?? theme.colorScheme.surface,
              extendBody: true,
              appBar: _AnimatedTabAppBar(appBar: config.appBar),
              floatingActionButton:
                  config.showFab ? const FloatingActionButtonCustom() : null,
              body: body,
              bottomNavigationBar: BellugaBottomNavigationBar(
                currentIndex: tabsRouter.activeIndex,
              ),
            );
          },
        );
      },
    );
  }
}

class _AnimatedTabAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const _AnimatedTabAppBar({this.appBar});

  final PreferredSizeWidget? appBar;

  @override
  Size get preferredSize =>
      Size.fromHeight(appBar?.preferredSize.height ?? kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, animation) => SizeTransition(
        sizeFactor: animation,
        axisAlignment: -1,
        child: child,
      ),
      child: appBar ?? const SizedBox.shrink(),
    );
  }
}

class _TabScaffoldConfig {
  const _TabScaffoldConfig({
    this.appBar,
    this.backgroundColor,
    this.showFab = false,
    this.useSafeArea = true,
  });

  final PreferredSizeWidget? appBar;
  final Color? backgroundColor;
  final bool showFab;
  final bool useSafeArea;
}

_TabScaffoldConfig _tabConfigForIndex(BuildContext context, int index) {
  switch (index) {
    case 0:
      return _TabScaffoldConfig(
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
        showFab: true,
      );
    case 1:
      return _TabScaffoldConfig(
        appBar: AppBar(
          titleSpacing: 16,
          automaticallyImplyLeading: false,
          title: const MainLogo(),
          actions: [
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () => context.pushRoute(EventSearchRoute()),
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
      );
    default:
      return const _TabScaffoldConfig();
  }
}
