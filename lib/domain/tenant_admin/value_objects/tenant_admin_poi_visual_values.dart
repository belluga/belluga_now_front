import 'package:belluga_now/domain/tenant_admin/tenant_admin_poi_visual.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_dynamic_map_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_hex_color_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_lowercase_token_value.dart';
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

  final modeTokenValue = TenantAdminLowercaseTokenValue();
  try {
    modeTokenValue.parse((json['mode'] ?? '').toString());
  } on Object {
    return null;
  }
  final mode = tenantAdminPoiVisualModeFromValue(modeTokenValue);
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
  );
}
