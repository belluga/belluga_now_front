import 'package:belluga_now/infrastructure/dal/dao/backend_context.dart';
import 'package:belluga_now/infrastructure/dal/dao/backend_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/laravel_backend/shared/tenant_public_auth_headers.dart';
import 'package:belluga_now/infrastructure/dal/dto/discovery_filters/discovery_filter_catalog_dto.dart';
import 'package:belluga_now/infrastructure/services/discovery_filters_backend_contract.dart';
import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';

class LaravelDiscoveryFiltersHttpService
    implements DiscoveryFiltersBackendContract {
  LaravelDiscoveryFiltersHttpService({
    BackendContext? context,
    Dio? dio,
  }) : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: _resolveBaseUrl(context),
                connectTimeout: const Duration(seconds: 5),
                receiveTimeout: const Duration(seconds: 12),
                sendTimeout: const Duration(seconds: 12),
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
        'BackendContext is not available via BackendContract for LaravelDiscoveryFiltersHttpService.',
      );
    }
    return resolved.baseUrl;
  }

  @override
  Future<DiscoveryFilterCatalogDTO> getCatalog(String surface) async {
    final normalizedSurface = surface.trim();
    if (normalizedSurface.isEmpty) {
      return DiscoveryFilterCatalogDTO.fromJson(const <String, dynamic>{});
    }

    final response = await _dio.get(
      '/v1/discovery-filters/${Uri.encodeComponent(normalizedSurface)}',
      options: Options(
        headers: await _buildHeaders(),
        listFormat: ListFormat.multiCompatible,
      ),
    );

    final payload = _normalizeMap(response.data);
    if (payload == null) {
      throw Exception(
        'Unexpected /v1/discovery-filters/$normalizedSurface response envelope',
      );
    }

    return DiscoveryFilterCatalogDTO.fromJson(payload);
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
