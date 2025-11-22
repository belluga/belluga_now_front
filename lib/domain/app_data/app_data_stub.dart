import 'package:belluga_now/domain/app_data/app_type.dart';
import 'package:belluga_now/domain/app_data/value_objects/environment_name_value.dart';
import 'package:belluga_now/domain/app_data/value_objects/environment_type_value.dart';
import 'package:belluga_now/domain/tenant/value_objects/app_domain_value.dart';
import 'package:belluga_now/domain/tenant/value_objects/domain_value.dart';
import 'package:belluga_now/domain/tenant/value_objects/icon_url_value.dart';
import 'package:belluga_now/domain/tenant/value_objects/main_color_value.dart';
import 'package:belluga_now/domain/tenant/value_objects/main_logo_url_value.dart';
import 'package:belluga_now/domain/theme_data_settings/theme_data_settings.dart';

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
  
  // Extra fields for app owner avatar
  final IconUrlValue? iconUrl;
  final MainColorValue? mainColor;
  final MainLogoUrlValue? mainLogoUrl;

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
    this.iconUrl,
    this.mainColor,
    this.mainLogoUrl,
  });

  factory AppData.fromInitialization({
    required Map<String, dynamic> remoteData,
    required Map<String, dynamic> localInfo,
  }) {
    return AppData._(
      platformType: localInfo['platformType'].value,
      port: localInfo['port'],
      hostname: localInfo['hostname'],
      href: localInfo['href'],
      device: localInfo['device'],
      nameValue: EnvironmentNameValue()..parse(remoteData['name']),
      themeDataSettings:
          ThemeDataSettings.fromJson(remoteData['theme_data_settings']),
      mainDomainValue:
          DomainValue(defaultValue: Uri.parse(remoteData['main_domain'])),
      typeValue: EnvironmentTypeValue()..parse(remoteData['type']),
      domains: (remoteData['domains'] as List<dynamic>?)
              ?.map((domain) => DomainValue(defaultValue: Uri.parse(domain)))
              .toList() ??
          [],
      appDomains: (remoteData['app_domains'] as List<dynamic>?)
          ?.map((appDomain) => AppDomainValue()..parse(appDomain))
          .toList(),
      iconUrl: remoteData['icon_url'] != null 
          ? (IconUrlValue()..parse(remoteData['icon_url'])) 
          : null,
      mainColor: remoteData['main_color'] != null 
          ? (MainColorValue()..parse(remoteData['main_color'])) 
          : null,
      mainLogoUrl: remoteData['main_logo_url'] != null 
          ? (MainLogoUrlValue()..parse(remoteData['main_logo_url'])) 
          : null,
    );
  }

  AppType get appType => typeValue.value;

  String get schema => href.split(hostname).first;

  @override
  String toString() {
    return 'AppData(port: $port, hostname: $hostname, href: $href, device: $device)';
  }
}
