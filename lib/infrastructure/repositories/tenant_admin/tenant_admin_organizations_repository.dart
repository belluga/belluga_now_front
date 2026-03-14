import 'package:belluga_now/domain/repositories/landlord_auth_repository_contract.dart';
import 'package:belluga_now/domain/repositories/tenant_admin_organizations_repository_contract.dart';
import 'package:belluga_now/domain/services/tenant_admin_tenant_scope_contract.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_organization.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_paged_result.dart';
import 'package:belluga_now/infrastructure/dal/dao/tenant_admin/tenant_admin_organizations_request_encoder.dart';
import 'package:belluga_now/infrastructure/dal/dto/tenant_admin/tenant_admin_organizations_response_decoder.dart';
import 'package:belluga_now/infrastructure/dal/dto/mappers/tenant_admin_dto_mapper.dart';
import 'package:belluga_now/infrastructure/repositories/tenant_admin/tenant_admin_pagination_utils.dart';
import 'package:belluga_now/infrastructure/repositories/tenant_admin/support/tenant_admin_validation_failure_resolver.dart';
import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';

class TenantAdminOrganizationsRepository
    with TenantAdminOrganizationsPaginationMixin, TenantAdminDtoMapper
    implements TenantAdminOrganizationsRepositoryContract {
  TenantAdminOrganizationsRepository({
    Dio? dio,
    TenantAdminTenantScopeContract? tenantScope,
  })  : _dio = dio ?? Dio(),
        _tenantScope = tenantScope;

  final Dio _dio;
  final TenantAdminTenantScopeContract? _tenantScope;
  final TenantAdminOrganizationsResponseDecoder _responseDecoder =
      const TenantAdminOrganizationsResponseDecoder();
  final TenantAdminOrganizationsRequestEncoder _requestEncoder =
      const TenantAdminOrganizationsRequestEncoder();

  String get _apiBaseUrl =>
      (_tenantScope ?? GetIt.I.get<TenantAdminTenantScopeContract>())
          .selectedTenantAdminBaseUrl;

  Map<String, String> _buildHeaders() {
    final token = GetIt.I.get<LandlordAuthRepositoryContract>().token;
    return {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    };
  }

  @override
  Future<List<TenantAdminOrganization>> fetchOrganizations() async {
    var page = 1;
    const pageSize = 100;
    var hasMore = true;
    final organizations = <TenantAdminOrganization>[];

    while (hasMore) {
      final result = await fetchOrganizationsPage(
        page: page,
        pageSize: pageSize,
      );
      organizations.addAll(result.items);
      hasMore = result.hasMore;
      page += 1;
    }

    return List<TenantAdminOrganization>.unmodifiable(organizations);
  }

  @override
  Future<TenantAdminPagedResult<TenantAdminOrganization>>
      fetchOrganizationsPage({
    required int page,
    required int pageSize,
  }) async {
    try {
      final response = await _dio.get(
        '$_apiBaseUrl/v1/organizations',
        queryParameters: {
          'page': page,
          'page_size': pageSize,
        },
        options: Options(headers: _buildHeaders()),
      );
      final dtos = _responseDecoder.decodeOrganizationList(response.data);
      return TenantAdminPagedResult<TenantAdminOrganization>(
        items: dtos.map(mapTenantAdminOrganizationDto).toList(growable: false),
        hasMore: tenantAdminResolveHasMore(
          rawResponse: response.data,
          requestedPage: page,
        ),
      );
    } on DioException catch (error) {
      throw _wrapError(error, 'load organizations page');
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
      final dto = _responseDecoder.decodeOrganizationItem(response.data);
      return mapTenantAdminOrganizationDto(dto);
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
      final dto = _responseDecoder.decodeOrganizationItem(response.data);
      return mapTenantAdminOrganizationDto(dto);
    } on DioException catch (error) {
      throw _wrapError(error, 'create organization');
    }
  }

  @override
  Future<TenantAdminOrganization> updateOrganization({
    required String organizationId,
    String? name,
    String? slug,
    String? description,
  }) async {
    try {
      final payload = _requestEncoder.encodeOrganizationUpdate(
        name: name,
        slug: slug,
        description: description,
      );
      final response = await _dio.patch(
        '$_apiBaseUrl/v1/organizations/$organizationId',
        data: payload,
        options: Options(headers: _buildHeaders()),
      );
      final dto = _responseDecoder.decodeOrganizationItem(response.data);
      return mapTenantAdminOrganizationDto(dto);
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
      final dto = _responseDecoder.decodeOrganizationItem(response.data);
      return mapTenantAdminOrganizationDto(dto);
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

  Exception _wrapError(DioException error, String label) {
    return tenantAdminWrapRepositoryError(error, label);
  }
}
