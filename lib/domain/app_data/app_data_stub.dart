import 'package:belluga_now/domain/app_data/app_type.dart';
import 'package:belluga_now/domain/app_data/value_objects/environment_name_value.dart';
import 'package:belluga_now/domain/app_data/value_objects/environment_type_value.dart';
import 'package:belluga_now/domain/tenant/value_objects/app_domain_value.dart';
import 'package:belluga_now/domain/tenant/value_objects/domain_value.dart';
import 'package:belluga_now/domain/tenant/value_objects/icon_url_value.dart';
import 'package:belluga_now/domain/tenant/value_objects/main_color_value.dart';
import 'package:belluga_now/domain/tenant/value_objects/main_logo_url_value.dart';
import 'package:belluga_now/domain/theme_data_settings/theme_data_settings.dart';
import 'package:value_object_pattern/value_object.dart';

class AppData {
  final AppType platformType;
  final String? port;
  final String hostname;
  final String href;
  final String device;

  final EnvironmentNameValue nameValue;
  final EnvironmentTypeValue typeValue;
  final ThemeDataSettings themeDataSettings;
  final DomainValue mainDomainValue;
  final List<DomainValue> domains;
  final List<AppDomainValue>? appDomains;

  // Extra fields for app owner avatar/branding
  final IconUrlValue mainIconLightUrl;
  final IconUrlValue mainIconDarkUrl;
  final MainColorValue mainColor;
  final MainLogoUrlValue mainLogoLightUrl;
  final MainLogoUrlValue mainLogoDarkUrl;

  AppData._({
    required this.platformType,
    required this.port,
    required this.hostname,
    required this.href,
    required this.device,
    required this.nameValue,
    required this.typeValue,
    required this.themeDataSettings,
    required this.mainDomainValue,
    required this.domains,
    required this.appDomains,
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
    // Support either DTO or raw map (fallback)
    final Map<String, dynamic> map = remoteData is Map<String, dynamic>
        ? remoteData
        : {
            'name': remoteData.name,
            'type': remoteData.type,
            'main_domain': remoteData.mainDomain,
            'domains': remoteData.domains,
            'app_domains': remoteData.appDomains,
            'theme_data_settings': remoteData.themeDataSettings,
            'icon_url': remoteData.iconUrl,
            'main_color': remoteData.mainColor,
            'main_icon_light_url': remoteData.mainIconLightUrl,
            'main_icon_dark_url': remoteData.mainIconDarkUrl,
            'main_logo_url': remoteData.mainLogoUrl,
            'main_logo_light_url': remoteData.mainLogoLightUrl,
            'main_logo_dark_url': remoteData.mainLogoDarkUrl,
          };

    final mainIconLightRaw =
        map['main_icon_light_url'] ?? map['icon_url'] as String?;
    final mainIconDarkRaw =
        map['main_icon_dark_url'] ?? map['icon_url'] as String?;
    final mainLogoLightRaw =
        map['main_logo_light_url'] ?? map['main_logo_url'] as String?;
    final mainLogoDarkRaw =
        map['main_logo_dark_url'] ?? map['main_logo_url'] as String?;
    // `main_color` is no longer sent by the backend; use the seed color as the authoritative value.
    final mainColorRaw = (map['main_color'] as String?) ??
        (map['theme_data_settings'] is Map<String, dynamic>
            ? (map['theme_data_settings'] as Map<String, dynamic>)[
                'primary_seed_color'] as String?
            : null);

    return AppData._(
      platformType: localInfo['platformType'].value,
      port: localInfo['port'],
      hostname: localInfo['hostname'],
      href: localInfo['href'],
      device: localInfo['device'],
      nameValue: EnvironmentNameValue()..parse(map['name']),
      themeDataSettings: ThemeDataSettings.fromJson(map['theme_data_settings']),
      mainDomainValue: DomainValue(defaultValue: Uri.parse(map['main_domain'])),
      typeValue: EnvironmentTypeValue()..parse(map['type']),
      domains: (map['domains'] as List<dynamic>?)
              ?.map((domain) => DomainValue(defaultValue: Uri.parse(domain)))
              .toList() ??
          [],
      appDomains: (map['app_domains'] as List<dynamic>?)
          ?.map((appDomain) => AppDomainValue()..parse(appDomain))
          .toList(),
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

  AppType get appType => typeValue.value;

  IconUrlValue get iconUrl => mainIconDarkUrl;

  MainLogoUrlValue get mainLogoUrl => mainLogoDarkUrl;

  String get schema => href.split(hostname).first;

  /// Convenience constructor when a typed DTO is already available.
  factory AppData.fromDto({
    required dynamic dto,
    required Map<String, dynamic> localInfo,
  }) {
    // Delegate to fromInitialization; it already accepts DTO or map.
    return AppData.fromInitialization(remoteData: dto, localInfo: localInfo);
  }

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
}
