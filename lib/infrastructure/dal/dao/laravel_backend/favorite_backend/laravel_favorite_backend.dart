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

  Map<String, String> _headers({
    required String token,
    bool includeJsonAccept = false,
  }) {
    final headers = <String, String>{};

    if (token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    if (includeJsonAccept) {
      headers['Accept'] = 'application/json';
    }

    return headers;
  }

  @override
  Future<List<FavoritePreviewDTO>> fetchFavorites() async {
    final token = await TenantPublicAuthHeaders.resolveToken(
      bootstrapIfEmpty: true,
    );
    if (token.trim().isEmpty) {
      return const <FavoritePreviewDTO>[];
    }

    final favorites = <FavoritePreviewDTO>[];
    var page = 1;
    var hasMore = true;

    while (hasMore) {
      final pagePayload = await _fetchFavoritesPageWithToken(
        token: token,
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
  }

  @override
  Future<FavoritePreviewPageDTO> fetchFavoritesPage({
    required int page,
    required int pageSize,
  }) async {
    final token = await TenantPublicAuthHeaders.resolveToken(
      bootstrapIfEmpty: true,
    );
    if (token.trim().isEmpty) {
      return const FavoritePreviewPageDTO(
        items: <FavoritePreviewDTO>[],
        hasMore: false,
      );
    }

    return _fetchFavoritesPageWithToken(
      token: token,
      page: page,
      pageSize: pageSize,
    );
  }

  Future<FavoritePreviewPageDTO> _fetchFavoritesPageWithToken({
    required String token,
    required int page,
    required int pageSize,
  }) async {
    final payload = await _get(
      '$_apiBaseUrl/v1/favorites',
      token: token,
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

    return FavoritePreviewPageDTO(
      items: pageItems,
      hasMore: payload['has_more'] == true,
    );
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
    final token = await TenantPublicAuthHeaders.resolveToken(
      bootstrapIfEmpty: true,
    );
    if (token.isEmpty) {
      throw Exception('Cannot mutate favorites without authentication token.');
    }

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
      final options = Options(
        headers: _headers(token: token, includeJsonAccept: true),
        connectTimeout: _connectTimeout,
        sendTimeout: _sendTimeout,
        receiveTimeout: _receiveTimeout,
      );
      if (isFavorite) {
        await _dio.post(requestUri, data: payload, options: options);
        return;
      }
      await _dio.delete(requestUri, data: payload, options: options);
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
    required String token,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _dio.get(
        url,
        queryParameters: queryParameters,
        options: Options(
          headers: _headers(token: token, includeJsonAccept: true),
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
      final statusCode = error.response?.statusCode;
      if (statusCode == 401) {
        return const {'items': <dynamic>[], 'has_more': false};
      }

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
