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
  }) : super(primaryLabel: 'Reservar agora');

  @override
  List<Widget Function(BuildContext)> buildSections() => [
        addressSection,
        (context) => Row(
              children: const [
                Icon(Icons.king_bed_outlined, size: 18),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Conferimos disponibilidade especial para você.',
                  ),
                ),
              ],
            ),
        tagsSection,
      ];
}
