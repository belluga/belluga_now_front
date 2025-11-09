import 'package:flutter/material.dart';
import 'package:belluga_now/domain/map/map_status.dart';

class MapStatusVisuals {
  const MapStatusVisuals({
    required this.icon,
    required this.background,
    required this.textColor,
  });

  final IconData icon;
  final Color background;
  final Color textColor;
}

MapStatusVisuals resolveStatusVisuals(
  MapStatus status,
  ThemeData theme,
) {
  final scheme = theme.colorScheme;
  switch (status) {
    case MapStatus.locating:
      return MapStatusVisuals(
        icon: Icons.my_location_outlined,
        background: scheme.surfaceContainerHighest,
        textColor: scheme.onSurfaceVariant,
      );
    case MapStatus.fetching:
      return MapStatusVisuals(
        icon: Icons.downloading_outlined,
        background: scheme.surfaceContainerHighest,
        textColor: scheme.onSurfaceVariant,
      );
    case MapStatus.ready:
      return MapStatusVisuals(
        icon: Icons.check_circle_outline,
        background: scheme.secondaryContainer,
        textColor: scheme.onSecondaryContainer,
      );
    case MapStatus.error:
      return MapStatusVisuals(
        icon: Icons.warning_amber,
        background: scheme.errorContainer,
        textColor: scheme.onErrorContainer,
      );
    case MapStatus.fallback:
      return MapStatusVisuals(
        icon: Icons.map_outlined,
        background: scheme.tertiaryContainer,
        textColor: scheme.onTertiaryContainer,
      );
  }
}
