import 'package:belluga_now/domain/repositories/landlord_auth_repository_contract.dart';
import 'package:belluga_now/domain/repositories/tenant_admin_account_profiles_repository_contract.dart';
import 'package:belluga_now/domain/services/tenant_admin_tenant_scope_contract.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_account_profile.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_location.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_media_upload.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_paged_result.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_poi_visual.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_profile_type.dart';
import 'package:belluga_now/infrastructure/dal/dao/tenant_admin/tenant_admin_account_profiles_request_encoder.dart';
import 'package:belluga_now/infrastructure/dal/dao/tenant_admin/tenant_admin_media_form_data_builder.dart';
import 'package:belluga_now/infrastructure/dal/dto/tenant_admin/tenant_admin_account_profiles_response_decoder.dart';
import 'package:belluga_now/infrastructure/repositories/tenant_admin/tenant_admin_pagination_utils.dart';
import 'package:belluga_now/infrastructure/repositories/tenant_admin/support/tenant_admin_validation_failure_resolver.dart';
import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_terms.dart';

class TenantAdminAccountProfilesRepository
    with TenantAdminProfileTypesPaginationMixin
    implements TenantAdminAccountProfilesRepositoryContract {
  TenantAdminAccountProfilesRepository({
    Dio? dio,
    TenantAdminTenantScopeContract? tenantScope,
  })  : _dio = dio ?? Dio(),
        _tenantScope = tenantScope;

  final Dio _dio;
  final TenantAdminTenantScopeContract? _tenantScope;
  final TenantAdminAccountProfilesResponseDecoder _responseDecoder =
      const TenantAdminAccountProfilesResponseDecoder();
  final TenantAdminAccountProfilesRequestEncoder _requestEncoder =
      const TenantAdminAccountProfilesRequestEncoder();
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
  Future<List<TenantAdminAccountProfile>> fetchAccountProfiles({
    TenantAdminAccountProfilesRepoString? accountId,
  }) async {
    try {
      final response = await _dio.get(
        '$_apiBaseUrl/v1/account_profiles',
        queryParameters:
            accountId == null ? null : {'account_id': accountId.value},
        options: Options(headers: _buildHeaders()),
      );
      final dtos = _responseDecoder.decodeAccountProfileList(response.data);
      return dtos.map((dto) => dto.toDomain()).toList(growable: false);
    } on DioException catch (error) {
      throw _wrapError(error, 'load account profiles');
    }
  }

  @override
  Future<TenantAdminAccountProfile> fetchAccountProfile(
    TenantAdminAccountProfilesRepoString accountProfileId,
  ) async {
    try {
      final response = await _dio.get(
        '$_apiBaseUrl/v1/account_profiles/${accountProfileId.value}',
        options: Options(headers: _buildHeaders()),
      );
      final dto = _responseDecoder.decodeAccountProfileItem(response.data);
      return dto.toDomain();
    } on DioException catch (error) {
      throw _wrapError(error, 'load account profile');
    }
  }

  @override
  Future<TenantAdminAccountProfile> createAccountProfile({
    required TenantAdminAccountProfilesRepoString accountId,
    required TenantAdminAccountProfilesRepoString profileType,
    required TenantAdminAccountProfilesRepoString displayName,
    TenantAdminLocation? location,
    TenantAdminTaxonomyTerms taxonomyTerms =
        const TenantAdminTaxonomyTerms.empty(),
    TenantAdminAccountProfilesRepoString? bio,
    TenantAdminAccountProfilesRepoString? content,
    TenantAdminAccountProfilesRepoString? avatarUrl,
    TenantAdminAccountProfilesRepoString? coverUrl,
    TenantAdminMediaUpload? avatarUpload,
    TenantAdminMediaUpload? coverUpload,
  }) async {
    try {
      final payload = _requestEncoder.encodeCreateAccountProfile(
        accountId: accountId.value,
        profileType: profileType.value,
        displayName: displayName.value,
        location: location,
        taxonomyTerms: taxonomyTerms,
        bio: bio?.value,
        content: content?.value,
        avatarUrl: avatarUrl?.value,
        coverUrl: coverUrl?.value,
      );
      final uploadPayload = _mediaFormDataBuilder.buildAvatarCoverPayload(
        payload: payload,
        avatarUpload: avatarUpload,
        coverUpload: coverUpload,
      );
      final response = await _dio.post(
        '$_apiBaseUrl/v1/account_profiles',
        data: uploadPayload ?? payload,
        options: uploadPayload == null
            ? Options(headers: _buildHeaders())
            : Options(
                headers: _buildHeaders(),
                contentType: 'multipart/form-data',
              ),
      );
      final dto = _responseDecoder.decodeAccountProfileItem(response.data);
      return dto.toDomain();
    } on DioException catch (error) {
      throw _wrapError(error, 'create account profile');
    }
  }

  @override
  Future<TenantAdminAccountProfile> updateAccountProfile({
    required TenantAdminAccountProfilesRepoString accountProfileId,
    TenantAdminAccountProfilesRepoString? profileType,
    TenantAdminAccountProfilesRepoString? displayName,
    TenantAdminAccountProfilesRepoString? slug,
    TenantAdminLocation? location,
    TenantAdminTaxonomyTerms? taxonomyTerms,
    TenantAdminAccountProfilesRepoString? bio,
    TenantAdminAccountProfilesRepoString? content,
    TenantAdminAccountProfilesRepoString? avatarUrl,
    TenantAdminAccountProfilesRepoString? coverUrl,
    TenantAdminAccountProfilesRepoBool? removeAvatar,
    TenantAdminAccountProfilesRepoBool? removeCover,
    TenantAdminMediaUpload? avatarUpload,
    TenantAdminMediaUpload? coverUpload,
  }) async {
    try {
      final payload = _requestEncoder.encodeUpdateAccountProfile(
        profileType: profileType?.value,
        displayName: displayName?.value,
        slug: slug?.value,
        location: location,
        taxonomyTerms: taxonomyTerms,
        bio: bio?.value,
        content: content?.value,
        avatarUrl: avatarUrl?.value,
        coverUrl: coverUrl?.value,
        removeAvatar: removeAvatar?.value,
        removeCover: removeCover?.value,
      );
      final uploadPayload = _mediaFormDataBuilder.buildAvatarCoverPayload(
        payload: payload,
        avatarUpload: avatarUpload,
        coverUpload: coverUpload,
      );
      final response = uploadPayload == null
          ? await _dio.patch(
              '$_apiBaseUrl/v1/account_profiles/${accountProfileId.value}',
              data: payload,
              options: Options(headers: _buildHeaders()),
            )
          : await _dio.post(
              '$_apiBaseUrl/v1/account_profiles/${accountProfileId.value}',
              data: uploadPayload
                ..fields.add(const MapEntry('_method', 'PATCH')),
              options: Options(
                headers: _buildHeaders(),
                contentType: 'multipart/form-data',
              ),
            );
      final dto = _responseDecoder.decodeAccountProfileItem(response.data);
      return dto.toDomain();
    } on DioException catch (error) {
      throw _wrapError(error, 'update account profile');
    }
  }

  @override
  Future<void> deleteAccountProfile(
    TenantAdminAccountProfilesRepoString accountProfileId,
  ) async {
    try {
      await _dio.delete(
        '$_apiBaseUrl/v1/account_profiles/${accountProfileId.value}',
        options: Options(headers: _buildHeaders()),
      );
    } on DioException catch (error) {
      throw _wrapError(error, 'delete account profile');
    }
  }

  @override
  Future<TenantAdminAccountProfile> restoreAccountProfile(
    TenantAdminAccountProfilesRepoString accountProfileId,
  ) async {
    try {
      final response = await _dio.post(
        '$_apiBaseUrl/v1/account_profiles/${accountProfileId.value}/restore',
        options: Options(headers: _buildHeaders()),
      );
      final dto = _responseDecoder.decodeAccountProfileItem(response.data);
      return dto.toDomain();
    } on DioException catch (error) {
      throw _wrapError(error, 'restore account profile');
    }
  }

  @override
  Future<void> forceDeleteAccountProfile(
    TenantAdminAccountProfilesRepoString accountProfileId,
  ) async {
    try {
      await _dio.post(
        '$_apiBaseUrl/v1/account_profiles/${accountProfileId.value}/force_delete',
        options: Options(headers: _buildHeaders()),
      );
    } on DioException catch (error) {
      throw _wrapError(error, 'force delete account profile');
    }
  }

  @override
  Future<List<TenantAdminProfileTypeDefinition>> fetchProfileTypes() async {
    var page = 1;
    const pageSize = 100;
    var hasMore = true;
    final types = <TenantAdminProfileTypeDefinition>[];

    while (hasMore) {
      final result = await fetchProfileTypesPage(
        page: tenantAdminAccountProfilesRepoInt(
          page,
          defaultValue: 1,
        ),
        pageSize: tenantAdminAccountProfilesRepoInt(
          pageSize,
          defaultValue: pageSize,
        ),
      );
      types.addAll(result.items);
      hasMore = result.hasMore;
      page += 1;
    }

    return List<TenantAdminProfileTypeDefinition>.unmodifiable(types);
  }

  @override
  Future<TenantAdminPagedResult<TenantAdminProfileTypeDefinition>>
      fetchProfileTypesPage({
    required TenantAdminAccountProfilesRepoInt page,
    required TenantAdminAccountProfilesRepoInt pageSize,
  }) async {
    try {
      final response = await _dio.get(
        '$_apiBaseUrl/v1/account_profile_types',
        queryParameters: {
          'page': page.value,
          'page_size': pageSize.value,
        },
        options: Options(headers: _buildHeaders()),
      );
      final dtos = _responseDecoder.decodeProfileTypeList(response.data);
      return tenantAdminPagedResultFromRaw(
        items: dtos.map((dto) => dto.toDomain()).toList(growable: false),
        hasMore: tenantAdminResolveHasMore(
          rawResponse: response.data,
          requestedPage: page.value,
        ),
      );
    } on DioException catch (error) {
      throw _wrapError(error, 'load profile types page');
    }
  }

  @override
  Future<TenantAdminProfileTypeDefinition> createProfileType({
    required TenantAdminAccountProfilesRepoString type,
    required TenantAdminAccountProfilesRepoString label,
    List<TenantAdminAccountProfilesRepoString> allowedTaxonomies = const [],
    required TenantAdminProfileTypeCapabilities capabilities,
  }) async {
    try {
      final response = await _dio.post(
        '$_apiBaseUrl/v1/account_profile_types',
        data: _requestEncoder.encodeCreateProfileType(
          type: type.value,
          label: label.value,
          allowedTaxonomies: allowedTaxonomies
              .map((entry) => entry.value)
              .toList(growable: false),
          capabilities: capabilities,
        ),
        options: Options(headers: _buildHeaders()),
      );
      final dto = _responseDecoder.decodeProfileTypeItem(response.data);
      return dto.toDomain();
    } on DioException catch (error) {
      throw _wrapError(error, 'create profile type');
    }
  }

  @override
  Future<TenantAdminProfileTypeDefinition> createProfileTypeWithPoiVisual({
    required TenantAdminAccountProfilesRepoString type,
    required TenantAdminAccountProfilesRepoString label,
    List<TenantAdminAccountProfilesRepoString> allowedTaxonomies = const [],
    required TenantAdminProfileTypeCapabilities capabilities,
    TenantAdminPoiVisual? poiVisual,
  }) async {
    try {
      final response = await _dio.post(
        '$_apiBaseUrl/v1/account_profile_types',
        data: _requestEncoder.encodeCreateProfileType(
          type: type.value,
          label: label.value,
          allowedTaxonomies: allowedTaxonomies
              .map((entry) => entry.value)
              .toList(growable: false),
          capabilities: capabilities,
          poiVisual: poiVisual,
          includePoiVisual: true,
        ),
        options: Options(headers: _buildHeaders()),
      );
      final dto = _responseDecoder.decodeProfileTypeItem(response.data);
      return dto.toDomain();
    } on DioException catch (error) {
      throw _wrapError(error, 'create profile type');
    }
  }

  @override
  Future<TenantAdminProfileTypeDefinition> updateProfileType({
    required TenantAdminAccountProfilesRepoString type,
    TenantAdminAccountProfilesRepoString? newType,
    TenantAdminAccountProfilesRepoString? label,
    List<TenantAdminAccountProfilesRepoString>? allowedTaxonomies,
    TenantAdminProfileTypeCapabilities? capabilities,
  }) async {
    try {
      final encodedType = Uri.encodeComponent(type.value);
      final payload = _requestEncoder.encodeUpdateProfileType(
        newType: newType?.value,
        label: label?.value,
        allowedTaxonomies: allowedTaxonomies
            ?.map((entry) => entry.value)
            .toList(growable: false),
        capabilities: capabilities,
      );
      final response = await _dio.patch(
        '$_apiBaseUrl/v1/account_profile_types/$encodedType',
        data: payload,
        options: Options(headers: _buildHeaders()),
      );
      final dto = _responseDecoder.decodeProfileTypeItem(response.data);
      return dto.toDomain();
    } on DioException catch (error) {
      throw _wrapError(error, 'update profile type');
    }
  }

  @override
  Future<TenantAdminProfileTypeDefinition> updateProfileTypeWithPoiVisual({
    required TenantAdminAccountProfilesRepoString type,
    TenantAdminAccountProfilesRepoString? newType,
    TenantAdminAccountProfilesRepoString? label,
    List<TenantAdminAccountProfilesRepoString>? allowedTaxonomies,
    TenantAdminProfileTypeCapabilities? capabilities,
    TenantAdminPoiVisual? poiVisual,
  }) async {
    try {
      final encodedType = Uri.encodeComponent(type.value);
      final payload = _requestEncoder.encodeUpdateProfileType(
        newType: newType?.value,
        label: label?.value,
        allowedTaxonomies: allowedTaxonomies
            ?.map((entry) => entry.value)
            .toList(growable: false),
        capabilities: capabilities,
        poiVisual: poiVisual,
        includePoiVisual: true,
      );
      final response = await _dio.patch(
        '$_apiBaseUrl/v1/account_profile_types/$encodedType',
        data: payload,
        options: Options(headers: _buildHeaders()),
      );
      final dto = _responseDecoder.decodeProfileTypeItem(response.data);
      return dto.toDomain();
    } on DioException catch (error) {
      throw _wrapError(error, 'update profile type');
    }
  }

  @override
  Future<TenantAdminAccountProfilesRepoInt>
      fetchProfileTypeMapPoiProjectionImpact({
    required TenantAdminAccountProfilesRepoString type,
  }) async {
    try {
      final encodedType = Uri.encodeComponent(type.value);
      final response = await _dio.get(
        '$_apiBaseUrl/v1/account_profile_types/$encodedType/map_poi_projection_impact',
        options: Options(headers: _buildHeaders()),
      );
      return tenantAdminAccountProfilesRepoInt(
        _responseDecoder.decodeProjectionImpactCount(response.data),
        defaultValue: 0,
      );
    } on DioException catch (error) {
      throw _wrapError(error, 'load profile type projection impact');
    }
  }

  @override
  Future<void> deleteProfileType(
      TenantAdminAccountProfilesRepoString type) async {
    try {
      final encodedType = Uri.encodeComponent(type.value);
      await _dio.delete(
        '$_apiBaseUrl/v1/account_profile_types/$encodedType',
        options: Options(headers: _buildHeaders()),
      );
    } on DioException catch (error) {
      throw _wrapError(error, 'delete profile type');
    }
  }

  Exception _wrapError(DioException error, String label) {
    final validationFailure = tenantAdminTryResolveValidationFailure(error);
    if (validationFailure != null) {
      return validationFailure;
    }
    return tenantAdminWrapRepositoryError(error, label);
  }
}
