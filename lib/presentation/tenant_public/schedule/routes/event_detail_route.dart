import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/modular_app/modules/schedule_module.dart';
import 'package:belluga_now/presentation/tenant_public/schedule/routes/widgets/event_detail_loader.dart';
import 'package:flutter/material.dart';
import 'package:get_it_modular_with_auto_route/get_it_modular_with_auto_route.dart';

@RoutePage(name: 'EventDetailRoute')
class EventDetailRoutePage extends StatelessWidget {
  const EventDetailRoutePage({
    super.key,
    @PathParam('slug') required this.slug,
  });

  final String slug;

  @override
  Widget build(BuildContext context) {
    return ModuleScope<ScheduleModule>(
      child: EventDetailLoader(slug: slug),
    );
  }
}
