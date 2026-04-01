import 'package:belluga_now/domain/map/value_objects/poi_filter_image_uri_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_filter_source_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_hex_color_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_icon_symbol_value.dart';

enum CityPoiVisualMode {
  icon,
  image,
}

class CityPoiVisual {
  CityPoiVisual.icon({
    required this.iconValue,
    required this.colorHexValue,
    PoiHexColorValue? iconColorHexValue,
    this.sourceValue,
  })  : mode = CityPoiVisualMode.icon,
        iconColorHexValue = iconColorHexValue ?? _defaultIconColorHex(),
        imageUriValue = null;

  CityPoiVisual.image({
    required this.imageUriValue,
    this.sourceValue,
  })  : mode = CityPoiVisualMode.image,
        iconValue = null,
        colorHexValue = null,
        iconColorHexValue = null;

  final CityPoiVisualMode mode;
  final PoiIconSymbolValue? iconValue;
  final PoiHexColorValue? colorHexValue;
  final PoiHexColorValue? iconColorHexValue;
  final PoiFilterImageUriValue? imageUriValue;
  final PoiFilterSourceValue? sourceValue;

  String? get icon => iconValue?.value;
  String? get colorHex => colorHexValue?.value;
  String? get iconColorHex => iconColorHexValue?.value;
  String? get imageUri => imageUriValue?.value;
  String? get source => sourceValue?.value;

  bool get isIcon => mode == CityPoiVisualMode.icon;
  bool get isImage => mode == CityPoiVisualMode.image;

  bool get isValid {
    switch (mode) {
      case CityPoiVisualMode.icon:
        return (icon ?? '').trim().isNotEmpty &&
            (colorHex ?? '').trim().isNotEmpty &&
            (iconColorHex ?? '').trim().isNotEmpty;
      case CityPoiVisualMode.image:
        return (imageUri ?? '').trim().isNotEmpty;
    }
  }

  static PoiHexColorValue _defaultIconColorHex() {
    final value = PoiHexColorValue();
    value.parse('#FFFFFF');
    return value;
  }
}
