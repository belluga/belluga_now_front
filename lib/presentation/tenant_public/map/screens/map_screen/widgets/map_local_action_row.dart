import 'package:belluga_now/presentation/tenant_public/map/screens/map_screen/controllers/map_location_feedback_state.dart';
import 'package:belluga_now/presentation/tenant_public/map/screens/map_screen/controllers/map_screen_controller.dart';
import 'package:belluga_now/presentation/tenant_public/map/screens/map_screen/controllers/map_tray_mode.dart';
import 'package:belluga_now/presentation/tenant_public/map/screens/map_screen/widgets/shared/map_location_status_icon.dart';
import 'package:flutter/material.dart';
import 'package:stream_value/core/stream_value_builder.dart';

const double _kMapActionButtonHeight = 52;

class MapLocalActionRow extends StatelessWidget {
  const MapLocalActionRow({
    super.key,
    required this.controller,
  });

  final MapScreenController controller;

  @override
  Widget build(BuildContext context) {
    return StreamValueBuilder<MapTrayMode>(
      streamValue: controller.mapTrayModeStreamValue,
      builder: (_, trayMode) {
        return StreamValueBuilder<MapLocationFeedbackState>(
          streamValue: controller.locationFeedbackStateStreamValue,
          builder: (_, locationFeedbackState) {
            return StreamValueBuilder<bool>(
              streamValue: controller.isLoading,
              builder: (_, isLoading) {
                return StreamValueBuilder<bool>(
                  streamValue:
                      controller.filterInteractionLockedStreamValue,
                  builder: (_, filterLocked) {
                    final canTapFilters = !isLoading && !filterLocked;
                    return ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: Row(
                        children: [
                          Expanded(
                            child: _MapActionButton(
                              label: 'Você',
                              selected: false,
                              enabled: locationFeedbackState.isActionEnabled,
                              icon: MapLocationStatusIcon(
                                state: locationFeedbackState,
                                enabled: locationFeedbackState.isActionEnabled,
                              ),
                              onPressed: () {
                                controller.centerOnUser();
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _MapActionButton(
                              label: 'Buscar',
                              selected: trayMode == MapTrayMode.search,
                              icon: const Icon(Icons.search_rounded),
                              onPressed: controller.showSearchTray,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _MapActionButton(
                              label: 'Filtros',
                              selected: trayMode == MapTrayMode.filters,
                              enabled: canTapFilters,
                              icon: const Icon(Icons.tune_rounded),
                              onPressed: controller.showFiltersTray,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}

class _MapActionButton extends StatelessWidget {
  const _MapActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.enabled = true,
    this.selected = false,
  });

  final String label;
  final Widget icon;
  final VoidCallback onPressed;
  final bool enabled;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final backgroundColor = selected
        ? scheme.primaryContainer
        : scheme.surface.withValues(alpha: 0.96);
    final foregroundColor =
        selected ? scheme.onPrimaryContainer : scheme.onSurfaceVariant;

    return Material(
      key: ValueKey<String>('map-local-action-$label'),
      color: backgroundColor,
      borderRadius: BorderRadius.circular(18),
      elevation: 10,
      shadowColor: Colors.black26,
      child: InkWell(
        onTap: enabled ? onPressed : null,
        borderRadius: BorderRadius.circular(18),
        child: Opacity(
          opacity: enabled ? 1 : 0.56,
          child: SizedBox(
            height: _kMapActionButtonHeight,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconTheme(
                    data: IconThemeData(color: foregroundColor, size: 18),
                    child: icon,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      label,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: foregroundColor,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
