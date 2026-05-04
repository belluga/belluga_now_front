import 'package:belluga_now/application/icons/boora_icons.dart';
import 'package:flutter/material.dart';

import 'package:belluga_now/presentation/shared/icons/map_marker_icon_catalog.dart';

class MapMarkerVisualResolver {
  const MapMarkerVisualResolver._();

  static const IconData fallbackIcon = BooraIcons.local;

  static IconData resolveIcon(String? rawIcon) {
    final token = MapMarkerIconToken.fromStorage(rawIcon);
    if (token == null) {
      return fallbackIcon;
    }
    return token.iconData;
  }

  static Color? tryParseHexColor(String? rawColor) {
    final resolved = rawColor?.trim().toUpperCase() ?? '';
    if (!RegExp(r'^#[0-9A-F]{6}$').hasMatch(resolved)) {
      return null;
    }

    final hex = resolved.substring(1);
    final value = int.tryParse(hex, radix: 16);
    if (value == null) {
      return null;
    }

    return Color(0xFF000000 | value);
  }
}
