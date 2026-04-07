import 'package:belluga_now/domain/map/city_poi_category.dart';
import 'package:belluga_now/domain/map/projections/city_poi_model.dart';
import 'package:belluga_now/domain/map/projections/city_poi_stack_items.dart';
import 'package:belluga_now/domain/map/value_objects/city_coordinate.dart';
import 'package:belluga_now/domain/map/value_objects/city_poi_address_value.dart';
import 'package:belluga_now/domain/map/value_objects/city_poi_description_value.dart';
import 'package:belluga_now/domain/map/value_objects/city_poi_id_value.dart';
import 'package:belluga_now/domain/map/value_objects/city_poi_name_value.dart';
import 'package:belluga_now/domain/map/value_objects/distance_in_meters_value.dart';
import 'package:belluga_now/domain/map/value_objects/latitude_value.dart';
import 'package:belluga_now/domain/map/value_objects/longitude_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_boolean_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_priority_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_reference_id_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_reference_type_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_time_end_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_time_start_value.dart';
import 'package:belluga_now/presentation/tenant_public/map/screens/map_screen/widgets/event_poi_detail_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('event detail card shows explicit schedule range',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EventPoiDetailCard(
            poi: _buildEventPoi(),
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
            onPrimaryAction: () {},
            onShare: () {},
            onRoute: () {},
          ),
        ),
      ),
    );

    expect(find.text('07/04 • 18:30 - 20:00'), findsOneWidget);
  });
}

CityPoiModel _buildEventPoi() {
  return CityPoiModel(
    idValue: CityPoiIdValue()..parse('event-poi-1'),
    nameValue: CityPoiNameValue()..parse('Estreia'),
    descriptionValue: CityPoiDescriptionValue()..parse('Evento no mapa'),
    addressValue: CityPoiAddressValue()..parse('Maratimbas'),
    category: CityPoiCategory.culture,
    coordinate: CityCoordinate(
      latitudeValue: LatitudeValue()..parse('-20.0'),
      longitudeValue: LongitudeValue()..parse('-40.0'),
    ),
    priorityValue: PoiPriorityValue()..parse('10'),
    isDynamicValue: PoiBooleanValue()..parse('true'),
    refTypeValue: PoiReferenceTypeValue()..parse('event'),
    refIdValue: PoiReferenceIdValue()..parse('event-1'),
    stackItems: CityPoiStackItems(),
    isHappeningNowValue: PoiBooleanValue()..parse('false'),
    timeStartValue: (PoiTimeStartValue()
      ..parse(DateTime(2026, 4, 7, 18, 30).toIso8601String())),
    timeEndValue: (PoiTimeEndValue()
      ..parse(DateTime(2026, 4, 7, 20, 0).toIso8601String())),
    distanceMetersValue: DistanceInMetersValue()..parse('4800'),
  );
}
