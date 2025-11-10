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
  final _fabController = GetIt.I.get<FabMenuController>();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return StreamValueBuilder<bool>(
      streamValue: _fabController.expandedStreamValue,
      builder: (_, isExpanded) {
        return StreamValueBuilder<PoiFilterMode>(
          streamValue: _fabController.filterModeStreamValue,
          builder: (_, mode) {
            final filterActive = mode != PoiFilterMode.none;
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (isExpanded) ...[
                  _ActionButton(
                    label: 'Ir para você',
                    icon: Icons.my_location,
                    backgroundColor: scheme.secondaryContainer,
                    foregroundColor: scheme.onSecondaryContainer,
                    onTap: widget.onNavigateToUser,
                  ),
                  const SizedBox(height: 8),
                  _ActionButton(
                    label:
                        filterActive ? 'Limpar filtro' : 'Eventos acontecendo',
                    icon: filterActive
                        ? Icons.layers_clear
                        : Icons.local_activity,
                    backgroundColor:
                        filterActive ? scheme.errorContainer : scheme.primary,
                    foregroundColor: filterActive
                        ? scheme.onErrorContainer
                        : scheme.onPrimary,
                    onTap: _fabController.toggleEventFilter,
                  ),
                  const SizedBox(height: 12),
                ],
                FloatingActionButton(
                  heroTag: 'map-fab-main',
                  onPressed: _fabController.toggleExpanded,
                  child: Icon(isExpanded ? Icons.close : Icons.tune),
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
  });

  final String label;
  final IconData icon;
  final Color backgroundColor;
  final Color foregroundColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      heroTag: '${label.hashCode}-${icon.codePoint}',
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      elevation: 0.5,
      onPressed: onTap,
      icon: Icon(icon),
      label: Text(label),
    );
  }
}
