import 'package:belluga_now/domain/map/value_objects/city_coordinate.dart';
import 'package:stream_value/main.dart';

class MockWebSocketService {
  MockWebSocketService({Duration latency = Duration.zero})
      : _latency = latency,
        _events = StreamValue<Map<String, dynamic>>();

  final Duration _latency;
  final StreamValue<Map<String, dynamic>> _events;

  Future<void> triggerPoiMovedEvent(
    String poiId,
    CityCoordinate newCoords,
  ) async {
    await Future<void>.delayed(_latency);
    _events.addValue({
      'event': 'poi:moved',
      'payload': {
        'poiId': poiId,
        'coordinates': {
          'latitude': newCoords.latitude,
          'longitude': newCoords.longitude,
        },
      },
    });
  }

  Future<void> triggerOfferActivatedEvent(
    String poiId,
    String offerDetails,
    String offerIcon,
  ) async {
    await Future<void>.delayed(_latency);
    _events.addValue({
      'event': 'poi:offer_activated',
      'payload': {
        'poiId': poiId,
        'details': offerDetails,
        'icon': offerIcon,
      },
    });
  }

  void dispose() => _events.dispose();
}
