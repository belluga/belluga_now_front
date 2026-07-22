import 'package:belluga_now/domain/partners/account_profile_model.dart';
import 'package:belluga_now/domain/partners/paged_account_profiles_result.dart';
import 'package:belluga_now/domain/repositories/account_profiles_repository_contract.dart';
import 'package:belluga_now/domain/repositories/favorite_repository_contract.dart';
import 'package:belluga_now/domain/repositories/value_objects/account_profiles_repository_contract_values.dart';
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
    FavoriteRepositoryContract? favoriteRepository,
    TelemetryRepositoryContract? telemetryRepository,
  }) : this._internal(
         backend ??
             (backendContract ?? GetIt.I.get<BackendContract>())
                 .accountProfiles,
         favoriteBackend ??
             _resolveFavoriteBackend(backendContract: backendContract),
         Set<String>.from(favoriteAccountProfileIds ?? const <String>{}),
         favoriteRepository ?? _resolveFavoriteRepositoryOrNull(),
         telemetryRepository ?? GetIt.I.get<TelemetryRepositoryContract>(),
       );

  AccountProfilesRepository._internal(
    this._backend,
    this._favoriteBackend,
    this._favoriteAccountProfileIds,
    this._favoriteRepository,
    this._telemetryRepository,
  );

  final AccountProfilesBackendContract _backend;
  final FavoriteBackendContract _favoriteBackend;
  final Set<String> _favoriteAccountProfileIds;
  final FavoriteRepositoryContract? _favoriteRepository;
  final TelemetryRepositoryContract _telemetryRepository;

  @override
  Future<void> init() async {
    await refreshFavoriteAccountProfileIds();
  }

  @override
  Future<void> refreshFavoriteAccountProfileIds() async {
    final remoteFavoriteIds = await _loadRemoteFavoriteIds();
    _favoriteAccountProfileIds
      ..clear()
      ..addAll(remoteFavoriteIds);

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
    List<AccountProfilesRepositoryContractPrimString>? typeFilters,
    List<AccountProfilesRepositoryTaxonomyFilter>? taxonomyFilters,
  }) async {
    final normalizedTypeFilters = _normalizeTypeFilters(
      singleTypeFilter: typeFilter,
      typeFilters: typeFilters,
    );
    final result = await _backend.fetchAccountProfilesPage(
      page: page.value,
      pageSize: pageSize.value,
      query: query?.value,
      typeFilter: normalizedTypeFilters.length == 1
          ? normalizedTypeFilters.single
          : null,
      typeFilters: normalizedTypeFilters.length > 1
          ? normalizedTypeFilters
          : null,
      taxonomyFilters: _normalizeTaxonomyFilters(taxonomyFilters),
    );
    return pagedAccountProfilesResultFromRaw(
      profiles: result.profiles,
      hasMore: result.hasMore,
      discoveryFilterFacets: result.discoveryFilterFacets,
      discoveryFilterCatalog: result.discoveryFilterCatalog,
    );
  }

  @override
  Future<List<AccountProfileModel>> fetchNearbyAccountProfiles({
    AccountProfilesRepositoryContractPrimInt? pageSize,
    List<AccountProfilesRepositoryContractPrimString>? typeFilters,
    List<AccountProfilesRepositoryTaxonomyFilter>? taxonomyFilters,
  }) async {
    final effectivePageSize = pageSize ?? _toIntValue(10, defaultValue: 10);
    return _backend.fetchNearbyAccountProfiles(
      pageSize: effectivePageSize.value,
      typeFilters: _normalizeTypeFilters(typeFilters: typeFilters),
      taxonomyFilters: _normalizeTaxonomyFilters(taxonomyFilters),
    );
  }

  @override
  Future<AccountProfileModel?> getAccountProfileBySlug(
    AccountProfilesRepositoryContractPrimString slug,
  ) async {
    return _backend.fetchAccountProfileBySlug(slug.value);
  }

  @override
  Future<void> toggleFavorite(
    AccountProfilesRepositoryContractPrimString accountProfileId,
  ) async {
    final normalizedProfileId = accountProfileId.value.trim();
    if (normalizedProfileId.isEmpty) {
      return;
    }
    final wasFavorite = _favoriteAccountProfileIds.contains(
      normalizedProfileId,
    );
    if (wasFavorite) {
      _favoriteAccountProfileIds.remove(normalizedProfileId);
    } else {
      _favoriteAccountProfileIds.add(normalizedProfileId);
    }
    favoriteAccountProfileIdsStreamValue.addValue(
      _toFavoriteIdValues(_favoriteAccountProfileIds),
    );
    var persistenceSucceeded = false;
    try {
      if (wasFavorite) {
        await _favoriteBackend.unfavoriteAccountProfile(normalizedProfileId);
      } else {
        await _favoriteBackend.favoriteAccountProfile(normalizedProfileId);
      }
      persistenceSucceeded = true;
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
        'Failed to persist favorite mutation for $normalizedProfileId: $error',
      );
    }
    if (!persistenceSucceeded) {
      return;
    }
    try {
      await _favoriteRepository?.refreshFavoriteResumes();
    } catch (error) {
      debugPrint(
        'Failed to refresh favorite resumes after mutation for $normalizedProfileId: $error',
      );
    }
    try {
      await _telemetryRepository.logEvent(
        EventTrackerEvents.favoriteArtistToggled,
        eventName: telemetryRepoString('favorite_artist_toggled'),
        properties: telemetryRepoMap({
          'account_profile_id': normalizedProfileId,
          'is_favorite': !wasFavorite,
        }),
      );
    } catch (error) {
      debugPrint(
        'Failed to log favorite mutation telemetry for $normalizedProfileId: $error',
      );
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

  List<String> _normalizeTypeFilters({
    AccountProfilesRepositoryContractPrimString? singleTypeFilter,
    List<AccountProfilesRepositoryContractPrimString>? typeFilters,
  }) {
    return <String>{
      if (singleTypeFilter != null && singleTypeFilter.value.trim().isNotEmpty)
        singleTypeFilter.value.trim(),
      for (final filter in typeFilters ?? const [])
        if (filter.value.trim().isNotEmpty) filter.value.trim(),
    }.toList(growable: false);
  }

  List<AccountProfilesRepositoryTaxonomyFilter> _normalizeTaxonomyFilters(
    List<AccountProfilesRepositoryTaxonomyFilter>? taxonomyFilters,
  ) {
    final seen = <String>{};
    final normalized = <AccountProfilesRepositoryTaxonomyFilter>[];
    for (final filter in taxonomyFilters ?? const []) {
      if (!filter.isValid) {
        continue;
      }
      final key = '${filter.type.value}:${filter.term.value}';
      if (seen.add(key)) {
        normalized.add(filter);
      }
    }
    return normalized;
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
    return values.map((value) => _toTextValue(value)).toSet();
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

  static FavoriteRepositoryContract? _resolveFavoriteRepositoryOrNull() {
    if (!GetIt.I.isRegistered<FavoriteRepositoryContract>()) {
      return null;
    }
    return GetIt.I.get<FavoriteRepositoryContract>();
  }
}
