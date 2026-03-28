import 'package:belluga_now/domain/partners/account_profile_model.dart';
import 'package:belluga_now/domain/partners/paged_account_profiles_result.dart';
import 'package:stream_value/core/stream_value.dart';

typedef AccountProfilesRepositoryContractPrimString = String;
typedef AccountProfilesRepositoryContractPrimInt = int;
typedef AccountProfilesRepositoryContractPrimBool = bool;
typedef AccountProfilesRepositoryContractPrimDouble = double;
typedef AccountProfilesRepositoryContractPrimDateTime = DateTime;
typedef AccountProfilesRepositoryContractPrimDynamic = dynamic;

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
  final discoveryLiveAccountProfilesStreamValue =
      StreamValue<List<AccountProfileModel>>(defaultValue: const []);
  final discoveryNearbyAccountProfilesStreamValue =
      StreamValue<List<AccountProfileModel>>(defaultValue: const []);
  final discoveryCuratorAccountProfilesStreamValue =
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
    AccountProfilesRepositoryContractPrimInt pageSize = 30,
    AccountProfilesRepositoryContractPrimString? query,
    AccountProfilesRepositoryContractPrimString? typeFilter,
  }) async {
    await _waitForPagedAccountProfilesFetch();
    _resetPagedAccountProfilesState();
    pagedAccountProfilesStreamValue.addValue(null);
    await _fetchPagedAccountProfiles(
      page: 1,
      pageSize: pageSize,
      query: query,
      typeFilter: typeFilter,
    );
  }

  Future<void> loadNextAccountProfilesPage({
    AccountProfilesRepositoryContractPrimInt pageSize = 30,
    AccountProfilesRepositoryContractPrimString? query,
    AccountProfilesRepositoryContractPrimString? typeFilter,
  }) async {
    if (_paginationState.isFetching || !_paginationState.hasMore) {
      return;
    }
    await _fetchPagedAccountProfiles(
      page: _paginationState.currentPage + 1,
      pageSize: pageSize,
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
    AccountProfilesRepositoryContractPrimInt pageSize = 10,
  });

  Future<void> loadAccountProfileBySlug(
      AccountProfilesRepositoryContractPrimString slug) async {
    final profile = await getAccountProfileBySlug(slug);
    selectedAccountProfileStreamValue.addValue(profile);
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
    while (_paginationState.isFetching) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
  }

  Future<void> _fetchPagedAccountProfiles({
    required AccountProfilesRepositoryContractPrimInt page,
    required AccountProfilesRepositoryContractPrimInt pageSize,
    AccountProfilesRepositoryContractPrimString? query,
    AccountProfilesRepositoryContractPrimString? typeFilter,
  }) async {
    if (_paginationState.isFetching) return;
    if (page > 1 && !_paginationState.hasMore) return;

    _paginationState.isFetching = true;
    if (page > 1) {
      isPagedAccountProfilesLoadingStreamValue.addValue(true);
    }
    try {
      final result = await fetchAccountProfilesPage(
        page: page,
        pageSize: pageSize,
        query: query,
        typeFilter: typeFilter,
      );
      _paginationState.currentPage = page;
      _paginationState.hasMore = result.hasMore;
      hasMorePagedAccountProfilesStreamValue.addValue(_paginationState.hasMore);
      pagedAccountProfilesStreamValue.addValue(result);
      pagedAccountProfilesErrorStreamValue.addValue(null);
    } catch (error) {
      pagedAccountProfilesErrorStreamValue.addValue(error.toString());
      if (page == 1) {
        pagedAccountProfilesStreamValue.addValue(
          const PagedAccountProfilesResult(
            profiles: <AccountProfileModel>[],
            hasMore: false,
          ),
        );
        hasMorePagedAccountProfilesStreamValue.addValue(false);
      }
    } finally {
      _paginationState.isFetching = false;
      isPagedAccountProfilesLoadingStreamValue.addValue(false);
    }
  }

  void _resetPagedAccountProfilesState() {
    _paginationState.currentPage = 0;
    _paginationState.hasMore = true;
    _paginationState.isFetching = false;
    hasMorePagedAccountProfilesStreamValue.addValue(true);
    isPagedAccountProfilesLoadingStreamValue.addValue(false);
  }
}

class _AccountProfilesPaginationState {
  final StreamValue<PagedAccountProfilesResult?>
      pagedAccountProfilesStreamValue =
      StreamValue<PagedAccountProfilesResult?>(defaultValue: null);
  final StreamValue<AccountProfilesRepositoryContractPrimBool>
      hasMoreStreamValue =
      StreamValue<AccountProfilesRepositoryContractPrimBool>(
          defaultValue: true);
  final StreamValue<AccountProfilesRepositoryContractPrimBool>
      isPageLoadingStreamValue =
      StreamValue<AccountProfilesRepositoryContractPrimBool>(
          defaultValue: false);
  final StreamValue<AccountProfilesRepositoryContractPrimString?>
      errorStreamValue =
      StreamValue<AccountProfilesRepositoryContractPrimString?>();
  AccountProfilesRepositoryContractPrimInt currentPage = 0;
  AccountProfilesRepositoryContractPrimBool hasMore = true;
  AccountProfilesRepositoryContractPrimBool isFetching = false;
}
