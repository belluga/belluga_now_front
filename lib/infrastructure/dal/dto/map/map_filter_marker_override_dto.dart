import 'package:belluga_now/domain/map/filters/poi_filter_marker_override.dart';
import 'package:belluga_now/domain/map/value_objects/poi_filter_image_uri_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_hex_color_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_icon_symbol_value.dart';

class MapFilterMarkerOverrideDTO {
  const MapFilterMarkerOverrideDTO.icon({
    required this.icon,
    required this.color,
    required this.iconColor,
  })  : mode = 'icon',
        imageUri = null;

  const MapFilterMarkerOverrideDTO.image({
    required this.imageUri,
  })  : mode = 'image',
        icon = null,
        color = null,
        iconColor = null;

  final String mode;
  final String? icon;
  final String? color;
  final String? iconColor;
  final String? imageUri;

  static MapFilterMarkerOverrideDTO? tryFromJson(Object? raw) {
    if (raw is! Map) {
      return null;
    }

    final json = Map<Object?, Object?>.from(raw);
    final mode = _readString(json['mode']).toLowerCase();

    if (mode == 'icon') {
      final icon = _readString(json['icon'] ?? json['icon_name']);
      final color =
          _readString(json['color'] ?? json['marker_color']).toUpperCase();
      final iconColor =
          _readString(json['icon_color'] ?? json['iconColor'] ?? '#FFFFFF')
              .toUpperCase();
      if (icon.isEmpty ||
          !RegExp(r'^#[0-9A-F]{6}$').hasMatch(color) ||
          !RegExp(r'^#[0-9A-F]{6}$').hasMatch(iconColor)) {
        return null;
      }
      return MapFilterMarkerOverrideDTO.icon(
        icon: icon,
        color: color,
        iconColor: iconColor,
      );
    }

    if (mode == 'image') {
      final imageUri = _readString(json['image_uri']);
      if (imageUri.isEmpty) {
        return null;
      }
      return MapFilterMarkerOverrideDTO.image(imageUri: imageUri);
    }

    return null;
  }

  PoiFilterMarkerOverride toDomain() {
    if (mode == 'icon') {
      final iconValue = PoiIconSymbolValue()..parse(icon);
      final colorHexValue = PoiHexColorValue()..parse(color);
      final iconColorHexValue = PoiHexColorValue()..parse(iconColor);
      return PoiFilterMarkerOverride.icon(
        iconValue: iconValue,
        colorHexValue: colorHexValue,
        iconColorHexValue: iconColorHexValue,
      );
    }

    final imageUriValue = PoiFilterImageUriValue()..parse(imageUri);
    return PoiFilterMarkerOverride.image(
      imageUriValue: imageUriValue,
    );
  }

  static String _readString(Object? raw) {
    final resolved = _unwrapScalar(raw);
    return resolved?.toString().trim() ?? '';
  }

  static Object? _unwrapScalar(Object? raw) {
    if (raw is! Map) {
      return raw;
    }

    const prioritizedKeys = <String>[
      'value',
      r'$value',
      'string',
      r'$string',
      'raw',
      'text',
    ];

    for (final key in prioritizedKeys) {
      if (raw.containsKey(key)) {
        return _unwrapScalar(raw[key]);
      }
    }

    if (raw.length == 1) {
      final value = raw.values.first;
      if (value is! Map && value is! Iterable) {
        return value;
      }
    }

    return null;
  }
}
