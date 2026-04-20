import 'package:belluga_now/domain/app_data/app_data.dart';
import 'package:belluga_now/infrastructure/dal/dao/laravel_backend/shared/tenant_public_auth_headers.dart';
import 'package:belluga_now/infrastructure/dal/dao/proximity_preferences_backend_contract.dart';
import 'package:belluga_now/infrastructure/dal/dto/proximity_preference_dto.dart';
import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';

class LaravelProximityPreferencesBackend
    implements ProximityPreferencesBackendContract {
  LaravelProximityPreferencesBackend({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;

  String get _apiBaseUrl =>
      '${GetIt.I.get<AppData>().mainDomainValue.value.origin}/api';

  @override
  Future<ProximityPreferenceDTO?> fetch() async {
    final token = TenantPublicAuthHeaders.currentToken();
    if (token.isEmpty) {
      return null;
    }

    try {
      final response = await _dio.get(
        '$_apiBaseUrl/v1/profile/proximity-preferences',
        options: Options(
          headers: <String, String>{
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        ),
      );

      final raw = response.data;
      if (raw is! Map<String, dynamic>) {
        throw Exception('Unexpected proximity preferences response shape.');
      }
      final data = raw['data'];
      if (data is! Map<String, dynamic>) {
        throw Exception('Missing proximity preferences data payload.');
      }
      return ProximityPreferenceDTO.fromJson(data);
    } on DioException catch (error) {
      final statusCode = error.response?.statusCode;
      if (statusCode == 404 || statusCode == 401) {
        return null;
      }

      throw Exception(
        'Failed to fetch proximity preferences '
        '[status=$statusCode] (${error.requestOptions.uri}): '
        '${error.response?.data ?? error.message}',
      );
    }
  }

  @override
  Future<ProximityPreferenceDTO> upsert(
    ProximityPreferenceDTO preference,
  ) async {
    final token = TenantPublicAuthHeaders.currentToken();
    if (token.isEmpty) {
      throw Exception(
        'Cannot persist proximity preferences without an identity token.',
      );
    }

    try {
      final response = await _dio.put(
        '$_apiBaseUrl/v1/profile/proximity-preferences',
        data: preference.toJson(),
        options: Options(
          headers: <String, String>{
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        ),
      );

      final raw = response.data;
      if (raw is! Map<String, dynamic>) {
        throw Exception('Unexpected proximity preferences response shape.');
      }
      final data = raw['data'];
      if (data is! Map<String, dynamic>) {
        throw Exception('Missing proximity preferences data payload.');
      }
      return ProximityPreferenceDTO.fromJson(data);
    } on DioException catch (error) {
      final statusCode = error.response?.statusCode;
      throw Exception(
        'Failed to persist proximity preferences '
        '[status=$statusCode] (${error.requestOptions.uri}): '
        '${error.response?.data ?? error.message}',
      );
    }
  }
}
