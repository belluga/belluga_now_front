import 'package:belluga_now/domain/partners/partner_model.dart';
import 'package:belluga_now/domain/repositories/partners_repository_contract.dart';
import 'package:belluga_now/infrastructure/services/dal/datasources/mock_partners_database.dart';

class PartnersRepository extends PartnersRepositoryContract {
  PartnersRepository({
    MockPartnersDatabase? database,
  }) : _database = database ?? MockPartnersDatabase();

  final MockPartnersDatabase _database;

  // App manager is always favorited by default
  static const String _appManagerId = 'app-manager';

  @override
  Future<void> init() async {
    final partners = await fetchAllPartners();
    allPartnersStreamValue.addValue(partners);

    // Initialize favorites with app manager
    favoritePartnerIdsStreamValue.addValue({_appManagerId});
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
    final currentFavorites =
        Set<String>.from(favoritePartnerIdsStreamValue.value);

    if (partnerId == _appManagerId) {
      // App manager cannot be unfavorited
      return;
    }

    if (currentFavorites.contains(partnerId)) {
      currentFavorites.remove(partnerId);
    } else {
      currentFavorites.add(partnerId);
    }

    favoritePartnerIdsStreamValue.addValue(currentFavorites);
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
