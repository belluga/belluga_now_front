import 'package:belluga_now/infrastructure/dal/dto/map/map_filter_category_dto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MapFilterCategoryDTO marker override', () {
    test('parses valid icon marker override payload', () {
      final dto = MapFilterCategoryDTO.fromJson({
        'key': 'events',
        'label': 'Eventos',
        'count': 10,
        'override_marker': true,
        'marker_override': {
          'mode': 'icon',
          'icon': 'event',
          'color': '#00AAFF',
        },
      });

      expect(dto.overrideMarker, isTrue);
      expect(dto.markerOverride, isNotNull);
      expect(dto.markerOverride?.mode, 'icon');
      expect(dto.markerOverride?.icon, 'event');
      expect(dto.markerOverride?.color, '#00AAFF');
      expect(dto.markerOverride?.iconColor, '#FFFFFF');
    });

    test('parses icon_color in marker override payload', () {
      final dto = MapFilterCategoryDTO.fromJson({
        'key': 'events',
        'label': 'Eventos',
        'count': 10,
        'override_marker': true,
        'marker_override': {
          'mode': 'icon',
          'icon': 'event',
          'color': '#00AAFF',
          'icon_color': '#101010',
        },
      });

      expect(dto.overrideMarker, isTrue);
      expect(dto.markerOverride, isNotNull);
      expect(dto.markerOverride?.mode, 'icon');
      expect(dto.markerOverride?.icon, 'event');
      expect(dto.markerOverride?.color, '#00AAFF');
      expect(dto.markerOverride?.iconColor, '#101010');
    });

    test('drops invalid marker override payload', () {
      final dto = MapFilterCategoryDTO.fromJson({
        'key': 'events',
        'label': 'Eventos',
        'count': 10,
        'override_marker': true,
        'marker_override': {
          'mode': 'icon',
          'icon': 'event',
          'color': 'blue',
        },
      });

      expect(dto.overrideMarker, isTrue);
      expect(dto.markerOverride, isNull);
    });
  });
}
