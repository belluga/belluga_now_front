import 'package:belluga_now/domain/map/filters/main_filter_option.dart';
import 'package:belluga_now/presentation/tenant/map/screens/city_map_screen/controllers/city_map_controller.dart';
import 'package:belluga_now/presentation/tenant/map/screens/city_map_screen/controllers/fab_menu_controller.dart';
import 'package:belluga_now/presentation/tenant/map/screens/city_map_screen/widgets/shared/main_filter_icon_resolver.dart';
import 'package:flutter/material.dart';
import 'package:stream_value/core/stream_value_builder.dart';

typedef MainFilterTap = Future<void> Function(MainFilterOption option);

class CityMapMainFilterFabGroup extends StatelessWidget {
  const CityMapMainFilterFabGroup({
    super.key,
    required this.controller,
    required this.fabMenuController,
    required this.onMainFilterTap,
    required this.panelResolver,
  });

  final CityMapController controller;
  final FabMenuController fabMenuController;
  final MainFilterTap onMainFilterTap;
  final LateralPanelType? Function(MainFilterType type) panelResolver;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return StreamValueBuilder<List<MainFilterOption>>(
      streamValue: controller.mainFilterOptionsStreamValue,
      builder: (_, options) {
        if (options.isEmpty) {
          return const SizedBox.shrink();
        }
        return StreamValueBuilder<bool>(
          streamValue: fabMenuController.menuExpanded,
          builder: (_, expanded) {
            return StreamValueBuilder<MainFilterOption?>(
              streamValue: controller.activeMainFilterStreamValue,
              builder: (_, activeFilter) {
                return StreamValueBuilder<LateralPanelType?>(
                  streamValue: fabMenuController.activePanel,
                  builder: (_, activePanel) {
                    final children = <Widget>[];
                    if (expanded == true) {
                      for (final option in options.reversed) {
                        children.add(
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _SecondaryFilterFab(
                              theme: theme,
                              option: option,
                              onTap: () => onMainFilterTap(option),
                              activeFilter: activeFilter,
                              activePanel: activePanel,
                              panelType: panelResolver(option.type),
                            ),
                          ),
                        );
                      }
                    }

                    children.add(
                      FloatingActionButton(
                        heroTag: 'main-filter-toggle-fab',
                        onPressed: fabMenuController.toggleMenu,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: Icon(
                            expanded == true ? Icons.close : Icons.filter_list,
                            key: ValueKey<bool>(expanded == true),
                          ),
                        ),
                      ),
                    );

                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: children,
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

class _SecondaryFilterFab extends StatelessWidget {
  const _SecondaryFilterFab({
    required this.theme,
    required this.option,
    required this.onTap,
    required this.activeFilter,
    required this.activePanel,
    required this.panelType,
  });

  final ThemeData theme;
  final MainFilterOption option;
  final VoidCallback onTap;
  final MainFilterOption? activeFilter;
  final LateralPanelType? activePanel;
  final LateralPanelType? panelType;

  @override
  Widget build(BuildContext context) {
    final icon = resolveMainFilterIcon(option.iconName);
    final isActive = option.isQuickApply
        ? activeFilter?.id == option.id
        : (panelType != null && panelType == activePanel);
    final backgroundColor =
        isActive ? theme.colorScheme.primary : theme.colorScheme.surface;
    final foregroundColor =
        isActive ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface;

    return Tooltip(
      message: option.label,
      child: FloatingActionButton.small(
        heroTag: 'main-filter-${option.id}',
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        onPressed: onTap,
        child: Icon(icon),
      ),
    );
  }
}
