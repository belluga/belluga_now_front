import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_android_app_identifier_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_dynamic_map_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_ios_bundle_identifier_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_ios_team_id_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_sha256_fingerprint_list_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_trimmed_string_list_value.dart';

typedef TenantAdminAppLinksSettingsPrimString = String;
typedef TenantAdminAppLinksSettingsPrimInt = int;
typedef TenantAdminAppLinksSettingsPrimBool = bool;
typedef TenantAdminAppLinksSettingsPrimDouble = double;
typedef TenantAdminAppLinksSettingsPrimDateTime = DateTime;
typedef TenantAdminAppLinksSettingsPrimDynamic = dynamic;

class TenantAdminAppLinksSettings {
  static const List<TenantAdminAppLinksSettingsPrimString> canonicalIosPaths =
      <TenantAdminAppLinksSettingsPrimString>[
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
          const <TenantAdminAppLinksSettingsPrimString>[],
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

  Map<TenantAdminAppLinksSettingsPrimString,
          TenantAdminAppLinksSettingsPrimDynamic>
      get rawAppLinks => rawAppLinksValue.value;
  TenantAdminAppLinksSettingsPrimString? get androidAppIdentifier =>
      androidAppIdentifierValue?.value;
  TenantAdminAppLinksSettingsPrimString? get androidPackageName =>
      androidAppIdentifier;
  List<TenantAdminAppLinksSettingsPrimString>
      get androidSha256CertFingerprints =>
          androidSha256CertFingerprintsValue.value;
  TenantAdminAppLinksSettingsPrimString? get iosTeamId => iosTeamIdValue?.value;
  TenantAdminAppLinksSettingsPrimString? get iosBundleId =>
      iosBundleIdValue?.value;
  List<TenantAdminAppLinksSettingsPrimString> get iosPaths =>
      iosPathsValue.value;

  TenantAdminAppLinksSettings applyValues({
    required TenantAdminAppLinksSettingsPrimString? androidAppIdentifier,
    required List<TenantAdminAppLinksSettingsPrimString>
        androidSha256CertFingerprints,
    required TenantAdminAppLinksSettingsPrimString? iosTeamId,
    required TenantAdminAppLinksSettingsPrimString? iosBundleId,
    required List<TenantAdminAppLinksSettingsPrimString> iosPaths,
  }) {
    final nextRaw = Map<TenantAdminAppLinksSettingsPrimString,
        TenantAdminAppLinksSettingsPrimDynamic>.from(rawAppLinks);

    final android = nextRaw['android'] is Map
        ? Map<TenantAdminAppLinksSettingsPrimString,
                TenantAdminAppLinksSettingsPrimDynamic>.from(
            nextRaw['android'] as Map)
        : <TenantAdminAppLinksSettingsPrimString,
            TenantAdminAppLinksSettingsPrimDynamic>{};
    android['sha256_cert_fingerprints'] = TenantAdminSha256FingerprintListValue(
      androidSha256CertFingerprints,
    ).value;
    nextRaw['android'] = android;

    final ios = nextRaw['ios'] is Map
        ? Map<TenantAdminAppLinksSettingsPrimString,
            TenantAdminAppLinksSettingsPrimDynamic>.from(nextRaw['ios'] as Map)
        : <TenantAdminAppLinksSettingsPrimString,
            TenantAdminAppLinksSettingsPrimDynamic>{};
    ios['team_id'] = iosTeamId?.trim();
    ios['paths'] = _sanitizeIosPaths(iosPaths);
    nextRaw['ios'] = ios;

    return TenantAdminAppLinksSettings(
      rawAppLinksValue: TenantAdminDynamicMapValue(
        Map<TenantAdminAppLinksSettingsPrimString,
            TenantAdminAppLinksSettingsPrimDynamic>.unmodifiable(nextRaw),
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
    required TenantAdminAppLinksSettingsPrimString? androidAppIdentifier,
    required TenantAdminAppLinksSettingsPrimString? iosBundleId,
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
    TenantAdminAppLinksSettingsPrimString? raw,
  ) {
    final normalized = raw?.trim();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }
    final value = TenantAdminAndroidAppIdentifierValue()..parse(normalized);
    return value;
  }

  static TenantAdminIosBundleIdentifierValue? _buildIosBundleIdentifierValue(
    TenantAdminAppLinksSettingsPrimString? raw,
  ) {
    final normalized = raw?.trim();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }
    final value = TenantAdminIosBundleIdentifierValue()..parse(normalized);
    return value;
  }

  static TenantAdminIosTeamIdValue? _buildIosTeamIdValue(
      TenantAdminAppLinksSettingsPrimString? raw) {
    final normalized = raw?.trim();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }
    final value = TenantAdminIosTeamIdValue()..parse(normalized);
    return value;
  }

  static List<TenantAdminAppLinksSettingsPrimString> _sanitizeIosPaths(
      List<TenantAdminAppLinksSettingsPrimString> raw) {
    final selected = TenantAdminTrimmedStringListValue(raw).value.toSet();
    final sanitized = <TenantAdminAppLinksSettingsPrimString>[];
    for (final canonical in canonicalIosPaths) {
      if (selected.contains(canonical)) {
        sanitized.add(canonical);
      }
    }

    if (sanitized.isEmpty) {
      return List<TenantAdminAppLinksSettingsPrimString>.from(canonicalIosPaths,
          growable: false);
    }

    return sanitized;
  }
}
