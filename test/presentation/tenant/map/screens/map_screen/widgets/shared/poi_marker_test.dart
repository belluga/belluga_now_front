import 'package:belluga_now/domain/map/city_poi_category.dart';
import 'package:belluga_now/domain/map/city_poi_model.dart';
import 'package:belluga_now/domain/map/projections/city_poi_visual.dart';
import 'package:belluga_now/domain/map/value_objects/city_coordinate.dart';
import 'package:belluga_now/domain/map/value_objects/city_poi_address_value.dart';
import 'package:belluga_now/domain/map/value_objects/city_poi_description_value.dart';
import 'package:belluga_now/domain/map/value_objects/city_poi_id_value.dart';
import 'package:belluga_now/domain/map/value_objects/city_poi_name_value.dart';
import 'package:belluga_now/domain/map/value_objects/latitude_value.dart';
import 'package:belluga_now/domain/map/value_objects/longitude_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_filter_image_uri_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_hex_color_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_icon_symbol_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_priority_value.dart';
import 'package:belluga_now/infrastructure/dal/dto/map/city_poi_dto.dart';
import 'package:belluga_now/presentation/tenant_public/map/screens/map_screen/widgets/shared/poi_marker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

CityPoiModel _buildPoi({
  required CityPoiCategory category,
  CityPoiVisual? visual,
}) {
  final idValue = CityPoiIdValue()..parse('poi-1');
  final nameValue = CityPoiNameValue()..parse('POI');
  final descriptionValue = CityPoiDescriptionValue()..parse('Desc');
  final addressValue = CityPoiAddressValue()..parse('Address');
  final priorityValue = PoiPriorityValue()..parse('10');
  final coordinate = CityCoordinate(
    latitudeValue: LatitudeValue()..parse('-20.0'),
    longitudeValue: LongitudeValue()..parse('-40.0'),
  );

  return CityPoiModel(
    idValue: idValue,
    nameValue: nameValue,
    descriptionValue: descriptionValue,
    addressValue: addressValue,
    category: category,
    coordinate: coordinate,
    priorityValue: priorityValue,
    visual: visual,
  );
}

CityPoiModel _buildPoiFromTransportPayload(Map<String, dynamic> payload) {
  return CityPoiDTO.fromJson(payload).toDomain();
}

PoiIconSymbolValue _iconValue(String raw) {
  final value = PoiIconSymbolValue();
  value.parse(raw);
  return value;
}

PoiHexColorValue _hexColorValue(String raw) {
  final value = PoiHexColorValue();
  value.parse(raw);
  return value;
}

PoiFilterImageUriValue _imageUriValue(String raw) {
  final value = PoiFilterImageUriValue();
  value.parse(raw);
  return value;
}

void main() {
  testWidgets('uses poi visual icon instead of category hardcoded icon', (
    tester,
  ) async {
    final poi = _buildPoi(
      category: CityPoiCategory.beach,
      visual: CityPoiVisual.icon(
        iconValue: _iconValue('restaurant'),
        colorHexValue: _hexColorValue('#00AAFF'),
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 56,
              height: 56,
              child: PoiMarker(
                poi: poi,
                isSelected: false,
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.restaurant), findsOneWidget);
    expect(find.byIcon(Icons.beach_access), findsNothing);
  });

  testWidgets('keeps selected marker icon contrast with visual color', (
    tester,
  ) async {
    final poi = _buildPoi(
      category: CityPoiCategory.beach,
      visual: CityPoiVisual.icon(
        iconValue: _iconValue('restaurant'),
        colorHexValue: _hexColorValue('#00AAFF'),
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 56,
              height: 56,
              child: PoiMarker(
                poi: poi,
                isSelected: true,
              ),
            ),
          ),
        ),
      ),
    );

    final iconWidget = tester.widget<Icon>(find.byIcon(Icons.restaurant));
    expect(iconWidget.color, Colors.white);

    final markerContainer =
        tester.widget<DecoratedBox>(find.byType(DecoratedBox).first);
    final decoration = markerContainer.decoration as BoxDecoration;
    expect(
      decoration.color,
      const Color(0xFF00AAFF).withValues(alpha: 0.92),
    );
  });

  testWidgets('uses single generic fallback icon when visual is absent', (
    tester,
  ) async {
    final poi = _buildPoi(
      category: CityPoiCategory.restaurant,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 56,
              height: 56,
              child: PoiMarker(
                poi: poi,
                isSelected: false,
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.place), findsOneWidget);
    expect(find.byIcon(Icons.restaurant), findsNothing);
  });

  testWidgets('renders marker image when poi visual mode is image', (
    tester,
  ) async {
    final poi = _buildPoi(
      category: CityPoiCategory.culture,
      visual: CityPoiVisual.image(
        imageUriValue: _imageUriValue('https://tenant.test/media/poi-1.png'),
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 56,
              height: 56,
              child: PoiMarker(
                poi: poi,
                isSelected: false,
              ),
            ),
          ),
        ),
      ),
    );

    final image = tester.widget<Image>(find.byType(Image).first);
    expect(image.image, isA<NetworkImage>());
  });

  testWidgets(
    'prefers valid override visual over poi visual',
    (tester) async {
      final poi = _buildPoi(
        category: CityPoiCategory.culture,
        visual: CityPoiVisual.icon(
          iconValue: _iconValue('museum'),
          colorHexValue: _hexColorValue('#11AA11'),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 56,
                height: 56,
                child: PoiMarker(
                  poi: poi,
                  isSelected: false,
                  overrideVisual: CityPoiVisual.icon(
                    iconValue: _iconValue('restaurant'),
                    colorHexValue: _hexColorValue('#AA1111'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.restaurant), findsOneWidget);
      expect(find.byIcon(Icons.museum), findsNothing);
    },
  );

  testWidgets(
    'falls back to poi visual when override visual is invalid',
    (tester) async {
      final poi = _buildPoi(
        category: CityPoiCategory.culture,
        visual: CityPoiVisual.icon(
          iconValue: _iconValue('museum'),
          colorHexValue: _hexColorValue('#11AA11'),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 56,
                height: 56,
                child: PoiMarker(
                  poi: poi,
                  isSelected: false,
                  overrideVisual: CityPoiVisual.icon(
                    iconValue: PoiIconSymbolValue(),
                    colorHexValue: _hexColorValue('#AA1111'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.museum), findsOneWidget);
      expect(find.byIcon(Icons.restaurant), findsNothing);
    },
  );

  testWidgets(
    'renders icon from transport payload without falling back to generic marker',
    (tester) async {
      final poi = _buildPoiFromTransportPayload({
        'id': 'poi-transport-1',
        'name': 'Restaurante',
        'description': 'Descricao',
        'address': 'Endereco',
        'category': 'restaurant',
        'location': {
          'lat': -20.0,
          'lng': -40.0,
        },
        'visual': {
          'mode': {'value': 'icon'},
          'icon': {'value': 'restaurant'},
          'color': {'value': '#EB2528'},
          'source': {'value': 'type_definition'},
        },
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 56,
                height: 56,
                child: PoiMarker(
                  poi: poi,
                  isSelected: false,
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.restaurant), findsOneWidget);
      expect(find.byIcon(Icons.place), findsNothing);
    },
  );

  testWidgets(
    'uses transport icon_color for icon glyph when provided',
    (tester) async {
      final poi = _buildPoiFromTransportPayload({
        'id': 'poi-transport-2',
        'name': 'Restaurante',
        'description': 'Descricao',
        'address': 'Endereco',
        'category': 'restaurant',
        'location': {
          'lat': -20.0,
          'lng': -40.0,
        },
        'visual': {
          'mode': {'value': 'icon'},
          'icon': {'value': 'restaurant'},
          'color': {'value': '#111111'},
          'icon_color': {'value': '#EB2528'},
          'source': {'value': 'type_definition'},
        },
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 56,
                height: 56,
                child: PoiMarker(
                  poi: poi,
                  isSelected: false,
                ),
              ),
            ),
          ),
        ),
      );

      final iconWidget = tester.widget<Icon>(find.byIcon(Icons.restaurant));
      expect(iconWidget.color, const Color(0xFFEB2528));
    },
  );

  testWidgets(
    'renders marker visual from legacy payload without explicit mode',
    (tester) async {
      final poi = _buildPoiFromTransportPayload({
        'id': 'poi-transport-legacy',
        'name': 'Restaurante',
        'description': 'Descricao',
        'address': 'Endereco',
        'category': 'restaurant',
        'location': {
          'lat': -20.0,
          'lng': -40.0,
        },
        'poi_visual': {
          'icon': 'restaurant',
          'color': 'eb2528',
          'icon_color': '101010',
          'source': 'type_definition',
        },
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 56,
                height: 56,
                child: PoiMarker(
                  poi: poi,
                  isSelected: false,
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.restaurant), findsOneWidget);
      expect(find.byIcon(Icons.place), findsNothing);

      final markerContainer =
          tester.widget<DecoratedBox>(find.byType(DecoratedBox).first);
      final decoration = markerContainer.decoration as BoxDecoration;
      expect(
        decoration.color,
        const Color(0xFFEB2528).withValues(alpha: 0.92),
      );
    },
  );
}
