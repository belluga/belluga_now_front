import 'package:belluga_now/domain/partners/partner_model.dart';
import 'package:belluga_now/domain/repositories/partners_repository_contract.dart';
import 'package:belluga_now/infrastructure/dal/datasources/mock_partners_database.dart';

class PartnersRepository extends PartnersRepositoryContract {
  PartnersRepository({
    MockPartnersDatabase? database,
  }) : _database = database ?? MockPartnersDatabase();

  final MockPartnersDatabase _database;

  @override
  Future<void> init() async {
    final partners = await fetchAllPartners();
    allPartnersStreamValue.addValue(partners);

    // Initialize favorites from mock persistence (app manager included)
    favoritePartnerIdsStreamValue.addValue(
      Set<String>.from(_database.favoritePartnerIds),
    );
  }

  @override
  Future<List<PartnerModel>> fetchAllPartners() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 100));
    return _database.allPartners;
  }

  @override
  Future<List<PartnerModel>> searchPartners({
    String? query,
    PartnerType? typeFilter,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 50));
    return _database.searchPartners(query: query, typeFilter: typeFilter);
  }

  @override
  Future<PartnerModel?> getPartnerBySlug(String slug) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 50));
    return _database.getPartnerBySlug(slug);
  }

  @override
  Future<void> toggleFavorite(String partnerId) async {
    _database.toggleFavorite(partnerId);
    favoritePartnerIdsStreamValue.addValue(
      Set<String>.from(_database.favoritePartnerIds),
    );
  }

  @override
  bool isFavorite(String partnerId) {
    return favoritePartnerIdsStreamValue.value.contains(partnerId);
  }

  @override
  List<PartnerModel> getFavoritePartners() {
    final favoriteIds = favoritePartnerIdsStreamValue.value;
    final allPartners = allPartnersStreamValue.value;

    return allPartners
        .where((partner) => favoriteIds.contains(partner.id))
        .toList();
  }
}
