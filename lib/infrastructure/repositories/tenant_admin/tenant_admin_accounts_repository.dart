import 'package:belluga_now/domain/repositories/landlord_auth_repository_contract.dart';
import 'package:belluga_now/domain/repositories/tenant_admin_accounts_repository_contract.dart';
import 'package:belluga_now/domain/services/tenant_admin_tenant_scope_contract.dart';
import 'package:belluga_now/domain/tenant_admin/ownership_state.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_account.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_document.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_paged_accounts_result.dart';
import 'package:belluga_now/infrastructure/dal/dto/tenant_admin/tenant_admin_account_dto.dart';
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
  }) async {
    await _waitForAccountsFetch();
    _resetAccountsPagination();
    accountsStreamValue.addValue(null);
    await _fetchAccountsPage(
      page: 1,
      pageSize: pageSize,
      ownershipState: ownershipState,
    );
  }

  @override
  Future<void> loadNextAccountsPage({
    int pageSize = _defaultPageSize,
    TenantAdminOwnershipState? ownershipState,
  }) async {
    if (_isFetchingAccountsPage || !_hasMoreAccounts) {
      return;
    }
    await _fetchAccountsPage(
      page: _currentAccountsPage + 1,
      pageSize: pageSize,
      ownershipState: ownershipState,
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
  }) async {
    return _fetchFilteredAccountsPage(
      page: page,
      pageSize: pageSize,
      ownershipState: ownershipState,
    );
  }

  Future<TenantAdminPagedAccountsResult> _fetchFilteredAccountsPage({
    required int page,
    required int pageSize,
    TenantAdminOwnershipState? ownershipState,
  }) async {
    try {
      final response = await _dio.get(
        '$_apiBaseUrl/v1/accounts',
        queryParameters: {
          'page': page,
          'page_size': pageSize,
          if (ownershipState != null)
            'ownership_state': ownershipState.apiValue,
        },
        options: Options(headers: _buildHeaders()),
      );
      final data = _extractList(response.data);
      final currentPage = _extractCurrentPage(
            raw: response.data,
            fallback: page,
          ) ??
          page;
      final lastPage = _extractLastPage(
            raw: response.data,
            fallback: page,
          ) ??
          currentPage;
      final hasMore = currentPage < lastPage;
      return TenantAdminPagedAccountsResult(
        accounts: data.map(_mapAccount).toList(growable: false),
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
      final item = _extractItem(response.data);
      final account = _mapAccount(item);
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
    final payload = <String, dynamic>{
      'name': name,
      'ownership_state': ownershipState.apiValue,
      if (organizationId != null && organizationId.trim().isNotEmpty)
        'organization_id': organizationId.trim(),
    };
    if (document != null) {
      payload['document'] = {
        'type': document.type,
        'number': document.number,
      };
    }
    try {
      final response = await _dio.post(
        '$_apiBaseUrl/v1/accounts',
        data: payload,
        options: Options(headers: _buildHeaders()),
      );
      final item = _extractAccountFromCreate(response.data);
      final created = _mapAccount(item);
      _appendLoadedAccount(created);
      return created;
    } on DioException catch (error) {
      throw _wrapError(error, 'create account');
    }
  }

  @override
  Future<TenantAdminAccount> updateAccount({
    required String accountSlug,
    String? name,
    String? slug,
    TenantAdminDocument? document,
  }) async {
    try {
      final payload = <String, dynamic>{};
      if (name != null && name.trim().isNotEmpty) {
        payload['name'] = name.trim();
      }
      if (slug != null && slug.trim().isNotEmpty) {
        payload['slug'] = slug.trim();
      }
      if (document != null) {
        payload['document'] = {
          'type': document.type,
          'number': document.number,
        };
      }
      final response = await _dio.patch(
        '$_apiBaseUrl/v1/accounts/$accountSlug',
        data: payload,
        options: Options(headers: _buildHeaders()),
      );
      final item = _extractItem(response.data);
      final updated = _mapAccount(item);
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
      final item = _extractItem(response.data);
      final restored = _mapAccount(item);
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

  Map<String, dynamic> _extractItem(dynamic raw) {
    if (raw is Map<String, dynamic>) {
      final data = raw['data'];
      if (data is Map<String, dynamic>) return data;
      return raw;
    }
    throw Exception('Unexpected account response shape.');
  }

  Map<String, dynamic> _extractAccountFromCreate(dynamic raw) {
    if (raw is Map<String, dynamic>) {
      final data = raw['data'];
      if (data is Map<String, dynamic>) {
        final account = data['account'];
        if (account is Map<String, dynamic>) {
          return account;
        }
        return data;
      }
    }
    throw Exception('Unexpected account create response shape.');
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
    throw Exception('Unexpected accounts list response shape.');
  }

  int? _extractCurrentPage({
    required dynamic raw,
    int? fallback,
  }) {
    if (raw is! Map<String, dynamic>) return fallback;
    return _readInt(raw, 'current_page') ??
        _readInt(raw['meta'], 'current_page') ??
        fallback;
  }

  int? _extractLastPage({
    required dynamic raw,
    int? fallback,
  }) {
    if (raw is! Map<String, dynamic>) return fallback;
    return _readInt(raw, 'last_page') ??
        _readInt(raw['meta'], 'last_page') ??
        fallback;
  }

  int? _readInt(dynamic source, String key) {
    if (source is! Map) {
      return null;
    }
    final value = source[key];
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value);
    }
    return null;
  }

  TenantAdminAccount _mapAccount(Map<String, dynamic> json) {
    final dto = TenantAdminAccountDTO.fromJson(json);
    final ownershipStateRaw = dto.ownershipState?.trim();
    final ownershipState =
        (ownershipStateRaw == null || ownershipStateRaw.isEmpty)
            ? TenantAdminOwnershipState.unmanaged
            : TenantAdminOwnershipState.fromApiValue(ownershipStateRaw);
    return TenantAdminAccount(
      id: dto.id,
      name: dto.name,
      slug: dto.slug,
      document: TenantAdminDocument(
        type: dto.documentType,
        number: dto.documentNumber,
      ),
      organizationId: dto.organizationId,
      ownershipState: ownershipState,
      avatarUrl: dto.avatarUrl,
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
}
