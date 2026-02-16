import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/presentation/tenant_admin/settings/screens/tenant_admin_settings_screen.dart';
import 'package:flutter/material.dart';

@RoutePage(name: 'TenantAdminSettingsRoute')
class TenantAdminSettingsRoutePage extends StatelessWidget {
  const TenantAdminSettingsRoutePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const TenantAdminSettingsScreen();
  }
}
