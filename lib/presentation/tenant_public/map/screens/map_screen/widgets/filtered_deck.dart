import 'package:belluga_now/domain/map/city_poi_model.dart';
import 'package:belluga_now/presentation/tenant_public/map/screens/map_screen/controllers/map_screen_controller.dart';
import 'package:belluga_now/presentation/tenant_public/map/screens/map_screen/widgets/poi_detail_card_builder.dart';
import 'package:belluga_now/presentation/tenant_public/map/screens/map_screen/widgets/size_reporting_widget.dart';
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
              return AnimatedBuilder(
                animation: pageController,
                builder: (context, child) {
                  final selectedPage =
                      controller.poiDeckIndexStreamValue.value.toDouble();
                  final page = pageController.hasClients
                      ? (pageController.page ?? selectedPage)
                      : selectedPage;
                  final delta = (page - index).abs();
                  final scale = (1 - (delta * 0.06)).clamp(0.92, 1.0);
                  final opacity = (1 - (delta * 0.18)).clamp(0.72, 1.0);
                  final verticalOffset = (delta * 12).clamp(0, 14).toDouble();

                  return Opacity(
                    opacity: opacity,
                    child: Transform.translate(
                      offset: Offset(0, verticalOffset),
                      child: Transform.scale(
                        scale: scale,
                        child: child,
                      ),
                    ),
                  );
                },
                child: Padding(
                  padding: EdgeInsets.only(
                    left: index == 0 ? 0 : 4,
                    right: index == pois.length - 1 ? 0 : 4,
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
                ),
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
                  width:
                      controller.poiDeckIndexStreamValue.value == index ? 18 : 7,
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
