enum CityPoiVisualMode {
  icon,
  image,
}

typedef CityPoiVisualRawString = String;

class CityPoiVisual {
  const CityPoiVisual.icon({
    required this.icon,
    required this.colorHex,
    this.iconColorHex = '#FFFFFF',
    this.source,
  })  : mode = CityPoiVisualMode.icon,
        imageUri = null;

  const CityPoiVisual.image({
    required this.imageUri,
    this.source,
  })  : mode = CityPoiVisualMode.image,
        icon = null,
        colorHex = null,
        iconColorHex = null;

  final CityPoiVisualMode mode;
  final CityPoiVisualRawString? icon;
  final CityPoiVisualRawString? colorHex;
  final CityPoiVisualRawString? iconColorHex;
  final CityPoiVisualRawString? imageUri;
  final CityPoiVisualRawString? source;

  bool get isIcon => mode == CityPoiVisualMode.icon;
  bool get isImage => mode == CityPoiVisualMode.image;

  bool get isValid {
    switch (mode) {
      case CityPoiVisualMode.icon:
        final resolvedIcon = (icon ?? '').trim();
        final resolvedColor = (colorHex ?? '').trim();
        final resolvedIconColor = (iconColorHex ?? '').trim();
        return resolvedIcon.isNotEmpty &&
            RegExp(r'^#[0-9A-Fa-f]{6}$').hasMatch(resolvedColor) &&
            RegExp(r'^#[0-9A-Fa-f]{6}$').hasMatch(resolvedIconColor);
      case CityPoiVisualMode.image:
        return (imageUri ?? '').trim().isNotEmpty;
    }
  }
}
