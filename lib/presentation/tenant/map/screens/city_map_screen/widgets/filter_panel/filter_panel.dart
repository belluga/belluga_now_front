import 'package:belluga_now/domain/map/filters/poi_filter_options.dart';
import 'package:belluga_now/presentation/tenant/map/screens/city_map_screen/controllers/city_map_controller.dart';
import 'package:belluga_now/presentation/tenant/map/screens/city_map_screen/widgets/filter_panel/widgets/filter_category_chips.dart';
import 'package:belluga_now/presentation/tenant/map/screens/city_map_screen/widgets/filter_panel/widgets/filter_error_message.dart';
import 'package:belluga_now/presentation/tenant/map/screens/city_map_screen/widgets/filter_panel/widgets/filter_tag_section.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value_builder.dart';

class FilterPanel extends StatelessWidget {
  FilterPanel({super.key});

  final CityMapController _controller = GetIt.I.get<CityMapController>();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                fit: FlexFit.loose,
                child: Text(
                  'Filtros',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              StreamValueBuilder<int>(
                streamValue: _controller.activeFilterCount,
                builder: (context, count) {
                  final hasFilters = count > 0;
                  return TextButton.icon(
                    onPressed: hasFilters ? _controller.clearFilters : null,
                    icon: const Icon(Icons.clear_all),
                    label: const Text('Limpar'),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          StreamValueBuilder<PoiFilterOptions?>(
            streamValue: _controller.filterOptionsStreamValue,
            builder: (context, options) {
              if (options == null) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    ),
                  ),
                );
              }

              if (_controller.filtersLoadFailed) {
                return FilterErrorMessage(theme: theme);
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FilterCategoryChips(options: options),
                  FilterTagSection(options: options),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
