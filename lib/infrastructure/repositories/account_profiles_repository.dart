import 'package:belluga_now/domain/partners/account_profile_model.dart';
import 'package:belluga_now/domain/partners/paged_account_profiles_result.dart';
import 'package:belluga_now/domain/app_data/app_data.dart';
import 'package:belluga_now/domain/partners/profile_type_registry.dart';
import 'package:belluga_now/domain/partners/value_objects/profile_type_key_value.dart';
import 'package:belluga_now/domain/repositories/account_profiles_repository_contract.dart';
import 'package:belluga_now/domain/repositories/telemetry_repository_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/backend_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/account_profiles_backend_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/favorite_backend_contract.dart';
import 'package:event_tracker_handler/event_tracker_handler.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';

class AccountProfilesRepository extends AccountProfilesRepositoryContract {
  AccountProfilesRepository({
    AccountProfilesBackendContract? backend,
    FavoriteBackendContract? favoriteBackend,
    BackendContract? backendContract,
    Set<String>? favoriteAccountProfileIds,
    TelemetryRepositoryContract? telemetryRepository,
  })  : _backend = backend ??
            (backendContract ?? GetIt.I.get<BackendContract>()).accountProfiles,
        _favoriteBackend = favoriteBackend ??
            _resolveFavoriteBackend(
              backendContract: backendContract,
            ),
        _favoriteAccountProfileIds =
            Set<String>.from(favoriteAccountProfileIds ?? const <String>{}),
        _telemetryRepository =
            telemetryRepository ?? GetIt.I.get<TelemetryRepositoryContract>();

  static const int _defaultPageSize = 30;
  static const int _maxPagedFetches = 10;
  final AccountProfilesBackendContract _backend;
  final FavoriteBackendContract _favoriteBackend;
  final Set<String> _favoriteAccountProfileIds;
  final TelemetryRepositoryContract _telemetryRepository;

  @override
  Future<void> init() async {
    final profiles = await fetchAllAccountProfiles();
    allAccountProfilesStreamValue.addValue(profiles);

    final remoteFavoriteIds = await _loadRemoteFavoriteIds();
    if (remoteFavoriteIds.isNotEmpty) {
      _favoriteAccountProfileIds
        ..clear()
        ..addAll(remoteFavoriteIds);
    }

    favoriteAccountProfileIdsStreamValue.addValue(
      Set<String>.from(_favoriteAccountProfileIds),
    );
  }

  @override
  Future<List<AccountProfileModel>> fetchAllAccountProfiles() async {
    final profiles = <AccountProfileModel>[];
    var page = 1;
    var hasMore = true;

    while (hasMore && page <= _maxPagedFetches) {
      final result = await fetchAccountProfilesPage(
        page: page,
        pageSize: _defaultPageSize,
      );
      profiles.addAll(result.profiles);
      hasMore = result.hasMore;
      page += 1;
    }

    return profiles;
  }

  @override
  Future<PagedAccountProfilesResult> fetchAccountProfilesPage({
    required int page,
    required int pageSize,
    String? query,
    String? typeFilter,
  }) async {
    final result = await _backend.fetchAccountProfilesPage(
      page: page,
      pageSize: pageSize,
      query: query,
      typeFilter: typeFilter,
    );
    final filtered = _filterByRegistry(result.profiles);
    return PagedAccountProfilesResult(
      profiles: filtered,
      hasMore: result.hasMore,
    );
  }

  @override
  Future<List<AccountProfileModel>> searchAccountProfiles({
    String? query,
    String? typeFilter,
  }) async {
    final results = <AccountProfileModel>[];
    var page = 1;
    var hasMore = true;

    while (hasMore && page <= _maxPagedFetches) {
      final pageResult = await fetchAccountProfilesPage(
        page: page,
        pageSize: _defaultPageSize,
        query: query,
        typeFilter: typeFilter,
      );
      results.addAll(pageResult.profiles);
      hasMore = pageResult.hasMore;
      page += 1;
    }

    return results;
  }

  @override
  Future<AccountProfileModel?> getAccountProfileBySlug(String slug) async {
    final profile = await _backend.fetchAccountProfileBySlug(slug);
    if (profile == null) return null;
    return _isAccountProfileTypeEnabled(profile) ? profile : null;
  }

  @override
  Future<void> toggleFavorite(String accountProfileId) async {
    final normalizedProfileId = accountProfileId.trim();
    if (normalizedProfileId.isEmpty) {
      return;
    }
    final wasFavorite =
        _favoriteAccountProfileIds.contains(normalizedProfileId);
    if (wasFavorite) {
      _favoriteAccountProfileIds.remove(normalizedProfileId);
    } else {
      _favoriteAccountProfileIds.add(normalizedProfileId);
    }
    favoriteAccountProfileIdsStreamValue.addValue(
      Set<String>.from(_favoriteAccountProfileIds),
    );
    try {
      if (wasFavorite) {
        await _favoriteBackend.unfavoriteAccountProfile(normalizedProfileId);
      } else {
        await _favoriteBackend.favoriteAccountProfile(normalizedProfileId);
      }
      await _telemetryRepository.logEvent(
        EventTrackerEvents.favoriteArtistToggled,
        eventName: 'favorite_artist_toggled',
        properties: {
          'account_profile_id': normalizedProfileId,
          'is_favorite': !wasFavorite,
        },
      );
    } catch (error) {
      if (wasFavorite) {
        _favoriteAccountProfileIds.add(normalizedProfileId);
      } else {
        _favoriteAccountProfileIds.remove(normalizedProfileId);
      }
      favoriteAccountProfileIdsStreamValue.addValue(
        Set<String>.from(_favoriteAccountProfileIds),
      );
      debugPrint(
          'Failed to persist favorite mutation for $normalizedProfileId: $error');
    }
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

  List<AccountProfileModel> _filterByRegistry(
      List<AccountProfileModel> profiles) {
    final registry = _resolveRegistry();
    if (registry == null || registry.isEmpty) {
      debugPrint(
          'Profile type registry missing; hiding account profile lists.');
      return const [];
    }
    return profiles.where(_isAccountProfileTypeEnabled).toList(growable: false);
  }

  bool _isAccountProfileTypeEnabled(AccountProfileModel profile) {
    final registry = _resolveRegistry();
    return registry
            ?.isEnabledFor(ProfileTypeKeyValue(profile.profileType)) ??
        false;
  }

  ProfileTypeRegistry? _resolveRegistry() {
    if (!GetIt.I.isRegistered<AppData>()) {
      return null;
    }
    return GetIt.I.get<AppData>().profileTypeRegistry;
  }

  Future<Set<String>> _loadRemoteFavoriteIds() async {
    try {
      final favorites = await _favoriteBackend.fetchFavorites();
      return favorites
          .map((favorite) {
            final targetId = favorite.targetId?.trim();
            if (targetId != null && targetId.isNotEmpty) {
              return targetId;
            }
            return favorite.id.trim();
          })
          .where((id) => id.isNotEmpty)
          .toSet();
    } catch (error, stackTrace) {
      Error.throwWithStackTrace(
        StateError('Failed to load favorites from backend: $error'),
        stackTrace,
      );
    }
  }

  static FavoriteBackendContract _resolveFavoriteBackend({
    required BackendContract? backendContract,
  }) {
    if (backendContract != null) {
      return backendContract.favorites;
    }
    if (GetIt.I.isRegistered<BackendContract>()) {
      return GetIt.I.get<BackendContract>().favorites;
    }
    throw StateError(
      'FavoriteBackendContract is not available for AccountProfilesRepository.',
    );
  }
}
