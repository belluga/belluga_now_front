import 'package:belluga_now/infrastructure/dal/dto/tenant_admin/tenant_admin_taxonomy_term_dto.dart';

class TenantAdminStaticAssetDTO {
  const TenantAdminStaticAssetDTO({
    required this.id,
    required this.profileType,
    required this.displayName,
    required this.slug,
    required this.isActive,
    required this.taxonomyTerms,
    this.avatarUrl,
    this.coverUrl,
    this.bio,
    this.content,
    this.locationLat,
    this.locationLng,
  });

  final String id;
  final String profileType;
  final String displayName;
  final String slug;
  final bool isActive;
  final String? avatarUrl;
  final String? coverUrl;
  final String? bio;
  final String? content;
  final List<TenantAdminTaxonomyTermDTO> taxonomyTerms;
  final double? locationLat;
  final double? locationLng;

  factory TenantAdminStaticAssetDTO.fromJson(Map<String, dynamic> json) {
    final taxonomyTerms = <TenantAdminTaxonomyTermDTO>[];
    final rawTerms = json['taxonomy_terms'];
    if (rawTerms is List) {
      for (final entry in rawTerms) {
        if (entry is Map<String, dynamic>) {
          taxonomyTerms.add(TenantAdminTaxonomyTermDTO.fromJson(entry));
        }
      }
    }
    final location = json['location'];
    double? lat;
    double? lng;
    if (location is Map<String, dynamic>) {
      lat = _parseDouble(location['lat']);
      lng = _parseDouble(location['lng']);
    }
    return TenantAdminStaticAssetDTO(
      id: json['id']?.toString() ?? '',
      profileType: json['profile_type']?.toString() ?? '',
      displayName: json['display_name']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      avatarUrl: json['avatar_url']?.toString(),
      coverUrl: json['cover_url']?.toString(),
      bio: json['bio']?.toString(),
      content: json['content']?.toString(),
      taxonomyTerms: taxonomyTerms,
      locationLat: lat,
      locationLng: lng,
      isActive: _parseBool(json['is_active']),
    );
  }

  static double? _parseDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
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
