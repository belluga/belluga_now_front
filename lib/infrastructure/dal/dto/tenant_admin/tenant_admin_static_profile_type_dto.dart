import 'package:belluga_now/domain/tenant_admin/tenant_admin_poi_visual.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_static_profile_type.dart';
import 'package:belluga_now/infrastructure/dal/dto/tenant_admin/support/tenant_admin_poi_visual_json_normalizer.dart';

class TenantAdminStaticProfileTypeDTO {
  const TenantAdminStaticProfileTypeDTO({
    required this.type,
    required this.label,
    required this.allowedTaxonomies,
    this.visual,
    required this.isPoiEnabled,
    required this.hasBio,
    required this.hasTaxonomies,
    required this.hasAvatar,
    required this.hasCover,
    required this.hasContent,
  });

  final String type;
  final String label;
  final List<String> allowedTaxonomies;
  final TenantAdminPoiVisual? visual;
  final bool isPoiEnabled;
  final bool hasBio;
  final bool hasTaxonomies;
  final bool hasAvatar;
  final bool hasCover;
  final bool hasContent;

  factory TenantAdminStaticProfileTypeDTO.fromJson(Map<String, dynamic> json) {
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
    bool isPoiEnabled = false;
    bool hasBio = false;
    bool hasTaxonomies = false;
    bool hasAvatar = false;
    bool hasCover = false;
    bool hasContent = false;
    if (capabilities is Map<String, dynamic>) {
      isPoiEnabled = _parseBool(capabilities['is_poi_enabled']);
      hasBio = _parseBool(capabilities['has_bio']);
      hasTaxonomies = _parseBool(capabilities['has_taxonomies']);
      hasAvatar = _parseBool(capabilities['has_avatar']);
      hasCover = _parseBool(capabilities['has_cover']);
      hasContent = _parseBool(capabilities['has_content']);
    }
    final visualRaw = tenantAdminResolvePoiVisualRaw(
      visualRaw: json['visual'] ?? json['poi_visual'],
      typeAssetUrl: json['type_asset_url'],
    );
    return TenantAdminStaticProfileTypeDTO(
      type: json['type']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      allowedTaxonomies: allowed,
      visual: tenantAdminPoiVisualFromRaw(visualRaw),
      isPoiEnabled: isPoiEnabled,
      hasBio: hasBio,
      hasTaxonomies: hasTaxonomies,
      hasAvatar: hasAvatar,
      hasCover: hasCover,
      hasContent: hasContent,
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

  TenantAdminStaticProfileTypeDefinition toDomain() {
    return tenantAdminStaticProfileTypeDefinitionFromRaw(
      type: type,
      label: label,
      allowedTaxonomies: allowedTaxonomies,
      visual: visual,
      capabilities: TenantAdminStaticProfileTypeCapabilities(
        isPoiEnabled: TenantAdminFlagValue(isPoiEnabled),
        hasBio: TenantAdminFlagValue(hasBio),
        hasTaxonomies: TenantAdminFlagValue(hasTaxonomies),
        hasAvatar: TenantAdminFlagValue(hasAvatar),
        hasCover: TenantAdminFlagValue(hasCover),
        hasContent: TenantAdminFlagValue(hasContent),
      ),
    );
  }
}
