import 'package:belluga_now/domain/map/city_poi_category.dart';
import 'package:belluga_now/domain/map/city_poi_model.dart';
import 'package:belluga_now/domain/map/event_poi_model.dart';
import 'package:belluga_now/presentation/tenant/map/screens/map_screen/widgets/event_poi_detail_card.dart';
import 'package:belluga_now/presentation/tenant/map/screens/map_screen/widgets/poi_beach_card.dart';
import 'package:belluga_now/presentation/tenant/map/screens/map_screen/widgets/poi_default_card.dart';
import 'package:belluga_now/presentation/tenant/map/screens/map_screen/widgets/poi_lodging_card.dart';
import 'package:belluga_now/presentation/tenant/map/screens/map_screen/widgets/poi_restaurant_card.dart';
import 'package:flutter/material.dart';

class PoiDetailCardBuilder {
  const PoiDetailCardBuilder();

  Widget build({
    required BuildContext context,
    required CityPoiModel poi,
    required ColorScheme colorScheme,
    required VoidCallback onPrimaryAction,
    required VoidCallback onShare,
    required VoidCallback onRoute,
  }) {
    if (poi is EventPoiModel) {
      return EventPoiDetailCard(
        eventPoi: poi,
        colorScheme: colorScheme,
        onPrimaryAction: onPrimaryAction,
        onShare: onShare,
        onRoute: onRoute,
      );
    }

    switch (poi.category) {
      case CityPoiCategory.restaurant:
        return PoiRestaurantCard(
          poi: poi,
          colorScheme: colorScheme,
          onPrimaryAction: onPrimaryAction,
          onShare: onShare,
          onRoute: onRoute,
        );
      case CityPoiCategory.beach:
        return PoiBeachCard(
          poi: poi,
          colorScheme: colorScheme,
          onPrimaryAction: onPrimaryAction,
          onShare: onShare,
          onRoute: onRoute,
        );
      case CityPoiCategory.lodging:
        return PoiLodgingCard(
          poi: poi,
          colorScheme: colorScheme,
          onPrimaryAction: onPrimaryAction,
          onShare: onShare,
          onRoute: onRoute,
        );
      default:
        return PoiDefaultCard(
          poi: poi,
          colorScheme: colorScheme,
          onPrimaryAction: onPrimaryAction,
          onShare: onShare,
          onRoute: onRoute,
        );
    }
  }
}
