import 'package:belluga_now/application/tenant_admin/settings/tenant_admin_discovery_filters_settings_canonicalizer.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_settings.dart';
import 'package:belluga_now/domain/map/value_objects/latitude_value.dart';
import 'package:belluga_now/domain/map/value_objects/longitude_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_app_link_path_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_android_app_identifier_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_boolean_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_discovery_filters_settings_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_dynamic_map_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_flag_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_hex_color_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_ios_bundle_identifier_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_ios_team_id_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_lowercase_token_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_optional_text_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_optional_url_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_positive_int_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_required_text_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_sha256_fingerprint_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_trimmed_string_list_value.dart';
import 'package:belluga_now/infrastructure/dal/dao/http/raw_json_envelope_decoder.dart';
import 'package:value_object_pattern/domain/value_objects/email_address_value.dart';

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

  TenantAdminDiscoveryFiltersSettingsValue decodeDiscoveryFiltersSettings(
    Object? rawResponse, {
    required Uri tenantOrigin,
  }) {
    final payload = _envelopeDecoder.decodeDataMap(
      rawResponse,
      label: 'discovery_filters settings',
      emptyWhenDataIsNotMap: true,
    );
    final discoveryFilters = _extractNamedMap(
      payload,
      namespace: 'discovery_filters',
    );
    final legacyMapUi = _extractNamedMap(payload, namespace: 'map_ui');
    return TenantAdminDiscoveryFiltersSettingsValue(
      TenantAdminDynamicMapValue(
        Map<String, dynamic>.unmodifiable(
          const TenantAdminDiscoveryFiltersSettingsCanonicalizer().canonicalize(
            discoveryFilters: discoveryFilters,
            legacyMapUi: legacyMapUi,
          ),
        ),
      ),
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
    TenantAdminAndroidAppIdentifierValue? androidAppIdentifierValue;
    final androidAppIdentifier = _normalizeOptionalText(appDomains['android']);
    if (androidAppIdentifier != null && androidAppIdentifier.isNotEmpty) {
      androidAppIdentifierValue = TenantAdminAndroidAppIdentifierValue()
        ..parse(androidAppIdentifier);
    }
    TenantAdminIosBundleIdentifierValue? iosBundleIdValue;
    final iosBundleId = _normalizeOptionalText(appDomains['ios']);
    if (iosBundleId != null && iosBundleId.isNotEmpty) {
      iosBundleIdValue = TenantAdminIosBundleIdentifierValue()
        ..parse(iosBundleId);
    }
    return TenantAdminAppDomainIdentifiers(
      androidAppIdentifierValue: androidAppIdentifierValue,
      iosBundleIdValue: iosBundleIdValue,
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

  TenantAdminResendEmailSettings decodeResendEmailSettings(
      Object? rawResponse) {
    final payload = _envelopeDecoder.decodeDataMap(
      rawResponse,
      label: 'resend_email settings',
      emptyWhenDataIsNotMap: true,
    );
    if (payload.containsKey('resend_email')) {
      final resendRaw = payload['resend_email'];
      if (resendRaw is Map) {
        return _mapResendEmailSettings(
          Map<String, dynamic>.from(resendRaw),
        );
      }
      return TenantAdminResendEmailSettings.empty();
    }

    return _mapResendEmailSettings(payload);
  }

  TenantAdminOutboundIntegrationsSettings decodeOutboundIntegrationsSettings(
    Object? rawResponse,
  ) {
    final outboundIntegrations =
        _extractOutboundIntegrationsPayload(rawResponse);
    return _mapOutboundIntegrationsSettings(outboundIntegrations);
  }

  TenantAdminPhoneOtpReviewAccessSettings decodePhoneOtpReviewAccessSettings(
    Object? rawResponse,
  ) {
    final payload = _envelopeDecoder.decodeDataMap(
      rawResponse,
      label: 'phone_otp_review_access settings',
      emptyWhenDataIsNotMap: true,
    );
    if (payload.containsKey('phone_e164') || payload.containsKey('code_hash')) {
      return _mapPhoneOtpReviewAccessSettings(payload);
    }

    return _mapPhoneOtpReviewAccessSettings(
      _extractNamedMap(
        payload,
        namespace: 'phone_otp_review_access',
      ),
    );
  }

  String decodePhoneOtpReviewAccessCodeHash(Object? rawResponse) {
    final payload = _envelopeDecoder.decodeDataMap(
      rawResponse,
      label: 'phone_otp_review_access code hash',
      emptyWhenDataIsNotMap: true,
    );
    final nestedPayload = payload['phone_otp_review_access'];
    final source = nestedPayload is Map
        ? Map<String, dynamic>.from(nestedPayload)
        : payload;
    final codeHash = _normalizeOptionalText(source['code_hash']);
    if (codeHash == null || codeHash.isEmpty) {
      throw Exception('phone_otp_review_access code_hash response is empty.');
    }
    return codeHash;
  }

  TenantAdminPushSettings decodePushSettings(Object? rawResponse) {
    final payload = _envelopeDecoder.decodeDataMap(
      rawResponse,
      label: 'push settings',
    );
    return _mapPushSettings(payload);
  }

  TenantAdminPushStatus decodePushStatus(Object? rawResponse) {
    final payload = _envelopeDecoder.decodeRootMap(
      rawResponse,
      label: 'push status',
    );
    final status = _normalizeOptionalText(payload['status']);
    if (status == null || status.isEmpty) {
      throw Exception('Push status response is empty.');
    }
    return TenantAdminPushStatus(
      statusValue: _requiredTextValue(status),
    );
  }

  TenantAdminPushCredentials? decodePushCredentials(Object? rawResponse) {
    final root = _envelopeDecoder.decodeRootMap(
      rawResponse,
      label: 'push credentials',
    );
    final data = root['data'];
    if (data == null) {
      return null;
    }
    if (data is Map<String, dynamic>) {
      return _mapPushCredentials(data);
    }
    if (data is Map) {
      return _mapPushCredentials(Map<String, dynamic>.from(data));
    }
    if (data is List) {
      if (data.isEmpty) {
        return null;
      }
      final first = data.first;
      if (first is Map<String, dynamic>) {
        return _mapPushCredentials(first);
      }
      if (first is Map) {
        return _mapPushCredentials(Map<String, dynamic>.from(first));
      }
    }
    throw Exception('Unexpected push credentials response shape.');
  }

  TenantAdminPushCredentials decodePushCredentialItem(Object? rawResponse) {
    final payload = _envelopeDecoder.decodeItemMap(
      rawResponse,
      label: 'push credential',
    );
    return _mapPushCredentials(payload);
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
      availableEventValues: TenantAdminTrimmedStringListValue(availableEvents),
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
    final brandingAssetsRaw = payload['branding_assets'];
    final brandingAssets = brandingAssetsRaw is Map
        ? Map<String, dynamic>.from(brandingAssetsRaw)
        : const <String, dynamic>{};
    final faviconAssetRaw = brandingAssets['favicon'];
    final faviconAsset = faviconAssetRaw is Map
        ? Map<String, dynamic>.from(faviconAssetRaw)
        : const <String, dynamic>{};
    final publicWebMetadataRaw = payload['public_web_metadata'];
    final publicWebMetadata = publicWebMetadataRaw is Map
        ? Map<String, dynamic>.from(publicWebMetadataRaw)
        : const <String, dynamic>{};

    return TenantAdminBrandingSettings(
      tenantName: _requiredTextValue(tenantName),
      brightnessDefault: brightnessDefault,
      primarySeedColor: _hexColorValue(primarySeedColor),
      secondarySeedColor: _hexColorValue(secondarySeedColor),
      lightLogoUrl: _optionalUrlValue(
          _buildTenantAssetUrl(tenantOrigin, 'logo-light.png')),
      darkLogoUrl: _optionalUrlValue(
          _buildTenantAssetUrl(tenantOrigin, 'logo-dark.png')),
      lightIconUrl: _optionalUrlValue(
          _buildTenantAssetUrl(tenantOrigin, 'icon-light.png')),
      darkIconUrl: _optionalUrlValue(
          _buildTenantAssetUrl(tenantOrigin, 'icon-dark.png')),
      faviconUrl:
          _optionalUrlValue(_buildTenantAssetUrl(tenantOrigin, 'favicon.ico')),
      pwaIconUrl: (() {
        final pwaIcon = _resolvePwaIconUrl(payload, tenantOrigin: tenantOrigin);
        if (pwaIcon == null || pwaIcon.isEmpty) {
          return null;
        }
        return _optionalUrlValue(pwaIcon);
      })(),
      publicWebDefaultTitle: (() {
        final rawTitle = _normalizeOptionalText(
          publicWebMetadata['default_title'],
        );
        if (rawTitle == null || rawTitle.isEmpty) {
          return null;
        }
        return _optionalTextValue(rawTitle);
      })(),
      publicWebDefaultDescription: (() {
        final rawDescription = _normalizeOptionalText(
          publicWebMetadata['default_description'],
        );
        if (rawDescription == null || rawDescription.isEmpty) {
          return null;
        }
        return _optionalTextValue(rawDescription);
      })(),
      publicWebDefaultImageUrl: (() {
        final rawImage = _normalizeOptionalText(
          publicWebMetadata['default_image'],
        );
        if (rawImage == null || rawImage.isEmpty) {
          return null;
        }
        final resolvedImage = _resolveAssetUrl(
          rawImage,
          tenantOrigin: tenantOrigin,
        );
        if (resolvedImage == null || resolvedImage.isEmpty) {
          return null;
        }
        return _optionalUrlValue(resolvedImage);
      })(),
      hasDedicatedFaviconValue: _booleanValue(_parseBool(
        faviconAsset['has_dedicated_asset'],
      )),
      usesPwaFaviconFallbackValue: _booleanValue(_parseBool(
        faviconAsset['uses_pwa_fallback'],
      )),
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

  Map<String, dynamic> _extractNamedMap(
    Map<String, dynamic> payload, {
    required String namespace,
  }) {
    final raw = payload[namespace];
    if (raw is Map) {
      return Map<String, dynamic>.from(raw);
    }
    if (raw == null && payload.containsKey(namespace)) {
      return const <String, dynamic>{};
    }
    if (raw is List && raw.isEmpty) {
      return const <String, dynamic>{};
    }
    if (payload.containsKey(namespace)) {
      throw Exception('Unexpected $namespace payload shape.');
    }
    return payload.containsKey('surfaces') ||
            payload.keys.any((key) => key.startsWith('surfaces.'))
        ? Map<String, dynamic>.from(payload)
        : const <String, dynamic>{};
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

  Map<String, dynamic> _extractOutboundIntegrationsPayload(Object? raw) {
    final payload = _envelopeDecoder.decodeDataMap(
      raw,
      label: 'outbound_integrations settings',
      emptyWhenDataIsNotMap: true,
    );
    if (payload.containsKey('outbound_integrations')) {
      final outboundIntegrationsRaw = payload['outbound_integrations'];
      if (outboundIntegrationsRaw is Map) {
        return Map<String, dynamic>.from(outboundIntegrationsRaw);
      }
      if (outboundIntegrationsRaw == null) {
        return const <String, dynamic>{};
      }
      if (outboundIntegrationsRaw is List && outboundIntegrationsRaw.isEmpty) {
        return const <String, dynamic>{};
      }
      throw Exception('Unexpected outbound_integrations payload shape.');
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
      androidSha256CertFingerprintValues: androidFingerprintValues
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
          lat: _latitudeValue(lat),
          lng: _longitudeValue(lng),
          label: rawLabel == null || rawLabel.isEmpty
              ? null
              : _optionalTextValue(rawLabel),
        );
      }
    } else {
      final lat = _parseDouble(mapUi['default_origin.lat']);
      final lng = _parseDouble(mapUi['default_origin.lng']);
      if (lat != null && lng != null) {
        final rawLabel = mapUi['default_origin.label']?.toString().trim();
        defaultOrigin = TenantAdminMapDefaultOrigin(
          lat: _latitudeValue(lat),
          lng: _longitudeValue(lng),
          label: rawLabel == null || rawLabel.isEmpty
              ? null
              : _optionalTextValue(rawLabel),
        );
      }
    }

    final filters = TenantAdminMapFilterCatalogItems();
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
        final overrideMarker = _parseBool(filterMap['override_marker']);
        final markerOverride = _mapMapFilterMarkerOverride(
          overrideMarker: overrideMarker,
          raw: filterMap['marker_override'],
          fallbackImageUri: imageUri,
        );
        final query = _mapMapFilterQuery(
          filterMap['query'] is Map
              ? Map<String, dynamic>.from(filterMap['query'] as Map)
              : null,
        );
        if (key.isEmpty || label.isEmpty) {
          continue;
        }
        final keyValue = TenantAdminLowercaseTokenValue()..parse(key);
        final labelValue = TenantAdminRequiredTextValue()..parse(label);
        final imageUriValue = imageUri == null || imageUri.isEmpty
            ? null
            : (TenantAdminOptionalUrlValue()..parse(imageUri));
        filters.add(
          TenantAdminMapFilterCatalogItem(
            keyValue: keyValue,
            labelValue: labelValue,
            imageUriValue: imageUriValue,
            overrideMarkerValue: TenantAdminFlagValue(overrideMarker),
            markerOverride: markerOverride,
            query: query,
          ),
        );
      }
    }

    return TenantAdminMapUiSettings(
      rawMapUiValue: TenantAdminDynamicMapValue(
        Map<String, dynamic>.unmodifiable(mapUi),
      ),
      defaultOrigin: defaultOrigin,
      filters: filters,
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
      source: TenantAdminMapFilterSource.fromRaw(
        TenantAdminLowercaseTokenValue(isRequired: false)
          ..parse(json['source']?.toString()),
      ),
      typeValues: asStringList(json['types']).map(_tokenValue).toList(),
      taxonomyValues: asStringList(json['taxonomy']).map(_tokenValue).toList(),
    );
  }

  TenantAdminMapFilterMarkerOverride? _mapMapFilterMarkerOverride({
    required bool overrideMarker,
    required Object? raw,
    required String? fallbackImageUri,
  }) {
    if (!overrideMarker || raw is! Map) {
      return null;
    }

    final marker = Map<String, dynamic>.from(raw);
    final modeTokenValue = TenantAdminLowercaseTokenValue();
    try {
      modeTokenValue.parse(marker['mode']?.toString());
    } on Object {
      return null;
    }
    final mode =
        tenantAdminMapFilterMarkerOverrideModeFromValue(modeTokenValue);
    if (mode == null) {
      return null;
    }

    if (mode == TenantAdminMapFilterMarkerOverrideMode.icon) {
      final iconValue = TenantAdminRequiredTextValue();
      final colorValue = TenantAdminHexColorValue();
      final iconColorValue = TenantAdminHexColorValue();
      try {
        iconValue.parse(marker['icon']?.toString());
        colorValue.parse(marker['color']?.toString());
        iconColorValue.parse((marker['icon_color'] ?? '#FFFFFF').toString());
      } on Object {
        return null;
      }

      return TenantAdminMapFilterMarkerOverride.icon(
        iconValue: iconValue,
        colorValue: colorValue,
        iconColorValue: iconColorValue,
      );
    }

    final imageUriRaw = marker['image_uri']?.toString().trim();
    final imageUri = (imageUriRaw == null || imageUriRaw.isEmpty)
        ? (fallbackImageUri?.trim() ?? '')
        : imageUriRaw;
    if (imageUri.isEmpty) {
      return null;
    }

    final imageUriValue = TenantAdminOptionalUrlValue();
    try {
      imageUriValue.parse(imageUri);
    } on Object {
      return null;
    }

    return TenantAdminMapFilterMarkerOverride.image(
      imageUriValue: imageUriValue,
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
      apiKey: _requiredTextValue(apiKey),
      appId: _requiredTextValue(appId),
      projectId: _requiredTextValue(projectId),
      messagingSenderId: _requiredTextValue(sender),
      storageBucket: _requiredTextValue(storageBucket),
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
      maxTtlDaysValue: _positiveIntValue(ttlDays),
      maxPerMinuteValue: _positiveIntValue(maxPerMinute),
      maxPerHourValue: _positiveIntValue(maxPerHour),
      enabledValue: map.containsKey('enabled')
          ? _booleanValue(_parseBool(map['enabled']))
          : null,
    );
  }

  TenantAdminPushCredentials _mapPushCredentials(Map<String, dynamic> map) {
    final projectId = _requireNonEmptyString(
      map['project_id'],
      fieldName: 'push_credentials.project_id',
    );
    final clientEmail = _requireNonEmptyString(
      map['client_email'],
      fieldName: 'push_credentials.client_email',
    );
    final id = _normalizeOptionalText(map['id']);
    final privateKey = _normalizeOptionalText(map['private_key']);
    return TenantAdminPushCredentials(
      idValue: id == null || id.isEmpty ? null : _requiredTextValue(id),
      projectIdValue: _requiredTextValue(projectId),
      clientEmailValue: _emailAddressValue(clientEmail),
      privateKeyValue: privateKey == null || privateKey.isEmpty
          ? null
          : _requiredTextValue(privateKey),
    );
  }

  TenantAdminResendEmailSettings _mapResendEmailSettings(
    Map<String, dynamic> map,
  ) {
    final token = _normalizeOptionalText(map['token']);
    final from = _normalizeOptionalText(map['from']);

    return TenantAdminResendEmailSettings(
      token: token == null ? null : _optionalTextValue(token),
      from: from == null ? null : _optionalTextValue(from),
      toRecipients: _resendEmailRecipients(_extractStringList(map['to'])),
      ccRecipients: _resendEmailRecipients(_extractStringList(map['cc'])),
      bccRecipients: _resendEmailRecipients(_extractStringList(map['bcc'])),
      replyToRecipients: _resendEmailRecipients(
        _extractStringList(map['reply_to']),
      ),
    );
  }

  TenantAdminOutboundIntegrationsSettings _mapOutboundIntegrationsSettings(
    Map<String, dynamic> map,
  ) {
    final whatsappRaw = map['whatsapp'];
    final whatsapp = whatsappRaw is Map
        ? Map<String, dynamic>.from(whatsappRaw)
        : const <String, dynamic>{};
    final otpRaw = map['otp'];
    final otp = otpRaw is Map
        ? Map<String, dynamic>.from(otpRaw)
        : const <String, dynamic>{};

    final whatsappWebhookUrl = _normalizeOptionalText(whatsapp['webhook_url']);
    final otpWebhookUrl = _normalizeOptionalText(otp['webhook_url']);
    final deliveryChannelRaw =
        _normalizeOptionalText(otp['delivery_channel']) ??
            TenantAdminOutboundIntegrationsSettings.deliveryChannelWhatsapp;
    final deliveryChannel = _isValidOutboundOtpDeliveryChannel(
      deliveryChannelRaw,
    )
        ? deliveryChannelRaw.toLowerCase()
        : TenantAdminOutboundIntegrationsSettings.deliveryChannelWhatsapp;

    return TenantAdminOutboundIntegrationsSettings(
      whatsappWebhookUrlValue: whatsappWebhookUrl == null
          ? null
          : _optionalUrlValue(whatsappWebhookUrl),
      otpWebhookUrlValue:
          otpWebhookUrl == null ? null : _optionalUrlValue(otpWebhookUrl),
      otpUseWhatsappWebhookValue: _booleanValue(
        _parseBool(otp['use_whatsapp_webhook'] ?? true),
      ),
      otpDeliveryChannelValue: _tokenValue(deliveryChannel),
      otpTtlMinutesValue: _positiveIntValue(
        _parseInt(otp['ttl_minutes']) ??
            TenantAdminOutboundIntegrationsSettings.defaultOtpTtlMinutes,
      ),
      otpResendCooldownSecondsValue: _positiveIntValue(
        _parseInt(otp['resend_cooldown_seconds']) ??
            TenantAdminOutboundIntegrationsSettings
                .defaultOtpResendCooldownSeconds,
      ),
      otpMaxAttemptsValue: _positiveIntValue(
        _parseInt(otp['max_attempts']) ??
            TenantAdminOutboundIntegrationsSettings.defaultOtpMaxAttempts,
      ),
    );
  }

  TenantAdminPhoneOtpReviewAccessSettings _mapPhoneOtpReviewAccessSettings(
    Map<String, dynamic> map,
  ) {
    final phoneE164 = _normalizeOptionalText(map['phone_e164']);
    final codeHash = _normalizeOptionalText(map['code_hash']);

    return TenantAdminPhoneOtpReviewAccessSettings(
      rawPhoneOtpReviewAccessValue: TenantAdminDynamicMapValue(
        Map<String, dynamic>.unmodifiable(map),
      ),
      phoneE164Value: phoneE164 == null ? null : _optionalTextValue(phoneE164),
      codeHashValue: codeHash == null ? null : _optionalTextValue(codeHash),
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
      type: _tokenValue(type),
      trackAll: _booleanValue(trackAll),
      eventValues: events.map(_tokenValue).toList(growable: false),
      token: token == null || token.isEmpty ? null : _optionalTextValue(token),
      url: url == null || url.isEmpty ? null : _optionalUrlValue(url),
      rawExtraValue: extra.isEmpty
          ? null
          : TenantAdminDynamicMapValue(Map<String, dynamic>.from(extra)),
    );
  }

  TenantAdminRequiredTextValue _requiredTextValue(String raw) {
    final value = TenantAdminRequiredTextValue();
    value.parse(raw);
    return value;
  }

  TenantAdminPositiveIntValue _positiveIntValue(int raw) {
    final value = TenantAdminPositiveIntValue();
    value.parse(raw.toString());
    return value;
  }

  EmailAddressValue _emailAddressValue(String raw) {
    final value = EmailAddressValue();
    value.parse(raw);
    return value;
  }

  TenantAdminHexColorValue _hexColorValue(String raw) {
    final value = TenantAdminHexColorValue();
    value.parse(raw);
    return value;
  }

  TenantAdminOptionalUrlValue _optionalUrlValue(String raw) {
    final value = TenantAdminOptionalUrlValue();
    value.parse(raw);
    return value;
  }

  TenantAdminOptionalTextValue _optionalTextValue(String raw) {
    final value = TenantAdminOptionalTextValue();
    value.parse(raw);
    return value;
  }

  LatitudeValue _latitudeValue(double raw) {
    final value = LatitudeValue();
    value.parse(raw.toString());
    return value;
  }

  LongitudeValue _longitudeValue(double raw) {
    final value = LongitudeValue();
    value.parse(raw.toString());
    return value;
  }

  TenantAdminLowercaseTokenValue _tokenValue(String raw) {
    final value = TenantAdminLowercaseTokenValue();
    value.parse(raw);
    return value;
  }

  TenantAdminBooleanValue _booleanValue(bool raw) {
    final value = TenantAdminBooleanValue();
    value.parse(raw.toString());
    return value;
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

  bool _isValidOutboundOtpDeliveryChannel(String raw) {
    final normalized = raw.trim().toLowerCase();
    return normalized ==
            TenantAdminOutboundIntegrationsSettings.deliveryChannelWhatsapp ||
        normalized ==
            TenantAdminOutboundIntegrationsSettings.deliveryChannelSms;
  }

  TenantAdminResendEmailRecipients _resendEmailRecipients(
    Iterable<String> rawValues,
  ) {
    return TenantAdminResendEmailRecipients(
      rawValues.map(_emailAddressValue),
    );
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
