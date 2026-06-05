import 'package:belluga_now/domain/tenant_admin/tenant_admin_poi_visual.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_profile_type.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_profile_type_capability_values.dart';

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
    required this.isFavoritable,
    required this.isPoiEnabled,
    required this.isReferenceLocationEnabled,
    required this.hasBio,
    required this.hasContent,
    required this.hasTaxonomies,
    required this.hasAvatar,
    required this.hasCover,
    required this.hasEvents,
    required this.hasNestedProfileGroups,
  });

  final String type;
  final String label;
  final String pluralLabel;
  final List<String> allowedTaxonomies;
  final TenantAdminPoiVisual? visual;
  final bool isQueryable;
  final bool isPubliclyNavigable;
  final bool isPubliclyDiscoverable;
  final bool isFavoritable;
  final bool isPoiEnabled;
  final bool isReferenceLocationEnabled;
  final bool hasBio;
  final bool hasContent;
  final bool hasTaxonomies;
  final bool hasAvatar;
  final bool hasCover;
  final bool hasEvents;
  final bool hasNestedProfileGroups;

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
        ? TenantAdminProfileTypeCapabilityStateValue(capabilities)
            .normalized()
            .toJson()
        : TenantAdminProfileTypeCapabilityStateValue().normalized().toJson();
    final visualRaw = _resolveVisualRaw(
      visualRaw: json['visual'] ?? json['poi_visual'],
      typeAssetUrl: json['type_asset_url'],
    );
    final labelsRaw = json['labels'];
    final labels = labelsRaw is Map<String, dynamic>
        ? labelsRaw
        : (labelsRaw is Map ? Map<String, dynamic>.from(labelsRaw) : const {});
    final singularLabel = labels['singular']?.toString().trim();
    final pluralLabel = labels['plural']?.toString().trim();
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
      isQueryable: capabilityMap['is_queryable'] ?? true,
      isPubliclyNavigable: capabilityMap['is_publicly_navigable'] ?? true,
      isPubliclyDiscoverable: capabilityMap['is_publicly_discoverable'] ?? true,
      isFavoritable: capabilityMap['is_favoritable'] ?? false,
      isPoiEnabled: capabilityMap['is_poi_enabled'] ?? false,
      isReferenceLocationEnabled:
          capabilityMap['is_reference_location_enabled'] ?? false,
      hasBio: capabilityMap['has_bio'] ?? false,
      hasContent: capabilityMap['has_content'] ?? false,
      hasTaxonomies: capabilityMap['has_taxonomies'] ?? false,
      hasAvatar: capabilityMap['has_avatar'] ?? false,
      hasCover: capabilityMap['has_cover'] ?? false,
      hasEvents: capabilityMap['has_events'] ?? false,
      hasNestedProfileGroups:
          capabilityMap['has_nested_profile_groups'] ?? false,
    );
  }

  static Object? _resolveVisualRaw({
    required Object? visualRaw,
    required Object? typeAssetUrl,
  }) {
    if (visualRaw is! Map) {
      return visualRaw;
    }

    final visualMap = Map<String, dynamic>.from(visualRaw);
    if (_readTrimmedString(visualMap['image_url']) != null) {
      return visualMap;
    }

    final fallbackTypeAssetUrl = _readTrimmedString(typeAssetUrl);
    if (fallbackTypeAssetUrl != null) {
      visualMap['image_url'] = fallbackTypeAssetUrl;
    }
    return visualMap;
  }

  static String? _readTrimmedString(Object? raw) {
    final value = raw?.toString().trim();
    if (value == null || value.isEmpty) {
      return null;
    }
    return value;
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
        hasNestedProfileGroups: TenantAdminFlagValue(hasNestedProfileGroups),
      ),
    );
  }
}
