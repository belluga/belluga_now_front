class AppDataDTO {
  AppDataDTO({
    this.tenantId,
    required this.name,
    required this.type,
    required this.mainDomain,
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
  })  : domains = List.unmodifiable(domains ?? const []),
        appDomains = List.unmodifiable(appDomains ?? const []),
        telemetry = telemetry == null ? null : Map.unmodifiable(telemetry),
        telemetryContext =
            telemetryContext == null ? null : Map.unmodifiable(telemetryContext),
        firebase = firebase == null ? null : Map.unmodifiable(firebase),
        push = push == null ? null : Map.unmodifiable(push);

  final String? tenantId;
  final String name;
  final String type;
  final String mainDomain;
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

  factory AppDataDTO.fromJson(Map<String, dynamic> json) {
    final themeSettings = Map<String, dynamic>.unmodifiable(
      (json['theme_data_settings'] as Map<String, dynamic>? ??
          const <String, dynamic>{}),
    );

    return AppDataDTO(
      tenantId: json['tenant_id'] as String?,
      name: json['name'] as String? ?? '',
      type: json['type'] as String? ?? '',
      mainDomain: json['main_domain'] as String? ?? '',
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
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tenant_id': tenantId,
      'name': name,
      'type': type,
      'main_domain': mainDomain,
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
    };
  }

  static Map<String, dynamic>? _normalizeTelemetry(Object? raw) {
    if (raw is Map) {
      final map = raw is Map<String, dynamic>
          ? raw
          : Map<String, dynamic>.from(raw);
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
}
