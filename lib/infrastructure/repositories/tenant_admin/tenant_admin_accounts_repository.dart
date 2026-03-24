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
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_term.dart';
import 'package:belluga_now/infrastructure/dal/dao/tenant_admin/tenant_admin_accounts_request_encoder.dart';
import 'package:belluga_now/infrastructure/dal/dao/tenant_admin/tenant_admin_media_form_data_builder.dart';
import 'package:belluga_now/infrastructure/dal/dao/tenant_admin/tenant_admin_pagination_decoder.dart';
import 'package:belluga_now/infrastructure/dal/dto/tenant_admin/tenant_admin_accounts_response_decoder.dart';
import 'package:belluga_now/infrastructure/repositories/tenant_admin/support/tenant_admin_validation_failure_resolver.dart';
import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value.dart';

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
  static const int _defaultPageSize = 20;
  bool _isFetchingAccountsPage = false;
  bool _hasMoreAccounts = true;
  int _currentAccountsPage = 0;

  @override
  final StreamValue<List<TenantAdminAccount>?> accountsStreamValue =
      StreamValue<List<TenantAdminAccount>?>();

  @override
  final StreamValue<bool> hasMoreAccountsStreamValue =
      StreamValue<bool>(defaultValue: true);

  @override
  final StreamValue<bool> isAccountsPageLoadingStreamValue =
      StreamValue<bool>(defaultValue: false);

  @override
  final StreamValue<String?> accountsErrorStreamValue = StreamValue<String?>();

  String get _apiBaseUrl =>
      (_tenantScope ?? GetIt.I.get<TenantAdminTenantScopeContract>())
          .selectedTenantAdminBaseUrl;

  @override
  Future<void> loadAccounts({
    int pageSize = _defaultPageSize,
    TenantAdminOwnershipState? ownershipState,
    String? searchQuery,
  }) async {
    await _waitForAccountsFetch();
    _resetAccountsPagination();
    accountsStreamValue.addValue(null);
    await _fetchAccountsPage(
      page: 1,
      pageSize: pageSize,
      ownershipState: ownershipState,
      searchQuery: searchQuery,
    );
  }

  @override
  Future<void> loadNextAccountsPage({
    int pageSize = _defaultPageSize,
    TenantAdminOwnershipState? ownershipState,
    String? searchQuery,
  }) async {
    if (_isFetchingAccountsPage || !_hasMoreAccounts) {
      return;
    }
    await _fetchAccountsPage(
      page: _currentAccountsPage + 1,
      pageSize: pageSize,
      ownershipState: ownershipState,
      searchQuery: searchQuery,
    );
  }

  @override
  void resetAccountsState() {
    _resetAccountsPagination();
    accountsStreamValue.addValue(null);
    accountsErrorStreamValue.addValue(null);
  }

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
        page: page,
        pageSize: pageSize,
      );
      accounts.addAll(pageResult.accounts);
      hasMore = pageResult.hasMore;
      page += 1;
    }

    return List<TenantAdminAccount>.unmodifiable(accounts);
  }

  @override
  Future<TenantAdminPagedAccountsResult> fetchAccountsPage({
    required int page,
    required int pageSize,
    TenantAdminOwnershipState? ownershipState,
    String? searchQuery,
  }) async {
    return _fetchFilteredAccountsPage(
      page: page,
      pageSize: pageSize,
      ownershipState: ownershipState,
      searchQuery: searchQuery,
    );
  }

  Future<TenantAdminPagedAccountsResult> _fetchFilteredAccountsPage({
    required int page,
    required int pageSize,
    TenantAdminOwnershipState? ownershipState,
    String? searchQuery,
  }) async {
    final normalizedSearch = searchQuery?.trim() ?? '';
    try {
      final response = await _dio.get(
        '$_apiBaseUrl/v1/accounts',
        queryParameters: {
          'page': page,
          'per_page': pageSize,
          if (ownershipState != null)
            'ownership_state': ownershipState.apiValue,
          if (normalizedSearch.isNotEmpty) 'search': normalizedSearch,
        },
        options: Options(headers: _buildHeaders()),
      );
      final dtos = _responseDecoder.decodeAccountList(response.data);
      final currentPage = _extractCurrentPage(
            rawResponse: response.data,
            fallback: page,
          ) ??
          page;
      final lastPage = _extractLastPage(
            rawResponse: response.data,
            fallback: page,
          ) ??
          currentPage;
      final hasMore = currentPage < lastPage;
      return TenantAdminPagedAccountsResult(
        accounts: dtos.map((dto) => dto.toDomain()).toList(growable: false),
        hasMore: hasMore,
      );
    } on DioException catch (error) {
      throw _wrapError(error, 'load accounts page');
    }
  }

  @override
  Future<TenantAdminAccount> fetchAccountBySlug(String accountSlug) async {
    final loaded = findLoadedAccount(accountSlug: accountSlug);
    if (loaded != null) {
      return loaded;
    }
    try {
      final response = await _dio.get(
        '$_apiBaseUrl/v1/accounts/$accountSlug',
        options: Options(headers: _buildHeaders()),
      );
      final dto = _responseDecoder.decodeAccountItem(response.data);
      final account = dto.toDomain();
      _upsertLoadedAccount(account);
      return account;
    } on DioException catch (error) {
      throw _wrapError(error, 'load account');
    }
  }

  @override
  Future<TenantAdminAccount> createAccount({
    required String name,
    TenantAdminDocument? document,
    required TenantAdminOwnershipState ownershipState,
    String? organizationId,
  }) async {
    final payload = _requestEncoder.encodeCreateAccount(
      name: name,
      ownershipState: ownershipState,
      organizationId: organizationId,
      document: document,
    );
    try {
      final response = await _dio.post(
        '$_apiBaseUrl/v1/accounts',
        data: payload,
        options: Options(headers: _buildHeaders()),
      );
      final dto = _responseDecoder.decodeCreateAccountItem(response.data);
      final created = dto.toDomain();
      _appendLoadedAccount(created);
      return created;
    } on DioException catch (error) {
      throw _wrapError(error, 'create account');
    }
  }

  @override
  Future<TenantAdminAccountOnboardingResult> createAccountOnboarding({
    required String name,
    required TenantAdminOwnershipState ownershipState,
    required String profileType,
    TenantAdminLocation? location,
    List<TenantAdminTaxonomyTerm> taxonomyTerms = const [],
    String? bio,
    String? content,
    TenantAdminMediaUpload? avatarUpload,
    TenantAdminMediaUpload? coverUpload,
  }) async {
    try {
      final payload = _requestEncoder.encodeCreateOnboarding(
        name: name,
        ownershipState: ownershipState,
        profileType: profileType,
        location: location,
        taxonomyTerms: taxonomyTerms,
        bio: bio,
        content: content,
      );

      final uploadPayload = _mediaFormDataBuilder.buildAvatarCoverPayload(
        payload: payload,
        avatarUpload: avatarUpload,
        coverUpload: coverUpload,
      );

      final response = await _dio.post(
        '$_apiBaseUrl/v1/account_onboardings',
        data: uploadPayload ?? payload,
        options: Options(headers: _buildHeaders()),
      );
      final onboardingData = _responseDecoder.decodeOnboarding(response.data);
      final account = onboardingData.account.toDomain();
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
    required String accountSlug,
    String? name,
    String? slug,
    TenantAdminDocument? document,
    TenantAdminOwnershipState? ownershipState,
  }) async {
    try {
      final payload = _requestEncoder.encodeUpdateAccount(
        name: name,
        slug: slug,
        document: document,
        ownershipState: ownershipState,
      );
      final response = await _dio.patch(
        '$_apiBaseUrl/v1/accounts/$accountSlug',
        data: payload,
        options: Options(headers: _buildHeaders()),
      );
      final dto = _responseDecoder.decodeAccountItem(response.data);
      final updated = dto.toDomain();
      _upsertLoadedAccount(updated);
      return updated;
    } on DioException catch (error) {
      throw _wrapError(error, 'update account');
    }
  }

  @override
  Future<void> deleteAccount(String accountSlug) async {
    try {
      await _dio.delete(
        '$_apiBaseUrl/v1/accounts/$accountSlug',
        options: Options(headers: _buildHeaders()),
      );
      _removeLoadedAccountBySlug(accountSlug);
    } on DioException catch (error) {
      throw _wrapError(error, 'delete account');
    }
  }

  @override
  Future<TenantAdminAccount> restoreAccount(String accountSlug) async {
    try {
      final response = await _dio.post(
        '$_apiBaseUrl/v1/accounts/$accountSlug/restore',
        options: Options(headers: _buildHeaders()),
      );
      final dto = _responseDecoder.decodeAccountItem(response.data);
      final restored = dto.toDomain();
      _upsertLoadedAccount(restored);
      return restored;
    } on DioException catch (error) {
      throw _wrapError(error, 'restore account');
    }
  }

  @override
  Future<void> forceDeleteAccount(String accountSlug) async {
    try {
      await _dio.post(
        '$_apiBaseUrl/v1/accounts/$accountSlug/force_delete',
        options: Options(headers: _buildHeaders()),
      );
      _removeLoadedAccountBySlug(accountSlug);
    } on DioException catch (error) {
      throw _wrapError(error, 'force delete account');
    }
  }

  Future<void> _waitForAccountsFetch() async {
    while (_isFetchingAccountsPage) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
  }

  Future<void> _fetchAccountsPage({
    required int page,
    required int pageSize,
    TenantAdminOwnershipState? ownershipState,
    String? searchQuery,
  }) async {
    if (_isFetchingAccountsPage) return;
    if (page > 1 && !_hasMoreAccounts) return;

    _isFetchingAccountsPage = true;
    if (page > 1) {
      isAccountsPageLoadingStreamValue.addValue(true);
    }
    try {
      final result = await fetchAccountsPage(
        page: page,
        pageSize: pageSize,
        ownershipState: ownershipState,
        searchQuery: searchQuery,
      );
      final currentAccounts = accountsStreamValue.value;
      final nextAccounts = page == 1
          ? result.accounts
          : <TenantAdminAccount>[
              ...?currentAccounts,
              ...result.accounts,
            ];
      _currentAccountsPage = page;
      _hasMoreAccounts = result.hasMore;
      hasMoreAccountsStreamValue.addValue(_hasMoreAccounts);
      accountsStreamValue.addValue(
        List<TenantAdminAccount>.unmodifiable(nextAccounts),
      );
      accountsErrorStreamValue.addValue(null);
    } catch (error) {
      accountsErrorStreamValue.addValue(error.toString());
      if (page == 1 && accountsStreamValue.value == null) {
        accountsStreamValue.addValue(const <TenantAdminAccount>[]);
      }
    } finally {
      _isFetchingAccountsPage = false;
      isAccountsPageLoadingStreamValue.addValue(false);
    }
  }

  void _resetAccountsPagination() {
    _currentAccountsPage = 0;
    _hasMoreAccounts = true;
    _isFetchingAccountsPage = false;
    hasMoreAccountsStreamValue.addValue(true);
    isAccountsPageLoadingStreamValue.addValue(false);
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

  Exception _wrapError(DioException error, String label) {
    final validationFailure = tenantAdminTryResolveValidationFailure(error);
    if (validationFailure != null) {
      return validationFailure;
    }
    return tenantAdminWrapRepositoryError(error, label);
  }
}
