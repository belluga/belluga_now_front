import 'dart:convert';

import 'package:belluga_now/domain/app_data/app_data.dart';
import 'package:belluga_now/infrastructure/dal/dao/laravel_backend/shared/tenant_public_auth_headers.dart';
import 'package:belluga_now/infrastructure/dal/dto/schedule/event_delta_dto.dart';
import 'package:belluga_now/infrastructure/dal/dto/schedule/event_dto.dart';
import 'package:belluga_now/infrastructure/dal/dto/schedule/event_page_dto.dart';
import 'package:belluga_now/infrastructure/services/schedule_backend_contract.dart';
import 'package:belluga_now/infrastructure/services/sse/sse_client.dart';
import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';

class LaravelScheduleBackend implements ScheduleBackendContract {
  LaravelScheduleBackend({Dio? dio, SseClient? sseClient})
      : _dio = dio ?? Dio(),
        _sseClient = sseClient ?? createSseClient();

  final Dio _dio;
  final SseClient _sseClient;

  String get _apiBaseUrl =>
      '${GetIt.I.get<AppData>().mainDomainValue.value.origin}/api';
  Future<Map<String, String>> _buildHeaders({
    bool includeJsonAccept = false,
  }) async {
    return TenantPublicAuthHeaders.build(
      includeJsonAccept: includeJsonAccept,
      bootstrapIfEmpty: true,
    );
  }

  Map<String, String> _buildStreamHeaders({bool includeJsonAccept = false}) {
    return TenantPublicAuthHeaders.buildSync(
      includeJsonAccept: includeJsonAccept,
    );
  }

  @override
  Future<EventDTO?> fetchEventDetail({required String eventIdOrSlug}) async {
    try {
      final headers = await _buildHeaders(includeJsonAccept: true);
      final response = await _dio.get(
        '$_apiBaseUrl/v1/events/$eventIdOrSlug',
        options: Options(headers: headers),
      );
      final raw = response.data;
      final Map<String, dynamic> json;
      if (raw is Map<String, dynamic>) {
        final data = raw['data'];
        json = data is Map<String, dynamic> ? data : raw;
      } else {
        throw Exception('Unexpected event detail response shape.');
      }
      return EventDTO.fromJson(json);
    } on DioException catch (error) {
      final statusCode = error.response?.statusCode;
      if (statusCode == 404) {
        return null;
      }
      final data = error.response?.data;
      throw Exception(
        'Failed to load event detail '
        '[status=$statusCode] '
        '(${error.requestOptions.uri}): '
        '${data ?? error.message}',
      );
    }
  }

  @override
  Future<EventPageDTO> fetchEventsPage({
    required int page,
    required int pageSize,
    required bool showPastOnly,
    bool liveNowOnly = false,
    String? searchQuery,
    List<String>? categories,
    List<String>? tags,
    List<Map<String, String>>? taxonomy,
    bool confirmedOnly = false,
    double? originLat,
    double? originLng,
    double? maxDistanceMeters,
  }) async {
    final params = <String, dynamic>{
      'page': page,
      'page_size': pageSize,
      'confirmed_only': confirmedOnly ? 1 : 0,
    };
    if (liveNowOnly) {
      params['live_now_only'] = 1;
    } else {
      params['past_only'] = showPastOnly ? 1 : 0;
    }

    final normalizedSearchQuery = searchQuery?.trim();
    final hasSearchQuery =
        normalizedSearchQuery != null && normalizedSearchQuery.isNotEmpty;
    if (hasSearchQuery) {
      params['search'] = normalizedSearchQuery;
    }
    if (categories != null && categories.isNotEmpty) {
      params['categories'] = categories;
    }
    if (tags != null && tags.isNotEmpty) {
      params['tags'] = tags;
    }
    if (taxonomy != null && taxonomy.isNotEmpty) {
      params['taxonomy'] = taxonomy;
    }
    if (!hasSearchQuery && originLat != null && originLng != null) {
      params['origin_lat'] = originLat;
      params['origin_lng'] = originLng;
      if (maxDistanceMeters != null) {
        params['max_distance_meters'] = maxDistanceMeters;
      }
    }

    try {
      final headers = await _buildHeaders(includeJsonAccept: true);
      final response = await _dio.get(
        '$_apiBaseUrl/v1/agenda',
        queryParameters: params,
        options: Options(headers: headers),
      );
      final raw = response.data;
      final Map<String, dynamic> json;
      if (raw is Map<String, dynamic>) {
        final data = raw['data'];
        json = data is Map<String, dynamic> ? data : raw;
      } else {
        throw Exception('Unexpected agenda response shape.');
      }
      return EventPageDTO.fromJson(json);
    } on DioException catch (error) {
      final statusCode = error.response?.statusCode;
      final data = error.response?.data;
      throw Exception(
        'Failed to load agenda '
        '[status=$statusCode] '
        '(${error.requestOptions.uri}): '
        '${data ?? error.message}',
      );
    }
  }

  @override
  Stream<EventDeltaDTO> watchEventsStream({
    String? searchQuery,
    List<String>? categories,
    List<String>? tags,
    List<Map<String, String>>? taxonomy,
    bool confirmedOnly = false,
    double? originLat,
    double? originLng,
    double? maxDistanceMeters,
    String? lastEventId,
    bool showPastOnly = false,
  }) {
    final queryParts = <String>[];
    void addParam(String key, String value) {
      queryParts.add(
        '${Uri.encodeQueryComponent(key)}='
        '${Uri.encodeQueryComponent(value)}',
      );
    }

    addParam('past_only', showPastOnly ? '1' : '0');
    addParam('confirmed_only', confirmedOnly ? '1' : '0');
    final normalizedSearchQuery = searchQuery?.trim();
    final hasSearchQuery =
        normalizedSearchQuery != null && normalizedSearchQuery.isNotEmpty;
    if (hasSearchQuery) {
      addParam('search', normalizedSearchQuery);
    }
    if (categories != null && categories.isNotEmpty) {
      for (final category in categories) {
        addParam('categories[]', category.toString());
      }
    }
    if (tags != null && tags.isNotEmpty) {
      for (final tag in tags) {
        addParam('tags[]', tag.toString());
      }
    }
    if (taxonomy != null && taxonomy.isNotEmpty) {
      for (var index = 0; index < taxonomy.length; index++) {
        final term = taxonomy[index];
        final type = term['type']?.toString().trim();
        final value = term['value']?.toString().trim();
        if (type == null || type.isEmpty || value == null || value.isEmpty) {
          continue;
        }
        addParam('taxonomy[$index][type]', type);
        addParam('taxonomy[$index][value]', value);
      }
    }
    if (!hasSearchQuery && originLat != null && originLng != null) {
      addParam('origin_lat', originLat.toString());
      addParam('origin_lng', originLng.toString());
      if (maxDistanceMeters != null) {
        addParam('max_distance_meters', maxDistanceMeters.toString());
      }
    }

    final uri = Uri.parse(
      '$_apiBaseUrl/v1/events/stream'
      '${queryParts.isEmpty ? '' : '?${queryParts.join('&')}'}',
    );

    return _sseClient
        .connect(
          uri,
          lastEventId: lastEventId,
          headers: _buildStreamHeaders(),
        )
        .map((message) => _parseDelta(message.data, message.id));
  }

  EventDeltaDTO _parseDelta(String raw, String? lastEventId) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return EventDeltaDTO.fromJson(decoded, lastEventId: lastEventId);
      }
    } catch (_) {}
    return EventDeltaDTO(eventId: '', type: '', lastEventId: lastEventId);
  }
}
