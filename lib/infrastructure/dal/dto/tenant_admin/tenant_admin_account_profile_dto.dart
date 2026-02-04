import 'package:belluga_now/infrastructure/dal/dto/tenant_admin/tenant_admin_taxonomy_term_dto.dart';

class TenantAdminAccountProfileDTO {
  const TenantAdminAccountProfileDTO({
    required this.id,
    required this.accountId,
    required this.profileType,
    required this.displayName,
    this.slug,
    this.avatarUrl,
    this.coverUrl,
    this.bio,
    this.locationLat,
    this.locationLng,
    this.taxonomyTerms = const [],
    this.ownershipState,
  });

  final String id;
  final String accountId;
  final String profileType;
  final String displayName;
  final String? slug;
  final String? avatarUrl;
  final String? coverUrl;
  final String? bio;
  final double? locationLat;
  final double? locationLng;
  final List<TenantAdminTaxonomyTermDTO> taxonomyTerms;
  final String? ownershipState;

  factory TenantAdminAccountProfileDTO.fromJson(Map<String, dynamic> json) {
    final location = json['location'];
    double? lat;
    double? lng;
    if (location is Map<String, dynamic>) {
      lat = _toDouble(location['lat']);
      lng = _toDouble(location['lng']);
    }
    final taxonomyRaw = json['taxonomy_terms'];
    final terms = <TenantAdminTaxonomyTermDTO>[];
    if (taxonomyRaw is List) {
      for (final entry in taxonomyRaw) {
        if (entry is Map<String, dynamic>) {
          terms.add(TenantAdminTaxonomyTermDTO.fromJson(entry));
        }
      }
    }
    return TenantAdminAccountProfileDTO(
      id: json['id']?.toString() ?? '',
      accountId: json['account_id']?.toString() ?? '',
      profileType: json['profile_type']?.toString() ?? '',
      displayName: json['display_name']?.toString() ?? '',
      slug: json['slug']?.toString(),
      avatarUrl: json['avatar_url']?.toString(),
      coverUrl: json['cover_url']?.toString(),
      bio: json['bio']?.toString(),
      locationLat: lat,
      locationLng: lng,
      taxonomyTerms: terms,
      ownershipState: json['ownership_state']?.toString(),
    );
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }
}
