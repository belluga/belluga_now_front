import 'package:flutter/material.dart';

class TenantAdminSettingsKeys {
  const TenantAdminSettingsKeys._();

  static const hubList = ValueKey('tenant_admin_settings_hub_list');
  static const hubCardPreferences =
      ValueKey('tenant_admin_settings_hub_card_preferences');
  static const hubCardVisualIdentity =
      ValueKey('tenant_admin_settings_hub_card_visual_identity');
  static const hubCardDomains =
      ValueKey('tenant_admin_settings_hub_card_domains');
  static const hubCardTechnicalIntegrations =
      ValueKey('tenant_admin_settings_hub_card_technical_integrations');
  static const hubCardEnvironmentSnapshot =
      ValueKey('tenant_admin_settings_hub_card_environment_snapshot');

  static const hubActionPreferences =
      ValueKey('tenant_admin_settings_hub_action_preferences');
  static const hubActionVisualIdentity =
      ValueKey('tenant_admin_settings_hub_action_visual_identity');
  static const hubActionDomains =
      ValueKey('tenant_admin_settings_hub_action_domains');
  static const hubActionTechnicalIntegrations =
      ValueKey('tenant_admin_settings_hub_action_technical_integrations');
  static const hubActionEnvironmentSnapshot =
      ValueKey('tenant_admin_settings_hub_action_environment_snapshot');

  static const hubIntegrationFirebase =
      ValueKey('tenant_admin_settings_hub_integration_firebase');
  static const hubIntegrationResend =
      ValueKey('tenant_admin_settings_hub_integration_resend');
  static const hubIntegrationAppLinks =
      ValueKey('tenant_admin_settings_hub_integration_app_links');
  static const hubIntegrationTelemetry =
      ValueKey('tenant_admin_settings_hub_integration_telemetry');

  static const localPreferencesScreen =
      ValueKey('tenant_admin_settings_local_preferences_screen');
  static const visualIdentityScreen =
      ValueKey('tenant_admin_settings_visual_identity_screen');
  static const domainsScreen = ValueKey('tenant_admin_settings_domains_screen');
  static const technicalIntegrationsScreen =
      ValueKey('tenant_admin_settings_technical_integrations_screen');
  static const environmentSnapshotScreen =
      ValueKey('tenant_admin_settings_environment_snapshot_screen');

  static const localPreferencesScopedAppBar =
      ValueKey('tenant_admin_settings_local_preferences_scoped_app_bar');
  static const localPreferencesBackButton =
      ValueKey('tenant_admin_settings_local_preferences_back_button');
  static const localPreferencesDefaultOriginLatField =
      ValueKey('tenant_admin_settings_local_preferences_default_origin_lat');
  static const localPreferencesDefaultOriginLngField =
      ValueKey('tenant_admin_settings_local_preferences_default_origin_lng');
  static const localPreferencesDefaultOriginLabelField =
      ValueKey('tenant_admin_settings_local_preferences_default_origin_label');
  static const localPreferencesSelectOnMapButton =
      ValueKey('tenant_admin_settings_local_preferences_select_on_map');
  static const localPreferencesSaveOriginButton =
      ValueKey('tenant_admin_settings_local_preferences_save_origin');
  static const localPreferencesMapFiltersCard =
      ValueKey('tenant_admin_settings_local_preferences_map_filters_card');
  static const localPreferencesAddMapFilterButton =
      ValueKey('tenant_admin_settings_local_preferences_add_map_filter_button');
  static ValueKey<String> localPreferencesMapFilterRow(int index) => ValueKey(
        'tenant_admin_settings_local_preferences_map_filter_row_$index',
      );
  static ValueKey<String> localPreferencesMapFilterVisualPreview(int index) =>
      ValueKey(
        'tenant_admin_settings_local_preferences_map_filter_visual_preview_$index',
      );
  static const visualIdentityScopedAppBar =
      ValueKey('tenant_admin_settings_visual_identity_scoped_app_bar');
  static const visualIdentityBackButton =
      ValueKey('tenant_admin_settings_visual_identity_back_button');
  static const domainsScopedAppBar =
      ValueKey('tenant_admin_settings_domains_scoped_app_bar');
  static const domainsBackButton =
      ValueKey('tenant_admin_settings_domains_back_button');
  static const domainsPathField =
      ValueKey('tenant_admin_settings_domains_path_field');
  static const domainsAddButton =
      ValueKey('tenant_admin_settings_domains_add_button');
  static const domainsLoadMoreButton =
      ValueKey('tenant_admin_settings_domains_load_more_button');
  static ValueKey<String> domainsRow(int index) =>
      ValueKey('tenant_admin_settings_domains_row_$index');
  static ValueKey<String> domainsStatusChip(int index) =>
      ValueKey('tenant_admin_settings_domains_status_chip_$index');
  static ValueKey<String> domainsDeleteButton(int index) =>
      ValueKey('tenant_admin_settings_domains_delete_button_$index');
  static const technicalIntegrationsScopedAppBar =
      ValueKey('tenant_admin_settings_technical_integrations_scoped_app_bar');
  static const technicalIntegrationsBackButton =
      ValueKey('tenant_admin_settings_technical_integrations_back_button');
  static const technicalIntegrationsAppLinksSection = ValueKey(
      'tenant_admin_settings_technical_integrations_app_links_section');
  static const technicalIntegrationsResendSection =
      ValueKey('tenant_admin_settings_technical_integrations_resend_section');
  static const technicalIntegrationsResendTokenEdit = ValueKey(
    'tenant_admin_settings_technical_integrations_resend_token_edit',
  );
  static const technicalIntegrationsResendFromEdit = ValueKey(
    'tenant_admin_settings_technical_integrations_resend_from_edit',
  );
  static const technicalIntegrationsResendToEdit = ValueKey(
    'tenant_admin_settings_technical_integrations_resend_to_edit',
  );
  static const technicalIntegrationsResendCcEdit = ValueKey(
    'tenant_admin_settings_technical_integrations_resend_cc_edit',
  );
  static const technicalIntegrationsResendBccEdit = ValueKey(
    'tenant_admin_settings_technical_integrations_resend_bcc_edit',
  );
  static const technicalIntegrationsResendReplyToEdit = ValueKey(
    'tenant_admin_settings_technical_integrations_resend_reply_to_edit',
  );
  static const technicalIntegrationsSaveResend = ValueKey(
    'tenant_admin_settings_technical_integrations_save_resend',
  );
  static const technicalIntegrationsAppLinksAndroidPackageEdit = ValueKey(
    'tenant_admin_settings_technical_integrations_app_links_android_package_edit',
  );
  static const technicalIntegrationsAppLinksFingerprintsEdit = ValueKey(
    'tenant_admin_settings_technical_integrations_app_links_fingerprints_edit',
  );
  static const technicalIntegrationsAppLinksIosTeamIdEdit = ValueKey(
    'tenant_admin_settings_technical_integrations_app_links_ios_team_id_edit',
  );
  static const technicalIntegrationsAppLinksIosBundleIdEdit = ValueKey(
    'tenant_admin_settings_technical_integrations_app_links_ios_bundle_id_edit',
  );
  static const technicalIntegrationsAppLinksIosPathsEdit = ValueKey(
    'tenant_admin_settings_technical_integrations_app_links_ios_paths_edit',
  );
  static const technicalIntegrationsSaveAppLinks = ValueKey(
    'tenant_admin_settings_technical_integrations_save_app_links',
  );
  static const environmentSnapshotScopedAppBar =
      ValueKey('tenant_admin_settings_environment_snapshot_scoped_app_bar');
  static const environmentSnapshotBackButton =
      ValueKey('tenant_admin_settings_environment_snapshot_back_button');

  static const brandingPrimaryField =
      ValueKey('tenant_admin_settings_branding_primary_field');
  static const brandingSecondaryField =
      ValueKey('tenant_admin_settings_branding_secondary_field');
  static const brandingFaviconPreview =
      ValueKey('tenant_admin_settings_branding_favicon_preview');
  static const brandingPrimaryPickerButton =
      ValueKey('tenant_admin_settings_branding_primary_picker_button');
  static const brandingSecondaryPickerButton =
      ValueKey('tenant_admin_settings_branding_secondary_picker_button');
}
