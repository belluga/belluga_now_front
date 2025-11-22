import 'package:belluga_now/domain/partners/partner_model.dart';
import 'package:belluga_now/domain/repositories/partners_repository_contract.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value.dart';

class PartnerDetailController implements Disposable {
  PartnerDetailController({
    PartnersRepositoryContract? partnersRepository,
  }) : _partnersRepository =
            partnersRepository ?? GetIt.I.get<PartnersRepositoryContract>();

  final PartnersRepositoryContract _partnersRepository;

  final partnerStreamValue = StreamValue<PartnerModel?>();
  final isLoadingStreamValue = StreamValue<bool>(defaultValue: false);

  Future<void> loadPartner(String slug) async {
    isLoadingStreamValue.addValue(true);
    try {
      final partner = await _partnersRepository.getPartnerBySlug(slug);
      partnerStreamValue.addValue(partner);
    } finally {
      isLoadingStreamValue.addValue(false);
    }
  }

  void toggleFavorite(String partnerId) {
    _partnersRepository.toggleFavorite(partnerId);
  }

  bool isFavorite(String partnerId) {
    return _partnersRepository.isFavorite(partnerId);
  }

  @override
  void onDispose() {
    partnerStreamValue.dispose();
    isLoadingStreamValue.dispose();
  }
}
