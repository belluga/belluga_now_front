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
import 'package:belluga_now/presentation/tenant_public/discovery/models/curator_content.dart';
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
  int _reloadRequestToken = 0;
  bool _isFetchingPage = false;
  bool _isFetchingNearby = false;
  bool _isFetchingLiveNow = false;
  bool _hasPendingLiveNowReload = false;
  bool _hasMore = true;
  bool _scrollListenerAttached = false;
  int _currentPage = 0;
  String? _lastOriginSignature;

  List<AccountProfileModel> _allAccountProfiles = const [];

  final ScrollController scrollController = ScrollController();
  final searchQueryStreamValue = StreamValue<String>(defaultValue: '');
  final selectedTypeFilterStreamValue = StreamValue<String?>();
  final availableTypesStreamValue =
      StreamValue<List<String>>(defaultValue: const []);
  final favoriteIdsStreamValue =
      StreamValue<Set<String>>(defaultValue: const {});
  StreamValue<List<AccountProfileModel>> get filteredPartnersStreamValue =>
      _accountProfilesRepository.discoveryFilteredAccountProfilesStreamValue;
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
  StreamValue<List<AccountProfileModel>> get nearbyStreamValue =>
      _accountProfilesRepository.discoveryNearbyAccountProfilesStreamValue;
  StreamValue<List<AccountProfileModel>> get curatorStreamValue =>
      _accountProfilesRepository.discoveryCuratorAccountProfilesStreamValue;
  final curatorContentStreamValue =
      StreamValue<List<CuratorContent>>(defaultValue: const []);

  Future<void> init() async {
    if (_initialized) {
      await _loadFavoriteIds();
      if (!hasLoadedStreamValue.value && !_isFetchingPage) {
        await _reloadPartners(showFullScreenLoader: false);
      }
      unawaited(_reloadNearbySection());
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
          !_hasMore ||
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
    unawaited(_reloadNearbySection());
    unawaited(_reloadLiveNowSection());
  }

  Future<void> _reloadPartners({bool showFullScreenLoader = false}) async {
    final requestToken = ++_reloadRequestToken;
    final useFullScreenLoader = showFullScreenLoader ||
        (!hasLoadedStreamValue.value && _allAccountProfiles.isEmpty);

    _currentPage = 0;
    _hasMore = true;
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
      debugPrint('DiscoveryScreenController._reloadPartners failed: $error');
    } finally {
      if (requestToken == _reloadRequestToken) {
        hasLoadedStreamValue.addValue(true);
        isLoadingStreamValue.addValue(false);
        isRefreshingStreamValue.addValue(false);
        unawaited(_reloadNearbySection());
        unawaited(_reloadLiveNowSection());
      }
    }
  }

  void _clearVisibleData() {
    _allAccountProfiles = const [];
    filteredPartnersStreamValue.addValue(const []);
    liveNowEventsStreamValue.addValue(const []);
    nearbyStreamValue.addValue(const []);
    curatorStreamValue.addValue(const []);
    curatorContentStreamValue.addValue(const []);
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
    if (!isInitial && !_hasMore) return;

    _isFetchingPage = true;
    if (!isInitial) {
      isPageLoadingStreamValue.addValue(true);
    }

    try {
      final query = searchQueryStreamValue.value.trim();
      final selectedType = selectedTypeFilterStreamValue.value;
      final shouldLoadFirstPage = isInitial || _currentPage <= 0;
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

      if (requestToken != _reloadRequestToken) {
        return;
      }

      if (loadedPage.value == 1) {
        _allAccountProfiles =
            List<AccountProfileModel>.from(pageResult.profiles);
      } else {
        _allAccountProfiles = [
          ..._allAccountProfiles,
          ...pageResult.profiles,
        ];
      }

      _currentPage = loadedPage.value;
      _hasMore = pageResult.hasMore;
      hasMoreStreamValue.addValue(_hasMore);

      _updateAvailableTypes();
      _buildSections();
      _applyFilters();
    } finally {
      _isFetchingPage = false;
      if (!isInitial && requestToken == _reloadRequestToken) {
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

  void _buildSections() {
    final curators = _allAccountProfiles
        .where((p) => p.type == 'curator')
        .toList()
      ..sort((a, b) => (b.acceptedInvites).compareTo(a.acceptedInvites));
    curatorStreamValue.addValue(curators.take(10).toList());

    final curatorContent = curators.take(5).map((c) {
      final thumb = c.coverUrl ?? c.avatarUrl ?? '';
      final title = c.tags.isNotEmpty
          ? 'Novo ${c.tags.first} por ${c.name}'
          : 'Conteúdo de ${c.name}';
      return CuratorContent(
        id: c.id,
        title: title,
        typeLabel: 'Artigo',
        imageUrl: thumb,
        curatorName: c.name,
      );
    }).toList();
    curatorContentStreamValue.addValue(curatorContent);
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

  Future<void> _reloadNearbySection() async {
    if (_isFetchingNearby) {
      return;
    }

    _isFetchingNearby = true;
    try {
      final nearby = await _accountProfilesRepository.fetchNearbyAccountProfiles();
      nearbyStreamValue.addValue(nearby);
    } catch (error) {
      debugPrint(
          'DiscoveryScreenController._reloadNearbySection failed: $error');
    } finally {
      _isFetchingNearby = false;
    }
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

  void _applyFilters() {
    filteredPartnersStreamValue
        .addValue(List<AccountProfileModel>.from(_allAccountProfiles));
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

  @override
  void onDispose() {
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
    liveNowEventsStreamValue.dispose();
    curatorContentStreamValue.dispose();
    isLoadingStreamValue.dispose();
    searchController.dispose();
    scrollController.dispose();
    _favoriteIdsSubscription?.cancel();
  }
}
