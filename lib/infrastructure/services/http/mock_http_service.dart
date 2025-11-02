import 'dart:async';

import 'package:belluga_now/domain/map/filters/main_filter_option.dart';
import 'package:belluga_now/domain/map/filters/poi_filter_options.dart';
import 'package:belluga_now/infrastructure/services/dal/datasources/mock_poi_database.dart';
import 'package:belluga_now/infrastructure/services/dal/datasources/poi_query.dart';
import 'package:belluga_now/infrastructure/services/dal/dto/map/city_poi_dto.dart';

class MockHttpService {
  MockHttpService({
    required MockPoiDatabase database,
    Duration latency = const Duration(milliseconds: 350),
  })  : _database = database,
        _latency = latency;

  final MockPoiDatabase _database;
  final Duration _latency;

  Future<List<CityPoiDTO>> getPois(PoiQuery query) async {
    await Future<void>.delayed(_latency);
    return _database.findPois(query: query);
  }

  Future<PoiFilterOptions> getFilters() async {
    await Future<void>.delayed(_latency);
    return _database.availableFilters();
  }

  Future<List<MainFilterOption>> getMainFilters() async {
    await Future<void>.delayed(_latency);
    return _database.availableMainFilters();
  }
}
