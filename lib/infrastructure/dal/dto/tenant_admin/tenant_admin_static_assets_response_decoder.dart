import 'package:belluga_now/infrastructure/dal/dto/tenant_admin/tenant_admin_static_asset_dto.dart';
import 'package:belluga_now/infrastructure/dal/dto/tenant_admin/tenant_admin_static_profile_type_dto.dart';

class TenantAdminStaticAssetsResponseDecoder {
  const TenantAdminStaticAssetsResponseDecoder();

  TenantAdminStaticAssetDTO decodeStaticAssetItem(Object? rawResponse) {
    return TenantAdminStaticAssetDTO.fromJson(
      _extractItem(rawResponse, label: 'static asset'),
    );
  }

  List<TenantAdminStaticAssetDTO> decodeStaticAssetList(Object? rawResponse) {
    return _extractList(rawResponse, label: 'static assets')
        .map(TenantAdminStaticAssetDTO.fromJson)
        .toList(growable: false);
  }

  TenantAdminStaticProfileTypeDTO decodeStaticProfileTypeItem(
    Object? rawResponse,
  ) {
    return TenantAdminStaticProfileTypeDTO.fromJson(
      _extractItem(rawResponse, label: 'static profile type'),
    );
  }

  List<TenantAdminStaticProfileTypeDTO> decodeStaticProfileTypeList(
    Object? rawResponse,
  ) {
    return _extractList(rawResponse, label: 'static profile types')
        .map(TenantAdminStaticProfileTypeDTO.fromJson)
        .toList(growable: false);
  }

  Map<String, dynamic> _extractItem(
    Object? rawResponse, {
    required String label,
  }) {
    if (rawResponse is Map<String, dynamic>) {
      final data = rawResponse['data'];
      if (data is Map<String, dynamic>) {
        return data;
      }
      return rawResponse;
    }
    throw Exception('Unexpected $label response shape.');
  }

  List<Map<String, dynamic>> _extractList(
    Object? rawResponse, {
    required String label,
  }) {
    if (rawResponse is Map<String, dynamic>) {
      final data = rawResponse['data'];
      if (data is List) {
        return data
            .whereType<Map>()
            .map((entry) => Map<String, dynamic>.from(entry))
            .toList(growable: false);
      }
    }
    throw Exception('Unexpected $label list response shape.');
  }
}
