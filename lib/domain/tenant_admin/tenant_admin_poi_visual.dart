import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_hex_color_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_lowercase_token_value.dart';
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
}

extension TenantAdminPoiVisualImageSourceX on TenantAdminPoiVisualImageSource {
  String get apiValue => switch (this) {
        TenantAdminPoiVisualImageSource.avatar => 'avatar',
        TenantAdminPoiVisualImageSource.cover => 'cover',
      };

  String get label => switch (this) {
        TenantAdminPoiVisualImageSource.avatar => 'Avatar',
        TenantAdminPoiVisualImageSource.cover => 'Capa',
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
        imageSource = null;

  TenantAdminPoiVisual.image({
    required this.imageSource,
  })  : mode = TenantAdminPoiVisualMode.image,
        iconValue = null,
        colorValue = null,
        iconColorValue = null;

  final TenantAdminPoiVisualMode mode;
  final TenantAdminRequiredTextValue? iconValue;
  final TenantAdminHexColorValue? colorValue;
  final TenantAdminHexColorValue? iconColorValue;
  final TenantAdminPoiVisualImageSource? imageSource;

  String? get icon => iconValue?.value;
  String? get color => colorValue?.value;
  String? get iconColor => iconColorValue?.value;

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

  Map<String, dynamic> toJson() {
    if (mode == TenantAdminPoiVisualMode.icon) {
      return {
        'mode': mode.apiValue,
        'icon': icon,
        'color': color,
        'icon_color': iconColor,
      };
    }

    return {
      'mode': mode.apiValue,
      'image_source': imageSource?.apiValue,
    };
  }

  static TenantAdminPoiVisual? tryFromJson(Object? raw) {
    if (raw is! Map) {
      return null;
    }
    final json = Map<String, dynamic>.from(raw);

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

  static TenantAdminHexColorValue _defaultIconColorValue() {
    final value = TenantAdminHexColorValue();
    value.parse('#FFFFFF');
    return value;
  }
}
