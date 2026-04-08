import 'package:belluga_now/domain/map/city_poi_category.dart';
import 'package:belluga_now/domain/map/projections/city_poi_model.dart';
import 'package:belluga_now/domain/map/projections/city_poi_stack_items.dart';
import 'package:belluga_now/domain/map/value_objects/city_coordinate.dart';
import 'package:belluga_now/domain/map/value_objects/city_poi_address_value.dart';
import 'package:belluga_now/domain/map/value_objects/city_poi_description_value.dart';
import 'package:belluga_now/domain/map/value_objects/city_poi_id_value.dart';
import 'package:belluga_now/domain/map/value_objects/city_poi_name_value.dart';
import 'package:belluga_now/domain/map/value_objects/latitude_value.dart';
import 'package:belluga_now/domain/map/value_objects/longitude_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_boolean_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_priority_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_reference_id_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_reference_type_value.dart';
import 'package:belluga_now/presentation/tenant_public/map/screens/map_screen/widgets/map_layers.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('selected poi renders last in annotation order', () {
    final first = _buildPoi('first');
    final selected = _buildPoi('selected');
    final third = _buildPoi('third');

    final ordered = MapLayers.orderPoisForRendering(
      pois: [first, selected, third],
      selectedPoi: selected,
    );

    expect(
        ordered.map((poi) => poi.id).toList(), ['first', 'third', 'selected']);
  });

  test('remembered poi renders last when no active selection exists', () {
    final first = _buildPoi('first');
    final remembered = _buildPoi('remembered');
    final third = _buildPoi('third');

    final ordered = MapLayers.orderPoisForRendering(
      pois: [first, remembered, third],
      rememberedPoiId: 'remembered',
    );

    expect(
      ordered.map((poi) => poi.id).toList(),
      ['first', 'third', 'remembered'],
    );
  });
}

CityPoiModel _buildPoi(String id) {
  return CityPoiModel(
    idValue: CityPoiIdValue()..parse(id),
    nameValue: CityPoiNameValue()..parse(id),
    descriptionValue: CityPoiDescriptionValue()..parse('desc $id'),
    addressValue: CityPoiAddressValue()..parse('addr $id'),
    category: CityPoiCategory.attraction,
    coordinate: CityCoordinate(
      latitudeValue: LatitudeValue()..parse('-20.0'),
      longitudeValue: LongitudeValue()..parse('-40.0'),
    ),
    priorityValue: PoiPriorityValue()..parse('10'),
    isDynamicValue: PoiBooleanValue()..parse('false'),
    refTypeValue: PoiReferenceTypeValue()..parse('static'),
    refIdValue: PoiReferenceIdValue()..parse(id),
    stackItems: CityPoiStackItems(),
  );
}
