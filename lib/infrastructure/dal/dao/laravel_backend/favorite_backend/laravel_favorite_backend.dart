import 'package:belluga_now/domain/app_data/app_data.dart';
import 'package:belluga_now/domain/repositories/auth_repository_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/favorite_backend_contract.dart';
import 'package:belluga_now/infrastructure/dal/dto/favorite/favorite_preview_dto.dart';
import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';

class LaravelFavoriteBackend implements FavoriteBackendContract {
  LaravelFavoriteBackend({Dio? dio}) : _dio = dio ?? Dio();

  static const int _defaultPageSize = 30;
  static const int _maxPages = 5;

  final Dio _dio;

  String get _apiBaseUrl =>
      '${GetIt.I.get<AppData>().mainDomainValue.value.origin}/api';

  Map<String, String> _headers({bool includeJsonAccept = false}) {
    final token = GetIt.I.get<AuthRepositoryContract>().userToken.trim();
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
    final token = GetIt.I.get<AuthRepositoryContract>().userToken.trim();
    if (token.isEmpty) {
      return const <FavoritePreviewDTO>[];
    }

    final favorites = <FavoritePreviewDTO>[];
    var page = 1;
    var hasMore = true;

    while (hasMore && page <= _maxPages) {
      final payload = await _get(
        '$_apiBaseUrl/v1/favorites',
        queryParameters: {
          'page': page,
          'page_size': _defaultPageSize,
          'registry_key': 'account_profile',
          'target_type': 'account_profile',
        },
      );

      final rawItems = payload['items'];
      final pageItems = rawItems is List
          ? rawItems
              .whereType<Map>()
              .map((item) => FavoritePreviewDTO.fromJson(
                    Map<String, dynamic>.from(item),
                  ))
              .toList(growable: false)
          : const <FavoritePreviewDTO>[];

      favorites.addAll(pageItems);

      hasMore = payload['has_more'] == true;
      if (pageItems.isEmpty) {
        break;
      }

      page += 1;
    }

    return favorites;
  }

  Future<Map<String, dynamic>> _get(
    String url, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _dio.get(
        url,
        queryParameters: queryParameters,
        options: Options(headers: _headers(includeJsonAccept: true)),
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
