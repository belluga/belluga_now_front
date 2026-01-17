import 'package:belluga_now/domain/partners/partner_model.dart';
import 'package:belluga_now/domain/repositories/partners_repository_contract.dart';
import 'package:belluga_now/domain/repositories/telemetry_repository_contract.dart';
import 'package:belluga_now/infrastructure/dal/datasources/mock_partners_database.dart';
import 'package:event_tracker_handler/event_tracker_handler.dart';
import 'package:get_it/get_it.dart';

class PartnersRepository extends PartnersRepositoryContract {
  PartnersRepository({
    MockPartnersDatabase? database,
    TelemetryRepositoryContract? telemetryRepository,
  })  : _database = database ?? MockPartnersDatabase(),
        _telemetryRepository =
            telemetryRepository ?? GetIt.I.get<TelemetryRepositoryContract>();

  final MockPartnersDatabase _database;
  final TelemetryRepositoryContract _telemetryRepository;

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
    final wasFavorite = _database.favoritePartnerIds.contains(partnerId);
    _database.toggleFavorite(partnerId);
    favoritePartnerIdsStreamValue.addValue(
      Set<String>.from(_database.favoritePartnerIds),
    );
    await _telemetryRepository.logEvent(
      EventTrackerEvents.favoriteArtistToggled,
      eventName: 'favorite_artist_toggled',
      properties: {
        'partner_id': partnerId,
        'is_favorite': !wasFavorite,
      },
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
