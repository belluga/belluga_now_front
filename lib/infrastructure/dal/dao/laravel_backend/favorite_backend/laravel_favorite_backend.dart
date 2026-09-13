import 'package:belluga_now/domain/app_data/app_data.dart';
import 'package:belluga_now/infrastructure/dal/dao/favorite_backend_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/laravel_backend/shared/tenant_public_auth_headers.dart';
import 'package:belluga_now/infrastructure/dal/dto/favorite/favorite_preview_dto.dart';
import 'package:belluga_now/infrastructure/dal/dto/favorite/favorite_preview_page_dto.dart';
import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';

class LaravelFavoriteBackend implements FavoriteBackendContract {
  LaravelFavoriteBackend({Dio? dio}) : _dio = dio ?? Dio();

  static const int _defaultPageSize = 10;
  static const Duration _connectTimeout = Duration(seconds: 5);
  static const Duration _sendTimeout = Duration(seconds: 12);
  static const Duration _receiveTimeout = Duration(seconds: 12);

  final Dio _dio;

  String get _apiBaseUrl =>
      '${GetIt.I.get<AppData>().mainDomainValue.value.origin}/api';

  @override
  Future<List<FavoritePreviewDTO>> fetchFavorites() async {
    return TenantPublicAuthHeaders.retryOnceOnUnauthorized(
      includeJsonAccept: true,
      action: (headers) async {
        final favorites = <FavoritePreviewDTO>[];
        var page = 1;
        var hasMore = true;

        while (hasMore) {
          final pagePayload = await _fetchFavoritesPageWithHeaders(
            headers: headers,
            page: page,
            pageSize: _defaultPageSize,
          );
          favorites.addAll(pagePayload.items);
          hasMore = pagePayload.hasMore;
          if (pagePayload.items.isEmpty) {
            break;
          }
          page += 1;
        }

        return favorites;
      },
    );
  }

  @override
  Future<FavoritePreviewPageDTO> fetchFavoritesPage({
    required int page,
    required int pageSize,
  }) async {
    return TenantPublicAuthHeaders.retryOnceOnUnauthorized(
      includeJsonAccept: true,
      action: (headers) => _fetchFavoritesPageWithHeaders(
        headers: headers,
        page: page,
        pageSize: pageSize,
      ),
    );
  }

  Future<FavoritePreviewPageDTO> _fetchFavoritesPageWithHeaders({
    required Map<String, String> headers,
    required int page,
    required int pageSize,
  }) async {
    final payload = await _get(
      '$_apiBaseUrl/v1/favorites',
      headers: headers,
      queryParameters: {
        'page': page,
        'page_size': pageSize,
        'registry_key': 'account_profile',
        'target_type': 'account_profile',
      },
    );

    final rawItems = payload['items'];
    final pageItems = rawItems is List
        ? rawItems
              .whereType<Map>()
              .map(
                (item) => FavoritePreviewDTO.fromJson(
                  Map<String, dynamic>.from(item),
                ),
              )
              .toList(growable: false)
        : const <FavoritePreviewDTO>[];
    final rawPinned = payload['pinned'];
    final pinned = _decodePinned(rawPinned);

    return FavoritePreviewPageDTO(
      items: pageItems,
      hasMore: payload['has_more'] == true,
      pinned: pinned,
    );
  }

  FavoritePreviewDTO? _decodePinned(Object? rawPinned) {
    if (rawPinned is! Map) return null;
    final payload = Map<String, dynamic>.from(rawPinned);
    final targetRaw = payload['target'];
    final occurrenceStateRaw = payload['occurrence_state'];
    final navigationRaw = payload['navigation'];
    if (payload['registry_key'] != 'account_profile' ||
        payload['target_type'] != 'account_profile' ||
        targetRaw is! Map ||
        occurrenceStateRaw is! Map ||
        navigationRaw is! Map ||
        payload.containsKey('favorite_id') ||
        payload.containsKey('favorited_at')) {
      return null;
    }

    final target = Map<String, dynamic>.from(targetRaw);
    final occurrenceState = Map<String, dynamic>.from(occurrenceStateRaw);
    final navigation = Map<String, dynamic>.from(navigationRaw);
    if (!_isValidPinnedTarget(payload, target) ||
        !_isValidPinnedOccurrenceState(occurrenceState) ||
        !_isValidPinnedNavigation(
          target: target,
          occurrenceState: occurrenceState,
          navigation: navigation,
        )) {
      return null;
    }

    return FavoritePreviewDTO.fromJson(payload);
  }

  bool _isValidPinnedTarget(
    Map<String, dynamic> payload,
    Map<String, dynamic> target,
  ) {
    if (!_hasNonEmptyString(payload, 'target_id') ||
        !_hasNonEmptyString(target, 'id') ||
        !_hasNonEmptyString(target, 'slug') ||
        !_hasNonEmptyString(target, 'display_name') ||
        !_hasNullableNonEmptyString(target, 'avatar_url') ||
        !_hasNullableNonEmptyString(target, 'cover_url') ||
        !_hasNonEmptyString(target, 'profile_type') ||
        target['can_open_public_detail'] != true ||
        !_hasNonEmptyString(target, 'public_detail_path')) {
      return false;
    }

    return payload['target_id'] == target['id'];
  }

  bool _isValidPinnedOccurrenceState(Map<String, dynamic> state) {
    if (!_hasNullableNonEmptyString(state, 'live_now_event_occurrence_id') ||
        !_hasNullableIsoDate(state, 'live_now_event_occurrence_at') ||
        !_hasNullableNonEmptyString(state, 'next_event_occurrence_id') ||
        !_hasNullableIsoDate(state, 'next_event_occurrence_at') ||
        !_hasNullableIsoDate(state, 'last_event_occurrence_at')) {
      return false;
    }

    return (state['live_now_event_occurrence_id'] == null) ==
            (state['live_now_event_occurrence_at'] == null) &&
        (state['next_event_occurrence_id'] == null) ==
            (state['next_event_occurrence_at'] == null);
  }

  bool _isValidPinnedNavigation({
    required Map<String, dynamic> target,
    required Map<String, dynamic> occurrenceState,
    required Map<String, dynamic> navigation,
  }) {
    if (!_hasNonEmptyString(navigation, 'kind') ||
        !_hasNonEmptyString(navigation, 'target_slug') ||
        !_hasNonEmptyString(navigation, 'target_path') ||
        !_hasNonEmptyString(navigation, 'profile_target_path') ||
        !_hasNullableNonEmptyString(navigation, 'event_target_path') ||
        !_hasNullableNonEmptyString(navigation, 'event_target_slug') ||
        !_hasNullableNonEmptyString(navigation, 'event_occurrence_id') ||
        navigation['can_open_public_detail'] != true ||
        navigation['profile_target_path'] != target['public_detail_path']) {
      return false;
    }

    final kind = navigation['kind'];
    if (kind == 'account_profile') {
      return navigation['target_slug'] == target['slug'] &&
          navigation['target_path'] == navigation['profile_target_path'] &&
          navigation['event_target_path'] == null &&
          navigation['event_target_slug'] == null &&
          navigation['event_occurrence_id'] == null &&
          occurrenceState['live_now_event_occurrence_id'] == null &&
          occurrenceState['next_event_occurrence_id'] == null;
    }
    if (kind != 'event') return false;

    final expectedOccurrenceId =
        occurrenceState['live_now_event_occurrence_id'] ??
        occurrenceState['next_event_occurrence_id'];
    return expectedOccurrenceId != null &&
        navigation['event_occurrence_id'] == expectedOccurrenceId &&
        navigation['target_slug'] == navigation['event_target_slug'] &&
        navigation['target_path'] == navigation['event_target_path'];
  }

  bool _hasNonEmptyString(Map<String, dynamic> payload, String key) =>
      payload[key] is String && (payload[key] as String).trim().isNotEmpty;

  bool _hasNullableNonEmptyString(Map<String, dynamic> payload, String key) =>
      payload.containsKey(key) &&
      (payload[key] == null || _hasNonEmptyString(payload, key));

  bool _hasNullableIsoDate(Map<String, dynamic> payload, String key) {
    if (!payload.containsKey(key)) return false;
    final value = payload[key];
    return value == null ||
        (value is String &&
            value.trim().isNotEmpty &&
            DateTime.tryParse(value.trim()) != null);
  }

  @override
  Future<void> favoriteAccountProfile(String accountProfileId) async {
    await _mutateAccountProfileFavorite(
      accountProfileId: accountProfileId,
      isFavorite: true,
    );
  }

  @override
  Future<void> unfavoriteAccountProfile(String accountProfileId) async {
    await _mutateAccountProfileFavorite(
      accountProfileId: accountProfileId,
      isFavorite: false,
    );
  }

  Future<void> _mutateAccountProfileFavorite({
    required String accountProfileId,
    required bool isFavorite,
  }) async {
    final normalizedTargetId = accountProfileId.trim();
    if (normalizedTargetId.isEmpty) {
      throw Exception('Cannot mutate favorites with an empty target id.');
    }

    final payload = <String, dynamic>{
      'target_id': normalizedTargetId,
      'registry_key': 'account_profile',
      'target_type': 'account_profile',
    };

    try {
      final requestUri = '$_apiBaseUrl/v1/favorites';
      await TenantPublicAuthHeaders.retryOnceOnUnauthorized(
        includeJsonAccept: true,
        action: (headers) async {
          final options = Options(
            headers: headers,
            connectTimeout: _connectTimeout,
            sendTimeout: _sendTimeout,
            receiveTimeout: _receiveTimeout,
          );
          if (isFavorite) {
            await _dio.post(requestUri, data: payload, options: options);
            return;
          }
          await _dio.delete(requestUri, data: payload, options: options);
        },
      );
    } on DioException catch (error) {
      final statusCode = error.response?.statusCode;
      final data = error.response?.data;
      final operation = isFavorite ? 'favorite' : 'unfavorite';
      throw Exception(
        'Failed to $operation account profile '
        '[status=$statusCode] '
        '(${error.requestOptions.uri}): '
        '${data ?? error.message}',
      );
    }
  }

  Future<Map<String, dynamic>> _get(
    String url, {
    required Map<String, String> headers,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _dio.get(
        url,
        queryParameters: queryParameters,
        options: Options(
          headers: headers,
          connectTimeout: _connectTimeout,
          sendTimeout: _sendTimeout,
          receiveTimeout: _receiveTimeout,
        ),
      );

      final raw = response.data;
      if (raw is Map<String, dynamic>) {
        final data = raw['data'];
        if (data is Map<String, dynamic>) {
          return data;
        }

        return raw;
      }

      throw Exception('Unexpected favorites response shape.');
    } on DioException catch (error) {
      if (error.response?.statusCode == 401) {
        rethrow;
      }
      final statusCode = error.response?.statusCode;
      final data = error.response?.data;
      throw Exception(
        'Failed to GET favorites request '
        '[status=$statusCode] '
        '(${error.requestOptions.uri}): '
        '${data ?? error.message}',
      );
    }
  }
}
