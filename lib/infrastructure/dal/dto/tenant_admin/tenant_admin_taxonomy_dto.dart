class TenantAdminTaxonomyDTO {
  const TenantAdminTaxonomyDTO({
    required this.id,
    required this.slug,
    required this.name,
    required this.appliesTo,
    this.icon,
    this.color,
  });

  final String id;
  final String slug;
  final String name;
  final List<String> appliesTo;
  final String? icon;
  final String? color;

  factory TenantAdminTaxonomyDTO.fromJson(Map<String, dynamic> json) {
    final appliesRaw = json['applies_to'];
    final applies = <String>[];
    if (appliesRaw is List) {
      for (final entry in appliesRaw) {
        if (entry == null) continue;
        applies.add(entry.toString());
      }
    }
    return TenantAdminTaxonomyDTO(
      id: json['id']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      appliesTo: applies,
      icon: json['icon']?.toString(),
      color: json['color']?.toString(),
    );
  }
}
