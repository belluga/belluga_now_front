import 'package:belluga_now/domain/partners/engagement_data.dart';
import 'package:belluga_now/domain/partners/account_profile_model.dart';
import 'package:belluga_now/domain/partners/profile_type_registry.dart';
import 'package:belluga_now/domain/repositories/account_profiles_repository_contract.dart';
import 'package:belluga_now/domain/app_data/app_data.dart';
import 'package:belluga_now/presentation/tenant_public/discovery/models/curator_content.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value.dart';

class DiscoveryScreenController implements Disposable {
  DiscoveryScreenController({
    AccountProfilesRepositoryContract? accountProfilesRepository,
  }) : _partnersRepository = accountProfilesRepository ??
            GetIt.I.get<AccountProfilesRepositoryContract>();

  final AccountProfilesRepositoryContract _partnersRepository;

  // Cached dataset
  List<AccountProfileModel> _allAccountProfiles = const [];

  final searchQueryStreamValue = StreamValue<String>(defaultValue: '');
  final selectedTypeFilterStreamValue = StreamValue<String?>();
  final availableTypesStreamValue =
      StreamValue<List<String>>(defaultValue: const []);
  final filteredPartnersStreamValue =
      StreamValue<List<AccountProfileModel>>(defaultValue: const []);
  final isLoadingStreamValue = StreamValue<bool>(defaultValue: false);
  final hasLoadedStreamValue = StreamValue<bool>(defaultValue: false);
  final isSearchingStreamValue = StreamValue<bool>(defaultValue: false);
  final TextEditingController searchController = TextEditingController();

  // Highlighted sections
  final liveNowStreamValue = StreamValue<List<AccountProfileModel>>(defaultValue: const []);
  final nearbyStreamValue = StreamValue<List<AccountProfileModel>>(defaultValue: const []);
  final curatorStreamValue = StreamValue<List<AccountProfileModel>>(defaultValue: const []);
  final curatorContentStreamValue =
      StreamValue<List<CuratorContent>>(defaultValue: const []);

  Future<void> init() async {
    searchController.addListener(() {
      setSearchQuery(searchController.text);
    });
    await _partnersRepository.init();
    await _loadPartners();
  }

  Future<void> _loadPartners() async {
    isLoadingStreamValue.addValue(true);
    try {
      _allAccountProfiles = await _partnersRepository.fetchAllAccountProfiles();
      _updateAvailableTypes();
      _buildSections();
      _applyFilters();
      hasLoadedStreamValue.addValue(true);
    } finally {
      isLoadingStreamValue.addValue(false);
    }
  }

  void setSearchQuery(String query) {
    searchQueryStreamValue.addValue(query);
    _applyFilters();
  }

  void setTypeFilter(String? type) {
    selectedTypeFilterStreamValue.addValue(type);
    _applyFilters();
  }

  void toggleSearch() {
    final next = !isSearchingStreamValue.value;
    isSearchingStreamValue.addValue(next);
    if (!next) {
      searchController.clear();
      setSearchQuery('');
    }
  }

  void toggleFavorite(String accountProfileId) {
    _partnersRepository.toggleFavorite(accountProfileId);
  }

  bool isFavorite(String accountProfileId) {
    return _partnersRepository.isFavorite(accountProfileId);
  }

  StreamValue<Set<String>> get favoriteIdsStream =>
      _partnersRepository.favoriteAccountProfileIdsStreamValue;

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

    // Conteúdo de curadores (mock)
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
    final query = searchQueryStreamValue.value.trim().toLowerCase();
    final type = selectedTypeFilterStreamValue.value;

    var results = _allAccountProfiles;

    if (type != null) {
      results = results.where((p) => p.type == type).toList();
    }

    if (query.isNotEmpty) {
      results = results.where((p) {
        final nameMatch = p.name.toLowerCase().contains(query);
        final tagMatch = p.tags.any((tag) => tag.toLowerCase().contains(query));
        return nameMatch || tagMatch;
      }).toList();
    }

    filteredPartnersStreamValue.addValue(results);
  }

  void _updateAvailableTypes() {
    final registry = _resolveRegistry();
    if (registry == null || registry.isEmpty) {
      availableTypesStreamValue.addValue(const []);
      return;
    }
    final presentTypes = _allAccountProfiles.map((p) => p.type).toSet();
    final allowed = registry
        .enabledAccountProfileTypes()
        .where(presentTypes.contains)
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

  @override
  void onDispose() {
    searchQueryStreamValue.dispose();
    selectedTypeFilterStreamValue.dispose();
    availableTypesStreamValue.dispose();
    filteredPartnersStreamValue.dispose();
    hasLoadedStreamValue.dispose();
    isSearchingStreamValue.dispose();
    liveNowStreamValue.dispose();
    nearbyStreamValue.dispose();
    curatorStreamValue.dispose();
    curatorContentStreamValue.dispose();
    isLoadingStreamValue.dispose();
    searchController.dispose();
  }
}
