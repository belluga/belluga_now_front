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
    required this.hasBio,
    required this.hasContent,
    required this.hasTaxonomies,
    required this.hasAvatar,
    required this.hasCover,
    required this.hasEvents,
  });

  final bool isFavoritable;
  final bool isPoiEnabled;
  final bool hasBio;
  final bool hasContent;
  final bool hasTaxonomies;
  final bool hasAvatar;
  final bool hasCover;
  final bool hasEvents;
}
