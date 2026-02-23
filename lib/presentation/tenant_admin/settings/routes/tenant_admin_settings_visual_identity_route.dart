import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/presentation/tenant_admin/settings/screens/tenant_admin_settings_visual_identity_screen.dart';
import 'package:flutter/material.dart';

@RoutePage(name: 'TenantAdminSettingsVisualIdentityRoute')
class TenantAdminSettingsVisualIdentityRoutePage extends StatelessWidget {
  const TenantAdminSettingsVisualIdentityRoutePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const TenantAdminSettingsVisualIdentityScreen();
  }
}
