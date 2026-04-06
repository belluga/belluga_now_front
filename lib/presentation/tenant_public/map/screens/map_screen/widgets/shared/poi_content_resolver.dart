import 'package:belluga_now/domain/map/city_poi_model.dart';
import 'package:belluga_now/presentation/tenant_public/map/screens/map_screen/widgets/shared/map_marker_icon_resolver.dart';
import 'package:flutter/material.dart';

class PoiContentResolver {
  const PoiContentResolver._();

  static String badgeLabel(CityPoiModel poi) {
    if (poi.isHappeningNow) {
      return 'Ao vivo';
    }
    return typeLabel(poi);
  }

  static String typeLabel(CityPoiModel poi) {
    final refType = poi.refType.trim();
    if (refType.isNotEmpty && refType.toLowerCase() != 'static') {
      return _humanizeToken(refType);
    }
    return _humanizeToken(poi.category.name);
  }

  static String? sanitizedDescription(CityPoiModel poi) {
    final cleaned = _sanitizeText(poi.description);
    if (cleaned == null || cleaned.length < 3) {
      return null;
    }
    final usefulAddress = compactAddress(poi);
    if (usefulAddress != null &&
        cleaned.toLowerCase() == usefulAddress.toLowerCase()) {
      return null;
    }
    return cleaned;
  }

  static String? compactAddress(CityPoiModel poi) {
    final cleaned = _sanitizeText(poi.address);
    if (cleaned == null) {
      return null;
    }
    final parts = cleaned
        .split(',')
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .where((part) {
          final normalized = part.toLowerCase();
          return normalized != 'mapa' && normalized != 'map';
        })
        .take(2)
        .toList(growable: false);
    if (parts.isEmpty) {
      return null;
    }
    final compact = parts.join(' • ').trim();
    if (compact.isEmpty) {
      return null;
    }
    return compact;
  }

  static String? distanceLabel(
    CityPoiModel poi, {
    bool includeAudienceSuffix = false,
  }) {
    final distance = poi.distanceMeters;
    if (distance == null || !distance.isFinite || distance <= 0) {
      return null;
    }
    final suffix = includeAudienceSuffix ? ' de você' : '';
    if (distance < 1000) {
      return '${distance.round()}m$suffix';
    }
    final inKm = distance / 1000;
    return '${inKm.toStringAsFixed(inKm >= 10 ? 0 : 1)} km$suffix';
  }

  static String searchMeta(CityPoiModel poi) {
    final meta = <String>[];
    final distance = distanceLabel(poi);
    final address = compactAddress(poi);
    if (distance != null) {
      meta.add(distance);
    }
    if (address != null) {
      meta.add(address);
    }
    if (meta.isEmpty) {
      meta.add(typeLabel(poi));
    }
    return meta.join(' • ');
  }

  static List<String> tags(CityPoiModel poi, {int limit = 2}) {
    final values = <String>[];
    for (final tag in poi.tags) {
      final cleaned = _sanitizeText(tag.value);
      if (cleaned == null) {
        continue;
      }
      values.add(cleaned);
      if (values.length >= limit) {
        break;
      }
    }
    return List<String>.unmodifiable(values);
  }

  static String? imageUri(CityPoiModel poi) {
    final imageUri = poi.visual?.isImage == true ? poi.visual?.imageUri : null;
    final trimmed = imageUri?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    return trimmed;
  }

  static String? assetPath(CityPoiModel poi) {
    final trimmed = poi.assetPath?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    return trimmed;
  }

  static IconData icon(CityPoiModel poi) {
    return poi.visual?.isIcon == true
        ? MapMarkerIconResolver.resolve(poi.visual?.icon)
        : MapMarkerIconResolver.fallbackIcon;
  }

  static Color? accentColor(CityPoiModel poi) {
    if (poi.visual?.isIcon != true) {
      return null;
    }
    return MapMarkerIconResolver.tryParseHexColor(poi.visual?.colorHex);
  }

  static Color? iconColor(CityPoiModel poi) {
    if (poi.visual?.isIcon != true) {
      return null;
    }
    return MapMarkerIconResolver.tryParseHexColor(poi.visual?.iconColorHex);
  }

  static String? updatedAtLabel(CityPoiModel poi) {
    final updatedAt = poi.updatedAt;
    if (updatedAt == null) {
      return null;
    }
    final day = updatedAt.day.toString().padLeft(2, '0');
    final month = updatedAt.month.toString().padLeft(2, '0');
    final hour = updatedAt.hour.toString().padLeft(2, '0');
    final minute = updatedAt.minute.toString().padLeft(2, '0');
    return 'Atualizado em $day/$month • $hour:$minute';
  }

  static String _humanizeToken(String raw) {
    final normalized = raw
        .trim()
        .replaceAllMapped(
          RegExp(r'([a-z0-9])([A-Z])'),
          (match) => '${match.group(1)} ${match.group(2)}',
        )
        .replaceAll(RegExp(r'[_-]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (normalized.isEmpty) {
      return '';
    }
    return normalized.split(' ').map((part) {
      if (part.isEmpty) {
        return part;
      }
      return '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}';
    }).join(' ');
  }

  static String? _sanitizeText(String raw) {
    final stripped = raw
        .replaceAll(RegExp(r'<[^>]*>'), ' ')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (stripped.isEmpty) {
      return null;
    }
    return stripped;
  }
}
