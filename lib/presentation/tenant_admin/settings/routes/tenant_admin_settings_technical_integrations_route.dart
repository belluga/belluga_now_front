import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/presentation/tenant_admin/settings/models/tenant_admin_settings_integration_section.dart';
import 'package:belluga_now/presentation/tenant_admin/settings/screens/tenant_admin_settings_technical_integrations_screen.dart';
import 'package:flutter/material.dart';

@RoutePage(name: 'TenantAdminSettingsTechnicalIntegrationsRoute')
class TenantAdminSettingsTechnicalIntegrationsRoutePage
    extends StatelessWidget {
  const TenantAdminSettingsTechnicalIntegrationsRoutePage({
    super.key,
    this.initialSection = TenantAdminSettingsIntegrationSection.firebase,
  });

  final TenantAdminSettingsIntegrationSection initialSection;

  @override
  Widget build(BuildContext context) {
    return TenantAdminSettingsTechnicalIntegrationsScreen(
      initialSection: initialSection,
    );
  }
}
