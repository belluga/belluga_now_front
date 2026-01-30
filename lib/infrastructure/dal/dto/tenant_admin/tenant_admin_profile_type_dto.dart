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
      isFavoritable = _parseBool(capabilities['is_favoritable']);
      isPoiEnabled = _parseBool(capabilities['is_poi_enabled']);
    }
    return TenantAdminProfileTypeDTO(
      type: json['type']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      allowedTaxonomies: allowed,
      isFavoritable: isFavoritable,
      isPoiEnabled: isPoiEnabled,
    );
  }

  static bool _parseBool(dynamic value) {
    if (value == true) return true;
    if (value is num) return value != 0;
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      return normalized == 'true' || normalized == '1' || normalized == 'yes';
    }
    return false;
  }
}
