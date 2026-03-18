import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_android_app_identifier_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_dynamic_map_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_ios_bundle_identifier_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_ios_team_id_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_sha256_fingerprint_list_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_trimmed_string_list_value.dart';

class TenantAdminAppLinksSettings {
  static const List<String> canonicalIosPaths = <String>[
    '/invite*',
    '/convites*',
    '/agenda*',
    '/agenda/evento/*',
    '/mapa*',
    '/profile*',
    '/home',
    '/',
  ];

  TenantAdminAppLinksSettings({
    required this.rawAppLinksValue,
    required this.androidAppIdentifierValue,
    required TenantAdminSha256FingerprintListValue
        androidSha256CertFingerprintsValue,
    required this.iosTeamIdValue,
    required this.iosBundleIdValue,
    required TenantAdminTrimmedStringListValue iosPathsValue,
  })  : androidSha256CertFingerprintsValue =
            TenantAdminSha256FingerprintListValue(
          androidSha256CertFingerprintsValue.value,
        ),
        iosPathsValue = TenantAdminTrimmedStringListValue(
          _sanitizeIosPaths(iosPathsValue.value),
        );

  TenantAdminAppLinksSettings.empty()
      : rawAppLinksValue = TenantAdminDynamicMapValue(),
        androidAppIdentifierValue = null,
        androidSha256CertFingerprintsValue =
            TenantAdminSha256FingerprintListValue(
          const <String>[],
        ),
        iosTeamIdValue = null,
        iosBundleIdValue = null,
        iosPathsValue = TenantAdminTrimmedStringListValue(canonicalIosPaths);

  final TenantAdminDynamicMapValue rawAppLinksValue;
  final TenantAdminAndroidAppIdentifierValue? androidAppIdentifierValue;
  final TenantAdminSha256FingerprintListValue
      androidSha256CertFingerprintsValue;
  final TenantAdminIosTeamIdValue? iosTeamIdValue;
  final TenantAdminIosBundleIdentifierValue? iosBundleIdValue;
  final TenantAdminTrimmedStringListValue iosPathsValue;

  Map<String, dynamic> get rawAppLinks => rawAppLinksValue.value;
  String? get androidAppIdentifier => androidAppIdentifierValue?.value;
  String? get androidPackageName => androidAppIdentifier;
  List<String> get androidSha256CertFingerprints =>
      androidSha256CertFingerprintsValue.value;
  String? get iosTeamId => iosTeamIdValue?.value;
  String? get iosBundleId => iosBundleIdValue?.value;
  List<String> get iosPaths => iosPathsValue.value;

  TenantAdminAppLinksSettings applyValues({
    required String? androidAppIdentifier,
    required List<String> androidSha256CertFingerprints,
    required String? iosTeamId,
    required String? iosBundleId,
    required List<String> iosPaths,
  }) {
    final nextRaw = Map<String, dynamic>.from(rawAppLinks);

    final android = nextRaw['android'] is Map
        ? Map<String, dynamic>.from(nextRaw['android'] as Map)
        : <String, dynamic>{};
    android['sha256_cert_fingerprints'] = TenantAdminSha256FingerprintListValue(
      androidSha256CertFingerprints,
    ).value;
    nextRaw['android'] = android;

    final ios = nextRaw['ios'] is Map
        ? Map<String, dynamic>.from(nextRaw['ios'] as Map)
        : <String, dynamic>{};
    ios['team_id'] = iosTeamId?.trim();
    ios['paths'] = _sanitizeIosPaths(iosPaths);
    nextRaw['ios'] = ios;

    return TenantAdminAppLinksSettings(
      rawAppLinksValue: TenantAdminDynamicMapValue(
        Map<String, dynamic>.unmodifiable(nextRaw),
      ),
      androidAppIdentifierValue:
          _buildAndroidIdentifierValue(androidAppIdentifier),
      androidSha256CertFingerprintsValue: TenantAdminSha256FingerprintListValue(
        androidSha256CertFingerprints,
      ),
      iosTeamIdValue: _buildIosTeamIdValue(iosTeamId),
      iosBundleIdValue: _buildIosBundleIdentifierValue(iosBundleId),
      iosPathsValue: TenantAdminTrimmedStringListValue(
        _sanitizeIosPaths(iosPaths),
      ),
    );
  }

  TenantAdminAppLinksSettings withAppDomainIdentifiers({
    required String? androidAppIdentifier,
    required String? iosBundleId,
  }) {
    return TenantAdminAppLinksSettings(
      rawAppLinksValue: TenantAdminDynamicMapValue(rawAppLinks),
      androidAppIdentifierValue:
          _buildAndroidIdentifierValue(androidAppIdentifier),
      androidSha256CertFingerprintsValue: TenantAdminSha256FingerprintListValue(
        androidSha256CertFingerprints,
      ),
      iosTeamIdValue: _buildIosTeamIdValue(iosTeamId),
      iosBundleIdValue: _buildIosBundleIdentifierValue(iosBundleId),
      iosPathsValue: TenantAdminTrimmedStringListValue(
        _sanitizeIosPaths(iosPaths),
      ),
    );
  }

  static TenantAdminAndroidAppIdentifierValue? _buildAndroidIdentifierValue(
    String? raw,
  ) {
    final normalized = raw?.trim();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }
    final value = TenantAdminAndroidAppIdentifierValue()..parse(normalized);
    return value;
  }

  static TenantAdminIosBundleIdentifierValue? _buildIosBundleIdentifierValue(
    String? raw,
  ) {
    final normalized = raw?.trim();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }
    final value = TenantAdminIosBundleIdentifierValue()..parse(normalized);
    return value;
  }

  static TenantAdminIosTeamIdValue? _buildIosTeamIdValue(String? raw) {
    final normalized = raw?.trim();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }
    final value = TenantAdminIosTeamIdValue()..parse(normalized);
    return value;
  }

  static List<String> _sanitizeIosPaths(List<String> raw) {
    final selected = TenantAdminTrimmedStringListValue(raw).value.toSet();
    final sanitized = <String>[];
    for (final canonical in canonicalIosPaths) {
      if (selected.contains(canonical)) {
        sanitized.add(canonical);
      }
    }

    if (sanitized.isEmpty) {
      return List<String>.from(canonicalIosPaths, growable: false);
    }

    return sanitized;
  }
}
