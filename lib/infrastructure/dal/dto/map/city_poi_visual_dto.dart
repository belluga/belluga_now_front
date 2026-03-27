import 'package:belluga_now/domain/map/projections/city_poi_visual.dart';
import 'package:belluga_now/domain/map/value_objects/poi_filter_image_uri_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_filter_source_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_hex_color_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_icon_symbol_value.dart';

class CityPoiVisualDTO {
  const CityPoiVisualDTO.icon({
    required this.icon,
    required this.color,
    required this.iconColor,
    this.source,
  })  : mode = 'icon',
        imageUri = null;

  const CityPoiVisualDTO.image({
    required this.imageUri,
    this.source,
  })  : mode = 'image',
        icon = null,
        color = null,
        iconColor = null;

  final String mode;
  final String? icon;
  final String? color;
  final String? iconColor;
  final String? imageUri;
  final String? source;

  static CityPoiVisualDTO? tryFromJson(Object? raw) {
    final json = _normalizeMap(raw);
    if (json == null || json.isEmpty) {
      return null;
    }
    final mode = _resolveMode(json);

    if (mode == 'icon') {
      final icon = _readString(
        json['icon'] ?? json['icon_name'] ?? json['icon_key'] ?? json['symbol'],
      );
      final color = _normalizeHexColor(
        json['color'] ?? json['marker_color'] ?? json['background_color'],
      );
      final iconColor = _resolveIconColor(
        json['icon_color'] ?? json['iconColor'] ?? json['glyph_color'],
      );
      final source = _readString(json['source']).toLowerCase();
      if (icon.isEmpty || color == null || iconColor == null) {
        return null;
      }
      return CityPoiVisualDTO.icon(
        icon: icon,
        color: color,
        iconColor: iconColor,
        source: source.isEmpty ? null : source,
      );
    }

    if (mode == 'image') {
      final imageUri = _readString(
        json['image_uri'] ?? json['image_url'] ?? json['image'],
      );
      final source = _readString(json['source']).toLowerCase();
      if (imageUri.isEmpty) {
        return null;
      }
      return CityPoiVisualDTO.image(
        imageUri: imageUri,
        source: source.isEmpty ? null : source,
      );
    }

    return null;
  }

  static String _resolveMode(Map<Object?, Object?> json) {
    final explicitMode = _readString(json['mode']).toLowerCase();
    if (explicitMode == 'icon' || explicitMode == 'image') {
      return explicitMode;
    }

    final icon = _readString(
      json['icon'] ?? json['icon_name'] ?? json['icon_key'] ?? json['symbol'],
    );
    final color = _normalizeHexColor(
      json['color'] ?? json['marker_color'] ?? json['background_color'],
    );
    if (icon.isNotEmpty && color != null) {
      return 'icon';
    }

    final imageUri = _readString(
      json['image_uri'] ?? json['image_url'] ?? json['image'],
    );
    if (imageUri.isNotEmpty) {
      return 'image';
    }

    return '';
  }

  static String? _resolveIconColor(Object? raw) {
    final fallback = '#FFFFFF';
    final rawString = _readString(raw);
    if (rawString.isEmpty) {
      return fallback;
    }
    return _normalizeHexColor(raw);
  }

  static String? _normalizeHexColor(Object? raw) {
    var value = _readString(raw).trim().toUpperCase();
    if (value.isEmpty) {
      return null;
    }

    if (value.startsWith('0X')) {
      value = value.substring(2);
    }
    if (value.startsWith('#')) {
      value = value.substring(1);
    }

    if (value.length == 3 && RegExp(r'^[0-9A-F]{3}$').hasMatch(value)) {
      value = value.split('').map((token) => '$token$token').join();
    }

    if (value.length == 8 && RegExp(r'^[0-9A-F]{8}$').hasMatch(value)) {
      if (value.startsWith('FF')) {
        value = value.substring(2);
      } else if (value.endsWith('FF')) {
        value = value.substring(0, 6);
      } else {
        value = value.substring(0, 6);
      }
    }

    if (!RegExp(r'^[0-9A-F]{6}$').hasMatch(value)) {
      return null;
    }

    return '#$value';
  }

  static Map<Object?, Object?>? _normalizeMap(Object? raw) {
    if (raw is! Map) {
      return null;
    }
    return Map<Object?, Object?>.from(raw);
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

  Map<String, dynamic> toJson() {
    if (mode == 'icon') {
      return {
        'mode': 'icon',
        'icon': icon,
        'color': color,
        'icon_color': iconColor,
        if (source != null) 'source': source,
      };
    }

    return {
      'mode': 'image',
      'image_uri': imageUri,
      if (source != null) 'source': source,
    };
  }

  CityPoiVisual toDomain() {
    if (mode == 'icon') {
      final iconValue = PoiIconSymbolValue()..parse(icon!.trim());
      final colorHexValue = PoiHexColorValue()..parse(color!.trim());
      final iconColorHexValue = PoiHexColorValue()
        ..parse((iconColor ?? '#FFFFFF').trim());
      return CityPoiVisual.icon(
        iconValue: iconValue,
        colorHexValue: colorHexValue,
        iconColorHexValue: iconColorHexValue,
        sourceValue: _parseSourceValue(source),
      );
    }

    final imageUriValue = PoiFilterImageUriValue()..parse(imageUri!.trim());
    return CityPoiVisual.image(
      imageUriValue: imageUriValue,
      sourceValue: _parseSourceValue(source),
    );
  }

  static PoiFilterSourceValue? _parseSourceValue(String? rawSource) {
    final normalized = rawSource?.trim().toLowerCase();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }
    final value = PoiFilterSourceValue();
    value.parse(normalized);
    return value;
  }
}
