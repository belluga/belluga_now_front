import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/modular_app/modules/schedule_module.dart';
import 'package:belluga_now/presentation/tenant/screens/schedule/screens/event_search_screen.dart';
import 'package:flutter/material.dart';
import 'package:get_it_modular_with_auto_route/get_it_modular_with_auto_route.dart';

@RoutePage()
class EventSearchRoute extends StatelessWidget {
  const EventSearchRoute({super.key});

  @override
  Widget build(BuildContext context) {
    return const ModuleScope<ScheduleModule>(
      child: EventSearchScreen(),
    );
  }
}
