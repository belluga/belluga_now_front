import 'package:belluga_now/domain/map/city_poi_category.dart';
import 'package:belluga_now/domain/map/projections/city_poi_model.dart';
import 'package:belluga_now/domain/map/projections/city_poi_visual.dart';
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
import 'package:belluga_now/domain/map/value_objects/poi_filter_image_uri_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_filter_source_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_hex_color_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_icon_symbol_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_priority_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_reference_id_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_reference_type_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_stack_count_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_stack_key_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_tag_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_type_label_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_updated_at_value.dart';
import 'package:belluga_now/domain/value_objects/asset_path_value.dart';
import 'package:belluga_now/presentation/tenant_public/map/screens/map_screen/widgets/shared/poi_content_resolver.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PoiContentResolver', () {
    test('badge label prefers ao vivo state from payload', () {
      final poi = _buildPoi(isHappeningNow: true, refType: 'event');

      expect(PoiContentResolver.badgeLabel(poi), 'Ao vivo');
    });

    test('type label prefers payload category over technical refType', () {
      final poi = _buildPoi(
        refType: 'accountProfile',
        category: CityPoiCategory.attraction,
        categoryLabel: 'beach_club_custom',
      );

      expect(PoiContentResolver.typeLabel(poi), 'Beach Club Custom');
    });

    test('type label stays empty when payload does not provide factual label', () {
      final poi = _buildPoi(
        refType: 'accountProfile',
        category: CityPoiCategory.attraction,
      );

      expect(PoiContentResolver.typeLabel(poi), isEmpty);
    });

    test('compact address hides generic map placeholders', () {
      final poi = _buildPoi(address: 'Mapa');

      expect(PoiContentResolver.compactAddress(poi), isNull);
    });

    test('sanitized description strips html and collapses whitespace', () {
      final poi = _buildPoi(
        description: '<p>Essa é <strong>uma</strong> descrição</p>\n<br/>',
      );

      expect(
        PoiContentResolver.sanitizedDescription(poi),
        'Essa é uma descrição',
      );
    });

    test(
        'search meta falls back to payload-derived category when address is weak',
        () {
      final poi = _buildPoi(
        refType: 'accountProfile',
        category: CityPoiCategory.attraction,
        categoryLabel: 'beach_club_custom',
        address: 'Mapa',
        distanceMeters: null,
      );

      expect(PoiContentResolver.searchMeta(poi), 'Beach Club Custom');
    });

    test('image and icon helpers reuse payload visual contract', () {
      final imagePoi = _buildPoi(
        visual: CityPoiVisual.image(
          imageUriValue: _imageUriValue('https://cdn.example.com/praia.jpg'),
          sourceValue: _sourceValue('backend'),
        ),
      );
      final iconPoi = _buildPoi(
        visual: CityPoiVisual.icon(
          iconValue: _iconValue('local_dining'),
          colorHexValue: _hexValue('#D93A56'),
          iconColorHexValue: _hexValue('#FFFFFF'),
          sourceValue: _sourceValue('backend'),
        ),
      );

      expect(
        PoiContentResolver.coverImageUri(imagePoi),
        'https://cdn.example.com/praia.jpg',
      );
      expect(
        PoiContentResolver.thumbnailImageUri(imagePoi),
        'https://cdn.example.com/praia.jpg',
      );
      expect(PoiContentResolver.assetPath(imagePoi), 'assets/images/poi.png');
      expect(PoiContentResolver.icon(iconPoi), isNotNull);
      expect(PoiContentResolver.accentColor(iconPoi), isNotNull);
      expect(PoiContentResolver.iconColor(iconPoi), isNotNull);
    });
  });
}

CityPoiModel _buildPoi({
  String id = 'poi-1',
  String name = 'Praia das Castanheiras',
  String description = 'Ponto de interesse no mapa',
  String address = 'Av. Oceânica, Centro',
  String refType = 'static',
  String refId = 'poi-1',
  CityPoiCategory category = CityPoiCategory.beach,
  String? categoryLabel,
  double? distanceMeters = 521,
  bool isHappeningNow = false,
  DateTime? updatedAt,
  List<String> tags = const ['Sol', 'Mar'],
  CityPoiVisual? visual,
  String assetPath = 'assets/images/poi.png',
}) {
  final idValue = CityPoiIdValue()..parse(id);
  final nameValue = CityPoiNameValue()..parse(name);
  final descriptionValue = CityPoiDescriptionValue()..parse(description);
  final addressValue = CityPoiAddressValue()..parse(address);
  final priorityValue = PoiPriorityValue()..parse('1');
  final refTypeValue = PoiReferenceTypeValue()..parse(refType);
  final refIdValue = PoiReferenceIdValue()..parse(refId);
  final stackKeyValue = PoiStackKeyValue()..parse('');
  final stackCountValue = PoiStackCountValue()..parse('1');
  final stackItems = CityPoiStackItems();
  final latitude = LatitudeValue()..parse('-20.676');
  final longitude = LongitudeValue()..parse('-40.497');
  final coordinate = CityCoordinate(
    latitudeValue: latitude,
    longitudeValue: longitude,
  );
  final isDynamicValue = PoiBooleanValue()
    ..parse(refType == 'event' ? 'true' : 'false');
  final isHappeningNowValue = PoiBooleanValue()
    ..parse(
      isHappeningNow ? 'true' : 'false',
    );
  final assetPathValue = AssetPathValue()..parse(assetPath);
  final distanceValue = distanceMeters == null
      ? null
      : (DistanceInMetersValue()..parse(distanceMeters.toString()));
  final updatedAtValue = updatedAt == null
      ? null
      : (PoiUpdatedAtValue()..parse(updatedAt.toUtc().toIso8601String()));
  final categoryLabelValue = categoryLabel == null || categoryLabel.trim().isEmpty
      ? null
      : (PoiTypeLabelValue()..parse(categoryLabel.trim()));

  return CityPoiModel(
    idValue: idValue,
    nameValue: nameValue,
    descriptionValue: descriptionValue,
    addressValue: addressValue,
    category: category,
    categoryLabelValue: categoryLabelValue,
    coordinate: coordinate,
    priorityValue: priorityValue,
    assetPathValue: assetPathValue,
    isDynamicValue: isDynamicValue,
    tagValues: tags.map(_tagValue).toList(growable: false),
    refTypeValue: refTypeValue,
    refIdValue: refIdValue,
    stackKeyValue: stackKeyValue,
    stackCountValue: stackCountValue,
    stackItems: stackItems,
    isHappeningNowValue: isHappeningNowValue,
    updatedAtValue: updatedAtValue,
    distanceMetersValue: distanceValue,
    visual: visual,
  );
}

PoiTagValue _tagValue(String value) {
  final tagValue = PoiTagValue();
  tagValue.parse(value);
  return tagValue;
}

PoiFilterImageUriValue _imageUriValue(String value) {
  final imageUriValue = PoiFilterImageUriValue();
  imageUriValue.parse(value);
  return imageUriValue;
}

PoiFilterSourceValue _sourceValue(String value) {
  final sourceValue = PoiFilterSourceValue();
  sourceValue.parse(value);
  return sourceValue;
}

PoiIconSymbolValue _iconValue(String value) {
  final iconValue = PoiIconSymbolValue();
  iconValue.parse(value);
  return iconValue;
}

PoiHexColorValue _hexValue(String value) {
  final hexValue = PoiHexColorValue();
  hexValue.parse(value);
  return hexValue;
}
