import 'package:belluga_now/presentation/tenant/map/screens/map_screen/widgets/poi_base_card.dart';
import 'package:flutter/material.dart';

class PoiDefaultCard extends PoiBaseCard {
  const PoiDefaultCard({
    super.key,
    required super.poi,
    required super.colorScheme,
    required super.onPrimaryAction,
    required super.onShare,
    required super.onRoute,
  });

  @override
  List<Widget Function(BuildContext)> buildSections() => [
        addressSection,
        tagsSection,
      ];
}
