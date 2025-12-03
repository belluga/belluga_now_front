class AppDataDTO {
  const AppDataDTO({
    required this.name,
    required this.type,
    required this.mainDomain,
    required this.domains,
    required this.appDomains,
    required this.themeDataSettings,
    this.iconUrl,
    this.mainColor,
    this.mainLogoUrl,
    this.mainLogoLightUrl,
    this.mainLogoDarkUrl,
    this.mainIconLightUrl,
    this.mainIconDarkUrl,
  });

  final String name;
  final String type;
  final String mainDomain;
  final List<String> domains;
  final List<String> appDomains;
  final Map<String, dynamic> themeDataSettings;
  final String? iconUrl;
  final String? mainColor;
  final String? mainLogoUrl;
  final String? mainLogoLightUrl;
  final String? mainLogoDarkUrl;
  final String? mainIconLightUrl;
  final String? mainIconDarkUrl;

  factory AppDataDTO.fromJson(Map<String, dynamic> json) {
    return AppDataDTO(
      name: json['name'] as String? ?? '',
      type: json['type'] as String? ?? '',
      mainDomain: json['main_domain'] as String? ?? '',
      domains: (json['domains'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .toList(),
      appDomains: (json['app_domains'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .toList(),
      themeDataSettings:
          (json['theme_data_settings'] as Map<String, dynamic>? ?? const {}),
      iconUrl: json['icon_url'] as String?,
      mainColor: json['main_color'] as String?,
      mainLogoUrl: json['main_logo_url'] as String?,
      mainLogoLightUrl: json['main_logo_light_url'] as String?,
      mainLogoDarkUrl: json['main_logo_dark_url'] as String?,
      mainIconLightUrl: json['main_icon_light_url'] as String?,
      mainIconDarkUrl: json['main_icon_dark_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
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
    };
  }
}
