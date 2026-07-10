import 'package:belluga_now/domain/map/city_poi_category.dart';
import 'package:belluga_now/domain/map/city_poi_model.dart';
import 'package:belluga_now/domain/map/projections/city_poi_stack_items.dart';
import 'package:belluga_now/domain/map/value_objects/city_coordinate.dart';
import 'package:belluga_now/domain/map/value_objects/city_poi_address_value.dart';
import 'package:belluga_now/domain/map/value_objects/city_poi_description_value.dart';
import 'package:belluga_now/domain/map/value_objects/city_poi_id_value.dart';
import 'package:belluga_now/domain/map/value_objects/city_poi_name_value.dart';
import 'package:belluga_now/domain/map/value_objects/latitude_value.dart';
import 'package:belluga_now/domain/map/value_objects/longitude_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_priority_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_reference_id_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_reference_type_value.dart';
import 'package:belluga_now/presentation/tenant_public/map/screens/map_screen/controllers/map_screen_controller.dart';
import 'package:belluga_now/presentation/tenant_public/map/screens/map_screen/widgets/filtered_deck.dart';
import 'package:belluga_now/presentation/tenant_public/map/screens/map_screen/widgets/poi_detail_card_builder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stream_value/core/stream_value.dart';

void main() {
  testWidgets(
    'same-spot filtered deck keeps tall cards inside a scrollable viewport',
    (tester) async {
      final controller = _StubMapScreenController();
      final measuredHeights = <String, double>{};
      final pois = [
        _buildPoi('poi-1', 'Primeiro'),
        _buildPoi('poi-2', 'Segundo'),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 360,
                height: 280,
                child: FilteredDeck(
                  pois: pois,
                  controller: controller,
                  colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
                  pageController: PageController(viewportFraction: 0.82),
                  cardBuilder: const _TallCardBuilder(),
                  onPrimaryAction: (_) {},
                  showPrimaryActionForPoi: (_) => true,
                  secondaryActionForPoi: (_) => null,
                  onRoute: (_) {},
                  referencePointActionForPoi: (_) => null,
                  onClose: () {},
                  onChanged: (_) {},
                  deckHeight: 240,
                  onCardHeightChanged: (poiId, height) {
                    measuredHeights[poiId] = height;
                  },
                  deckMeasurementPadding: 32,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final scrollFinder = find.byKey(
        const ValueKey<String>('poi-deck-scroll-poi-1'),
      );
      final scrollableFinder = find.descendant(
        of: scrollFinder,
        matching: find.byType(Scrollable),
      );
      final scrollable = tester.state<ScrollableState>(scrollableFinder);

      expect(scrollFinder, findsOneWidget);
      expect(scrollableFinder, findsOneWidget);
      expect(scrollable.position.maxScrollExtent, greaterThan(0));
      expect(measuredHeights['poi-1'], greaterThan(240));

      await tester.drag(scrollFinder, const Offset(0, -120));
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(scrollable.position.pixels, greaterThan(0));
    },
  );
}

class _StubMapScreenController extends Fake implements MapScreenController {
  @override
  final StreamValue<int> poiDeckIndexStreamValue = StreamValue<int>(
    defaultValue: 0,
  );

  @override
  void ensureDeckPoiHydrated(CityPoiModel poi) {}

  @override
  void selectPoi(CityPoiModel? poi) {}
}

class _TallCardBuilder extends PoiDetailCardBuilder {
  const _TallCardBuilder();

  @override
  Widget build({
    required BuildContext context,
    required CityPoiModel poi,
    required ColorScheme colorScheme,
    required VoidCallback onPrimaryAction,
    bool showPrimaryAction = true,
    required secondaryAction,
    required VoidCallback onRoute,
    referencePointAction,
    VoidCallback? onClose,
    double? heroMaxHeight,
  }) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: List<Widget>.generate(
            12,
            (index) => Padding(
              padding: const EdgeInsets.all(12),
              child: Text('${poi.name} item $index'),
            ),
          ),
        ),
      ),
    );
  }
}

CityPoiModel _buildPoi(String id, String name) {
  return CityPoiModel(
    idValue: CityPoiIdValue()..parse(id),
    nameValue: CityPoiNameValue()..parse(name),
    descriptionValue: CityPoiDescriptionValue()..parse('Descricao do ponto'),
    addressValue: CityPoiAddressValue()..parse('Centro'),
    category: CityPoiCategory.restaurant,
    coordinate: CityCoordinate(
      latitudeValue: LatitudeValue()..parse('-20.0'),
      longitudeValue: LongitudeValue()..parse('-40.0'),
    ),
    priorityValue: PoiPriorityValue()..parse('1'),
    refTypeValue: PoiReferenceTypeValue()..parse('account_profile'),
    refIdValue: PoiReferenceIdValue()..parse('ref-$id'),
    stackItems: CityPoiStackItems(),
  );
}
