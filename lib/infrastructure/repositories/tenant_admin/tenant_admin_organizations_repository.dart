import 'package:belluga_now/domain/repositories/landlord_auth_repository_contract.dart';
import 'package:belluga_now/domain/repositories/tenant_admin_organizations_repository_contract.dart';
import 'package:belluga_now/domain/services/tenant_admin_tenant_scope_contract.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_organization.dart';
import 'package:belluga_now/infrastructure/dal/dto/tenant_admin/tenant_admin_organization_dto.dart';
import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';

class TenantAdminOrganizationsRepository
    implements TenantAdminOrganizationsRepositoryContract {
  TenantAdminOrganizationsRepository({
    Dio? dio,
    TenantAdminTenantScopeContract? tenantScope,
  })  : _dio = dio ?? Dio(),
        _tenantScope = tenantScope;

  final Dio _dio;
  final TenantAdminTenantScopeContract? _tenantScope;

  String get _apiBaseUrl => _resolveTenantAdminBaseUrl(
        _tenantScope ?? GetIt.I.get<TenantAdminTenantScopeContract>(),
      );

  Map<String, String> _buildHeaders() {
    final token = GetIt.I.get<LandlordAuthRepositoryContract>().token;
    return {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    };
  }

  @override
  Future<List<TenantAdminOrganization>> fetchOrganizations() async {
    try {
      final response = await _dio.get(
        '$_apiBaseUrl/v1/organizations',
        options: Options(headers: _buildHeaders()),
      );
      final data = _extractList(response.data);
      return data.map(_mapOrganization).toList(growable: false);
    } on DioException catch (error) {
      throw _wrapError(error, 'load organizations');
    }
  }

  @override
  Future<TenantAdminOrganization> fetchOrganization(
      String organizationId) async {
    try {
      final response = await _dio.get(
        '$_apiBaseUrl/v1/organizations/$organizationId',
        options: Options(headers: _buildHeaders()),
      );
      final item = _extractItem(response.data);
      return _mapOrganization(item);
    } on DioException catch (error) {
      throw _wrapError(error, 'load organization');
    }
  }

  @override
  Future<TenantAdminOrganization> createOrganization({
    required String name,
    String? description,
  }) async {
    try {
      final response = await _dio.post(
        '$_apiBaseUrl/v1/organizations',
        data: {
          'name': name,
          if (description != null && description.trim().isNotEmpty)
            'description': description.trim(),
        },
        options: Options(headers: _buildHeaders()),
      );
      final item = _extractItem(response.data);
      return _mapOrganization(item);
    } on DioException catch (error) {
      throw _wrapError(error, 'create organization');
    }
  }

  @override
  Future<TenantAdminOrganization> updateOrganization({
    required String organizationId,
    String? name,
    String? description,
  }) async {
    try {
      final payload = <String, dynamic>{};
      if (name != null && name.trim().isNotEmpty) {
        payload['name'] = name.trim();
      }
      if (description != null) {
        payload['description'] = description.trim();
      }
      final response = await _dio.patch(
        '$_apiBaseUrl/v1/organizations/$organizationId',
        data: payload,
        options: Options(headers: _buildHeaders()),
      );
      final item = _extractItem(response.data);
      return _mapOrganization(item);
    } on DioException catch (error) {
      throw _wrapError(error, 'update organization');
    }
  }

  @override
  Future<void> deleteOrganization(String organizationId) async {
    try {
      await _dio.delete(
        '$_apiBaseUrl/v1/organizations/$organizationId',
        options: Options(headers: _buildHeaders()),
      );
    } on DioException catch (error) {
      throw _wrapError(error, 'delete organization');
    }
  }

  @override
  Future<TenantAdminOrganization> restoreOrganization(
    String organizationId,
  ) async {
    try {
      final response = await _dio.post(
        '$_apiBaseUrl/v1/organizations/$organizationId/restore',
        options: Options(headers: _buildHeaders()),
      );
      final item = _extractItem(response.data);
      return _mapOrganization(item);
    } on DioException catch (error) {
      throw _wrapError(error, 'restore organization');
    }
  }

  @override
  Future<void> forceDeleteOrganization(String organizationId) async {
    try {
      await _dio.post(
        '$_apiBaseUrl/v1/organizations/$organizationId/force_delete',
        options: Options(headers: _buildHeaders()),
      );
    } on DioException catch (error) {
      throw _wrapError(error, 'force delete organization');
    }
  }

  Map<String, dynamic> _extractItem(dynamic raw) {
    if (raw is Map<String, dynamic>) {
      final data = raw['data'];
      if (data is Map<String, dynamic>) return data;
      return raw;
    }
    throw Exception('Unexpected organization response shape.');
  }

  List<Map<String, dynamic>> _extractList(dynamic raw) {
    if (raw is Map<String, dynamic>) {
      final data = raw['data'];
      if (data is List) {
        return data
            .whereType<Map>()
            .map((entry) => Map<String, dynamic>.from(entry))
            .toList();
      }
    }
    throw Exception('Unexpected organizations list response shape.');
  }

  TenantAdminOrganization _mapOrganization(Map<String, dynamic> json) {
    final dto = TenantAdminOrganizationDTO.fromJson(json);
    return TenantAdminOrganization(
      id: dto.id,
      name: dto.name,
      slug: dto.slug,
      description: dto.description,
    );
  }

  Exception _wrapError(DioException error, String label) {
    final status = error.response?.statusCode;
    final data = error.response?.data;
    return Exception(
      'Failed to $label [status=$status] (${error.requestOptions.uri}): '
      '${data ?? error.message}',
    );
  }

  String _resolveTenantAdminBaseUrl(
    TenantAdminTenantScopeContract tenantScope,
  ) {
    final selectedDomain = tenantScope.selectedTenantDomain?.trim();
    if (selectedDomain == null || selectedDomain.isEmpty) {
      throw StateError('Tenant admin scope is not selected.');
    }
    final uri = Uri.tryParse(
      selectedDomain.contains('://')
          ? selectedDomain
          : 'https://$selectedDomain',
    );
    if (uri == null || uri.host.trim().isEmpty) {
      throw StateError('Invalid tenant domain selected for admin scope.');
    }
    final origin = Uri(
      scheme: uri.scheme,
      host: uri.host,
      port: uri.hasPort ? uri.port : null,
    );
    return origin.resolve('/admin/api').toString();
  }
}
