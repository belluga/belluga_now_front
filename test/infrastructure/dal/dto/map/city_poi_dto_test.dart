import 'package:belluga_now/domain/map/projections/city_poi_visual.dart';
import 'package:belluga_now/infrastructure/dal/dto/map/city_poi_dto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CityPoiDTO visual snapshot', () {
    test('parses icon visual snapshot into domain model', () {
      final dto = CityPoiDTO.fromJson({
        'id': 'poi-1',
        'name': 'Restaurant',
        'description': 'Great food',
        'address': 'Main avenue',
        'category': 'restaurant',
        'location': {
          'lat': -20.0,
          'lng': -40.0,
        },
        'visual': {
          'mode': 'icon',
          'icon': 'restaurant',
          'color': '#00AAFF',
          'source': 'type_definition',
        },
      });

      final model = dto.toDomain();

      expect(model.visual, isNotNull);
      expect(model.visual?.mode, CityPoiVisualMode.icon);
      expect(model.visual?.icon, 'restaurant');
      expect(model.visual?.colorHex, '#00AAFF');
      expect(model.visual?.iconColorHex, '#FFFFFF');
      expect(model.visual?.source, 'type_definition');
    });

    test('parses image visual snapshot into domain model', () {
      final dto = CityPoiDTO.fromJson({
        'id': 'poi-1',
        'name': 'Museum',
        'description': 'Culture',
        'address': 'Square',
        'category': 'culture',
        'location': {
          'lat': -20.0,
          'lng': -40.0,
        },
        'visual': {
          'mode': 'image',
          'image_uri': 'https://tenant.test/media/poi-1.png',
          'source': 'item_media',
        },
      });

      final model = dto.toDomain();

      expect(model.visual, isNotNull);
      expect(model.visual?.mode, CityPoiVisualMode.image);
      expect(model.visual?.imageUri, 'https://tenant.test/media/poi-1.png');
      expect(model.visual?.source, 'item_media');
    });

    test('ignores malformed visual snapshot', () {
      final dto = CityPoiDTO.fromJson({
        'id': 'poi-1',
        'name': 'Beach',
        'description': 'Sun',
        'address': 'Coast',
        'category': 'beach',
        'location': {
          'lat': -20.0,
          'lng': -40.0,
        },
        'visual': {
          'mode': 'icon',
          'icon': 'beach',
          'color': 'blue',
        },
      });

      final model = dto.toDomain();

      expect(model.visual, isNull);
    });

    test('parses wrapped icon visual values from transport payload', () {
      final dto = CityPoiDTO.fromJson({
        'id': 'poi-1',
        'name': 'Restaurant',
        'description': 'Great food',
        'address': 'Main avenue',
        'category': 'restaurant',
        'location': {
          'lat': -20.0,
          'lng': -40.0,
        },
        'visual': {
          'mode': {'value': 'icon'},
          'icon': {'value': 'restaurant'},
          'color': {'value': '#eb2528'},
          'source': {'value': 'type_definition'},
        },
      });

      final model = dto.toDomain();

      expect(model.visual, isNotNull);
      expect(model.visual?.mode, CityPoiVisualMode.icon);
      expect(model.visual?.icon, 'restaurant');
      expect(model.visual?.colorHex, '#EB2528');
      expect(model.visual?.iconColorHex, '#FFFFFF');
      expect(model.visual?.source, 'type_definition');
    });

    test('parses explicit icon_color from transport payload', () {
      final dto = CityPoiDTO.fromJson({
        'id': 'poi-1',
        'name': 'Restaurant',
        'description': 'Great food',
        'address': 'Main avenue',
        'category': 'restaurant',
        'location': {
          'lat': -20.0,
          'lng': -40.0,
        },
        'visual': {
          'mode': {'value': 'icon'},
          'icon': {'value': 'restaurant'},
          'color': {'value': '#eb2528'},
          'icon_color': {'value': '#112233'},
          'source': {'value': 'type_definition'},
        },
      });

      final model = dto.toDomain();

      expect(model.visual, isNotNull);
      expect(model.visual?.mode, CityPoiVisualMode.icon);
      expect(model.visual?.icon, 'restaurant');
      expect(model.visual?.colorHex, '#EB2528');
      expect(model.visual?.iconColorHex, '#112233');
      expect(model.visual?.source, 'type_definition');
    });

    test('parses wrapped image visual values from transport payload', () {
      final dto = CityPoiDTO.fromJson({
        'id': 'poi-1',
        'name': 'Museum',
        'description': 'Culture',
        'address': 'Square',
        'category': 'culture',
        'location': {
          'lat': -20.0,
          'lng': -40.0,
        },
        'visual': {
          'mode': {'value': 'image'},
          'image_uri': {'value': 'https://tenant.test/media/poi-1.png'},
          'source': {'value': 'item_media'},
        },
      });

      final model = dto.toDomain();

      expect(model.visual, isNotNull);
      expect(model.visual?.mode, CityPoiVisualMode.image);
      expect(model.visual?.imageUri, 'https://tenant.test/media/poi-1.png');
      expect(model.visual?.source, 'item_media');
    });

    test('parses legacy icon visual payload without explicit mode', () {
      final dto = CityPoiDTO.fromJson({
        'id': 'poi-legacy-1',
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

      final model = dto.toDomain();

      expect(model.visual, isNotNull);
      expect(model.visual?.mode, CityPoiVisualMode.icon);
      expect(model.visual?.icon, 'restaurant');
      expect(model.visual?.colorHex, '#EB2528');
      expect(model.visual?.iconColorHex, '#101010');
      expect(model.visual?.source, 'type_definition');
    });

    test('parses icon visual payload when color arrives with alpha suffix', () {
      final dto = CityPoiDTO.fromJson({
        'id': 'poi-legacy-2',
        'name': 'Restaurante',
        'description': 'Descricao',
        'address': 'Endereco',
        'category': 'restaurant',
        'location': {
          'lat': -20.0,
          'lng': -40.0,
        },
        'visual': {
          'mode': 'icon',
          'icon': 'restaurant',
          'color': '#EB2528FF',
          'icon_color': '#FFFFFFFF',
          'source': 'type_definition',
        },
      });

      final model = dto.toDomain();

      expect(model.visual, isNotNull);
      expect(model.visual?.mode, CityPoiVisualMode.icon);
      expect(model.visual?.icon, 'restaurant');
      expect(model.visual?.colorHex, '#EB2528');
      expect(model.visual?.iconColorHex, '#FFFFFF');
      expect(model.visual?.source, 'type_definition');
    });

    test('parses event timing snapshot into domain model', () {
      final dto = CityPoiDTO.fromJson({
        'id': 'poi-event-1',
        'name': 'Evento Longo',
        'description': 'Descricao',
        'address': 'Carvoeiro',
        'category': 'event',
        'ref_type': 'event',
        'location': {
          'lat': -20.0,
          'lng': -40.0,
        },
        'is_happening_now': true,
        'time_start': '2026-04-07T10:00:00Z',
        'time_end': '2026-04-07T22:00:00Z',
      });

      final model = dto.toDomain();

      expect(model.isHappeningNow, isTrue);
      expect(model.timeStart?.toUtc().toIso8601String(),
          '2026-04-07T10:00:00.000Z');
      expect(
          model.timeEnd?.toUtc().toIso8601String(), '2026-04-07T22:00:00.000Z');
    });
  });
}
