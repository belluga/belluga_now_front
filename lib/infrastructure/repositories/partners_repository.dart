import 'package:belluga_now/domain/partners/partner_model.dart';
import 'package:belluga_now/domain/app_data/app_data.dart';
import 'package:belluga_now/domain/partners/profile_type_registry.dart';
import 'package:belluga_now/domain/repositories/partners_repository_contract.dart';
import 'package:belluga_now/domain/repositories/telemetry_repository_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/backend_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/partners_backend_contract.dart';
import 'package:belluga_now/infrastructure/dal/datasources/mock_partners_database.dart';
import 'package:event_tracker_handler/event_tracker_handler.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';

class PartnersRepository extends PartnersRepositoryContract {
  PartnersRepository({
    PartnersBackendContract? backend,
    BackendContract? backendContract,
    Set<String>? favoritePartnerIds,
    TelemetryRepositoryContract? telemetryRepository,
  })  : _backend =
            backend ?? (backendContract ?? GetIt.I.get<BackendContract>())
                .partners,
        _favoritePartnerIds =
            Set<String>.from(favoritePartnerIds ??
                MockPartnersDatabase().favoritePartnerIds),
        _telemetryRepository =
            telemetryRepository ?? GetIt.I.get<TelemetryRepositoryContract>();

  static const String _appManagerId = 'app-manager';
  final PartnersBackendContract _backend;
  final Set<String> _favoritePartnerIds;
  final TelemetryRepositoryContract _telemetryRepository;

  @override
  Future<void> init() async {
    final partners = await fetchAllPartners();
    allPartnersStreamValue.addValue(partners);

    // Initialize favorites from mock persistence (app manager included)
    favoritePartnerIdsStreamValue.addValue(
      Set<String>.from(_favoritePartnerIds),
    );
  }

  @override
  Future<List<PartnerModel>> fetchAllPartners() async {
    final partners = await _backend.fetchPartners();
    return _filterByRegistry(partners);
  }

  @override
  Future<List<PartnerModel>> searchPartners({
    String? query,
    PartnerType? typeFilter,
  }) async {
    final results =
        await _backend.searchPartners(query: query, typeFilter: typeFilter);
    return _filterByRegistry(results);
  }

  @override
  Future<PartnerModel?> getPartnerBySlug(String slug) async {
    final partner = await _backend.fetchPartnerBySlug(slug);
    if (partner == null) return null;
    return _isPartnerTypeEnabled(partner) ? partner : null;
  }

  @override
  Future<void> toggleFavorite(String partnerId) async {
    if (partnerId == _appManagerId) {
      return;
    }
    final wasFavorite = _favoritePartnerIds.contains(partnerId);
    if (wasFavorite) {
      _favoritePartnerIds.remove(partnerId);
    } else {
      _favoritePartnerIds.add(partnerId);
    }
    favoritePartnerIdsStreamValue.addValue(
      Set<String>.from(_favoritePartnerIds),
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

  ProfileTypeRegistry? _resolveRegistry() {
    if (!GetIt.I.isRegistered<AppData>()) {
      return null;
    }
    return GetIt.I.get<AppData>().profileTypeRegistry;
  }
}
