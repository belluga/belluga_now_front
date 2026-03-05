import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/presentation/tenant_admin/events/screens/tenant_admin_event_type_form_screen.dart';
import 'package:flutter/material.dart';

@RoutePage(name: 'TenantAdminEventTypeCreateRoute')
class TenantAdminEventTypeCreateRoutePage extends StatelessWidget {
  const TenantAdminEventTypeCreateRoutePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const TenantAdminEventTypeFormScreen();
  }
}
