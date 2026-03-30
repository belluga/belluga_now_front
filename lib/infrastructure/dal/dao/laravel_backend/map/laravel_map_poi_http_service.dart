import 'package:belluga_now/domain/map/queries/poi_query.dart';
import 'package:belluga_now/infrastructure/dal/dao/backend_context.dart';
import 'package:belluga_now/infrastructure/dal/dao/backend_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/laravel_backend/shared/tenant_public_auth_headers.dart';
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
                listFormat: ListFormat.multiCompatible,
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
      options: Options(
        headers: await _buildHeaders(),
        listFormat: ListFormat.multiCompatible,
      ),
    );

    final raw = response.data;
    final payload = _normalizeMap(raw);
    if (payload == null) {
      throw Exception('Unexpected /v1/map/pois response envelope');
    }

    final stacks = payload['stacks'];
    if (stacks is! List) {
      throw Exception('Unexpected /v1/map/pois stacks payload');
    }

    final shouldExpandItems = (stackKey ?? '').trim().isNotEmpty;
    return stacks
        .map(_normalizeMap)
        .whereType<Map<String, dynamic>>()
        .map(
          (stack) => CityPoiDTO.fromStackedApiJson(
            stack,
            includeItems: shouldExpandItems,
          ),
        )
        .toList(growable: false);
  }

  Future<CityPoiDTO?> lookupPoiByReference({
    required String refType,
    required String refId,
  }) async {
    final normalizedRefType = refType.trim().toLowerCase();
    final normalizedRefId = refId.trim();
    if (normalizedRefType.isEmpty || normalizedRefId.isEmpty) {
      return null;
    }

    try {
      final response = await _dio.get(
        '/v1/map/pois/lookup',
        queryParameters: <String, dynamic>{
          'ref_type': normalizedRefType,
          'ref_id': normalizedRefId,
        },
        options: Options(
          headers: await _buildHeaders(),
          listFormat: ListFormat.multiCompatible,
        ),
      );

      final raw = response.data;
      final payload = _normalizeMap(raw);
      if (payload == null) {
        throw Exception('Unexpected /v1/map/pois/lookup response envelope');
      }

      final poiPayload = _normalizeMap(payload['poi']);
      if (poiPayload != null) {
        return CityPoiDTO.fromJson(poiPayload);
      }

      return CityPoiDTO.fromJson(payload);
    } on DioException catch (error) {
      if (error.response?.statusCode == 404) {
        return null;
      }
      rethrow;
    }
  }

  Future<MapFiltersDTO> getFilters(PoiQuery query) async {
    final response = await _dio.get(
      '/v1/map/filters',
      queryParameters: _buildQueryParams(query),
      options: Options(
        headers: await _buildHeaders(),
        listFormat: ListFormat.multiCompatible,
      ),
    );

    final raw = response.data;
    final payload = _normalizeMap(raw);
    if (payload == null) {
      throw Exception('Unexpected /v1/map/filters response envelope');
    }
    return MapFiltersDTO.fromJson(payload);
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

    final maxDistanceMeters = query.maxDistanceMetersValue?.value;
    if (maxDistanceMeters != null && maxDistanceMeters > 0) {
      params['max_distance_meters'] = maxDistanceMeters;
    }

    final categoryKeys = query.categoryKeyValues
        ?.map((value) => value.value.trim())
        .where((value) => value.isNotEmpty)
        .toSet();
    if (categoryKeys != null && categoryKeys.isNotEmpty) {
      params['categories'] = categoryKeys.toList(growable: false);
    }

    final source = query.sourceValue?.value.trim();
    if (source != null && source.isNotEmpty) {
      params['source'] = source;
    }

    final types = query.typeValues
        ?.map((value) => value.value.trim())
        .where((value) => value.isNotEmpty)
        .toSet();
    if (types != null && types.isNotEmpty) {
      params['types'] = types.toList(growable: false);
    }

    final tags = query.tagValues
        ?.map((value) => value.value.trim())
        .where((value) => value.isNotEmpty)
        .toSet();
    if (tags != null && tags.isNotEmpty) {
      params['tags'] = tags.toList(growable: false);
    }

    final taxonomy = query.taxonomyTokenValues
        ?.map((value) => value.value.trim())
        .where((value) => value.isNotEmpty)
        .toSet();
    if (taxonomy != null && taxonomy.isNotEmpty) {
      params['taxonomy'] = taxonomy.toList(growable: false);
    }

    final search = query.searchTermValue?.value;
    if (search != null && search.trim().isNotEmpty) {
      params['search'] = search.trim();
    }

    final normalizedStackKey = stackKey?.trim();
    if (normalizedStackKey != null && normalizedStackKey.isNotEmpty) {
      params['stack_key'] = normalizedStackKey;
    }

    return params;
  }

  Future<Map<String, String>> _buildHeaders() {
    return TenantPublicAuthHeaders.build(
      includeJsonAccept: true,
      bootstrapIfEmpty: true,
    );
  }

  Map<String, dynamic>? _normalizeMap(Object? raw) {
    if (raw is! Map) {
      return null;
    }

    return raw.map(
      (key, value) => MapEntry(key.toString(), value),
    );
  }
}
