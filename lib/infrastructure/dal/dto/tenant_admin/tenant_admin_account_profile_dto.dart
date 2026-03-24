import 'package:belluga_now/infrastructure/dal/dto/tenant_admin/tenant_admin_taxonomy_term_dto.dart';
import 'package:belluga_now/domain/tenant_admin/ownership_state.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_account_profile.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_location.dart';

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
    this.content,
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
  final String? content;
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
      content: json['content']?.toString(),
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

  TenantAdminAccountProfile toDomain() {
    final location = (locationLat != null && locationLng != null)
        ? TenantAdminLocation(
            latitude: locationLat!,
            longitude: locationLng!,
          )
        : null;
    final taxonomy = taxonomyTerms
        .map((term) => term.toDomain())
        .toList(growable: false);
    return TenantAdminAccountProfile(
      id: id,
      accountId: accountId,
      profileType: profileType,
      displayName: displayName,
      slug: slug,
      avatarUrl: avatarUrl,
      coverUrl: coverUrl,
      bio: bio,
      content: content,
      location: location,
      taxonomyTerms: taxonomy,
      ownershipState: ownershipState == null
          ? null
          : TenantAdminOwnershipState.fromApiValue(ownershipState),
    );
  }
}
