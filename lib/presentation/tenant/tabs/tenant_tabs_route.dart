import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/presentation/tenant/widgets/belluga_bottom_navigation_bar.dart';
import 'package:belluga_now/presentation/tenant/widgets/floating_action_button_custom.dart';
import 'package:flutter/material.dart';

import 'widgets/animated_tab_app_bar.dart';
import 'widgets/tab_scaffold_config.dart';

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
            final config = tabConfigForIndex(tabsRouter.activeIndex);
            final body = config.useSafeArea
                ? SafeArea(top: true, bottom: false, child: child)
                : child;
            final appBar = config.buildAppBar(context);

            return Scaffold(
              backgroundColor:
                  config.backgroundColor ?? theme.colorScheme.surface,
              extendBody: true,
              appBar: AnimatedTabAppBar(appBar: appBar),
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
