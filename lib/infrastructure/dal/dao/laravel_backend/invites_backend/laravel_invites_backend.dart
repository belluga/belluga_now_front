import 'package:belluga_now/domain/app_data/app_data.dart';
import 'package:belluga_now/domain/repositories/auth_repository_contract.dart';
import 'package:belluga_now/infrastructure/services/invites_backend_contract.dart';
import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';

class LaravelInvitesBackend implements InvitesBackendContract {
  LaravelInvitesBackend({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;

  String get _apiBaseUrl =>
      '${GetIt.I.get<AppData>().mainDomainValue.value.origin}/api';

  Map<String, String> _headers({bool includeJsonAccept = false}) {
    final token = GetIt.I.get<AuthRepositoryContract>().userToken.trim();
    final headers = <String, String>{
      'Authorization': 'Bearer $token',
    };
    if (includeJsonAccept) {
      headers['Accept'] = 'application/json';
    }
    return headers;
  }

  @override
  Future<Map<String, dynamic>> fetchInvites({
    required int page,
    required int pageSize,
  }) async {
    return _get(
      '$_apiBaseUrl/v1/invites',
      queryParameters: {
        'page': page,
        'page_size': pageSize,
      },
    );
  }

  @override
  Future<Map<String, dynamic>> fetchSettings() {
    return _get('$_apiBaseUrl/v1/invites/settings');
  }

  @override
  Future<Map<String, dynamic>> acceptInvite(String inviteId) {
    return _post('$_apiBaseUrl/v1/invites/$inviteId/accept');
  }

  @override
  Future<Map<String, dynamic>> declineInvite(String inviteId) {
    return _post('$_apiBaseUrl/v1/invites/$inviteId/decline');
  }

  @override
  Future<Map<String, dynamic>> sendInvites(Map<String, dynamic> payload) {
    return _post(
      '$_apiBaseUrl/v1/invites',
      data: payload,
    );
  }

  @override
  Future<Map<String, dynamic>> createShareCode(Map<String, dynamic> payload) {
    return _post(
      '$_apiBaseUrl/v1/invites/share',
      data: payload,
    );
  }

  @override
  Future<Map<String, dynamic>> acceptShareCode(String code) {
    return _post('$_apiBaseUrl/v1/invites/share/$code/accept');
  }

  @override
  Future<Map<String, dynamic>> importContacts(Map<String, dynamic> payload) {
    return _post(
      '$_apiBaseUrl/v1/contacts/import',
      data: payload,
    );
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
      return _normalizeResponse(response.data);
    } on DioException catch (error) {
      throw _wrapException('GET', error);
    }
  }

  Future<Map<String, dynamic>> _post(
    String url, {
    Map<String, dynamic>? data,
  }) async {
    try {
      final response = await _dio.post(
        url,
        data: data,
        options: Options(headers: _headers(includeJsonAccept: true)),
      );
      return _normalizeResponse(response.data);
    } on DioException catch (error) {
      throw _wrapException('POST', error);
    }
  }

  Map<String, dynamic> _normalizeResponse(dynamic raw) {
    if (raw is Map<String, dynamic>) {
      final data = raw['data'];
      if (data is Map<String, dynamic>) {
        return data;
      }
      return raw;
    }
    throw Exception('Unexpected invites response shape.');
  }

  Exception _wrapException(String method, DioException error) {
    final statusCode = error.response?.statusCode;
    final data = error.response?.data;
    return Exception(
      'Failed to $method invites request '
      '[status=$statusCode] '
      '(${error.requestOptions.uri}): '
      '${data ?? error.message}',
    );
  }
}
