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
import 'package:belluga_now/domain/app_data/value_object/environment_name_value.dart';
import 'package:belluga_now/domain/app_data/value_object/environment_type_value.dart';
import 'package:belluga_now/domain/app_data/value_object/platform_type_value.dart';
import 'package:belluga_now/domain/map/value_objects/city_coordinate.dart';
import 'package:belluga_now/domain/map/value_objects/distance_in_meters_value.dart';
import 'package:belluga_now/domain/map/value_objects/latitude_value.dart';
import 'package:belluga_now/domain/map/value_objects/longitude_value.dart';
import 'package:belluga_now/domain/partners/profile_type_registry.dart';
import 'package:belluga_now/domain/tenant/value_objects/icon_url_value.dart';
import 'package:belluga_now/domain/tenant/value_objects/main_color_value.dart';
import 'package:belluga_now/domain/tenant/value_objects/main_logo_url_value.dart';
import 'package:belluga_now/domain/tenant/value_objects/tenant_id_value.dart';
import 'package:belluga_now/domain/theme_data_settings/theme_data_settings.dart';
import 'package:value_object_pattern/value_object.dart';

/// Unified application configuration model (all platforms).
class AppData {
  static const double _defaultMinRadiusKm = 1.0;
  static const double _defaultRadiusKm = 5.0;
  static const double _defaultMaxRadiusKm = 50.0;

  final PlatformTypeValue platformType;
  final AppDataPortValue portValue;
  final AppDataHostnameValue hostnameValue;
  final AppDataHrefValue hrefValue;
  final AppDataRequiredTextValue deviceValue;

  final EnvironmentNameValue nameValue;
  final EnvironmentTypeValue typeValue;
  final ThemeDataSettings themeDataSettings;
  final TenantIdValue tenantIdValue;
  final ProfileTypeRegistry profileTypeRegistry;
  final DomainValue mainDomainValue;
  final List<DomainValue> domains;
  final List<AppDomainValue>? appDomains;
  final TelemetrySettings telemetrySettings;
  final TelemetryContextSettings telemetryContextSettings;
  final FirebaseSettings? firebaseSettings;
  final PushSettings? pushSettings;
  final CityCoordinate? tenantDefaultOrigin;
  final DistanceInMetersValue mapRadiusMinMetersValue;
  final DistanceInMetersValue mapRadiusDefaultMetersValue;
  final DistanceInMetersValue mapRadiusMaxMetersValue;
  final AppDataMapFilterCatalogKeysValue mapFilterCatalogKeysValue;

  final IconUrlValue mainIconLightUrl;
  final IconUrlValue mainIconDarkUrl;
  final MainColorValue mainColor;
  final MainLogoUrlValue mainLogoLightUrl;
  final MainLogoUrlValue mainLogoDarkUrl;

  AppData._({
    required this.platformType,
    required this.portValue,
    required this.hostnameValue,
    required this.hrefValue,
    required this.deviceValue,
    required this.nameValue,
    required this.typeValue,
    required this.themeDataSettings,
    required this.tenantIdValue,
    required this.profileTypeRegistry,
    required this.mainDomainValue,
    required this.domains,
    required this.appDomains,
    required this.telemetrySettings,
    required this.telemetryContextSettings,
    required this.firebaseSettings,
    required this.pushSettings,
    required this.tenantDefaultOrigin,
    required this.mapRadiusMinMetersValue,
    required this.mapRadiusDefaultMetersValue,
    required this.mapRadiusMaxMetersValue,
    required this.mapFilterCatalogKeysValue,
    required this.mainIconLightUrl,
    required this.mainIconDarkUrl,
    required this.mainColor,
    required this.mainLogoLightUrl,
    required this.mainLogoDarkUrl,
  });

  factory AppData.fromInitialization({
    required dynamic remoteData,
    required Map<String, dynamic> localInfo,
  }) {
    final Map<String, dynamic> map = remoteData is Map<String, dynamic>
        ? remoteData
        : {
            'name': remoteData.name,
            'type': remoteData.type,
            'main_domain': remoteData.mainDomain,
            'profile_types': remoteData.profileTypes,
            'domains': remoteData.domains,
            'app_domains': remoteData.appDomains,
            'theme_data_settings': remoteData.themeDataSettings,
            'main_color': remoteData.mainColor,
            'tenant_id': remoteData.tenantId,
            'telemetry': remoteData.telemetry,
            'telemetry_context': remoteData.telemetryContext,
            'firebase': remoteData.firebase,
            'push': remoteData.push,
            'settings': remoteData.settings,
          };

    final radiusBounds = _resolveRadiusBounds(map['settings']);
    final tenantDefaultOrigin = _resolveTenantDefaultOrigin(map['settings']);
    final mapFilterCatalogKeys = _resolveMapFilterCatalogKeys(map['settings']);

    final origin = _resolveOrigin(map: map);
    final mainIconLightRaw = '$origin/icon-light.png';
    final mainIconDarkRaw = '$origin/icon-dark.png';
    final mainLogoLightRaw = '$origin/logo-light.png';
    final mainLogoDarkRaw = '$origin/logo-dark.png';
    final mainColorRaw = (map['main_color'] as String?) ??
        (map['theme_data_settings'] is Map<String, dynamic>
            ? (map['theme_data_settings']
                as Map<String, dynamic>)['primary_seed_color'] as String?
            : null);

    final mainDomain = DomainValue()
      ..parse(DomainValue.coerceRaw(map['main_domain']));
    final tenantIdValue = TenantIdValue()..parse(map['tenant_id']?.toString());
    final profileTypeRegistry = ProfileTypeRegistry.fromJsonList(
      map['profile_types'] as List<dynamic>?,
    );
    final telemetryRaw = map['telemetry'];
    final telemetrySettings = TelemetrySettings.fromRaw(telemetryRaw);
    final telemetryContextRaw =
        telemetryRaw is Map ? telemetryRaw : map['telemetry_context'];
    final telemetryContextSettings =
        TelemetryContextSettings.fromRaw(telemetryContextRaw);
    final firebaseSettings =
        FirebaseSettings.tryFromMap(map['firebase'] as Map<String, dynamic>?);
    final pushSettings =
        PushSettings.tryFromMap(map['push'] as Map<String, dynamic>?);

    final platformType = localInfo['platformType'] as PlatformTypeValue;
    final resolvedPlatform =
        platformType.value ?? platformType.defaultValue ?? AppType.mobile;
    final isWeb = resolvedPlatform == AppType.web;
    final resolvedHostname =
        isWeb ? localInfo['hostname'] as String : mainDomain.value.host;
    final resolvedHref =
        isWeb ? localInfo['href'] as String : mainDomain.value.toString();

    return AppData._(
      platformType: platformType,
      portValue: _buildPortValue(localInfo['port'] as String?),
      hostnameValue: _buildHostnameValue(resolvedHostname),
      hrefValue: _buildHrefValue(resolvedHref),
      deviceValue: _buildDeviceValue(localInfo['device'] as String),
      nameValue: EnvironmentNameValue()..parse(map['name']),
      themeDataSettings: ThemeDataSettings.fromJson(map['theme_data_settings']),
      tenantIdValue: tenantIdValue,
      profileTypeRegistry: profileTypeRegistry,
      mainDomainValue: mainDomain,
      typeValue: EnvironmentTypeValue()..parse(map['type']),
      domains: (map['domains'] as List<dynamic>?)
              ?.map((domain) {
                final value = DomainValue();
                final parsed = value.tryParse(DomainValue.coerceRaw(domain));
                return parsed != null ? value : null;
              })
              .whereType<DomainValue>()
              .toList() ??
          [],
      appDomains: (map['app_domains'] as List<dynamic>?)
          ?.map((appDomain) => AppDomainValue()..parse(appDomain))
          .toList(),
      telemetrySettings: telemetrySettings,
      telemetryContextSettings: telemetryContextSettings,
      firebaseSettings: firebaseSettings,
      pushSettings: pushSettings,
      tenantDefaultOrigin: tenantDefaultOrigin,
      mapRadiusMinMetersValue: _buildDistanceValue(radiusBounds.minMeters),
      mapRadiusDefaultMetersValue:
          _buildDistanceValue(radiusBounds.defaultMeters),
      mapRadiusMaxMetersValue: _buildDistanceValue(radiusBounds.maxMeters),
      mapFilterCatalogKeysValue:
          AppDataMapFilterCatalogKeysValue(mapFilterCatalogKeys),
      mainIconLightUrl: _parseRequired(
        mainIconLightRaw,
        () => IconUrlValue(isRequired: true),
        'main_icon_light_url',
      ),
      mainIconDarkUrl: _parseRequired(
        mainIconDarkRaw,
        () => IconUrlValue(isRequired: true),
        'main_icon_dark_url',
      ),
      mainColor: _parseRequired(
        mainColorRaw,
        () => MainColorValue(isRequired: true, minLenght: 1),
        'main_color',
      ),
      mainLogoLightUrl: _parseRequired(
        mainLogoLightRaw,
        () => MainLogoUrlValue(isRequired: true),
        'main_logo_light_url',
      ),
      mainLogoDarkUrl: _parseRequired(
        mainLogoDarkRaw,
        () => MainLogoUrlValue(isRequired: true),
        'main_logo_dark_url',
      ),
    );
  }

  AppType get appType =>
      platformType.value ?? platformType.defaultValue ?? AppType.mobile;

  String? get port => portValue.nullableValue;
  String get hostname => hostnameValue.value;
  String get href => hrefValue.value;
  String get device => deviceValue.value;
  double get mapRadiusMinMeters => mapRadiusMinMetersValue.value;
  double get mapRadiusDefaultMeters => mapRadiusDefaultMetersValue.value;
  double get mapRadiusMaxMeters => mapRadiusMaxMetersValue.value;
  List<String> get mapFilterCatalogKeys => mapFilterCatalogKeysValue.value;

  IconUrlValue get iconUrl => mainIconDarkUrl;

  MainLogoUrlValue get mainLogoUrl => mainLogoDarkUrl;

  String get schema => href.split(hostname).first;

  @override
  String toString() {
    return 'AppData(port: $port, hostname: $hostname, href: $href, device: $device)';
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

  static DistanceInMetersValue _buildDistanceValue(double rawValue) {
    final value = DistanceInMetersValue()..parse(rawValue.toString());
    return value;
  }

  static String _resolveOrigin({
    required Map<String, dynamic> map,
  }) {
    final mainDomainRaw = map['main_domain'];
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
      _resolveRadiusBounds(dynamic rawSettings) {
    final settings = rawSettings is Map
        ? Map<String, dynamic>.from(rawSettings)
        : const <String, dynamic>{};
    final mapUi = settings['map_ui'] is Map
        ? Map<String, dynamic>.from(settings['map_ui'] as Map)
        : const <String, dynamic>{};
    final radius = mapUi['radius'] is Map
        ? Map<String, dynamic>.from(mapUi['radius'] as Map)
        : const <String, dynamic>{};

    final minKm = _parsePositiveDouble(radius['min_km'], _defaultMinRadiusKm);
    final maxKmRaw =
        _parsePositiveDouble(radius['max_km'], _defaultMaxRadiusKm);
    final maxKm = maxKmRaw < minKm ? minKm : maxKmRaw;
    final defaultKmRaw =
        _parsePositiveDouble(radius['default_km'], _defaultRadiusKm);
    final defaultKm = defaultKmRaw.clamp(minKm, maxKm).toDouble();

    return (
      minMeters: minKm * 1000,
      defaultMeters: defaultKm * 1000,
      maxMeters: maxKm * 1000,
    );
  }

  static double _parsePositiveDouble(dynamic raw, double fallback) {
    final value =
        raw is num ? raw.toDouble() : double.tryParse(raw?.toString() ?? '');
    if (value == null || value <= 0) {
      return fallback;
    }
    return value;
  }

  static CityCoordinate? _resolveTenantDefaultOrigin(dynamic rawSettings) {
    final settings = rawSettings is Map
        ? Map<String, dynamic>.from(rawSettings)
        : const <String, dynamic>{};
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

  static List<String> _resolveMapFilterCatalogKeys(dynamic rawSettings) {
    final settings = rawSettings is Map
        ? Map<String, dynamic>.from(rawSettings)
        : const <String, dynamic>{};
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

  static double? _parseDouble(dynamic raw) {
    if (raw is num) {
      return raw.toDouble();
    }
    return double.tryParse(raw?.toString() ?? '');
  }
}
