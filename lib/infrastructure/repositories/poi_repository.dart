import 'package:belluga_now/domain/map/city_poi_model.dart';
import 'package:belluga_now/domain/map/events/poi_update_event.dart';
import 'package:belluga_now/domain/map/filters/poi_filter_options.dart';
import 'package:belluga_now/domain/map/filters/poi_filter_mode.dart';
import 'package:belluga_now/domain/map/map_region_definition.dart';
import 'package:belluga_now/domain/map/queries/poi_query.dart';
import 'package:belluga_now/domain/map/value_objects/city_coordinate.dart';
import 'package:belluga_now/domain/map/value_objects/poi_reference_id_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_reference_type_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_stack_key_value.dart';
import 'package:belluga_now/domain/partners/account_profile_model.dart';
import 'package:belluga_now/domain/repositories/account_profiles_repository_contract.dart';
import 'package:belluga_now/domain/repositories/city_map_repository_contract.dart';
import 'package:belluga_now/domain/repositories/poi_repository_contract.dart';
import 'package:belluga_now/domain/repositories/schedule_repository_contract.dart';
import 'package:belluga_now/domain/repositories/static_assets_repository_contract.dart';
import 'package:belluga_now/domain/schedule/event_model.dart';
import 'package:belluga_now/domain/static_assets/public_static_asset_model.dart';
import 'package:belluga_now/domain/value_objects/thumb_uri_value.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value.dart';

class PoiRepository implements PoiRepositoryContract {
  PoiRepository({
    CityMapRepositoryContract? dataSource,
    AccountProfilesRepositoryContract? accountProfilesRepository,
    ScheduleRepositoryContract? scheduleRepository,
    StaticAssetsRepositoryContract? staticAssetsRepository,
  })  : _dataSource = dataSource ?? GetIt.I.get<CityMapRepositoryContract>(),
        _accountProfilesRepository = accountProfilesRepository ??
            (GetIt.I.isRegistered<AccountProfilesRepositoryContract>()
                ? GetIt.I.get<AccountProfilesRepositoryContract>()
                : null),
        _scheduleRepository = scheduleRepository ??
            (GetIt.I.isRegistered<ScheduleRepositoryContract>()
                ? GetIt.I.get<ScheduleRepositoryContract>()
                : null),
        _staticAssetsRepository = staticAssetsRepository ??
            (GetIt.I.isRegistered<StaticAssetsRepositoryContract>()
                ? GetIt.I.get<StaticAssetsRepositoryContract>()
                : null);

  final CityMapRepositoryContract _dataSource;
  final AccountProfilesRepositoryContract? _accountProfilesRepository;
  final ScheduleRepositoryContract? _scheduleRepository;
  final StaticAssetsRepositoryContract? _staticAssetsRepository;

  final allPoisStreamValue =
      StreamValue<List<CityPoiModel>?>(defaultValue: null);
  @override
  final filteredPoisStreamValue =
      StreamValue<List<CityPoiModel>?>(defaultValue: null);
  @override
  final stackItemsStreamValue =
      StreamValue<List<CityPoiModel>?>(defaultValue: null);
  @override
  final selectedPoiStreamValue = StreamValue<CityPoiModel?>();
  @override
  final filterModeStreamValue =
      StreamValue<PoiFilterMode>(defaultValue: PoiFilterMode.none);
  PoiFilterMode _filterMode = PoiFilterMode.none;

  @override
  final filterOptionsStreamValue = StreamValue<PoiFilterOptions?>();
  @override
  final poiHydrationRevisionStreamValue =
      StreamValue<int>(defaultValue: 0);
  final Map<String, Future<void>> _poiHydrationInFlightById =
      <String, Future<void>>{};
  final Map<String, AccountProfileModel> _hydratedAccountProfilesByPoiId =
      <String, AccountProfileModel>{};
  final Map<String, EventModel> _hydratedEventsByPoiId =
      <String, EventModel>{};
  final Map<String, PublicStaticAssetModel> _hydratedStaticAssetsByPoiId =
      <String, PublicStaticAssetModel>{};

  @override
  Future<List<CityPoiModel>> fetchPoints(PoiQuery query) async {
    final cityPois = await _dataSource.fetchPoints(query);
    final snapshot = List<CityPoiModel>.unmodifiable(cityPois);
    _setAllPois(snapshot);
    return snapshot;
  }

  Future<void> initializePoiStreams() async {
    if (filterOptionsStreamValue.value == null) {
      await fetchFilters();
    }
  }

  @override
  Future<void> refreshPoints(PoiQuery query) async {
    await fetchPoints(query);
  }

  @override
  Future<List<CityPoiModel>> fetchStackItems({
    required PoiStackKeyValue stackKey,
    required PoiQuery query,
  }) {
    return _dataSource.fetchStackItems(
      query: query,
      stackKey: stackKey,
    );
  }

  @override
  Future<CityPoiModel?> fetchPoiByReference({
    required PoiReferenceTypeValue refType,
    required PoiReferenceIdValue refId,
  }) {
    return _dataSource.fetchPoiByReference(
      refType: refType,
      refId: refId,
    );
  }

  @override
  Future<void> loadStackItems({
    required PoiStackKeyValue stackKey,
    required PoiQuery query,
  }) async {
    final stackItems = await fetchStackItems(
      stackKey: stackKey,
      query: query,
    );
    setStackItems(stackItems);
  }

  @override
  Future<PoiFilterOptions> fetchFilters() async {
    final filters = await _dataSource.fetchFilters();
    filterOptionsStreamValue.addValue(filters);
    return filters;
  }

  @override
  Future<void> ensurePoiHydrated(CityPoiModel poi) async {
    if (!_supportsPoiHydration(poi)) {
      return;
    }
    if (_isPoiHydrated(poi)) {
      return;
    }
    final inFlight = _poiHydrationInFlightById[poi.id];
    if (inFlight != null) {
      await inFlight;
      return;
    }

    final future = _hydratePoi(poi).whenComplete(() {
      _poiHydrationInFlightById.remove(poi.id);
    });
    _poiHydrationInFlightById[poi.id] = future;
    await future;
  }

  Future<List<MapRegionDefinition>> fetchRegions() =>
      _dataSource.fetchRegions();

  Future<ThumbUriValue> fetchFallbackEventImage() =>
      _dataSource.fetchFallbackEventImage();

  Stream<PoiUpdateEvent?> get poiEvents => _dataSource.poiEvents;

  @override
  CityCoordinate get defaultCenter => _dataSource.defaultCenter();

  @override
  void selectPoi(CityPoiModel? poi) {
    selectedPoiStreamValue.addValue(poi);
  }

  @override
  void clearSelection() => selectPoi(null);

  @override
  void setStackItems(List<CityPoiModel>? items) {
    if (items == null) {
      stackItemsStreamValue.addValue(null);
      return;
    }
    stackItemsStreamValue.addValue(List<CityPoiModel>.unmodifiable(items));
  }

  @override
  void clearStackItems() => setStackItems(null);

  @override
  void clearLoadedPois() {
    _setAllPois(const <CityPoiModel>[]);
    clearSelection();
    clearStackItems();
  }

  @override
  void applyFilterMode(PoiFilterMode mode) {
    if (_filterMode == mode) {
      return;
    }
    _filterMode = mode;
    filterModeStreamValue.addValue(mode);
    _recomputeFilteredPois();
    if (mode == PoiFilterMode.none) {
      clearSelection();
    }
  }

  @override
  void clearFilters() => applyFilterMode(PoiFilterMode.none);

  @override
  AccountProfileModel? hydratedAccountProfileForPoi(CityPoiModel poi) {
    return _hydratedAccountProfilesByPoiId[poi.id];
  }

  @override
  EventModel? hydratedEventForPoi(CityPoiModel poi) {
    return _hydratedEventsByPoiId[poi.id];
  }

  @override
  PublicStaticAssetModel? hydratedStaticAssetForPoi(CityPoiModel poi) {
    return _hydratedStaticAssetsByPoiId[poi.id];
  }

  void _setAllPois(List<CityPoiModel> pois) {
    final snapshot = List<CityPoiModel>.unmodifiable(pois);
    allPoisStreamValue.addValue(snapshot);
    _recomputeFilteredPois(snapshot);
  }

  void _recomputeFilteredPois([List<CityPoiModel>? source]) {
    final all = source ?? allPoisStreamValue.value ?? const <CityPoiModel>[];
    final filtered = all;

    final snapshot = List<CityPoiModel>.unmodifiable(filtered);
    filteredPoisStreamValue.addValue(snapshot);

    if (_filterMode == PoiFilterMode.none) {
      return;
    }

    final selected = selectedPoiStreamValue.value;
    if (selected == null) {
      return;
    }
    final stillContains = snapshot.any((poi) => poi.id == selected.id);
    if (!stillContains) {
      clearSelection();
    }
  }

  bool _supportsPoiHydration(CityPoiModel poi) {
    return _isPartnerPoi(poi) || _isEventPoi(poi) || _isStaticPoi(poi);
  }

  bool _isPoiHydrated(CityPoiModel poi) {
    return _hydratedAccountProfilesByPoiId.containsKey(poi.id) ||
        _hydratedEventsByPoiId.containsKey(poi.id) ||
        _hydratedStaticAssetsByPoiId.containsKey(poi.id);
  }

  Future<void> _hydratePoi(CityPoiModel poi) async {
    try {
      if (_isPartnerPoi(poi)) {
        final slug = _resolvePoiSlug(poi);
        final repository = _accountProfilesRepository;
        if (slug == null || repository == null) {
          return;
        }
        final profile = await repository.getAccountProfileBySlug(
          AccountProfilesRepositoryContractPrimString.fromRaw(slug),
        );
        if (profile == null) {
          return;
        }
        _hydratedAccountProfilesByPoiId[poi.id] = profile;
        _bumpPoiHydrationRevision();
        return;
      }

      if (_isEventPoi(poi)) {
        final slug = _resolvePoiSlug(poi);
        final repository = _scheduleRepository;
        if (slug == null || repository == null) {
          return;
        }
        final event = await repository.getEventBySlug(
          ScheduleRepoString.fromRaw(
            slug,
            defaultValue: slug,
            isRequired: true,
          ),
        );
        if (event == null) {
          return;
        }
        _hydratedEventsByPoiId[poi.id] = event;
        _bumpPoiHydrationRevision();
        return;
      }

      if (_isStaticPoi(poi)) {
        final assetRef = _resolveStaticAssetRef(poi);
        final repository = _staticAssetsRepository;
        if (assetRef == null || repository == null) {
          return;
        }
        final asset = await repository.getStaticAssetByRef(
          StaticAssetRepoText.fromRaw(
            assetRef,
            defaultValue: assetRef,
            isRequired: true,
          ),
        );
        if (asset == null) {
          return;
        }
        _hydratedStaticAssetsByPoiId[poi.id] = asset;
        _bumpPoiHydrationRevision();
      }
    } catch (error) {
      debugPrint('Failed to hydrate poi ${poi.id}: $error');
    }
  }

  void _bumpPoiHydrationRevision() {
    poiHydrationRevisionStreamValue
        .addValue(poiHydrationRevisionStreamValue.value + 1);
  }

  bool _isPartnerPoi(CityPoiModel poi) {
    return poi.refType.trim().toLowerCase() == 'account_profile';
  }

  bool _isEventPoi(CityPoiModel poi) {
    return poi.refType.trim().toLowerCase() == 'event';
  }

  bool _isStaticPoi(CityPoiModel poi) {
    final refType = poi.refType.trim().toLowerCase();
    return refType == 'static' || refType == 'static_asset' || refType == 'asset';
  }

  String? _resolvePoiSlug(CityPoiModel poi) {
    final refSlug = poi.refSlug?.trim();
    if (refSlug != null && refSlug.isNotEmpty) {
      return refSlug;
    }

    final refPath = poi.refPath?.trim();
    if (refPath == null || refPath.isEmpty) {
      return null;
    }

    final segments = refPath
        .split('/')
        .map((entry) => entry.trim())
        .where((entry) => entry.isNotEmpty)
        .toList(growable: false);
    if (segments.isEmpty) {
      return null;
    }
    return segments.last;
  }

  String? _resolveStaticAssetRef(CityPoiModel poi) {
    final refSlug = poi.refSlug?.trim();
    if (refSlug != null && refSlug.isNotEmpty) {
      return refSlug;
    }
    final refId = poi.refId.trim();
    if (refId.isNotEmpty) {
      return refId;
    }
    return _resolvePoiSlug(poi);
  }
}
