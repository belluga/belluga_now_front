import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/modular_app/modules/schedule_module.dart';
import 'package:belluga_now/presentation/tenant/schedule/screens/event_search_screen/controllers/event_search_screen_controller.dart';
import 'package:belluga_now/presentation/tenant/schedule/screens/event_search_screen/event_search_screen.dart';
import 'package:belluga_now/presentation/tenant/schedule/screens/event_search_screen/models/invite_filter.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:get_it_modular_with_auto_route/get_it_modular_with_auto_route.dart';

@RoutePage()
class EventSearchRoute extends StatelessWidget {
  const EventSearchRoute({
    super.key,
    this.startSearchActive = false,
    this.initialSearchQuery,
    this.inviteFilter = InviteFilter.none,
    this.startWithHistory = false,
  });

  final bool startSearchActive;
  final String? initialSearchQuery;
  final InviteFilter inviteFilter;
  final bool startWithHistory;

  @override
  Widget build(BuildContext context) {
    return ModuleScope<ScheduleModule>(
      child: EventSearchScreen(
        controller: GetIt.I.get<EventSearchScreenController>(),
        startSearchActive: startSearchActive,
        initialSearchQuery: initialSearchQuery,
        inviteFilter: inviteFilter,
        startWithHistory: startWithHistory,
      ),
    );
  }
}
