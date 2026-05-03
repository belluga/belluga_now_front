import 'package:belluga_now/domain/tenant_admin/settings/tenant_admin_app_links_settings.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_app_link_path_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_android_app_identifier_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_dynamic_map_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_ios_bundle_identifier_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_ios_team_id_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_sha256_fingerprint_value.dart';

TenantAdminAppLinksSettings buildTenantAdminAppLinksSettings({
  required Map<String, dynamic> rawAppLinks,
  required String? androidAppIdentifier,
  required List<String> androidSha256CertFingerprints,
  required String? iosTeamId,
  required String? iosBundleId,
  required List<String> iosPaths,
  bool? androidPublicationEnabled,
  String? androidStoreUrl,
  bool? iosPublicationEnabled,
  String? iosStoreUrl,
}) {
  final normalizedRaw = Map<String, dynamic>.from(rawAppLinks);
  final androidRaw = normalizedRaw['android'] is Map
      ? Map<String, dynamic>.from(normalizedRaw['android'] as Map)
      : <String, dynamic>{};
  if (androidPublicationEnabled != null) {
    androidRaw['enabled'] = androidPublicationEnabled;
  }
  if (androidStoreUrl != null) {
    androidRaw['store_url'] = androidStoreUrl.trim();
  }
  normalizedRaw['android'] = androidRaw;

  final iosRaw = normalizedRaw['ios'] is Map
      ? Map<String, dynamic>.from(normalizedRaw['ios'] as Map)
      : <String, dynamic>{};
  if (iosPublicationEnabled != null) {
    iosRaw['enabled'] = iosPublicationEnabled;
  }
  if (iosStoreUrl != null) {
    iosRaw['store_url'] = iosStoreUrl.trim();
  }
  normalizedRaw['ios'] = iosRaw;

  TenantAdminAndroidAppIdentifierValue? androidAppIdentifierValue;
  final normalizedAndroid = androidAppIdentifier?.trim();
  if (normalizedAndroid != null && normalizedAndroid.isNotEmpty) {
    androidAppIdentifierValue = TenantAdminAndroidAppIdentifierValue()
      ..parse(normalizedAndroid);
  }

  TenantAdminIosTeamIdValue? iosTeamIdValue;
  final normalizedIosTeam = iosTeamId?.trim();
  if (normalizedIosTeam != null && normalizedIosTeam.isNotEmpty) {
    iosTeamIdValue = TenantAdminIosTeamIdValue()..parse(normalizedIosTeam);
  }

  TenantAdminIosBundleIdentifierValue? iosBundleIdValue;
  final normalizedIosBundle = iosBundleId?.trim();
  if (normalizedIosBundle != null && normalizedIosBundle.isNotEmpty) {
    iosBundleIdValue = TenantAdminIosBundleIdentifierValue()
      ..parse(normalizedIosBundle);
  }

  return TenantAdminAppLinksSettings(
    rawAppLinksValue: TenantAdminDynamicMapValue(normalizedRaw),
    androidAppIdentifierValue: androidAppIdentifierValue,
    androidSha256CertFingerprintValues: androidSha256CertFingerprints
        .map(
          (entry) => TenantAdminSha256FingerprintValue()..parse(entry),
        )
        .toList(growable: false),
    iosTeamIdValue: iosTeamIdValue,
    iosBundleIdValue: iosBundleIdValue,
    iosPathValues: iosPaths
        .map(
          (entry) => TenantAdminAppLinkPathValue()..parse(entry),
        )
        .toList(growable: false),
  );
}
