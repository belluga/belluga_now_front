import 'package:belluga_now/domain/partners/partner_model.dart';
import 'package:belluga_now/domain/repositories/partners_repository_contract.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value.dart';

class DiscoveryScreenController implements Disposable {
  DiscoveryScreenController({
    PartnersRepositoryContract? partnersRepository,
  }) : _partnersRepository =
            partnersRepository ?? GetIt.I.get<PartnersRepositoryContract>();

  final PartnersRepositoryContract _partnersRepository;

  final searchQueryStreamValue = StreamValue<String>(defaultValue: '');
  final selectedTypeFilterStreamValue = StreamValue<PartnerType?>();
  final filteredPartnersStreamValue =
      StreamValue<List<PartnerModel>>(defaultValue: const []);
  final isLoadingStreamValue = StreamValue<bool>(defaultValue: false);

  Future<void> init() async {
    await _partnersRepository.init();
    await _loadPartners();
  }

  Future<void> _loadPartners() async {
    isLoadingStreamValue.addValue(true);
    try {
      final partners = await _partnersRepository.searchPartners(
        query: searchQueryStreamValue.value.isEmpty
            ? null
            : searchQueryStreamValue.value,
        typeFilter: selectedTypeFilterStreamValue.value,
      );
      filteredPartnersStreamValue.addValue(partners);
    } finally {
      isLoadingStreamValue.addValue(false);
    }
  }

  void setSearchQuery(String query) {
    searchQueryStreamValue.addValue(query);
    _loadPartners();
  }

  void setTypeFilter(PartnerType? type) {
    selectedTypeFilterStreamValue.addValue(type);
    _loadPartners();
  }

  void toggleFavorite(String partnerId) {
    _partnersRepository.toggleFavorite(partnerId);
  }

  bool isFavorite(String partnerId) {
    return _partnersRepository.isFavorite(partnerId);
  }

  @override
  void onDispose() {
    searchQueryStreamValue.dispose();
    selectedTypeFilterStreamValue.dispose();
    filteredPartnersStreamValue.dispose();
    isLoadingStreamValue.dispose();
  }
}
