class TenantAdminStaticProfileTypeDefinition {
  const TenantAdminStaticProfileTypeDefinition({
    required this.type,
    required this.label,
    required this.allowedTaxonomies,
    required this.capabilities,
  });

  final String type;
  final String label;
  final List<String> allowedTaxonomies;
  final TenantAdminStaticProfileTypeCapabilities capabilities;
}

class TenantAdminStaticProfileTypeCapabilities {
  const TenantAdminStaticProfileTypeCapabilities({
    required this.isPoiEnabled,
    required this.hasBio,
    required this.hasTaxonomies,
    required this.hasAvatar,
    required this.hasCover,
    required this.hasContent,
  });

  final bool isPoiEnabled;
  final bool hasBio;
  final bool hasTaxonomies;
  final bool hasAvatar;
  final bool hasCover;
  final bool hasContent;
}
