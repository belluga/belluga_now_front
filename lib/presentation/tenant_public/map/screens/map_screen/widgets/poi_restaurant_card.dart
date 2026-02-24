import 'package:belluga_now/presentation/tenant/map/screens/map_screen/widgets/poi_base_card.dart';
import 'package:flutter/material.dart';

class PoiRestaurantCard extends PoiBaseCard {
  const PoiRestaurantCard({
    super.key,
    required super.poi,
    required super.colorScheme,
    required super.onPrimaryAction,
    required super.onShare,
    required super.onRoute,
  }) : super(primaryLabel: 'Ver cardápio');

  @override
  List<Widget Function(BuildContext)> buildSections() => [
        addressSection,
        (context) => Row(
              children: [
                const Icon(Icons.local_dining, size: 18),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Sabores indicados pela curadoria Belluga.',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(fontStyle: FontStyle.italic),
                  ),
                ),
              ],
            ),
        tagsSection,
      ];
}
