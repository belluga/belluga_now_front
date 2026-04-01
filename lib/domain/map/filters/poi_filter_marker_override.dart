import 'package:belluga_now/domain/map/projections/city_poi_visual.dart';
import 'package:belluga_now/domain/map/value_objects/poi_filter_image_uri_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_filter_source_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_hex_color_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_icon_symbol_value.dart';

enum PoiFilterMarkerOverrideMode {
  icon,
  image,
}

class PoiFilterMarkerOverride {
  PoiFilterMarkerOverride.icon({
    required this.iconValue,
    required this.colorHexValue,
    PoiHexColorValue? iconColorHexValue,
  })  : mode = PoiFilterMarkerOverrideMode.icon,
        iconColorHexValue = iconColorHexValue ?? _defaultIconColorHex(),
        imageUriValue = null;

  PoiFilterMarkerOverride.image({
    required this.imageUriValue,
  })  : mode = PoiFilterMarkerOverrideMode.image,
        iconValue = null,
        colorHexValue = null,
        iconColorHexValue = null;

  final PoiFilterMarkerOverrideMode mode;
  final PoiIconSymbolValue? iconValue;
  final PoiHexColorValue? colorHexValue;
  final PoiHexColorValue? iconColorHexValue;
  final PoiFilterImageUriValue? imageUriValue;

  String? get icon => iconValue?.value;
  String? get colorHex => colorHexValue?.value;
  String? get iconColorHex => iconColorHexValue?.value;
  String? get imageUri => imageUriValue?.value;

  bool get isValid {
    switch (mode) {
      case PoiFilterMarkerOverrideMode.icon:
        final resolvedIcon = iconValue?.value.trim() ?? '';
        final resolvedColor = colorHexValue?.value.trim() ?? '';
        final resolvedIconColor = iconColorHexValue?.value.trim() ?? '';
        return resolvedIcon.isNotEmpty &&
            resolvedColor.isNotEmpty &&
            resolvedIconColor.isNotEmpty;
      case PoiFilterMarkerOverrideMode.image:
        return (imageUriValue?.value ?? '').trim().isNotEmpty;
    }
  }

  CityPoiVisual? toPoiVisual() {
    if (!isValid) {
      return null;
    }

    switch (mode) {
      case PoiFilterMarkerOverrideMode.icon:
        return CityPoiVisual.icon(
          iconValue: iconValue!,
          colorHexValue: colorHexValue!,
          iconColorHexValue: iconColorHexValue!,
          sourceValue: _filterOverrideSourceValue(),
        );
      case PoiFilterMarkerOverrideMode.image:
        return CityPoiVisual.image(
          imageUriValue: imageUriValue!,
          sourceValue: _filterOverrideSourceValue(),
        );
    }
  }

  static PoiHexColorValue _defaultIconColorHex() {
    final value = PoiHexColorValue();
    value.parse('#FFFFFF');
    return value;
  }

  static PoiFilterSourceValue _filterOverrideSourceValue() {
    final value = PoiFilterSourceValue();
    value.parse('filter_override');
    return value;
  }
}
