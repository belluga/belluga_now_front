import 'package:flutter/material.dart';

class TenantAdminSettingsKeys {
  const TenantAdminSettingsKeys._();

  static const hubList = ValueKey('tenant_admin_settings_hub_list');
  static const hubCardPreferences =
      ValueKey('tenant_admin_settings_hub_card_preferences');
  static const hubCardVisualIdentity =
      ValueKey('tenant_admin_settings_hub_card_visual_identity');
  static const hubCardTechnicalIntegrations =
      ValueKey('tenant_admin_settings_hub_card_technical_integrations');
  static const hubCardEnvironmentSnapshot =
      ValueKey('tenant_admin_settings_hub_card_environment_snapshot');

  static const hubActionPreferences =
      ValueKey('tenant_admin_settings_hub_action_preferences');
  static const hubActionVisualIdentity =
      ValueKey('tenant_admin_settings_hub_action_visual_identity');
  static const hubActionTechnicalIntegrations =
      ValueKey('tenant_admin_settings_hub_action_technical_integrations');
  static const hubActionEnvironmentSnapshot =
      ValueKey('tenant_admin_settings_hub_action_environment_snapshot');

  static const hubIntegrationFirebase =
      ValueKey('tenant_admin_settings_hub_integration_firebase');
  static const hubIntegrationTelemetry =
      ValueKey('tenant_admin_settings_hub_integration_telemetry');

  static const localPreferencesScreen =
      ValueKey('tenant_admin_settings_local_preferences_screen');
  static const visualIdentityScreen =
      ValueKey('tenant_admin_settings_visual_identity_screen');
  static const technicalIntegrationsScreen =
      ValueKey('tenant_admin_settings_technical_integrations_screen');
  static const environmentSnapshotScreen =
      ValueKey('tenant_admin_settings_environment_snapshot_screen');

  static const localPreferencesScopedAppBar =
      ValueKey('tenant_admin_settings_local_preferences_scoped_app_bar');
  static const localPreferencesBackButton =
      ValueKey('tenant_admin_settings_local_preferences_back_button');
  static const visualIdentityScopedAppBar =
      ValueKey('tenant_admin_settings_visual_identity_scoped_app_bar');
  static const visualIdentityBackButton =
      ValueKey('tenant_admin_settings_visual_identity_back_button');
  static const technicalIntegrationsScopedAppBar =
      ValueKey('tenant_admin_settings_technical_integrations_scoped_app_bar');
  static const technicalIntegrationsBackButton =
      ValueKey('tenant_admin_settings_technical_integrations_back_button');
  static const environmentSnapshotScopedAppBar =
      ValueKey('tenant_admin_settings_environment_snapshot_scoped_app_bar');
  static const environmentSnapshotBackButton =
      ValueKey('tenant_admin_settings_environment_snapshot_back_button');

  static const brandingPrimaryField =
      ValueKey('tenant_admin_settings_branding_primary_field');
  static const brandingSecondaryField =
      ValueKey('tenant_admin_settings_branding_secondary_field');
  static const brandingPrimaryPickerButton =
      ValueKey('tenant_admin_settings_branding_primary_picker_button');
  static const brandingSecondaryPickerButton =
      ValueKey('tenant_admin_settings_branding_secondary_picker_button');
}
