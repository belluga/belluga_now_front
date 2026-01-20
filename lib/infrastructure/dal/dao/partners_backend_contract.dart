import 'package:belluga_now/domain/partners/partner_model.dart';

abstract class PartnersBackendContract {
  Future<List<PartnerModel>> fetchPartners();

  Future<List<PartnerModel>> searchPartners({
    String? query,
    PartnerType? typeFilter,
  });

  Future<PartnerModel?> fetchPartnerBySlug(String slug);
}
