import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/presentation/common/widgets/main_logo.dart';
import 'package:flutter/material.dart';

typedef TabAppBarBuilder = PreferredSizeWidget? Function(BuildContext context);
typedef TabActionBuilder = void Function(BuildContext context);

class TabScaffoldConfig {
  const TabScaffoldConfig({
    this.appBarBuilder,
    this.backgroundColor,
    this.showFab = false,
    this.useSafeArea = true,
  });

  final TabAppBarBuilder? appBarBuilder;
  final Color? backgroundColor;
  final bool showFab;
  final bool useSafeArea;

  PreferredSizeWidget? buildAppBar(BuildContext context) =>
      appBarBuilder?.call(context);
}

TabScaffoldConfig tabConfigForIndex(int index) {
  switch (index) {
    case 0:
      return TabScaffoldConfig(
        appBarBuilder: (context) => AppBar(
          titleSpacing: 16,
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
        showFab: true,
      );
    case 1:
      return TabScaffoldConfig(
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
      );
    default:
      return const TabScaffoldConfig();
  }
}
