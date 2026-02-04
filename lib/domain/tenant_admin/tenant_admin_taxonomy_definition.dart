class TenantAdminTaxonomyDefinition {
  const TenantAdminTaxonomyDefinition({
    required this.id,
    required this.slug,
    required this.name,
    required this.appliesTo,
    required this.icon,
    required this.color,
  });

  final String id;
  final String slug;
  final String name;
  final List<String> appliesTo;
  final String? icon;
  final String? color;

  bool appliesToTarget(String target) {
    return appliesTo.contains(target);
  }
}
