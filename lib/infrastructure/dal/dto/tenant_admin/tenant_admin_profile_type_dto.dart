import 'package:belluga_now/domain/tenant_admin/tenant_admin_poi_visual.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_profile_type.dart';

class TenantAdminProfileTypeDTO {
  const TenantAdminProfileTypeDTO({
    required this.type,
    required this.label,
    required this.pluralLabel,
    required this.allowedTaxonomies,
    this.visual,
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
  });

  final String type;
  final String label;
  final String pluralLabel;
  final List<String> allowedTaxonomies;
  final TenantAdminPoiVisual? visual;
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
    bool isPubliclyDiscoverable = false;
    bool isFavoritable = false;
    bool isPoiEnabled = false;
    bool isReferenceLocationEnabled = false;
    bool hasBio = false;
    bool hasContent = false;
    bool hasTaxonomies = false;
    bool hasAvatar = false;
    bool hasCover = false;
    bool hasEvents = false;
    if (capabilities is Map<String, dynamic>) {
      isPubliclyDiscoverable = _parseBool(
        capabilities['is_publicly_discoverable'],
      );
      isFavoritable =
          isPubliclyDiscoverable && _parseBool(capabilities['is_favoritable']);
      isPoiEnabled = _parseBool(capabilities['is_poi_enabled']);
      isReferenceLocationEnabled =
          isPoiEnabled &&
          _parseBool(capabilities['is_reference_location_enabled']);
      hasBio = _parseBool(capabilities['has_bio']);
      hasContent = _parseBool(capabilities['has_content']);
      hasTaxonomies = _parseBool(capabilities['has_taxonomies']);
      hasAvatar = _parseBool(capabilities['has_avatar']);
      hasCover = _parseBool(capabilities['has_cover']);
      hasEvents = _parseBool(capabilities['has_events']);
    }
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
      isPubliclyDiscoverable: isPubliclyDiscoverable,
      isFavoritable: isFavoritable,
      isPoiEnabled: isPoiEnabled,
      isReferenceLocationEnabled: isReferenceLocationEnabled,
      hasBio: hasBio,
      hasContent: hasContent,
      hasTaxonomies: hasTaxonomies,
      hasAvatar: hasAvatar,
      hasCover: hasCover,
      hasEvents: hasEvents,
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
      ),
    );
  }
}
