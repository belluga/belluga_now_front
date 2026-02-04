class TenantAdminOrganization {
  const TenantAdminOrganization({
    required this.id,
    required this.name,
    this.slug,
    this.description,
  });

  final String id;
  final String name;
  final String? slug;
  final String? description;
}
