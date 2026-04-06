import 'package:belluga_now/presentation/tenant_public/map/screens/map_screen/widgets/poi_base_card.dart';
import 'package:flutter/material.dart';

class PoiLodgingCard extends PoiBaseCard {
  const PoiLodgingCard({
    super.key,
    required super.poi,
    required super.colorScheme,
    required super.onPrimaryAction,
    required super.onShare,
    required super.onRoute,
  });

  @override
  List<Widget Function(BuildContext)> buildSections() => [tagsSection];
}
