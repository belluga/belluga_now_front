import 'dart:async';

import 'package:belluga_discovery_filters/belluga_discovery_filters.dart';
import 'package:belluga_now/domain/app_data/app_data.dart';
import 'package:belluga_now/domain/app_data/discovery_filter_selection_snapshot.dart';
import 'package:belluga_now/domain/app_data/value_object/app_data_discovery_filter_token_value.dart';
import 'package:belluga_now/domain/partners/account_profile_model.dart';
import 'package:belluga_now/domain/partners/profile_type_registry.dart';
import 'package:belluga_now/domain/partners/value_objects/profile_type_key_value.dart';
import 'package:belluga_now/domain/repositories/account_profiles_repository_contract.dart';
import 'package:belluga_now/domain/repositories/app_data_repository_contract.dart';
import 'package:belluga_now/domain/repositories/auth_repository_contract.dart';
import 'package:belluga_now/domain/repositories/discovery_filters_repository_contract.dart';
import 'package:belluga_now/domain/repositories/schedule_repository_contract.dart';
import 'package:belluga_now/domain/repositories/user_location_repository_contract.dart';
import 'package:belluga_now/domain/repositories/value_objects/account_profiles_repository_contract_values.dart';
import 'package:belluga_now/domain/repositories/value_objects/discovery_filters_repository_contract_values.dart';
import 'package:belluga_now/domain/schedule/event_model.dart';
import 'package:belluga_now/domain/services/location_origin_service_contract.dart';
import 'package:belluga_now/infrastructure/services/location_origin_resolution_request_factory.dart';
import 'package:belluga_now/presentation/shared/visuals/account_profile_visual_resolver.dart';
import 'package:belluga_now/presentation/shared/visuals/resolved_account_profile_visual.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value.dart';

enum FavoriteToggleOutcome {
  toggled,
  requiresAuthentication,
}

class DiscoveryScreenController implements Disposable {
  DiscoveryScreenController({
    AccountProfilesRepositoryContract? accountProfilesRepository,
    AuthRepositoryContract? authRepository,
    DiscoveryFiltersRepositoryContract? discoveryFiltersRepository,
    AppDataRepositoryContract? appDataRepository,
    ScheduleRepositoryContract? scheduleRepository,
    LocationOriginServiceContract? locationOriginService,
  })  : _accountProfilesRepository = accountProfilesRepository ??
            GetIt.I.get<AccountProfilesRepositoryContract>(),
        _authRepository = authRepository ??
            (GetIt.I.isRegistered<AuthRepositoryContract>()
                ? GetIt.I.get<AuthRepositoryContract>()
                : null),
        _discoveryFiltersRepository = discoveryFiltersRepository ??
            (GetIt.I.isRegistered<DiscoveryFiltersRepositoryContract>()
                ? GetIt.I.get<DiscoveryFiltersRepositoryContract>()
                : null),
        _appDataRepository = appDataRepository ??
            (GetIt.I.isRegistered<AppDataRepositoryContract>()
                ? GetIt.I.get<AppDataRepositoryContract>()
                : null),
        _scheduleRepository = scheduleRepository,
        _locationOriginService = locationOriginService ??
            GetIt.I.get<LocationOriginServiceContract>();

  final AccountProfilesRepositoryContract _accountProfilesRepository;
  final AuthRepositoryContract? _authRepository;
  final DiscoveryFiltersRepositoryContract? _discoveryFiltersRepository;
  final AppDataRepositoryContract? _appDataRepository;
  ScheduleRepositoryContract? _scheduleRepository;
  final LocationOriginServiceContract _locationOriginService;

  static const Duration _searchDebounceDuration = Duration(milliseconds: 350);
  static const String _discoveryAccountProfilesSurface =
      'discovery.account_profiles';
  static const DiscoveryFilterPolicy _discoveryAccountProfilesFilterPolicy =
      DiscoveryFilterPolicy(
    primarySelectionMode: DiscoveryFilterSelectionMode.single,
    taxonomySelectionMode: DiscoveryFilterSelectionMode.multiple,
    primaryLayoutMode: DiscoveryFilterLayoutMode.row,
    taxonomyLayoutMode: DiscoveryFilterLayoutMode.row,
  );
  static const double _filterPanelScrollHideEpsilon = 0.5;

  StreamSubscription<Set<AccountProfilesRepositoryContractPrimString>>?
      _favoriteIdsSubscription;
  StreamSubscription<Object?>? _userLocationSubscription;
  StreamSubscription<Object?>? _lastKnownLocationSubscription;
  Timer? _searchDebounce;
  bool _initialized = false;
  bool _isDisposed = false;
  int _lifecycleToken = 0;
  int _reloadRequestToken = 0;
  bool _isFetchingPage = false;
  bool _isFetchingLiveNow = false;
  bool _hasPendingLiveNowReload = false;
  bool _scrollListenerAttached = false;
  bool _isProgrammaticSearchTextChange = false;
  String? _lastOriginSignature;

  final ScrollController scrollController = ScrollController();
  final searchQueryStreamValue = StreamValue<String>(defaultValue: '');
  final selectedTypeFilterStreamValue = StreamValue<String?>();
  final discoveryFilterCatalogStreamValue = StreamValue<DiscoveryFilterCatalog>(
    defaultValue: const DiscoveryFilterCatalog(
      surface: _discoveryAccountProfilesSurface,
    ),
  );
  final discoveryFilterSelectionStreamValue =
      StreamValue<DiscoveryFilterSelection>(
    defaultValue: const DiscoveryFilterSelection(),
  );
  final isDiscoveryFilterPanelVisibleStreamValue =
      StreamValue<bool>(defaultValue: false);
  final isDiscoveryFilterCatalogLoadingStreamValue =
      StreamValue<bool>(defaultValue: false);
  final availableTypesStreamValue =
      StreamValue<List<String>>(defaultValue: const []);
  final favoriteIdsStreamValue =
      StreamValue<Set<String>>(defaultValue: const {});
  final isLoadingStreamValue = StreamValue<bool>(defaultValue: false);
  final isRefreshingStreamValue = StreamValue<bool>(defaultValue: false);
  final isPageLoadingStreamValue = StreamValue<bool>(defaultValue: false);
  final hasMoreStreamValue = StreamValue<bool>(defaultValue: true);
  final hasLoadedStreamValue = StreamValue<bool>(defaultValue: false);
  final isSearchingStreamValue = StreamValue<bool>(defaultValue: false);
  final TextEditingController searchController = TextEditingController();

  StreamValue<List<EventModel>?> get liveNowEventsStreamValue =>
      _resolveScheduleRepository()?.discoveryLiveNowEventsStreamValue ??
      StreamValue<List<EventModel>?>(defaultValue: null);
  StreamValue<List<AccountProfileModel>> get filteredPartnersStreamValue =>
      _accountProfilesRepository.discoveryFilteredAccountProfilesStreamValue;
  StreamValue<List<AccountProfileModel>> get nearbyStreamValue =>
      _accountProfilesRepository.discoveryNearbyAccountProfilesStreamValue;

  Future<void> init() async {
    if (_initialized) {
      await _loadFavoriteIds();
      if (!hasLoadedStreamValue.value && !_isFetchingPage) {
        await _reloadPartners(showFullScreenLoader: false);
      }
      unawaited(_reloadLiveNowSection());
      return;
    }
    _initialized = true;

    searchController.addListener(_handleSearchControllerChanged);
    _attachScrollListener();
    _attachLocationListeners();

    try {
      await _accountProfilesRepository.init();
    } catch (error) {
      debugPrint(
        'DiscoveryScreenController.init repository init failed: $error',
      );
    }
    _favoriteIdsSubscription ??= _accountProfilesRepository
        .favoriteAccountProfileIdsStreamValue.stream
        .listen(
      (ids) {
        favoriteIdsStreamValue.addValue(
          ids.map((entry) => entry.value).toSet(),
        );
      },
    );
    await _loadFavoriteIds();
    _hydrateFromRepositoryCache();
    await _loadDiscoveryFilterCatalog();
    await _reloadPartners(showFullScreenLoader: false);
  }

  void _handleSearchControllerChanged() {
    if (_isProgrammaticSearchTextChange) {
      return;
    }
    setSearchQuery(searchController.text);
  }

  void _attachScrollListener() {
    if (_scrollListenerAttached) return;
    _scrollListenerAttached = true;
    scrollController.addListener(() {
      if (!scrollController.hasClients) {
        return;
      }
      updateDiscoveryFilterPanelVisibilityFromScroll(
        scrollController.position.pixels,
      );
      if (_isFetchingPage ||
          isLoadingStreamValue.value ||
          isRefreshingStreamValue.value ||
          !hasMoreStreamValue.value) {
        return;
      }
      const threshold = 280.0;
      final position = scrollController.position;
      if (position.pixels + threshold >= position.maxScrollExtent) {
        unawaited(loadNextPage());
      }
    });
  }

  void _attachLocationListeners() {
    if (!GetIt.I.isRegistered<UserLocationRepositoryContract>()) {
      return;
    }
    final repository = GetIt.I.get<UserLocationRepositoryContract>();
    _lastOriginSignature = _originSignature();

    _userLocationSubscription ??=
        repository.userLocationStreamValue.stream.listen((_) {
      _onLocationUpdated();
    });
    _lastKnownLocationSubscription ??=
        repository.lastKnownLocationStreamValue.stream.listen((_) {
      _onLocationUpdated();
    });
  }

  void _onLocationUpdated() {
    final signature = _originSignature();
    if (signature == null || signature == _lastOriginSignature) {
      return;
    }
    _lastOriginSignature = signature;
    unawaited(_reloadLiveNowSection());
  }

  Future<void> _reloadPartners({bool showFullScreenLoader = false}) async {
    if (_isDisposed) {
      return;
    }
    final lifecycleToken = _lifecycleToken;
    final requestToken = ++_reloadRequestToken;
    final useFullScreenLoader = showFullScreenLoader ||
        (!hasLoadedStreamValue.value &&
            filteredPartnersStreamValue.value.isEmpty);

    hasMoreStreamValue.addValue(true);

    if (useFullScreenLoader) {
      _clearVisibleData();
      isLoadingStreamValue.addValue(true);
      hasLoadedStreamValue.addValue(false);
    } else {
      isRefreshingStreamValue.addValue(true);
    }

    try {
      await _fetchNextPage(isInitial: true, requestToken: requestToken);
    } catch (error) {
      if (_isLifecycleTokenActive(lifecycleToken)) {
        debugPrint('DiscoveryScreenController._reloadPartners failed: $error');
      }
    } finally {
      if (_isLifecycleTokenActive(lifecycleToken) &&
          requestToken == _reloadRequestToken) {
        hasLoadedStreamValue.addValue(true);
        isLoadingStreamValue.addValue(false);
        isRefreshingStreamValue.addValue(false);
        unawaited(_reloadLiveNowSection());
      }
    }
  }

  void _clearVisibleData() {
    _updateAvailableTypes();
  }

  Future<void> loadNextPage() async {
    await _fetchNextPage(
      isInitial: false,
      requestToken: _reloadRequestToken,
    );
  }

  Future<void> _fetchNextPage({
    required bool isInitial,
    required int requestToken,
  }) async {
    if (_isFetchingPage) return;
    if (!isInitial && !hasMoreStreamValue.value) return;

    final lifecycleToken = _lifecycleToken;
    _isFetchingPage = true;
    if (!isInitial) {
      isPageLoadingStreamValue.addValue(true);
    }

    try {
      final query = searchQueryStreamValue.value.trim();
      final selectedType = selectedTypeFilterStreamValue.value;
      final typeFilters = _selectedAccountProfileTypeFilters();
      final taxonomyFilters = _selectedAccountProfileTaxonomyFilters();
      final shouldLoadFirstPage = isInitial ||
          _accountProfilesRepository.currentPagedAccountProfilesPage.value <= 0;
      if (shouldLoadFirstPage) {
        await _accountProfilesRepository.loadAccountProfilesPage(
          query: query.isEmpty
              ? null
              : AccountProfilesRepositoryContractPrimString.fromRaw(query),
          typeFilter: selectedType == null
              ? null
              : AccountProfilesRepositoryContractPrimString.fromRaw(
                  selectedType,
                ),
          typeFilters: typeFilters,
          taxonomyFilters: taxonomyFilters,
        );
      } else {
        await _accountProfilesRepository.loadNextAccountProfilesPage(
          query: query.isEmpty
              ? null
              : AccountProfilesRepositoryContractPrimString.fromRaw(query),
          typeFilter: selectedType == null
              ? null
              : AccountProfilesRepositoryContractPrimString.fromRaw(
                  selectedType,
                ),
          typeFilters: typeFilters,
          taxonomyFilters: taxonomyFilters,
        );
      }

      final pageResult =
          _accountProfilesRepository.pagedAccountProfilesStreamValue.value;
      if (pageResult == null) {
        return;
      }

      final loadedPage =
          _accountProfilesRepository.currentPagedAccountProfilesPage;
      if (loadedPage.value <= 0) {
        return;
      }

      if (!_isLifecycleTokenActive(lifecycleToken) ||
          requestToken != _reloadRequestToken) {
        return;
      }

      hasMoreStreamValue.addValue(pageResult.hasMore);

      _updateAvailableTypes();
      if (_shouldSyncNearby(
        query: query,
        selectedType: selectedType,
        typeFilters: typeFilters,
        taxonomyFilters: taxonomyFilters,
      )) {
        await _accountProfilesRepository.syncDiscoveryNearbyAccountProfiles();
      }
    } finally {
      _isFetchingPage = false;
      if (_isLifecycleTokenActive(lifecycleToken) &&
          !isInitial &&
          requestToken == _reloadRequestToken) {
        isPageLoadingStreamValue.addValue(false);
      }
    }
  }

  void setSearchQuery(String query) {
    if (searchQueryStreamValue.value == query) {
      return;
    }
    searchQueryStreamValue.addValue(query);
    _scheduleReload(immediate: false);
  }

  void setTypeFilter(String? type) {
    if (selectedTypeFilterStreamValue.value == type) {
      return;
    }
    selectedTypeFilterStreamValue.addValue(type);
    _scheduleReload(immediate: true);
  }

  void setDiscoveryFilterSelection(DiscoveryFilterSelection selection) {
    final repaired = _repairDiscoveryFilterSelection(selection);
    if (_sameDiscoveryFilterSelection(
      discoveryFilterSelectionStreamValue.value,
      repaired,
    )) {
      return;
    }
    discoveryFilterSelectionStreamValue.addValue(repaired);
    unawaited(_persistDiscoveryFilterSelection(repaired));
    _scheduleReload(immediate: true);
  }

  DiscoveryFilterPolicy get discoveryFilterPolicy =>
      _discoveryAccountProfilesFilterPolicy;

  void toggleDiscoveryFilterPanel() {
    setDiscoveryFilterPanelVisible(
      !isDiscoveryFilterPanelVisibleStreamValue.value,
    );
  }

  void setDiscoveryFilterPanelVisible(bool visible) {
    if (isDiscoveryFilterPanelVisibleStreamValue.value == visible) {
      return;
    }
    isDiscoveryFilterPanelVisibleStreamValue.addValue(visible);
  }

  void updateDiscoveryFilterPanelVisibilityFromScroll(double pixels) {
    if (pixels <= _filterPanelScrollHideEpsilon ||
        !isDiscoveryFilterPanelVisibleStreamValue.value) {
      return;
    }
    setDiscoveryFilterPanelVisible(false);
  }

  bool get hasActiveFilterState {
    final selectedType = selectedTypeFilterStreamValue.value;
    if (selectedType != null && selectedType.isNotEmpty) {
      return true;
    }
    if (discoveryFilterSelectionStreamValue.value.isNotEmpty) {
      return true;
    }
    return searchQueryStreamValue.value.trim().isNotEmpty;
  }

  bool consumeBackNavigationIfNeeded() {
    if (!hasActiveFilterState) {
      return false;
    }
    resetToDefaultDiscoveryState();
    return true;
  }

  void resetToDefaultDiscoveryState() {
    _searchDebounce?.cancel();

    var changed = false;
    final selectedType = selectedTypeFilterStreamValue.value;
    if (selectedType != null && selectedType.isNotEmpty) {
      selectedTypeFilterStreamValue.addValue(null);
      changed = true;
    }

    if (discoveryFilterSelectionStreamValue.value.isNotEmpty) {
      const emptySelection = DiscoveryFilterSelection();
      discoveryFilterSelectionStreamValue.addValue(emptySelection);
      unawaited(_persistDiscoveryFilterSelection(emptySelection));
      changed = true;
    }

    if (searchQueryStreamValue.value.isNotEmpty) {
      searchQueryStreamValue.addValue('');
      changed = true;
    }

    if (searchController.text.isNotEmpty) {
      _setSearchControllerText('');
    }

    if (isSearchingStreamValue.value) {
      isSearchingStreamValue.addValue(false);
    }
    if (isDiscoveryFilterPanelVisibleStreamValue.value) {
      isDiscoveryFilterPanelVisibleStreamValue.addValue(false);
    }

    if (changed) {
      _scheduleReload(immediate: true);
    }
  }

  void _setSearchControllerText(String value) {
    if (searchController.text == value) {
      return;
    }
    _isProgrammaticSearchTextChange = true;
    searchController.text = value;
    searchController.selection = TextSelection.collapsed(
      offset: value.length,
    );
    _isProgrammaticSearchTextChange = false;
  }

  void _scheduleReload({required bool immediate}) {
    _searchDebounce?.cancel();
    if (immediate) {
      unawaited(_reloadPartners());
      return;
    }
    _searchDebounce = Timer(_searchDebounceDuration, () {
      unawaited(_reloadPartners());
    });
  }

  void toggleSearch() {
    final next = !isSearchingStreamValue.value;
    isSearchingStreamValue.addValue(next);
    if (next) {
      if (selectedTypeFilterStreamValue.value != null) {
        setTypeFilter(null);
      }
      if (discoveryFilterSelectionStreamValue.value.isNotEmpty) {
        setDiscoveryFilterSelection(const DiscoveryFilterSelection());
      }
      return;
    }
    if (!next) {
      if (searchController.text.isNotEmpty ||
          searchQueryStreamValue.value.isNotEmpty) {
        _setSearchControllerText('');
        setSearchQuery('');
      }
    }
  }

  FavoriteToggleOutcome toggleFavorite(String accountProfileId) {
    if (!_isAuthorized) {
      return FavoriteToggleOutcome.requiresAuthentication;
    }
    final current = Set<String>.from(favoriteIdsStreamValue.value);
    if (current.contains(accountProfileId)) {
      current.remove(accountProfileId);
    } else {
      current.add(accountProfileId);
    }
    favoriteIdsStreamValue.addValue(current);

    unawaited(
      _accountProfilesRepository.toggleFavorite(
        AccountProfilesRepositoryContractPrimString.fromRaw(accountProfileId),
      ),
    );
    return FavoriteToggleOutcome.toggled;
  }

  bool isFavorite(String accountProfileId) {
    return favoriteIdsStreamValue.value.contains(accountProfileId);
  }

  StreamValue<Set<String>> get favoriteIdsStream => favoriteIdsStreamValue;

  Future<void> _loadFavoriteIds() async {
    final ids = Set<String>.from(
      _accountProfilesRepository.favoriteAccountProfileIdsStreamValue.value
          .map((entry) => entry.value),
    );
    favoriteIdsStreamValue.addValue(ids);
  }

  Future<void> _loadDiscoveryFilterCatalog() async {
    final repository = _discoveryFiltersRepository;
    if (repository == null) {
      return;
    }

    isDiscoveryFilterCatalogLoadingStreamValue.addValue(true);
    try {
      final catalog = await repository.fetchCatalog(
        discoveryFiltersRepoText(_discoveryAccountProfilesSurface),
      );
      discoveryFilterCatalogStreamValue.addValue(catalog);

      final restoredSelection = await _loadPersistedDiscoveryFilterSelection();
      final repaired = _repairDiscoveryFilterSelection(
        restoredSelection ?? discoveryFilterSelectionStreamValue.value,
        catalogOverride: catalog,
      );
      if (!_sameDiscoveryFilterSelection(
        discoveryFilterSelectionStreamValue.value,
        repaired,
      )) {
        discoveryFilterSelectionStreamValue.addValue(repaired);
      }
      if (restoredSelection != null &&
          !_sameDiscoveryFilterSelection(restoredSelection, repaired)) {
        unawaited(_persistDiscoveryFilterSelection(repaired));
      }
    } catch (error) {
      debugPrint(
        'DiscoveryScreenController._loadDiscoveryFilterCatalog failed: $error',
      );
      discoveryFilterCatalogStreamValue.addValue(
        const DiscoveryFilterCatalog(
          surface: _discoveryAccountProfilesSurface,
        ),
      );
    } finally {
      isDiscoveryFilterCatalogLoadingStreamValue.addValue(false);
    }
  }

  Future<DiscoveryFilterSelection?>
      _loadPersistedDiscoveryFilterSelection() async {
    final repository = _appDataRepository;
    if (repository == null) {
      return null;
    }
    final stored = await repository.getDiscoveryFilterSelection(
      AppDataDiscoveryFilterTokenValue.fromRaw(
        _discoveryAccountProfilesSurface,
      ),
    );
    if (stored == null) {
      return null;
    }
    return _discoveryFilterSelectionFromSnapshot(stored);
  }

  Future<void> _persistDiscoveryFilterSelection(
    DiscoveryFilterSelection selection,
  ) async {
    final repository = _appDataRepository;
    if (repository == null) {
      return;
    }
    try {
      await repository.setDiscoveryFilterSelection(
        AppDataDiscoveryFilterTokenValue.fromRaw(
          _discoveryAccountProfilesSurface,
        ),
        _discoveryFilterSelectionSnapshot(selection),
      );
    } catch (error) {
      debugPrint(
        'DiscoveryScreenController._persistDiscoveryFilterSelection failed: $error',
      );
    }
  }

  DiscoveryFilterSelection _discoveryFilterSelectionFromSnapshot(
    AppDataDiscoveryFilterSelectionSnapshot snapshot,
  ) {
    return DiscoveryFilterSelection(
      primaryKeys: snapshot.primaryKeys
          .map((value) => value.value)
          .where((value) => value.isNotEmpty)
          .toSet(),
      taxonomyTermKeys: <String, Set<String>>{
        for (final taxonomy in snapshot.taxonomySelections)
          if (!taxonomy.isEmpty)
            taxonomy.taxonomyKey.value: taxonomy.termKeys
                .map((value) => value.value)
                .where((value) => value.isNotEmpty)
                .toSet(),
      },
    );
  }

  AppDataDiscoveryFilterSelectionSnapshot _discoveryFilterSelectionSnapshot(
    DiscoveryFilterSelection selection,
  ) {
    return AppDataDiscoveryFilterSelectionSnapshot(
      primaryKeys: selection.primaryKeys
          .map(AppDataDiscoveryFilterTokenValue.fromRaw)
          .where((value) => value.value.isNotEmpty)
          .toList(growable: false),
      taxonomySelections: selection.taxonomyTermKeys.entries
          .map(
            (entry) => AppDataDiscoveryFilterTaxonomySelection(
              taxonomyKey: AppDataDiscoveryFilterTokenValue.fromRaw(entry.key),
              termKeys: entry.value
                  .map(AppDataDiscoveryFilterTokenValue.fromRaw)
                  .where((value) => value.value.isNotEmpty)
                  .toList(growable: false),
            ),
          )
          .where((selection) => !selection.isEmpty)
          .toList(growable: false),
    );
  }

  String? _originSignature() {
    final coordinate =
        _locationOriginService.resolveCached().effectiveCoordinate;
    if (coordinate == null) {
      return null;
    }
    return '${coordinate.latitude.toStringAsFixed(6)}:'
        '${coordinate.longitude.toStringAsFixed(6)}';
  }

  Future<void> _reloadLiveNowSection() async {
    final scheduleRepository = _resolveScheduleRepository();
    if (scheduleRepository == null) {
      return;
    }
    if (_isFetchingLiveNow) {
      _hasPendingLiveNowReload = true;
      return;
    }

    final resolution = await _locationOriginService.resolve(
      LocationOriginResolutionRequestFactory.create(
        warmUpIfPossible: true,
      ),
    );
    final origin = resolution.effectiveCoordinate;
    final maxDistanceMeters = _resolveDiscoveryMaxDistanceMeters();

    _isFetchingLiveNow = true;
    try {
      await scheduleRepository.refreshDiscoveryLiveNowEvents(
        originLat: origin == null
            ? null
            : ScheduleRepoDouble.fromRaw(
                origin.latitude,
                defaultValue: origin.latitude,
              ),
        originLng: origin == null
            ? null
            : ScheduleRepoDouble.fromRaw(
                origin.longitude,
                defaultValue: origin.longitude,
              ),
        maxDistanceMeters: maxDistanceMeters == null
            ? null
            : ScheduleRepoDouble.fromRaw(
                maxDistanceMeters,
                defaultValue: maxDistanceMeters,
              ),
      );
    } catch (error) {
      debugPrint(
          'DiscoveryScreenController._reloadLiveNowSection failed: $error');
    } finally {
      _isFetchingLiveNow = false;
      if (_hasPendingLiveNowReload) {
        _hasPendingLiveNowReload = false;
        unawaited(_reloadLiveNowSection());
      }
    }
  }

  void _hydrateFromRepositoryCache() {
    final cachedPage =
        _accountProfilesRepository.pagedAccountProfilesStreamValue.value;
    if (cachedPage == null) {
      return;
    }
    final cachedProfiles = cachedPage.profiles;
    if (cachedProfiles.isEmpty) {
      return;
    }

    hasLoadedStreamValue.addValue(true);
    hasMoreStreamValue.addValue(cachedPage.hasMore);
    _updateAvailableTypes();
  }

  bool _shouldSyncNearby({
    required String query,
    required String? selectedType,
    required List<AccountProfilesRepositoryContractPrimString> typeFilters,
    required List<AccountProfilesRepositoryTaxonomyFilter> taxonomyFilters,
  }) {
    return query.isEmpty &&
        (selectedType == null || selectedType.isEmpty) &&
        discoveryFilterSelectionStreamValue.value.isEmpty &&
        typeFilters.isEmpty &&
        taxonomyFilters.isEmpty;
  }

  List<AccountProfilesRepositoryContractPrimString>
      _selectedAccountProfileTypeFilters() {
    final selection = discoveryFilterSelectionStreamValue.value;
    final payload = DiscoveryFilterQueryPayload.compile(
      catalog: discoveryFilterCatalogStreamValue.value,
      selection: selection,
    );
    final values = <String>{
      ...payload.typesForEntity('account_profile'),
    };

    return values
        .map(
          (value) => AccountProfilesRepositoryContractPrimString.fromRaw(
            value,
            defaultValue: value,
          ),
        )
        .where((value) => value.value.trim().isNotEmpty)
        .toList(growable: false);
  }

  List<AccountProfilesRepositoryTaxonomyFilter>
      _selectedAccountProfileTaxonomyFilters() {
    final payload = DiscoveryFilterQueryPayload.compile(
      catalog: discoveryFilterCatalogStreamValue.value,
      selection: discoveryFilterSelectionStreamValue.value,
    );
    return payload.taxonomyEntries
        .map(
          (entry) => AccountProfilesRepositoryTaxonomyFilter.fromRaw(
            type: entry.type,
            value: entry.value,
          ),
        )
        .where((entry) => entry.isValid)
        .toList(growable: false);
  }

  DiscoveryFilterSelection _repairDiscoveryFilterSelection(
    DiscoveryFilterSelection selection, {
    DiscoveryFilterCatalog? catalogOverride,
  }) {
    final catalog = catalogOverride ?? discoveryFilterCatalogStreamValue.value;
    return const DiscoveryFilterSelectionRepair()
        .repair(
          selection: selection,
          catalog: catalog.filters,
          catalogEnvelope: catalog,
          policy: _discoveryAccountProfilesFilterPolicy,
        )
        .selection;
  }

  bool _sameDiscoveryFilterSelection(
    DiscoveryFilterSelection left,
    DiscoveryFilterSelection right,
  ) {
    return _sameStringSet(left.primaryKeys, right.primaryKeys) &&
        _sameTaxonomySelection(left.taxonomyTermKeys, right.taxonomyTermKeys);
  }

  bool _sameTaxonomySelection(
    Map<String, Set<String>> left,
    Map<String, Set<String>> right,
  ) {
    if (!setEquals(left.keys.toSet(), right.keys.toSet())) {
      return false;
    }
    for (final key in left.keys) {
      if (!_sameStringSet(left[key] ?? const {}, right[key] ?? const {})) {
        return false;
      }
    }
    return true;
  }

  bool _sameStringSet(Set<String> left, Set<String> right) {
    return setEquals(left, right);
  }

  void _updateAvailableTypes() {
    final registry = _resolveRegistry();
    if (registry == null || registry.isEmpty) {
      availableTypesStreamValue.addValue(const []);
      return;
    }
    final allowed = registry
        .enabledAccountProfileTypes()
        .where(
          registry.isFavoritableFor,
        )
        .map((type) => type.value)
        .toList(growable: false);
    availableTypesStreamValue.addValue(allowed);
  }

  bool isFavoritable(AccountProfileModel accountProfile) {
    final registry = _resolveRegistry();
    if (registry == null || registry.isEmpty) return false;
    return registry.isFavoritableFor(
      ProfileTypeKeyValue(accountProfile.type),
    );
  }

  String labelForAccountProfileType(String type) {
    final registry = _resolveRegistry();
    if (registry == null || registry.isEmpty) {
      return _fallbackLabelForType(type);
    }
    return registry.labelForType(ProfileTypeKeyValue(type));
  }

  ResolvedAccountProfileVisual resolvedVisualForAccountProfile(
    AccountProfileModel accountProfile,
  ) {
    return AccountProfileVisualResolver.resolve(
      accountProfile: accountProfile,
      registry: _resolveRegistry(),
    );
  }

  ProfileTypeRegistry? _resolveRegistry() {
    return appData?.profileTypeRegistry;
  }

  double? _resolveDiscoveryMaxDistanceMeters() {
    final repository = _appDataRepository;
    if (repository != null) {
      final preferred = repository.maxRadiusMetersStreamValue.value;
      if (preferred.value > 0) {
        return preferred.value;
      }
    }
    return appData?.mapRadiusDefaultMeters;
  }

  AppData? get appData {
    if (!GetIt.I.isRegistered<AppData>()) {
      return null;
    }
    return GetIt.I.get<AppData>();
  }

  ScheduleRepositoryContract? _resolveScheduleRepository() {
    final cached = _scheduleRepository;
    if (cached != null) {
      return cached;
    }
    if (!GetIt.I.isRegistered<ScheduleRepositoryContract>()) {
      return null;
    }
    final resolved = GetIt.I.get<ScheduleRepositoryContract>();
    _scheduleRepository = resolved;
    return resolved;
  }

  String _fallbackLabelForType(String type) {
    switch (type) {
      case 'artist':
        return 'Artista';
      case 'venue':
        return 'Local';
      case 'restaurant':
        return 'Restaurante';
      case 'experience_provider':
        return 'Experiência';
      case 'influencer':
        return 'Influenciador';
      case 'curator':
        return 'Curador';
      case 'personal':
        return 'Pessoal';
    }
    return type;
  }

  bool get _isAuthorized => _authRepository?.isAuthorized ?? true;

  bool _isLifecycleTokenActive(int lifecycleToken) {
    return !_isDisposed && lifecycleToken == _lifecycleToken;
  }

  @override
  void onDispose() {
    _isDisposed = true;
    _lifecycleToken++;
    _searchDebounce?.cancel();
    searchController.removeListener(_handleSearchControllerChanged);
    _userLocationSubscription?.cancel();
    _lastKnownLocationSubscription?.cancel();
    searchQueryStreamValue.dispose();
    selectedTypeFilterStreamValue.dispose();
    discoveryFilterCatalogStreamValue.dispose();
    discoveryFilterSelectionStreamValue.dispose();
    isDiscoveryFilterPanelVisibleStreamValue.dispose();
    isDiscoveryFilterCatalogLoadingStreamValue.dispose();
    availableTypesStreamValue.dispose();
    favoriteIdsStreamValue.dispose();
    isRefreshingStreamValue.dispose();
    isPageLoadingStreamValue.dispose();
    hasMoreStreamValue.dispose();
    hasLoadedStreamValue.dispose();
    isSearchingStreamValue.dispose();
    isLoadingStreamValue.dispose();
    searchController.dispose();
    scrollController.dispose();
    _favoriteIdsSubscription?.cancel();
  }
}
