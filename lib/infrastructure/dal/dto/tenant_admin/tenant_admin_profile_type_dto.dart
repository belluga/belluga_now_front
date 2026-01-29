class TenantAdminProfileTypeDTO {
  const TenantAdminProfileTypeDTO({
    required this.type,
    required this.label,
    required this.allowedTaxonomies,
    required this.isFavoritable,
    required this.isPoiEnabled,
  });

  final String type;
  final String label;
  final List<String> allowedTaxonomies;
  final bool isFavoritable;
  final bool isPoiEnabled;

  factory TenantAdminProfileTypeDTO.fromJson(Map<String, dynamic> json) {
    final allowed = <String>[];
    final raw = json['allowed_taxonomies'];
    if (raw is List) {
      for (final entry in raw) {
        if (entry != null) {
          allowed.add(entry.toString());
        }
      }
    }
    final capabilities = json['capabilities'];
    bool isFavoritable = false;
    bool isPoiEnabled = false;
    if (capabilities is Map<String, dynamic>) {
      isFavoritable = capabilities['is_favoritable'] == true;
      isPoiEnabled = capabilities['is_poi_enabled'] == true;
    }
    return TenantAdminProfileTypeDTO(
      type: json['type']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      allowedTaxonomies: allowed,
      isFavoritable: isFavoritable,
      isPoiEnabled: isPoiEnabled,
    );
  }
}
