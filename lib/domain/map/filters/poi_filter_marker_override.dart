import 'package:belluga_now/domain/map/projections/city_poi_visual.dart';

enum PoiFilterMarkerOverrideMode {
  icon,
  image,
}

typedef PoiFilterMarkerOverrideRawString = String;

class PoiFilterMarkerOverride {
  const PoiFilterMarkerOverride.icon({
    required this.icon,
    required this.colorHex,
    this.iconColorHex = '#FFFFFF',
  })  : mode = PoiFilterMarkerOverrideMode.icon,
        imageUri = null;

  const PoiFilterMarkerOverride.image({
    required this.imageUri,
  })  : mode = PoiFilterMarkerOverrideMode.image,
        icon = null,
        colorHex = null,
        iconColorHex = null;

  final PoiFilterMarkerOverrideMode mode;
  final PoiFilterMarkerOverrideRawString? icon;
  final PoiFilterMarkerOverrideRawString? colorHex;
  final PoiFilterMarkerOverrideRawString? iconColorHex;
  final PoiFilterMarkerOverrideRawString? imageUri;

  bool get isValid {
    switch (mode) {
      case PoiFilterMarkerOverrideMode.icon:
        final resolvedIcon = (icon ?? '').trim();
        final resolvedColor = (colorHex ?? '').trim();
        final resolvedIconColor = (iconColorHex ?? '').trim();
        return resolvedIcon.isNotEmpty &&
            RegExp(r'^#[0-9A-Fa-f]{6}$').hasMatch(resolvedColor) &&
            RegExp(r'^#[0-9A-Fa-f]{6}$').hasMatch(resolvedIconColor);
      case PoiFilterMarkerOverrideMode.image:
        return (imageUri ?? '').trim().isNotEmpty;
    }
  }

  CityPoiVisual? toPoiVisual() {
    if (!isValid) {
      return null;
    }

    switch (mode) {
      case PoiFilterMarkerOverrideMode.icon:
        return CityPoiVisual.icon(
          icon: icon!.trim(),
          colorHex: colorHex!.trim().toUpperCase(),
          iconColorHex: iconColorHex!.trim().toUpperCase(),
          source: 'filter_override',
        );
      case PoiFilterMarkerOverrideMode.image:
        return CityPoiVisual.image(
          imageUri: imageUri!.trim(),
          source: 'filter_override',
        );
    }
  }
}
