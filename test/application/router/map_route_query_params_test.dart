import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Map routes query params', () {
    test('city map route encodes poi and stack query params', () {
      final route = CityMapRoute(
        poi: 'event:evt-001',
        stack: 'stack-abc',
      );

      expect(route.rawQueryParams, {
        'poi': 'event:evt-001',
        'stack': 'stack-abc',
      });
      _expectResolvedQueryParams(route.rawQueryParams);
    });

    test('poi details alias route encodes poi and stack query params', () {
      final route = PoiDetailsRoute(
        poi: 'event:evt-002',
        stack: 'stack-def',
      );

      expect(route.rawQueryParams, {
        'poi': 'event:evt-002',
        'stack': 'stack-def',
      });
      _expectResolvedQueryParams(route.rawQueryParams);
    });
  });
}

void _expectResolvedQueryParams(Map<String, dynamic> rawQueryParams) {
  for (final value in rawQueryParams.values) {
    expect(value, isNotNull);
    final text = value.toString();
    expect(text.trim(), isNotEmpty);
  }
}
