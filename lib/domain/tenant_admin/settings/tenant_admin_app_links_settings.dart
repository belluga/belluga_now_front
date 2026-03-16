import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_dynamic_map_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_optional_text_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_trimmed_string_list_value.dart';

class TenantAdminAppLinksSettings {
  TenantAdminAppLinksSettings({
    required Map<String, dynamic> rawAppLinks,
    required String? androidPackageName,
    required List<String> androidSha256CertFingerprints,
    required String? iosTeamId,
    required String? iosBundleId,
    required List<String> iosPaths,
  })  : rawAppLinksValue = TenantAdminDynamicMapValue(rawAppLinks),
        androidPackageNameValue = _buildOptionalTextValue(androidPackageName),
        androidSha256CertFingerprintsValue = TenantAdminTrimmedStringListValue(
          _normalizeFingerprints(androidSha256CertFingerprints),
        ),
        iosTeamIdValue = _buildOptionalTextValue(iosTeamId),
        iosBundleIdValue = _buildOptionalTextValue(iosBundleId),
        iosPathsValue = TenantAdminTrimmedStringListValue(iosPaths);

  TenantAdminAppLinksSettings.empty()
      : rawAppLinksValue = TenantAdminDynamicMapValue(),
        androidPackageNameValue = null,
        androidSha256CertFingerprintsValue = TenantAdminTrimmedStringListValue(
          const <String>[],
        ),
        iosTeamIdValue = null,
        iosBundleIdValue = null,
        iosPathsValue = TenantAdminTrimmedStringListValue(const <String>[]);

  final TenantAdminDynamicMapValue rawAppLinksValue;
  final TenantAdminOptionalTextValue? androidPackageNameValue;
  final TenantAdminTrimmedStringListValue androidSha256CertFingerprintsValue;
  final TenantAdminOptionalTextValue? iosTeamIdValue;
  final TenantAdminOptionalTextValue? iosBundleIdValue;
  final TenantAdminTrimmedStringListValue iosPathsValue;

  Map<String, dynamic> get rawAppLinks => rawAppLinksValue.value;
  String? get androidPackageName => androidPackageNameValue?.nullableValue;
  List<String> get androidSha256CertFingerprints =>
      androidSha256CertFingerprintsValue.value;
  String? get iosTeamId => iosTeamIdValue?.nullableValue;
  String? get iosBundleId => iosBundleIdValue?.nullableValue;
  List<String> get iosPaths => iosPathsValue.value;

  TenantAdminAppLinksSettings applyValues({
    required String androidPackageName,
    required List<String> androidSha256CertFingerprints,
    required String? iosTeamId,
    required String? iosBundleId,
    required List<String> iosPaths,
  }) {
    final nextRaw = Map<String, dynamic>.from(rawAppLinks);

    final android = nextRaw['android'] is Map
        ? Map<String, dynamic>.from(nextRaw['android'] as Map)
        : <String, dynamic>{};
    android['package_name'] = androidPackageName.trim();
    android['sha256_cert_fingerprints'] =
        _normalizeFingerprints(androidSha256CertFingerprints);
    nextRaw['android'] = android;

    final ios = nextRaw['ios'] is Map
        ? Map<String, dynamic>.from(nextRaw['ios'] as Map)
        : <String, dynamic>{};
    ios['team_id'] = iosTeamId?.trim();
    ios['bundle_id'] = iosBundleId?.trim();
    ios['paths'] = iosPaths
        .map((entry) => entry.trim())
        .where((entry) => entry.isNotEmpty)
        .toList(growable: false);
    nextRaw['ios'] = ios;

    return TenantAdminAppLinksSettings(
      rawAppLinks: Map<String, dynamic>.unmodifiable(nextRaw),
      androidPackageName: androidPackageName,
      androidSha256CertFingerprints: androidSha256CertFingerprints,
      iosTeamId: iosTeamId,
      iosBundleId: iosBundleId,
      iosPaths: iosPaths,
    );
  }

  static TenantAdminOptionalTextValue? _buildOptionalTextValue(String? raw) {
    final normalized = raw?.trim();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }
    final value = TenantAdminOptionalTextValue()..parse(normalized);
    return value;
  }

  static List<String> _normalizeFingerprints(List<String> raw) {
    return raw
        .map((entry) => entry.trim().toUpperCase())
        .where((entry) => entry.isNotEmpty)
        .toSet()
        .toList(growable: false);
  }
}
