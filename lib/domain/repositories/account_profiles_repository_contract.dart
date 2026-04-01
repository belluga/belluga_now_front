import 'package:belluga_now/domain/partners/account_profile_model.dart';
import 'package:belluga_now/domain/partners/paged_account_profiles_result.dart';
import 'package:belluga_now/domain/repositories/value_objects/account_profiles_repository_contract_values.dart';
import 'package:stream_value/core/stream_value.dart';

typedef AccountProfilesRepositoryContractPrimString
    = AccountProfilesRepositoryContractTextValue;
typedef AccountProfilesRepositoryContractPrimInt
    = AccountProfilesRepositoryContractIntValue;
typedef AccountProfilesRepositoryContractPrimBool
    = AccountProfilesRepositoryContractBoolValue;

abstract class AccountProfilesRepositoryContract {
  static final Expando<_AccountProfilesPaginationState>
      _paginationStateByRepository = Expando<_AccountProfilesPaginationState>();

  _AccountProfilesPaginationState get _paginationState =>
      _paginationStateByRepository[this] ??= _AccountProfilesPaginationState();

  /// Stream of all account profiles
  final allAccountProfilesStreamValue =
      StreamValue<List<AccountProfileModel>>(defaultValue: const []);
  final selectedAccountProfileStreamValue =
      StreamValue<AccountProfileModel?>(defaultValue: null);
  final discoveryFilteredAccountProfilesStreamValue =
      StreamValue<List<AccountProfileModel>>(defaultValue: const []);
  final discoveryNearbyAccountProfilesStreamValue =
      StreamValue<List<AccountProfileModel>>(defaultValue: const []);

  /// Stream of favorite account profile IDs
  final favoriteAccountProfileIdsStreamValue =
      StreamValue<Set<AccountProfilesRepositoryContractPrimString>>(
          defaultValue: const {});

  StreamValue<PagedAccountProfilesResult?>
      get pagedAccountProfilesStreamValue =>
          _paginationState.pagedAccountProfilesStreamValue;

  StreamValue<AccountProfilesRepositoryContractPrimBool>
      get hasMorePagedAccountProfilesStreamValue =>
          _paginationState.hasMoreStreamValue;

  StreamValue<AccountProfilesRepositoryContractPrimBool>
      get isPagedAccountProfilesLoadingStreamValue =>
          _paginationState.isPageLoadingStreamValue;

  StreamValue<AccountProfilesRepositoryContractPrimString?>
      get pagedAccountProfilesErrorStreamValue =>
          _paginationState.errorStreamValue;

  AccountProfilesRepositoryContractPrimInt
      get currentPagedAccountProfilesPage => _paginationState.currentPage;

  /// Initialize repository and load data
  Future<void> init();

  /// Fetch all account profiles
  Future<List<AccountProfileModel>> fetchAllAccountProfiles();

  /// Fetch paged account profiles for scrolling surfaces.
  Future<PagedAccountProfilesResult> fetchAccountProfilesPage({
    required AccountProfilesRepositoryContractPrimInt page,
    required AccountProfilesRepositoryContractPrimInt pageSize,
    AccountProfilesRepositoryContractPrimString? query,
    AccountProfilesRepositoryContractPrimString? typeFilter,
  });

  Future<void> loadAccountProfilesPage({
    AccountProfilesRepositoryContractPrimInt? pageSize,
    AccountProfilesRepositoryContractPrimString? query,
    AccountProfilesRepositoryContractPrimString? typeFilter,
  }) async {
    final effectivePageSize = pageSize ??
        AccountProfilesRepositoryContractPrimInt.fromRaw(
          30,
          defaultValue: 30,
        );
    await _waitForPagedAccountProfilesFetch();
    _resetPagedAccountProfilesState();
    pagedAccountProfilesStreamValue.addValue(null);
    await _fetchPagedAccountProfiles(
      page: AccountProfilesRepositoryContractPrimInt.fromRaw(
        1,
        defaultValue: 1,
      ),
      pageSize: effectivePageSize,
      query: query,
      typeFilter: typeFilter,
    );
  }

  Future<void> loadNextAccountProfilesPage({
    AccountProfilesRepositoryContractPrimInt? pageSize,
    AccountProfilesRepositoryContractPrimString? query,
    AccountProfilesRepositoryContractPrimString? typeFilter,
  }) async {
    final effectivePageSize = pageSize ??
        AccountProfilesRepositoryContractPrimInt.fromRaw(
          30,
          defaultValue: 30,
        );
    if (_paginationState.isFetching.value || !_paginationState.hasMore.value) {
      return;
    }
    await _fetchPagedAccountProfiles(
      page: AccountProfilesRepositoryContractPrimInt.fromRaw(
        _paginationState.currentPage.value + 1,
        defaultValue: 1,
      ),
      pageSize: effectivePageSize,
      query: query,
      typeFilter: typeFilter,
    );
  }

  void resetPagedAccountProfilesState() {
    _resetPagedAccountProfilesState();
    pagedAccountProfilesStreamValue.addValue(null);
    pagedAccountProfilesErrorStreamValue.addValue(null);
  }

  /// Search account profiles by query and optional type filter
  Future<List<AccountProfileModel>> searchAccountProfiles({
    AccountProfilesRepositoryContractPrimString? query,
    AccountProfilesRepositoryContractPrimString? typeFilter,
  });

  /// Get account profile by slug
  Future<AccountProfileModel?> getAccountProfileBySlug(
      AccountProfilesRepositoryContractPrimString slug);

  Future<List<AccountProfileModel>> fetchNearbyAccountProfiles({
    AccountProfilesRepositoryContractPrimInt? pageSize,
  });

  Future<void> syncDiscoveryNearbyAccountProfiles({
    AccountProfilesRepositoryContractPrimInt? pageSize,
  }) async {
    final effectivePageSize = pageSize ??
        AccountProfilesRepositoryContractPrimInt.fromRaw(
          10,
          defaultValue: 10,
        );
    final profiles = await fetchNearbyAccountProfiles(
      pageSize: effectivePageSize,
    );
    discoveryNearbyAccountProfilesStreamValue.addValue(
      _filterDiscoveryMvpProfiles(profiles)
          .take(effectivePageSize.value)
          .toList(growable: false),
    );
  }

  Future<void> loadAccountProfileBySlug(
      AccountProfilesRepositoryContractPrimString slug) async {
    final profile = await getAccountProfileBySlug(slug);
    selectedAccountProfileStreamValue.addValue(profile);
  }

  void setSelectedAccountProfile(AccountProfileModel? profile) {
    selectedAccountProfileStreamValue.addValue(profile);
  }

  void clearSelectedAccountProfile() {
    selectedAccountProfileStreamValue.addValue(null);
  }

  /// Toggle favorite status for an account profile
  Future<void> toggleFavorite(
      AccountProfilesRepositoryContractPrimString accountProfileId);

  /// Check if account profile is favorited
  AccountProfilesRepositoryContractPrimBool isFavorite(
      AccountProfilesRepositoryContractPrimString accountProfileId);

  /// Get all favorite account profiles
  List<AccountProfileModel> getFavoriteAccountProfiles();

  Future<void> _waitForPagedAccountProfilesFetch() async {
    while (_paginationState.isFetching.value) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
  }

  Future<void> _fetchPagedAccountProfiles({
    required AccountProfilesRepositoryContractPrimInt page,
    required AccountProfilesRepositoryContractPrimInt pageSize,
    AccountProfilesRepositoryContractPrimString? query,
    AccountProfilesRepositoryContractPrimString? typeFilter,
  }) async {
    if (_paginationState.isFetching.value) return;
    if (page.value > 1 && !_paginationState.hasMore.value) return;

    _paginationState.isFetching =
        AccountProfilesRepositoryContractPrimBool.fromRaw(
      true,
      defaultValue: true,
    );
    if (page.value > 1) {
      isPagedAccountProfilesLoadingStreamValue.addValue(
        AccountProfilesRepositoryContractPrimBool.fromRaw(
          true,
          defaultValue: true,
        ),
      );
    }
    try {
      final result = await fetchAccountProfilesPage(
        page: page,
        pageSize: pageSize,
        query: query,
        typeFilter: typeFilter,
      );
      final accumulatedProfiles = page.value <= 1
          ? List<AccountProfileModel>.from(result.profiles)
          : <AccountProfileModel>[
              ...?_paginationState
                  .pagedAccountProfilesStreamValue.value?.profiles,
              ...result.profiles,
            ];
      _paginationState.currentPage = page;
      _paginationState.hasMore =
          AccountProfilesRepositoryContractPrimBool.fromRaw(
        result.hasMore,
        defaultValue: true,
      );
      hasMorePagedAccountProfilesStreamValue.addValue(_paginationState.hasMore);
      pagedAccountProfilesStreamValue.addValue(
        pagedAccountProfilesResultFromRaw(
          profiles: accumulatedProfiles,
          hasMore: result.hasMore,
        ),
      );
      discoveryFilteredAccountProfilesStreamValue.addValue(
        _filterDiscoveryMvpProfiles(accumulatedProfiles),
      );
      pagedAccountProfilesErrorStreamValue.addValue(null);
    } catch (error) {
      pagedAccountProfilesErrorStreamValue.addValue(
        AccountProfilesRepositoryContractPrimString.fromRaw(error.toString()),
      );
      if (page.value == 1) {
        discoveryFilteredAccountProfilesStreamValue.addValue(
          const <AccountProfileModel>[],
        );
        pagedAccountProfilesStreamValue.addValue(
          pagedAccountProfilesResultFromRaw(
            profiles: <AccountProfileModel>[],
            hasMore: false,
          ),
        );
        hasMorePagedAccountProfilesStreamValue.addValue(
          AccountProfilesRepositoryContractPrimBool.fromRaw(
            false,
            defaultValue: false,
          ),
        );
      }
    } finally {
      _paginationState.isFetching =
          AccountProfilesRepositoryContractPrimBool.fromRaw(
        false,
        defaultValue: false,
      );
      isPagedAccountProfilesLoadingStreamValue.addValue(
        AccountProfilesRepositoryContractPrimBool.fromRaw(
          false,
          defaultValue: false,
        ),
      );
    }
  }

  void _resetPagedAccountProfilesState() {
    _paginationState.currentPage =
        AccountProfilesRepositoryContractPrimInt.fromRaw(
      0,
      defaultValue: 0,
    );
    _paginationState.hasMore =
        AccountProfilesRepositoryContractPrimBool.fromRaw(
      true,
      defaultValue: true,
    );
    _paginationState.isFetching =
        AccountProfilesRepositoryContractPrimBool.fromRaw(
      false,
      defaultValue: false,
    );
    hasMorePagedAccountProfilesStreamValue.addValue(
      AccountProfilesRepositoryContractPrimBool.fromRaw(
        true,
        defaultValue: true,
      ),
    );
    isPagedAccountProfilesLoadingStreamValue.addValue(
      AccountProfilesRepositoryContractPrimBool.fromRaw(
        false,
        defaultValue: false,
      ),
    );
  }

  List<AccountProfileModel> _filterDiscoveryMvpProfiles(
    List<AccountProfileModel> profiles,
  ) {
    return profiles
        .where((profile) => profile.type != 'curator')
        .toList(growable: false);
  }
}

class _AccountProfilesPaginationState {
  final StreamValue<PagedAccountProfilesResult?>
      pagedAccountProfilesStreamValue =
      StreamValue<PagedAccountProfilesResult?>(defaultValue: null);
  final StreamValue<AccountProfilesRepositoryContractPrimBool>
      hasMoreStreamValue =
      StreamValue<AccountProfilesRepositoryContractPrimBool>(
          defaultValue: AccountProfilesRepositoryContractPrimBool.fromRaw(
    true,
    defaultValue: true,
  ));
  final StreamValue<AccountProfilesRepositoryContractPrimBool>
      isPageLoadingStreamValue =
      StreamValue<AccountProfilesRepositoryContractPrimBool>(
          defaultValue: AccountProfilesRepositoryContractPrimBool.fromRaw(
    false,
    defaultValue: false,
  ));
  final StreamValue<AccountProfilesRepositoryContractPrimString?>
      errorStreamValue =
      StreamValue<AccountProfilesRepositoryContractPrimString?>();
  AccountProfilesRepositoryContractPrimInt currentPage =
      AccountProfilesRepositoryContractPrimInt.fromRaw(
    0,
    defaultValue: 0,
  );
  AccountProfilesRepositoryContractPrimBool hasMore =
      AccountProfilesRepositoryContractPrimBool.fromRaw(
    true,
    defaultValue: true,
  );
  AccountProfilesRepositoryContractPrimBool isFetching =
      AccountProfilesRepositoryContractPrimBool.fromRaw(
    false,
    defaultValue: false,
  );
}
