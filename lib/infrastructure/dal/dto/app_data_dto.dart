import 'package:belluga_now/application/functions/to_hex.dart';
import 'package:belluga_now/domain/app_data/app_data.dart';
import 'package:belluga_now/domain/app_data/app_type.dart';
import 'package:belluga_now/domain/app_data/firebase_settings.dart';
import 'package:belluga_now/domain/app_data/push_settings.dart';
import 'package:belluga_now/domain/app_data/telemetry_context_settings.dart';
import 'package:belluga_now/domain/app_data/telemetry_settings.dart';
import 'package:belluga_now/domain/app_data/value_object/app_data_hostname_value.dart';
import 'package:belluga_now/domain/app_data/value_object/app_data_href_value.dart';
import 'package:belluga_now/domain/app_data/value_object/app_data_map_filter_catalog_keys_value.dart';
import 'package:belluga_now/domain/app_data/value_object/app_data_port_value.dart';
import 'package:belluga_now/domain/app_data/value_object/app_data_required_text_value.dart';
import 'package:belluga_now/domain/app_data/value_object/app_domain_value.dart';
import 'package:belluga_now/domain/app_data/value_object/domain_value.dart';
import 'package:belluga_now/domain/app_data/value_object/push_enabled_value.dart';
import 'package:belluga_now/domain/app_data/value_object/push_throttles_value.dart';
import 'package:belluga_now/domain/app_data/value_object/push_types_value.dart';
import 'package:belluga_now/domain/app_data/value_object/telemetry_location_freshness_value.dart';
import 'package:belluga_now/domain/app_data/value_object/environment_name_value.dart';
import 'package:belluga_now/domain/app_data/value_object/environment_type_value.dart';
import 'package:belluga_now/domain/map/value_objects/city_coordinate.dart';
import 'package:belluga_now/domain/map/value_objects/distance_in_meters_value.dart';
import 'package:belluga_now/domain/map/value_objects/latitude_value.dart';
import 'package:belluga_now/domain/map/value_objects/longitude_value.dart';
import 'package:belluga_now/domain/partners/profile_type_capabilities.dart';
import 'package:belluga_now/domain/partners/profile_type_definitions.dart';
import 'package:belluga_now/domain/partners/profile_type_definition.dart';
import 'package:belluga_now/domain/partners/profile_type_registry.dart';
import 'package:belluga_now/domain/partners/profile_type_visual.dart';
import 'package:belluga_now/domain/partners/value_objects/profile_type_flag_value.dart';
import 'package:belluga_now/domain/partners/value_objects/profile_type_key_value.dart';
import 'package:belluga_now/domain/partners/value_objects/profile_type_label_value.dart';
import 'package:belluga_now/domain/partners/value_objects/profile_type_visual_hex_color_value.dart';
import 'package:belluga_now/domain/partners/value_objects/profile_type_visual_icon_value.dart';
import 'package:belluga_now/domain/partners/value_objects/profile_type_visual_image_url_value.dart';
import 'package:belluga_now/domain/tenant/value_objects/icon_url_value.dart';
import 'package:belluga_now/domain/tenant/value_objects/main_color_value.dart';
import 'package:belluga_now/domain/tenant/value_objects/main_logo_url_value.dart';
import 'package:belluga_now/domain/tenant/value_objects/tenant_id_value.dart';
import 'package:belluga_now/domain/theme_data_settings/color_scheme_data.dart';
import 'package:belluga_now/domain/theme_data_settings/theme_data_settings.dart';
import 'package:belluga_now/domain/theme_data_settings/value_objects/brightness_value.dart';
import 'package:belluga_now/domain/value_objects/color_required_value.dart';
import 'package:belluga_now/infrastructure/platform/app_data_local_info_source/app_data_local_info_dto.dart';
import 'package:event_tracker_handler/event_tracker_handler.dart';
import 'package:flutter/material.dart';
import 'package:value_object_pattern/value_object.dart';

class AppDataDTO {
  AppDataDTO({
    this.tenantId,
    required this.name,
    required this.type,
    required this.mainDomain,
    List<Map<String, dynamic>>? profileTypes,
    List<String>? domains,
    List<String>? appDomains,
    required this.themeDataSettings,
    this.iconUrl,
    this.mainColor,
    this.mainLogoUrl,
    this.mainLogoLightUrl,
    this.mainLogoDarkUrl,
    this.mainIconLightUrl,
    this.mainIconDarkUrl,
    Map<String, dynamic>? telemetry,
    Map<String, dynamic>? telemetryContext,
    Map<String, dynamic>? firebase,
    Map<String, dynamic>? push,
    Map<String, dynamic>? settings,
  })  : profileTypes = List.unmodifiable(profileTypes ?? const []),
        domains = List.unmodifiable(domains ?? const []),
        appDomains = List.unmodifiable(appDomains ?? const []),
        telemetry = telemetry == null ? null : Map.unmodifiable(telemetry),
        telemetryContext = telemetryContext == null
            ? null
            : Map.unmodifiable(telemetryContext),
        firebase = firebase == null ? null : Map.unmodifiable(firebase),
        push = push == null ? null : Map.unmodifiable(push),
        settings = settings == null ? null : Map.unmodifiable(settings);

  final String? tenantId;
  final String name;
  final String type;
  final String mainDomain;
  final List<Map<String, dynamic>> profileTypes;
  final List<String> domains;
  final List<String> appDomains;
  final Map<String, dynamic> themeDataSettings;
  final String? iconUrl;

  /// Sourced from `theme_data_settings.primary_seed_color` (backend omits `main_color`).
  final String? mainColor;
  final String? mainLogoUrl;
  final String? mainLogoLightUrl;
  final String? mainLogoDarkUrl;
  final String? mainIconLightUrl;
  final String? mainIconDarkUrl;
  final Map<String, dynamic>? telemetry;
  final Map<String, dynamic>? telemetryContext;
  final Map<String, dynamic>? firebase;
  final Map<String, dynamic>? push;
  final Map<String, dynamic>? settings;

  factory AppDataDTO.fromJson(Map<String, dynamic> json) {
    final themeSettings = Map<String, dynamic>.unmodifiable(
      (json['theme_data_settings'] as Map<String, dynamic>? ??
          const <String, dynamic>{}),
    );
    final profileTypes = (json['profile_types'] as List<dynamic>? ?? const [])
        .whereType<Map>()
        .map((entry) => Map<String, dynamic>.from(entry))
        .toList();

    return AppDataDTO(
      tenantId: json['tenant_id'] as String?,
      name: json['name'] as String? ?? '',
      type: json['type'] as String? ?? '',
      mainDomain: json['main_domain'] as String? ?? '',
      profileTypes: profileTypes,
      domains: (json['domains'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .toList(),
      appDomains: (json['app_domains'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .toList(),
      themeDataSettings: themeSettings,
      iconUrl: json['icon_url'] as String?,
      // Backend no longer returns `main_color`; use the seed color instead.
      mainColor: themeSettings['primary_seed_color'] as String?,
      mainLogoUrl: json['main_logo_url'] as String?,
      mainLogoLightUrl: json['main_logo_light_url'] as String?,
      mainLogoDarkUrl: json['main_logo_dark_url'] as String?,
      mainIconLightUrl: json['main_icon_light_url'] as String?,
      mainIconDarkUrl: json['main_icon_dark_url'] as String?,
      telemetry: _normalizeTelemetry(json['telemetry']),
      telemetryContext: json['telemetry_context'] is Map<String, dynamic>
          ? Map<String, dynamic>.from(json['telemetry_context'] as Map)
          : null,
      firebase: json['firebase'] is Map<String, dynamic>
          ? Map<String, dynamic>.from(json['firebase'] as Map)
          : null,
      push: json['push'] is Map<String, dynamic>
          ? Map<String, dynamic>.from(json['push'] as Map)
          : null,
      settings: json['settings'] is Map<String, dynamic>
          ? Map<String, dynamic>.from(json['settings'] as Map)
          : null,
    );
  }

  factory AppDataDTO.fromLegacy(Object raw) {
    if (raw is AppDataDTO) {
      return raw;
    }
    if (raw is Map<String, dynamic>) {
      return AppDataDTO.fromJson(raw);
    }
    if (raw is Map) {
      return AppDataDTO.fromJson(Map<String, dynamic>.from(raw));
    }

    final legacy = raw as dynamic;
    return AppDataDTO(
      tenantId: legacy.tenantId?.toString(),
      name: legacy.name?.toString() ?? '',
      type: legacy.type?.toString() ?? '',
      mainDomain: legacy.mainDomain?.toString() ?? '',
      profileTypes: (legacy.profileTypes as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map((entry) => Map<String, dynamic>.from(entry))
          .toList(growable: false),
      domains: (legacy.domains as List<dynamic>? ?? const [])
          .map((entry) => entry.toString())
          .toList(growable: false),
      appDomains: (legacy.appDomains as List<dynamic>? ?? const [])
          .map((entry) => entry.toString())
          .toList(growable: false),
      themeDataSettings: legacy.themeDataSettings is Map<String, dynamic>
          ? Map<String, dynamic>.from(legacy.themeDataSettings as Map)
          : const <String, dynamic>{},
      iconUrl: legacy.iconUrl?.toString(),
      mainColor: legacy.mainColor?.toString(),
      mainLogoUrl: legacy.mainLogoUrl?.toString(),
      mainLogoLightUrl: legacy.mainLogoLightUrl?.toString(),
      mainLogoDarkUrl: legacy.mainLogoDarkUrl?.toString(),
      mainIconLightUrl: legacy.mainIconLightUrl?.toString(),
      mainIconDarkUrl: legacy.mainIconDarkUrl?.toString(),
      telemetry: _normalizeTelemetry(legacy.telemetry),
      telemetryContext: legacy.telemetryContext is Map
          ? Map<String, dynamic>.from(legacy.telemetryContext as Map)
          : null,
      firebase: legacy.firebase is Map
          ? Map<String, dynamic>.from(legacy.firebase as Map)
          : null,
      push: legacy.push is Map
          ? Map<String, dynamic>.from(legacy.push as Map)
          : null,
      settings: legacy.settings is Map
          ? Map<String, dynamic>.from(legacy.settings as Map)
          : null,
    );
  }

  AppData toDomain({required AppDataLocalInfoDTO localInfo}) {
    final radiusBounds = _resolveRadiusBounds(settings);
    final tenantDefaultOrigin = _resolveTenantDefaultOrigin(settings);
    final mapFilterCatalogKeys = _resolveMapFilterCatalogKeys(settings);

    final origin = _resolveOrigin(mainDomain);
    final mainIconLightResolved =
        _firstNonEmpty(mainIconLightUrl, '$origin/icon-light.png');
    final mainIconDarkResolved =
        _firstNonEmpty(mainIconDarkUrl, '$origin/icon-dark.png');
    final mainLogoLightResolved =
        _firstNonEmpty(mainLogoLightUrl, '$origin/logo-light.png');
    final mainLogoDarkResolved =
        _firstNonEmpty(mainLogoDarkUrl, '$origin/logo-dark.png');
    final mainColorResolved = _firstNonEmpty(
        mainColor, themeDataSettings['primary_seed_color'] as String?);

    final mainDomainValue = DomainValue()
      ..parse(DomainValue.coerceRaw(mainDomain));
    final tenantIdValue = TenantIdValue()..parse(tenantId?.toString());

    final resolvedPlatform = localInfo.platformTypeValue.value ??
        localInfo.platformTypeValue.defaultValue ??
        AppType.mobile;
    final isWeb = resolvedPlatform == AppType.web;
    final resolvedHostname =
        isWeb ? localInfo.hostname : mainDomainValue.value.host;
    final resolvedHref =
        isWeb ? localInfo.href : mainDomainValue.value.toString();

    return AppData(
      platformType: localInfo.platformTypeValue,
      portValue: _buildPortValue(localInfo.port),
      hostnameValue: _buildHostnameValue(resolvedHostname),
      hrefValue: _buildHrefValue(resolvedHref),
      deviceValue: _buildDeviceValue(localInfo.device),
      nameValue: EnvironmentNameValue()..parse(name),
      typeValue: EnvironmentTypeValue()..parse(type),
      themeDataSettings: _buildThemeDataSettings(themeDataSettings),
      tenantIdValue: tenantIdValue,
      profileTypeRegistry: _buildProfileTypeRegistry(profileTypes),
      mainDomainValue: mainDomainValue,
      domains: domains
          .map((domain) {
            final value = DomainValue();
            final parsed = value.tryParse(DomainValue.coerceRaw(domain));
            return parsed != null ? value : null;
          })
          .whereType<DomainValue>()
          .toList(growable: false),
      appDomains: appDomains
          .map((appDomain) => AppDomainValue()..parse(appDomain))
          .toList(growable: false),
      telemetrySettings: _buildTelemetrySettings(telemetry),
      telemetryContextSettings: _buildTelemetryContextSettings(
        telemetryRaw: telemetry,
        telemetryContextRaw: telemetryContext,
      ),
      firebaseSettings: _buildFirebaseSettings(firebase),
      pushSettings: _buildPushSettings(push),
      tenantDefaultOrigin: tenantDefaultOrigin,
      mapRadiusMinMetersValue: _buildDistanceValue(radiusBounds.minMeters),
      mapRadiusDefaultMetersValue:
          _buildDistanceValue(radiusBounds.defaultMeters),
      mapRadiusMaxMetersValue: _buildDistanceValue(radiusBounds.maxMeters),
      mapFilterCatalogKeysValue:
          AppDataMapFilterCatalogKeysValue(mapFilterCatalogKeys),
      mainIconLightUrl: _parseRequired(
        mainIconLightResolved,
        () => IconUrlValue(isRequired: true),
        'main_icon_light_url',
      ),
      mainIconDarkUrl: _parseRequired(
        mainIconDarkResolved,
        () => IconUrlValue(isRequired: true),
        'main_icon_dark_url',
      ),
      mainColor: _parseRequired(
        mainColorResolved,
        () => MainColorValue(isRequired: true, minLenght: 1),
        'main_color',
      ),
      mainLogoLightUrl: _parseRequired(
        mainLogoLightResolved,
        () => MainLogoUrlValue(isRequired: true),
        'main_logo_light_url',
      ),
      mainLogoDarkUrl: _parseRequired(
        mainLogoDarkResolved,
        () => MainLogoUrlValue(isRequired: true),
        'main_logo_dark_url',
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tenant_id': tenantId,
      'name': name,
      'type': type,
      'main_domain': mainDomain,
      'profile_types': profileTypes,
      'domains': domains,
      'app_domains': appDomains,
      'theme_data_settings': themeDataSettings,
      'icon_url': iconUrl,
      'main_color': mainColor,
      'main_logo_url': mainLogoUrl,
      'main_logo_light_url': mainLogoLightUrl,
      'main_logo_dark_url': mainLogoDarkUrl,
      'main_icon_light_url': mainIconLightUrl,
      'main_icon_dark_url': mainIconDarkUrl,
      'telemetry': telemetry,
      'telemetry_context': telemetryContext,
      'firebase': firebase,
      'push': push,
      'settings': settings,
    };
  }

  static Map<String, dynamic>? _normalizeTelemetry(Object? raw) {
    if (raw is Map) {
      final map =
          raw is Map<String, dynamic> ? raw : Map<String, dynamic>.from(raw);
      if (map['trackers'] is List) {
        final trackers = (map['trackers'] as List)
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
        return {
          ...map,
          'trackers': trackers,
        };
      }
      return Map<String, dynamic>.from(map);
    }
    if (raw is List) {
      final trackers = raw
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      return {
        'trackers': trackers,
      };
    }
    return null;
  }

  static ProfileTypeRegistry _buildProfileTypeRegistry(
    List<Map<String, dynamic>> rawTypes,
  ) {
    final types = ProfileTypeDefinitions();
    for (final rawType in rawTypes) {
      final type = rawType['type']?.toString().trim() ?? '';
      if (type.isEmpty) {
        continue;
      }
      final label = rawType['label']?.toString().trim();
      final capabilitiesRaw = rawType['capabilities'];
      final capabilitiesMap = capabilitiesRaw is Map
          ? Map<String, dynamic>.from(capabilitiesRaw)
          : const <String, dynamic>{};

      types.add(
        ProfileTypeDefinition(
          typeValue: ProfileTypeKeyValue(type),
          labelValue: ProfileTypeLabelValue(
            label == null || label.isEmpty ? type : label,
          ),
          visual: _buildProfileTypeVisual(
            rawType['visual'] ?? rawType['poi_visual'],
            typeAssetUrl: rawType['type_asset_url'],
          ),
          capabilities: ProfileTypeCapabilities(
            isFavoritableValue: ProfileTypeFlagValue(
              capabilitiesMap['is_favoritable'] == true,
            ),
            isPoiEnabledValue: ProfileTypeFlagValue(
              capabilitiesMap['is_poi_enabled'] == true,
            ),
            hasBioValue: ProfileTypeFlagValue(
              capabilitiesMap['has_bio'] == true,
            ),
            hasContentValue: ProfileTypeFlagValue(
              capabilitiesMap['has_content'] == true,
            ),
            hasTaxonomiesValue: ProfileTypeFlagValue(
              capabilitiesMap['has_taxonomies'] == true,
            ),
            hasAvatarValue: ProfileTypeFlagValue(
              capabilitiesMap['has_avatar'] == true,
            ),
            hasCoverValue: ProfileTypeFlagValue(
              capabilitiesMap['has_cover'] == true,
            ),
            hasEventsValue: ProfileTypeFlagValue(
              capabilitiesMap['has_events'] == true,
            ),
          ),
        ),
      );
    }
    return ProfileTypeRegistry(types: types);
  }

  static ProfileTypeVisual? _buildProfileTypeVisual(
    Object? rawVisual, {
    Object? typeAssetUrl,
  }) {
    if (rawVisual is! Map) {
      return null;
    }

    final visualMap = Map<String, dynamic>.from(rawVisual);
    final mode = _resolveProfileTypeVisualMode(visualMap);
    if (mode == null) {
      return null;
    }

    if (mode == ProfileTypeVisualMode.icon) {
      final icon = _readTrimmedString(visualMap['icon']);
      final color = _normalizeHexColor(visualMap['color']);
      final iconColor =
          _normalizeHexColor(visualMap['icon_color']) ?? '#FFFFFF';
      if (icon == null || color == null) {
        return null;
      }
      final iconValue = ProfileTypeVisualIconValue(icon);
      final colorValue = ProfileTypeVisualHexColorValue()..parse(color);
      final iconColorValue = ProfileTypeVisualHexColorValue()..parse(iconColor);
      return ProfileTypeVisual.icon(
        iconValue: iconValue,
        colorValue: colorValue,
        iconColorValue: iconColorValue,
      );
    }

    final imageSource = _resolveProfileTypeVisualImageSource(visualMap);
    if (imageSource == null) {
      return null;
    }
    return ProfileTypeVisual.image(
      imageSource: imageSource,
      imageUrlValue: _optionalProfileTypeImageUrlValue(
        _readTrimmedString(visualMap['image_url']) ??
            _readTrimmedString(typeAssetUrl),
      ),
    );
  }

  static ProfileTypeVisualMode? _resolveProfileTypeVisualMode(
    Map<String, dynamic> visualMap,
  ) {
    final rawMode = _readTrimmedString(visualMap['mode'])?.toLowerCase();
    switch (rawMode) {
      case 'icon':
        return ProfileTypeVisualMode.icon;
      case 'image':
        return ProfileTypeVisualMode.image;
    }

    final icon = _readTrimmedString(visualMap['icon']);
    final color = _normalizeHexColor(visualMap['color']);
    if (icon != null && color != null) {
      return ProfileTypeVisualMode.icon;
    }

    final imageSource = _readTrimmedString(visualMap['image_source']);
    if (imageSource != null) {
      return ProfileTypeVisualMode.image;
    }

    return null;
  }

  static ProfileTypeVisualImageSource? _resolveProfileTypeVisualImageSource(
    Map<String, dynamic> visualMap,
  ) {
    return switch (
        _readTrimmedString(visualMap['image_source'])?.toLowerCase()) {
      'avatar' => ProfileTypeVisualImageSource.avatar,
      'cover' => ProfileTypeVisualImageSource.cover,
      'type_asset' => ProfileTypeVisualImageSource.typeAsset,
      _ => null,
    };
  }

  static String? _readTrimmedString(Object? raw) {
    final value = raw?.toString().trim();
    if (value == null || value.isEmpty) {
      return null;
    }
    return value;
  }

  static String? _normalizeHexColor(Object? raw) {
    final value = _readTrimmedString(raw)?.toUpperCase();
    if (value == null) {
      return null;
    }
    if (RegExp(r'^#[0-9A-F]{6}$').hasMatch(value)) {
      return value;
    }
    if (RegExp(r'^[0-9A-F]{6}$').hasMatch(value)) {
      return '#$value';
    }
    return null;
  }

  static ThemeDataSettings _buildThemeDataSettings(
    Map<String, dynamic> themeSettings,
  ) {
    final brightnessValue = BrightnessValue()
      ..parse(themeSettings['brightness_default'] as String?);
    final primarySeedColor =
        (themeSettings['primary_seed_color'] as String?) ?? '#4FA0E3';
    final secondarySeedColor =
        (themeSettings['secondary_seed_color'] as String?) ?? '#E80D5D';

    return ThemeDataSettings(
      darkSchemeData: _buildColorSchemeData(
        brightness: 'dark',
        primarySeedColor: primarySeedColor,
        secondarySeedColor: secondarySeedColor,
      ),
      lightSchemeData: _buildColorSchemeData(
        brightness: 'light',
        primarySeedColor: primarySeedColor,
        secondarySeedColor: secondarySeedColor,
      ),
      brightnessDefault: brightnessValue.value == Brightness.dark
          ? Brightness.dark
          : Brightness.light,
    );
  }

  static ColorSchemeData _buildColorSchemeData({
    required String brightness,
    required String primarySeedColor,
    required String secondarySeedColor,
  }) {
    return ColorSchemeData(
      brightnessValue: BrightnessValue()..parse(brightness),
      primarySeedColorValue:
          ColorRequiredValue(defaultValue: primarySeedColor.toColor()),
      secondarySeedColorValue:
          ColorRequiredValue(defaultValue: secondarySeedColor.toColor()),
    );
  }

  static TelemetrySettings _buildTelemetrySettings(Map<String, dynamic>? raw) {
    final trackersRaw = raw == null ? null : raw['trackers'];
    if (trackersRaw is! List) {
      return const TelemetrySettings(trackers: <EventTrackerSettingsModel>[]);
    }

    final trackers = <EventTrackerSettingsModel>[];
    for (final item in trackersRaw) {
      if (item is Map<String, dynamic>) {
        trackers.add(EventTrackerSettingsModel.fromMap(item));
      } else if (item is Map) {
        trackers.add(
            EventTrackerSettingsModel.fromMap(Map<String, dynamic>.from(item)));
      }
    }

    return TelemetrySettings(trackers: List.unmodifiable(trackers));
  }

  static TelemetryContextSettings _buildTelemetryContextSettings({
    required Map<String, dynamic>? telemetryRaw,
    required Map<String, dynamic>? telemetryContextRaw,
  }) {
    final context = telemetryRaw ?? telemetryContextRaw;
    final minutes = _parsePositiveInt(
      context?['location_freshness_minutes'] ??
          context?['telemetry_location_freshness_minutes'],
    );

    return TelemetryContextSettings(
      locationFreshnessValue: _buildLocationFreshnessValueFromMinutes(
        minutes ?? TelemetryContextSettings.defaultLocationFreshnessMinutes,
      ),
    );
  }

  static FirebaseSettings? _buildFirebaseSettings(Map<String, dynamic>? raw) {
    if (raw == null) {
      return null;
    }

    final apiKey = raw['apiKey'] as String?;
    final appId = raw['appId'] as String?;
    final projectId = raw['projectId'] as String?;
    final messagingSenderId = raw['messagingSenderId'] as String?;
    final storageBucket = raw['storageBucket'] as String?;

    if ([apiKey, appId, projectId, messagingSenderId, storageBucket]
        .any((value) => value == null || value.trim().isEmpty)) {
      return null;
    }

    return FirebaseSettings(
      apiKeyValue: _buildRequiredTextValue(apiKey!),
      appIdValue: _buildRequiredTextValue(appId!),
      projectIdValue: _buildRequiredTextValue(projectId!),
      messagingSenderIdValue: _buildRequiredTextValue(messagingSenderId!),
      storageBucketValue: _buildRequiredTextValue(storageBucket!),
    );
  }

  static PushSettings? _buildPushSettings(Map<String, dynamic>? raw) {
    if (raw == null) {
      return null;
    }

    final parsedEnabled =
        raw['enabled'] is bool ? raw['enabled'] as bool : false;
    final parsedTypes = (raw['types'] is List)
        ? (raw['types'] as List)
            .map((entry) => entry.toString())
            .toList(growable: false)
        : const <String>[];
    final parsedThrottles = raw['throttles'] is Map<String, dynamic>
        ? Map<String, dynamic>.unmodifiable(
            raw['throttles'] as Map<String, dynamic>)
        : const <String, dynamic>{};

    return PushSettings(
      enabledValue: _buildEnabledValue(parsedEnabled),
      typeValues: PushTypesValue(parsedTypes),
      throttlesValue: PushThrottlesValue(parsedThrottles),
    );
  }

  static String _resolveOrigin(String mainDomainRaw) {
    final mainDomainStr = DomainValue.coerceRaw(mainDomainRaw);
    if (mainDomainStr.isEmpty) {
      throw ArgumentError('Environment missing required main_domain');
    }

    final domainValue = DomainValue();
    final parsed = domainValue.tryParse(mainDomainStr);
    if (parsed == null) {
      throw ArgumentError('Invalid main_domain: $mainDomainRaw');
    }

    return domainValue.value.origin;
  }

  static ({double minMeters, double defaultMeters, double maxMeters})
      _resolveRadiusBounds(Map<String, dynamic>? rawSettings) {
    final settings = rawSettings ?? const <String, dynamic>{};
    final mapUi = settings['map_ui'] is Map
        ? Map<String, dynamic>.from(settings['map_ui'] as Map)
        : const <String, dynamic>{};
    final radius = mapUi['radius'] is Map
        ? Map<String, dynamic>.from(mapUi['radius'] as Map)
        : const <String, dynamic>{};

    const defaultMinRadiusKm = 1.0;
    const defaultRadiusKm = 5.0;
    const defaultMaxRadiusKm = 50.0;

    final minKm = _parsePositiveDouble(radius['min_km'], defaultMinRadiusKm);
    final maxKmRaw = _parsePositiveDouble(radius['max_km'], defaultMaxRadiusKm);
    final maxKm = maxKmRaw < minKm ? minKm : maxKmRaw;
    final defaultKmRaw =
        _parsePositiveDouble(radius['default_km'], defaultRadiusKm);
    final defaultKm = defaultKmRaw.clamp(minKm, maxKm).toDouble();

    return (
      minMeters: minKm * 1000,
      defaultMeters: defaultKm * 1000,
      maxMeters: maxKm * 1000,
    );
  }

  static CityCoordinate? _resolveTenantDefaultOrigin(
    Map<String, dynamic>? rawSettings,
  ) {
    final settings = rawSettings ?? const <String, dynamic>{};
    final mapUi = settings['map_ui'] is Map
        ? Map<String, dynamic>.from(settings['map_ui'] as Map)
        : const <String, dynamic>{};
    final defaultOrigin = mapUi['default_origin'] is Map
        ? Map<String, dynamic>.from(mapUi['default_origin'] as Map)
        : const <String, dynamic>{};

    final lat = _parseDouble(defaultOrigin['lat']) ??
        _parseDouble(mapUi['default_origin.lat']);
    final lng = _parseDouble(defaultOrigin['lng']) ??
        _parseDouble(mapUi['default_origin.lng']);
    if (lat == null || lng == null) {
      return null;
    }

    try {
      final latitude = LatitudeValue()..parse(lat.toString());
      final longitude = LongitudeValue()..parse(lng.toString());
      return CityCoordinate(
        latitudeValue: latitude,
        longitudeValue: longitude,
      );
    } on Object {
      return null;
    }
  }

  static List<String> _resolveMapFilterCatalogKeys(
    Map<String, dynamic>? rawSettings,
  ) {
    final settings = rawSettings ?? const <String, dynamic>{};
    final mapUi = settings['map_ui'] is Map
        ? Map<String, dynamic>.from(settings['map_ui'] as Map)
        : const <String, dynamic>{};
    final rawFilters = mapUi['filters'];
    if (rawFilters is! List) {
      return const <String>[];
    }

    final ordered = <String>[];
    final seen = <String>{};
    for (final entry in rawFilters) {
      if (entry is! Map) {
        continue;
      }
      final map = Map<String, dynamic>.from(entry);
      final key = map['key']?.toString().trim().toLowerCase() ?? '';
      if (key.isEmpty || !seen.add(key)) {
        continue;
      }
      ordered.add(key);
    }
    return List<String>.unmodifiable(ordered);
  }

  static T _parseRequired<T extends ValueObject<dynamic>>(
    String? rawValue,
    T Function() builder,
    String fieldName,
  ) {
    if (rawValue == null || rawValue.isEmpty) {
      throw ArgumentError('AppData missing required field: $fieldName');
    }

    final valueObject = builder()..parse(rawValue);
    if (valueObject.value == null) {
      throw ArgumentError('AppData has invalid value for: $fieldName');
    }
    return valueObject;
  }

  static AppDataPortValue _buildPortValue(String? rawValue) {
    final value = AppDataPortValue()..parse(rawValue);
    return value;
  }

  static AppDataHostnameValue _buildHostnameValue(String rawValue) {
    final value = AppDataHostnameValue()..parse(rawValue);
    return value;
  }

  static AppDataHrefValue _buildHrefValue(String rawValue) {
    final value = AppDataHrefValue()..parse(rawValue);
    return value;
  }

  static AppDataRequiredTextValue _buildDeviceValue(String rawValue) {
    final value = AppDataRequiredTextValue()..parse(rawValue);
    return value;
  }

  static AppDataRequiredTextValue _buildRequiredTextValue(String rawValue) {
    final value = AppDataRequiredTextValue()..parse(rawValue);
    return value;
  }

  static PushEnabledValue _buildEnabledValue(bool rawValue) {
    final value = PushEnabledValue()..parse(rawValue.toString());
    return value;
  }

  static TelemetryLocationFreshnessValue
      _buildLocationFreshnessValueFromMinutes(
    int minutes,
  ) {
    final value = TelemetryLocationFreshnessValue(
      defaultValue: const Duration(
        minutes: TelemetryContextSettings.defaultLocationFreshnessMinutes,
      ),
    )..parse(minutes.toString());
    return value;
  }

  static DistanceInMetersValue _buildDistanceValue(double rawValue) {
    final value = DistanceInMetersValue()..parse(rawValue.toString());
    return value;
  }

  static int? _parsePositiveInt(Object? raw) {
    if (raw is int) {
      return raw > 0 ? raw : null;
    }
    if (raw is num) {
      final value = raw.toInt();
      return value > 0 ? value : null;
    }
    if (raw is String) {
      final value = int.tryParse(raw.trim());
      return value != null && value > 0 ? value : null;
    }
    return null;
  }

  static double _parsePositiveDouble(Object? raw, double fallback) {
    final value =
        raw is num ? raw.toDouble() : double.tryParse(raw?.toString() ?? '');
    if (value == null || value <= 0) {
      return fallback;
    }
    return value;
  }

  static ProfileTypeVisualImageUrlValue? _optionalProfileTypeImageUrlValue(
    String? raw,
  ) {
    if (raw == null) {
      return null;
    }
    return ProfileTypeVisualImageUrlValue(raw);
  }

  static double? _parseDouble(Object? raw) {
    if (raw is num) {
      return raw.toDouble();
    }
    return double.tryParse(raw?.toString() ?? '');
  }

  static String? _firstNonEmpty(String? primary, String? fallback) {
    final normalized = primary?.trim();
    if (normalized == null || normalized.isEmpty) {
      return fallback;
    }
    return normalized;
  }
}
