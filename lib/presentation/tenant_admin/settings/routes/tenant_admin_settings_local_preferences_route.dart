import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/presentation/tenant_admin/settings/screens/tenant_admin_settings_local_preferences_screen.dart';
import 'package:flutter/material.dart';

@RoutePage(name: 'TenantAdminSettingsLocalPreferencesRoute')
class TenantAdminSettingsLocalPreferencesRoutePage extends StatelessWidget {
  const TenantAdminSettingsLocalPreferencesRoutePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const TenantAdminSettingsLocalPreferencesScreen();
  }
}
