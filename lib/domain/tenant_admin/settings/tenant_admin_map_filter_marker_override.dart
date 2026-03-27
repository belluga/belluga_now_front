import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_hex_color_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_lowercase_token_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_optional_url_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_required_text_value.dart';

enum TenantAdminMapFilterMarkerOverrideMode {
  icon,
  image,
}

extension TenantAdminMapFilterMarkerOverrideModeX
    on TenantAdminMapFilterMarkerOverrideMode {
  String get apiValue => switch (this) {
        TenantAdminMapFilterMarkerOverrideMode.icon => 'icon',
        TenantAdminMapFilterMarkerOverrideMode.image => 'image',
      };

  String get label => switch (this) {
        TenantAdminMapFilterMarkerOverrideMode.icon => 'Ícone',
        TenantAdminMapFilterMarkerOverrideMode.image => 'Imagem',
      };
}

TenantAdminMapFilterMarkerOverrideMode?
    tenantAdminMapFilterMarkerOverrideModeFromValue(
  TenantAdminLowercaseTokenValue? rawValue,
) {
  final normalized = rawValue?.value.trim();
  if (normalized == null || normalized.isEmpty) {
    return null;
  }

  for (final candidate in TenantAdminMapFilterMarkerOverrideMode.values) {
    if (candidate.apiValue == normalized) {
      return candidate;
    }
  }
  return null;
}

class TenantAdminMapFilterMarkerOverride {
  TenantAdminMapFilterMarkerOverride.icon({
    required this.iconValue,
    required this.colorValue,
    TenantAdminHexColorValue? iconColorValue,
  })  : mode = TenantAdminMapFilterMarkerOverrideMode.icon,
        iconColorValue = iconColorValue ?? _defaultIconColorValue(),
        imageUriValue = null;

  TenantAdminMapFilterMarkerOverride.image({
    required this.imageUriValue,
  })  : mode = TenantAdminMapFilterMarkerOverrideMode.image,
        iconValue = null,
        colorValue = null,
        iconColorValue = null;

  final TenantAdminMapFilterMarkerOverrideMode mode;
  final TenantAdminRequiredTextValue? iconValue;
  final TenantAdminHexColorValue? colorValue;
  final TenantAdminHexColorValue? iconColorValue;
  final TenantAdminOptionalUrlValue? imageUriValue;

  String? get icon => iconValue?.value;
  String? get color => colorValue?.value;
  String? get iconColor => iconColorValue?.value;
  String? get imageUri => imageUriValue?.nullableValue;

  bool get isValid {
    switch (mode) {
      case TenantAdminMapFilterMarkerOverrideMode.icon:
        final iconValue = icon?.trim() ?? '';
        return iconValue.isNotEmpty &&
            colorValue != null &&
            iconColorValue != null;
      case TenantAdminMapFilterMarkerOverrideMode.image:
        return (imageUriValue?.nullableValue ?? '').trim().isNotEmpty;
    }
  }

  Map<String, dynamic> toJson() {
    if (mode == TenantAdminMapFilterMarkerOverrideMode.icon) {
      return {
        'mode': mode.apiValue,
        'icon': icon,
        'color': color,
        'icon_color': iconColor,
      };
    }

    return {
      'mode': mode.apiValue,
      'image_uri': imageUri,
    };
  }

  static TenantAdminHexColorValue _defaultIconColorValue() {
    final value = TenantAdminHexColorValue();
    value.parse('#FFFFFF');
    return value;
  }
}
