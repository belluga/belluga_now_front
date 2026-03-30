import 'package:belluga_now/domain/repositories/landlord_auth_repository_contract.dart';
import 'package:belluga_now/domain/repositories/tenant_admin_taxonomies_repository_contract.dart';
import 'package:belluga_now/domain/services/tenant_admin_tenant_scope_contract.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_paged_result.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_definition.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_term_definition.dart';
import 'package:belluga_now/infrastructure/dal/dao/tenant_admin/tenant_admin_taxonomies_request_encoder.dart';
import 'package:belluga_now/infrastructure/dal/dto/tenant_admin/tenant_admin_taxonomies_response_decoder.dart';
import 'package:belluga_now/infrastructure/repositories/tenant_admin/tenant_admin_pagination_utils.dart';
import 'package:belluga_now/infrastructure/repositories/tenant_admin/support/tenant_admin_validation_failure_resolver.dart';
import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';

class TenantAdminTaxonomiesRepository
    with TenantAdminTaxonomiesPaginationMixin
    implements TenantAdminTaxonomiesRepositoryContract {
  TenantAdminTaxonomiesRepository({
    Dio? dio,
    TenantAdminTenantScopeContract? tenantScope,
  })  : _dio = dio ?? Dio(),
        _tenantScope = tenantScope;

  final Dio _dio;
  final TenantAdminTenantScopeContract? _tenantScope;
  final TenantAdminTaxonomiesResponseDecoder _responseDecoder =
      const TenantAdminTaxonomiesResponseDecoder();
  final TenantAdminTaxonomiesRequestEncoder _requestEncoder =
      const TenantAdminTaxonomiesRequestEncoder();

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
  Future<List<TenantAdminTaxonomyDefinition>> fetchTaxonomies() async {
    var page = TenantAdminTaxRepoInt.fromRaw(1, defaultValue: 1);
    final pageSize = TenantAdminTaxRepoInt.fromRaw(100, defaultValue: 100);
    var hasMore = TenantAdminTaxRepoBool.fromRaw(true, defaultValue: true);
    final taxonomies = <TenantAdminTaxonomyDefinition>[];

    while (hasMore.value) {
      final result = await fetchTaxonomiesPage(
        page: page,
        pageSize: pageSize,
      );
      taxonomies.addAll(result.items);
      hasMore = TenantAdminTaxRepoBool.fromRaw(
        result.hasMore,
        defaultValue: true,
      );
      page = TenantAdminTaxRepoInt.fromRaw(
        page.value + 1,
        defaultValue: 1,
      );
    }

    return List<TenantAdminTaxonomyDefinition>.unmodifiable(taxonomies);
  }

  @override
  Future<TenantAdminPagedResult<TenantAdminTaxonomyDefinition>>
      fetchTaxonomiesPage({
    required TenantAdminTaxRepoInt page,
    required TenantAdminTaxRepoInt pageSize,
  }) async {
    try {
      final response = await _dio.get(
        '$_apiBaseUrl/v1/taxonomies',
        queryParameters: {
          'page': page.value,
          'page_size': pageSize.value,
        },
        options: Options(headers: _buildHeaders()),
      );
      final dtos = _responseDecoder.decodeTaxonomyList(response.data);
      return tenantAdminPagedResultFromRaw(
        items: dtos.map((dto) => dto.toDomain()).toList(growable: false),
        hasMore: tenantAdminResolveHasMore(
          rawResponse: response.data,
          requestedPage: page.value,
        ),
      );
    } on DioException catch (error) {
      throw _wrapError(error, 'load taxonomies page');
    }
  }

  @override
  Future<TenantAdminTaxonomyDefinition> createTaxonomy({
    required TenantAdminTaxRepoString slug,
    required TenantAdminTaxRepoString name,
    required List<TenantAdminTaxRepoString> appliesTo,
    TenantAdminTaxRepoString? icon,
    TenantAdminTaxRepoString? color,
  }) async {
    try {
      final response = await _dio.post(
        '$_apiBaseUrl/v1/taxonomies',
        data: {
          'slug': slug.value,
          'name': name.value,
          'applies_to':
              appliesTo.map((value) => value.value).toList(growable: false),
          if (icon != null && icon.value.trim().isNotEmpty)
            'icon': icon.value.trim(),
          if (color != null && color.value.trim().isNotEmpty)
            'color': color.value.trim(),
        },
        options: Options(headers: _buildHeaders()),
      );
      final dto = _responseDecoder.decodeTaxonomyItem(response.data);
      return dto.toDomain();
    } on DioException catch (error) {
      throw _wrapError(error, 'create taxonomy');
    }
  }

  @override
  Future<TenantAdminTaxonomyDefinition> updateTaxonomy({
    required TenantAdminTaxRepoString taxonomyId,
    TenantAdminTaxRepoString? slug,
    TenantAdminTaxRepoString? name,
    List<TenantAdminTaxRepoString>? appliesTo,
    TenantAdminTaxRepoString? icon,
    TenantAdminTaxRepoString? color,
  }) async {
    try {
      final payload = _requestEncoder.encodeTaxonomyUpdate(
        slug: slug?.value,
        name: name?.value,
        appliesTo:
            appliesTo?.map((value) => value.value).toList(growable: false),
        icon: icon?.value,
        color: color?.value,
      );
      final response = await _dio.patch(
        '$_apiBaseUrl/v1/taxonomies/${taxonomyId.value}',
        data: payload,
        options: Options(headers: _buildHeaders()),
      );
      final dto = _responseDecoder.decodeTaxonomyItem(response.data);
      return dto.toDomain();
    } on DioException catch (error) {
      throw _wrapError(error, 'update taxonomy');
    }
  }

  @override
  Future<void> deleteTaxonomy(TenantAdminTaxRepoString taxonomyId) async {
    try {
      await _dio.delete(
        '$_apiBaseUrl/v1/taxonomies/${taxonomyId.value}',
        options: Options(headers: _buildHeaders()),
      );
    } on DioException catch (error) {
      throw _wrapError(error, 'delete taxonomy');
    }
  }

  @override
  Future<List<TenantAdminTaxonomyTermDefinition>> fetchTerms({
    required TenantAdminTaxRepoString taxonomyId,
  }) async {
    var page = TenantAdminTaxRepoInt.fromRaw(1, defaultValue: 1);
    final pageSize = TenantAdminTaxRepoInt.fromRaw(100, defaultValue: 100);
    var hasMore = TenantAdminTaxRepoBool.fromRaw(true, defaultValue: true);
    final terms = <TenantAdminTaxonomyTermDefinition>[];

    while (hasMore.value) {
      final result = await fetchTermsPage(
        taxonomyId: taxonomyId,
        page: page,
        pageSize: pageSize,
      );
      terms.addAll(result.items);
      hasMore = TenantAdminTaxRepoBool.fromRaw(
        result.hasMore,
        defaultValue: true,
      );
      page = TenantAdminTaxRepoInt.fromRaw(
        page.value + 1,
        defaultValue: 1,
      );
    }

    return List<TenantAdminTaxonomyTermDefinition>.unmodifiable(terms);
  }

  @override
  Future<TenantAdminPagedResult<TenantAdminTaxonomyTermDefinition>>
      fetchTermsPage({
    required TenantAdminTaxRepoString taxonomyId,
    required TenantAdminTaxRepoInt page,
    required TenantAdminTaxRepoInt pageSize,
  }) async {
    try {
      final response = await _dio.get(
        '$_apiBaseUrl/v1/taxonomies/${taxonomyId.value}/terms',
        queryParameters: {
          'page': page.value,
          'page_size': pageSize.value,
        },
        options: Options(headers: _buildHeaders()),
      );
      final dtos = _responseDecoder.decodeTermList(response.data);
      return tenantAdminPagedResultFromRaw(
        items: dtos.map((dto) => dto.toDomain()).toList(growable: false),
        hasMore: tenantAdminResolveHasMore(
          rawResponse: response.data,
          requestedPage: page.value,
        ),
      );
    } on DioException catch (error) {
      throw _wrapError(error, 'load taxonomy terms page');
    }
  }

  @override
  Future<TenantAdminTaxonomyTermDefinition> createTerm({
    required TenantAdminTaxRepoString taxonomyId,
    required TenantAdminTaxRepoString slug,
    required TenantAdminTaxRepoString name,
  }) async {
    try {
      final response = await _dio.post(
        '$_apiBaseUrl/v1/taxonomies/${taxonomyId.value}/terms',
        data: {
          'slug': slug.value,
          'name': name.value,
        },
        options: Options(headers: _buildHeaders()),
      );
      final dto = _responseDecoder.decodeTermItem(response.data);
      return dto.toDomain();
    } on DioException catch (error) {
      throw _wrapError(error, 'create taxonomy term');
    }
  }

  @override
  Future<TenantAdminTaxonomyTermDefinition> updateTerm({
    required TenantAdminTaxRepoString taxonomyId,
    required TenantAdminTaxRepoString termId,
    TenantAdminTaxRepoString? slug,
    TenantAdminTaxRepoString? name,
  }) async {
    try {
      final payload = _requestEncoder.encodeTermUpdate(
        slug: slug?.value,
        name: name?.value,
      );
      final response = await _dio.patch(
        '$_apiBaseUrl/v1/taxonomies/${taxonomyId.value}/terms/${termId.value}',
        data: payload,
        options: Options(headers: _buildHeaders()),
      );
      final dto = _responseDecoder.decodeTermItem(response.data);
      return dto.toDomain();
    } on DioException catch (error) {
      throw _wrapError(error, 'update taxonomy term');
    }
  }

  @override
  Future<void> deleteTerm({
    required TenantAdminTaxRepoString taxonomyId,
    required TenantAdminTaxRepoString termId,
  }) async {
    try {
      await _dio.delete(
        '$_apiBaseUrl/v1/taxonomies/${taxonomyId.value}/terms/${termId.value}',
        options: Options(headers: _buildHeaders()),
      );
    } on DioException catch (error) {
      throw _wrapError(error, 'delete taxonomy term');
    }
  }

  Exception _wrapError(DioException error, String label) {
    return tenantAdminWrapRepositoryError(error, label);
  }
}
