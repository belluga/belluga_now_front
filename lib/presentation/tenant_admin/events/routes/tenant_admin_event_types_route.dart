import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/presentation/tenant_admin/events/screens/tenant_admin_event_types_list_screen.dart';
import 'package:flutter/material.dart';

@RoutePage(name: 'TenantAdminEventTypesRoute')
class TenantAdminEventTypesRoutePage extends StatelessWidget {
  const TenantAdminEventTypesRoutePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const TenantAdminEventTypesListScreen();
  }
}
