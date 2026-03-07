import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_event.dart';
import 'package:belluga_now/presentation/tenant_admin/events/screens/tenant_admin_event_type_form_screen.dart';
import 'package:flutter/material.dart';

@RoutePage(name: 'TenantAdminEventTypeEditRoute')
class TenantAdminEventTypeEditRoutePage extends StatelessWidget {
  const TenantAdminEventTypeEditRoutePage({
    required this.type,
    super.key,
  });

  final TenantAdminEventType type;

  @override
  Widget build(BuildContext context) {
    return TenantAdminEventTypeFormScreen(existingType: type);
  }
}
