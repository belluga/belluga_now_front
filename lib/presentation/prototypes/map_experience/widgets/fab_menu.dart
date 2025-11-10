import 'dart:async';

import 'package:belluga_now/infrastructure/repositories/poi_repository.dart';
import 'package:belluga_now/presentation/prototypes/map_experience/controllers/fab_menu_controller.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value_builder.dart';

class FabMenu extends StatefulWidget {
  const FabMenu({
    super.key,
    required this.onNavigateToUser,
  });

  final Future<void> Function() onNavigateToUser;

  @override
  State<FabMenu> createState() => _FabMenuState();
}

class _FabMenuState extends State<FabMenu> {
  static const _condenseDelay = Duration(seconds: 2);

  final _fabController = GetIt.I.get<FabMenuController>();

  bool _condensed = false;
  bool? _lastExpanded;
  Timer? _condenseTimer;

  @override
  void dispose() {
    _condenseTimer?.cancel();
    super.dispose();
  }

  void _handleExpandedChange(bool expanded) {
    _condenseTimer?.cancel();
    if (!expanded) {
      if (_condensed) {
        setState(() => _condensed = false);
      }
      return;
    }
    if (_condensed) {
      setState(() => _condensed = false);
    }
    _condenseTimer = Timer(_condenseDelay, () {
      if (!mounted) {
        return;
      }
      setState(() => _condensed = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return StreamValueBuilder<bool>(
      streamValue: _fabController.expandedStreamValue,
      builder: (_, expanded) {
        if (_lastExpanded != expanded) {
          _lastExpanded = expanded;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _handleExpandedChange(expanded);
            }
          });
        }
        return StreamValueBuilder<PoiFilterMode>(
          streamValue: _fabController.filterModeStreamValue,
          builder: (_, mode) {
            final filterConfigs = [
              _FilterConfig(
                mode: PoiFilterMode.events,
                label: 'Eventos agora',
                icon: Icons.local_activity,
                activeColor: scheme.primary,
                activeForeground: scheme.onPrimary,
              ),
              _FilterConfig(
                mode: PoiFilterMode.restaurants,
                label: 'Restaurantes',
                icon: Icons.restaurant,
                activeColor: scheme.secondary,
                activeForeground: scheme.onSecondary,
              ),
              _FilterConfig(
                mode: PoiFilterMode.beaches,
                label: 'Praias',
                icon: Icons.beach_access,
                activeColor: scheme.tertiary,
                activeForeground: scheme.onTertiary,
              ),
              _FilterConfig(
                mode: PoiFilterMode.lodging,
                label: 'Hospedagens',
                icon: Icons.hotel,
                activeColor: scheme.primaryContainer,
                activeForeground: scheme.onPrimaryContainer,
              ),
            ];

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (expanded) ...[
                  _ActionButton(
                    label: 'Ir para você',
                    icon: Icons.my_location,
                    backgroundColor: scheme.secondaryContainer,
                    foregroundColor: scheme.onSecondaryContainer,
                    onTap: widget.onNavigateToUser,
                    condensed: _condensed,
                  ),
                  const SizedBox(height: 8),
                  ...filterConfigs.map((config) {
                    final isActive = mode == config.mode;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _ActionButton(
                        label: config.label,
                        icon: config.icon,
                        backgroundColor:
                            isActive ? config.activeColor : scheme.surface,
                        foregroundColor: isActive
                            ? config.activeForeground
                            : scheme.onSurfaceVariant,
                        onTap: () =>
                            _fabController.toggleFilterMode(config.mode),
                        condensed: _condensed,
                      ),
                    );
                  }),
                  const SizedBox(height: 4),
                ],
                FloatingActionButton(
                  heroTag: 'map-fab-main',
                  onPressed: _fabController.toggleExpanded,
                  child: Icon(expanded ? Icons.close : Icons.tune),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.onTap,
    required this.condensed,
  });

  final String label;
  final IconData icon;
  final Color backgroundColor;
  final Color foregroundColor;
  final VoidCallback onTap;
  final bool condensed;

  @override
  Widget build(BuildContext context) {
    if (condensed) {
      return FloatingActionButton.small(
        heroTag: 'condensed-${label.hashCode}-${icon.codePoint}',
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        elevation: 0.5,
        onPressed: onTap,
        child: Icon(icon),
      );
    }
    return FloatingActionButton.extended(
      heroTag: 'expanded-${label.hashCode}-${icon.codePoint}',
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      elevation: 0.5,
      onPressed: onTap,
      icon: Icon(icon),
      label: Text(label),
    );
  }
}

class _FilterConfig {
  const _FilterConfig({
    required this.mode,
    required this.label,
    required this.icon,
    required this.activeColor,
    required this.activeForeground,
  });

  final PoiFilterMode mode;
  final String label;
  final IconData icon;
  final Color activeColor;
  final Color activeForeground;
}
