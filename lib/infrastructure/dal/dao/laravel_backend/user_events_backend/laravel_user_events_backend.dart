import 'package:belluga_now/domain/app_data/app_data.dart';
import 'package:belluga_now/domain/repositories/auth_repository_contract.dart';
import 'package:belluga_now/infrastructure/services/user_events_backend_contract.dart';
import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';

class LaravelUserEventsBackend implements UserEventsBackendContract {
  LaravelUserEventsBackend({Dio? dio}) : _dio = dio ?? Dio();

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
  Future<Map<String, dynamic>> fetchConfirmedEventIds() {
    return _get('$_apiBaseUrl/v1/events/attendance/confirmed');
  }

  @override
  Future<Map<String, dynamic>> confirmAttendance({
    required String eventId,
    String? occurrenceId,
  }) {
    final payload = <String, dynamic>{};
    if (occurrenceId != null && occurrenceId.trim().isNotEmpty) {
      payload['occurrence_id'] = occurrenceId.trim();
    }

    return _post(
      '$_apiBaseUrl/v1/events/$eventId/attendance/confirm',
      data: payload.isEmpty ? null : payload,
    );
  }

  @override
  Future<Map<String, dynamic>> unconfirmAttendance({
    required String eventId,
    String? occurrenceId,
  }) {
    final payload = <String, dynamic>{};
    if (occurrenceId != null && occurrenceId.trim().isNotEmpty) {
      payload['occurrence_id'] = occurrenceId.trim();
    }

    return _post(
      '$_apiBaseUrl/v1/events/$eventId/attendance/unconfirm',
      data: payload.isEmpty ? null : payload,
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
    throw Exception('Unexpected user events response shape.');
  }

  Exception _wrapException(String method, DioException error) {
    final statusCode = error.response?.statusCode;
    final data = error.response?.data;
    return Exception(
      'Failed to $method user-events request '
      '[status=$statusCode] '
      '(${error.requestOptions.uri}): '
      '${data ?? error.message}',
    );
  }
}

