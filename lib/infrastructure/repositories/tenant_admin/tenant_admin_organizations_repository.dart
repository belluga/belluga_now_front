import 'package:belluga_now/domain/repositories/landlord_auth_repository_contract.dart';
import 'package:belluga_now/domain/repositories/tenant_admin_organizations_repository_contract.dart';
import 'package:belluga_now/domain/services/tenant_admin_tenant_scope_contract.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_organization.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_paged_result.dart';
import 'package:belluga_now/infrastructure/dal/dao/tenant_admin/tenant_admin_organizations_request_encoder.dart';
import 'package:belluga_now/infrastructure/dal/dto/tenant_admin/tenant_admin_organizations_response_decoder.dart';
import 'package:belluga_now/infrastructure/repositories/tenant_admin/tenant_admin_pagination_utils.dart';
import 'package:belluga_now/infrastructure/repositories/tenant_admin/support/tenant_admin_validation_failure_resolver.dart';
import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';

class TenantAdminOrganizationsRepository
    with TenantAdminOrganizationsPaginationMixin
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
        page: TenantAdminOrganizationsRepositoryContractPrimInt.fromRaw(
          page,
          defaultValue: 1,
        ),
        pageSize: TenantAdminOrganizationsRepositoryContractPrimInt.fromRaw(
          pageSize,
          defaultValue: pageSize,
        ),
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
    required TenantAdminOrganizationsRepositoryContractPrimInt page,
    required TenantAdminOrganizationsRepositoryContractPrimInt pageSize,
  }) async {
    try {
      final response = await _dio.get(
        '$_apiBaseUrl/v1/organizations',
        queryParameters: {
          'page': page.value,
          'page_size': pageSize.value,
        },
        options: Options(headers: _buildHeaders()),
      );
      final dtos = _responseDecoder.decodeOrganizationList(response.data);
      return tenantAdminPagedResultFromRaw(
        items: dtos.map((dto) => dto.toDomain()).toList(growable: false),
        hasMore: tenantAdminResolveHasMore(
          rawResponse: response.data,
          requestedPage: page.value,
        ),
      );
    } on DioException catch (error) {
      throw _wrapError(error, 'load organizations page');
    }
  }

  @override
  Future<TenantAdminOrganization> fetchOrganization(
      TenantAdminOrganizationsRepositoryContractPrimString
          organizationId) async {
    try {
      final response = await _dio.get(
        '$_apiBaseUrl/v1/organizations/${organizationId.value}',
        options: Options(headers: _buildHeaders()),
      );
      final dto = _responseDecoder.decodeOrganizationItem(response.data);
      return dto.toDomain();
    } on DioException catch (error) {
      throw _wrapError(error, 'load organization');
    }
  }

  @override
  Future<TenantAdminOrganization> createOrganization({
    required TenantAdminOrganizationsRepositoryContractPrimString name,
    TenantAdminOrganizationsRepositoryContractPrimString? description,
  }) async {
    try {
      final response = await _dio.post(
        '$_apiBaseUrl/v1/organizations',
        data: {
          'name': name.value,
          if (description != null && description.value.trim().isNotEmpty)
            'description': description.value.trim(),
        },
        options: Options(headers: _buildHeaders()),
      );
      final dto = _responseDecoder.decodeOrganizationItem(response.data);
      return dto.toDomain();
    } on DioException catch (error) {
      throw _wrapError(error, 'create organization');
    }
  }

  @override
  Future<TenantAdminOrganization> updateOrganization({
    required TenantAdminOrganizationsRepositoryContractPrimString
        organizationId,
    TenantAdminOrganizationsRepositoryContractPrimString? name,
    TenantAdminOrganizationsRepositoryContractPrimString? slug,
    TenantAdminOrganizationsRepositoryContractPrimString? description,
  }) async {
    try {
      final payload = _requestEncoder.encodeOrganizationUpdate(
        name: name?.value,
        slug: slug?.value,
        description: description?.value,
      );
      final response = await _dio.patch(
        '$_apiBaseUrl/v1/organizations/${organizationId.value}',
        data: payload,
        options: Options(headers: _buildHeaders()),
      );
      final dto = _responseDecoder.decodeOrganizationItem(response.data);
      return dto.toDomain();
    } on DioException catch (error) {
      throw _wrapError(error, 'update organization');
    }
  }

  @override
  Future<void> deleteOrganization(
    TenantAdminOrganizationsRepositoryContractPrimString organizationId,
  ) async {
    try {
      await _dio.delete(
        '$_apiBaseUrl/v1/organizations/${organizationId.value}',
        options: Options(headers: _buildHeaders()),
      );
    } on DioException catch (error) {
      throw _wrapError(error, 'delete organization');
    }
  }

  @override
  Future<TenantAdminOrganization> restoreOrganization(
    TenantAdminOrganizationsRepositoryContractPrimString organizationId,
  ) async {
    try {
      final response = await _dio.post(
        '$_apiBaseUrl/v1/organizations/${organizationId.value}/restore',
        options: Options(headers: _buildHeaders()),
      );
      final dto = _responseDecoder.decodeOrganizationItem(response.data);
      return dto.toDomain();
    } on DioException catch (error) {
      throw _wrapError(error, 'restore organization');
    }
  }

  @override
  Future<void> forceDeleteOrganization(
    TenantAdminOrganizationsRepositoryContractPrimString organizationId,
  ) async {
    try {
      await _dio.post(
        '$_apiBaseUrl/v1/organizations/${organizationId.value}/force_delete',
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
