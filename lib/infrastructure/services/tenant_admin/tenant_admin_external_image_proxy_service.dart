import 'dart:typed_data';

import 'package:belluga_now/domain/repositories/landlord_auth_repository_contract.dart';
import 'package:belluga_now/domain/services/tenant_admin_external_image_proxy_contract.dart';
import 'package:belluga_now/domain/services/tenant_admin_tenant_scope_contract.dart';
import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';

class TenantAdminExternalImageProxyService
    implements TenantAdminExternalImageProxyContract {
  TenantAdminExternalImageProxyService({
    Dio? dio,
    TenantAdminTenantScopeContract? tenantScope,
  })  : _dio = dio ?? Dio(),
        _tenantScope = tenantScope;

  final Dio _dio;
  final TenantAdminTenantScopeContract? _tenantScope;

  String get _apiBaseUrl =>
      (_tenantScope ?? GetIt.I.get<TenantAdminTenantScopeContract>())
          .selectedTenantAdminBaseUrl;

  Map<String, String> _buildHeaders() {
    final token = GetIt.I.get<LandlordAuthRepositoryContract>().token;
    return {
      'Authorization': 'Bearer $token',
      'Accept': 'image/*',
      'Content-Type': 'application/json',
    };
  }

  @override
  Future<Uint8List> fetchExternalImageBytes({
    required String imageUrl,
  }) async {
    try {
      final response = await _dio.post<List<int>>(
        '$_apiBaseUrl/v1/media/external-image',
        data: {
          'url': imageUrl.trim(),
        },
        options: Options(
          headers: _buildHeaders(),
          responseType: ResponseType.bytes,
          validateStatus: (status) => status != null && status < 400,
          followRedirects: false,
          receiveTimeout: const Duration(seconds: 30),
          sendTimeout: const Duration(seconds: 30),
        ),
      );

      final data = response.data;
      if (data == null || data.isEmpty) {
        throw StateError('Empty proxy response.');
      }
      return Uint8List.fromList(data);
    } on DioException catch (error) {
      // Leave UX messaging up to the caller.
      throw StateError(
        'Failed to proxy external image: '
        '${error.response?.statusCode ?? 'no-status'}',
      );
    }
  }
}
