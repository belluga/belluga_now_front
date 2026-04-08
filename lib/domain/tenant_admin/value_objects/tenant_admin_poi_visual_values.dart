import 'package:belluga_now/domain/tenant_admin/tenant_admin_poi_visual.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_dynamic_map_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_hex_color_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_lowercase_token_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_optional_url_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_required_text_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_value_parsers.dart';

TenantAdminPoiVisual? tenantAdminPoiVisualFromRaw(Object? raw) {
  return tenantAdminPoiVisualFromMapValue(tenantAdminDynamicMap(raw));
}

TenantAdminPoiVisual? tenantAdminPoiVisualFromMapValue(
  TenantAdminDynamicMapValue? rawValue,
) {
  if (rawValue == null) {
    return null;
  }

  final json = rawValue.value;

  final mode = _resolvePoiVisualMode(json);
  if (mode == null) {
    return null;
  }

  if (mode == TenantAdminPoiVisualMode.icon) {
    final iconValue = TenantAdminRequiredTextValue();
    final colorValue = TenantAdminHexColorValue();
    final iconColorValue = TenantAdminHexColorValue();
    try {
      iconValue.parse((json['icon'] ?? '').toString());
      colorValue.parse((json['color'] ?? '').toString());
      iconColorValue.parse((json['icon_color'] ?? '#FFFFFF').toString());
    } on Object {
      return null;
    }
    return TenantAdminPoiVisual.icon(
      iconValue: iconValue,
      colorValue: colorValue,
      iconColorValue: iconColorValue,
    );
  }

  final imageSourceTokenValue = TenantAdminLowercaseTokenValue();
  try {
    imageSourceTokenValue.parse((json['image_source'] ?? '').toString());
  } on Object {
    return null;
  }
  final imageSource =
      tenantAdminPoiVisualImageSourceFromValue(imageSourceTokenValue);
  if (imageSource == null) {
    return null;
  }
  return TenantAdminPoiVisual.image(
    imageSource: imageSource,
    imageUrlValue: _optionalUrlValue(_readTrimmedString(json['image_url'])),
  );
}

TenantAdminPoiVisualMode? _resolvePoiVisualMode(Map<String, dynamic> json) {
  final rawMode = (json['mode'] ?? '').toString().trim().toLowerCase();
  if (rawMode.isNotEmpty) {
    final modeTokenValue = TenantAdminLowercaseTokenValue();
    try {
      modeTokenValue.parse(rawMode);
    } on Object {
      return null;
    }
    return tenantAdminPoiVisualModeFromValue(modeTokenValue);
  }

  final hasIcon = (json['icon'] ?? '').toString().trim().isNotEmpty;
  final hasColor = (json['color'] ?? '').toString().trim().isNotEmpty;
  if (hasIcon && hasColor) {
    return TenantAdminPoiVisualMode.icon;
  }

  final hasImageSource =
      (json['image_source'] ?? '').toString().trim().isNotEmpty;
  if (hasImageSource) {
    return TenantAdminPoiVisualMode.image;
  }

  return null;
}

String? _readTrimmedString(Object? raw) {
  final value = raw?.toString().trim();
  if (value == null || value.isEmpty) {
    return null;
  }
  return value;
}

TenantAdminOptionalUrlValue? _optionalUrlValue(String? raw) {
  if (raw == null) {
    return null;
  }
  final value = TenantAdminOptionalUrlValue();
  value.parse(raw);
  return value;
}
