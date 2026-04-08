import 'package:belluga_now/domain/map/city_poi_model.dart';
import 'package:belluga_now/presentation/tenant_public/map/screens/map_screen/widgets/event_poi_detail_card.dart';
import 'package:belluga_now/presentation/tenant_public/map/screens/map_screen/widgets/poi_card_secondary_action.dart';
import 'package:belluga_now/presentation/tenant_public/map/screens/map_screen/widgets/poi_default_card.dart';
import 'package:flutter/material.dart';

class PoiDetailCardBuilder {
  const PoiDetailCardBuilder();

  Widget build({
    required BuildContext context,
    required CityPoiModel poi,
    required ColorScheme colorScheme,
    required VoidCallback onPrimaryAction,
    required PoiCardSecondaryAction? secondaryAction,
    required VoidCallback onRoute,
    VoidCallback? onClose,
    double? heroMaxHeight,
  }) {
    if (poi.isDynamic) {
      return EventPoiDetailCard(
        poi: poi,
        colorScheme: colorScheme,
        onPrimaryAction: onPrimaryAction,
        secondaryAction: secondaryAction,
        onRoute: onRoute,
        onClose: onClose,
        heroMaxHeight: heroMaxHeight,
      );
    }

    return PoiDefaultCard(
      poi: poi,
      colorScheme: colorScheme,
      onPrimaryAction: onPrimaryAction,
      secondaryAction: secondaryAction,
      onRoute: onRoute,
      onClose: onClose,
      heroMaxHeight: heroMaxHeight,
    );
  }
}
