import 'dart:async';

import 'package:belluga_now/domain/map/city_poi_model.dart';
import 'package:belluga_now/domain/map/events/poi_update_event.dart';
import 'package:belluga_now/domain/map/filters/main_filter_option.dart';
import 'package:belluga_now/domain/map/filters/poi_filter_options.dart';
import 'package:belluga_now/domain/map/map_region_definition.dart';
import 'package:belluga_now/domain/map/value_objects/city_coordinate.dart';
import 'package:belluga_now/domain/repositories/city_map_repository_contract.dart';
import 'package:belluga_now/infrastructure/services/dal/datasources/mock_poi_database.dart';
import 'package:belluga_now/infrastructure/services/dal/datasources/poi_query.dart';
import 'package:belluga_now/infrastructure/services/dal/dto/map/city_poi_dto.dart';
import 'package:belluga_now/infrastructure/services/http/mock_http_service.dart';
import 'package:belluga_now/infrastructure/services/networking/mock_web_socket_service.dart';
import 'package:stream_value/core/stream_value.dart';

class CityMapRepository extends CityMapRepositoryContract {
  CityMapRepository({
    MockPoiDatabase? database,
    MockHttpService? httpService,
    MockWebSocketService? webSocketService,
  })  : _httpService = httpService ??
            MockHttpService(database: database ?? MockPoiDatabase()),
        _ownsWebSocketService = webSocketService == null,
        _webSocketService = webSocketService ?? MockWebSocketService(),
        _poiEvents = StreamValue<PoiUpdateEvent?>() {
    _webSocketSubscription =
        _webSocketService.eventsStreamValue.stream.listen(_handleSocketEvent);
  }

  final bool _ownsWebSocketService;
  final MockHttpService _httpService;
  final MockWebSocketService _webSocketService;
  late final StreamSubscription<Map<String, dynamic>?> _webSocketSubscription;
  final StreamValue<PoiUpdateEvent?> _poiEvents;

  @override
  Future<List<CityPoiModel>> fetchPoints(PoiQuery query) async {
    final List<CityPoiDTO> dtos = await _httpService.getPois(query);
    return dtos.map(CityPoiModel.fromDTO).toList(growable: false);
  }

  @override
  Future<PoiFilterOptions> fetchFilters() => _httpService.getFilters();

  @override
  Future<List<MainFilterOption>> fetchMainFilters() =>
      _httpService.getMainFilters();

  @override
  Future<List<MapRegionDefinition>> fetchRegions() => _httpService.getRegions();

  @override
  Future<String> fetchFallbackEventImage() =>
      _httpService.getFallbackEventImage();

  @override
  Stream<PoiUpdateEvent?> get poiEvents => _poiEvents.stream;

  @override
  CityCoordinate defaultCenter() => const CityCoordinate(
        latitude: -20.673067,
        longitude: -40.498383,
      );

  void _handleSocketEvent(Map<String, dynamic>? event) {
    if (event == null || event['event'] == null || event['payload'] == null) {
      return;
    }

    final eventName = event['event'] as String;
    final payload = event['payload'] as Map<String, dynamic>;

    switch (eventName) {
      case 'poi:moved':
        final poiId = payload['poiId'] as String?;
        final coords = payload['coordinates'];
        if (poiId == null || coords is! Map<String, dynamic>) {
          return;
        }
        final lat = (coords['latitude'] as num?)?.toDouble();
        final lon = (coords['longitude'] as num?)?.toDouble();
        if (lat == null || lon == null) {
          return;
        }
        _poiEvents.addValue(
          PoiMovedEvent(
            poiId: poiId,
            coordinate: CityCoordinate(
              latitude: lat,
              longitude: lon,
            ),
          ),
        );
        break;
      case 'poi:offer_activated':
        final poiId = payload['poiId'] as String?;
        final details = payload['details'] as String?;
        final icon = payload['icon'] as String?;
        if (poiId == null || details == null || icon == null) {
          return;
        }
        _poiEvents.addValue(
          PoiOfferActivatedEvent(
            poiId: poiId,
            details: details,
            icon: icon,
          ),
        );
        break;
      default:
        break;
    }
  }

  @override
  void dispose() {
    _webSocketSubscription.cancel();
    _poiEvents.dispose();
    if (_ownsWebSocketService) {
      _webSocketService.dispose();
    }
  }
}
