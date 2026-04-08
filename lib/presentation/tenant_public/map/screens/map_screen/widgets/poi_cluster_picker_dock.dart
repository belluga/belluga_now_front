import 'dart:math' as math;

import 'package:belluga_now/domain/map/city_poi_model.dart';
import 'package:belluga_now/presentation/shared/widgets/belluga_network_image.dart';
import 'package:belluga_now/presentation/tenant_public/map/screens/map_screen/controllers/map_screen_controller.dart';
import 'package:belluga_now/presentation/tenant_public/map/screens/map_screen/widgets/shared/poi_content_resolver.dart';
import 'package:flutter/material.dart';

const double _kClusterPickerVisualSize = 46;

class PoiClusterPickerPopover extends StatelessWidget {
  const PoiClusterPickerPopover({
    super.key,
    required this.controller,
    required this.pois,
  });

  final MapScreenController controller;
  final List<CityPoiModel> pois;

  @override
  Widget build(BuildContext context) {
    if (pois.isEmpty) {
      return const SizedBox.shrink();
    }
    final scheme = Theme.of(context).colorScheme;
    final maxHeight = math.min(12.0 + (pois.length * 92.0), 296.0);
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 320),
      child: DecoratedBox(
        key: const ValueKey<String>('map-cluster-picker-popover'),
        decoration: BoxDecoration(
          color: scheme.surface.withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 20,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: maxHeight),
                child: ListView.separated(
                  key: const ValueKey<String>('map-cluster-picker-list'),
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  itemCount: pois.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final poi = pois[index];
                    return _ClusterPickerItem(
                      poi: poi,
                      onTap: () => controller.handleClusterPickerPoiSelection(
                        poi,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ClusterPickerItem extends StatelessWidget {
  const _ClusterPickerItem({
    required this.poi,
    required this.onTap,
  });

  final CityPoiModel poi;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final titleStyle = Theme.of(context).textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w700,
        );
    final subtitleStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
          color: scheme.onSurfaceVariant,
        );
    final badgeLabel = PoiContentResolver.eventTimingBadgeLabel(poi);
    final isLiveNow = poi.isHappeningNow && badgeLabel != null;

    return Material(
      color: scheme.surfaceContainerHigh.withValues(alpha: 0.72),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        key: ValueKey<String>('map-cluster-picker-item-${poi.id}'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              _ClusterPickerItemVisual(poi: poi),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (badgeLabel != null) ...[
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: isLiveNow
                              ? scheme.errorContainer
                              : scheme.primaryContainer,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          child: Text(
                            badgeLabel.toUpperCase(),
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: isLiveNow
                                      ? scheme.onErrorContainer
                                      : scheme.onPrimaryContainer,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.6,
                                ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                    ],
                    Text(
                      poi.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: titleStyle,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      PoiContentResolver.searchMeta(poi),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: subtitleStyle,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: scheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ClusterPickerItemVisual extends StatelessWidget {
  const _ClusterPickerItemVisual({
    required this.poi,
  });

  final CityPoiModel poi;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final imageUri = PoiContentResolver.thumbnailImageUri(poi);
    final assetPath = PoiContentResolver.assetPath(poi);

    Widget child;
    if (imageUri != null && imageUri.isNotEmpty) {
      child = BellugaNetworkImage(
        imageUri,
        width: _kClusterPickerVisualSize,
        height: _kClusterPickerVisualSize,
        fit: BoxFit.cover,
        clipBorderRadius: BorderRadius.circular(14),
      );
    } else if (assetPath != null && assetPath.isNotEmpty) {
      child = ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Image.asset(
          assetPath,
          width: _kClusterPickerVisualSize,
          height: _kClusterPickerVisualSize,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildPlaceholder(scheme),
        ),
      );
    } else {
      child = _buildPlaceholder(scheme);
    }

    return SizedBox(
      width: _kClusterPickerVisualSize,
      height: _kClusterPickerVisualSize,
      child: child,
    );
  }

  Widget _buildPlaceholder(ColorScheme scheme) {
    final backgroundColor =
        PoiContentResolver.accentColor(poi) ?? scheme.primaryContainer;
    final iconColor =
        PoiContentResolver.iconColor(poi) ?? scheme.onPrimaryContainer;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Center(
        child: Icon(
          PoiContentResolver.icon(poi),
          color: iconColor,
          size: 20,
        ),
      ),
    );
  }
}
