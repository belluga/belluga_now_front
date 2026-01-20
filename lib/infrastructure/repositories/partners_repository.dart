import 'package:belluga_now/domain/partners/partner_model.dart';
import 'package:belluga_now/domain/partners/profile_type_registry.dart';
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
    return _filterByRegistry(_database.allPartners);
  }

  @override
  Future<List<PartnerModel>> searchPartners({
    String? query,
    PartnerType? typeFilter,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 50));
    final results = _database.searchPartners(query: query, typeFilter: typeFilter);
    return _filterByRegistry(results);
  }

  @override
  Future<PartnerModel?> getPartnerBySlug(String slug) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 50));
    final partner = _database.getPartnerBySlug(slug);
    if (partner == null) return null;
    return _isPartnerTypeEnabled(partner) ? partner : null;
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

  List<PartnerModel> _filterByRegistry(List<PartnerModel> partners) {
    final registry = _resolveRegistry();
    if (registry == null || registry.isEmpty) {
      debugPrint('Profile type registry missing; hiding partner lists.');
      return const [];
    }
    return partners
        .where((partner) => _isPartnerTypeEnabled(partner))
        .toList(growable: false);
  }

  bool _isPartnerTypeEnabled(PartnerModel partner) {
    final registry = _resolveRegistry();
    return registry?.isEnabledFor(partner.type) ?? false;
  }

  bool _canFavoritePartner(PartnerModel partner) {
    final registry = _resolveRegistry();
    if (registry == null || registry.isEmpty) {
      return false;
    }
    return registry.isFavoritableFor(partner.type);
  }

  ProfileTypeRegistry? _resolveRegistry() {
    if (!GetIt.I.isRegistered<AppData>()) {
      return null;
    }
    return GetIt.I.get<AppData>().profileTypeRegistry;
  }
}
