import 'package:belluga_now/domain/tenant_admin/tenant_admin_poi_visual.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_profile_type.dart';
import 'package:belluga_now/infrastructure/dal/dto/tenant_admin/support/tenant_admin_poi_visual_json_normalizer.dart';

class TenantAdminProfileTypeDTO {
  const TenantAdminProfileTypeDTO({
    required this.type,
    required this.label,
    required this.pluralLabel,
    required this.allowedTaxonomies,
    this.visual,
    required this.isQueryable,
    required this.isPubliclyNavigable,
    required this.isPubliclyDiscoverable,
    required this.isInviteable,
    required this.isFavoritable,
    required this.isPoiEnabled,
    required this.isReferenceLocationEnabled,
    required this.hasBio,
    required this.hasContent,
    required this.hasTaxonomies,
    required this.hasAvatar,
    required this.hasCover,
    required this.hasEvents,
    required this.hasGallery,
    required this.hasNestedProfileGroups,
    required this.hasContactChannels,
  });

  final String type;
  final String label;
  final String pluralLabel;
  final List<String> allowedTaxonomies;
  final TenantAdminPoiVisual? visual;
  final bool isQueryable;
  final bool isPubliclyNavigable;
  final bool isPubliclyDiscoverable;
  final bool isInviteable;
  final bool isFavoritable;
  final bool isPoiEnabled;
  final bool isReferenceLocationEnabled;
  final bool hasBio;
  final bool hasContent;
  final bool hasTaxonomies;
  final bool hasAvatar;
  final bool hasCover;
  final bool hasEvents;
  final bool hasGallery;
  final bool hasNestedProfileGroups;
  final bool hasContactChannels;

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
    final capabilityMap = capabilities is Map<String, dynamic>
        ? Map<String, dynamic>.from(capabilities)
        : const <String, dynamic>{};
    final labelsRaw = json['labels'];
    final labels = labelsRaw is Map<String, dynamic>
        ? labelsRaw
        : (labelsRaw is Map ? Map<String, dynamic>.from(labelsRaw) : const {});
    final singularLabel = labels['singular']?.toString().trim();
    final pluralLabel = labels['plural']?.toString().trim();
    final visualRaw = tenantAdminResolvePoiVisualRaw(
      visualRaw: json['visual'] ?? json['poi_visual'],
      typeAssetUrl: json['type_asset_url'],
    );
    return TenantAdminProfileTypeDTO(
      type: json['type']?.toString() ?? '',
      label: singularLabel != null && singularLabel.isNotEmpty
          ? singularLabel
          : json['label']?.toString() ?? '',
      pluralLabel: pluralLabel != null && pluralLabel.isNotEmpty
          ? pluralLabel
          : singularLabel != null && singularLabel.isNotEmpty
              ? singularLabel
              : json['label']?.toString() ?? '',
      allowedTaxonomies: allowed,
      visual: tenantAdminPoiVisualFromRaw(visualRaw),
      isQueryable: capabilityMap['is_queryable'] == true,
      isPubliclyNavigable: capabilityMap['is_publicly_navigable'] == true,
      isPubliclyDiscoverable: capabilityMap['is_publicly_discoverable'] == true,
      isInviteable: capabilityMap['is_inviteable'] == true,
      isFavoritable: capabilityMap['is_favoritable'] == true,
      isPoiEnabled: capabilityMap['is_poi_enabled'] == true,
      isReferenceLocationEnabled:
          capabilityMap['is_reference_location_enabled'] == true,
      hasBio: capabilityMap['has_bio'] == true,
      hasContent: capabilityMap['has_content'] == true,
      hasTaxonomies: capabilityMap['has_taxonomies'] == true,
      hasAvatar: capabilityMap['has_avatar'] == true,
      hasCover: capabilityMap['has_cover'] == true,
      hasEvents: capabilityMap['has_events'] == true,
      hasGallery: capabilityMap['has_gallery'] == true,
      hasNestedProfileGroups:
          capabilityMap['has_nested_profile_groups'] == true,
      hasContactChannels: capabilityMap['has_contact_channels'] == true,
    );
  }

  TenantAdminProfileTypeDefinition toDomain() {
    return tenantAdminProfileTypeDefinitionFromRaw(
      type: type,
      label: label,
      pluralLabel: pluralLabel,
      allowedTaxonomies: allowedTaxonomies,
      visual: visual,
      capabilities: TenantAdminProfileTypeCapabilities(
        isQueryable: TenantAdminFlagValue(isQueryable),
        isPubliclyNavigable: TenantAdminFlagValue(isPubliclyNavigable),
        isPubliclyDiscoverable: TenantAdminFlagValue(isPubliclyDiscoverable),
        isInviteable: TenantAdminFlagValue(isInviteable),
        isFavoritable: TenantAdminFlagValue(isFavoritable),
        isPoiEnabled: TenantAdminFlagValue(isPoiEnabled),
        isReferenceLocationEnabled: TenantAdminFlagValue(
          isReferenceLocationEnabled,
        ),
        hasBio: TenantAdminFlagValue(hasBio),
        hasContent: TenantAdminFlagValue(hasContent),
        hasTaxonomies: TenantAdminFlagValue(hasTaxonomies),
        hasAvatar: TenantAdminFlagValue(hasAvatar),
        hasCover: TenantAdminFlagValue(hasCover),
        hasEvents: TenantAdminFlagValue(hasEvents),
        hasGallery: TenantAdminFlagValue(hasGallery),
        hasNestedProfileGroups: TenantAdminFlagValue(hasNestedProfileGroups),
        hasContactChannels: TenantAdminFlagValue(hasContactChannels),
      ),
    );
  }
}
