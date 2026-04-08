import 'package:belluga_now/domain/app_data/app_data.dart';
import 'package:belluga_now/domain/static_assets/public_static_asset_model.dart';
import 'package:belluga_now/infrastructure/dal/dao/laravel_backend/shared/tenant_public_auth_headers.dart';
import 'package:belluga_now/infrastructure/dal/dao/static_assets_backend_contract.dart';
import 'package:belluga_now/infrastructure/dal/dto/static_assets/public_static_asset_dto.dart';
import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';

class LaravelStaticAssetsBackend implements StaticAssetsBackendContract {
  LaravelStaticAssetsBackend({
    Dio? dio,
  }) : _dio = dio ?? Dio();

  final Dio _dio;

  String get _apiBaseUrl =>
      '${GetIt.I.get<AppData>().mainDomainValue.value.origin}/api';

  Future<Map<String, String>> _buildHeaders({bool includeJsonAccept = false}) {
    return TenantPublicAuthHeaders.build(
      includeJsonAccept: includeJsonAccept,
      bootstrapIfEmpty: true,
    );
  }

  @override
  Future<PublicStaticAssetModel?> fetchStaticAssetByRef(String assetRef) async {
    final normalizedRef = assetRef.trim();
    if (normalizedRef.isEmpty) {
      return null;
    }

    try {
      final headers = await _buildHeaders(includeJsonAccept: true);
      final response = await _dio.get(
        '$_apiBaseUrl/v1/static_assets/${Uri.encodeComponent(normalizedRef)}',
        options: Options(headers: headers),
      );
      final raw = response.data;
      if (raw is! Map<String, dynamic>) {
        throw Exception('Unexpected static asset detail response shape.');
      }
      final data = raw['data'];
      if (data is! Map) {
        throw Exception('Static asset detail payload missing data object.');
      }
      return PublicStaticAssetDto.fromJson(Map<String, dynamic>.from(data))
          .toDomain();
    } on DioException catch (error) {
      if (error.response?.statusCode == 404) {
        return null;
      }
      final statusCode = error.response?.statusCode;
      final data = error.response?.data;
      throw Exception(
        'Failed to load static asset by ref '
        '[status=$statusCode] '
        '(${error.requestOptions.uri}): '
        '${data ?? error.message}',
      );
    }
  }
}
