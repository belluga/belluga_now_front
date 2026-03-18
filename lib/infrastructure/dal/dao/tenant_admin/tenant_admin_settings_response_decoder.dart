import 'package:belluga_now/domain/tenant_admin/tenant_admin_settings.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_android_app_identifier_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_dynamic_map_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_ios_bundle_identifier_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_ios_team_id_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_sha256_fingerprint_list_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_trimmed_string_list_value.dart';
import 'package:belluga_now/infrastructure/dal/dao/http/raw_json_envelope_decoder.dart';

class TenantAdminSettingsResponseDecoder {
  const TenantAdminSettingsResponseDecoder({
    RawJsonEnvelopeDecoder? envelopeDecoder,
  }) : _envelopeDecoder = envelopeDecoder ?? const RawJsonEnvelopeDecoder();

  final RawJsonEnvelopeDecoder _envelopeDecoder;

  TenantAdminMapUiSettings decodeMapUiSettings(
    Object? rawResponse, {
    required Uri tenantOrigin,
  }) {
    final mapUi = _extractMapUiPayload(rawResponse);
    return _mapMapUiSettings(
      mapUi,
      tenantOrigin: tenantOrigin,
    );
  }

  TenantAdminAppLinksSettings decodeAppLinksSettings(
    Object? rawResponse, {
    TenantAdminAppDomainIdentifiers? appDomainIdentifiers,
  }) {
    final appLinks = _extractAppLinksPayload(rawResponse);
    return _mapAppLinksSettings(
      appLinks,
      appDomainIdentifiers:
          appDomainIdentifiers ?? TenantAdminAppDomainIdentifiers.empty(),
    );
  }

  TenantAdminAppDomainIdentifiers decodeAppDomainIdentifiers(
    Object? rawResponse,
  ) {
    final payload = _envelopeDecoder.decodeDataMap(
      rawResponse,
      label: 'app domain identifiers',
      emptyWhenDataIsNotMap: true,
    );
    final appDomainsRaw = payload['app_domains'];
    if (appDomainsRaw is! Map) {
      return TenantAdminAppDomainIdentifiers.empty();
    }

    final appDomains = Map<String, dynamic>.from(appDomainsRaw);
    return TenantAdminAppDomainIdentifiers(
      androidAppIdentifier: _normalizeOptionalText(appDomains['android']),
      iosBundleId: _normalizeOptionalText(appDomains['ios']),
    );
  }

  String decodeMapFilterImageUpload(
    Object? rawResponse, {
    required String key,
    required Uri tenantOrigin,
  }) {
    final payloadMap = _envelopeDecoder.decodeDataMap(
      rawResponse,
      label: 'map filter image upload',
      fallbackToRoot: false,
    );
    final imageUri = _normalizeMapFilterImageUri(
          key: key,
          rawImageUri: payloadMap['image_uri'],
          tenantOrigin: tenantOrigin,
        ) ??
        '';
    if (imageUri.isEmpty) {
      throw Exception('Map filter image upload response is empty.');
    }
    return imageUri;
  }

  TenantAdminFirebaseSettings? decodeFirebaseSettings(Object? rawResponse) {
    final payload = _envelopeDecoder.decodeDataMap(
      rawResponse,
      label: 'firebase settings',
    );
    return _mapFirebaseSettings(payload);
  }

  TenantAdminPushSettings decodePushSettings(Object? rawResponse) {
    final payload = _envelopeDecoder.decodeDataMap(
      rawResponse,
      label: 'push settings',
    );
    return _mapPushSettings(payload);
  }

  TenantAdminTelemetrySettingsSnapshot decodeTelemetrySnapshot(
    Object? rawResponse,
  ) {
    final rawMap = _envelopeDecoder.decodeRootMap(
      rawResponse,
      label: 'telemetry settings',
    );

    final integrations =
        _extractDataList(rawMap['data']).map(_mapTelemetry).toList(
              growable: false,
            );
    final availableEvents = _extractStringList(rawMap['available_events']);
    return TenantAdminTelemetrySettingsSnapshot(
      integrations: integrations,
      availableEvents: availableEvents,
    );
  }

  TenantAdminBrandingSettings decodeBrandingFromEnvironment(
    Map<String, dynamic> payload, {
    required Uri tenantOrigin,
  }) {
    final environmentType = payload['type']?.toString().trim().toLowerCase();
    if (environmentType != 'tenant') {
      throw Exception(
        'Unexpected environment type "$environmentType" for tenant branding read.',
      );
    }

    final themeSettingsRaw = payload['theme_data_settings'];
    if (themeSettingsRaw is! Map) {
      throw Exception('Missing theme_data_settings in tenant environment.');
    }
    final themeSettings = Map<String, dynamic>.from(themeSettingsRaw);

    final tenantName = _requireNonEmptyString(
      payload['name'],
      fieldName: 'name',
    );
    final primarySeedColor = _requireHexColor(
      themeSettings['primary_seed_color'],
      fieldName: 'theme_data_settings.primary_seed_color',
    );
    final secondarySeedColor = _requireHexColor(
      themeSettings['secondary_seed_color'],
      fieldName: 'theme_data_settings.secondary_seed_color',
    );
    final brightnessDefault = _parseBrandingBrightness(
      themeSettings['brightness_default'],
    );

    return TenantAdminBrandingSettings(
      tenantName: tenantName,
      brightnessDefault: brightnessDefault,
      primarySeedColor: primarySeedColor,
      secondarySeedColor: secondarySeedColor,
      lightLogoUrl: _buildTenantAssetUrl(tenantOrigin, 'logo-light.png'),
      darkLogoUrl: _buildTenantAssetUrl(tenantOrigin, 'logo-dark.png'),
      lightIconUrl: _buildTenantAssetUrl(tenantOrigin, 'icon-light.png'),
      darkIconUrl: _buildTenantAssetUrl(tenantOrigin, 'icon-dark.png'),
      faviconUrl: _buildTenantAssetUrl(tenantOrigin, 'favicon.ico'),
      pwaIconUrl: _resolvePwaIconUrl(payload, tenantOrigin: tenantOrigin),
    );
  }

  Map<String, dynamic> _extractMapUiPayload(Object? raw) {
    final payload = _envelopeDecoder.decodeDataMap(
      raw,
      label: 'map_ui settings',
      emptyWhenDataIsNotMap: true,
    );
    if (payload.containsKey('map_ui')) {
      final mapUiRaw = payload['map_ui'];
      if (mapUiRaw is Map) {
        return Map<String, dynamic>.from(mapUiRaw);
      }
      if (mapUiRaw == null) {
        return const <String, dynamic>{};
      }
      if (mapUiRaw is List && mapUiRaw.isEmpty) {
        return const <String, dynamic>{};
      }
      throw Exception('Unexpected map_ui payload shape.');
    }
    return Map<String, dynamic>.from(payload);
  }

  Map<String, dynamic> _extractAppLinksPayload(Object? raw) {
    final payload = _envelopeDecoder.decodeDataMap(
      raw,
      label: 'app_links settings',
      emptyWhenDataIsNotMap: true,
    );
    if (payload.containsKey('app_links')) {
      final appLinksRaw = payload['app_links'];
      if (appLinksRaw is Map) {
        return Map<String, dynamic>.from(appLinksRaw);
      }
      if (appLinksRaw == null) {
        return const <String, dynamic>{};
      }
      if (appLinksRaw is List && appLinksRaw.isEmpty) {
        return const <String, dynamic>{};
      }
      throw Exception('Unexpected app_links payload shape.');
    }
    return Map<String, dynamic>.from(payload);
  }

  TenantAdminAppLinksSettings _mapAppLinksSettings(
    Map<String, dynamic> appLinks, {
    required TenantAdminAppDomainIdentifiers appDomainIdentifiers,
  }) {
    final androidRaw = appLinks['android'];
    final android = androidRaw is Map
        ? Map<String, dynamic>.from(androidRaw)
        : const <String, dynamic>{};
    final iosRaw = appLinks['ios'];
    final ios = iosRaw is Map
        ? Map<String, dynamic>.from(iosRaw)
        : const <String, dynamic>{};

    final androidFingerprintValues =
        _extractStringList(android['sha256_cert_fingerprints'])
            .map((entry) => entry.toUpperCase())
            .toSet()
            .toList(growable: false);
    final iosPaths = _extractStringList(ios['paths']).toSet().toList(
          growable: false,
        );

    TenantAdminAndroidAppIdentifierValue? androidAppIdentifierValue;
    final androidAppIdentifier = appDomainIdentifiers.androidAppIdentifier;
    if (androidAppIdentifier != null &&
        androidAppIdentifier.trim().isNotEmpty) {
      androidAppIdentifierValue = TenantAdminAndroidAppIdentifierValue()
        ..parse(androidAppIdentifier);
    }

    TenantAdminIosBundleIdentifierValue? iosBundleIdValue;
    final iosBundleId = appDomainIdentifiers.iosBundleId;
    if (iosBundleId != null && iosBundleId.trim().isNotEmpty) {
      iosBundleIdValue = TenantAdminIosBundleIdentifierValue()
        ..parse(iosBundleId);
    }

    TenantAdminIosTeamIdValue? iosTeamIdValue;
    final iosTeamId = _normalizeOptionalText(ios['team_id']);
    if (iosTeamId != null && iosTeamId.trim().isNotEmpty) {
      iosTeamIdValue = TenantAdminIosTeamIdValue()..parse(iosTeamId);
    }

    return TenantAdminAppLinksSettings(
      rawAppLinksValue: TenantAdminDynamicMapValue(
        Map<String, dynamic>.unmodifiable(appLinks),
      ),
      androidAppIdentifierValue: androidAppIdentifierValue,
      androidSha256CertFingerprintsValue: TenantAdminSha256FingerprintListValue(
        androidFingerprintValues,
      ),
      iosTeamIdValue: iosTeamIdValue,
      iosBundleIdValue: iosBundleIdValue,
      iosPathsValue: TenantAdminTrimmedStringListValue(iosPaths),
    );
  }

  TenantAdminMapUiSettings _mapMapUiSettings(
    Map<String, dynamic> mapUi, {
    required Uri tenantOrigin,
  }) {
    final defaultOriginRaw = mapUi['default_origin'];
    TenantAdminMapDefaultOrigin? defaultOrigin;
    if (defaultOriginRaw is Map) {
      final originMap = Map<String, dynamic>.from(defaultOriginRaw);
      final lat = _parseDouble(originMap['lat']);
      final lng = _parseDouble(originMap['lng']);
      if (lat != null && lng != null) {
        final rawLabel = originMap['label']?.toString().trim();
        defaultOrigin = TenantAdminMapDefaultOrigin(
          lat: lat,
          lng: lng,
          label: rawLabel == null || rawLabel.isEmpty ? null : rawLabel,
        );
      }
    } else {
      final lat = _parseDouble(mapUi['default_origin.lat']);
      final lng = _parseDouble(mapUi['default_origin.lng']);
      if (lat != null && lng != null) {
        final rawLabel = mapUi['default_origin.label']?.toString().trim();
        defaultOrigin = TenantAdminMapDefaultOrigin(
          lat: lat,
          lng: lng,
          label: rawLabel == null || rawLabel.isEmpty ? null : rawLabel,
        );
      }
    }

    final filters = <TenantAdminMapFilterCatalogItem>[];
    final rawFilters = mapUi['filters'];
    if (rawFilters is List) {
      for (final entry in rawFilters) {
        if (entry is! Map) {
          continue;
        }
        final filterMap = Map<String, dynamic>.from(entry);
        final key = filterMap['key']?.toString().trim() ?? '';
        final label = filterMap['label']?.toString().trim() ?? '';
        final imageUri = _normalizeMapFilterImageUri(
          key: key,
          rawImageUri: filterMap['image_uri'],
          tenantOrigin: tenantOrigin,
        );
        final query = _mapMapFilterQuery(
          filterMap['query'] is Map
              ? Map<String, dynamic>.from(filterMap['query'] as Map)
              : null,
        );
        if (key.isEmpty || label.isEmpty) {
          continue;
        }
        filters.add(
          TenantAdminMapFilterCatalogItem(
            key: key,
            label: label,
            imageUri: imageUri == null || imageUri.isEmpty ? null : imageUri,
            query: query,
          ),
        );
      }
    }

    return TenantAdminMapUiSettings(
      rawMapUi: Map<String, dynamic>.unmodifiable(mapUi),
      defaultOrigin: defaultOrigin,
      filters: List<TenantAdminMapFilterCatalogItem>.unmodifiable(filters),
    );
  }

  TenantAdminMapFilterQuery _mapMapFilterQuery(Map<String, dynamic>? json) {
    if (json == null) {
      return TenantAdminMapFilterQuery();
    }

    List<String> asStringList(Object? raw) {
      if (raw is! List) {
        return const <String>[];
      }
      return raw
          .map((entry) => entry.toString().trim().toLowerCase())
          .where((entry) => entry.isNotEmpty)
          .toSet()
          .toList(growable: false);
    }

    return TenantAdminMapFilterQuery(
      source: TenantAdminMapFilterSource.fromRaw(json['source']?.toString()),
      types: asStringList(json['types']),
      taxonomy: asStringList(json['taxonomy']),
    );
  }

  TenantAdminFirebaseSettings? _mapFirebaseSettings(Map<String, dynamic> map) {
    final apiKey = map['apiKey']?.toString().trim();
    final appId = map['appId']?.toString().trim();
    final projectId = map['projectId']?.toString().trim();
    final sender = map['messagingSenderId']?.toString().trim();
    final storageBucket = map['storageBucket']?.toString().trim();
    if (apiKey == null ||
        appId == null ||
        projectId == null ||
        sender == null ||
        storageBucket == null ||
        apiKey.isEmpty ||
        appId.isEmpty ||
        projectId.isEmpty ||
        sender.isEmpty ||
        storageBucket.isEmpty) {
      return null;
    }
    return TenantAdminFirebaseSettings(
      apiKey: apiKey,
      appId: appId,
      projectId: projectId,
      messagingSenderId: sender,
      storageBucket: storageBucket,
    );
  }

  TenantAdminPushSettings _mapPushSettings(Map<String, dynamic> map) {
    final ttlDays = _parseInt(map['max_ttl_days']) ?? 30;
    final throttlesRaw = map['throttles'];
    final throttles = throttlesRaw is Map
        ? Map<String, dynamic>.from(throttlesRaw)
        : const <String, dynamic>{};
    final maxPerMinute = _parseInt(throttles['max_per_minute']) ?? 60;
    final maxPerHour = _parseInt(throttles['max_per_hour']) ?? 600;
    return TenantAdminPushSettings(
      maxTtlDays: ttlDays,
      maxPerMinute: maxPerMinute,
      maxPerHour: maxPerHour,
    );
  }

  TenantAdminTelemetryIntegration _mapTelemetry(Map<String, dynamic> map) {
    final type = map['type']?.toString().trim() ?? '';
    final trackAll = _parseBool(map['track_all']);
    final events = _extractStringList(map['events']);
    final token = map['token']?.toString().trim();
    final url = map['url']?.toString().trim();

    final extra = <String, dynamic>{};
    for (final entry in map.entries) {
      if (entry.key == 'type' ||
          entry.key == 'track_all' ||
          entry.key == 'events' ||
          entry.key == 'token' ||
          entry.key == 'url') {
        continue;
      }
      extra[entry.key] = entry.value;
    }

    return TenantAdminTelemetryIntegration(
      type: type,
      trackAll: trackAll,
      events: events,
      token: token == null || token.isEmpty ? null : token,
      url: url == null || url.isEmpty ? null : url,
      extra: extra.isEmpty ? null : extra,
    );
  }

  List<Map<String, dynamic>> _extractDataList(Object? raw) {
    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((entry) => Map<String, dynamic>.from(entry))
          .toList(growable: false);
    }
    return const <Map<String, dynamic>>[];
  }

  List<String> _extractStringList(Object? raw) {
    if (raw is List) {
      return raw
          .map((entry) => entry.toString().trim())
          .where((value) => value.isNotEmpty)
          .toList(growable: false);
    }
    return const <String>[];
  }

  String _requireNonEmptyString(
    Object? raw, {
    required String fieldName,
  }) {
    final value = raw?.toString().trim();
    if (value == null || value.isEmpty) {
      throw Exception('Missing required environment field: $fieldName');
    }
    return value;
  }

  String _requireHexColor(
    Object? raw, {
    required String fieldName,
  }) {
    final value = _normalizeHexColor(raw);
    if (value == null) {
      throw Exception('Invalid or missing color field: $fieldName');
    }
    return value;
  }

  TenantAdminBrandingBrightness _parseBrandingBrightness(Object? raw) {
    final value = raw?.toString().trim().toLowerCase();
    if (value == 'light') {
      return TenantAdminBrandingBrightness.light;
    }
    if (value == 'dark') {
      return TenantAdminBrandingBrightness.dark;
    }
    throw Exception(
      'Invalid or missing brightness field: theme_data_settings.brightness_default',
    );
  }

  String _buildTenantAssetUrl(Uri origin, String assetName) {
    return origin
        .replace(path: '/$assetName', queryParameters: null)
        .toString();
  }

  String? _resolvePwaIconUrl(
    Map<String, dynamic> payload, {
    required Uri tenantOrigin,
  }) {
    final logoSettings = payload['logo_settings'];
    final fromLogoSettings = _extractPwaIconUrlFromNode(
      logoSettings,
      tenantOrigin: tenantOrigin,
    );
    if (fromLogoSettings != null) {
      return fromLogoSettings;
    }

    return _extractPwaIconUrlFromNode(
      payload['pwa_icon'],
      tenantOrigin: tenantOrigin,
    );
  }

  String? _extractPwaIconUrlFromNode(
    Object? node, {
    required Uri tenantOrigin,
  }) {
    if (node is String) {
      return _resolveAssetUrl(
        node,
        tenantOrigin: tenantOrigin,
      );
    }
    if (node is! Map) {
      return null;
    }

    final map = Map<String, dynamic>.from(node);
    final direct = _resolveAssetUrl(
      map['icon512_uri'],
      tenantOrigin: tenantOrigin,
    );
    if (direct != null) {
      return direct;
    }

    final uri = _resolveAssetUrl(
      map['uri'],
      tenantOrigin: tenantOrigin,
    );
    if (uri != null) {
      return uri;
    }

    final pwaIconUri = _resolveAssetUrl(
      map['pwa_icon_uri'],
      tenantOrigin: tenantOrigin,
    );
    if (pwaIconUri != null) {
      return pwaIconUri;
    }

    final nested = map['pwa_icon'];
    if (nested != null && !identical(nested, node)) {
      return _extractPwaIconUrlFromNode(
        nested,
        tenantOrigin: tenantOrigin,
      );
    }
    return null;
  }

  String? _resolveAssetUrl(
    Object? raw, {
    required Uri tenantOrigin,
  }) {
    final value = raw?.toString().trim();
    if (value == null || value.isEmpty) {
      return null;
    }
    final parsed = Uri.tryParse(value);
    if (parsed == null) {
      return null;
    }
    if (parsed.host.trim().isNotEmpty) {
      return parsed.toString();
    }
    return tenantOrigin.resolveUri(parsed).toString();
  }

  String? _normalizeMapFilterImageUri({
    required String key,
    required Object? rawImageUri,
    required Uri tenantOrigin,
  }) {
    final normalizedKey = key.trim().toLowerCase();
    final value = rawImageUri?.toString().trim();
    if (normalizedKey.isEmpty || value == null || value.isEmpty) {
      return null;
    }

    final parsed = Uri.tryParse(value);
    if (parsed == null) {
      return value;
    }

    final path = parsed.path.trim();
    final legacyPath = '/map-filters/$normalizedKey/image';
    final canonicalPath = '/api/v1/media/map-filters/$normalizedKey';

    if (path == legacyPath || path == canonicalPath) {
      final canonicalUri = tenantOrigin.resolve(canonicalPath);
      final query = parsed.hasQuery ? parsed.query : null;
      return canonicalUri
          .replace(query: query == null || query.isEmpty ? null : query)
          .toString();
    }

    if (parsed.host.trim().isNotEmpty) {
      return parsed.toString();
    }

    return tenantOrigin.resolveUri(parsed).toString();
  }

  bool _parseBool(Object? value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    final raw = value?.toString().trim().toLowerCase();
    return raw == '1' || raw == 'true' || raw == 'yes';
  }

  String? _normalizeHexColor(Object? raw) {
    final value = raw?.toString().trim();
    if (value == null || value.isEmpty) {
      return null;
    }
    final sixDigit = RegExp(r'^#([a-fA-F0-9]{6})$');
    if (sixDigit.hasMatch(value)) {
      return value.toUpperCase();
    }
    final threeDigit = RegExp(r'^#([a-fA-F0-9]{3})$');
    final match = threeDigit.firstMatch(value);
    if (match == null) {
      return null;
    }
    final compact = match.group(1)!;
    final expanded = compact.split('').map((char) => '$char$char').join();
    return '#${expanded.toUpperCase()}';
  }

  String? _normalizeOptionalText(Object? raw) {
    final normalized = raw?.toString().trim();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }
    return normalized;
  }

  int? _parseInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim());
    return null;
  }

  double? _parseDouble(Object? value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value.trim());
    return null;
  }
}
