export 'value_objects/tenant_admin_poi_visual_values.dart';

import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_hex_color_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_dynamic_map_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_lowercase_token_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_optional_url_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_required_text_value.dart';

enum TenantAdminPoiVisualMode {
  icon,
  image,
}

extension TenantAdminPoiVisualModeX on TenantAdminPoiVisualMode {
  String get apiValue => switch (this) {
        TenantAdminPoiVisualMode.icon => 'icon',
        TenantAdminPoiVisualMode.image => 'image',
      };

  String get label => switch (this) {
        TenantAdminPoiVisualMode.icon => 'Ícone',
        TenantAdminPoiVisualMode.image => 'Imagem',
      };
}

TenantAdminPoiVisualMode? tenantAdminPoiVisualModeFromValue(
  TenantAdminLowercaseTokenValue? rawValue,
) {
  final normalized = rawValue?.value.trim();
  if (normalized == null || normalized.isEmpty) {
    return null;
  }

  for (final candidate in TenantAdminPoiVisualMode.values) {
    if (candidate.apiValue == normalized) {
      return candidate;
    }
  }
  return null;
}

enum TenantAdminPoiVisualImageSource {
  avatar,
  cover,
  typeAsset,
}

extension TenantAdminPoiVisualImageSourceX on TenantAdminPoiVisualImageSource {
  String get apiValue => switch (this) {
        TenantAdminPoiVisualImageSource.avatar => 'avatar',
        TenantAdminPoiVisualImageSource.cover => 'cover',
        TenantAdminPoiVisualImageSource.typeAsset => 'type_asset',
      };

  String get label => switch (this) {
        TenantAdminPoiVisualImageSource.avatar => 'Avatar do perfil',
        TenantAdminPoiVisualImageSource.cover => 'Capa do perfil',
        TenantAdminPoiVisualImageSource.typeAsset => 'Imagem canônica do tipo',
      };
}

TenantAdminPoiVisualImageSource? tenantAdminPoiVisualImageSourceFromValue(
  TenantAdminLowercaseTokenValue? rawValue,
) {
  final normalized = rawValue?.value.trim();
  if (normalized == null || normalized.isEmpty) {
    return null;
  }

  for (final candidate in TenantAdminPoiVisualImageSource.values) {
    if (candidate.apiValue == normalized) {
      return candidate;
    }
  }
  return null;
}

class TenantAdminPoiVisual {
  TenantAdminPoiVisual.icon({
    required this.iconValue,
    required this.colorValue,
    TenantAdminHexColorValue? iconColorValue,
  })  : mode = TenantAdminPoiVisualMode.icon,
        iconColorValue = iconColorValue ?? _defaultIconColorValue(),
        imageSource = null,
        imageUrlValue = null;

  TenantAdminPoiVisual.image({
    required this.imageSource,
    this.imageUrlValue,
  })  : mode = TenantAdminPoiVisualMode.image,
        iconValue = null,
        colorValue = null,
        iconColorValue = null;

  final TenantAdminPoiVisualMode mode;
  final TenantAdminRequiredTextValue? iconValue;
  final TenantAdminHexColorValue? colorValue;
  final TenantAdminHexColorValue? iconColorValue;
  final TenantAdminPoiVisualImageSource? imageSource;
  final TenantAdminOptionalUrlValue? imageUrlValue;

  String? get icon => iconValue?.value;
  String? get color => colorValue?.value;
  String? get iconColor => iconColorValue?.value;
  String? get imageUrl => imageUrlValue?.nullableValue;

  bool get isValid {
    switch (mode) {
      case TenantAdminPoiVisualMode.icon:
        final resolvedIcon = iconValue?.value.trim() ?? '';
        return resolvedIcon.isNotEmpty &&
            colorValue != null &&
            iconColorValue != null;
      case TenantAdminPoiVisualMode.image:
        return imageSource != null;
    }
  }

  TenantAdminDynamicMapValue toJson() {
    if (mode == TenantAdminPoiVisualMode.icon) {
      return TenantAdminDynamicMapValue({
        'mode': mode.apiValue,
        'icon': icon,
        'color': color,
        'icon_color': iconColor,
      });
    }

    return TenantAdminDynamicMapValue({
      'mode': mode.apiValue,
      'image_source': imageSource?.apiValue,
    });
  }

  static TenantAdminHexColorValue _defaultIconColorValue() {
    final value = TenantAdminHexColorValue();
    value.parse('#FFFFFF');
    return value;
  }
}
