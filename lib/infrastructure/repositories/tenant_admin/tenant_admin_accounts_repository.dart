import 'package:belluga_now/domain/repositories/landlord_auth_repository_contract.dart';
import 'package:belluga_now/domain/repositories/tenant_admin_accounts_repository_contract.dart';
import 'package:belluga_now/domain/services/tenant_admin_tenant_scope_contract.dart';
import 'package:belluga_now/domain/tenant_admin/ownership_state.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_account.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_account_onboarding_result.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_document.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_location.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_media_upload.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_paged_accounts_result.dart';
import 'package:belluga_now/infrastructure/dal/dao/tenant_admin/tenant_admin_accounts_request_encoder.dart';
import 'package:belluga_now/infrastructure/dal/dao/tenant_admin/tenant_admin_media_form_data_builder.dart';
import 'package:belluga_now/infrastructure/dal/dao/tenant_admin/tenant_admin_pagination_decoder.dart';
import 'package:belluga_now/infrastructure/dal/dto/tenant_admin/tenant_admin_account_dto.dart';
import 'package:belluga_now/infrastructure/dal/dto/tenant_admin/tenant_admin_accounts_response_decoder.dart';
import 'package:belluga_now/infrastructure/repositories/tenant_admin/support/tenant_admin_validation_failure_resolver.dart';
import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_terms.dart';

class TenantAdminAccountsRepository
    with TenantAdminAccountsRepositoryPaginationMixin
    implements TenantAdminAccountsRepositoryContract {
  TenantAdminAccountsRepository({
    Dio? dio,
    TenantAdminTenantScopeContract? tenantScope,
  })  : _dio = dio ?? Dio(),
        _tenantScope = tenantScope;

  final Dio _dio;
  final TenantAdminTenantScopeContract? _tenantScope;
  final TenantAdminAccountsResponseDecoder _responseDecoder =
      const TenantAdminAccountsResponseDecoder();
  final TenantAdminAccountsRequestEncoder _requestEncoder =
      const TenantAdminAccountsRequestEncoder();
  final TenantAdminMediaFormDataBuilder _mediaFormDataBuilder =
      const TenantAdminMediaFormDataBuilder();
  final TenantAdminPaginationDecoder _paginationDecoder =
      const TenantAdminPaginationDecoder();

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
  Future<List<TenantAdminAccount>> fetchAccounts() async {
    var page = 1;
    const pageSize = 100;
    final accounts = <TenantAdminAccount>[];
    var hasMore = true;

    while (hasMore) {
      final pageResult = await fetchAccountsPage(
        page: TenantAdminAccountsRepositoryContractPrimInt.fromRaw(
          page,
          defaultValue: 1,
        ),
        pageSize: TenantAdminAccountsRepositoryContractPrimInt.fromRaw(
          pageSize,
          defaultValue: pageSize,
        ),
      );
      accounts.addAll(pageResult.accounts);
      hasMore = pageResult.hasMore;
      page += 1;
    }

    return List<TenantAdminAccount>.unmodifiable(accounts);
  }

  @override
  Future<TenantAdminPagedAccountsResult> fetchAccountsPage({
    required TenantAdminAccountsRepositoryContractPrimInt page,
    required TenantAdminAccountsRepositoryContractPrimInt pageSize,
    TenantAdminOwnershipState? ownershipState,
    TenantAdminAccountsRepositoryContractPrimString? searchQuery,
  }) async {
    return _fetchFilteredAccountsPage(
      page: page,
      pageSize: pageSize,
      ownershipState: ownershipState,
      searchQuery: searchQuery,
    );
  }

  Future<TenantAdminPagedAccountsResult> _fetchFilteredAccountsPage({
    required TenantAdminAccountsRepositoryContractPrimInt page,
    required TenantAdminAccountsRepositoryContractPrimInt pageSize,
    TenantAdminOwnershipState? ownershipState,
    TenantAdminAccountsRepositoryContractPrimString? searchQuery,
  }) async {
    final normalizedSearch = searchQuery?.value.trim() ?? '';
    try {
      final response = await _dio.get(
        '$_apiBaseUrl/v1/accounts',
        queryParameters: {
          'page': page.value,
          'per_page': pageSize.value,
          if (ownershipState != null)
            'ownership_state': ownershipState.apiValue,
          if (normalizedSearch.isNotEmpty) 'search': normalizedSearch,
        },
        options: Options(headers: _buildHeaders()),
      );
      final dtos = _responseDecoder.decodeAccountList(response.data);
      final currentPage = _extractCurrentPage(
            rawResponse: response.data,
            fallback: page.value,
          ) ??
          page.value;
      final lastPage = _extractLastPage(
            rawResponse: response.data,
            fallback: page.value,
          ) ??
          currentPage;
      final hasMore = currentPage < lastPage;
      return tenantAdminPagedAccountsResultFromRaw(
        accounts: dtos
            .map(_normalizeAccountMediaUrls)
            .map((dto) => dto.toDomain())
            .toList(growable: false),
        hasMore: hasMore,
      );
    } on DioException catch (error) {
      throw _wrapError(error, 'load accounts page');
    }
  }

  @override
  Future<TenantAdminAccount> fetchAccountBySlug(
    TenantAdminAccountsRepositoryContractPrimString accountSlug,
  ) async {
    final loaded = findLoadedAccount(accountSlug: accountSlug);
    if (loaded != null) {
      return loaded;
    }
    try {
      final response = await _dio.get(
        '$_apiBaseUrl/v1/accounts/${accountSlug.value}',
        options: Options(headers: _buildHeaders()),
      );
      final dto = _responseDecoder.decodeAccountItem(response.data);
      final account = _normalizeAccountMediaUrls(dto).toDomain();
      _upsertLoadedAccount(account);
      return account;
    } on DioException catch (error) {
      throw _wrapError(error, 'load account');
    }
  }

  @override
  Future<TenantAdminAccount> createAccount({
    required TenantAdminAccountsRepositoryContractPrimString name,
    TenantAdminDocument? document,
    required TenantAdminOwnershipState ownershipState,
    TenantAdminAccountsRepositoryContractPrimString? organizationId,
  }) async {
    final payload = _requestEncoder.encodeCreateAccount(
      name: name.value,
      ownershipState: ownershipState,
      organizationId: organizationId?.value,
      document: document,
    );
    try {
      final response = await _dio.post(
        '$_apiBaseUrl/v1/accounts',
        data: payload,
        options: Options(headers: _buildHeaders()),
      );
      final dto = _responseDecoder.decodeCreateAccountItem(response.data);
      final created = _normalizeAccountMediaUrls(dto).toDomain();
      _appendLoadedAccount(created);
      return created;
    } on DioException catch (error) {
      throw _wrapError(error, 'create account');
    }
  }

  @override
  Future<TenantAdminAccountOnboardingResult> createAccountOnboarding({
    required TenantAdminAccountsRepositoryContractPrimString name,
    required TenantAdminOwnershipState ownershipState,
    required TenantAdminAccountsRepositoryContractPrimString profileType,
    TenantAdminLocation? location,
    TenantAdminTaxonomyTerms taxonomyTerms =
        const TenantAdminTaxonomyTerms.empty(),
    TenantAdminAccountsRepositoryContractPrimString? bio,
    TenantAdminAccountsRepositoryContractPrimString? content,
    TenantAdminMediaUpload? avatarUpload,
    TenantAdminMediaUpload? coverUpload,
  }) async {
    try {
      final payload = _requestEncoder.encodeCreateOnboarding(
        name: name.value,
        ownershipState: ownershipState,
        profileType: profileType.value,
        location: location,
        taxonomyTerms: taxonomyTerms,
        bio: bio?.value,
        content: content?.value,
      );

      final uploadPayload = _mediaFormDataBuilder.buildAvatarCoverPayload(
        payload: payload,
        avatarUpload: avatarUpload,
        coverUpload: coverUpload,
      );

      final response = await _dio.post(
        '$_apiBaseUrl/v1/account_onboardings',
        data: uploadPayload ?? payload,
        options: uploadPayload == null
            ? Options(headers: _buildHeaders())
            : Options(
                headers: _buildHeaders(),
                contentType: 'multipart/form-data',
              ),
      );
      final onboardingData = _responseDecoder.decodeOnboarding(response.data);
      final account =
          _normalizeAccountMediaUrls(onboardingData.account).toDomain();
      final accountProfile = onboardingData.accountProfile.toDomain();
      _appendLoadedAccount(account);
      return TenantAdminAccountOnboardingResult(
        account: account,
        accountProfile: accountProfile,
      );
    } on DioException catch (error) {
      throw _wrapError(error, 'create account onboarding');
    }
  }

  @override
  Future<TenantAdminAccount> updateAccount({
    required TenantAdminAccountsRepositoryContractPrimString accountSlug,
    TenantAdminAccountsRepositoryContractPrimString? name,
    TenantAdminAccountsRepositoryContractPrimString? slug,
    TenantAdminDocument? document,
    TenantAdminOwnershipState? ownershipState,
  }) async {
    try {
      final payload = _requestEncoder.encodeUpdateAccount(
        name: name?.value,
        slug: slug?.value,
        document: document,
        ownershipState: ownershipState,
      );
      final response = await _dio.patch(
        '$_apiBaseUrl/v1/accounts/${accountSlug.value}',
        data: payload,
        options: Options(headers: _buildHeaders()),
      );
      final dto = _responseDecoder.decodeAccountItem(response.data);
      final updated = _normalizeAccountMediaUrls(dto).toDomain();
      _upsertLoadedAccount(updated);
      return updated;
    } on DioException catch (error) {
      throw _wrapError(error, 'update account');
    }
  }

  @override
  Future<void> deleteAccount(
    TenantAdminAccountsRepositoryContractPrimString accountSlug,
  ) async {
    try {
      await _dio.delete(
        '$_apiBaseUrl/v1/accounts/${accountSlug.value}',
        options: Options(headers: _buildHeaders()),
      );
      _removeLoadedAccountBySlug(accountSlug.value);
    } on DioException catch (error) {
      throw _wrapError(error, 'delete account');
    }
  }

  @override
  Future<TenantAdminAccount> restoreAccount(
    TenantAdminAccountsRepositoryContractPrimString accountSlug,
  ) async {
    try {
      final response = await _dio.post(
        '$_apiBaseUrl/v1/accounts/${accountSlug.value}/restore',
        options: Options(headers: _buildHeaders()),
      );
      final dto = _responseDecoder.decodeAccountItem(response.data);
      final restored = _normalizeAccountMediaUrls(dto).toDomain();
      _upsertLoadedAccount(restored);
      return restored;
    } on DioException catch (error) {
      throw _wrapError(error, 'restore account');
    }
  }

  @override
  Future<void> forceDeleteAccount(
    TenantAdminAccountsRepositoryContractPrimString accountSlug,
  ) async {
    try {
      await _dio.post(
        '$_apiBaseUrl/v1/accounts/${accountSlug.value}/force_delete',
        options: Options(headers: _buildHeaders()),
      );
      _removeLoadedAccountBySlug(accountSlug.value);
    } on DioException catch (error) {
      throw _wrapError(error, 'force delete account');
    }
  }

  void _appendLoadedAccount(TenantAdminAccount account) {
    final currentAccounts = accountsStreamValue.value;
    if (currentAccounts == null) {
      accountsStreamValue.addValue(
        List<TenantAdminAccount>.unmodifiable(<TenantAdminAccount>[account]),
      );
      return;
    }
    final nextAccounts = <TenantAdminAccount>[
      ...currentAccounts,
      account,
    ];
    accountsStreamValue.addValue(
      List<TenantAdminAccount>.unmodifiable(nextAccounts),
    );
  }

  void _upsertLoadedAccount(TenantAdminAccount account) {
    final currentAccounts = accountsStreamValue.value;
    if (currentAccounts == null) {
      accountsStreamValue.addValue(
        List<TenantAdminAccount>.unmodifiable(<TenantAdminAccount>[account]),
      );
      return;
    }
    final nextAccounts = List<TenantAdminAccount>.from(currentAccounts);
    final index = nextAccounts.indexWhere((entry) => entry.id == account.id);
    if (index >= 0) {
      nextAccounts[index] = account;
      accountsStreamValue.addValue(
        List<TenantAdminAccount>.unmodifiable(nextAccounts),
      );
      return;
    }
    nextAccounts.add(account);
    accountsStreamValue.addValue(
      List<TenantAdminAccount>.unmodifiable(nextAccounts),
    );
  }

  void _removeLoadedAccountBySlug(String accountSlug) {
    final currentAccounts = accountsStreamValue.value;
    if (currentAccounts == null) {
      return;
    }
    final nextAccounts = List<TenantAdminAccount>.from(currentAccounts);
    final beforeCount = nextAccounts.length;
    nextAccounts.removeWhere((entry) => entry.slug == accountSlug);
    if (nextAccounts.length != beforeCount) {
      accountsStreamValue.addValue(
        List<TenantAdminAccount>.unmodifiable(nextAccounts),
      );
    }
  }

  int? _extractCurrentPage({
    required Object? rawResponse,
    int? fallback,
  }) {
    return _paginationDecoder.readPageValue(rawResponse, 'current_page') ??
        _paginationDecoder.readPageValue(
          _paginationDecoder.extractMetaNode(rawResponse),
          'current_page',
        ) ??
        fallback;
  }

  int? _extractLastPage({
    required Object? rawResponse,
    int? fallback,
  }) {
    return _paginationDecoder.readPageValue(rawResponse, 'last_page') ??
        _paginationDecoder.readPageValue(
          _paginationDecoder.extractMetaNode(rawResponse),
          'last_page',
        ) ??
        fallback;
  }

  TenantAdminAccountDTO _normalizeAccountMediaUrls(TenantAdminAccountDTO dto) {
    return TenantAdminAccountDTO(
      id: dto.id,
      name: dto.name,
      slug: dto.slug,
      documentType: dto.documentType,
      documentNumber: dto.documentNumber,
      organizationId: dto.organizationId,
      ownershipState: dto.ownershipState,
      avatarUrl: _normalizeAccountAvatarUrl(dto.avatarUrl),
    );
  }

  String? _normalizeAccountAvatarUrl(String? rawUrl) {
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
