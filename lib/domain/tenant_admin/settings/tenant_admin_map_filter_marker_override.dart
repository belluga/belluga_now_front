typedef TenantAdminMapFilterMarkerOverridePrimString = String;
typedef TenantAdminMapFilterMarkerOverridePrimInt = int;
typedef TenantAdminMapFilterMarkerOverridePrimBool = bool;
typedef TenantAdminMapFilterMarkerOverridePrimDouble = double;
typedef TenantAdminMapFilterMarkerOverridePrimDateTime = DateTime;
typedef TenantAdminMapFilterMarkerOverridePrimDynamic = dynamic;

enum TenantAdminMapFilterMarkerOverrideMode {
  icon(apiValue: 'icon', label: 'Ícone'),
  image(apiValue: 'image', label: 'Imagem');

  const TenantAdminMapFilterMarkerOverrideMode({
    required this.apiValue,
    required this.label,
  });

  final TenantAdminMapFilterMarkerOverridePrimString apiValue;
  final TenantAdminMapFilterMarkerOverridePrimString label;

  static TenantAdminMapFilterMarkerOverrideMode? fromRaw(
    TenantAdminMapFilterMarkerOverridePrimString? raw,
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

class TenantAdminMapFilterMarkerOverride {
  TenantAdminMapFilterMarkerOverride.icon({
    required TenantAdminMapFilterMarkerOverridePrimString icon,
    required TenantAdminMapFilterMarkerOverridePrimString color,
    TenantAdminMapFilterMarkerOverridePrimString iconColor = '#FFFFFF',
  })  : mode = TenantAdminMapFilterMarkerOverrideMode.icon,
        icon = icon.trim(),
        color = color.trim().toUpperCase(),
        iconColor = iconColor.trim().toUpperCase(),
        imageUri = null;

  TenantAdminMapFilterMarkerOverride.image({
    required TenantAdminMapFilterMarkerOverridePrimString imageUri,
  })  : mode = TenantAdminMapFilterMarkerOverrideMode.image,
        icon = null,
        color = null,
        iconColor = null,
        imageUri = imageUri.trim();

  final TenantAdminMapFilterMarkerOverrideMode mode;
  final TenantAdminMapFilterMarkerOverridePrimString? icon;
  final TenantAdminMapFilterMarkerOverridePrimString? color;
  final TenantAdminMapFilterMarkerOverridePrimString? iconColor;
  final TenantAdminMapFilterMarkerOverridePrimString? imageUri;

  TenantAdminMapFilterMarkerOverridePrimBool get isValid {
    switch (mode) {
      case TenantAdminMapFilterMarkerOverrideMode.icon:
        final iconValue = icon?.trim() ?? '';
        final colorValue = color?.trim().toUpperCase() ?? '';
        final iconColorValue = iconColor?.trim().toUpperCase() ?? '';
        return iconValue.isNotEmpty &&
            RegExp(r'^#[0-9A-F]{6}$').hasMatch(colorValue) &&
            RegExp(r'^#[0-9A-F]{6}$').hasMatch(iconColorValue);
      case TenantAdminMapFilterMarkerOverrideMode.image:
        return (imageUri?.trim().isNotEmpty ?? false);
    }
  }

  Map<TenantAdminMapFilterMarkerOverridePrimString,
      TenantAdminMapFilterMarkerOverridePrimDynamic> toJson() {
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
}
