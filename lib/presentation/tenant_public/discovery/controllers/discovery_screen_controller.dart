import 'dart:async';

import 'package:belluga_now/domain/partners/engagement_data.dart';
import 'package:belluga_now/domain/partners/account_profile_model.dart';
import 'package:belluga_now/domain/partners/profile_type_registry.dart';
import 'package:belluga_now/domain/repositories/account_profiles_repository_contract.dart';
import 'package:belluga_now/domain/repositories/auth_repository_contract.dart';
import 'package:belluga_now/domain/app_data/app_data.dart';
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
  })  : _partnersRepository = accountProfilesRepository ??
            GetIt.I.get<AccountProfilesRepositoryContract>(),
        _authRepository = authRepository ??
            (GetIt.I.isRegistered<AuthRepositoryContract>()
                ? GetIt.I.get<AuthRepositoryContract>()
                : null);

  final AccountProfilesRepositoryContract _partnersRepository;
  final AuthRepositoryContract? _authRepository;

  static const int _defaultPageSize = 20;
  static const Duration _searchDebounceDuration = Duration(milliseconds: 350);

  StreamSubscription<Set<String>>? _favoriteIdsSubscription;
  Timer? _searchDebounce;
  int _reloadRequestToken = 0;
  bool _isFetchingPage = false;
  bool _hasMore = true;
  bool _scrollListenerAttached = false;
  int _currentPage = 0;

  // Cached dataset
  List<AccountProfileModel> _allAccountProfiles = const [];

  final ScrollController scrollController = ScrollController();
  final searchQueryStreamValue = StreamValue<String>(defaultValue: '');
  final selectedTypeFilterStreamValue = StreamValue<String?>();
  final availableTypesStreamValue =
      StreamValue<List<String>>(defaultValue: const []);
  final favoriteIdsStreamValue =
      StreamValue<Set<String>>(defaultValue: const {});
  final filteredPartnersStreamValue =
      StreamValue<List<AccountProfileModel>>(defaultValue: const []);
  final isLoadingStreamValue = StreamValue<bool>(defaultValue: false);
  final isPageLoadingStreamValue = StreamValue<bool>(defaultValue: false);
  final hasMoreStreamValue = StreamValue<bool>(defaultValue: true);
  final hasLoadedStreamValue = StreamValue<bool>(defaultValue: false);
  final isSearchingStreamValue = StreamValue<bool>(defaultValue: false);
  final TextEditingController searchController = TextEditingController();

  // Highlighted sections
  final liveNowStreamValue =
      StreamValue<List<AccountProfileModel>>(defaultValue: const []);
  final nearbyStreamValue =
      StreamValue<List<AccountProfileModel>>(defaultValue: const []);
  final curatorStreamValue =
      StreamValue<List<AccountProfileModel>>(defaultValue: const []);
  final curatorContentStreamValue =
      StreamValue<List<CuratorContent>>(defaultValue: const []);

  Future<void> init() async {
    searchController.addListener(() {
      setSearchQuery(searchController.text);
    });
    _attachScrollListener();

    await _partnersRepository.init();
    _favoriteIdsSubscription ??=
        _partnersRepository.favoriteAccountProfileIdsStreamValue.stream.listen(
      (ids) {
        favoriteIdsStreamValue.addValue(Set<String>.from(ids));
      },
    );
    await _loadFavoriteIds();
    await _reloadPartners();
  }

  void _attachScrollListener() {
    if (_scrollListenerAttached) return;
    _scrollListenerAttached = true;
    scrollController.addListener(() {
      if (_isFetchingPage ||
          !_hasMore ||
          isLoadingStreamValue.value ||
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

  Future<void> _reloadPartners() async {
    final requestToken = ++_reloadRequestToken;
    isLoadingStreamValue.addValue(true);
    hasLoadedStreamValue.addValue(false);
    _allAccountProfiles = const [];
    _currentPage = 0;
    _hasMore = true;
    hasMoreStreamValue.addValue(true);
    filteredPartnersStreamValue.addValue(const []);
    liveNowStreamValue.addValue(const []);
    nearbyStreamValue.addValue(const []);
    curatorStreamValue.addValue(const []);
    curatorContentStreamValue.addValue(const []);
    availableTypesStreamValue.addValue(const []);
    try {
      await _fetchNextPage(isInitial: true, requestToken: requestToken);
      hasLoadedStreamValue.addValue(true);
    } finally {
      if (requestToken == _reloadRequestToken) {
        isLoadingStreamValue.addValue(false);
      }
    }
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
      final nextPage = _currentPage + 1;
      final query = searchQueryStreamValue.value.trim();
      final selectedType = selectedTypeFilterStreamValue.value;
      final pageResult = await _partnersRepository.fetchAccountProfilesPage(
        page: nextPage,
        pageSize: _defaultPageSize,
        query: query.isEmpty ? null : query,
        typeFilter: selectedType,
      );

      if (requestToken != _reloadRequestToken) {
        return;
      }

      if (nextPage == 1) {
        _allAccountProfiles =
            List<AccountProfileModel>.from(pageResult.profiles);
      } else {
        _allAccountProfiles = [
          ..._allAccountProfiles,
          ...pageResult.profiles,
        ];
      }

      _currentPage = nextPage;
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
    searchQueryStreamValue.addValue(query);
    _searchDebounce?.cancel();
    _searchDebounce = Timer(_searchDebounceDuration, () {
      unawaited(_reloadPartners());
    });
  }

  void setTypeFilter(String? type) {
    selectedTypeFilterStreamValue.addValue(type);
    _searchDebounce?.cancel();
    unawaited(_reloadPartners());
  }

  void toggleSearch() {
    final next = !isSearchingStreamValue.value;
    isSearchingStreamValue.addValue(next);
    if (!next) {
      searchController.clear();
      setSearchQuery('');
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

    unawaited(_partnersRepository.toggleFavorite(accountProfileId));
    return FavoriteToggleOutcome.toggled;
  }

  bool isFavorite(String accountProfileId) {
    return favoriteIdsStreamValue.value.contains(accountProfileId);
  }

  StreamValue<Set<String>> get favoriteIdsStream => favoriteIdsStreamValue;

  Future<void> _loadFavoriteIds() async {
    final ids = Set<String>.from(
      _partnersRepository.favoriteAccountProfileIdsStreamValue.value,
    );
    favoriteIdsStreamValue.addValue(ids);
  }

  void _buildSections() {
    // Tocando agora: artistas com status ativo ou próximo, ordenados por distância quando existir
    final live = _allAccountProfiles.where(_isLiveNow).toList()
      ..sort((a, b) {
        final aDist = a.distanceMeters ?? double.infinity;
        final bDist = b.distanceMeters ?? double.infinity;
        return aDist.compareTo(bDist);
      });
    liveNowStreamValue.addValue(live.take(10).toList());

    // Perto de você: venues/experiências ordenando por distância quando disponível
    final nearby = _allAccountProfiles
        .where((p) => p.type == 'venue' || p.type == 'experience_provider')
        .toList()
      ..sort((a, b) {
        final aDist = a.distanceMeters ?? double.infinity;
        final bDist = b.distanceMeters ?? double.infinity;
        return aDist.compareTo(bDist);
      });
    nearbyStreamValue.addValue(nearby.take(10).toList());

    // Curadores
    final curators = _allAccountProfiles
        .where((p) => p.type == 'curator')
        .toList()
      ..sort((a, b) => (b.acceptedInvites).compareTo(a.acceptedInvites));
    curatorStreamValue.addValue(curators.take(10).toList());

    // Conteúdo de curadores derivado dos account profiles carregados.
    final curatorContent = curators.take(5).map((c) {
      final thumb = c.coverUrl ?? c.avatarUrl ?? '';
      final typeLabel = 'Artigo';
      final title = c.tags.isNotEmpty
          ? 'Novo ${c.tags.first} por ${c.name}'
          : 'Conteúdo de ${c.name}';
      return CuratorContent(
        id: c.id,
        title: title,
        typeLabel: typeLabel,
        imageUrl: thumb,
        curatorName: c.name,
      );
    }).toList();
    curatorContentStreamValue.addValue(curatorContent);
  }

  void _applyFilters() {
    // Discovery query/type filtering is backend-driven for paginated datasets.
    // Applying local text/type filters here can silently drop valid backend
    // matches (for example slug or taxonomy-only matches).
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
        .where((type) => registry.isFavoritableFor(type))
        .toList(growable: false);
    availableTypesStreamValue.addValue(allowed);
  }

  bool isPartnerFavoritable(AccountProfileModel partner) {
    final registry = _resolveRegistry();
    if (registry == null || registry.isEmpty) return false;
    return registry.isFavoritableFor(partner.type);
  }

  String labelForAccountProfileType(String type) {
    final registry = _resolveRegistry();
    if (registry == null || registry.isEmpty) {
      return _fallbackLabelForType(type);
    }
    return registry.labelForType(type);
  }

  ProfileTypeRegistry? _resolveRegistry() {
    if (!GetIt.I.isRegistered<AppData>()) {
      return null;
    }
    return GetIt.I.get<AppData>().profileTypeRegistry;
  }

  String _fallbackLabelForType(String type) {
    switch (type) {
      case 'artist':
        return 'Artista';
      case 'venue':
        return 'Local';
      case 'experience_provider':
        return 'Experiência';
      case 'influencer':
        return 'Influenciador';
      case 'curator':
        return 'Curador';
    }
    return type;
  }

  bool _isLiveNow(AccountProfileModel p) {
    if (p.type != 'artist' || p.engagementData == null) return false;
    final engagement = p.engagementData;
    if (engagement is ArtistEngagementData) {
      return engagement.status.toLowerCase().contains('agora');
    }
    return false;
  }

  bool get _isAuthorized => _authRepository?.isAuthorized ?? true;

  @override
  void onDispose() {
    _searchDebounce?.cancel();
    searchQueryStreamValue.dispose();
    selectedTypeFilterStreamValue.dispose();
    availableTypesStreamValue.dispose();
    favoriteIdsStreamValue.dispose();
    filteredPartnersStreamValue.dispose();
    isPageLoadingStreamValue.dispose();
    hasMoreStreamValue.dispose();
    hasLoadedStreamValue.dispose();
    isSearchingStreamValue.dispose();
    liveNowStreamValue.dispose();
    nearbyStreamValue.dispose();
    curatorStreamValue.dispose();
    curatorContentStreamValue.dispose();
    isLoadingStreamValue.dispose();
    searchController.dispose();
    scrollController.dispose();
    _favoriteIdsSubscription?.cancel();
  }
}
