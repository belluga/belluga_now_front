import 'package:belluga_now/domain/map/city_poi_category.dart';
import 'package:belluga_now/domain/map/projections/city_poi_model.dart';
import 'package:belluga_now/domain/map/projections/city_poi_visual.dart';
import 'package:belluga_now/domain/map/projections/city_poi_stack_items.dart';
import 'package:belluga_now/domain/map/value_objects/city_coordinate.dart';
import 'package:belluga_now/domain/map/value_objects/city_poi_address_value.dart';
import 'package:belluga_now/domain/map/value_objects/city_poi_description_value.dart';
import 'package:belluga_now/domain/map/value_objects/city_poi_id_value.dart';
import 'package:belluga_now/domain/map/value_objects/city_poi_name_value.dart';
import 'package:belluga_now/domain/map/value_objects/latitude_value.dart';
import 'package:belluga_now/domain/map/value_objects/longitude_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_filter_image_uri_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_priority_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_reference_id_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_reference_type_value.dart';
import 'package:belluga_now/presentation/tenant_public/map/screens/map_screen/widgets/poi_default_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('account profile card shows avatar next to the title',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PoiDefaultCard(
            poi: _buildAccountProfilePoi(),
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
            onPrimaryAction: () {},
            secondaryAction: null,
            onRoute: () {},
          ),
        ),
      ),
    );

    expect(
        find.byKey(const ValueKey<String>('poi-card-avatar')), findsOneWidget);
    expect(find.text('Casa Marracini'), findsOneWidget);
  });

  testWidgets(
      'cards with remote cover use branded hero placeholder instead of generic gray image placeholder',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PoiDefaultCard(
            poi: _buildStaticPoiWithRemoteCover(),
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
            onPrimaryAction: () {},
            secondaryAction: null,
            onRoute: () {},
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byIcon(Icons.image_outlined), findsNothing);
  });
}

CityPoiModel _buildAccountProfilePoi() {
  final idValue = CityPoiIdValue()..parse('poi-1');
  final nameValue = CityPoiNameValue()..parse('Casa Marracini');
  final descriptionValue = CityPoiDescriptionValue()
    ..parse('Restaurante no mapa');
  final addressValue = CityPoiAddressValue()..parse('Av. Brasil');
  final priorityValue = PoiPriorityValue()..parse('1');
  final refTypeValue = PoiReferenceTypeValue()..parse('account_profile');
  final refIdValue = PoiReferenceIdValue()..parse('profile-1');
  final latitude = LatitudeValue()..parse('-20.0');
  final longitude = LongitudeValue()..parse('-40.0');
  final imageUriValue = PoiFilterImageUriValue()
    ..parse('https://tenant.test/media/casa-avatar.png');

  return CityPoiModel(
    idValue: idValue,
    nameValue: nameValue,
    descriptionValue: descriptionValue,
    addressValue: addressValue,
    category: CityPoiCategory.attraction,
    coordinate: CityCoordinate(
      latitudeValue: latitude,
      longitudeValue: longitude,
    ),
    priorityValue: priorityValue,
    refTypeValue: refTypeValue,
    refIdValue: refIdValue,
    stackItems: CityPoiStackItems(),
    visual: CityPoiVisual.image(
      imageUriValue: imageUriValue,
    ),
  );
}

CityPoiModel _buildStaticPoiWithRemoteCover() {
  final idValue = CityPoiIdValue()..parse('poi-static-1');
  final nameValue = CityPoiNameValue()..parse('Praia das Castanheiras');
  final descriptionValue = CityPoiDescriptionValue()
    ..parse('Praia urbana com quiosques.');
  final addressValue = CityPoiAddressValue()..parse('Centro');
  final priorityValue = PoiPriorityValue()..parse('1');
  final refTypeValue = PoiReferenceTypeValue()..parse('static');
  final refIdValue = PoiReferenceIdValue()..parse('static-1');
  final latitude = LatitudeValue()..parse('-20.0');
  final longitude = LongitudeValue()..parse('-40.0');
  final imageUriValue = PoiFilterImageUriValue()
    ..parse('https://tenant.test/media/castanheiras-cover.png');

  return CityPoiModel(
    idValue: idValue,
    nameValue: nameValue,
    descriptionValue: descriptionValue,
    addressValue: addressValue,
    category: CityPoiCategory.beach,
    coordinate: CityCoordinate(
      latitudeValue: latitude,
      longitudeValue: longitude,
    ),
    priorityValue: priorityValue,
    refTypeValue: refTypeValue,
    refIdValue: refIdValue,
    stackItems: CityPoiStackItems(),
    coverImageUriValue: imageUriValue,
  );
}
