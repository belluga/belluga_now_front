class TenantAdminProfileTypeDefinition {
  const TenantAdminProfileTypeDefinition({
    required this.type,
    required this.label,
    required this.allowedTaxonomies,
    required this.capabilities,
  });

  final String type;
  final String label;
  final List<String> allowedTaxonomies;
  final TenantAdminProfileTypeCapabilities capabilities;
}

class TenantAdminProfileTypeCapabilities {
  const TenantAdminProfileTypeCapabilities({
    required this.isFavoritable,
    required this.isPoiEnabled,
  });

  final bool isFavoritable;
  final bool isPoiEnabled;
}
