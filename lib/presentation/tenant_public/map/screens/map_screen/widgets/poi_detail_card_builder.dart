import 'package:belluga_now/domain/map/city_poi_model.dart';
import 'package:belluga_now/presentation/tenant_public/map/screens/map_screen/widgets/event_poi_detail_card.dart';
import 'package:belluga_now/presentation/tenant_public/map/screens/map_screen/widgets/poi_card_reference_point_action.dart';
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
    bool showPrimaryAction = true,
    required PoiCardSecondaryAction? secondaryAction,
    required VoidCallback onRoute,
    PoiCardReferencePointAction? referencePointAction,
    VoidCallback? onClose,
    double? heroMaxHeight,
  }) {
    if (poi.isDynamic) {
      return EventPoiDetailCard(
        poi: poi,
        colorScheme: colorScheme,
        onPrimaryAction: onPrimaryAction,
        showPrimaryAction: showPrimaryAction,
        secondaryAction: secondaryAction,
        onRoute: onRoute,
        referencePointAction: referencePointAction,
        onClose: onClose,
        heroMaxHeight: heroMaxHeight,
      );
    }

    return PoiDefaultCard(
      poi: poi,
      colorScheme: colorScheme,
      onPrimaryAction: onPrimaryAction,
      showPrimaryAction: showPrimaryAction,
      secondaryAction: secondaryAction,
      onRoute: onRoute,
      referencePointAction: referencePointAction,
      onClose: onClose,
      heroMaxHeight: heroMaxHeight,
    );
  }
}
