import 'package:belluga_now/domain/map/city_poi_category.dart';
import 'package:belluga_now/domain/repositories/auth_repository_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/backend_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/backend_context.dart';
import 'package:belluga_now/domain/map/queries/poi_query.dart';
import 'package:belluga_now/infrastructure/dal/dto/map/city_poi_dto.dart';
import 'package:belluga_now/infrastructure/dal/dto/map/map_filters_dto.dart';
import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';

class LaravelMapPoiHttpService {
  LaravelMapPoiHttpService({
    BackendContext? context,
    Dio? dio,
  }) : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: _resolveBaseUrl(context),
                connectTimeout: const Duration(seconds: 2),
                receiveTimeout: const Duration(seconds: 4),
                sendTimeout: const Duration(seconds: 4),
              ),
            );

  final Dio _dio;

  static String _resolveBaseUrl(BackendContext? context) {
    final resolved = context ??
        (GetIt.I.isRegistered<BackendContract>()
            ? GetIt.I.get<BackendContract>().context
            : null);
    if (resolved == null) {
      throw StateError(
        'BackendContext is not available via BackendContract for LaravelMapPoiHttpService.',
      );
    }
    return resolved.baseUrl;
  }

  Future<List<CityPoiDTO>> getPois(
    PoiQuery query, {
    String? stackKey,
  }) async {
    final params = _buildQueryParams(
      query,
      stackKey: stackKey,
    );

    final response = await _dio.get(
      '/v1/map/pois',
      queryParameters: params,
      options: Options(headers: _buildHeaders()),
    );

    final raw = response.data;
    if (raw is! Map<String, dynamic>) {
      throw Exception('Unexpected /v1/map/pois response envelope');
    }

    final stacks = raw['stacks'];
    if (stacks is! List) {
      throw Exception('Unexpected /v1/map/pois stacks payload');
    }

    final shouldExpandItems = (stackKey ?? '').trim().isNotEmpty;
    return stacks
        .whereType<Map<String, dynamic>>()
        .map(
          (stack) => CityPoiDTO.fromStackedApiJson(
            stack,
            includeItems: shouldExpandItems,
          ),
        )
        .toList(growable: false);
  }

  Future<MapFiltersDTO> getFilters(PoiQuery query) async {
    final response = await _dio.get(
      '/v1/map/filters',
      queryParameters: _buildQueryParams(query),
      options: Options(headers: _buildHeaders()),
    );

    final raw = response.data;
    if (raw is! Map<String, dynamic>) {
      throw Exception('Unexpected /v1/map/filters response envelope');
    }
    return MapFiltersDTO.fromJson(raw);
  }

  Map<String, dynamic> _buildQueryParams(
    PoiQuery query, {
    String? stackKey,
  }) {
    final params = <String, dynamic>{};

    if (query.hasBounds) {
      params['ne_lat'] = query.northEast!.latitude;
      params['ne_lng'] = query.northEast!.longitude;
      params['sw_lat'] = query.southWest!.latitude;
      params['sw_lng'] = query.southWest!.longitude;
    }

    final origin = query.origin;
    if (origin != null) {
      params['origin_lat'] = origin.latitude;
      params['origin_lng'] = origin.longitude;
    } else if (query.hasBounds) {
      params['origin_lat'] =
          (query.northEast!.latitude + query.southWest!.latitude) / 2;
      params['origin_lng'] =
          (query.northEast!.longitude + query.southWest!.longitude) / 2;
    }

    if (query.maxDistanceMeters != null && query.maxDistanceMeters! > 0) {
      params['max_distance_meters'] = query.maxDistanceMeters;
    }

    final categoryKeys = query.categoryKeys;
    if (categoryKeys != null && categoryKeys.isNotEmpty) {
      params['categories'] = categoryKeys.toList(growable: false);
    } else {
      final categories = query.categories;
      if (categories != null && categories.isNotEmpty) {
        final categoryTokens = categories
            .map(_mapCategoryToken)
            .whereType<String>()
            .toSet()
            .toList(growable: false);
        if (categoryTokens.isNotEmpty) {
          params['categories'] = categoryTokens;
        }
      }
    }

    final source = query.source?.trim();
    if (source != null && source.isNotEmpty) {
      params['source'] = source;
    }

    final types = query.types;
    if (types != null && types.isNotEmpty) {
      params['types'] = types.toList(growable: false);
    }

    final tags = query.tags;
    if (tags != null && tags.isNotEmpty) {
      params['tags'] = tags.toList(growable: false);
    }

    final taxonomy = query.taxonomy;
    if (taxonomy != null && taxonomy.isNotEmpty) {
      params['taxonomy'] = taxonomy.toList(growable: false);
    }

    final search = query.searchTerm;
    if (search != null && search.trim().isNotEmpty) {
      params['search'] = search.trim();
    }

    final normalizedStackKey = stackKey?.trim();
    if (normalizedStackKey != null && normalizedStackKey.isNotEmpty) {
      params['stack_key'] = normalizedStackKey;
    }

    return params;
  }

  String? _mapCategoryToken(CityPoiCategory category) {
    switch (category) {
      case CityPoiCategory.restaurant:
        return 'restaurant';
      case CityPoiCategory.beach:
        return 'beach';
      case CityPoiCategory.nature:
        return 'nature';
      case CityPoiCategory.culture:
        return 'culture';
      case CityPoiCategory.monument:
      case CityPoiCategory.church:
        return 'historic';
      case CityPoiCategory.health:
      case CityPoiCategory.lodging:
      case CityPoiCategory.attraction:
      case CityPoiCategory.sponsor:
        return null;
    }
  }

  Map<String, String> _buildHeaders() {
    final headers = <String, String>{
      'Accept': 'application/json',
    };
    if (GetIt.I.isRegistered<AuthRepositoryContract>()) {
      final token = GetIt.I.get<AuthRepositoryContract>().userToken.trim();
      if (token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }
}
