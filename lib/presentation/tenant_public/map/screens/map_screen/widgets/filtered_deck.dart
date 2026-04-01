import 'package:belluga_now/domain/map/city_poi_model.dart';
import 'package:belluga_now/domain/map/filters/poi_filter_mode.dart';
import 'package:belluga_now/domain/map/projections/city_poi_visual.dart';
import 'package:belluga_now/presentation/tenant_public/map/screens/map_screen/controllers/map_screen_controller.dart';
import 'package:belluga_now/presentation/tenant_public/map/screens/map_screen/widgets/poi_detail_card_builder.dart';
import 'package:belluga_now/presentation/tenant_public/map/screens/map_screen/widgets/size_reporting_widget.dart';
import 'package:belluga_now/presentation/tenant_public/map/screens/map_screen/widgets/shared/map_marker_icon_resolver.dart';
import 'package:flutter/material.dart';

class FilteredDeck extends StatelessWidget {
  const FilteredDeck({
    super.key,
    required this.pois,
    required this.controller,
    required this.colorScheme,
    required this.pageController,
    required this.cardBuilder,
    required this.onPrimaryAction,
    required this.onShare,
    required this.onRoute,
    required this.onChanged,
    required this.deckHeight,
    required this.onCardHeightChanged,
    required this.deckMeasurementPadding,
  });

  final List<CityPoiModel> pois;
  final MapScreenController controller;
  final ColorScheme colorScheme;
  final PageController pageController;
  final PoiDetailCardBuilder cardBuilder;
  final ValueChanged<CityPoiModel> onPrimaryAction;
  final ValueChanged<CityPoiModel> onShare;
  final ValueChanged<CityPoiModel> onRoute;
  final ValueChanged<int> onChanged;
  final double deckHeight;
  final void Function(String poiId, double height) onCardHeightChanged;
  final double deckMeasurementPadding;

  @override
  Widget build(BuildContext context) {
    final visual = _resolveDeckVisual();
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              _iconForDeckVisual(visual),
              color: _accentColorForDeckVisual(
                visual: visual,
                scheme: colorScheme,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _titleForFilterMode(controller.filterModeStreamValue.value),
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        const SizedBox(height: 12),
        AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          height: deckHeight,
          child: PageView.builder(
            controller: pageController,
            padEnds: false,
            itemCount: pois.length,
            onPageChanged: onChanged,
            itemBuilder: (context, index) {
              final poi = pois[index];
              return Padding(
                padding: EdgeInsets.only(
                  right: index == pois.length - 1 ? 0 : 12,
                ),
                child: OverflowBox(
                  alignment: Alignment.topCenter,
                  minHeight: 0,
                  maxHeight: double.infinity,
                  child: SizeReportingWidget(
                    onSizeChanged: (size) => onCardHeightChanged(
                      poi.id,
                      size.height + deckMeasurementPadding,
                    ),
                    child: cardBuilder.build(
                      context: context,
                      poi: poi,
                      colorScheme: colorScheme,
                      onPrimaryAction: () {
                        controller.selectPoi(poi);
                        onPrimaryAction(poi);
                      },
                      onShare: () => onShare(poi),
                      onRoute: () => onRoute(poi),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  String _titleForFilterMode(PoiFilterMode mode) {
    switch (mode) {
      case PoiFilterMode.events:
        return 'Eventos em destaque';
      case PoiFilterMode.restaurants:
        return 'Sugestões gastronômicas';
      case PoiFilterMode.beaches:
        return 'Praias recomendadas';
      case PoiFilterMode.lodging:
        return 'Hospedagens parceiras';
      case PoiFilterMode.server:
        return controller.activeFilterLabelStreamValue.value ??
            'Filtro do mapa';
      case PoiFilterMode.none:
        return 'Pontos selecionados';
    }
  }

  IconData _iconForFilterMode(PoiFilterMode mode) {
    return switch (mode) {
      PoiFilterMode.server => Icons.tune,
      PoiFilterMode.none => Icons.map,
      _ => MapMarkerIconResolver.fallbackIcon,
    };
  }

  CityPoiVisual? _resolveDeckVisual() {
    final selected = controller.selectedPoiStreamValue.value?.visual;
    if (selected != null && selected.isValid) {
      return selected;
    }
    for (final poi in pois) {
      final candidate = poi.visual;
      if (candidate != null && candidate.isValid) {
        return candidate;
      }
    }
    return null;
  }

  IconData _iconForDeckVisual(CityPoiVisual? visual) {
    if (visual?.isIcon == true) {
      return MapMarkerIconResolver.resolve(visual?.icon);
    }
    if (visual?.isImage == true) {
      return Icons.image_outlined;
    }

    return _iconForFilterMode(controller.filterModeStreamValue.value);
  }

  Color _accentColorForDeckVisual({
    required CityPoiVisual? visual,
    required ColorScheme scheme,
  }) {
    if (visual?.isIcon == true) {
      return MapMarkerIconResolver.tryParseHexColor(visual?.colorHex) ??
          scheme.primary;
    }

    return scheme.primary;
  }
}
