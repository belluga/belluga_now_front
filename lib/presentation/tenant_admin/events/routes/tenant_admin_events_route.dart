import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/presentation/tenant_admin/events/screens/tenant_admin_events_screen.dart';
import 'package:flutter/material.dart';

@RoutePage(name: 'TenantAdminEventsRoute')
class TenantAdminEventsRoutePage extends StatelessWidget {
  const TenantAdminEventsRoutePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const TenantAdminEventsScreen();
  }
}
