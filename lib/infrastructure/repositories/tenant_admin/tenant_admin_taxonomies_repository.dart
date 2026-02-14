import 'package:belluga_now/domain/repositories/landlord_auth_repository_contract.dart';
import 'package:belluga_now/domain/repositories/tenant_admin_taxonomies_repository_contract.dart';
import 'package:belluga_now/domain/services/tenant_admin_tenant_scope_contract.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_definition.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_term_definition.dart';
import 'package:belluga_now/infrastructure/dal/dto/tenant_admin/tenant_admin_taxonomy_dto.dart';
import 'package:belluga_now/infrastructure/dal/dto/tenant_admin/tenant_admin_taxonomy_term_definition_dto.dart';
import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';

class TenantAdminTaxonomiesRepository
    implements TenantAdminTaxonomiesRepositoryContract {
  TenantAdminTaxonomiesRepository({
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
  Future<List<TenantAdminTaxonomyDefinition>> fetchTaxonomies() async {
    try {
      final response = await _dio.get(
        '$_apiBaseUrl/v1/taxonomies',
        options: Options(headers: _buildHeaders()),
      );
      final data = _extractList(response.data);
      return data.map(_mapTaxonomy).toList(growable: false);
    } on DioException catch (error) {
      throw _wrapError(error, 'load taxonomies');
    }
  }

  @override
  Future<TenantAdminTaxonomyDefinition> createTaxonomy({
    required String slug,
    required String name,
    required List<String> appliesTo,
    String? icon,
    String? color,
  }) async {
    try {
      final response = await _dio.post(
        '$_apiBaseUrl/v1/taxonomies',
        data: {
          'slug': slug,
          'name': name,
          'applies_to': appliesTo,
          if (icon != null && icon.trim().isNotEmpty) 'icon': icon.trim(),
          if (color != null && color.trim().isNotEmpty) 'color': color.trim(),
        },
        options: Options(headers: _buildHeaders()),
      );
      final item = _extractItem(response.data);
      return _mapTaxonomy(item);
    } on DioException catch (error) {
      throw _wrapError(error, 'create taxonomy');
    }
  }

  @override
  Future<TenantAdminTaxonomyDefinition> updateTaxonomy({
    required String taxonomyId,
    String? slug,
    String? name,
    List<String>? appliesTo,
    String? icon,
    String? color,
  }) async {
    try {
      final payload = <String, dynamic>{};
      if (slug != null && slug.trim().isNotEmpty) {
        payload['slug'] = slug.trim();
      }
      if (name != null && name.trim().isNotEmpty) {
        payload['name'] = name.trim();
      }
      if (appliesTo != null) {
        payload['applies_to'] = appliesTo;
      }
      if (icon != null) {
        payload['icon'] = icon.trim();
      }
      if (color != null) {
        payload['color'] = color.trim();
      }
      final response = await _dio.patch(
        '$_apiBaseUrl/v1/taxonomies/$taxonomyId',
        data: payload,
        options: Options(headers: _buildHeaders()),
      );
      final item = _extractItem(response.data);
      return _mapTaxonomy(item);
    } on DioException catch (error) {
      throw _wrapError(error, 'update taxonomy');
    }
  }

  @override
  Future<void> deleteTaxonomy(String taxonomyId) async {
    try {
      await _dio.delete(
        '$_apiBaseUrl/v1/taxonomies/$taxonomyId',
        options: Options(headers: _buildHeaders()),
      );
    } on DioException catch (error) {
      throw _wrapError(error, 'delete taxonomy');
    }
  }

  @override
  Future<List<TenantAdminTaxonomyTermDefinition>> fetchTerms({
    required String taxonomyId,
  }) async {
    try {
      final response = await _dio.get(
        '$_apiBaseUrl/v1/taxonomies/$taxonomyId/terms',
        options: Options(headers: _buildHeaders()),
      );
      final data = _extractList(response.data);
      return data.map(_mapTerm).toList(growable: false);
    } on DioException catch (error) {
      throw _wrapError(error, 'load taxonomy terms');
    }
  }

  @override
  Future<TenantAdminTaxonomyTermDefinition> createTerm({
    required String taxonomyId,
    required String slug,
    required String name,
  }) async {
    try {
      final response = await _dio.post(
        '$_apiBaseUrl/v1/taxonomies/$taxonomyId/terms',
        data: {
          'slug': slug,
          'name': name,
        },
        options: Options(headers: _buildHeaders()),
      );
      final item = _extractItem(response.data);
      return _mapTerm(item);
    } on DioException catch (error) {
      throw _wrapError(error, 'create taxonomy term');
    }
  }

  @override
  Future<TenantAdminTaxonomyTermDefinition> updateTerm({
    required String taxonomyId,
    required String termId,
    String? slug,
    String? name,
  }) async {
    try {
      final payload = <String, dynamic>{};
      if (slug != null && slug.trim().isNotEmpty) {
        payload['slug'] = slug.trim();
      }
      if (name != null && name.trim().isNotEmpty) {
        payload['name'] = name.trim();
      }
      final response = await _dio.patch(
        '$_apiBaseUrl/v1/taxonomies/$taxonomyId/terms/$termId',
        data: payload,
        options: Options(headers: _buildHeaders()),
      );
      final item = _extractItem(response.data);
      return _mapTerm(item);
    } on DioException catch (error) {
      throw _wrapError(error, 'update taxonomy term');
    }
  }

  @override
  Future<void> deleteTerm({
    required String taxonomyId,
    required String termId,
  }) async {
    try {
      await _dio.delete(
        '$_apiBaseUrl/v1/taxonomies/$taxonomyId/terms/$termId',
        options: Options(headers: _buildHeaders()),
      );
    } on DioException catch (error) {
      throw _wrapError(error, 'delete taxonomy term');
    }
  }

  Map<String, dynamic> _extractItem(dynamic raw) {
    if (raw is Map<String, dynamic>) {
      final data = raw['data'];
      if (data is Map<String, dynamic>) return data;
      return raw;
    }
    throw Exception('Unexpected taxonomy response shape.');
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
    throw Exception('Unexpected taxonomy list response shape.');
  }

  TenantAdminTaxonomyDefinition _mapTaxonomy(Map<String, dynamic> json) {
    final dto = TenantAdminTaxonomyDTO.fromJson(json);
    return TenantAdminTaxonomyDefinition(
      id: dto.id,
      slug: dto.slug,
      name: dto.name,
      appliesTo: dto.appliesTo,
      icon: dto.icon,
      color: dto.color,
    );
  }

  TenantAdminTaxonomyTermDefinition _mapTerm(Map<String, dynamic> json) {
    final dto = TenantAdminTaxonomyTermDefinitionDTO.fromJson(json);
    return TenantAdminTaxonomyTermDefinition(
      id: dto.id,
      taxonomyId: dto.taxonomyId,
      slug: dto.slug,
      name: dto.name,
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
