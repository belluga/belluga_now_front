import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_event.dart';
import 'package:belluga_now/presentation/tenant_admin/events/screens/tenant_admin_event_form_screen.dart';
import 'package:flutter/material.dart';

@RoutePage(name: 'TenantAdminEventEditRoute')
class TenantAdminEventEditRoutePage extends StatelessWidget {
  const TenantAdminEventEditRoutePage({
    required this.event,
    super.key,
  });

  final TenantAdminEvent event;

  @override
  Widget build(BuildContext context) {
    return TenantAdminEventFormScreen(existingEvent: event);
  }
}
