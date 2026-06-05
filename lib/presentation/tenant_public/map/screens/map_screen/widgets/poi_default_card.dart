import 'package:belluga_now/presentation/tenant_public/map/screens/map_screen/widgets/poi_base_card.dart';
import 'package:flutter/material.dart';

class PoiDefaultCard extends PoiBaseCard {
  const PoiDefaultCard({
    super.key,
    required super.poi,
    required super.colorScheme,
    required super.onPrimaryAction,
    super.showPrimaryAction,
    required super.secondaryAction,
    required super.onRoute,
    super.referencePointAction,
    super.onClose,
    super.heroMaxHeight,
  });

  @override
  List<Widget Function(BuildContext)> buildSections() => [tagsSection];
}
