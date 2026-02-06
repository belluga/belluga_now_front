class TenantAdminTaxonomy {
  const TenantAdminTaxonomy({
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
}
