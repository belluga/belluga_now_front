import 'package:belluga_now/domain/partners/account_profile_model.dart';
import 'package:belluga_now/domain/partners/paged_account_profiles_result.dart';
import 'package:stream_value/core/stream_value.dart';

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
      StreamValue<Set<String>>(defaultValue: const {});

  StreamValue<PagedAccountProfilesResult?>
      get pagedAccountProfilesStreamValue =>
          _paginationState.pagedAccountProfilesStreamValue;

  StreamValue<bool> get hasMorePagedAccountProfilesStreamValue =>
      _paginationState.hasMoreStreamValue;

  StreamValue<bool> get isPagedAccountProfilesLoadingStreamValue =>
      _paginationState.isPageLoadingStreamValue;

  StreamValue<String?> get pagedAccountProfilesErrorStreamValue =>
      _paginationState.errorStreamValue;

  int get currentPagedAccountProfilesPage => _paginationState.currentPage;

  /// Initialize repository and load data
  Future<void> init();

  /// Fetch all account profiles
  Future<List<AccountProfileModel>> fetchAllAccountProfiles();

  /// Fetch paged account profiles for scrolling surfaces.
  Future<PagedAccountProfilesResult> fetchAccountProfilesPage({
    required int page,
    required int pageSize,
    String? query,
    String? typeFilter,
  });

  Future<void> loadAccountProfilesPage({
    int pageSize = 30,
    String? query,
    String? typeFilter,
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
    int pageSize = 30,
    String? query,
    String? typeFilter,
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
    String? query,
    String? typeFilter,
  });

  /// Get account profile by slug
  Future<AccountProfileModel?> getAccountProfileBySlug(String slug);

  Future<void> loadAccountProfileBySlug(String slug) async {
    final profile = await getAccountProfileBySlug(slug);
    selectedAccountProfileStreamValue.addValue(profile);
  }

  /// Toggle favorite status for an account profile
  Future<void> toggleFavorite(String accountProfileId);

  /// Check if account profile is favorited
  bool isFavorite(String accountProfileId);

  /// Get all favorite account profiles
  List<AccountProfileModel> getFavoriteAccountProfiles();

  Future<void> _waitForPagedAccountProfilesFetch() async {
    while (_paginationState.isFetching) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
  }

  Future<void> _fetchPagedAccountProfiles({
    required int page,
    required int pageSize,
    String? query,
    String? typeFilter,
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
  final StreamValue<bool> hasMoreStreamValue =
      StreamValue<bool>(defaultValue: true);
  final StreamValue<bool> isPageLoadingStreamValue =
      StreamValue<bool>(defaultValue: false);
  final StreamValue<String?> errorStreamValue = StreamValue<String?>();
  int currentPage = 0;
  bool hasMore = true;
  bool isFetching = false;
}
