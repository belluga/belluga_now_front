import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/modular_app/modules/schedule_module.dart';
import 'package:belluga_now/presentation/tenant/schedule/screens/event_search_screen/event_search_screen.dart';
import 'package:belluga_now/presentation/tenant/schedule/screens/event_search_screen/models/invite_filter.dart';
import 'package:flutter/material.dart';
import 'package:get_it_modular_with_auto_route/get_it_modular_with_auto_route.dart';

@RoutePage()
class EventSearchRoute extends StatelessWidget {
  const EventSearchRoute({
    super.key,
    this.startSearchActive = false,
    this.inviteFilter = InviteFilter.none,
  });

  final bool startSearchActive;
  final InviteFilter inviteFilter;

  @override
  Widget build(BuildContext context) {
    return ModuleScope<ScheduleModule>(
      child: EventSearchScreen(
        startSearchActive: startSearchActive,
        inviteFilter: inviteFilter,
      ),
    );
  }
}
