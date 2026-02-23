import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/presentation/tenant_admin/settings/screens/tenant_admin_settings_environment_snapshot_screen.dart';
import 'package:flutter/material.dart';

@RoutePage(name: 'TenantAdminSettingsEnvironmentSnapshotRoute')
class TenantAdminSettingsEnvironmentSnapshotRoutePage extends StatelessWidget {
  const TenantAdminSettingsEnvironmentSnapshotRoutePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const TenantAdminSettingsEnvironmentSnapshotScreen();
  }
}
