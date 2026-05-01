import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_app_link_path_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_android_app_identifier_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_boolean_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_dynamic_map_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_ios_bundle_identifier_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_ios_team_id_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_optional_url_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_sha256_fingerprint_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_sha256_fingerprint_list_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_trimmed_string_list_value.dart';

class TenantAdminAppLinksSettings {
  static const List<String> canonicalIosPaths = <String>[
    '/invite*',
    '/convites*',
    '/agenda*',
    '/agenda/evento/*',
    '/mapa*',
    '/parceiro/*',
    '/profile*',
    '/home',
    '/',
  ];

  TenantAdminAppLinksSettings({
    required this.rawAppLinksValue,
    required this.androidAppIdentifierValue,
    required List<TenantAdminSha256FingerprintValue>
        androidSha256CertFingerprintValues,
    required this.iosTeamIdValue,
    required this.iosBundleIdValue,
    required List<TenantAdminAppLinkPathValue> iosPathValues,
  })  : androidSha256CertFingerprintsValue =
            _fingerprintListValue(androidSha256CertFingerprintValues),
        iosPathsValue = _sanitizeIosPaths(iosPathValues);

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

  TenantAdminDynamicMapValue get rawAppLinks => rawAppLinksValue;
  String? get androidAppIdentifier => androidAppIdentifierValue?.value;
  String? get androidPackageName => androidAppIdentifier;
  TenantAdminSha256FingerprintListValue get androidSha256CertFingerprints =>
      androidSha256CertFingerprintsValue;
  String? get iosTeamId => iosTeamIdValue?.value;
  String? get iosBundleId => iosBundleIdValue?.value;
  TenantAdminTrimmedStringListValue get iosPaths => iosPathsValue;
  bool get androidPublicationEnabled {
    final platformRaw = rawAppLinksValue.value['android'];
    if (platformRaw is! Map) {
      return false;
    }
    final value = platformRaw['enabled'];
    if (value is bool) {
      return value;
    }
    if (value is num) {
      return value != 0;
    }
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      return normalized == 'true' ||
          normalized == '1' ||
          normalized == 'yes' ||
          normalized == 'on';
    }
    return false;
  }

  bool get iosPublicationEnabled {
    final platformRaw = rawAppLinksValue.value['ios'];
    if (platformRaw is! Map) {
      return false;
    }
    final value = platformRaw['enabled'];
    if (value is bool) {
      return value;
    }
    if (value is num) {
      return value != 0;
    }
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      return normalized == 'true' ||
          normalized == '1' ||
          normalized == 'yes' ||
          normalized == 'on';
    }
    return false;
  }

  String? get androidStoreUrl {
    final platformRaw = rawAppLinksValue.value['android'];
    if (platformRaw is! Map) {
      return null;
    }
    final value = platformRaw['store_url'];
    if (value is! String) {
      return null;
    }
    final normalized = value.trim();
    return normalized.isEmpty ? null : normalized;
  }

  String? get iosStoreUrl {
    final platformRaw = rawAppLinksValue.value['ios'];
    if (platformRaw is! Map) {
      return null;
    }
    final value = platformRaw['store_url'];
    if (value is! String) {
      return null;
    }
    final normalized = value.trim();
    return normalized.isEmpty ? null : normalized;
  }

  TenantAdminAppLinksSettings applyValues({
    required TenantAdminAndroidAppIdentifierValue? androidAppIdentifier,
    required List<TenantAdminSha256FingerprintValue>
        androidSha256CertFingerprintValues,
    required TenantAdminIosTeamIdValue? iosTeamId,
    required TenantAdminIosBundleIdentifierValue? iosBundleId,
    required List<TenantAdminAppLinkPathValue> iosPathValues,
    TenantAdminBooleanValue? androidPublicationEnabled,
    TenantAdminOptionalUrlValue? androidStoreUrl,
    TenantAdminBooleanValue? iosPublicationEnabled,
    TenantAdminOptionalUrlValue? iosStoreUrl,
  }) {
    final nextRaw = Map<String, dynamic>.from(rawAppLinksValue.value);

    final android = nextRaw['android'] is Map
        ? Map<String, dynamic>.from(nextRaw['android'] as Map)
        : <String, dynamic>{};
    android['sha256_cert_fingerprints'] =
        _fingerprintListValue(androidSha256CertFingerprintValues).value;
    if (androidPublicationEnabled != null) {
      android['enabled'] = androidPublicationEnabled.value;
    }
    if (androidStoreUrl != null) {
      android['store_url'] = androidStoreUrl.nullableValue;
    }
    nextRaw['android'] = android;

    final ios = nextRaw['ios'] is Map
        ? Map<String, dynamic>.from(nextRaw['ios'] as Map)
        : <String, dynamic>{};
    ios['team_id'] = iosTeamId?.value;
    ios['paths'] = _sanitizeIosPaths(iosPathValues).value;
    if (iosPublicationEnabled != null) {
      ios['enabled'] = iosPublicationEnabled.value;
    }
    if (iosStoreUrl != null) {
      ios['store_url'] = iosStoreUrl.nullableValue;
    }
    nextRaw['ios'] = ios;

    TenantAdminAndroidAppIdentifierValue? parsedAndroidAppIdentifier;
    if (androidAppIdentifier != null) {
      final next = TenantAdminAndroidAppIdentifierValue();
      next.parse(androidAppIdentifier.value);
      parsedAndroidAppIdentifier = next;
    }

    TenantAdminIosTeamIdValue? parsedIosTeamId;
    if (iosTeamId != null) {
      final next = TenantAdminIosTeamIdValue();
      next.parse(iosTeamId.value);
      parsedIosTeamId = next;
    }

    TenantAdminIosBundleIdentifierValue? parsedIosBundleId;
    if (iosBundleId != null) {
      final next = TenantAdminIosBundleIdentifierValue();
      next.parse(iosBundleId.value);
      parsedIosBundleId = next;
    }

    return TenantAdminAppLinksSettings(
      rawAppLinksValue: TenantAdminDynamicMapValue(
        Map<String, dynamic>.unmodifiable(nextRaw),
      ),
      androidAppIdentifierValue: parsedAndroidAppIdentifier,
      androidSha256CertFingerprintValues: androidSha256CertFingerprintValues,
      iosTeamIdValue: parsedIosTeamId,
      iosBundleIdValue: parsedIosBundleId,
      iosPathValues: iosPathValues,
    );
  }

  TenantAdminAppLinksSettings withAppDomainIdentifiers({
    required TenantAdminAndroidAppIdentifierValue? androidAppIdentifier,
    required TenantAdminIosBundleIdentifierValue? iosBundleId,
  }) {
    TenantAdminAndroidAppIdentifierValue? parsedAndroidAppIdentifier;
    if (androidAppIdentifier != null) {
      final next = TenantAdminAndroidAppIdentifierValue();
      next.parse(androidAppIdentifier.value);
      parsedAndroidAppIdentifier = next;
    }

    TenantAdminIosBundleIdentifierValue? parsedIosBundleId;
    if (iosBundleId != null) {
      final next = TenantAdminIosBundleIdentifierValue();
      next.parse(iosBundleId.value);
      parsedIosBundleId = next;
    }

    TenantAdminIosTeamIdValue? parsedIosTeamId;
    if (iosTeamIdValue != null) {
      final next = TenantAdminIosTeamIdValue();
      next.parse(iosTeamIdValue!.value);
      parsedIosTeamId = next;
    }

    return TenantAdminAppLinksSettings(
      rawAppLinksValue: TenantAdminDynamicMapValue(rawAppLinksValue.value),
      androidAppIdentifierValue: parsedAndroidAppIdentifier,
      androidSha256CertFingerprintValues: androidSha256CertFingerprints
          .map(
            (entry) => TenantAdminSha256FingerprintValue()..parse(entry),
          )
          .toList(growable: false),
      iosTeamIdValue: parsedIosTeamId,
      iosBundleIdValue: parsedIosBundleId,
      iosPathValues: iosPaths
          .map(
            (entry) => TenantAdminAppLinkPathValue()..parse(entry),
          )
          .toList(growable: false),
    );
  }

  static TenantAdminTrimmedStringListValue _sanitizeIosPaths(
    List<TenantAdminAppLinkPathValue> rawValues,
  ) {
    final selected = rawValues.map((entry) => entry.value).toSet();
    final sanitized = <String>[];
    for (final canonical in canonicalIosPaths) {
      if (selected.contains(canonical)) {
        sanitized.add(canonical);
      }
    }

    if (sanitized.isEmpty) {
      return TenantAdminTrimmedStringListValue(canonicalIosPaths);
    }

    return TenantAdminTrimmedStringListValue(sanitized);
  }

  static TenantAdminSha256FingerprintListValue _fingerprintListValue(
    List<TenantAdminSha256FingerprintValue> rawValues,
  ) {
    return TenantAdminSha256FingerprintListValue(
      rawValues.map((entry) => entry.value),
    );
  }
}
