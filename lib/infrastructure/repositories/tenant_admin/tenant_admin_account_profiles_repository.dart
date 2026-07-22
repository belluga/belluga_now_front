import 'package:belluga_contact_channels/belluga_contact_channels.dart';
import 'package:belluga_now/domain/repositories/landlord_auth_repository_contract.dart';
import 'package:belluga_now/domain/repositories/tenant_admin_account_profiles_repository_contract.dart';
import 'package:belluga_now/domain/services/tenant_admin_tenant_scope_contract.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_account_profile.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_account_profile_candidate.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_location.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_media_upload.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_nested_group_member_mutation_result.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_nested_group_member_page.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_paged_result.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_poi_visual.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_profile_type.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_optional_text_value.dart';
import 'package:belluga_now/infrastructure/dal/dao/tenant_admin/tenant_admin_account_profiles_request_encoder.dart';
import 'package:belluga_now/infrastructure/dal/dao/tenant_admin/tenant_admin_media_form_data_builder.dart';
import 'package:belluga_now/infrastructure/dal/dto/tenant_admin/tenant_admin_account_profiles_response_decoder.dart';
import 'package:belluga_now/infrastructure/repositories/tenant_admin/tenant_admin_pagination_utils.dart';
import 'package:belluga_now/infrastructure/repositories/tenant_admin/support/tenant_admin_validation_failure_resolver.dart';
import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';

class TenantAdminAccountProfilesRepository
    extends TenantAdminAccountProfilesRepositoryContract
    with TenantAdminProfileTypesPaginationMixin {
  TenantAdminAccountProfilesRepository({
    Dio? dio,
    TenantAdminTenantScopeContract? tenantScope,
  }) : this._internal(dio ?? Dio(), tenantScope);

  TenantAdminAccountProfilesRepository._internal(
    this._dio, [
    this._tenantScope,
  ]);

  final Dio _dio;
  final TenantAdminTenantScopeContract? _tenantScope;
  final TenantAdminAccountProfilesResponseDecoder _responseDecoder =
      const TenantAdminAccountProfilesResponseDecoder();
  final TenantAdminAccountProfilesRequestEncoder _requestEncoder =
      const TenantAdminAccountProfilesRequestEncoder();
  final TenantAdminMediaFormDataBuilder _mediaFormDataBuilder =
      const TenantAdminMediaFormDataBuilder();
  int _accountProfileCacheBustSequence = 0;

  String get _apiBaseUrl =>
      (_tenantScope ?? GetIt.I.get<TenantAdminTenantScopeContract>())
          .selectedTenantAdminBaseUrl;

  Map<String, String> _buildHeaders() {
    final token = GetIt.I.get<LandlordAuthRepositoryContract>().token;
    return {'Authorization': 'Bearer $token', 'Accept': 'application/json'};
  }

  String _nextAccountProfileCacheBuster() {
    _accountProfileCacheBustSequence += 1;
    return '${DateTime.now().microsecondsSinceEpoch}'
        '-$_accountProfileCacheBustSequence';
  }

  @override
  Future<List<TenantAdminAccountProfile>> fetchAccountProfiles({
    TenantAdminAccountProfilesRepoString? accountId,
    TenantAdminAccountProfilesRepoBool? queryableOnly,
    TenantAdminAccountProfilesRepoString? excludeAccountProfileId,
  }) async {
    try {
      final queryParameters = _requestEncoder.encodeFetchAccountProfilesQuery(
        accountId: accountId?.value,
        queryableOnly: queryableOnly?.value ?? false,
        excludeAccountProfileId: excludeAccountProfileId?.value,
      );
      final response = await _dio.get(
        '$_apiBaseUrl/v1/account_profiles',
        queryParameters: queryParameters.isEmpty ? null : queryParameters,
        options: Options(headers: _buildHeaders()),
      );
      final dtos = _responseDecoder.decodeAccountProfileList(response.data);
      return dtos.map((dto) => dto.toDomain()).toList(growable: false);
    } on DioException catch (error) {
      throw _wrapError(error, 'load account profiles');
    }
  }

  @override
  Future<TenantAdminPagedResult<TenantAdminAccountProfile>>
  fetchAccountProfilesPage({
    required TenantAdminAccountProfilesRepoInt page,
    required TenantAdminAccountProfilesRepoInt pageSize,
    TenantAdminAccountProfilesRepoString? search,
    TenantAdminAccountProfilesRepoString? accountId,
    TenantAdminAccountProfilesRepoBool? queryableOnly,
    TenantAdminAccountProfilesRepoString? excludeAccountProfileId,
  }) async {
    try {
      final queryParameters = _requestEncoder.encodeFetchAccountProfilesQuery(
        accountId: accountId?.value,
        queryableOnly: queryableOnly?.value ?? false,
        excludeAccountProfileId: excludeAccountProfileId?.value,
        search: search?.value,
        page: page.value,
        pageSize: pageSize.value,
      );
      final response = await _dio.get(
        '$_apiBaseUrl/v1/account_profiles',
        queryParameters: queryParameters.isEmpty ? null : queryParameters,
        options: Options(headers: _buildHeaders()),
      );
      final rawResponse = response.data;
      final currentPage =
          tenantAdminReadPageValue(rawResponse, 'current_page') ??
          tenantAdminReadPageValue(rawResponse, 'page') ??
          page.value;
      final resolvedPageSize =
          tenantAdminReadPageValue(rawResponse, 'page_size') ??
          tenantAdminReadPageValue(rawResponse, 'per_page') ??
          pageSize.value;
      final dtos = _responseDecoder.decodeAccountProfileList(rawResponse);
      return tenantAdminPagedResultFromRaw(
        items: dtos.map((dto) => dto.toDomain()).toList(growable: false),
        hasMore: tenantAdminResolveHasMore(
          rawResponse: rawResponse,
          requestedPage: currentPage,
        ),
        currentPage: currentPage,
        pageSize: resolvedPageSize,
      );
    } on DioException catch (error) {
      throw _wrapError(error, 'load account profile candidates page');
    }
  }

  @override
  Future<TenantAdminAccountProfileCandidatePage>
  fetchAccountProfileCandidatesPage({
    required TenantAdminAccountProfileCandidateScope scope,
    required TenantAdminAccountProfilesRepoString search,
    required TenantAdminAccountProfilesRepoInt page,
    required TenantAdminAccountProfilesRepoInt pageSize,
    TenantAdminAccountProfilesRepoString? excludeAccountProfileId,
  }) async {
    try {
      final response = await _dio.get(
        '$_apiBaseUrl/v1/account_profiles/candidates',
        queryParameters: _requestEncoder
            .encodeFetchAccountProfileCandidatesQuery(
              scope: scope.wireValue,
              search: search.value,
              page: page.value,
              perPage: pageSize.value,
              excludeAccountProfileId: excludeAccountProfileId?.value,
            ),
        options: Options(headers: _buildHeaders()),
      );
      return _responseDecoder.decodeCandidatePage(response.data).toDomain();
    } on DioException catch (error) {
      throw _wrapError(error, 'load account profile candidates page');
    }
  }

  @override
  Future<TenantAdminPagedResult<TenantAdminAccountProfile>>
  fetchContactSourceCandidatesPage({
    required TenantAdminAccountProfilesRepoInt page,
    required TenantAdminAccountProfilesRepoInt pageSize,
    TenantAdminAccountProfilesRepoString? excludeAccountProfileId,
  }) async {
    try {
      final response = await _dio.get(
        '$_apiBaseUrl/v1/account_profiles/contact_sources',
        queryParameters: _requestEncoder
            .encodeFetchContactSourceCandidatesQuery(
              page: page.value,
              pageSize: pageSize.value,
              excludeAccountProfileId: excludeAccountProfileId?.value,
            ),
        options: Options(headers: _buildHeaders()),
      );
      final rawResponse = response.data;
      final currentPage =
          tenantAdminReadPageValue(rawResponse, 'current_page') ?? page.value;
      final resolvedPageSize =
          tenantAdminReadPageValue(rawResponse, 'per_page') ?? pageSize.value;
      final dtos = _responseDecoder.decodeAccountProfileList(rawResponse);
      return tenantAdminPagedResultFromRaw(
        items: dtos.map((dto) => dto.toDomain()).toList(growable: false),
        hasMore: tenantAdminResolveHasMore(
          rawResponse: rawResponse,
          requestedPage: currentPage,
        ),
        currentPage: currentPage,
        pageSize: resolvedPageSize,
      );
    } on DioException catch (error) {
      throw _wrapError(error, 'load contact source candidates page');
    }
  }

  @override
  Future<TenantAdminAccountProfile> fetchAccountProfile(
    TenantAdminAccountProfilesRepoString accountProfileId,
  ) async {
    try {
      final response = await _dio.get(
        '$_apiBaseUrl/v1/account_profiles/${accountProfileId.value}',
        queryParameters: {'_ts': _nextAccountProfileCacheBuster()},
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
    List<TenantAdminNestedProfileGroup> nestedProfileGroups =
        const <TenantAdminNestedProfileGroup>[],
    BellugaContactSourceMode contactMode = BellugaContactSourceMode.own,
    TenantAdminAccountProfilesRepoString? contactSourceAccountProfileId,
    List<BellugaContactChannelDraft> contactChannelDrafts =
        const <BellugaContactChannelDraft>[],
    BellugaContactBubbleSelectionMutation bubbleSelection =
        const BellugaContactBubbleSelectionMutation.omit(),
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
        nestedProfileGroups: nestedProfileGroups,
        contactMode: contactMode,
        contactSourceAccountProfileId: contactSourceAccountProfileId?.value,
        contactChannelDrafts: contactChannelDrafts,
        bubbleSelection: bubbleSelection,
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
    List<TenantAdminNestedProfileGroup>? nestedProfileGroups,
    BellugaContactSourceMode? contactMode,
    TenantAdminAccountProfilesRepoString? contactSourceAccountProfileId,
    List<BellugaContactChannelDraft>? contactChannelDrafts,
    BellugaContactBubbleSelectionMutation bubbleSelection =
        const BellugaContactBubbleSelectionMutation.omit(),
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
        nestedProfileGroups: nestedProfileGroups,
        contactMode: contactMode,
        contactSourceAccountProfileId: contactSourceAccountProfileId?.value,
        contactChannelDrafts: contactChannelDrafts,
        bubbleSelection: bubbleSelection,
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
  Future<TenantAdminNestedGroupMemberPage> fetchNestedGroupMembersPage({
    required TenantAdminAccountProfilesRepoString accountProfileId,
    required TenantAdminAccountProfilesRepoString groupId,
    TenantAdminAccountProfilesRepoInt? perPage,
    TenantAdminAccountProfilesRepoString? cursor,
  }) async {
    try {
      final response = await _dio.get(
        '$_apiBaseUrl/v1/account_profiles/${accountProfileId.value}'
        '/nested_profile_groups/${groupId.value}/members',
        queryParameters: _requestEncoder.encodeFetchNestedGroupMembersQuery(
          perPage: cursor == null ? perPage?.value : null,
          cursor: cursor?.value,
        ),
        options: Options(headers: _buildHeaders()),
      );
      return _responseDecoder
          .decodeNestedGroupMemberPage(response.data)
          .toDomain();
    } on DioException catch (error) {
      throw _wrapError(error, 'load nested group members page');
    }
  }

  @override
  Future<TenantAdminNestedGroupMemberPage> fetchAllNestedGroupMembers({
    required TenantAdminAccountProfilesRepoString accountProfileId,
    required TenantAdminAccountProfilesRepoString groupId,
  }) async {
    final items = <TenantAdminAccountProfileSelectionSummary>[];
    TenantAdminAccountProfilesRepoString? cursor;
    TenantAdminNestedGroupMemberPage? lastPage;

    do {
      final page = await fetchNestedGroupMembersPage(
        accountProfileId: accountProfileId,
        groupId: groupId,
        perPage: cursor == null
            ? (TenantAdminAccountProfilesRepoInt(defaultValue: 50)
              ..set(50))
            : null,
        cursor: cursor,
      );
      lastPage = page;
      items.addAll(page.items);
      final rawCursor = page.nextCursor;
      cursor = rawCursor == null || rawCursor.isEmpty
          ? null
          : (TenantAdminAccountProfilesRepoString(
              defaultValue: '',
              isRequired: true,
            )..parse(rawCursor));
    } while (cursor != null);

    return TenantAdminNestedGroupMemberPage(
      items: items,
      aggregateRevisionValue: lastPage.aggregateRevisionValue,
      nextCursorValue: TenantAdminOptionalTextValue(),
    );
  }

  @override
  Future<TenantAdminNestedGroupMemberMutationResult> patchNestedGroupMembers({
    required TenantAdminAccountProfilesRepoString accountProfileId,
    required TenantAdminAccountProfilesRepoString groupId,
    required TenantAdminAccountProfilesRepoInt aggregateRevision,
    List<TenantAdminAccountProfilesRepoString> addIds = const [],
    List<TenantAdminAccountProfilesRepoString> removeIds = const [],
  }) async {
    try {
      final response = await _dio.patch(
        '$_apiBaseUrl/v1/account_profiles/${accountProfileId.value}'
        '/nested_profile_groups/${groupId.value}/members',
        data: _requestEncoder.encodePatchNestedGroupMembers(
          aggregateRevision: aggregateRevision.value,
          addIds: addIds.map((entry) => entry.value).toList(growable: false),
          removeIds: removeIds
              .map((entry) => entry.value)
              .toList(growable: false),
        ),
        options: Options(headers: _buildHeaders()),
      );
      return _responseDecoder
          .decodeNestedGroupMemberMutationResult(response.data)
          .toDomain();
    } on DioException catch (error) {
      throw _wrapError(error, 'patch nested group members');
    }
  }

  @override
  Future<TenantAdminAccountProfile> updateAccountProfileGallery({
    required TenantAdminAccountProfilesRepoString accountProfileId,
    List<TenantAdminAccountProfileGalleryUpdateGroup> galleryGroups =
        const <TenantAdminAccountProfileGalleryUpdateGroup>[],
  }) async {
    try {
      final encoded = _requestEncoder.encodeUpdateAccountProfileGallery(
        galleryGroups,
      );
      final formData = _mediaFormDataBuilder.buildGalleryPayload(
        galleryGroups: encoded.galleryGroups,
        uploads: encoded.uploads,
      );

      final response = await _dio.post(
        '$_apiBaseUrl/v1/account_profiles/${accountProfileId.value}/gallery',
        data: formData,
        options: Options(
          headers: _buildHeaders(),
          contentType: 'multipart/form-data',
        ),
      );
      final dto = _responseDecoder.decodeAccountProfileItem(response.data);
      return dto.toDomain();
    } on DioException catch (error) {
      throw _wrapError(error, 'update account profile gallery');
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
        page: tenantAdminAccountProfilesRepoInt(page, defaultValue: 1),
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
  Future<TenantAdminProfileTypeDefinition> fetchProfileType(
    TenantAdminAccountProfilesRepoString profileType,
  ) async {
    final normalizedType = profileType.value.trim();
    if (normalizedType.isEmpty) {
      throw ArgumentError.value(
        profileType,
        'profileType',
        'Profile type must not be empty',
      );
    }

    try {
      final encodedType = Uri.encodeComponent(normalizedType);
      final response = await _dio.get(
        '$_apiBaseUrl/v1/account_profile_types/$encodedType',
        options: Options(headers: _buildHeaders()),
      );
      final dto = _responseDecoder.decodeProfileTypeItem(response.data);
      return dto.toDomain();
    } on DioException catch (error) {
      throw _wrapError(error, 'load profile type');
    }
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
        queryParameters: {'page': page.value, 'page_size': pageSize.value},
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
    TenantAdminAccountProfilesRepoString? pluralLabel,
    List<TenantAdminAccountProfilesRepoString> allowedTaxonomies = const [],
    required TenantAdminProfileTypeCapabilities capabilities,
  }) async {
    try {
      final response = await _dio.post(
        '$_apiBaseUrl/v1/account_profile_types',
        data: _requestEncoder.encodeCreateProfileType(
          type: type.value,
          label: label.value,
          pluralLabel: pluralLabel?.value,
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
  Future<TenantAdminProfileTypeDefinition> createProfileTypeWithVisual({
    required TenantAdminAccountProfilesRepoString type,
    required TenantAdminAccountProfilesRepoString label,
    TenantAdminAccountProfilesRepoString? pluralLabel,
    List<TenantAdminAccountProfilesRepoString> allowedTaxonomies = const [],
    required TenantAdminProfileTypeCapabilities capabilities,
    TenantAdminPoiVisual? visual,
    TenantAdminMediaUpload? typeAssetUpload,
  }) async {
    try {
      final payload = _requestEncoder.encodeCreateProfileType(
        type: type.value,
        label: label.value,
        pluralLabel: pluralLabel?.value,
        allowedTaxonomies: allowedTaxonomies
            .map((entry) => entry.value)
            .toList(growable: false),
        capabilities: capabilities,
        visual: visual,
        includeVisual: true,
      );
      final uploadPayload = _mediaFormDataBuilder.buildTypeAssetPayload(
        payload: payload,
        typeAssetUpload: typeAssetUpload,
      );
      final response = await _dio.post(
        '$_apiBaseUrl/v1/account_profile_types',
        data: uploadPayload ?? payload,
        options: uploadPayload == null
            ? Options(headers: _buildHeaders())
            : Options(
                headers: _buildHeaders(),
                contentType: 'multipart/form-data',
              ),
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
    TenantAdminAccountProfilesRepoString? pluralLabel,
    List<TenantAdminAccountProfilesRepoString>? allowedTaxonomies,
    TenantAdminProfileTypeCapabilities? capabilities,
  }) async {
    try {
      final encodedType = Uri.encodeComponent(type.value);
      final payload = _requestEncoder.encodeUpdateProfileType(
        newType: newType?.value,
        label: label?.value,
        pluralLabel: pluralLabel?.value,
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
  Future<TenantAdminProfileTypeDefinition> updateProfileTypeWithVisual({
    required TenantAdminAccountProfilesRepoString type,
    TenantAdminAccountProfilesRepoString? newType,
    TenantAdminAccountProfilesRepoString? label,
    TenantAdminAccountProfilesRepoString? pluralLabel,
    List<TenantAdminAccountProfilesRepoString>? allowedTaxonomies,
    TenantAdminProfileTypeCapabilities? capabilities,
    TenantAdminPoiVisual? visual,
    TenantAdminMediaUpload? typeAssetUpload,
    TenantAdminAccountProfilesRepoBool? removeTypeAsset,
  }) async {
    try {
      final encodedType = Uri.encodeComponent(type.value);
      final payload = _requestEncoder.encodeUpdateProfileType(
        newType: newType?.value,
        label: label?.value,
        pluralLabel: pluralLabel?.value,
        allowedTaxonomies: allowedTaxonomies
            ?.map((entry) => entry.value)
            .toList(growable: false),
        capabilities: capabilities,
        visual: visual,
        includeVisual: true,
        removeTypeAsset: removeTypeAsset?.value,
      );
      final uploadPayload = _mediaFormDataBuilder.buildTypeAssetPayload(
        payload: payload,
        typeAssetUpload: typeAssetUpload,
      );
      final response = uploadPayload == null
          ? await _dio.patch(
              '$_apiBaseUrl/v1/account_profile_types/$encodedType',
              data: payload,
              options: Options(headers: _buildHeaders()),
            )
          : await _dio.post(
              '$_apiBaseUrl/v1/account_profile_types/$encodedType',
              data: uploadPayload
                ..fields.add(const MapEntry('_method', 'PATCH')),
              options: Options(
                headers: _buildHeaders(),
                contentType: 'multipart/form-data',
              ),
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
    TenantAdminAccountProfilesRepoString type,
  ) async {
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
