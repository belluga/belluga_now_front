import 'package:belluga_discovery_filters/belluga_discovery_filters.dart';
import 'package:belluga_now/domain/partners/account_profile_model.dart';
import 'package:belluga_now/domain/partners/account_profile_nested_group_member.dart';
import 'package:belluga_now/domain/partners/account_profile_nested_group_member_page.dart';
import 'package:belluga_now/domain/partners/paged_account_profiles_result.dart';
import 'package:belluga_now/domain/repositories/value_objects/account_profiles_repository_contract_values.dart';
import 'package:stream_value/core/stream_value.dart';

typedef AccountProfilesRepositoryContractPrimString =
    AccountProfilesRepositoryContractTextValue;
typedef AccountProfilesRepositoryContractPrimInt =
    AccountProfilesRepositoryContractIntValue;
typedef AccountProfilesRepositoryContractPrimBool =
    AccountProfilesRepositoryContractBoolValue;

abstract class AccountProfilesRepositoryContract {
  static final Expando<_AccountProfilesPaginationState>
  _paginationStateByRepository = Expando<_AccountProfilesPaginationState>();
  static final Expando<_NestedGroupMembersPaginationRegistry>
  _nestedGroupPaginationStateByRepository =
      Expando<_NestedGroupMembersPaginationRegistry>();

  _AccountProfilesPaginationState get _paginationState =>
      _paginationStateByRepository[this] ??= _AccountProfilesPaginationState();
  _NestedGroupMembersPaginationRegistry get _nestedGroupPaginationRegistry =>
      _nestedGroupPaginationStateByRepository[this] ??=
          _NestedGroupMembersPaginationRegistry();

  /// Stream of all account profiles
  final allAccountProfilesStreamValue = StreamValue<List<AccountProfileModel>>(
    defaultValue: const [],
  );
  final selectedAccountProfileStreamValue = StreamValue<AccountProfileModel?>(
    defaultValue: null,
  );
  final discoveryFilteredAccountProfilesStreamValue =
      StreamValue<List<AccountProfileModel>>(defaultValue: const []);
  final discoveryNearbyAccountProfilesStreamValue =
      StreamValue<List<AccountProfileModel>>(defaultValue: const []);
  final publicDiscoveryFilterFacetsStreamValue =
      StreamValue<DiscoveryFilterRuntimeFacets?>(defaultValue: null);
  final publicDiscoveryFilterCatalogStreamValue =
      StreamValue<DiscoveryFilterCatalog?>(defaultValue: null);

  /// Stream of favorite account profile IDs
  final favoriteAccountProfileIdsStreamValue =
      StreamValue<Set<AccountProfilesRepositoryContractPrimString>>(
        defaultValue: const {},
      );

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
  get pagedAccountProfilesErrorStreamValue => _paginationState.errorStreamValue;

  AccountProfilesRepositoryContractPrimInt
  get currentPagedAccountProfilesPage => _paginationState.currentPage;

  /// Initialize repository and load data
  Future<void> init();

  /// Refresh authenticated/anonymous favorite ids from the backend authority.
  Future<void> refreshFavoriteAccountProfileIds() async {
    await init();
  }

  void clearCurrentIdentityState() {
    favoriteAccountProfileIdsStreamValue.addValue(const {});
  }

  /// Fetch paged account profiles for scrolling surfaces.
  Future<PagedAccountProfilesResult> fetchAccountProfilesPage({
    required AccountProfilesRepositoryContractPrimInt page,
    required AccountProfilesRepositoryContractPrimInt pageSize,
    AccountProfilesRepositoryContractPrimString? query,
    AccountProfilesRepositoryContractPrimString? typeFilter,
    List<AccountProfilesRepositoryContractPrimString>? typeFilters,
    List<AccountProfilesRepositoryTaxonomyFilter>? taxonomyFilters,
  });

  Future<void> loadAccountProfilesPage({
    AccountProfilesRepositoryContractPrimInt? pageSize,
    AccountProfilesRepositoryContractPrimString? query,
    AccountProfilesRepositoryContractPrimString? typeFilter,
    List<AccountProfilesRepositoryContractPrimString>? typeFilters,
    List<AccountProfilesRepositoryTaxonomyFilter>? taxonomyFilters,
  }) async {
    final effectivePageSize =
        pageSize ??
        AccountProfilesRepositoryContractPrimInt.fromRaw(30, defaultValue: 30);
    final generation = _nextPagedAccountProfilesGeneration();
    _resetPagedAccountProfilesState();
    pagedAccountProfilesStreamValue.addValue(null);
    await _fetchPagedAccountProfiles(
      generation: generation,
      page: AccountProfilesRepositoryContractPrimInt.fromRaw(
        1,
        defaultValue: 1,
      ),
      pageSize: effectivePageSize,
      query: query,
      typeFilter: typeFilter,
      typeFilters: typeFilters,
      taxonomyFilters: taxonomyFilters,
    );
  }

  Future<void> loadNextAccountProfilesPage({
    AccountProfilesRepositoryContractPrimInt? pageSize,
    AccountProfilesRepositoryContractPrimString? query,
    AccountProfilesRepositoryContractPrimString? typeFilter,
    List<AccountProfilesRepositoryContractPrimString>? typeFilters,
    List<AccountProfilesRepositoryTaxonomyFilter>? taxonomyFilters,
  }) async {
    final effectivePageSize =
        pageSize ??
        AccountProfilesRepositoryContractPrimInt.fromRaw(30, defaultValue: 30);
    final generation = _paginationState.activeGeneration;
    if (_paginationState.inFlightGenerations.contains(generation) ||
        !_paginationState.hasMore.value) {
      return;
    }
    await _fetchPagedAccountProfiles(
      generation: generation,
      page: AccountProfilesRepositoryContractPrimInt.fromRaw(
        _paginationState.currentPage.value + 1,
        defaultValue: 1,
      ),
      pageSize: effectivePageSize,
      query: query,
      typeFilter: typeFilter,
      typeFilters: typeFilters,
      taxonomyFilters: taxonomyFilters,
    );
  }

  void resetPagedAccountProfilesState() {
    _nextPagedAccountProfilesGeneration();
    _resetPagedAccountProfilesState();
    pagedAccountProfilesStreamValue.addValue(null);
    pagedAccountProfilesErrorStreamValue.addValue(null);
  }

  /// Get account profile by slug
  Future<AccountProfileModel?> getAccountProfileBySlug(
    AccountProfilesRepositoryContractPrimString slug,
  );

  Future<AccountProfileNestedGroupMemberPage> fetchNestedGroupMembersPageByPath(
    AccountProfilesRepositoryContractPrimString membersPath, {
    AccountProfilesRepositoryContractPrimString? cursor,
    AccountProfilesRepositoryContractPrimString? search,
  }) async => const AccountProfileNestedGroupMemberPage.empty();

  StreamValue<List<AccountProfileNestedGroupMember>>
  nestedGroupMembersStreamValue(
    AccountProfilesRepositoryContractPrimString membersPath,
  ) => _nestedGroupMembersState(membersPath).itemsStreamValue;

  StreamValue<AccountProfilesRepositoryContractPrimBool>
  hasMoreNestedGroupMembersStreamValue(
    AccountProfilesRepositoryContractPrimString membersPath,
  ) => _nestedGroupMembersState(membersPath).hasMoreStreamValue;

  StreamValue<AccountProfilesRepositoryContractPrimBool>
  isNestedGroupMembersPageLoadingStreamValue(
    AccountProfilesRepositoryContractPrimString membersPath,
  ) => _nestedGroupMembersState(membersPath).isPageLoadingStreamValue;

  StreamValue<AccountProfilesRepositoryContractPrimBool>
  isNestedGroupMembersSearchAvailableStreamValue(
    AccountProfilesRepositoryContractPrimString membersPath,
  ) => _nestedGroupMembersState(membersPath).isSearchAvailableStreamValue;

  StreamValue<AccountProfilesRepositoryContractPrimString?>
  nestedGroupMembersErrorStreamValue(
    AccountProfilesRepositoryContractPrimString membersPath,
  ) => _nestedGroupMembersState(membersPath).errorStreamValue;

  void retainNestedGroupMembersByPath(
    AccountProfilesRepositoryContractPrimString membersPath,
  ) {
    _nestedGroupPaginationRegistry.retain(membersPath);
  }

  void releaseNestedGroupMembersByPath(
    AccountProfilesRepositoryContractPrimString membersPath,
  ) {
    _nestedGroupPaginationRegistry.release(membersPath);
  }

  Future<void> loadNestedGroupMembersByPath(
    AccountProfilesRepositoryContractPrimString membersPath,
  ) async {
    final state = _nestedGroupMembersState(membersPath);
    if (state.hasLoaded.value || state.isFetching.value) {
      return;
    }
    _resetNestedGroupMembersState(state);
    await _fetchNestedGroupMembersPage(
      membersPath: membersPath,
      state: state,
      cursor: null,
      generation: state.activeGeneration,
    );
  }

  Future<void> searchNestedGroupMembersByPath(
    AccountProfilesRepositoryContractPrimString membersPath, {
    AccountProfilesRepositoryContractPrimString? search,
  }) async {
    final state = _nestedGroupMembersState(membersPath);
    final normalizedSearch = search?.value.trim();
    state.search = normalizedSearch == null || normalizedSearch.isEmpty
        ? null
        : AccountProfilesRepositoryContractPrimString.fromRaw(
            normalizedSearch,
            defaultValue: '',
            isRequired: true,
          );
    _resetNestedGroupMembersState(state);
    state.itemsStreamValue.addValue(const <AccountProfileNestedGroupMember>[]);
    state.errorStreamValue.addValue(null);
    await _fetchNestedGroupMembersPage(
      membersPath: membersPath,
      state: state,
      cursor: null,
      generation: state.activeGeneration,
    );
  }

  Future<void> loadMoreNestedGroupMembersByPath(
    AccountProfilesRepositoryContractPrimString membersPath,
  ) async {
    final state = _nestedGroupMembersState(membersPath);
    if (state.isFetching.value || !state.hasMore.value) {
      return;
    }

    await _fetchNestedGroupMembersPage(
      membersPath: membersPath,
      state: state,
      cursor: state.nextCursor,
      generation: state.activeGeneration,
    );
  }

  void resetNestedGroupMembersByPath(
    AccountProfilesRepositoryContractPrimString membersPath,
  ) {
    final state = _nestedGroupMembersState(membersPath);
    state.search = null;
    _resetNestedGroupMembersState(state);
    state.isSearchAvailable = AccountProfilesRepositoryContractPrimBool.fromRaw(
      false,
      defaultValue: false,
    );
    state.itemsStreamValue.addValue(const <AccountProfileNestedGroupMember>[]);
    state.isSearchAvailableStreamValue.addValue(state.isSearchAvailable);
    state.errorStreamValue.addValue(null);
  }

  Future<List<AccountProfileModel>> fetchNearbyAccountProfiles({
    AccountProfilesRepositoryContractPrimInt? pageSize,
    List<AccountProfilesRepositoryContractPrimString>? typeFilters,
    List<AccountProfilesRepositoryTaxonomyFilter>? taxonomyFilters,
  });

  Future<void> syncDiscoveryNearbyAccountProfiles({
    AccountProfilesRepositoryContractPrimInt? pageSize,
    List<AccountProfilesRepositoryContractPrimString>? typeFilters,
    List<AccountProfilesRepositoryTaxonomyFilter>? taxonomyFilters,
  }) async {
    final effectivePageSize =
        pageSize ??
        AccountProfilesRepositoryContractPrimInt.fromRaw(10, defaultValue: 10);
    final profiles = await fetchNearbyAccountProfiles(
      pageSize: effectivePageSize,
      typeFilters: typeFilters,
      taxonomyFilters: taxonomyFilters,
    );
    discoveryNearbyAccountProfilesStreamValue.addValue(
      profiles.take(effectivePageSize.value).toList(growable: false),
    );
  }

  Future<void> loadAccountProfileBySlug(
    AccountProfilesRepositoryContractPrimString slug,
  ) async {
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
    AccountProfilesRepositoryContractPrimString accountProfileId,
  );

  /// Check if account profile is favorited
  AccountProfilesRepositoryContractPrimBool isFavorite(
    AccountProfilesRepositoryContractPrimString accountProfileId,
  );

  /// Get all favorite account profiles
  List<AccountProfileModel> getFavoriteAccountProfiles();

  Future<void> _fetchPagedAccountProfiles({
    required AccountProfilesRepositoryContractPrimInt generation,
    required AccountProfilesRepositoryContractPrimInt page,
    required AccountProfilesRepositoryContractPrimInt pageSize,
    AccountProfilesRepositoryContractPrimString? query,
    AccountProfilesRepositoryContractPrimString? typeFilter,
    List<AccountProfilesRepositoryContractPrimString>? typeFilters,
    List<AccountProfilesRepositoryTaxonomyFilter>? taxonomyFilters,
  }) async {
    if (page.value > 1 && !_paginationState.hasMore.value) return;

    _markPagedAccountProfilesFetchStarted(generation);
    if (page.value > 1 &&
        _isCurrentPagedAccountProfilesGeneration(generation).value) {
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
        typeFilters: typeFilters,
        taxonomyFilters: taxonomyFilters,
      );
      if (!_isCurrentPagedAccountProfilesGeneration(generation).value) {
        return;
      }
      _commitPagedAccountProfilesSuccess(page: page, result: result);
    } catch (error) {
      if (!_isCurrentPagedAccountProfilesGeneration(generation).value) {
        return;
      }
      _commitPagedAccountProfilesError(
        page: page,
        errorMessage: AccountProfilesRepositoryContractPrimString.fromRaw(
          error.toString(),
          defaultValue: error.toString(),
        ),
      );
    } finally {
      _markPagedAccountProfilesFetchFinished(generation);
      if (page.value > 1 &&
          _isCurrentPagedAccountProfilesGeneration(generation).value) {
        isPagedAccountProfilesLoadingStreamValue.addValue(
          AccountProfilesRepositoryContractPrimBool.fromRaw(
            false,
            defaultValue: false,
          ),
        );
      }
    }
  }

  AccountProfilesRepositoryContractPrimInt
  _nextPagedAccountProfilesGeneration() {
    _paginationState.activeGeneration =
        AccountProfilesRepositoryContractPrimInt.fromRaw(
          _paginationState.activeGeneration.value + 1,
          defaultValue: 0,
        );
    return _paginationState.activeGeneration;
  }

  AccountProfilesRepositoryContractPrimBool
  _isCurrentPagedAccountProfilesGeneration(
    AccountProfilesRepositoryContractPrimInt generation,
  ) {
    return AccountProfilesRepositoryContractPrimBool.fromRaw(
      _paginationState.activeGeneration == generation,
      defaultValue: false,
    );
  }

  void _markPagedAccountProfilesFetchStarted(
    AccountProfilesRepositoryContractPrimInt generation,
  ) {
    _paginationState.inFlightGenerations.add(generation);
    if (_isCurrentPagedAccountProfilesGeneration(generation).value) {
      _paginationState.isFetching =
          AccountProfilesRepositoryContractPrimBool.fromRaw(
            true,
            defaultValue: true,
          );
    }
  }

  void _markPagedAccountProfilesFetchFinished(
    AccountProfilesRepositoryContractPrimInt generation,
  ) {
    _paginationState.inFlightGenerations.remove(generation);
    if (_isCurrentPagedAccountProfilesGeneration(generation).value) {
      _paginationState.isFetching =
          AccountProfilesRepositoryContractPrimBool.fromRaw(
            _paginationState.inFlightGenerations.contains(generation),
            defaultValue: false,
          );
    }
  }

  void _commitPagedAccountProfilesSuccess({
    required AccountProfilesRepositoryContractPrimInt page,
    required PagedAccountProfilesResult result,
  }) {
    final accumulatedProfiles = page.value <= 1
        ? List<AccountProfileModel>.from(result.profiles)
        : <AccountProfileModel>[
            ...?_paginationState
                .pagedAccountProfilesStreamValue
                .value
                ?.profiles,
            ...result.profiles,
          ];
    _paginationState.currentPage = page;
    _paginationState.hasMore =
        AccountProfilesRepositoryContractPrimBool.fromRaw(
          result.hasMore,
          defaultValue: true,
        );
    hasMorePagedAccountProfilesStreamValue.addValue(_paginationState.hasMore);
    publicDiscoveryFilterFacetsStreamValue.addValue(
      result.discoveryFilterFacets,
    );
    publicDiscoveryFilterCatalogStreamValue.addValue(
      result.discoveryFilterCatalog,
    );
    pagedAccountProfilesStreamValue.addValue(
      pagedAccountProfilesResultFromRaw(
        profiles: accumulatedProfiles,
        hasMore: result.hasMore,
        discoveryFilterFacets: result.discoveryFilterFacets,
        discoveryFilterCatalog: result.discoveryFilterCatalog,
      ),
    );
    discoveryFilteredAccountProfilesStreamValue.addValue(accumulatedProfiles);
    pagedAccountProfilesErrorStreamValue.addValue(null);
  }

  void _commitPagedAccountProfilesError({
    required AccountProfilesRepositoryContractPrimInt page,
    required AccountProfilesRepositoryContractPrimString errorMessage,
  }) {
    pagedAccountProfilesErrorStreamValue.addValue(errorMessage);
    _paginationState.hasMore =
        AccountProfilesRepositoryContractPrimBool.fromRaw(
          false,
          defaultValue: false,
        );
    hasMorePagedAccountProfilesStreamValue.addValue(_paginationState.hasMore);
    if (page.value == 1) {
      publicDiscoveryFilterFacetsStreamValue.addValue(null);
      publicDiscoveryFilterCatalogStreamValue.addValue(null);
      discoveryFilteredAccountProfilesStreamValue.addValue(
        const <AccountProfileModel>[],
      );
      pagedAccountProfilesStreamValue.addValue(
        pagedAccountProfilesResultFromRaw(
          profiles: <AccountProfileModel>[],
          hasMore: false,
          discoveryFilterFacets: null,
          discoveryFilterCatalog: null,
        ),
      );
      return;
    }

    final currentProfiles =
        _paginationState.pagedAccountProfilesStreamValue.value?.profiles ??
        const <AccountProfileModel>[];
    pagedAccountProfilesStreamValue.addValue(
      pagedAccountProfilesResultFromRaw(
        profiles: currentProfiles,
        hasMore: false,
        discoveryFilterFacets: publicDiscoveryFilterFacetsStreamValue.value,
        discoveryFilterCatalog: publicDiscoveryFilterCatalogStreamValue.value,
      ),
    );
  }

  void _resetPagedAccountProfilesState() {
    _paginationState.currentPage =
        AccountProfilesRepositoryContractPrimInt.fromRaw(0, defaultValue: 0);
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
    publicDiscoveryFilterFacetsStreamValue.addValue(null);
    publicDiscoveryFilterCatalogStreamValue.addValue(null);
  }

  Future<void> _fetchNestedGroupMembersPage({
    required AccountProfilesRepositoryContractPrimString membersPath,
    required _NestedGroupMembersPaginationState state,
    required AccountProfilesRepositoryContractPrimString? cursor,
    required AccountProfilesRepositoryContractPrimInt generation,
  }) async {
    if (generation.value != state.activeGeneration.value ||
        state.isFetching.value) {
      return;
    }

    final normalizedCursor = cursor?.value.trim();
    state.isFetching = AccountProfilesRepositoryContractPrimBool.fromRaw(
      true,
      defaultValue: true,
    );
    state.isPageLoadingStreamValue.addValue(
      AccountProfilesRepositoryContractPrimBool.fromRaw(
        true,
        defaultValue: true,
      ),
    );

    try {
      final result = await fetchNestedGroupMembersPageByPath(
        membersPath,
        cursor: normalizedCursor == null || normalizedCursor.isEmpty
            ? null
            : AccountProfilesRepositoryContractPrimString.fromRaw(
                normalizedCursor,
                defaultValue: '',
                isRequired: true,
              ),
        search: state.search,
      );
      if (generation.value != state.activeGeneration.value) {
        return;
      }
      final accumulatedItems =
          normalizedCursor == null || normalizedCursor.isEmpty
          ? List<AccountProfileNestedGroupMember>.from(result.items)
          : <AccountProfileNestedGroupMember>[
              ...(state.itemsStreamValue.value),
              ...result.items,
            ];
      final seenIds = <String>{};
      final deduplicatedItems = accumulatedItems
          .where((item) => seenIds.add(item.id))
          .toList(growable: false);
      final nextCursor = result.nextCursorValue?.value.trim();
      state.nextCursor = nextCursor == null || nextCursor.isEmpty
          ? null
          : AccountProfilesRepositoryContractPrimString.fromRaw(
              nextCursor,
              defaultValue: '',
              isRequired: true,
            );
      state.hasMore = AccountProfilesRepositoryContractPrimBool.fromRaw(
        result.hasMore,
        defaultValue: result.hasMore,
      );
      state.hasLoaded = AccountProfilesRepositoryContractPrimBool.fromRaw(
        true,
        defaultValue: true,
      );
      state.itemsStreamValue.addValue(deduplicatedItems);
      state.hasMoreStreamValue.addValue(state.hasMore);
      if ((normalizedCursor == null || normalizedCursor.isEmpty) &&
          state.search == null) {
        state.isSearchAvailable =
            AccountProfilesRepositoryContractPrimBool.fromRaw(
              result.hasMore,
              defaultValue: result.hasMore,
            );
        state.isSearchAvailableStreamValue.addValue(state.isSearchAvailable);
      }
      state.errorStreamValue.addValue(null);
    } catch (error) {
      if (generation.value != state.activeGeneration.value) {
        return;
      }
      if (normalizedCursor == null || normalizedCursor.isEmpty) {
        state.hasMore = AccountProfilesRepositoryContractPrimBool.fromRaw(
          false,
          defaultValue: false,
        );
        state.nextCursor = null;
        state.hasMoreStreamValue.addValue(state.hasMore);
        state.itemsStreamValue.addValue(
          const <AccountProfileNestedGroupMember>[],
        );
      } else {
        // Later-page failures must preserve the existing continuation state so
        // the same cursor can be retried without recreating repository state.
        state.hasMoreStreamValue.addValue(state.hasMore);
      }
      state.errorStreamValue.addValue(
        AccountProfilesRepositoryContractPrimString.fromRaw(error.toString()),
      );
    } finally {
      if (generation.value == state.activeGeneration.value) {
        state.isFetching = AccountProfilesRepositoryContractPrimBool.fromRaw(
          false,
          defaultValue: false,
        );
        state.isPageLoadingStreamValue.addValue(
          AccountProfilesRepositoryContractPrimBool.fromRaw(
            false,
            defaultValue: false,
          ),
        );
      }
    }
  }

  _NestedGroupMembersPaginationState _nestedGroupMembersState(
    AccountProfilesRepositoryContractPrimString membersPath,
  ) {
    return _nestedGroupPaginationRegistry.stateFor(membersPath);
  }

  void _resetNestedGroupMembersState(_NestedGroupMembersPaginationState state) {
    state.activeGeneration = AccountProfilesRepositoryContractPrimInt.fromRaw(
      state.activeGeneration.value + 1,
      defaultValue: state.activeGeneration.value + 1,
    );
    state.nextCursor = null;
    state.hasMore = AccountProfilesRepositoryContractPrimBool.fromRaw(
      true,
      defaultValue: true,
    );
    state.isFetching = AccountProfilesRepositoryContractPrimBool.fromRaw(
      false,
      defaultValue: false,
    );
    state.hasLoaded = AccountProfilesRepositoryContractPrimBool.fromRaw(
      false,
      defaultValue: false,
    );
    state.hasMoreStreamValue.addValue(
      AccountProfilesRepositoryContractPrimBool.fromRaw(
        true,
        defaultValue: true,
      ),
    );
    state.isPageLoadingStreamValue.addValue(
      AccountProfilesRepositoryContractPrimBool.fromRaw(
        false,
        defaultValue: false,
      ),
    );
  }
}

class _AccountProfilesPaginationState {
  final StreamValue<PagedAccountProfilesResult?>
  pagedAccountProfilesStreamValue = StreamValue<PagedAccountProfilesResult?>(
    defaultValue: null,
  );
  final StreamValue<AccountProfilesRepositoryContractPrimBool>
  hasMoreStreamValue = StreamValue<AccountProfilesRepositoryContractPrimBool>(
    defaultValue: AccountProfilesRepositoryContractPrimBool.fromRaw(
      true,
      defaultValue: true,
    ),
  );
  final StreamValue<AccountProfilesRepositoryContractPrimBool>
  isPageLoadingStreamValue =
      StreamValue<AccountProfilesRepositoryContractPrimBool>(
        defaultValue: AccountProfilesRepositoryContractPrimBool.fromRaw(
          false,
          defaultValue: false,
        ),
      );
  final StreamValue<AccountProfilesRepositoryContractPrimString?>
  errorStreamValue =
      StreamValue<AccountProfilesRepositoryContractPrimString?>();
  AccountProfilesRepositoryContractPrimInt currentPage =
      AccountProfilesRepositoryContractPrimInt.fromRaw(0, defaultValue: 0);
  AccountProfilesRepositoryContractPrimInt activeGeneration =
      AccountProfilesRepositoryContractPrimInt.fromRaw(0, defaultValue: 0);
  final Set<AccountProfilesRepositoryContractPrimInt> inFlightGenerations =
      <AccountProfilesRepositoryContractPrimInt>{};
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

class _NestedGroupMembersPaginationRegistry {
  final List<_NestedGroupMembersPaginationState> _states =
      <_NestedGroupMembersPaginationState>[];

  _NestedGroupMembersPaginationState stateFor(
    AccountProfilesRepositoryContractPrimString membersPath,
  ) {
    final normalizedPath = AccountProfilesRepositoryContractPrimString.fromRaw(
      membersPath.value.trim(),
      defaultValue: '',
      isRequired: true,
    );
    for (final state in _states) {
      if (state.membersPath == normalizedPath) {
        return state;
      }
    }

    final createdState = _NestedGroupMembersPaginationState(
      membersPath: normalizedPath,
    );
    _states.add(createdState);
    return createdState;
  }

  void retain(AccountProfilesRepositoryContractPrimString membersPath) {
    final state = stateFor(membersPath);
    state.retainCount = AccountProfilesRepositoryContractPrimInt.fromRaw(
      state.retainCount.value + 1,
      defaultValue: state.retainCount.value + 1,
    );
  }

  void release(AccountProfilesRepositoryContractPrimString membersPath) {
    final normalizedPath = AccountProfilesRepositoryContractPrimString.fromRaw(
      membersPath.value.trim(),
      defaultValue: '',
      isRequired: true,
    );
    _NestedGroupMembersPaginationState? state;
    for (final candidate in _states) {
      if (candidate.membersPath == normalizedPath) {
        state = candidate;
        break;
      }
    }
    if (state == null) return;

    state.retainCount = AccountProfilesRepositoryContractPrimInt.fromRaw(
      state.retainCount.value - 1,
      defaultValue: state.retainCount.value - 1,
    );
    if (state.retainCount.value > 0) return;

    _states.remove(state);
    state.dispose();
  }
}

class _NestedGroupMembersPaginationState {
  _NestedGroupMembersPaginationState({required this.membersPath});

  final AccountProfilesRepositoryContractPrimString membersPath;
  final StreamValue<List<AccountProfileNestedGroupMember>> itemsStreamValue =
      StreamValue<List<AccountProfileNestedGroupMember>>(
        defaultValue: const <AccountProfileNestedGroupMember>[],
      );
  final StreamValue<AccountProfilesRepositoryContractPrimBool>
  hasMoreStreamValue = StreamValue<AccountProfilesRepositoryContractPrimBool>(
    defaultValue: AccountProfilesRepositoryContractPrimBool.fromRaw(
      true,
      defaultValue: true,
    ),
  );
  final StreamValue<AccountProfilesRepositoryContractPrimBool>
  isPageLoadingStreamValue =
      StreamValue<AccountProfilesRepositoryContractPrimBool>(
        defaultValue: AccountProfilesRepositoryContractPrimBool.fromRaw(
          false,
          defaultValue: false,
        ),
      );
  final StreamValue<AccountProfilesRepositoryContractPrimBool>
  isSearchAvailableStreamValue =
      StreamValue<AccountProfilesRepositoryContractPrimBool>(
        defaultValue: AccountProfilesRepositoryContractPrimBool.fromRaw(
          false,
          defaultValue: false,
        ),
      );
  final StreamValue<AccountProfilesRepositoryContractPrimString?>
  errorStreamValue =
      StreamValue<AccountProfilesRepositoryContractPrimString?>();
  AccountProfilesRepositoryContractPrimString? nextCursor;
  AccountProfilesRepositoryContractPrimString? search;
  AccountProfilesRepositoryContractPrimInt activeGeneration =
      AccountProfilesRepositoryContractPrimInt.fromRaw(0, defaultValue: 0);
  AccountProfilesRepositoryContractPrimBool isSearchAvailable =
      AccountProfilesRepositoryContractPrimBool.fromRaw(
        false,
        defaultValue: false,
      );
  AccountProfilesRepositoryContractPrimBool hasMore =
      AccountProfilesRepositoryContractPrimBool.fromRaw(
        true,
        defaultValue: true,
      );
  AccountProfilesRepositoryContractPrimBool hasLoaded =
      AccountProfilesRepositoryContractPrimBool.fromRaw(
        false,
        defaultValue: false,
      );
  AccountProfilesRepositoryContractPrimBool isFetching =
      AccountProfilesRepositoryContractPrimBool.fromRaw(
        false,
        defaultValue: false,
      );
  AccountProfilesRepositoryContractPrimInt retainCount =
      AccountProfilesRepositoryContractPrimInt.fromRaw(0, defaultValue: 0);

  void dispose() {
    activeGeneration = AccountProfilesRepositoryContractPrimInt.fromRaw(
      activeGeneration.value + 1,
      defaultValue: activeGeneration.value + 1,
    );
    itemsStreamValue.dispose();
    hasMoreStreamValue.dispose();
    isPageLoadingStreamValue.dispose();
    isSearchAvailableStreamValue.dispose();
    errorStreamValue.dispose();
  }
}
