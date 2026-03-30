import 'package:belluga_now/domain/app_data/app_data.dart';
import 'package:belluga_now/infrastructure/dal/dao/laravel_backend/shared/tenant_public_auth_headers.dart';
import 'package:belluga_now/infrastructure/services/deferred_link_backend_contract.dart';
import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';

class LaravelDeferredLinkBackend implements DeferredLinkBackendContract {
  LaravelDeferredLinkBackend({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;

  String get _apiBaseUrl =>
      '${GetIt.I.get<AppData>().mainDomainValue.value.origin}/api';

  @override
  Future<Map<String, dynamic>> resolveDeferredLink({
    required String platform,
    String? installReferrer,
    String? storeChannel,
  }) async {
    try {
      final headers = await TenantPublicAuthHeaders.build(
        includeJsonAccept: true,
        bootstrapIfEmpty: true,
      );
      final response = await _dio.post(
        '$_apiBaseUrl/v1/deep-links/deferred/resolve',
        data: <String, dynamic>{
          'platform': platform,
          if (installReferrer != null && installReferrer.trim().isNotEmpty)
            'install_referrer': installReferrer.trim(),
          if (storeChannel != null && storeChannel.trim().isNotEmpty)
            'store_channel': storeChannel.trim(),
        },
        options: Options(headers: headers),
      );
      return _normalizeResponse(response.data);
    } on DioException catch (error) {
      throw Exception(
        'Failed to resolve deferred deep link '
        '[status=${error.response?.statusCode}] '
        '(${error.requestOptions.uri}): '
        '${error.response?.data ?? error.message}',
      );
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

    throw Exception('Unexpected deferred deep link response shape.');
  }
}
