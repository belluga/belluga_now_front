import 'package:belluga_now/domain/partners/partner_model.dart';
import 'package:belluga_now/infrastructure/dal/dao/partners_backend_contract.dart';
import 'package:belluga_now/infrastructure/dal/datasources/mock_partners_database.dart';

class MockPartnersBackend implements PartnersBackendContract {
  MockPartnersBackend({MockPartnersDatabase? database})
      : _database = database ?? MockPartnersDatabase();

  final MockPartnersDatabase _database;

  @override
  Future<List<PartnerModel>> fetchPartners() async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _database.allPartners;
  }

  @override
  Future<List<PartnerModel>> searchPartners({
    String? query,
    PartnerType? typeFilter,
  }) async {
    await Future.delayed(const Duration(milliseconds: 50));
    return _database.searchPartners(query: query, typeFilter: typeFilter);
  }

  @override
  Future<PartnerModel?> fetchPartnerBySlug(String slug) async {
    await Future.delayed(const Duration(milliseconds: 50));
    return _database.getPartnerBySlug(slug);
  }
}
