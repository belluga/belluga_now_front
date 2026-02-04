import 'package:belluga_now/domain/partners/account_profile_model.dart';
import 'package:belluga_now/domain/app_data/app_data.dart';
import 'package:belluga_now/domain/partners/profile_type_registry.dart';
import 'package:belluga_now/domain/repositories/account_profiles_repository_contract.dart';
import 'package:belluga_now/domain/repositories/telemetry_repository_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/backend_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/account_profiles_backend_contract.dart';
import 'package:belluga_now/infrastructure/dal/datasources/mock_account_profiles_database.dart';
import 'package:event_tracker_handler/event_tracker_handler.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';

class AccountProfilesRepository extends AccountProfilesRepositoryContract {
  AccountProfilesRepository({
    AccountProfilesBackendContract? backend,
    BackendContract? backendContract,
    Set<String>? favoriteAccountProfileIds,
    TelemetryRepositoryContract? telemetryRepository,
  })  : _backend =
            backend ?? (backendContract ?? GetIt.I.get<BackendContract>())
                .accountProfiles,
        _favoriteAccountProfileIds =
            Set<String>.from(favoriteAccountProfileIds ??
                MockAccountProfilesDatabase().favoriteAccountProfileIds),
        _telemetryRepository =
            telemetryRepository ?? GetIt.I.get<TelemetryRepositoryContract>();

  static const String _appManagerId = 'app-manager';
  final AccountProfilesBackendContract _backend;
  final Set<String> _favoriteAccountProfileIds;
  final TelemetryRepositoryContract _telemetryRepository;

  @override
  Future<void> init() async {
    final profiles = await fetchAllAccountProfiles();
    allAccountProfilesStreamValue.addValue(profiles);

    // Initialize favorites from mock persistence (app manager included)
    favoriteAccountProfileIdsStreamValue.addValue(
      Set<String>.from(_favoriteAccountProfileIds),
    );
  }

  @override
  Future<List<AccountProfileModel>> fetchAllAccountProfiles() async {
    final profiles = await _backend.fetchAccountProfiles();
    return _filterByRegistry(profiles);
  }

  @override
  Future<List<AccountProfileModel>> searchAccountProfiles({
    String? query,
    String? typeFilter,
  }) async {
    final results =
        await _backend.searchAccountProfiles(query: query, typeFilter: typeFilter);
    return _filterByRegistry(results);
  }

  @override
  Future<AccountProfileModel?> getAccountProfileBySlug(String slug) async {
    final profile = await _backend.fetchAccountProfileBySlug(slug);
    if (profile == null) return null;
    return _isAccountProfileTypeEnabled(profile) ? profile : null;
  }

  @override
  Future<void> toggleFavorite(String accountProfileId) async {
    if (accountProfileId == _appManagerId) {
      return;
    }
    final wasFavorite = _favoriteAccountProfileIds.contains(accountProfileId);
    if (wasFavorite) {
      _favoriteAccountProfileIds.remove(accountProfileId);
    } else {
      _favoriteAccountProfileIds.add(accountProfileId);
    }
    favoriteAccountProfileIdsStreamValue.addValue(
      Set<String>.from(_favoriteAccountProfileIds),
    );
    await _telemetryRepository.logEvent(
      EventTrackerEvents.favoriteArtistToggled,
      eventName: 'favorite_artist_toggled',
      properties: {
        'account_profile_id': accountProfileId,
        'is_favorite': !wasFavorite,
      },
    );
  }

  @override
  bool isFavorite(String accountProfileId) {
    return favoriteAccountProfileIdsStreamValue.value
        .contains(accountProfileId);
  }

  @override
  List<AccountProfileModel> getFavoriteAccountProfiles() {
    final favoriteIds = favoriteAccountProfileIdsStreamValue.value;
    final allAccountProfiles = allAccountProfilesStreamValue.value;

    return allAccountProfiles
        .where((profile) => favoriteIds.contains(profile.id))
        .toList();
  }

  List<AccountProfileModel> _filterByRegistry(List<AccountProfileModel> profiles) {
    final registry = _resolveRegistry();
    if (registry == null || registry.isEmpty) {
      debugPrint('Profile type registry missing; hiding account profile lists.');
      return const [];
    }
    return profiles
        .where(_isAccountProfileTypeEnabled)
        .toList(growable: false);
  }

  bool _isAccountProfileTypeEnabled(AccountProfileModel profile) {
    final registry = _resolveRegistry();
    return registry?.isEnabledFor(profile.profileType) ?? false;
  }

  ProfileTypeRegistry? _resolveRegistry() {
    if (!GetIt.I.isRegistered<AppData>()) {
      return null;
    }
    return GetIt.I.get<AppData>().profileTypeRegistry;
  }
}
