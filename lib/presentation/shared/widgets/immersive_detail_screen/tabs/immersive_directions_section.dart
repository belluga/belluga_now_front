import 'package:belluga_now/presentation/shared/widgets/directions_app_chooser/directions_app_chooser_contract.dart';
import 'package:belluga_now/presentation/shared/widgets/directions_app_chooser/directions_launch_target.dart';
import 'package:belluga_now/presentation/shared/widgets/directions_app_chooser/directions_provider_actions.dart';
import 'package:belluga_now/presentation/shared/widgets/immersive_detail_screen/immersive_common_tabs.dart';
import 'package:flutter/material.dart';

class ImmersiveDirectionsSection extends StatelessWidget {
  const ImmersiveDirectionsSection({
    super.key,
    required this.mapCanvas,
    this.destinationLabel = 'Ver no mapa',
    this.destinationSubtitle,
    this.distanceLabel,
    this.canOpenMap = false,
    this.onOpenMap,
    this.directionsTarget,
    this.onOpenDirectDirections,
    this.onOpenOtherDirections,
    this.extraChildren = const <Widget>[],
    this.padding = const EdgeInsets.all(16),
    this.titleStyle,
    this.mapTileKey,
    this.distanceBadgeKey,
    this.primaryWazeButtonKey,
    this.primaryUberButtonKey,
    this.primaryOtherButtonKey,
  });

  final Widget mapCanvas;
  final String destinationLabel;
  final String? destinationSubtitle;
  final String? distanceLabel;
  final bool canOpenMap;
  final VoidCallback? onOpenMap;
  final DirectionsLaunchTarget? directionsTarget;
  final Future<void> Function(
    DirectionsDirectProvider provider,
    DirectionsLaunchTarget target,
  )? onOpenDirectDirections;
  final Future<void> Function(DirectionsLaunchTarget target)?
      onOpenOtherDirections;
  final List<Widget> extraChildren;
  final EdgeInsetsGeometry padding;
  final TextStyle? titleStyle;
  final Key? mapTileKey;
  final Key? distanceBadgeKey;
  final Key? primaryWazeButtonKey;
  final Key? primaryUberButtonKey;
  final Key? primaryOtherButtonKey;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final subtitle = destinationSubtitle?.trim();
    final hasSubtitle = subtitle != null && subtitle.isNotEmpty;
    final badge = distanceLabel?.trim();
    final hasBadge = badge != null && badge.isNotEmpty;
    final addressCardBackground = colorScheme.surface.withValues(alpha: 0.95);
    final addressCardForeground =
        _contentColorForBackground(addressCardBackground, colorScheme);

    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            ImmersiveCommonTabs.directionsTitle,
            style: titleStyle ??
                theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            key: mapTileKey,
            onTap: canOpenMap ? onOpenMap : null,
            child: Container(
              height: 260,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                color: colorScheme.surfaceContainerHighest,
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  mapCanvas,
                  if (hasBadge)
                    Positioned(
                      top: 16,
                      right: 16,
                      child: Container(
                        key: distanceBadgeKey,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.96),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          badge,
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: _contentColorForBackground(
                              Colors.white.withValues(alpha: 0.96),
                              colorScheme,
                            ),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    left: 18,
                    right: 18,
                    bottom: 18,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: addressCardBackground,
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: colorScheme.primaryContainer,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.near_me_outlined,
                              color: _contentColorForBackground(
                                colorScheme.primaryContainer,
                                colorScheme,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  destinationLabel,
                                  style: theme.textTheme.labelLarge?.copyWith(
                                    color: addressCardForeground,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                if (hasSubtitle) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    subtitle,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style:
                                        theme.textTheme.titleMedium?.copyWith(
                                      color: addressCardForeground,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          if (canOpenMap)
                            Icon(
                              Icons.map_outlined,
                              color: addressCardForeground,
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (directionsTarget != null) ...[
            const SizedBox(height: 12),
            DirectionsProviderActions(
              target: directionsTarget!,
              isPrimary: true,
              onOpenDirectDirections: onOpenDirectDirections,
              onOpenOtherDirections: onOpenOtherDirections,
              wazeButtonKey: primaryWazeButtonKey,
              uberButtonKey: primaryUberButtonKey,
              otherButtonKey: primaryOtherButtonKey,
            ),
          ],
          ...extraChildren,
        ],
      ),
    );
  }

  Color _contentColorForBackground(
    Color background,
    ColorScheme colorScheme,
  ) {
    return ThemeData.estimateBrightnessForColor(background) == Brightness.dark
        ? Colors.white
        : colorScheme.onSurface;
  }
}
