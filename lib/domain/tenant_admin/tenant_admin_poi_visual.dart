typedef TenantAdminPoiVisualPrimString = String;
typedef TenantAdminPoiVisualPrimInt = int;
typedef TenantAdminPoiVisualPrimBool = bool;
typedef TenantAdminPoiVisualPrimDouble = double;
typedef TenantAdminPoiVisualPrimDateTime = DateTime;
typedef TenantAdminPoiVisualPrimDynamic = dynamic;

enum TenantAdminPoiVisualMode {
  icon(apiValue: 'icon', label: 'Ícone'),
  image(apiValue: 'image', label: 'Imagem');

  const TenantAdminPoiVisualMode({
    required this.apiValue,
    required this.label,
  });

  final TenantAdminPoiVisualPrimString apiValue;
  final TenantAdminPoiVisualPrimString label;

  static TenantAdminPoiVisualMode? fromRaw(
      TenantAdminPoiVisualPrimString? raw) {
    final normalized = raw?.trim().toLowerCase();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }

    for (final candidate in values) {
      if (candidate.apiValue == normalized) {
        return candidate;
      }
    }
    return null;
  }
}

enum TenantAdminPoiVisualImageSource {
  avatar(apiValue: 'avatar', label: 'Avatar'),
  cover(apiValue: 'cover', label: 'Capa');

  const TenantAdminPoiVisualImageSource({
    required this.apiValue,
    required this.label,
  });

  final TenantAdminPoiVisualPrimString apiValue;
  final TenantAdminPoiVisualPrimString label;

  static TenantAdminPoiVisualImageSource? fromRaw(
    TenantAdminPoiVisualPrimString? raw,
  ) {
    final normalized = raw?.trim().toLowerCase();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }

    for (final candidate in values) {
      if (candidate.apiValue == normalized) {
        return candidate;
      }
    }
    return null;
  }
}

class TenantAdminPoiVisual {
  TenantAdminPoiVisual.icon({
    required TenantAdminPoiVisualPrimString icon,
    required TenantAdminPoiVisualPrimString color,
    TenantAdminPoiVisualPrimString iconColor = '#FFFFFF',
  })  : mode = TenantAdminPoiVisualMode.icon,
        icon = icon.trim(),
        color = color.trim().toUpperCase(),
        iconColor = iconColor.trim().toUpperCase(),
        imageSource = null;

  TenantAdminPoiVisual.image({
    required this.imageSource,
  })  : mode = TenantAdminPoiVisualMode.image,
        icon = null,
        color = null,
        iconColor = null;

  final TenantAdminPoiVisualMode mode;
  final TenantAdminPoiVisualPrimString? icon;
  final TenantAdminPoiVisualPrimString? color;
  final TenantAdminPoiVisualPrimString? iconColor;
  final TenantAdminPoiVisualImageSource? imageSource;

  TenantAdminPoiVisualPrimBool get isValid {
    switch (mode) {
      case TenantAdminPoiVisualMode.icon:
        final iconValue = icon?.trim() ?? '';
        final colorValue = color?.trim().toUpperCase() ?? '';
        final iconColorValue = iconColor?.trim().toUpperCase() ?? '';
        return iconValue.isNotEmpty &&
            RegExp(r'^#[0-9A-F]{6}$').hasMatch(colorValue) &&
            RegExp(r'^#[0-9A-F]{6}$').hasMatch(iconColorValue);
      case TenantAdminPoiVisualMode.image:
        return imageSource != null;
    }
  }

  Map<TenantAdminPoiVisualPrimString, TenantAdminPoiVisualPrimDynamic>
      toJson() {
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
    final mode = TenantAdminPoiVisualMode.fromRaw(
      (json['mode'] ?? '').toString(),
    );
    if (mode == null) {
      return null;
    }

    if (mode == TenantAdminPoiVisualMode.icon) {
      final icon = (json['icon'] ?? '').toString().trim();
      final color = (json['color'] ?? '').toString().trim().toUpperCase();
      final iconColor =
          (json['icon_color'] ?? '#FFFFFF').toString().trim().toUpperCase();
      if (icon.isEmpty ||
          !RegExp(r'^#[0-9A-F]{6}$').hasMatch(color) ||
          !RegExp(r'^#[0-9A-F]{6}$').hasMatch(iconColor)) {
        return null;
      }
      return TenantAdminPoiVisual.icon(
        icon: icon,
        color: color,
        iconColor: iconColor,
      );
    }

    final imageSource = TenantAdminPoiVisualImageSource.fromRaw(
      (json['image_source'] ?? '').toString(),
    );
    if (imageSource == null) {
      return null;
    }
    return TenantAdminPoiVisual.image(
      imageSource: imageSource,
    );
  }
}
