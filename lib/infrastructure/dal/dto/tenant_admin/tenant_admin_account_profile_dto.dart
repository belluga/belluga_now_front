import 'package:belluga_now/infrastructure/dal/dto/tenant_admin/tenant_admin_taxonomy_term_dto.dart';
import 'package:belluga_now/domain/tenant_admin/ownership_state.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_account_profile.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_location.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_nested_profile_group.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_terms.dart';

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
    this.nestedProfileGroups = const [],
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
  final List<TenantAdminNestedProfileGroup> nestedProfileGroups;
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
    final nestedGroups = <TenantAdminNestedProfileGroup>[];
    final nestedRaw = json['nested_profile_groups'];
    if (nestedRaw is List) {
      for (final entry in nestedRaw) {
        if (entry is! Map) continue;
        final groupJson = Map<String, dynamic>.from(entry);
        final rawIds =
            groupJson['account_profile_ids'] ?? groupJson['profile_ids'];
        nestedGroups.add(
          _nestedProfileGroupFromRaw(
            id: groupJson['id'] ?? groupJson['key'],
            label: groupJson['label'],
            order: groupJson['order'],
            accountProfileIds:
                rawIds is Iterable ? rawIds.cast<Object?>() : const <Object?>[],
          ),
        );
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
      nestedProfileGroups: nestedGroups,
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
        ? tenantAdminLocationFromRaw(
            latitude: locationLat!,
            longitude: locationLng!,
          )
        : null;
    final taxonomy = TenantAdminTaxonomyTerms();
    for (final taxonomyTerm in taxonomyTerms) {
      taxonomy.add(taxonomyTerm.toDomain());
    }
    return tenantAdminAccountProfileFromRaw(
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
      nestedProfileGroups: nestedProfileGroups,
      ownershipState: ownershipState == null
          ? null
          : tenantAdminOwnershipStateFromRaw(ownershipState),
    );
  }
}

TenantAdminNestedProfileGroup _nestedProfileGroupFromRaw({
  required Object? id,
  required Object? label,
  Object? order,
  Iterable<Object?> accountProfileIds = const <Object?>[],
}) {
  return TenantAdminNestedProfileGroup(
    idValue: TenantAdminNestedProfileGroupTextValue(
      id?.toString().trim() ?? '',
    ),
    labelValue: TenantAdminNestedProfileGroupTextValue(
      label?.toString().trim() ?? '',
    ),
    orderValue: TenantAdminNestedProfileGroupOrderValue(
      order is num ? order.toInt() : int.tryParse(order?.toString() ?? '') ?? 0,
    ),
    accountProfileIdValues: accountProfileIds
        .map((entry) => TenantAdminNestedProfileGroupTextValue(
              entry?.toString().trim() ?? '',
            ))
        .where((entry) => entry.value.isNotEmpty)
        .toList(growable: false),
  );
}
