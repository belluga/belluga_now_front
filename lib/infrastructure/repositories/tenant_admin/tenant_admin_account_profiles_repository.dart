import 'package:belluga_now/domain/repositories/landlord_auth_repository_contract.dart';
import 'package:belluga_now/domain/repositories/tenant_admin_account_profiles_repository_contract.dart';
import 'package:belluga_now/domain/services/tenant_admin_tenant_scope_contract.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_account_profile.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_location.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_media_upload.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_paged_result.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_profile_type.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_term.dart';
import 'package:belluga_now/infrastructure/dal/dao/tenant_admin/tenant_admin_account_profiles_request_encoder.dart';
import 'package:belluga_now/infrastructure/dal/dao/tenant_admin/tenant_admin_media_form_data_builder.dart';
import 'package:belluga_now/infrastructure/dal/dto/tenant_admin/tenant_admin_account_profiles_response_decoder.dart';
import 'package:belluga_now/infrastructure/repositories/tenant_admin/tenant_admin_pagination_utils.dart';
import 'package:belluga_now/infrastructure/repositories/tenant_admin/support/tenant_admin_validation_failure_resolver.dart';
import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';

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
    String? accountId,
  }) async {
    try {
      final response = await _dio.get(
        '$_apiBaseUrl/v1/account_profiles',
        queryParameters: accountId == null ? null : {'account_id': accountId},
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
    String accountProfileId,
  ) async {
    try {
      final response = await _dio.get(
        '$_apiBaseUrl/v1/account_profiles/$accountProfileId',
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
    required String accountId,
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
      final payload = _requestEncoder.encodeCreateAccountProfile(
        accountId: accountId,
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
        '$_apiBaseUrl/v1/account_profiles',
        data: uploadPayload ?? payload,
        options: Options(headers: _buildHeaders()),
      );
      final dto = _responseDecoder.decodeAccountProfileItem(response.data);
      return dto.toDomain();
    } on DioException catch (error) {
      throw _wrapError(error, 'create account profile');
    }
  }

  @override
  Future<TenantAdminAccountProfile> updateAccountProfile({
    required String accountProfileId,
    String? profileType,
    String? displayName,
    String? slug,
    TenantAdminLocation? location,
    List<TenantAdminTaxonomyTerm>? taxonomyTerms,
    String? bio,
    String? content,
    String? avatarUrl,
    String? coverUrl,
    bool? removeAvatar,
    bool? removeCover,
    TenantAdminMediaUpload? avatarUpload,
    TenantAdminMediaUpload? coverUpload,
  }) async {
    try {
      final payload = _requestEncoder.encodeUpdateAccountProfile(
        profileType: profileType,
        displayName: displayName,
        slug: slug,
        location: location,
        taxonomyTerms: taxonomyTerms,
        bio: bio,
        content: content,
        avatarUrl: avatarUrl,
        coverUrl: coverUrl,
        removeAvatar: removeAvatar,
        removeCover: removeCover,
      );
      final uploadPayload = _mediaFormDataBuilder.buildAvatarCoverPayload(
        payload: payload,
        avatarUpload: avatarUpload,
        coverUpload: coverUpload,
      );
      final response = uploadPayload == null
          ? await _dio.patch(
              '$_apiBaseUrl/v1/account_profiles/$accountProfileId',
              data: payload,
              options: Options(headers: _buildHeaders()),
            )
          : await _dio.post(
              '$_apiBaseUrl/v1/account_profiles/$accountProfileId',
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
  Future<void> deleteAccountProfile(String accountProfileId) async {
    try {
      await _dio.delete(
        '$_apiBaseUrl/v1/account_profiles/$accountProfileId',
        options: Options(headers: _buildHeaders()),
      );
    } on DioException catch (error) {
      throw _wrapError(error, 'delete account profile');
    }
  }

  @override
  Future<TenantAdminAccountProfile> restoreAccountProfile(
    String accountProfileId,
  ) async {
    try {
      final response = await _dio.post(
        '$_apiBaseUrl/v1/account_profiles/$accountProfileId/restore',
        options: Options(headers: _buildHeaders()),
      );
      final dto = _responseDecoder.decodeAccountProfileItem(response.data);
      return dto.toDomain();
    } on DioException catch (error) {
      throw _wrapError(error, 'restore account profile');
    }
  }

  @override
  Future<void> forceDeleteAccountProfile(String accountProfileId) async {
    try {
      await _dio.post(
        '$_apiBaseUrl/v1/account_profiles/$accountProfileId/force_delete',
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
        page: page,
        pageSize: pageSize,
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
    required int page,
    required int pageSize,
  }) async {
    try {
      final response = await _dio.get(
        '$_apiBaseUrl/v1/account_profile_types',
        queryParameters: {
          'page': page,
          'page_size': pageSize,
        },
        options: Options(headers: _buildHeaders()),
      );
      final dtos = _responseDecoder.decodeProfileTypeList(response.data);
      return TenantAdminPagedResult<TenantAdminProfileTypeDefinition>(
        items: dtos.map((dto) => dto.toDomain()).toList(growable: false),
        hasMore: tenantAdminResolveHasMore(
          rawResponse: response.data,
          requestedPage: page,
        ),
      );
    } on DioException catch (error) {
      throw _wrapError(error, 'load profile types page');
    }
  }

  @override
  Future<TenantAdminProfileTypeDefinition> createProfileType({
    required String type,
    required String label,
    List<String> allowedTaxonomies = const [],
    required TenantAdminProfileTypeCapabilities capabilities,
  }) async {
    try {
      final response = await _dio.post(
        '$_apiBaseUrl/v1/account_profile_types',
        data: _requestEncoder.encodeCreateProfileType(
          type: type,
          label: label,
          allowedTaxonomies: allowedTaxonomies,
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
  Future<TenantAdminProfileTypeDefinition> updateProfileType({
    required String type,
    String? newType,
    String? label,
    List<String>? allowedTaxonomies,
    TenantAdminProfileTypeCapabilities? capabilities,
  }) async {
    try {
      final encodedType = Uri.encodeComponent(type);
      final payload = _requestEncoder.encodeUpdateProfileType(
        newType: newType,
        label: label,
        allowedTaxonomies: allowedTaxonomies,
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
  Future<void> deleteProfileType(String type) async {
    try {
      final encodedType = Uri.encodeComponent(type);
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
