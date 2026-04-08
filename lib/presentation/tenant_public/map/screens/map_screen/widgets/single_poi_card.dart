import 'package:belluga_now/domain/map/city_poi_model.dart';
import 'package:belluga_now/presentation/tenant_public/map/screens/map_screen/widgets/poi_card_secondary_action.dart';
import 'package:belluga_now/presentation/tenant_public/map/screens/map_screen/widgets/poi_detail_card_builder.dart';
import 'package:belluga_now/presentation/tenant_public/map/screens/map_screen/widgets/size_reporting_widget.dart';
import 'package:flutter/material.dart';

class SinglePoiCard extends StatelessWidget {
  const SinglePoiCard({
    super.key,
    required this.poi,
    required this.colorScheme,
    required this.cardBuilder,
    required this.onPrimaryAction,
    required this.secondaryAction,
    required this.onRoute,
    required this.onClose,
    required this.onCardHeightChanged,
    required this.deckHeight,
    required this.deckMeasurementPadding,
  });

  final CityPoiModel poi;
  final ColorScheme colorScheme;
  final PoiDetailCardBuilder cardBuilder;
  final ValueChanged<CityPoiModel> onPrimaryAction;
  final PoiCardSecondaryAction? secondaryAction;
  final ValueChanged<CityPoiModel> onRoute;
  final VoidCallback onClose;
  final void Function(String poiId, double height) onCardHeightChanged;
  final double deckHeight;
  final double deckMeasurementPadding;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      key: const ValueKey<String>('poi-deck-container'),
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      height: deckHeight,
      child: OverflowBox(
        alignment: Alignment.bottomCenter,
        minHeight: 0,
        maxHeight: double.infinity,
        child: SizeReportingWidget(
          onSizeChanged: (size) =>
              onCardHeightChanged(poi.id, size.height + deckMeasurementPadding),
          child: cardBuilder.build(
            context: context,
            poi: poi,
            colorScheme: colorScheme,
            onPrimaryAction: () => onPrimaryAction(poi),
            secondaryAction: secondaryAction,
            onRoute: () => onRoute(poi),
            onClose: onClose,
          ),
        ),
      ),
    );
  }
}
