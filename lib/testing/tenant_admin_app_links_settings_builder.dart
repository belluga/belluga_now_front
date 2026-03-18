import 'package:belluga_now/domain/tenant_admin/settings/tenant_admin_app_links_settings.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_android_app_identifier_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_dynamic_map_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_ios_bundle_identifier_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_ios_team_id_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_sha256_fingerprint_list_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_trimmed_string_list_value.dart';

TenantAdminAppLinksSettings buildTenantAdminAppLinksSettings({
  required Map<String, dynamic> rawAppLinks,
  required String? androidAppIdentifier,
  required List<String> androidSha256CertFingerprints,
  required String? iosTeamId,
  required String? iosBundleId,
  required List<String> iosPaths,
}) {
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
    rawAppLinksValue: TenantAdminDynamicMapValue(rawAppLinks),
    androidAppIdentifierValue: androidAppIdentifierValue,
    androidSha256CertFingerprintsValue: TenantAdminSha256FingerprintListValue(
      androidSha256CertFingerprints,
    ),
    iosTeamIdValue: iosTeamIdValue,
    iosBundleIdValue: iosBundleIdValue,
    iosPathsValue: TenantAdminTrimmedStringListValue(iosPaths),
  );
}
