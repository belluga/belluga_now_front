import 'package:belluga_now/domain/partners/engagement_data.dart';
import 'package:belluga_now/domain/partners/partner_model.dart';
import 'package:belluga_now/domain/repositories/partners_repository_contract.dart';
import 'package:belluga_now/presentation/tenant/discovery/models/curator_content.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value.dart';

class DiscoveryScreenController implements Disposable {
  DiscoveryScreenController({
    PartnersRepositoryContract? partnersRepository,
  }) : _partnersRepository =
            partnersRepository ?? GetIt.I.get<PartnersRepositoryContract>();

  final PartnersRepositoryContract _partnersRepository;

  // Cached dataset
  List<PartnerModel> _allPartners = const [];

  final searchQueryStreamValue = StreamValue<String>(defaultValue: '');
  final selectedTypeFilterStreamValue = StreamValue<PartnerType?>();
  final filteredPartnersStreamValue =
      StreamValue<List<PartnerModel>>(defaultValue: const []);
  final isLoadingStreamValue = StreamValue<bool>(defaultValue: false);
  final hasLoadedStreamValue = StreamValue<bool>(defaultValue: false);
  final isSearchingStreamValue = StreamValue<bool>(defaultValue: false);
  final TextEditingController searchController = TextEditingController();

  // Highlighted sections
  final liveNowStreamValue = StreamValue<List<PartnerModel>>(defaultValue: const []);
  final nearbyStreamValue = StreamValue<List<PartnerModel>>(defaultValue: const []);
  final curatorStreamValue = StreamValue<List<PartnerModel>>(defaultValue: const []);
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
      _allPartners = await _partnersRepository.fetchAllPartners();
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

  void setTypeFilter(PartnerType? type) {
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

  void toggleFavorite(String partnerId) {
    _partnersRepository.toggleFavorite(partnerId);
  }

  bool isFavorite(String partnerId) {
    return _partnersRepository.isFavorite(partnerId);
  }

  StreamValue<Set<String>> get favoriteIdsStream =>
      _partnersRepository.favoritePartnerIdsStreamValue;

  void _buildSections() {
    // Tocando agora: artistas com status ativo ou próximo, ordenados por distância quando existir
    final live = _allPartners.where(_isLiveNow).toList()
      ..sort((a, b) {
        final aDist = a.distanceMeters ?? double.infinity;
        final bDist = b.distanceMeters ?? double.infinity;
        return aDist.compareTo(bDist);
      });
    liveNowStreamValue.addValue(live.take(10).toList());

    // Perto de você: venues/experiências ordenando por distância quando disponível
    final nearby = _allPartners
        .where((p) => p.type == PartnerType.venue || p.type == PartnerType.experienceProvider)
        .toList()
      ..sort((a, b) {
        final aDist = a.distanceMeters ?? double.infinity;
        final bDist = b.distanceMeters ?? double.infinity;
        return aDist.compareTo(bDist);
      });
    nearbyStreamValue.addValue(nearby.take(10).toList());

    // Curadores
    final curators = _allPartners
        .where((p) => p.type == PartnerType.curator)
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

    var results = _allPartners;

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

  bool _isLiveNow(PartnerModel p) {
    if (p.type != PartnerType.artist || p.engagementData == null) return false;
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
