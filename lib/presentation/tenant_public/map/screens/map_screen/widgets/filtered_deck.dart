import 'package:belluga_now/domain/map/city_poi_model.dart';
import 'package:belluga_now/presentation/tenant_public/map/screens/map_screen/controllers/map_screen_controller.dart';
import 'package:belluga_now/presentation/tenant_public/map/screens/map_screen/widgets/poi_card_secondary_action.dart';
import 'package:belluga_now/presentation/tenant_public/map/screens/map_screen/widgets/poi_detail_card_builder.dart';
import 'package:belluga_now/presentation/tenant_public/map/screens/map_screen/widgets/size_reporting_widget.dart';
import 'package:flutter/material.dart';

class FilteredDeck extends StatelessWidget {
  static const double _kCarouselPageInset = 8;

  const FilteredDeck({
    super.key,
    required this.pois,
    required this.controller,
    required this.colorScheme,
    required this.pageController,
    required this.cardBuilder,
    required this.onPrimaryAction,
    required this.secondaryActionForPoi,
    required this.onRoute,
    required this.onClose,
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
  final PoiCardSecondaryAction? Function(CityPoiModel poi)
      secondaryActionForPoi;
  final ValueChanged<CityPoiModel> onRoute;
  final VoidCallback onClose;
  final ValueChanged<int> onChanged;
  final double deckHeight;
  final void Function(String poiId, double height) onCardHeightChanged;
  final double deckMeasurementPadding;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AnimatedContainer(
          key: const ValueKey<String>('poi-deck-container'),
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          height: deckHeight,
          child: PageView.builder(
            controller: pageController,
            padEnds: true,
            clipBehavior: Clip.none,
            itemCount: pois.length,
            onPageChanged: onChanged,
            itemBuilder: (context, index) {
              return _FilteredDeckPage(
                poi: pois[index],
                controller: controller,
                colorScheme: colorScheme,
                cardBuilder: cardBuilder,
                onPrimaryAction: onPrimaryAction,
                secondaryActionForPoi: secondaryActionForPoi,
                onRoute: onRoute,
                onClose: onClose,
                onCardHeightChanged: onCardHeightChanged,
                deckMeasurementPadding: deckMeasurementPadding,
              );
            },
          ),
        ),
        if (pois.length > 1) ...[
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.center,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List<Widget>.generate(pois.length, (index) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: controller.poiDeckIndexStreamValue.value == index
                      ? 18
                      : 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: controller.poiDeckIndexStreamValue.value == index
                        ? colorScheme.primary
                        : colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(999),
                  ),
                );
              }),
            ),
          ),
        ],
      ],
    );
  }
}

class _FilteredDeckPage extends StatefulWidget {
  const _FilteredDeckPage({
    required this.poi,
    required this.controller,
    required this.colorScheme,
    required this.cardBuilder,
    required this.onPrimaryAction,
    required this.secondaryActionForPoi,
    required this.onRoute,
    required this.onClose,
    required this.onCardHeightChanged,
    required this.deckMeasurementPadding,
  });

  final CityPoiModel poi;
  final MapScreenController controller;
  final ColorScheme colorScheme;
  final PoiDetailCardBuilder cardBuilder;
  final ValueChanged<CityPoiModel> onPrimaryAction;
  final PoiCardSecondaryAction? Function(CityPoiModel poi)
      secondaryActionForPoi;
  final ValueChanged<CityPoiModel> onRoute;
  final VoidCallback onClose;
  final void Function(String poiId, double height) onCardHeightChanged;
  final double deckMeasurementPadding;

  @override
  State<_FilteredDeckPage> createState() => _FilteredDeckPageState();
}

class _FilteredDeckPageState extends State<_FilteredDeckPage> {
  @override
  void initState() {
    super.initState();
    widget.controller.ensureDeckPoiHydrated(widget.poi);
  }

  @override
  void didUpdateWidget(covariant _FilteredDeckPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.poi.id != widget.poi.id) {
      widget.controller.ensureDeckPoiHydrated(widget.poi);
    }
  }

  @override
  Widget build(BuildContext context) {
    final poi = widget.poi;
    return LayoutBuilder(
      builder: (context, constraints) {
        final heroMaxHeight = (constraints.maxHeight * 0.20).clamp(
          80.0,
          84.0,
        );
        return Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: FilteredDeck._kCarouselPageInset,
            ),
            child: SizeReportingWidget(
              onSizeChanged: (size) => widget.onCardHeightChanged(
                poi.id,
                size.height + widget.deckMeasurementPadding,
              ),
              child: widget.cardBuilder.build(
                context: context,
                poi: poi,
                colorScheme: widget.colorScheme,
                onPrimaryAction: () {
                  widget.controller.selectPoi(poi);
                  widget.onPrimaryAction(poi);
                },
                secondaryAction: widget.secondaryActionForPoi(poi),
                onRoute: () => widget.onRoute(poi),
                onClose: widget.onClose,
                heroMaxHeight: heroMaxHeight,
              ),
            ),
          ),
        );
      },
    );
  }
}
