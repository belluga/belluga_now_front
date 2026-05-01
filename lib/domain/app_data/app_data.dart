import 'package:belluga_now/domain/app_data/app_type.dart';
import 'package:belluga_now/domain/app_data/app_publication_settings.dart';
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
import 'package:belluga_now/domain/partners/profile_type_registry.dart';
import 'package:belluga_now/domain/tenant/value_objects/icon_url_value.dart';
import 'package:belluga_now/domain/tenant/value_objects/main_color_value.dart';
import 'package:belluga_now/domain/tenant/value_objects/main_logo_url_value.dart';
import 'package:belluga_now/domain/tenant/value_objects/tenant_id_value.dart';
import 'package:belluga_now/domain/theme_data_settings/theme_data_settings.dart';
import 'package:belluga_now/domain/value_objects/domain_boolean_value.dart';

/// Unified application configuration model (all platforms).
class AppData {
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
  final DomainBooleanValue phoneOtpSmsFallbackEnabledValue;
  final AppPublicationSettings publicationSettings;
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

  AppData({
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
    DomainBooleanValue? phoneOtpSmsFallbackEnabledValue,
    AppPublicationSettings? publicationSettings,
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
  })  : phoneOtpSmsFallbackEnabledValue =
            phoneOtpSmsFallbackEnabledValue ?? _defaultFalseBooleanValue(),
        publicationSettings =
            publicationSettings ?? AppPublicationSettings.empty();

  AppType get appType =>
      platformType.value ?? platformType.defaultValue ?? AppType.mobile;

  String? get port => portValue.nullableValue;
  String get hostname => hostnameValue.value;
  String get href => hrefValue.value;
  String get device => deviceValue.value;
  double get mapRadiusMinMeters => mapRadiusMinMetersValue.value;
  double get mapRadiusDefaultMeters => mapRadiusDefaultMetersValue.value;
  double get mapRadiusMaxMeters => mapRadiusMaxMetersValue.value;
  bool get phoneOtpSmsFallbackEnabled => phoneOtpSmsFallbackEnabledValue.value;
  AppDataMapFilterCatalogKeysValue get mapFilterCatalogKeys =>
      mapFilterCatalogKeysValue;

  IconUrlValue get iconMUrl => mainIconDarkUrl;

  MainLogoUrlValue get mainLogoUrl => mainLogoDarkUrl;

  String get schema => href.split(hostname).first;

  static DomainBooleanValue _defaultFalseBooleanValue() {
    return DomainBooleanValue()..parse('false');
  }

  @override
  String toString() {
    return 'AppData(port: $port, hostname: $hostname, href: $href, device: $device)';
  }
}
