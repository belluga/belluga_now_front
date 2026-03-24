import 'package:belluga_now/domain/repositories/landlord_auth_repository_contract.dart';
import 'package:belluga_now/domain/repositories/tenant_admin_static_assets_repository_contract.dart';
import 'package:belluga_now/domain/services/tenant_admin_tenant_scope_contract.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_location.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_media_upload.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_paged_result.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_static_asset.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_static_profile_type.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_term.dart';
import 'package:belluga_now/infrastructure/dal/dao/tenant_admin/tenant_admin_media_form_data_builder.dart';
import 'package:belluga_now/infrastructure/dal/dao/tenant_admin/tenant_admin_static_assets_request_encoder.dart';
import 'package:belluga_now/infrastructure/dal/dto/tenant_admin/tenant_admin_static_asset_dto.dart';
import 'package:belluga_now/infrastructure/dal/dto/tenant_admin/tenant_admin_static_assets_response_decoder.dart';
import 'package:belluga_now/infrastructure/repositories/tenant_admin/tenant_admin_pagination_utils.dart';
import 'package:belluga_now/infrastructure/repositories/tenant_admin/support/tenant_admin_validation_failure_resolver.dart';
import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';

class TenantAdminStaticAssetsRepository
    with TenantAdminStaticAssetsPaginationMixin
    implements TenantAdminStaticAssetsRepositoryContract {
  TenantAdminStaticAssetsRepository({
    Dio? dio,
    TenantAdminTenantScopeContract? tenantScope,
  })  : _dio = dio ?? Dio(),
        _tenantScope = tenantScope;

  final Dio _dio;
  final TenantAdminTenantScopeContract? _tenantScope;
  final TenantAdminStaticAssetsResponseDecoder _responseDecoder =
      const TenantAdminStaticAssetsResponseDecoder();
  final TenantAdminStaticAssetsRequestEncoder _requestEncoder =
      const TenantAdminStaticAssetsRequestEncoder();
  final TenantAdminMediaFormDataBuilder _mediaFormDataBuilder =
      const TenantAdminMediaFormDataBuilder();

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
  Future<List<TenantAdminStaticAsset>> fetchStaticAssets() async {
    var page = 1;
    const pageSize = 100;
    var hasMore = true;
    final assets = <TenantAdminStaticAsset>[];

    while (hasMore) {
      final result = await fetchStaticAssetsPage(
        page: page,
        pageSize: pageSize,
      );
      assets.addAll(result.items);
      hasMore = result.hasMore;
      page += 1;
    }

    return List<TenantAdminStaticAsset>.unmodifiable(assets);
  }

  @override
  Future<TenantAdminPagedResult<TenantAdminStaticAsset>> fetchStaticAssetsPage({
    required int page,
    required int pageSize,
  }) async {
    try {
      final response = await _dio.get(
        '$_apiBaseUrl/v1/static_assets',
        queryParameters: {
          'page': page,
          'page_size': pageSize,
        },
        options: Options(headers: _buildHeaders()),
      );
      final dtos = _responseDecoder.decodeStaticAssetList(response.data);
      return TenantAdminPagedResult<TenantAdminStaticAsset>(
        items: dtos
            .map(
              (dto) => _normalizeStaticAssetMediaUrls(dto).toDomain(),
            )
            .toList(growable: false),
        hasMore: tenantAdminResolveHasMore(
          rawResponse: response.data,
          requestedPage: page,
        ),
      );
    } on DioException catch (error) {
      throw _wrapError(error, 'load static assets page');
    }
  }

  @override
  Future<TenantAdminStaticAsset> fetchStaticAsset(String assetId) async {
    try {
      final response = await _dio.get(
        '$_apiBaseUrl/v1/static_assets/$assetId',
        options: Options(headers: _buildHeaders()),
      );
      final dto = _responseDecoder.decodeStaticAssetItem(response.data);
      return _normalizeStaticAssetMediaUrls(dto).toDomain();
    } on DioException catch (error) {
      throw _wrapError(error, 'load static asset');
    }
  }

  @override
  Future<TenantAdminStaticAsset> createStaticAsset({
    required String profileType,
    required String displayName,
    TenantAdminLocation? location,
    List<TenantAdminTaxonomyTerm> taxonomyTerms = const [],
    String? bio,
    String? content,
    String? avatarUrl,
    String? coverUrl,
    TenantAdminMediaUpload? avatarUpload,
    TenantAdminMediaUpload? coverUpload,
  }) async {
    try {
      final payload = _requestEncoder.encodeStaticAssetPayload(
        profileType: profileType,
        displayName: displayName,
        location: location,
        taxonomyTerms: taxonomyTerms,
        bio: bio,
        content: content,
        avatarUrl: avatarUrl,
        coverUrl: coverUrl,
      );
      final uploadPayload = _mediaFormDataBuilder.buildAvatarCoverPayload(
        payload: payload,
        avatarUpload: avatarUpload,
        coverUpload: coverUpload,
      );
      final response = await _dio.post(
        '$_apiBaseUrl/v1/static_assets',
        data: uploadPayload ?? payload,
        options: Options(headers: _buildHeaders()),
      );
      final dto = _responseDecoder.decodeStaticAssetItem(response.data);
      return _normalizeStaticAssetMediaUrls(dto).toDomain();
    } on DioException catch (error) {
      throw _wrapError(error, 'create static asset');
    }
  }

  @override
  Future<TenantAdminStaticAsset> updateStaticAsset({
    required String assetId,
    String? profileType,
    String? displayName,
    String? slug,
    TenantAdminLocation? location,
    List<TenantAdminTaxonomyTerm>? taxonomyTerms,
    String? bio,
    String? content,
    String? avatarUrl,
    String? coverUrl,
    TenantAdminMediaUpload? avatarUpload,
    TenantAdminMediaUpload? coverUpload,
  }) async {
    try {
      final payload = _requestEncoder.encodeStaticAssetPayload(
        profileType: profileType,
        displayName: displayName,
        slug: slug,
        location: location,
        taxonomyTerms: taxonomyTerms,
        bio: bio,
        content: content,
        avatarUrl: avatarUrl,
        coverUrl: coverUrl,
      );
      final uploadPayload = _mediaFormDataBuilder.buildAvatarCoverPayload(
        payload: payload,
        avatarUpload: avatarUpload,
        coverUpload: coverUpload,
      );
      final response = uploadPayload == null
          ? await _dio.patch(
              '$_apiBaseUrl/v1/static_assets/$assetId',
              data: payload,
              options: Options(headers: _buildHeaders()),
            )
          : await _dio.post(
              '$_apiBaseUrl/v1/static_assets/$assetId',
              data: uploadPayload
                ..fields.add(const MapEntry('_method', 'PATCH')),
              options: Options(
                headers: _buildHeaders(),
                contentType: 'multipart/form-data',
              ),
            );
      final dto = _responseDecoder.decodeStaticAssetItem(response.data);
      return _normalizeStaticAssetMediaUrls(dto).toDomain();
    } on DioException catch (error) {
      throw _wrapError(error, 'update static asset');
    }
  }

  @override
  Future<void> deleteStaticAsset(String assetId) async {
    try {
      await _dio.delete(
        '$_apiBaseUrl/v1/static_assets/$assetId',
        options: Options(headers: _buildHeaders()),
      );
    } on DioException catch (error) {
      throw _wrapError(error, 'delete static asset');
    }
  }

  @override
  Future<TenantAdminStaticAsset> restoreStaticAsset(String assetId) async {
    try {
      final response = await _dio.post(
        '$_apiBaseUrl/v1/static_assets/$assetId/restore',
        options: Options(headers: _buildHeaders()),
      );
      final dto = _responseDecoder.decodeStaticAssetItem(response.data);
      return _normalizeStaticAssetMediaUrls(dto).toDomain();
    } on DioException catch (error) {
      throw _wrapError(error, 'restore static asset');
    }
  }

  @override
  Future<void> forceDeleteStaticAsset(String assetId) async {
    try {
      await _dio.delete(
        '$_apiBaseUrl/v1/static_assets/$assetId/force_delete',
        options: Options(headers: _buildHeaders()),
      );
    } on DioException catch (error) {
      throw _wrapError(error, 'force delete static asset');
    }
  }

  @override
  Future<List<TenantAdminStaticProfileTypeDefinition>>
      fetchStaticProfileTypes() async {
    var page = 1;
    const pageSize = 100;
    var hasMore = true;
    final types = <TenantAdminStaticProfileTypeDefinition>[];

    while (hasMore) {
      final result = await fetchStaticProfileTypesPage(
        page: page,
        pageSize: pageSize,
      );
      types.addAll(result.items);
      hasMore = result.hasMore;
      page += 1;
    }

    return List<TenantAdminStaticProfileTypeDefinition>.unmodifiable(types);
  }

  @override
  Future<TenantAdminPagedResult<TenantAdminStaticProfileTypeDefinition>>
      fetchStaticProfileTypesPage({
    required int page,
    required int pageSize,
  }) async {
    try {
      final response = await _dio.get(
        '$_apiBaseUrl/v1/static_profile_types',
        queryParameters: {
          'page': page,
          'page_size': pageSize,
        },
        options: Options(headers: _buildHeaders()),
      );
      final dtos = _responseDecoder.decodeStaticProfileTypeList(response.data);
      return TenantAdminPagedResult<TenantAdminStaticProfileTypeDefinition>(
        items: dtos
            .map((dto) => dto.toDomain())
            .toList(growable: false),
        hasMore: tenantAdminResolveHasMore(
          rawResponse: response.data,
          requestedPage: page,
        ),
      );
    } on DioException catch (error) {
      throw _wrapError(error, 'load static profile types page');
    }
  }

  @override
  Future<TenantAdminStaticProfileTypeDefinition> createStaticProfileType({
    required String type,
    required String label,
    List<String> allowedTaxonomies = const [],
    required TenantAdminStaticProfileTypeCapabilities capabilities,
  }) async {
    try {
      final payload = _requestEncoder.encodeStaticProfileTypePayload(
        type: type,
        label: label,
        allowedTaxonomies: allowedTaxonomies,
        capabilities: capabilities,
      );
      final response = await _dio.post(
        '$_apiBaseUrl/v1/static_profile_types',
        data: payload,
        options: Options(headers: _buildHeaders()),
      );
      final dto = _responseDecoder.decodeStaticProfileTypeItem(response.data);
      return dto.toDomain();
    } on DioException catch (error) {
      throw _wrapError(error, 'create static profile type');
    }
  }

  @override
  Future<TenantAdminStaticProfileTypeDefinition> updateStaticProfileType({
    required String type,
    String? newType,
    String? label,
    List<String>? allowedTaxonomies,
    TenantAdminStaticProfileTypeCapabilities? capabilities,
  }) async {
    try {
      final encodedType = Uri.encodeComponent(type);
      final payload = _requestEncoder.encodeStaticProfileTypePayload(
        type: newType,
        label: label,
        allowedTaxonomies: allowedTaxonomies,
        capabilities: capabilities,
      );
      final response = await _dio.patch(
        '$_apiBaseUrl/v1/static_profile_types/$encodedType',
        data: payload,
        options: Options(headers: _buildHeaders()),
      );
      final dto = _responseDecoder.decodeStaticProfileTypeItem(response.data);
      return dto.toDomain();
    } on DioException catch (error) {
      throw _wrapError(error, 'update static profile type');
    }
  }

  @override
  Future<void> deleteStaticProfileType(String type) async {
    try {
      final encodedType = Uri.encodeComponent(type);
      await _dio.delete(
        '$_apiBaseUrl/v1/static_profile_types/$encodedType',
        options: Options(headers: _buildHeaders()),
      );
    } on DioException catch (error) {
      throw _wrapError(error, 'delete static profile type');
    }
  }

  TenantAdminStaticAssetDTO _normalizeStaticAssetMediaUrls(
    TenantAdminStaticAssetDTO dto,
  ) {
    return TenantAdminStaticAssetDTO(
      id: dto.id,
      profileType: dto.profileType,
      displayName: dto.displayName,
      slug: dto.slug,
      isActive: dto.isActive,
      taxonomyTerms: dto.taxonomyTerms,
      bio: dto.bio,
      content: dto.content,
      locationLat: dto.locationLat,
      locationLng: dto.locationLng,
      avatarUrl: _normalizeStaticAssetMediaUrl(dto.avatarUrl),
      coverUrl: _normalizeStaticAssetMediaUrl(dto.coverUrl),
    );
  }

  String? _normalizeStaticAssetMediaUrl(String? rawUrl) {
    final value = rawUrl?.trim();
    if (value == null || value.isEmpty) {
      return null;
    }

    final parsed = Uri.tryParse(value);
    if (parsed == null) {
      return value;
    }

    if (parsed.host.trim().isNotEmpty) {
      return parsed.toString();
    }

    final path = parsed.path.trim();
    final tenantOrigin = _resolveTenantOriginUri();

    if (path.startsWith('/')) {
      final canonical = tenantOrigin.resolve(path);
      return canonical
          .replace(
            query: parsed.hasQuery ? parsed.query : null,
            fragment: parsed.hasFragment ? parsed.fragment : null,
          )
          .toString();
    }

    return tenantOrigin.resolveUri(parsed).toString();
  }

  Uri _resolveTenantOriginUri() {
    final parsed = Uri.tryParse(_apiBaseUrl);
    if (parsed == null || parsed.host.trim().isEmpty) {
      throw Exception('Invalid tenant admin base URL: $_apiBaseUrl');
    }
    return parsed.replace(path: '/', query: null, fragment: null);
  }

  Exception _wrapError(DioException error, String label) {
    final validationFailure = tenantAdminTryResolveValidationFailure(error);
    if (validationFailure != null) {
      return validationFailure;
    }

    return tenantAdminWrapRepositoryError(error, label);
  }
}
