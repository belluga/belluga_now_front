import 'package:belluga_now/presentation/tenant_public/map/screens/map_screen/widgets/poi_base_card.dart';
import 'package:flutter/material.dart';

class PoiBeachCard extends PoiBaseCard {
  const PoiBeachCard({
    super.key,
    required super.poi,
    required super.colorScheme,
    required super.onPrimaryAction,
    required super.onShare,
    required super.onRoute,
  }) : super(primaryLabel: 'Ver rota');

  @override
  List<Widget Function(BuildContext)> buildSections() => [
        addressSection,
        (context) => Row(
              children: const [
                Icon(Icons.sunny, size: 18),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Melhor aproveitada durante o dia de hoje.',
                  ),
                ),
              ],
            ),
        tagsSection,
      ];
}
