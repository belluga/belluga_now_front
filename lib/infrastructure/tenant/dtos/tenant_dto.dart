class TenantDto {
  final String name;
  final String subdomain;
  final String mainLogoUrl;
  final String? iconUrl;
  final String? mainColor;
  final List<String>? domains;
  final List<String>? appDomains;

  TenantDto({
    required this.name,
    required this.subdomain,
    required this.mainLogoUrl,
    this.iconUrl,
    this.mainColor,
    this.domains,
    this.appDomains,
  });

  factory TenantDto.fromJson(Map<String, dynamic> json) {
    return TenantDto(
      name: json['name'] as String,
      subdomain: json['subdomain'] as String,
      mainLogoUrl: json['main_logo_url'] as String,
      iconUrl: json['icon_url'] as String?,
      mainColor: json['main_color'] as String?,
      domains:
          (json['domains'] as List<dynamic>?)?.map((e) => e as String).toList(),
      appDomains: (json['app_domains'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'subdomain': subdomain,
      'main_logo_url': mainLogoUrl,
      'icon_url': iconUrl,
      'main_color': mainColor,
      'domains': domains,
      'app_domains': appDomains,
    };
  }
}
