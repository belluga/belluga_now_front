import 'package:belluga_now/domain/app_data/app_data.dart';
import 'package:belluga_now/domain/partners/account_profile_model.dart';
import 'package:belluga_now/domain/partners/paged_account_profiles_result.dart';
import 'package:belluga_now/domain/partners/profile_type_registry.dart';
import 'package:belluga_now/domain/partners/value_objects/profile_type_key_value.dart';
import 'package:belluga_now/domain/repositories/account_profiles_repository_contract.dart';
import 'package:belluga_now/domain/repositories/telemetry_repository_contract.dart';
import 'package:belluga_now/domain/repositories/value_objects/telemetry_repository_contract_values.dart';
import 'package:belluga_now/infrastructure/dal/dao/account_profiles_backend_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/backend_contract.dart';
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

  final AccountProfilesBackendContract _backend;
  final FavoriteBackendContract _favoriteBackend;
  final Set<String> _favoriteAccountProfileIds;
  final TelemetryRepositoryContract _telemetryRepository;

  @override
  Future<void> init() async {
    final remoteFavoriteIds = await _loadRemoteFavoriteIds();
    if (remoteFavoriteIds.isNotEmpty) {
      _favoriteAccountProfileIds
        ..clear()
        ..addAll(remoteFavoriteIds);
    }

    favoriteAccountProfileIdsStreamValue.addValue(
      _toFavoriteIdValues(_favoriteAccountProfileIds),
    );
  }

  @override
  Future<PagedAccountProfilesResult> fetchAccountProfilesPage({
    required AccountProfilesRepositoryContractPrimInt page,
    required AccountProfilesRepositoryContractPrimInt pageSize,
    AccountProfilesRepositoryContractPrimString? query,
    AccountProfilesRepositoryContractPrimString? typeFilter,
  }) async {
    final favoritableTypes = _favoritableEnabledTypes();
    if (favoritableTypes.isEmpty) {
      return pagedAccountProfilesResultFromRaw(
        profiles: <AccountProfileModel>[],
        hasMore: false,
      );
    }

    final normalizedTypeFilter = typeFilter?.value.trim();
    if (normalizedTypeFilter != null &&
        normalizedTypeFilter.isNotEmpty &&
        !favoritableTypes.any((type) => type.value == normalizedTypeFilter)) {
      return pagedAccountProfilesResultFromRaw(
        profiles: <AccountProfileModel>[],
        hasMore: false,
      );
    }

    final result = await _backend.fetchAccountProfilesPage(
      page: page.value,
      pageSize: pageSize.value,
      query: query?.value,
      typeFilter: normalizedTypeFilter,
    );
    final filtered = _filterByRegistry(result.profiles);
    return pagedAccountProfilesResultFromRaw(
      profiles: filtered,
      hasMore: result.hasMore,
    );
  }

  @override
  Future<List<AccountProfileModel>> fetchNearbyAccountProfiles({
    AccountProfilesRepositoryContractPrimInt? pageSize,
  }) async {
    final effectivePageSize = pageSize ??
        _toIntValue(
          10,
          defaultValue: 10,
        );
    final profiles = await _backend.fetchNearbyAccountProfiles(
      pageSize: effectivePageSize.value,
    );
    return _filterByRegistry(profiles);
  }

  @override
  Future<AccountProfileModel?> getAccountProfileBySlug(
    AccountProfilesRepositoryContractPrimString slug,
  ) async {
    final profile = await _backend.fetchAccountProfileBySlug(slug.value);
    if (profile == null) return null;
    return _isAccountProfileTypeEnabled(profile) ? profile : null;
  }

  @override
  Future<void> toggleFavorite(
    AccountProfilesRepositoryContractPrimString accountProfileId,
  ) async {
    final normalizedProfileId = accountProfileId.value.trim();
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
      _toFavoriteIdValues(_favoriteAccountProfileIds),
    );
    try {
      if (wasFavorite) {
        await _favoriteBackend.unfavoriteAccountProfile(normalizedProfileId);
      } else {
        await _favoriteBackend.favoriteAccountProfile(normalizedProfileId);
      }
      await _telemetryRepository.logEvent(
        EventTrackerEvents.favoriteArtistToggled,
        eventName: telemetryRepoString('favorite_artist_toggled'),
        properties: telemetryRepoMap({
          'account_profile_id': normalizedProfileId,
          'is_favorite': !wasFavorite,
        }),
      );
    } catch (error) {
      if (wasFavorite) {
        _favoriteAccountProfileIds.add(normalizedProfileId);
      } else {
        _favoriteAccountProfileIds.remove(normalizedProfileId);
      }
      favoriteAccountProfileIdsStreamValue.addValue(
        _toFavoriteIdValues(_favoriteAccountProfileIds),
      );
      debugPrint(
          'Failed to persist favorite mutation for $normalizedProfileId: $error');
    }
  }

  @override
  AccountProfilesRepositoryContractPrimBool isFavorite(
    AccountProfilesRepositoryContractPrimString accountProfileId,
  ) {
    return _toBoolValue(
      favoriteAccountProfileIdsStreamValue.value
          .map((value) => value.value)
          .contains(accountProfileId.value),
    );
  }

  @override
  List<AccountProfileModel> getFavoriteAccountProfiles() {
    final favoriteIds = favoriteAccountProfileIdsStreamValue.value
        .map((value) => value.value)
        .toSet();
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
    return profiles
        .where(_isAccountProfileTypeEnabled)
        .where(_isAccountProfileTypeFavoritable)
        .toList(growable: false);
  }

  bool _isAccountProfileTypeEnabled(AccountProfileModel profile) {
    final registry = _resolveRegistry();
    return registry?.isEnabledFor(ProfileTypeKeyValue(profile.profileType)) ??
        false;
  }

  bool _isAccountProfileTypeFavoritable(AccountProfileModel profile) {
    final registry = _resolveRegistry();
    return registry
            ?.isFavoritableFor(ProfileTypeKeyValue(profile.profileType)) ??
        false;
  }

  List<ProfileTypeKeyValue> _favoritableEnabledTypes() {
    final registry = _resolveRegistry();
    if (registry == null || registry.isEmpty) {
      return const <ProfileTypeKeyValue>[];
    }
    return registry
        .enabledAccountProfileTypes()
        .where(registry.isFavoritableFor)
        .toList(growable: false);
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

  Set<AccountProfilesRepositoryContractPrimString> _toFavoriteIdValues(
    Iterable<String> values,
  ) {
    return values
        .map(
          (value) => _toTextValue(value),
        )
        .toSet();
  }

  AccountProfilesRepositoryContractPrimString _toTextValue(
    String value, {
    String defaultValue = '',
  }) {
    return AccountProfilesRepositoryContractPrimString.fromRaw(
      value,
      defaultValue: defaultValue,
    );
  }

  AccountProfilesRepositoryContractPrimInt _toIntValue(
    int value, {
    int defaultValue = 0,
  }) {
    return AccountProfilesRepositoryContractPrimInt.fromRaw(
      value,
      defaultValue: defaultValue,
    );
  }

  AccountProfilesRepositoryContractPrimBool _toBoolValue(bool value) {
    return AccountProfilesRepositoryContractPrimBool.fromRaw(
      value,
      defaultValue: false,
    );
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
