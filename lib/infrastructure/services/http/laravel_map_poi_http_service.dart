import 'package:belluga_now/application/configurations/belluga_constants.dart';
import 'package:belluga_now/infrastructure/dal/datasources/poi_query.dart';
import 'package:belluga_now/infrastructure/dal/dto/map/city_poi_dto.dart';
import 'package:dio/dio.dart';

class LaravelMapPoiHttpService {
  LaravelMapPoiHttpService({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: 'https://localhost',
                connectTimeout: const Duration(seconds: 2),
                receiveTimeout: const Duration(seconds: 4),
                sendTimeout: const Duration(seconds: 4),
              ),
            );

  final Dio _dio;

  Future<List<CityPoiDTO>> getPois(PoiQuery query) async {
    final baseUrl = BellugaConstants.api.baseUrl;
    final url = baseUrl.endsWith('/')
        ? '${baseUrl}v1/app/map/pois'
        : '$baseUrl/v1/app/map/pois';

    final params = <String, dynamic>{};

    if (query.hasBounds) {
      params['ne_lat'] = query.northEast!.latitude;
      params['ne_lng'] = query.northEast!.longitude;
      params['sw_lat'] = query.southWest!.latitude;
      params['sw_lng'] = query.southWest!.longitude;

      params['origin_lat'] =
          (query.northEast!.latitude + query.southWest!.latitude) / 2;
      params['origin_lng'] =
          (query.northEast!.longitude + query.southWest!.longitude) / 2;
    }

    final categories = query.categories;
    if (categories != null && categories.isNotEmpty) {
      params['categories'] = categories.map((c) => c.name).toList();
    }

    final tags = query.tags;
    if (tags != null && tags.isNotEmpty) {
      params['tags'] = tags.toList();
    }

    final search = query.searchTerm;
    if (search != null && search.trim().isNotEmpty) {
      params['search'] = search.trim();
    }

    final response = await _dio.get(url, queryParameters: params);

    final raw = response.data;
    final dynamic list = raw is Map<String, dynamic> ? raw['data'] : raw;

    if (list is! List) {
      throw Exception('Unexpected /v1/app/map/pois response shape');
    }

    return list
        .whereType<Map<String, dynamic>>()
        .map(CityPoiDTO.fromJson)
        .toList(growable: false);
  }
}
