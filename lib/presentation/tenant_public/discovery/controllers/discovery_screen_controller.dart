import 'dart:async';

import 'package:belluga_now/domain/app_data/app_data.dart';
import 'package:belluga_now/domain/map/value_objects/city_coordinate.dart';
import 'package:belluga_now/domain/partners/account_profile_model.dart';
import 'package:belluga_now/domain/partners/profile_type_registry.dart';
import 'package:belluga_now/domain/partners/value_objects/profile_type_key_value.dart';
import 'package:belluga_now/domain/repositories/account_profiles_repository_contract.dart';
import 'package:belluga_now/domain/repositories/app_data_repository_contract.dart';
import 'package:belluga_now/domain/repositories/auth_repository_contract.dart';
import 'package:belluga_now/domain/repositories/schedule_repository_contract.dart';
import 'package:belluga_now/domain/repositories/user_location_repository_contract.dart';
import 'package:belluga_now/domain/schedule/event_model.dart';
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
    ScheduleRepositoryContract? scheduleRepository,
  })  : _accountProfilesRepository = accountProfilesRepository ??
            GetIt.I.get<AccountProfilesRepositoryContract>(),
        _authRepository = authRepository ??
            (GetIt.I.isRegistered<AuthRepositoryContract>()
                ? GetIt.I.get<AuthRepositoryContract>()
                : null),
        _scheduleRepository = scheduleRepository;

  final AccountProfilesRepositoryContract _accountProfilesRepository;
  final AuthRepositoryContract? _authRepository;
  ScheduleRepositoryContract? _scheduleRepository;

  static const Duration _searchDebounceDuration = Duration(milliseconds: 350);

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
  String? _lastOriginSignature;

  final ScrollController scrollController = ScrollController();
  final searchQueryStreamValue = StreamValue<String>(defaultValue: '');
  final selectedTypeFilterStreamValue = StreamValue<String?>();
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

  StreamValue<List<EventModel>> get liveNowEventsStreamValue =>
      _resolveScheduleRepository()?.discoveryLiveNowEventsStreamValue ??
      StreamValue<List<EventModel>>(defaultValue: const <EventModel>[]);
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
    await _reloadPartners(showFullScreenLoader: false);
  }

  void _handleSearchControllerChanged() {
    setSearchQuery(searchController.text);
  }

  void _attachScrollListener() {
    if (_scrollListenerAttached) return;
    _scrollListenerAttached = true;
    scrollController.addListener(() {
      if (_isFetchingPage ||
          isLoadingStreamValue.value ||
          isRefreshingStreamValue.value ||
          !hasMoreStreamValue.value) {
        return;
      }
      if (!scrollController.hasClients) {
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
    _lastOriginSignature = _originSignatureFrom(repository);

    _userLocationSubscription ??=
        repository.userLocationStreamValue.stream.listen((_) {
      _onLocationUpdated(repository);
    });
    _lastKnownLocationSubscription ??=
        repository.lastKnownLocationStreamValue.stream.listen((_) {
      _onLocationUpdated(repository);
    });
  }

  void _onLocationUpdated(UserLocationRepositoryContract repository) {
    final signature = _originSignatureFrom(repository);
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
      if (_shouldSyncNearby(query: query, selectedType: selectedType)) {
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
      return;
    }
    if (!next) {
      if (searchController.text.isNotEmpty) {
        searchController.clear();
      } else {
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

  String? _originSignatureFrom(UserLocationRepositoryContract repository) {
    final coordinate = repository.userLocationStreamValue.value ??
        repository.lastKnownLocationStreamValue.value;
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

    final origin = _resolveDiscoveryOrigin();
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
  }) {
    return query.isEmpty && (selectedType == null || selectedType.isEmpty);
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

  ProfileTypeRegistry? _resolveRegistry() {
    return appData?.profileTypeRegistry;
  }

  CityCoordinate? _resolveDiscoveryOrigin() {
    UserLocationRepositoryContract? locationRepository;
    if (GetIt.I.isRegistered<UserLocationRepositoryContract>()) {
      locationRepository = GetIt.I.get<UserLocationRepositoryContract>();
      final current = locationRepository.userLocationStreamValue.value ??
          locationRepository.lastKnownLocationStreamValue.value;
      if (current != null) {
        return current;
      }
    }
    return appData?.tenantDefaultOrigin;
  }

  double? _resolveDiscoveryMaxDistanceMeters() {
    if (GetIt.I.isRegistered<AppDataRepositoryContract>()) {
      final repository = GetIt.I.get<AppDataRepositoryContract>();
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
