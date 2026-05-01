import 'dart:async';
import 'dart:io';

import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/icons/boora_icons.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/application/router/guards/location_permission_gate_runtime.dart';
import 'package:belluga_now/application/router/support/canonical_route_family.dart';
import 'package:belluga_now/application/router/support/canonical_route_meta.dart';
import 'package:belluga_now/application/map_surface/belluga_map_handle_contract.dart';
import 'package:belluga_now/application/map_surface/belluga_map_interaction.dart';
import 'package:belluga_now/domain/app_data/app_data.dart';
import 'package:belluga_now/domain/app_data/value_object/app_data_map_filter_catalog_keys_value.dart';
import 'package:belluga_now/domain/map/city_poi_category.dart';
import 'package:belluga_now/domain/map/city_poi_model.dart';
import 'package:belluga_now/domain/map/events/poi_update_event.dart';
import 'package:belluga_now/domain/map/filters/poi_filter_mode.dart';
import 'package:belluga_now/domain/map/filters/poi_filter_options.dart';
import 'package:belluga_now/domain/map/map_status.dart';
import 'package:belluga_now/domain/map/map_region_definition.dart';
import 'package:belluga_now/domain/map/projections/city_poi_stack_items.dart';
import 'package:belluga_now/domain/map/queries/poi_query.dart';
import 'package:belluga_now/domain/map/ride_share_provider.dart';
import 'package:belluga_now/domain/map/value_objects/city_coordinate.dart';
import 'package:belluga_now/domain/map/value_objects/city_poi_address_value.dart';
import 'package:belluga_now/domain/map/value_objects/city_poi_description_value.dart';
import 'package:belluga_now/domain/map/value_objects/city_poi_id_value.dart';
import 'package:belluga_now/domain/map/value_objects/city_poi_name_value.dart';
import 'package:belluga_now/domain/map/value_objects/distance_in_meters_value.dart';
import 'package:belluga_now/domain/map/value_objects/latitude_value.dart';
import 'package:belluga_now/domain/map/value_objects/longitude_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_boolean_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_filter_count_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_filter_image_uri_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_filter_key_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_filter_label_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_filter_source_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_filter_taxonomy_token_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_filter_type_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_hex_color_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_icon_symbol_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_priority_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_reference_id_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_reference_path_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_reference_slug_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_reference_type_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_stack_count_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_stack_key_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_type_label_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_tag_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_time_end_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_time_start_value.dart';
import 'package:belluga_now/domain/partners/account_profile_model.dart';
import 'package:belluga_now/domain/partners/paged_account_profiles_result.dart';
import 'package:belluga_now/domain/repositories/account_profiles_repository_contract.dart';
import 'package:belluga_now/domain/repositories/app_data_repository_contract.dart';
import 'package:belluga_now/domain/repositories/city_map_repository_contract.dart';
import 'package:belluga_now/domain/repositories/poi_repository_contract.dart';
import 'package:belluga_now/domain/repositories/schedule_repository_contract.dart';
import 'package:belluga_now/domain/repositories/schedule_repository_contract_delta_handler.dart';
import 'package:belluga_now/domain/repositories/static_assets_repository_contract.dart';
import 'package:belluga_now/domain/repositories/telemetry_repository_contract.dart';
import 'package:belluga_now/domain/repositories/value_objects/telemetry_repository_contract_values.dart';
import 'package:belluga_now/domain/schedule/event_delta_model.dart';
import 'package:belluga_now/domain/schedule/event_model.dart';
import 'package:belluga_now/domain/static_assets/public_static_asset_model.dart';
import 'package:belluga_now/domain/static_assets/value_objects/public_static_asset_fields.dart';
import 'package:belluga_now/infrastructure/services/telemetry/telemetry_properties_codec.dart';
import 'package:belluga_now/infrastructure/dal/dto/schedule/event_dto.dart';
import 'package:belluga_now/domain/repositories/user_location_repository_contract.dart';
import 'package:belluga_now/domain/value_objects/slug_value.dart';
import 'package:belluga_now/domain/value_objects/thumb_uri_value.dart';
import 'package:belluga_now/infrastructure/repositories/poi_repository.dart';
import 'package:belluga_now/infrastructure/services/location_origin_service.dart';
import 'package:belluga_now/testing/app_data_test_factory.dart';
import 'package:belluga_now/testing/account_profile_model_factory.dart';
import 'package:belluga_now/presentation/tenant_public/map/screens/map_screen/controllers/map_location_feedback_state.dart';
import 'package:belluga_now/presentation/tenant_public/map/screens/map_screen/controllers/map_screen_controller.dart';
import 'package:belluga_now/presentation/tenant_public/map/screens/map_screen/controllers/map_tray_mode.dart';
import 'package:belluga_now/presentation/tenant_public/map/screens/map_screen/map_screen.dart';
import 'package:belluga_now/presentation/tenant_public/map/screens/map_screen/widgets/poi_details_deck.dart';
import 'package:event_tracker_handler/event_tracker_handler.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value.dart';

class _LoggedEvent {
  _LoggedEvent({
    required this.event,
    required this.eventName,
    required this.properties,
  });

  final EventTrackerEvents event;
  final String? eventName;
  final Map<String, dynamic>? properties;
}

class _TimedEvent {
  _TimedEvent({
    required this.handle,
    required this.event,
    required this.eventName,
    required this.properties,
  });

  final EventTrackerTimedEventHandle handle;
  final EventTrackerEvents event;
  final String? eventName;
  final Map<String, dynamic>? properties;
}

class _FakeTelemetryRepository implements TelemetryRepositoryContract {
  final List<_LoggedEvent> events = [];
  final List<_TimedEvent> activeTimedEvents = [];
  int _handleSeed = 0;

  @override
  Future<TelemetryRepositoryContractPrimBool> logEvent(
    EventTrackerEvents event, {
    TelemetryRepositoryContractPrimString? eventName,
    TelemetryRepositoryContractPrimMap? properties,
  }) async {
    events.add(
      _LoggedEvent(
        event: event,
        eventName: eventName?.value,
        properties: properties == null
            ? null
            : TelemetryPropertiesCodec.toRawMap(properties),
      ),
    );
    return telemetryRepoBool(true);
  }

  @override
  Future<EventTrackerTimedEventHandle?> startTimedEvent(
    EventTrackerEvents event, {
    TelemetryRepositoryContractPrimString? eventName,
    TelemetryRepositoryContractPrimMap? properties,
  }) async {
    final handle = EventTrackerTimedEventHandle('handle-${_handleSeed++}');
    activeTimedEvents.add(
      _TimedEvent(
        handle: handle,
        event: event,
        eventName: eventName?.value,
        properties: properties == null
            ? null
            : TelemetryPropertiesCodec.toRawMap(properties),
      ),
    );
    return handle;
  }

  @override
  Future<TelemetryRepositoryContractPrimBool> finishTimedEvent(
      EventTrackerTimedEventHandle handle) async {
    final index = activeTimedEvents.indexWhere(
      (entry) => entry.handle.id == handle.id,
    );
    if (index == -1) {
      return telemetryRepoBool(true);
    }
    final entry = activeTimedEvents.removeAt(index);
    events.add(
      _LoggedEvent(
        event: entry.event,
        eventName: entry.eventName,
        properties: entry.properties,
      ),
    );
    return telemetryRepoBool(true);
  }

  @override
  Future<TelemetryRepositoryContractPrimBool> flushTimedEvents() async {
    return telemetryRepoBool(true);
  }

  @override
  Future<TelemetryRepositoryContractPrimBool> mergeIdentity(
          {required TelemetryRepositoryContractPrimString
              previousUserId}) async =>
      telemetryRepoBool(true);

  @override
  void setScreenContext(TelemetryRepositoryContractPrimMap? screenContext) {}

  @override
  EventTrackerLifecycleObserver? buildLifecycleObserver() => null;
}

class _FakeUserLocationRepository implements UserLocationRepositoryContract {
  int refreshIfPermittedCallCount = 0;
  int resolveUserLocationCallCount = 0;
  int startTrackingCallCount = 0;
  Completer<bool>? refreshIfPermittedCompleter;
  Completer<String?>? resolveUserLocationCompleter;

  @override
  final StreamValue<CityCoordinate?> userLocationStreamValue =
      StreamValue<CityCoordinate?>();

  @override
  final StreamValue<CityCoordinate?> lastKnownLocationStreamValue =
      StreamValue<CityCoordinate?>();

  @override
  final StreamValue<DateTime?> lastKnownCapturedAtStreamValue =
      StreamValue<DateTime?>();

  @override
  final StreamValue<double?> lastKnownAccuracyStreamValue =
      StreamValue<double?>();

  @override
  final StreamValue<String?> lastKnownAddressStreamValue =
      StreamValue<String?>();

  @override
  final StreamValue<LocationResolutionPhase>
      locationResolutionPhaseStreamValue = StreamValue<LocationResolutionPhase>(
    defaultValue: LocationResolutionPhase.unknown,
  );

  @override
  Future<void> ensureLoaded() async {}

  @override
  Future<void> setLastKnownAddress(Object? address) async {}

  @override
  Future<bool> warmUpIfPermitted() async => false;

  @override
  Future<bool> refreshIfPermitted({Object? minInterval}) async {
    refreshIfPermittedCallCount += 1;
    locationResolutionPhaseStreamValue.addValue(
      LocationResolutionPhase.resolving,
    );
    final completer = refreshIfPermittedCompleter;
    if (completer != null) {
      return completer.future;
    }
    return false;
  }

  @override
  Future<String?> resolveUserLocation() async {
    resolveUserLocationCallCount += 1;
    locationResolutionPhaseStreamValue.addValue(
      LocationResolutionPhase.resolving,
    );
    final completer = resolveUserLocationCompleter;
    if (completer != null) {
      return completer.future;
    }
    return null;
  }

  @override
  Future<bool> startTracking(
      {LocationTrackingMode mode = LocationTrackingMode.mapForeground}) async {
    startTrackingCallCount += 1;
    return true;
  }

  @override
  Future<void> stopTracking() async {}

  void dispose() {
    userLocationStreamValue.dispose();
    lastKnownLocationStreamValue.dispose();
    lastKnownCapturedAtStreamValue.dispose();
    lastKnownAccuracyStreamValue.dispose();
    lastKnownAddressStreamValue.dispose();
    locationResolutionPhaseStreamValue.dispose();
  }
}

class _FakeCityMapRepository implements CityMapRepositoryContract {
  _FakeCityMapRepository() {
    final latitude = LatitudeValue()..parse('-20.0');
    final longitude = LongitudeValue()..parse('-40.0');
    _defaultCenter = CityCoordinate(
      latitudeValue: latitude,
      longitudeValue: longitude,
    );
  }

  late final CityCoordinate _defaultCenter;
  final StreamController<PoiUpdateEvent?> _poiEventsController =
      StreamController<PoiUpdateEvent?>.broadcast();
  PoiQuery? lastQuery;
  PoiQuery? lastStackQuery;
  String? lastStackKey;
  String? lastLookupRefType;
  String? lastLookupRefId;
  List<CityPoiModel> nextPois = const <CityPoiModel>[];
  List<CityPoiModel> nextStackItems = const <CityPoiModel>[];
  CityPoiModel? nextLookupPoi;
  bool throwOnFetchPoints = false;
  bool throwOnFetchStackItems = false;
  bool throwOnLookupPoi = false;
  bool throwOnFetchFilters = false;
  int fetchPointsCallCount = 0;
  int fetchFiltersCallCount = 0;
  final List<Completer<List<CityPoiModel>>> queuedFetchCompleters =
      <Completer<List<CityPoiModel>>>[];
  PoiFilterOptions nextFilterOptions = PoiFilterOptions(categories: const []);

  @override
  Future<List<CityPoiModel>> fetchPoints(PoiQuery query) async {
    fetchPointsCallCount += 1;
    lastQuery = query;
    if (queuedFetchCompleters.isNotEmpty) {
      final completer = queuedFetchCompleters.removeAt(0);
      return completer.future;
    }
    if (throwOnFetchPoints) {
      throw Exception('forced fetch failure');
    }
    return nextPois;
  }

  @override
  Future<List<CityPoiModel>> fetchStackItems({
    required PoiQuery query,
    required PoiStackKeyValue stackKey,
  }) async {
    lastStackQuery = query;
    lastStackKey = stackKey.value;
    if (throwOnFetchStackItems) {
      throw Exception('forced stack fetch failure');
    }
    return nextStackItems;
  }

  @override
  Future<CityPoiModel?> fetchPoiByReference({
    required PoiReferenceTypeValue refType,
    required PoiReferenceIdValue refId,
  }) async {
    lastLookupRefType = refType.value;
    lastLookupRefId = refId.value;
    if (throwOnLookupPoi) {
      throw Exception('forced lookup failure');
    }
    return nextLookupPoi;
  }

  @override
  Future<PoiFilterOptions> fetchFilters() async {
    fetchFiltersCallCount += 1;
    if (throwOnFetchFilters) {
      throw Exception('forced filters failure');
    }
    return nextFilterOptions;
  }

  @override
  Future<List<MapRegionDefinition>> fetchRegions() async => const [];

  @override
  Future<ThumbUriValue> fetchFallbackEventImage() async {
    final value = ThumbUriValue(
      defaultValue: Uri.parse('asset://event-placeholder'),
    );
    value.parse(value.defaultValue.toString());
    return value;
  }

  @override
  Stream<PoiUpdateEvent?> get poiEvents => _poiEventsController.stream;

  @override
  CityCoordinate defaultCenter() => _defaultCenter;

  @override
  void dispose() {
    _poiEventsController.close();
  }
}

class _FakeAccountProfilesRepository
    implements AccountProfilesRepositoryContract {
  int getAccountProfileBySlugCallCount = 0;
  @override
  final selectedAccountProfileStreamValue =
      StreamValue<AccountProfileModel?>(defaultValue: null);
  final List<String> requestedSlugs = <String>[];
  final Map<String, AccountProfileModel?> profilesBySlug =
      <String, AccountProfileModel?>{};
  final Map<String, Completer<AccountProfileModel?>> pendingBySlug =
      <String, Completer<AccountProfileModel?>>{};

  @override
  Future<void> init() async {}

  @override
  Future<PagedAccountProfilesResult> fetchAccountProfilesPage({
    required AccountProfilesRepositoryContractPrimInt page,
    required AccountProfilesRepositoryContractPrimInt pageSize,
    AccountProfilesRepositoryContractPrimString? query,
    AccountProfilesRepositoryContractPrimString? typeFilter,
    List<AccountProfilesRepositoryContractPrimString>? typeFilters,
    List<dynamic>? taxonomyFilters,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<List<AccountProfileModel>> fetchNearbyAccountProfiles({
    AccountProfilesRepositoryContractPrimInt? pageSize,
    List<AccountProfilesRepositoryContractPrimString>? typeFilters,
    List<dynamic>? taxonomyFilters,
  }) async {
    return const <AccountProfileModel>[];
  }

  @override
  Future<AccountProfileModel?> getAccountProfileBySlug(
    AccountProfilesRepositoryContractPrimString slug,
  ) async {
    getAccountProfileBySlugCallCount += 1;
    requestedSlugs.add(slug.value);
    final pending = pendingBySlug[slug.value];
    if (pending != null) {
      return pending.future;
    }
    return profilesBySlug[slug.value];
  }

  @override
  Future<void> loadAccountProfileBySlug(
    AccountProfilesRepositoryContractPrimString slug,
  ) async {
    final profile = await getAccountProfileBySlug(slug);
    selectedAccountProfileStreamValue.addValue(profile);
  }

  @override
  void clearSelectedAccountProfile() {
    selectedAccountProfileStreamValue.addValue(null);
  }

  @override
  void setSelectedAccountProfile(AccountProfileModel? profile) {
    selectedAccountProfileStreamValue.addValue(profile);
  }

  @override
  Future<void> toggleFavorite(
    AccountProfilesRepositoryContractPrimString accountProfileId,
  ) {
    throw UnimplementedError();
  }

  @override
  AccountProfilesRepositoryContractPrimBool isFavorite(
    AccountProfilesRepositoryContractPrimString accountProfileId,
  ) {
    return AccountProfilesRepositoryContractPrimBool.fromRaw(
      false,
      defaultValue: false,
    );
  }

  @override
  List<AccountProfileModel> getFavoriteAccountProfiles() {
    return const <AccountProfileModel>[];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    return super.noSuchMethod(invocation);
  }
}

class _FakeScheduleRepository implements ScheduleRepositoryContract {
  @override
  final StreamValue<List<EventModel>?> homeAgendaStreamValue =
      StreamValue<List<EventModel>?>();
  @override
  final StreamValue<List<EventModel>?> discoveryLiveNowEventsStreamValue =
      StreamValue<List<EventModel>?>(defaultValue: null);

  final Map<String, EventModel?> eventsBySlug = <String, EventModel?>{};
  final List<String> requestedSlugs = <String>[];

  @override
  List<EventModel>? readHomeAgenda({
    required ScheduleRepoBool showPastOnly,
    required ScheduleRepoString searchQuery,
    required ScheduleRepoBool confirmedOnly,
    ScheduleRepoDouble? originLat,
    ScheduleRepoDouble? originLng,
    ScheduleRepoDouble? maxDistanceMeters,
    List<ScheduleRepoString>? categories,
    ScheduleRepoTaxonomyEntries? taxonomy,
  }) {
    return homeAgendaStreamValue.value;
  }

  void writeHomeAgendaCache(List<EventModel> events) {
    homeAgendaStreamValue.addValue(List<EventModel>.unmodifiable(events));
  }

  void clearHomeAgendaCache() {
    homeAgendaStreamValue.addValue(null);
  }

  @override
  Future<List<EventModel>> loadHomeAgenda({
    required ScheduleRepoBool showPastOnly,
    required ScheduleRepoString searchQuery,
    required ScheduleRepoBool confirmedOnly,
    ScheduleRepoDouble? originLat,
    ScheduleRepoDouble? originLng,
    ScheduleRepoDouble? maxDistanceMeters,
    List<ScheduleRepoString>? categories,
    ScheduleRepoTaxonomyEntries? taxonomy,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<List<EventModel>> loadMoreHomeAgenda({
    required ScheduleRepoBool showPastOnly,
    required ScheduleRepoString searchQuery,
    required ScheduleRepoBool confirmedOnly,
    ScheduleRepoDouble? originLat,
    ScheduleRepoDouble? originLng,
    ScheduleRepoDouble? maxDistanceMeters,
    List<ScheduleRepoString>? categories,
    ScheduleRepoTaxonomyEntries? taxonomy,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<EventModel?> getEventBySlug(
    ScheduleRepoString slug, {
    ScheduleRepoString? occurrenceId,
  }) async {
    requestedSlugs.add(slug.value);
    return eventsBySlug[slug.value];
  }

  @override
  Future<List<EventModel>> loadEventSearch({
    required ScheduleRepoBool showPastOnly,
    ScheduleRepoString? searchQuery,
    ScheduleRepoBool? confirmedOnly,
    List<ScheduleRepoString>? occurrenceIds,
    ScheduleRepoDouble? originLat,
    ScheduleRepoDouble? originLng,
    ScheduleRepoDouble? maxDistanceMeters,
  }) async {
    return const <EventModel>[];
  }

  @override
  Future<List<EventModel>> loadMoreEventSearch({
    required ScheduleRepoBool showPastOnly,
    ScheduleRepoString? searchQuery,
    ScheduleRepoBool? confirmedOnly,
    List<ScheduleRepoString>? occurrenceIds,
    ScheduleRepoDouble? originLat,
    ScheduleRepoDouble? originLng,
    ScheduleRepoDouble? maxDistanceMeters,
  }) async {
    return const <EventModel>[];
  }

  @override
  Future<List<EventModel>> loadConfirmedEvents({
    required ScheduleRepoBool showPastOnly,
  }) async {
    return const <EventModel>[];
  }

  @override
  Future<void> refreshDiscoveryLiveNowEvents({
    ScheduleRepoDouble? originLat,
    ScheduleRepoDouble? originLng,
    ScheduleRepoDouble? maxDistanceMeters,
  }) async {}

  @override
  Stream<EventDeltaModel> watchEventsStream({
    ScheduleRepoString? searchQuery,
    List<ScheduleRepoString>? categories,
    List<ScheduleRepoString>? tags,
    ScheduleRepoTaxonomyEntries? taxonomy,
    ScheduleRepoBool? confirmedOnly,
    List<ScheduleRepoString>? occurrenceIds,
    ScheduleRepoDouble? originLat,
    ScheduleRepoDouble? originLng,
    ScheduleRepoDouble? maxDistanceMeters,
    ScheduleRepoString? lastEventId,
    ScheduleRepoBool? showPastOnly,
  }) {
    return const Stream<EventDeltaModel>.empty();
  }

  @override
  Stream<void> watchEventsSignal({
    required ScheduleRepositoryContractDeltaHandler onDelta,
    ScheduleRepoString? searchQuery,
    List<ScheduleRepoString>? categories,
    List<ScheduleRepoString>? tags,
    ScheduleRepoTaxonomyEntries? taxonomy,
    ScheduleRepoBool? confirmedOnly,
    List<ScheduleRepoString>? occurrenceIds,
    ScheduleRepoDouble? originLat,
    ScheduleRepoDouble? originLng,
    ScheduleRepoDouble? maxDistanceMeters,
    ScheduleRepoString? lastEventId,
    ScheduleRepoBool? showPastOnly,
  }) {
    return const Stream<void>.empty();
  }
}

class _FakeStaticAssetsRepository implements StaticAssetsRepositoryContract {
  final Map<String, PublicStaticAssetModel?> assetsByRef =
      <String, PublicStaticAssetModel?>{};
  final List<String> requestedRefs = <String>[];

  @override
  Future<PublicStaticAssetModel?> getStaticAssetByRef(
    StaticAssetRepoText assetRef,
  ) async {
    requestedRefs.add(assetRef.value);
    return assetsByRef[assetRef.value];
  }
}

PoiRepository _buildPoiRepository({
  required CityMapRepositoryContract mapRepository,
  AccountProfilesRepositoryContract? accountProfilesRepository,
  ScheduleRepositoryContract? scheduleRepository,
  StaticAssetsRepositoryContract? staticAssetsRepository,
}) {
  return PoiRepository(
    dataSource: mapRepository,
    accountProfilesRepository: accountProfilesRepository,
    scheduleRepository: scheduleRepository,
    staticAssetsRepository: staticAssetsRepository,
  );
}

PublicStaticAssetModel _buildPublicStaticAsset({
  required String id,
  required String name,
  required String slug,
  required String coverUrl,
  required String description,
}) {
  return PublicStaticAssetModel(
    idValue: PublicStaticAssetIdValue(defaultValue: id),
    profileTypeValue: PublicStaticAssetTypeValue(defaultValue: 'beach'),
    displayNameValue: PublicStaticAssetNameValue(defaultValue: name),
    slugValue: SlugValue()..parse(slug),
    coverValue: ThumbUriValue(defaultValue: Uri.parse(coverUrl)),
    contentValue: PublicStaticAssetDescriptionValue(
      defaultValue: description,
      isRequired: false,
    ),
  );
}

class _FakeMapHandle implements BellugaMapHandleContract {
  static const double _cameraCoordinateTolerance = 0.000001;
  static const double _cameraZoomTolerance = 0.01;

  _FakeMapHandle({
    bool isReady = true,
    double? initialZoom,
    CityCoordinate? initialCenter,
    bool treatNoOpMoveAsSuccess = false,
  })  : _isReady = isReady,
        _currentZoom = initialZoom ?? 16,
        _currentCenter = initialCenter,
        _treatNoOpMoveAsSuccess = treatNoOpMoveAsSuccess;

  final StreamController<BellugaMapInteractionEvent> _events =
      StreamController<BellugaMapInteractionEvent>.broadcast();
  bool _isReady;
  double? _currentZoom;
  CityCoordinate? _currentCenter;
  final bool _treatNoOpMoveAsSuccess;
  int moveCallCount = 0;
  CityCoordinate? lastMoveCoordinate;
  double? lastMoveZoom;
  double? lastVerticalViewportAnchor;
  Offset projectedViewportOffset = const Offset(180, 220);

  @override
  Stream<BellugaMapInteractionEvent> get interactionStream => _events.stream;

  @override
  bool get isReady => _isReady;

  @override
  double? get currentZoom => _currentZoom;

  @override
  CityCoordinate? get currentCenter => _currentCenter;

  @override
  bool moveTo(
    CityCoordinate coordinate, {
    required double zoom,
  }) {
    if (!_isReady) {
      return false;
    }
    if (_treatNoOpMoveAsSuccess && _matchesCurrentCamera(coordinate, zoom)) {
      return true;
    }
    moveCallCount += 1;
    lastMoveCoordinate = coordinate;
    lastMoveZoom = zoom;
    _currentCenter = coordinate;
    _currentZoom = zoom;
    return true;
  }

  @override
  bool moveToAnchored(
    CityCoordinate coordinate, {
    required double zoom,
    required double verticalViewportAnchor,
  }) {
    lastVerticalViewportAnchor = verticalViewportAnchor;
    return moveTo(coordinate, zoom: zoom);
  }

  @override
  bool fitToCoordinates(
    List<CityCoordinate> coordinates, {
    double padding = 32,
    double? maxZoom,
  }) {
    if (coordinates.isEmpty || !_isReady) {
      return false;
    }
    moveCallCount += 1;
    lastMoveCoordinate = coordinates.first;
    lastMoveZoom = maxZoom ?? _currentZoom;
    return true;
  }

  @override
  Offset? projectToViewport(CityCoordinate coordinate) =>
      projectedViewportOffset;

  @override
  void markReady() {
    if (_isReady) {
      return;
    }
    _isReady = true;
    emitInteraction(
      BellugaMapInteractionEvent(
        type: BellugaMapInteractionType.ready,
        zoom: _currentZoom,
      ),
    );
  }

  @override
  void emitInteraction(BellugaMapInteractionEvent event) {
    _currentZoom = event.zoom ?? _currentZoom;
    _events.add(event);
  }

  @override
  void dispose() {
    _events.close();
  }

  void emitReady() {
    _isReady = true;
    _events.add(
      BellugaMapInteractionEvent(
        type: BellugaMapInteractionType.ready,
        zoom: _currentZoom,
      ),
    );
  }

  bool _matchesCurrentCamera(CityCoordinate coordinate, double zoom) {
    final currentCenter = _currentCenter;
    if (currentCenter == null) {
      return false;
    }
    return (currentCenter.latitude - coordinate.latitude).abs() <=
            _cameraCoordinateTolerance &&
        (currentCenter.longitude - coordinate.longitude).abs() <=
            _cameraCoordinateTolerance &&
        ((_currentZoom ?? 0) - zoom).abs() <= _cameraZoomTolerance;
  }
}

CityPoiModel _buildPoi({
  String id = 'poi-1',
  String name = 'Beach Bar',
  String description = 'Nice place',
  String refType = 'static',
  String refId = 'poi-1',
  String? refSlug,
  String? refPath,
  String stackKey = '',
  int stackCount = 1,
  CityPoiCategory category = CityPoiCategory.restaurant,
  String? categoryLabel,
  bool isHappeningNow = false,
  DateTime? timeStart,
  DateTime? timeEnd,
  List<CityPoiModel>? stackItems,
  CityCoordinate? coordinate,
  double? distanceMeters,
  String? coverImageUri,
}) {
  final idValue = CityPoiIdValue()..parse(id);
  final nameValue = CityPoiNameValue()..parse(name);
  final descriptionValue = CityPoiDescriptionValue()..parse(description);
  final addressValue = CityPoiAddressValue()..parse('Av. Brasil');
  final priorityValue = PoiPriorityValue()..parse('1');
  final refTypeValue = PoiReferenceTypeValue()..parse(refType);
  final refIdValue = PoiReferenceIdValue()..parse(refId);
  final refSlugValue =
      refSlug == null ? null : (PoiReferenceSlugValue()..parse(refSlug));
  final refPathValue =
      refPath == null ? null : (PoiReferencePathValue()..parse(refPath));
  final categoryLabelValue =
      categoryLabel == null || categoryLabel.trim().isEmpty
          ? null
          : (PoiTypeLabelValue()..parse(categoryLabel.trim()));
  final stackKeyValue = PoiStackKeyValue()..parse(stackKey);
  final stackCountValue = PoiStackCountValue()..parse(stackCount.toString());
  final stackItemCollection = CityPoiStackItems();
  for (final item in stackItems ?? const <CityPoiModel>[]) {
    stackItemCollection.add(item);
  }
  final resolvedCoordinate = coordinate ??
      CityCoordinate(
        latitudeValue: LatitudeValue()..parse('-20.0'),
        longitudeValue: LongitudeValue()..parse('-40.0'),
      );
  final distanceMetersValue = distanceMeters == null
      ? null
      : (DistanceInMetersValue()..parse(distanceMeters.toString()));
  final isHappeningNowValue = PoiBooleanValue()
    ..parse(isHappeningNow.toString());
  final timeStartValue = timeStart == null
      ? null
      : (PoiTimeStartValue()..parse(timeStart.toUtc().toIso8601String()));
  final timeEndValue = timeEnd == null
      ? null
      : (PoiTimeEndValue()..parse(timeEnd.toUtc().toIso8601String()));
  final coverImageUriValue = coverImageUri == null
      ? null
      : (PoiFilterImageUriValue()..parse(coverImageUri));

  return CityPoiModel(
    idValue: idValue,
    nameValue: nameValue,
    descriptionValue: descriptionValue,
    addressValue: addressValue,
    category: category,
    categoryLabelValue: categoryLabelValue,
    coverImageUriValue: coverImageUriValue,
    coordinate: resolvedCoordinate,
    priorityValue: priorityValue,
    refTypeValue: refTypeValue,
    refIdValue: refIdValue,
    refSlugValue: refSlugValue,
    refPathValue: refPathValue,
    stackKeyValue: stackKeyValue,
    stackCountValue: stackCountValue,
    stackItems: stackItemCollection,
    isHappeningNowValue: isHappeningNowValue,
    timeStartValue: timeStartValue,
    timeEndValue: timeEndValue,
    distanceMetersValue: distanceMetersValue,
  );
}

Future<void> _flushMicrotasks() async {
  await Future<void>.delayed(Duration.zero);
}

CityCoordinate _buildCoordinate(String latitudeRaw, String longitudeRaw) {
  final latitude = LatitudeValue()..parse(latitudeRaw);
  final longitude = LongitudeValue()..parse(longitudeRaw);
  return CityCoordinate(
    latitudeValue: latitude,
    longitudeValue: longitude,
  );
}

PoiQuery _buildQuery({
  Set<String>? categoryKeys,
}) {
  return PoiQuery(
    categoryKeyValues:
        categoryKeys == null ? null : _buildFilterKeyValues(categoryKeys),
  );
}

DistanceInMetersValue _buildDistanceValue(double raw) {
  final value = DistanceInMetersValue();
  value.parse(raw.toString());
  return value;
}

EventModel _buildEventDetailModel({
  required String slug,
  String title = 'Evento Longo',
  String? thumbUrl,
  String? linkedAccountProfileAvatarUrl,
  String? linkedAccountProfileCoverUrl,
}) {
  final dto = EventDTO.fromJson({
    'id': '507f1f77bcf86cd799439099',
    'slug': slug,
    'type': {
      'id': 'type-1',
      'name': 'Feira',
      'slug': 'feira',
      'description': 'Evento',
    },
    'title': title,
    'content': '<p>Evento detalhado</p>',
    'location': 'Carvoeiro',
    'date_time_start': '2026-04-07T18:00:00Z',
    'date_time_end': '2026-04-07T21:00:00Z',
    'thumb': thumbUrl == null
        ? null
        : {
            'type': 'image',
            'data': {'url': thumbUrl},
          },
    'artists': const [],
    'linked_account_profiles': [
      {
        'id': 'artist-1',
        'display_name': 'Ananda Torres',
        'profile_type': 'artist',
        'party_type': 'artist',
        'slug': 'ananda-torres',
        'avatar_url': linkedAccountProfileAvatarUrl,
        'cover_url': linkedAccountProfileCoverUrl,
      },
    ],
  });
  return dto.toDomain();
}

Set<String>? _queryCategoryKeys(PoiQuery? query) {
  return query?.categoryKeyValues
      ?.map((entry) => entry.value.trim().toLowerCase())
      .where((entry) => entry.isNotEmpty)
      .toSet();
}

String? _querySource(PoiQuery? query) {
  final raw = query?.sourceValue?.value.trim().toLowerCase();
  if (raw == null || raw.isEmpty) {
    return null;
  }
  return raw;
}

Set<String>? _queryTypes(PoiQuery? query) {
  return query?.typeValues
      ?.map((entry) => entry.value.trim().toLowerCase())
      .where((entry) => entry.isNotEmpty)
      .toSet();
}

Set<String>? _queryTags(PoiQuery? query) {
  return query?.tagValues
      ?.map((entry) => entry.value.trim().toLowerCase())
      .where((entry) => entry.isNotEmpty)
      .toSet();
}

Set<String>? _queryTaxonomy(PoiQuery? query) {
  return query?.taxonomyTokenValues
      ?.map((entry) => entry.value.trim().toLowerCase())
      .where((entry) => entry.isNotEmpty)
      .toSet();
}

String? _querySearchTerm(PoiQuery? query) {
  final raw = query?.searchTermValue?.value.trim();
  if (raw == null || raw.isEmpty) {
    return null;
  }
  return raw;
}

CityCoordinate? _queryOrigin(PoiQuery? query) => query?.origin;

PoiFilterCategory _buildCategory({
  required String key,
  required String label,
  Set<String> tags = const <String>{},
  String? imageUri,
  bool overrideMarker = false,
  PoiFilterMarkerOverride? markerOverride,
  PoiFilterServerQuery? serverQuery,
}) {
  return PoiFilterCategory(
    keyValue: _buildFilterKeyValue(key),
    labelValue: _buildFilterLabelValue(label),
    countValue: _buildFilterCountValue(tags.length),
    tagValues: _buildTagValues(tags),
    imageUriValue: _buildFilterImageUriValue(imageUri),
    overrideMarkerValue: _buildBooleanValue(overrideMarker),
    markerOverride: markerOverride,
    serverQuery: serverQuery,
  );
}

PoiFilterServerQuery _buildServerQuery({
  String? source,
  Set<String> types = const <String>{},
  Set<String> categoryKeys = const <String>{},
  Set<String> taxonomy = const <String>{},
  Set<String> tags = const <String>{},
}) {
  return PoiFilterServerQuery(
    sourceValue: _buildFilterSourceValue(source),
    typeValues: _buildFilterTypeValues(types),
    categoryKeyValues: _buildFilterKeyValues(categoryKeys),
    taxonomyTokenValues: _buildFilterTaxonomyValues(taxonomy),
    tagValues: _buildTagValues(tags),
  );
}

PoiFilterMarkerOverride _buildIconMarkerOverride({
  required String icon,
  required String colorHex,
  String? iconColorHex,
}) {
  return PoiFilterMarkerOverride.icon(
    iconValue: _buildIconSymbolValue(icon),
    colorHexValue: _buildHexColorValue(colorHex),
    iconColorHexValue:
        iconColorHex == null ? null : _buildHexColorValue(iconColorHex),
  );
}

PoiFilterKeyValue _buildFilterKeyValue(String raw) {
  final value = PoiFilterKeyValue();
  value.parse(raw.trim().toLowerCase());
  return value;
}

PoiFilterLabelValue _buildFilterLabelValue(String raw) {
  final value = PoiFilterLabelValue();
  value.parse(raw.trim());
  return value;
}

PoiFilterCountValue _buildFilterCountValue(int raw) {
  final value = PoiFilterCountValue();
  value.parse(raw.toString());
  return value;
}

PoiFilterImageUriValue? _buildFilterImageUriValue(String? raw) {
  final normalized = raw?.trim();
  if (normalized == null || normalized.isEmpty) {
    return null;
  }
  final value = PoiFilterImageUriValue();
  value.parse(normalized);
  return value;
}

PoiBooleanValue _buildBooleanValue(bool raw) {
  final value = PoiBooleanValue();
  value.parse(raw.toString());
  return value;
}

PoiFilterSourceValue? _buildFilterSourceValue(String? raw) {
  final normalized = raw?.trim().toLowerCase();
  if (normalized == null || normalized.isEmpty) {
    return null;
  }
  final value = PoiFilterSourceValue();
  value.parse(normalized);
  return value;
}

List<PoiFilterTypeValue> _buildFilterTypeValues(Iterable<String> rawValues) {
  final values = <PoiFilterTypeValue>[];
  for (final entry in rawValues) {
    final normalized = entry.trim().toLowerCase();
    if (normalized.isEmpty) {
      continue;
    }
    final value = PoiFilterTypeValue();
    value.parse(normalized);
    values.add(value);
  }
  return List<PoiFilterTypeValue>.unmodifiable(values.toSet().toList());
}

List<PoiFilterKeyValue> _buildFilterKeyValues(Iterable<String> rawValues) {
  final values = <PoiFilterKeyValue>[];
  for (final entry in rawValues) {
    final normalized = entry.trim().toLowerCase();
    if (normalized.isEmpty) {
      continue;
    }
    final value = PoiFilterKeyValue();
    value.parse(normalized);
    values.add(value);
  }
  return List<PoiFilterKeyValue>.unmodifiable(values.toSet().toList());
}

List<PoiFilterTaxonomyTokenValue> _buildFilterTaxonomyValues(
  Iterable<String> rawValues,
) {
  final values = <PoiFilterTaxonomyTokenValue>[];
  for (final entry in rawValues) {
    final normalized = entry.trim().toLowerCase();
    if (normalized.isEmpty) {
      continue;
    }
    final value = PoiFilterTaxonomyTokenValue();
    value.parse(normalized);
    values.add(value);
  }
  return List<PoiFilterTaxonomyTokenValue>.unmodifiable(
    values.toSet().toList(),
  );
}

List<PoiTagValue> _buildTagValues(Iterable<String> rawValues) {
  final values = <PoiTagValue>[];
  for (final entry in rawValues) {
    final normalized = entry.trim().toLowerCase();
    if (normalized.isEmpty) {
      continue;
    }
    final value = PoiTagValue();
    value.parse(normalized);
    values.add(value);
  }
  return List<PoiTagValue>.unmodifiable(values.toSet().toList());
}

PoiIconSymbolValue _buildIconSymbolValue(String raw) {
  final value = PoiIconSymbolValue();
  value.parse(raw.trim());
  return value;
}

PoiHexColorValue _buildHexColorValue(String raw) {
  final value = PoiHexColorValue();
  value.parse(raw.trim());
  return value;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() {
    HttpOverrides.global = _TestHttpOverrides();
  });

  group('MapScreenController telemetry', () {
    late _FakeTelemetryRepository telemetry;
    late _FakeCityMapRepository mapRepository;
    late _FakeUserLocationRepository userLocationRepository;
    late _FakeAccountProfilesRepository accountProfilesRepository;
    late _FakeStaticAssetsRepository staticAssetsRepository;
    late MapScreenController controller;

    setUp(() {
      LocationPermissionGateRuntime.resetForTesting();
      telemetry = _FakeTelemetryRepository();
      mapRepository = _FakeCityMapRepository();
      userLocationRepository = _FakeUserLocationRepository();
      accountProfilesRepository = _FakeAccountProfilesRepository();
      staticAssetsRepository = _FakeStaticAssetsRepository();
      final poiRepository = _buildPoiRepository(
        mapRepository: mapRepository,
        accountProfilesRepository: accountProfilesRepository,
        staticAssetsRepository: staticAssetsRepository,
      );
      controller = _buildMapController(
        poiRepository: poiRepository,
        userLocationRepository: userLocationRepository,
        telemetryRepository: telemetry,
        appData: _buildAppData(),
      );
    });

    tearDown(() {
      LocationPermissionGateRuntime.resetForTesting();
      mapRepository.dispose();
      userLocationRepository.dispose();
      controller.onDispose();
    });

    test('logs poi_opened when selecting a poi', () async {
      final poi = _buildPoi(id: 'poi-123');

      controller.selectPoi(poi);
      await _flushMicrotasks();
      controller.clearSelectedPoi();
      await _flushMicrotasks();

      expect(telemetry.events, hasLength(1));
      final event = telemetry.events.first;
      expect(event.event, EventTrackerEvents.poiOpened);
      expect(event.eventName, 'poi_opened');
      expect(event.properties?['poi_id'], 'poi-123');
    });

    test('keeps last selected poi memory when closing the card explicitly',
        () async {
      final poi = _buildPoi(id: 'poi-memory');

      controller.selectPoi(poi);
      await _flushMicrotasks();
      controller.clearSelectedPoi();

      expect(controller.selectedPoiStreamValue.value, isNull);
      expect(
        controller.lastSelectedPoiMemoryStreamValue.value?.poiId,
        'poi-memory',
      );
    });

    test('clears selected poi memory after user pan interaction', () async {
      final fakeMapHandle = _FakeMapHandle();
      final localController = _buildMapController(
        poiRepository: _buildPoiRepository(
          mapRepository: mapRepository,
        ),
        userLocationRepository: userLocationRepository,
        telemetryRepository: telemetry,
        mapHandle: fakeMapHandle,
        appData: _buildAppData(),
      );
      addTearDown(() async {
        await localController.onDispose();
      });

      await localController.init();
      final poi = _buildPoi(id: 'poi-pan');
      localController.selectPoi(poi);
      await _flushMicrotasks();

      fakeMapHandle.emitInteraction(
        const BellugaMapInteractionEvent(
          type: BellugaMapInteractionType.pan,
          zoom: 16,
          userGesture: true,
        ),
      );
      await _flushMicrotasks();

      expect(localController.selectedPoiStreamValue.value, isNull);
      expect(localController.lastSelectedPoiMemoryStreamValue.value, isNull);
    });

    test('empty tap on map collapses search tray back to discovery', () async {
      final fakeMapHandle = _FakeMapHandle();
      final localController = _buildMapController(
        poiRepository: _buildPoiRepository(
          mapRepository: mapRepository,
        ),
        userLocationRepository: userLocationRepository,
        telemetryRepository: telemetry,
        mapHandle: fakeMapHandle,
        appData: _buildAppData(),
      );
      addTearDown(() async {
        await localController.onDispose();
      });

      await localController.init();
      localController.showSearchTray();
      await _flushMicrotasks();

      fakeMapHandle.emitInteraction(
        const BellugaMapInteractionEvent(
          type: BellugaMapInteractionType.emptyTap,
          userGesture: true,
        ),
      );
      await _flushMicrotasks();

      expect(
          localController.mapTrayModeStreamValue.value, MapTrayMode.discovery);
    });

    test('pan gesture on map collapses expanded filters back to discovery',
        () async {
      final fakeMapHandle = _FakeMapHandle();
      final localController = _buildMapController(
        poiRepository: _buildPoiRepository(
          mapRepository: mapRepository,
        ),
        userLocationRepository: userLocationRepository,
        telemetryRepository: telemetry,
        mapHandle: fakeMapHandle,
        appData: _buildAppData(),
      );
      addTearDown(() async {
        await localController.onDispose();
      });

      await localController.init();
      localController.showFiltersTray();
      await _flushMicrotasks();

      fakeMapHandle.emitInteraction(
        const BellugaMapInteractionEvent(
          type: BellugaMapInteractionType.pan,
          zoom: 16,
          userGesture: true,
        ),
      );
      await _flushMicrotasks();

      expect(
          localController.mapTrayModeStreamValue.value, MapTrayMode.discovery);
    });

    test('logs search submit and clear events', () async {
      await controller.searchPois('pizza');
      await _flushMicrotasks();

      await controller.clearSearch();
      await _flushMicrotasks();

      expect(telemetry.events, hasLength(2));
      expect(telemetry.events[0].eventName, 'map_search_submitted');
      expect(telemetry.events[0].event, EventTrackerEvents.search);
      expect(telemetry.events[0].properties?['query_len'], 5);
      expect(telemetry.events[1].eventName, 'map_search_cleared');
      expect(telemetry.events[1].event, EventTrackerEvents.buttonClick);
      expect(telemetry.events[1].properties?['previous_query_len'], 5);
    });

    test('typing search text debounces requests and uses the latest term',
        () async {
      controller.handleSearchInputChanged('pi');
      await Future<void>.delayed(const Duration(milliseconds: 120));
      controller.handleSearchInputChanged('pizza');
      await Future<void>.delayed(const Duration(milliseconds: 320));
      await _flushMicrotasks();

      expect(mapRepository.fetchPointsCallCount, 1);
      expect(_querySearchTerm(mapRepository.lastQuery), 'pizza');
      expect(telemetry.events, isEmpty);
    });

    test('clearing typed search restores nearby suggestions payload', () async {
      final searchResults = <CityPoiModel>[
        _buildPoi(id: 'poi-search', name: 'Pizza do Porto'),
      ];
      final nearbyResults = <CityPoiModel>[
        _buildPoi(id: 'poi-near', name: 'Palco Praia do Morro'),
      ];
      final searchRequest = Completer<List<CityPoiModel>>();
      final clearRequest = Completer<List<CityPoiModel>>();
      mapRepository.queuedFetchCompleters
        ..add(searchRequest)
        ..add(clearRequest);

      controller.handleSearchInputChanged('pizza');
      await Future<void>.delayed(const Duration(milliseconds: 320));
      await _flushMicrotasks();
      searchRequest.complete(searchResults);
      await _flushMicrotasks();

      expect(_querySearchTerm(mapRepository.lastQuery), 'pizza');
      expect(
        controller.filteredPoisStreamValue.value?.map((poi) => poi.id),
        equals(<String>['poi-search']),
      );

      controller.handleSearchInputChanged('');
      await Future<void>.delayed(const Duration(milliseconds: 320));
      await _flushMicrotasks();
      clearRequest.complete(nearbyResults);
      await _flushMicrotasks();

      expect(_querySearchTerm(mapRepository.lastQuery), isNull);
      expect(controller.searchTermStreamValue.value, anyOf(isNull, ''));
      expect(
        controller.filteredPoisStreamValue.value?.map((poi) => poi.id),
        equals(<String>['poi-near']),
      );
      expect(telemetry.events, isEmpty);
    });

    test('search tray captures current map center and preserves it on clear',
        () async {
      final fakeMapHandle = _FakeMapHandle(
        initialCenter: _buildCoordinate('-20.673100', '-40.495200'),
      );
      final localMapRepository = _FakeCityMapRepository();
      final localController = _buildMapController(
        poiRepository: _buildPoiRepository(mapRepository: localMapRepository),
        userLocationRepository: userLocationRepository,
        telemetryRepository: telemetry,
        mapHandle: fakeMapHandle,
        appData: _buildAppData(),
      );
      addTearDown(() async {
        localMapRepository.dispose();
        await localController.onDispose();
      });

      localController.showSearchTray();
      await _flushMicrotasks();

      final trayOrigin = _queryOrigin(localMapRepository.lastQuery);
      expect(trayOrigin, isNotNull);
      expect(trayOrigin!.latitude, closeTo(-20.6731, 0.000001));
      expect(trayOrigin.longitude, closeTo(-40.4952, 0.000001));
      expect(localController.mapTrayModeStreamValue.value, MapTrayMode.search);

      await localController.searchPois('pizza');
      await _flushMicrotasks();
      expect(_querySearchTerm(localMapRepository.lastQuery), 'pizza');
      expect(
        _queryOrigin(localMapRepository.lastQuery)?.latitude,
        closeTo(-20.6731, 0.000001),
      );

      await localController.clearSearch(logTelemetry: false);
      await _flushMicrotasks();

      expect(_querySearchTerm(localMapRepository.lastQuery), isNull);
      expect(
        _queryOrigin(localMapRepository.lastQuery)?.latitude,
        closeTo(-20.6731, 0.000001),
      );
      expect(
        _queryOrigin(localMapRepository.lastQuery)?.longitude,
        closeTo(-40.4952, 0.000001),
      );
    });

    test('logs filter apply and clear events', () async {
      controller.applyFilterMode(PoiFilterMode.events);
      await _flushMicrotasks();

      controller.clearFilters();
      await _flushMicrotasks();

      expect(telemetry.events, hasLength(2));
      expect(telemetry.events[0].eventName, 'map_filter_applied');
      expect(telemetry.events[0].event, EventTrackerEvents.selectItem);
      expect(telemetry.events[0].properties?['filter_mode'], 'events');
      expect(telemetry.events[1].eventName, 'map_filter_cleared');
      expect(telemetry.events[1].event, EventTrackerEvents.buttonClick);
    });

    test('catalog filter apply does not emit global loading status message',
        () async {
      final firstRequest = Completer<List<CityPoiModel>>();
      mapRepository.queuedFetchCompleters.add(firstRequest);
      final statusMessages = <String?>[];
      final subscription =
          controller.statusMessageStreamValue.stream.listen(statusMessages.add);

      controller.toggleCatalogCategoryFilter(
        _buildCategory(
          key: 'event',
          label: 'Eventos',
          serverQuery: _buildServerQuery(source: 'event'),
        ),
      );
      await _flushMicrotasks();

      expect(controller.filterInteractionLockedStreamValue.value, isTrue);
      expect(statusMessages, isNot(contains('Aplicando filtros...')));
      expect(controller.statusMessageStreamValue.value, isNull);

      firstRequest.complete(<CityPoiModel>[]);
      await _flushMicrotasks();
      await _flushMicrotasks();
      await subscription.cancel();
    });

    test('catalog filter apply opens filter results tray', () async {
      controller.toggleCatalogCategoryFilter(
        _buildCategory(
          key: 'beach',
          label: 'Praia',
        ),
      );
      await _flushMicrotasks();

      expect(
        controller.mapTrayModeStreamValue.value,
        MapTrayMode.filterResults,
      );
    });

    test('filter clear keeps pending chip label without global loading message',
        () async {
      controller.toggleCatalogCategoryFilter(
        _buildCategory(
          key: 'restaurant',
          label: 'Restaurantes',
        ),
      );
      await _flushMicrotasks();

      final firstRequest = Completer<List<CityPoiModel>>();
      mapRepository.queuedFetchCompleters.add(firstRequest);
      final statusMessages = <String?>[];
      final subscription =
          controller.statusMessageStreamValue.stream.listen(statusMessages.add);

      controller.clearFilters();
      await _flushMicrotasks();

      expect(controller.filterInteractionLockedStreamValue.value, isTrue);
      expect(controller.activeFilterLabelStreamValue.value, isNull);
      expect(controller.pendingFilterLabelStreamValue.value, 'Restaurantes');
      expect(statusMessages, isNot(contains('Carregando pontos...')));
      expect(controller.statusMessageStreamValue.value, isNull);

      firstRequest.complete(<CityPoiModel>[]);
      await _flushMicrotasks();
      await _flushMicrotasks();

      expect(controller.pendingFilterLabelStreamValue.value, isNull);
      await subscription.cancel();
    });

    test('applies dynamic category filters using category keys', () async {
      controller.toggleCatalogCategoryFilter(
        _buildCategory(
          key: 'nature',
          label: 'Natureza',
          tags: const {},
        ),
      );
      await _flushMicrotasks();

      expect(mapRepository.lastQuery, isNotNull);
      expect(_queryCategoryKeys(mapRepository.lastQuery), equals({'nature'}));
      expect(controller.filterModeStreamValue.value, PoiFilterMode.server);
    });

    test(
      'catalog filter focuses the first dock result by distance without auto-selecting a poi',
      () async {
        final fakeMapHandle = _FakeMapHandle(
          initialZoom: 15.2,
          initialCenter: _buildPoi(id: 'seed').coordinate,
        );
        final localController = _buildMapController(
          poiRepository: _buildPoiRepository(mapRepository: mapRepository),
          userLocationRepository: userLocationRepository,
          telemetryRepository: telemetry,
          mapHandle: fakeMapHandle,
          appData: _buildAppData(),
        );
        addTearDown(() async {
          await localController.onDispose();
          fakeMapHandle.dispose();
        });

        mapRepository.nextPois = <CityPoiModel>[
          _buildPoi(
            id: 'poi-far',
            name: 'Mais longe',
            coordinate: _buildCoordinate('-20.500000', '-40.500000'),
            distanceMeters: 900,
          ),
          _buildPoi(
            id: 'poi-near',
            name: 'Mais perto',
            coordinate: _buildCoordinate('-20.100000', '-40.100000'),
            distanceMeters: 120,
          ),
        ];

        localController.toggleCatalogCategoryFilter(
          _buildCategory(
            key: 'nature',
            label: 'Natureza',
            tags: const {},
          ),
        );
        await _flushMicrotasks();
        await _flushMicrotasks();

        expect(localController.selectedPoiStreamValue.value, isNull);
        expect(fakeMapHandle.moveCallCount, 1);
        expect(fakeMapHandle.lastMoveCoordinate, isNotNull);
        expect(
          fakeMapHandle.lastMoveCoordinate!.latitude,
          closeTo(-20.1, 1e-9),
        );
        expect(
          fakeMapHandle.lastVerticalViewportAnchor,
          closeTo(0.40, 1e-9),
        );
      },
    );

    test(
      'event catalog filter focuses the next upcoming event before nearer later events',
      () async {
        final reference = DateTime.now().toUtc();
        final fakeMapHandle = _FakeMapHandle(
          initialZoom: 15.2,
          initialCenter: _buildPoi(id: 'seed').coordinate,
        );
        final localController = _buildMapController(
          poiRepository: _buildPoiRepository(mapRepository: mapRepository),
          userLocationRepository: userLocationRepository,
          telemetryRepository: telemetry,
          mapHandle: fakeMapHandle,
          appData: _buildAppData(),
        );
        addTearDown(() async {
          await localController.onDispose();
          fakeMapHandle.dispose();
        });

        mapRepository.nextPois = <CityPoiModel>[
          _buildPoi(
            id: 'poi-later-near',
            name: 'Mais perto depois',
            refType: 'event',
            refId: 'event-2',
            refSlug: 'mais-perto-depois',
            coordinate: _buildCoordinate('-20.100000', '-40.100000'),
            distanceMeters: 120,
            timeStart: reference.add(const Duration(hours: 6)),
          ),
          _buildPoi(
            id: 'poi-soon-far',
            name: 'Mais longe antes',
            refType: 'event',
            refId: 'event-1',
            refSlug: 'mais-longe-antes',
            coordinate: _buildCoordinate('-20.500000', '-40.500000'),
            distanceMeters: 900,
            timeStart: reference.add(const Duration(hours: 2)),
          ),
          _buildPoi(
            id: 'poi-past-nearest',
            name: 'Já terminou',
            refType: 'event',
            refId: 'event-3',
            refSlug: 'ja-terminou',
            coordinate: _buildCoordinate('-20.050000', '-40.050000'),
            distanceMeters: 30,
            timeStart: reference.subtract(const Duration(hours: 5)),
          ),
        ];

        localController.toggleCatalogCategoryFilter(
          _buildCategory(
            key: 'event',
            label: 'Eventos',
            tags: const {},
          ),
        );
        await _flushMicrotasks();
        await _flushMicrotasks();

        expect(
          localController.mapTrayModeStreamValue.value,
          MapTrayMode.filterResults,
        );
        expect(localController.selectedPoiStreamValue.value, isNull);
        expect(fakeMapHandle.moveCallCount, 1);
        expect(fakeMapHandle.lastMoveCoordinate, isNotNull);
        expect(
          fakeMapHandle.lastMoveCoordinate!.latitude,
          closeTo(-20.5, 1e-9),
        );

        final filteredPois = localController.filteredPoisStreamValue.value!;
        final selectedLaterPoi = filteredPois.firstWhere(
          (poi) => poi.id == 'poi-later-near',
        );
        final deckPois = localController.deckPoisForSelectedPoi(
          selectedLaterPoi,
        );

        expect(
          deckPois.map((poi) => poi.id).toList(growable: false),
          equals(<String>[
            'poi-soon-far',
            'poi-later-near',
            'poi-past-nearest',
          ]),
        );
      },
    );

    test(
      'orderedFilterResultPois keeps happening-now and upcoming events ahead of past ones',
      () async {
        final reference = DateTime.now().toUtc();
        controller.activeCatalogFilterKeyStreamValue.addValue('event');

        final ordered = controller.orderedFilterResultPois(
          <CityPoiModel>[
            _buildPoi(
              id: 'poi-past',
              name: 'Evento passado',
              refType: 'event',
              refId: 'event-past',
              distanceMeters: 10,
              timeStart: reference.subtract(const Duration(hours: 5)),
            ),
            _buildPoi(
              id: 'poi-upcoming',
              name: 'Evento futuro',
              refType: 'event',
              refId: 'event-upcoming',
              distanceMeters: 900,
              timeStart: reference.add(const Duration(hours: 3)),
            ),
            _buildPoi(
              id: 'poi-now',
              name: 'Evento agora',
              refType: 'event',
              refId: 'event-now',
              isHappeningNow: true,
              distanceMeters: 400,
              timeStart: reference.subtract(const Duration(minutes: 30)),
              timeEnd: reference.add(const Duration(minutes: 30)),
            ),
          ],
        );

        expect(ordered.map((poi) => poi.id).toList(), <String>[
          'poi-now',
          'poi-upcoming',
          'poi-past',
        ]);
      },
    );

    test(
      'orderedFilterResultPois also treats plural events filter keys as event context',
      () async {
        final reference = DateTime.now().toUtc();
        controller.activeCatalogFilterKeyStreamValue.addValue('events');

        final ordered = controller.orderedFilterResultPois(
          <CityPoiModel>[
            _buildPoi(
              id: 'poi-past',
              name: 'Evento passado',
              refType: 'event',
              refId: 'event-past',
              distanceMeters: 10,
              timeStart: reference.subtract(const Duration(hours: 5)),
            ),
            _buildPoi(
              id: 'poi-upcoming',
              name: 'Evento futuro',
              refType: 'event',
              refId: 'event-upcoming',
              distanceMeters: 900,
              timeStart: reference.add(const Duration(hours: 3)),
            ),
          ],
        );

        expect(ordered.map((poi) => poi.id).toList(), <String>[
          'poi-upcoming',
          'poi-past',
        ]);
      },
    );

    test('tapping the same active catalog filter reopens filter results tray',
        () async {
      final category = _buildCategory(
        key: 'events',
        label: 'Eventos',
      );

      controller.toggleCatalogCategoryFilter(category);
      await _flushMicrotasks();
      await _flushMicrotasks();

      expect(
          controller.mapTrayModeStreamValue.value, MapTrayMode.filterResults);

      controller.showDiscoveryTray();
      await _flushMicrotasks();

      expect(controller.mapTrayModeStreamValue.value, MapTrayMode.discovery);
      expect(controller.activeFilterLabelStreamValue.value, 'Eventos');

      controller.toggleCatalogCategoryFilter(category);
      await _flushMicrotasks();

      expect(
          controller.mapTrayModeStreamValue.value, MapTrayMode.filterResults);
      expect(controller.activeFilterLabelStreamValue.value, 'Eventos');
    });

    test('applies catalog filter query metadata when available', () async {
      controller.toggleCatalogCategoryFilter(
        _buildCategory(
          key: 'event',
          label: 'Eventos agora',
          tags: const {},
          serverQuery: _buildServerQuery(
            source: 'event',
            types: {'show'},
            categoryKeys: {'culture'},
            taxonomy: {'music_genre:rock'},
            tags: {'live'},
          ),
        ),
      );
      await _flushMicrotasks();

      expect(mapRepository.lastQuery, isNotNull);
      expect(_querySource(mapRepository.lastQuery), equals('event'));
      expect(_queryTypes(mapRepository.lastQuery), equals({'show'}));
      expect(_queryCategoryKeys(mapRepository.lastQuery), equals({'culture'}));
      expect(_queryTags(mapRepository.lastQuery), equals({'live'}));
      expect(
        _queryTaxonomy(mapRepository.lastQuery),
        equals({'music_genre:rock'}),
      );
      expect(controller.filterModeStreamValue.value, PoiFilterMode.server);
    });

    test(
      'supports source/types query metadata without category key fallback',
      () async {
        controller.toggleCatalogCategoryFilter(
          _buildCategory(
            key: 'artists',
            label: 'Artistas',
            tags: const {},
            serverQuery: _buildServerQuery(
              source: 'account_profile',
              types: {'artist'},
              taxonomy: {'music_genre:jazz'},
              tags: {'live'},
            ),
          ),
        );
        await _flushMicrotasks();

        expect(mapRepository.lastQuery, isNotNull);
        expect(_queryCategoryKeys(mapRepository.lastQuery), isNull);
        expect(
            _querySource(mapRepository.lastQuery), equals('account_profile'));
        expect(_queryTypes(mapRepository.lastQuery), equals({'artist'}));
        expect(_queryTags(mapRepository.lastQuery), equals({'live'}));
        expect(_queryTaxonomy(mapRepository.lastQuery),
            equals({'music_genre:jazz'}));
      },
    );

    test('keeps stale map data visible when loadPois fails', () async {
      mapRepository.nextPois = <CityPoiModel>[
        _buildPoi(id: 'poi-a'),
      ];
      await controller.loadPois(PoiQuery());
      expect(
        controller.filteredPoisStreamValue.value ?? const <CityPoiModel>[],
        hasLength(1),
      );

      controller.selectPoi(_buildPoi(id: 'poi-a'));
      expect(controller.selectedPoiStreamValue.value, isNotNull);

      mapRepository.throwOnFetchPoints = true;
      await controller.loadPois(
        _buildQuery(categoryKeys: {'event'}),
        loadingMessage: 'Aplicando filtros...',
      );

      expect(
        controller.filteredPoisStreamValue.value ?? const <CityPoiModel>[],
        hasLength(1),
      );
      expect(controller.selectedPoiStreamValue.value?.id, 'poi-a');
      expect(
        controller.errorMessage.value,
        'Nao foi possivel carregar os pontos de interesse.',
      );
    });

    test('locks filter interactions while a filter reload is in flight',
        () async {
      final firstRequest = Completer<List<CityPoiModel>>();
      mapRepository.queuedFetchCompleters.add(firstRequest);

      controller.toggleCatalogCategoryFilter(
        _buildCategory(
          key: 'events',
          label: 'Eventos',
          tags: const {},
          serverQuery: _buildServerQuery(
            source: 'event',
          ),
        ),
      );
      await _flushMicrotasks();

      controller.toggleCatalogCategoryFilter(
        _buildCategory(
          key: 'beach',
          label: 'Praias',
          tags: const {},
          serverQuery: _buildServerQuery(
            source: 'static_asset',
            types: {'beach_spot'},
          ),
        ),
      );
      await _flushMicrotasks();

      expect(mapRepository.fetchPointsCallCount, 1);
      expect(
        controller.filterInteractionLockedStreamValue.value,
        isTrue,
      );

      firstRequest.complete(<CityPoiModel>[]);
      await _flushMicrotasks();
      await _flushMicrotasks();

      expect(
        controller.filterInteractionLockedStreamValue.value,
        isFalse,
      );

      controller.toggleCatalogCategoryFilter(
        _buildCategory(
          key: 'beach',
          label: 'Praias',
          tags: const {},
          serverQuery: _buildServerQuery(
            source: 'static_asset',
            types: {'beach_spot'},
          ),
        ),
      );
      await _flushMicrotasks();

      expect(mapRepository.fetchPointsCallCount, 2);
    });

    test('ignores marker taps while a filter reload is in flight', () async {
      final fakeMapHandle = _FakeMapHandle();
      final localController = _buildMapController(
        poiRepository: _buildPoiRepository(
          mapRepository: mapRepository,
        ),
        userLocationRepository: userLocationRepository,
        telemetryRepository: telemetry,
        mapHandle: fakeMapHandle,
        appData: _buildAppData(),
      );
      addTearDown(() async {
        await localController.onDispose();
        fakeMapHandle.dispose();
      });

      final pendingFetch = Completer<List<CityPoiModel>>();
      mapRepository.queuedFetchCompleters.add(pendingFetch);

      localController.toggleCatalogCategoryFilter(
        _buildCategory(
          key: 'events',
          label: 'Eventos',
          tags: const {},
          serverQuery: _buildServerQuery(source: 'event'),
        ),
      );
      await _flushMicrotasks();

      await localController.handleMarkerTap(_buildPoi(id: 'poi-ignored'));
      await _flushMicrotasks();

      expect(localController.selectedPoiStreamValue.value, isNull);
      expect(fakeMapHandle.moveCallCount, 0);

      pendingFetch.complete(<CityPoiModel>[]);
      await _flushMicrotasks();
      await _flushMicrotasks();
    });

    test('ignores marker taps immediately after a filter reload settles',
        () async {
      final fakeMapHandle = _FakeMapHandle();
      final localController = _buildMapController(
        poiRepository: _buildPoiRepository(
          mapRepository: mapRepository,
        ),
        userLocationRepository: userLocationRepository,
        telemetryRepository: telemetry,
        mapHandle: fakeMapHandle,
        appData: _buildAppData(),
      );
      addTearDown(() async {
        await localController.onDispose();
        fakeMapHandle.dispose();
      });

      await localController.init();
      await _flushMicrotasks();

      mapRepository.nextPois = <CityPoiModel>[
        _buildPoi(id: 'filtered-first'),
      ];

      localController.toggleCatalogCategoryFilter(
        _buildCategory(
          key: 'events',
          label: 'Eventos',
          tags: const {},
          serverQuery: _buildServerQuery(source: 'event'),
        ),
      );
      await _flushMicrotasks();
      await _flushMicrotasks();

      final focusMovesAfterFilter = fakeMapHandle.moveCallCount;
      await localController.handleMarkerTap(_buildPoi(id: 'poi-ignored'));
      await _flushMicrotasks();

      expect(localController.selectedPoiStreamValue.value, isNull);
      expect(fakeMapHandle.moveCallCount, focusMovesAfterFilter);
    });

    test('accepts marker taps after post-filter suppression window expires',
        () async {
      final fakeMapHandle = _FakeMapHandle();
      final localController = _buildMapController(
        poiRepository: _buildPoiRepository(
          mapRepository: mapRepository,
        ),
        userLocationRepository: userLocationRepository,
        telemetryRepository: telemetry,
        mapHandle: fakeMapHandle,
        appData: _buildAppData(),
      );
      addTearDown(() async {
        await localController.onDispose();
        fakeMapHandle.dispose();
      });

      mapRepository.nextPois = <CityPoiModel>[
        _buildPoi(id: 'filtered-first'),
      ];

      localController.toggleCatalogCategoryFilter(
        _buildCategory(
          key: 'events',
          label: 'Eventos',
          tags: const {},
          serverQuery: _buildServerQuery(source: 'event'),
        ),
      );
      await _flushMicrotasks();
      await _flushMicrotasks();
      await Future<void>.delayed(const Duration(milliseconds: 1100));

      await localController.handleMarkerTap(_buildPoi(id: 'poi-allowed'));
      await _flushMicrotasks();

      expect(localController.selectedPoiStreamValue.value?.id, 'poi-allowed');
      expect(fakeMapHandle.moveCallCount, greaterThanOrEqualTo(2));
    });

    test(
        'marker tap keeps card closed until account profile hydration completes and keeps avatar cover scoped to selection',
        () async {
      final fakeMapHandle = _FakeMapHandle();
      final localAccountProfilesRepository = _FakeAccountProfilesRepository();
      final localController = _buildMapController(
        poiRepository: _buildPoiRepository(
          mapRepository: mapRepository,
          accountProfilesRepository: localAccountProfilesRepository,
        ),
        userLocationRepository: userLocationRepository,
        telemetryRepository: telemetry,
        mapHandle: fakeMapHandle,
        appData: _buildAppData(),
      );
      addTearDown(() async {
        await localController.onDispose();
        fakeMapHandle.dispose();
      });

      mapRepository.nextPois = <CityPoiModel>[
        _buildPoi(
          id: 'poi-partner',
          name: 'Casa Marracini',
          refType: 'account_profile',
          refId: '507f1f77bcf86cd799439011',
          refSlug: 'casa-marracini',
          refPath: '/parceiro/casa-marracini',
          category: CityPoiCategory.restaurant,
        ),
      ];
      await localController.loadPois(PoiQuery());
      final poi = localController.filteredPoisStreamValue.value!.single;

      final hydration = Completer<AccountProfileModel?>();
      localAccountProfilesRepository.pendingBySlug['casa-marracini'] =
          hydration;

      final tapFuture = localController.handleMarkerTap(poi);
      await _flushMicrotasks();

      expect(localController.selectedPoiLoadingIdStreamValue.value, poi.id);
      expect(localController.selectedPoiStreamValue.value, isNull);
      expect(
          localAccountProfilesRepository.getAccountProfileBySlugCallCount, 1);

      hydration.complete(
        buildAccountProfileModelFromPrimitives(
          id: '507f1f77bcf86cd799439011',
          name: 'Casa Marracini',
          slug: 'casa-marracini',
          type: 'restaurant',
          avatarUrl: 'https://tenant.test/media/casa-avatar.png',
          coverUrl: 'https://tenant.test/media/casa-cover.png',
          bio: 'Cozinha autoral perto do mar.',
          locationAddress: 'Rua da Praia, 10',
        ),
      );

      await tapFuture;
      await _flushMicrotasks();

      final selected = localController.selectedPoiStreamValue.value;
      expect(localController.selectedPoiLoadingIdStreamValue.value, isNull);
      expect(selected?.id, 'poi-partner');
      expect(selected?.visual?.isImage, isTrue);
      expect(
        selected?.visual?.imageUri,
        'https://tenant.test/media/casa-avatar.png',
      );
      expect(
        selected?.coverImageUri,
        'https://tenant.test/media/casa-cover.png',
      );
      expect(selected?.description, 'Cozinha autoral perto do mar.');
      expect(selected?.address, 'Av. Brasil');
      expect(
        localController.filteredPoisStreamValue.value?.single.visual?.imageUri,
        isNull,
      );
      expect(
        localController.filteredPoisStreamValue.value?.single.coverImageUri,
        isNull,
      );
      expect(
        localController
            .lastSelectedPoiMemoryStreamValue.value?.visual?.imageUri,
        'https://tenant.test/media/casa-avatar.png',
      );
      expect(fakeMapHandle.moveCallCount, greaterThanOrEqualTo(2));
    });

    test('duplicate tap on the same poi while hydrating is dropped', () async {
      final localAccountProfilesRepository = _FakeAccountProfilesRepository();
      final fakeMapHandle = _FakeMapHandle();
      final localController = _buildMapController(
        poiRepository: _buildPoiRepository(
          mapRepository: mapRepository,
          accountProfilesRepository: localAccountProfilesRepository,
        ),
        userLocationRepository: userLocationRepository,
        telemetryRepository: telemetry,
        mapHandle: fakeMapHandle,
        appData: _buildAppData(),
      );
      addTearDown(() async {
        await localController.onDispose();
        fakeMapHandle.dispose();
      });

      mapRepository.nextPois = <CityPoiModel>[
        _buildPoi(
          id: 'poi-partner',
          refType: 'account_profile',
          refId: '507f1f77bcf86cd799439011',
          refSlug: 'casa-marracini',
          refPath: '/parceiro/casa-marracini',
        ),
      ];
      await localController.loadPois(PoiQuery());
      final poi = localController.filteredPoisStreamValue.value!.single;

      final hydration = Completer<AccountProfileModel?>();
      localAccountProfilesRepository.pendingBySlug['casa-marracini'] =
          hydration;

      final firstTap = localController.handleMarkerTap(poi);
      await _flushMicrotasks();
      final secondTap = localController.handleMarkerTap(poi);
      await _flushMicrotasks();

      expect(
          localAccountProfilesRepository.getAccountProfileBySlugCallCount, 1);
      expect(localController.selectedPoiLoadingIdStreamValue.value, poi.id);

      hydration.complete(
        buildAccountProfileModelFromPrimitives(
          id: '507f1f77bcf86cd799439011',
          name: 'Casa Marracini',
          slug: 'casa-marracini',
          type: 'restaurant',
        ),
      );

      await Future.wait<void>([firstTap, secondTap]);
      await _flushMicrotasks();
      expect(localController.selectedPoiStreamValue.value?.id, poi.id);
    });

    test('cluster marker tap opens picker dock instead of detailed card',
        () async {
      final fakeMapHandle = _FakeMapHandle();
      final localController = _buildMapController(
        poiRepository: _buildPoiRepository(
          mapRepository: mapRepository,
        ),
        userLocationRepository: userLocationRepository,
        telemetryRepository: telemetry,
        mapHandle: fakeMapHandle,
        appData: _buildAppData(),
      );
      addTearDown(() async {
        await localController.onDispose();
        fakeMapHandle.dispose();
      });

      mapRepository.nextPois = <CityPoiModel>[
        _buildPoi(
          id: 'poi-stack-top',
          name: 'Cluster Top',
          stackKey: 'stack-cluster',
          stackCount: 4,
        ),
      ];
      mapRepository.nextStackItems = <CityPoiModel>[
        _buildPoi(
          id: 'poi-stack-a',
          name: 'Cluster A',
          stackKey: 'stack-cluster',
          stackCount: 4,
        ),
        _buildPoi(
          id: 'poi-stack-b',
          name: 'Cluster B',
          stackKey: 'stack-cluster',
          stackCount: 4,
        ),
      ];
      await localController.loadPois(PoiQuery());

      await localController.handleMarkerTap(
        localController.filteredPoisStreamValue.value!.single,
      );
      await _flushMicrotasks();

      expect(localController.selectedPoiStreamValue.value, isNull);
      expect(localController.selectedPoiLoadingIdStreamValue.value, isNull);
      expect(localController.hasClusterPickerStreamValue.value, isTrue);
      expect(
        localController.clusterPickerPoisStreamValue.value
            ?.map((poi) => poi.id)
            .toList(growable: false),
        ['poi-stack-a', 'poi-stack-b'],
      );
      expect(fakeMapHandle.lastVerticalViewportAnchor, 0.40);
    });

    test('cluster picker selection hydrates chosen poi like direct selection',
        () async {
      final localAccountProfilesRepository = _FakeAccountProfilesRepository();
      final fakeMapHandle = _FakeMapHandle();
      final localController = _buildMapController(
        poiRepository: _buildPoiRepository(
          mapRepository: mapRepository,
          accountProfilesRepository: localAccountProfilesRepository,
        ),
        userLocationRepository: userLocationRepository,
        telemetryRepository: telemetry,
        mapHandle: fakeMapHandle,
        appData: _buildAppData(),
      );
      addTearDown(() async {
        await localController.onDispose();
        fakeMapHandle.dispose();
      });

      final poiA = _buildPoi(
        id: 'poi-stack-a',
        name: 'Casa A',
        refType: 'account_profile',
        refId: 'profile-a',
        refSlug: 'casa-a',
        refPath: '/parceiro/casa-a',
        stackKey: 'stack-cluster',
        stackCount: 2,
      );
      final poiB = _buildPoi(
        id: 'poi-stack-b',
        name: 'Casa B',
        refType: 'account_profile',
        refId: 'profile-b',
        refSlug: 'casa-b',
        refPath: '/parceiro/casa-b',
        stackKey: 'stack-cluster',
        stackCount: 2,
      );

      localController.showClusterPicker(
        <CityPoiModel>[poiA, poiB],
        anchorCoordinate: poiA.coordinate,
      );
      final hydration = Completer<AccountProfileModel?>();
      localAccountProfilesRepository.pendingBySlug['casa-b'] = hydration;

      final selectionFuture = localController.handleClusterPickerPoiSelection(
        poiB,
      );
      await _flushMicrotasks();

      expect(localController.hasClusterPickerStreamValue.value, isFalse);
      expect(
          localController.selectedPoiLoadingIdStreamValue.value, 'poi-stack-b');
      expect(localController.selectedPoiStreamValue.value, isNull);

      hydration.complete(
        buildAccountProfileModelFromPrimitives(
          id: '507f1f77bcf86cd799439023',
          name: 'Casa B',
          slug: 'casa-b',
          type: 'beach_club_custom',
          avatarUrl: 'https://tenant.test/media/casa-b-avatar.png',
          coverUrl: 'https://tenant.test/media/casa-b-cover.png',
        ),
      );

      await selectionFuture;
      await _flushMicrotasks();

      expect(localController.selectedPoiStreamValue.value?.id, 'poi-stack-b');
      expect(
        localController.selectedPoiStreamValue.value?.visual?.imageUri,
        'https://tenant.test/media/casa-b-avatar.png',
      );
      expect(
        localController.selectedPoiStreamValue.value?.coverImageUri,
        'https://tenant.test/media/casa-b-cover.png',
      );
    });

    test('deck poi selection hydrates account profile with avatar and cover',
        () async {
      final localAccountProfilesRepository = _FakeAccountProfilesRepository();
      final fakeMapHandle = _FakeMapHandle();
      final localController = _buildMapController(
        poiRepository: _buildPoiRepository(
          mapRepository: mapRepository,
          accountProfilesRepository: localAccountProfilesRepository,
        ),
        userLocationRepository: userLocationRepository,
        telemetryRepository: telemetry,
        mapHandle: fakeMapHandle,
        appData: _buildAppData(),
      );
      addTearDown(() async {
        await localController.onDispose();
        fakeMapHandle.dispose();
      });

      mapRepository.nextPois = <CityPoiModel>[
        _buildPoi(
          id: 'poi-partner',
          name: 'Casa Marracini',
          refType: 'account_profile',
          refId: '507f1f77bcf86cd799439011',
          refSlug: 'casa-marracini',
          refPath: '/parceiro/casa-marracini',
        ),
      ];
      await localController.loadPois(PoiQuery());
      final poi = localController.filteredPoisStreamValue.value!.single;

      final hydration = Completer<AccountProfileModel?>();
      localAccountProfilesRepository.pendingBySlug['casa-marracini'] =
          hydration;

      final selectionFuture = localController.handleDeckPoiSelection(poi);
      await _flushMicrotasks();

      expect(localController.selectedPoiLoadingIdStreamValue.value, poi.id);
      expect(localController.selectedPoiStreamValue.value, isNull);

      hydration.complete(
        buildAccountProfileModelFromPrimitives(
          id: '507f1f77bcf86cd799439011',
          name: 'Casa Marracini',
          slug: 'casa-marracini',
          type: 'beach_club_custom',
          avatarUrl: 'https://tenant.test/media/casa-avatar.png',
          coverUrl: 'https://tenant.test/media/casa-cover.png',
        ),
      );

      await selectionFuture;
      await _flushMicrotasks();

      expect(localController.selectedPoiStreamValue.value?.id, 'poi-partner');
      expect(
        localController.selectedPoiStreamValue.value?.visual?.imageUri,
        'https://tenant.test/media/casa-avatar.png',
      );
      expect(
        localController.selectedPoiStreamValue.value?.coverImageUri,
        'https://tenant.test/media/casa-cover.png',
      );
      expect(
        localController.filteredPoisStreamValue.value?.single.visual?.imageUri,
        isNull,
      );
    });

    test(
        'marker tap hydrates account-profile poi aliases with avatar and cover',
        () async {
      final localAccountProfilesRepository = _FakeAccountProfilesRepository();
      final fakeMapHandle = _FakeMapHandle();
      final localController = _buildMapController(
        poiRepository: _buildPoiRepository(
          mapRepository: mapRepository,
          accountProfilesRepository: localAccountProfilesRepository,
        ),
        userLocationRepository: userLocationRepository,
        telemetryRepository: telemetry,
        mapHandle: fakeMapHandle,
        appData: _buildAppData(),
      );
      addTearDown(() async {
        await localController.onDispose();
        fakeMapHandle.dispose();
      });

      for (final entry in const <({String id, String refType})>[
        (id: 'poi-partner-alias', refType: 'partner'),
        (id: 'poi-accountprofile-alias', refType: 'accountprofile'),
      ]) {
        mapRepository.nextPois = <CityPoiModel>[
          _buildPoi(
            id: entry.id,
            name: 'Casa Marracini',
            refType: entry.refType,
            refId: '507f1f77bcf86cd799439011',
            refSlug: 'casa-marracini',
            refPath: '/parceiro/casa-marracini',
          ),
        ];
        await localController.loadPois(PoiQuery());
        localController.clearSelectedPoi();

        final poi = localController.filteredPoisStreamValue.value!.single;
        final hydration = Completer<AccountProfileModel?>();
        localAccountProfilesRepository.pendingBySlug['casa-marracini'] =
            hydration;

        final selectionFuture = localController.handleMarkerTap(poi);
        await _flushMicrotasks();

        expect(localController.selectedPoiLoadingIdStreamValue.value, poi.id);
        expect(localController.selectedPoiStreamValue.value, isNull);

        hydration.complete(
          buildAccountProfileModelFromPrimitives(
            id: '507f1f77bcf86cd799439011',
            name: 'Casa Marracini',
            slug: 'casa-marracini',
            type: 'beach_club_custom',
            avatarUrl: 'https://tenant.test/media/casa-avatar.png',
            coverUrl: 'https://tenant.test/media/casa-cover.png',
          ),
        );

        await selectionFuture;
        await _flushMicrotasks();

        expect(localController.selectedPoiStreamValue.value?.id, entry.id);
        expect(
          localController.selectedPoiStreamValue.value?.visual?.imageUri,
          'https://tenant.test/media/casa-avatar.png',
        );
        expect(
          localController.selectedPoiStreamValue.value?.coverImageUri,
          'https://tenant.test/media/casa-cover.png',
        );
      }
    });

    test(
        'deck poi selection hydrates event imagery from the canonical cover fallback chain',
        () async {
      final localScheduleRepository = _FakeScheduleRepository();
      final fakeMapHandle = _FakeMapHandle();
      final localController = _buildMapController(
        poiRepository: _buildPoiRepository(
          mapRepository: mapRepository,
          scheduleRepository: localScheduleRepository,
        ),
        userLocationRepository: userLocationRepository,
        telemetryRepository: telemetry,
        mapHandle: fakeMapHandle,
        appData: _buildAppData(),
      );
      addTearDown(() async {
        await localController.onDispose();
        fakeMapHandle.dispose();
      });

      mapRepository.nextPois = <CityPoiModel>[
        _buildPoi(
          id: 'poi-event',
          name: 'Evento Longo',
          refType: 'event',
          refId: 'event-1',
          refSlug: 'evento-longo',
          refPath: '/event/evento-longo',
        ),
      ];
      localScheduleRepository.eventsBySlug['evento-longo'] =
          _buildEventDetailModel(
        slug: 'evento-longo',
        thumbUrl: 'https://tenant.test/media/event-cover.png',
        linkedAccountProfileAvatarUrl:
            'https://tenant.test/media/ananda-avatar.png',
        linkedAccountProfileCoverUrl:
            'https://tenant.test/media/ananda-cover.png',
      );

      await localController.loadPois(PoiQuery());
      final poi = localController.filteredPoisStreamValue.value!.single;

      await localController.handleDeckPoiSelection(poi);
      await _flushMicrotasks();

      expect(localScheduleRepository.requestedSlugs, ['evento-longo']);
      expect(localController.selectedPoiStreamValue.value?.id, 'poi-event');
      expect(
        localController.selectedPoiStreamValue.value?.visual?.imageUri,
        'https://tenant.test/media/event-cover.png',
      );
      expect(
        localController.selectedPoiStreamValue.value?.coverImageUri,
        'https://tenant.test/media/event-cover.png',
      );
      expect(
        localController.selectedPoiStreamValue.value?.description,
        'Evento detalhado',
      );
      expect(
        localController.selectedPoiStreamValue.value?.linkedProfiles
            .map((profile) => profile.displayName),
        ['Ananda Torres'],
      );
      expect(
        localController.filteredPoisStreamValue.value?.single.visual?.imageUri,
        isNull,
      );
    });

    test('clearing selection before hydration completes ignores stale result',
        () async {
      final localAccountProfilesRepository = _FakeAccountProfilesRepository();
      final fakeMapHandle = _FakeMapHandle();
      final localController = _buildMapController(
        poiRepository: _buildPoiRepository(
          mapRepository: mapRepository,
          accountProfilesRepository: localAccountProfilesRepository,
        ),
        userLocationRepository: userLocationRepository,
        telemetryRepository: telemetry,
        mapHandle: fakeMapHandle,
        appData: _buildAppData(),
      );
      addTearDown(() async {
        await localController.onDispose();
        fakeMapHandle.dispose();
      });

      mapRepository.nextPois = <CityPoiModel>[
        _buildPoi(
          id: 'poi-partner',
          refType: 'account_profile',
          refId: '507f1f77bcf86cd799439011',
          refSlug: 'casa-marracini',
          refPath: '/parceiro/casa-marracini',
        ),
      ];
      await localController.loadPois(PoiQuery());
      final poi = localController.filteredPoisStreamValue.value!.single;

      final hydration = Completer<AccountProfileModel?>();
      localAccountProfilesRepository.pendingBySlug['casa-marracini'] =
          hydration;

      final tapFuture = localController.handleMarkerTap(poi);
      await _flushMicrotasks();
      localController.clearSelectedPoi(preserveMarkerMemory: false);

      hydration.complete(
        buildAccountProfileModelFromPrimitives(
          id: '507f1f77bcf86cd799439011',
          name: 'Casa Marracini',
          slug: 'casa-marracini',
          type: 'restaurant',
          coverUrl: 'https://tenant.test/media/casa-cover.png',
        ),
      );

      await tapFuture;
      await _flushMicrotasks();

      expect(localController.selectedPoiLoadingIdStreamValue.value, isNull);
      expect(localController.selectedPoiStreamValue.value, isNull);
      expect(localController.lastSelectedPoiMemoryStreamValue.value, isNull);
      expect(
        localController.filteredPoisStreamValue.value?.single.visual?.imageUri,
        isNull,
      );
    });

    test('different poi taps are last-write-wins during hydration', () async {
      final localAccountProfilesRepository = _FakeAccountProfilesRepository();
      final fakeMapHandle = _FakeMapHandle();
      final localController = _buildMapController(
        poiRepository: _buildPoiRepository(
          mapRepository: mapRepository,
          accountProfilesRepository: localAccountProfilesRepository,
        ),
        userLocationRepository: userLocationRepository,
        telemetryRepository: telemetry,
        mapHandle: fakeMapHandle,
        appData: _buildAppData(),
      );
      addTearDown(() async {
        await localController.onDispose();
        fakeMapHandle.dispose();
      });

      mapRepository.nextPois = <CityPoiModel>[
        _buildPoi(
          id: 'poi-a',
          name: 'Casa A',
          refType: 'account_profile',
          refId: 'profile-a',
          refSlug: 'casa-a',
          refPath: '/parceiro/casa-a',
        ),
        _buildPoi(
          id: 'poi-b',
          name: 'Casa B',
          refType: 'account_profile',
          refId: 'profile-b',
          refSlug: 'casa-b',
          refPath: '/parceiro/casa-b',
        ),
      ];
      await localController.loadPois(PoiQuery());
      final pois = localController.filteredPoisStreamValue.value!;

      final hydrationA = Completer<AccountProfileModel?>();
      final hydrationB = Completer<AccountProfileModel?>();
      localAccountProfilesRepository.pendingBySlug['casa-a'] = hydrationA;
      localAccountProfilesRepository.pendingBySlug['casa-b'] = hydrationB;

      final tapA = localController.handleMarkerTap(pois[0]);
      await _flushMicrotasks();
      final tapB = localController.handleMarkerTap(pois[1]);
      await _flushMicrotasks();

      expect(localController.selectedPoiLoadingIdStreamValue.value, 'poi-b');

      hydrationA.complete(
        buildAccountProfileModelFromPrimitives(
          id: '507f1f77bcf86cd799439021',
          name: 'Casa A',
          slug: 'casa-a',
          type: 'restaurant',
          coverUrl: 'https://tenant.test/media/casa-a.png',
        ),
      );
      await _flushMicrotasks();

      expect(localController.selectedPoiStreamValue.value, isNull);
      expect(localController.selectedPoiLoadingIdStreamValue.value, 'poi-b');

      hydrationB.complete(
        buildAccountProfileModelFromPrimitives(
          id: '507f1f77bcf86cd799439022',
          name: 'Casa B',
          slug: 'casa-b',
          type: 'restaurant',
          coverUrl: 'https://tenant.test/media/casa-b.png',
        ),
      );

      await Future.wait<void>([tapA, tapB]);
      await _flushMicrotasks();

      expect(localController.selectedPoiStreamValue.value?.id, 'poi-b');
      expect(
        localController.selectedPoiStreamValue.value?.visual?.imageUri,
        'https://tenant.test/media/casa-b.png',
      );
      expect(
        localController.filteredPoisStreamValue.value?.first.visual?.imageUri,
        isNull,
      );
      expect(
        localController.filteredPoisStreamValue.value?[1].visual?.imageUri,
        isNull,
      );
    });

    test('empty tap on the map closes an open cluster picker', () async {
      final fakeMapHandle = _FakeMapHandle();
      final localController = _buildMapController(
        poiRepository: _buildPoiRepository(mapRepository: mapRepository),
        userLocationRepository: userLocationRepository,
        telemetryRepository: telemetry,
        mapHandle: fakeMapHandle,
        appData: _buildAppData(),
      );
      addTearDown(() async {
        await localController.onDispose();
        fakeMapHandle.dispose();
      });

      await localController.init();
      await _flushMicrotasks();

      final anchorPoi = _buildPoi(id: 'poi-a');
      localController.showClusterPicker(
        <CityPoiModel>[anchorPoi, _buildPoi(id: 'poi-b')],
        anchorCoordinate: anchorPoi.coordinate,
      );

      fakeMapHandle.emitInteraction(
        const BellugaMapInteractionEvent(
          type: BellugaMapInteractionType.emptyTap,
          userGesture: true,
        ),
      );
      await _flushMicrotasks();

      expect(localController.hasClusterPickerStreamValue.value, isFalse);
      expect(localController.clusterPickerPoisStreamValue.value, isNull);
    });

    test(
      'applies marker override key only after catalog reload completes',
      () async {
        final firstRequest = Completer<List<CityPoiModel>>();
        mapRepository.queuedFetchCompleters.add(firstRequest);
        final category = _buildCategory(
          key: 'beach',
          label: 'Praias',
          tags: const {},
          overrideMarker: true,
          markerOverride: _buildIconMarkerOverride(
            icon: 'beach',
            colorHex: '#FF3300',
          ),
          serverQuery: _buildServerQuery(
            source: 'static_asset',
            types: {'beach_spot'},
          ),
        );

        expect(controller.appliedCatalogFilterKeyStreamValue.value, isNull);

        controller.toggleCatalogCategoryFilter(category);
        await _flushMicrotasks();

        expect(controller.activeCatalogFilterKeyStreamValue.value, 'beach');
        expect(controller.appliedCatalogFilterKeyStreamValue.value, isNull);

        firstRequest.complete(<CityPoiModel>[]);
        await _flushMicrotasks();
        await _flushMicrotasks();

        expect(controller.appliedCatalogFilterKeyStreamValue.value, 'beach');
      },
    );

    test('keeps the latest loadPois result after overlapping requests',
        () async {
      final firstRequest = Completer<List<CityPoiModel>>();
      final secondRequest = Completer<List<CityPoiModel>>();
      mapRepository.queuedFetchCompleters
        ..add(firstRequest)
        ..add(secondRequest);

      final firstPoi = _buildPoi(id: 'poi-first');
      final secondPoi = _buildPoi(id: 'poi-second');

      final firstFuture = controller.loadPois(PoiQuery());
      await _flushMicrotasks();
      final secondFuture = controller.loadPois(
        _buildQuery(categoryKeys: {'event'}),
      );
      await _flushMicrotasks();

      firstRequest.complete(<CityPoiModel>[firstPoi]);
      await _flushMicrotasks();

      secondRequest.complete(<CityPoiModel>[secondPoi]);
      await Future.wait<void>([firstFuture, secondFuture]);
      await _flushMicrotasks();

      expect(
        (controller.filteredPoisStreamValue.value ?? const <CityPoiModel>[])
            .map((poi) => poi.id),
        equals(<String>['poi-second']),
      );
    });

    test('refreshes query origin from the latest tracked user location',
        () async {
      final firstOrigin = _buildCoordinate('-20.1000', '-40.1000');
      final latestOrigin = _buildCoordinate('-20.2000', '-40.2000');

      userLocationRepository.userLocationStreamValue.addValue(firstOrigin);
      await controller.loadPois(PoiQuery());
      expect(mapRepository.lastQuery?.origin, firstOrigin);

      userLocationRepository.userLocationStreamValue.addValue(latestOrigin);
      await controller.searchPois('pizza');

      expect(mapRepository.lastQuery?.origin, latestOrigin);
      expect(_querySearchTerm(mapRepository.lastQuery), 'pizza');
    });

    test('logs directions and ride share events', () async {
      final poi = _buildPoi();

      controller.logDirectionsOpened(poi);
      controller.logRideShareClicked(
        provider: RideShareProvider.uber,
        poiId: poi.id,
      );
      await _flushMicrotasks();

      expect(telemetry.events, hasLength(2));
      expect(telemetry.events[0].eventName, 'map_directions_opened');
      expect(telemetry.events[0].event, EventTrackerEvents.viewContent);
      expect(telemetry.events[0].properties?['poi_id'], poi.id);
      expect(telemetry.events[1].eventName, 'map_ride_share_clicked');
      expect(telemetry.events[1].event, EventTrackerEvents.buttonClick);
      expect(telemetry.events[1].properties?['provider'], 'uber');
    });

    test(
        'hydrates selected poi from initial query when top-level list has match',
        () async {
      final targetPoi = _buildPoi(
        id: 'poi-target',
        refType: 'event',
        refId: 'evt-001',
        stackKey: 'stack-target',
      );
      mapRepository.nextPois = <CityPoiModel>[targetPoi];

      await controller.init(initialPoiQuery: 'event:evt-001');
      await _flushMicrotasks();

      expect(controller.selectedPoiStreamValue.value?.id, 'poi-target');
      expect(
        controller.statusMessageStreamValue.value,
        isNot('POI do link não foi encontrado.'),
      );
    });

    test('skips auto-centering on user when initial poi query is provided',
        () async {
      final targetPoi = _buildPoi(
        id: 'poi-target',
        refType: 'event',
        refId: 'evt-001',
      );
      mapRepository.nextPois = <CityPoiModel>[targetPoi];

      await controller.init(initialPoiQuery: 'event:evt-001');
      await _flushMicrotasks();

      expect(userLocationRepository.refreshIfPermittedCallCount, 1);
      expect(userLocationRepository.resolveUserLocationCallCount, 0);
    });

    test(
        'does not auto-center on user but still triggers permission resolution on plain map load',
        () async {
      await controller.init();
      await _flushMicrotasks();

      expect(userLocationRepository.refreshIfPermittedCallCount, 1);
      expect(userLocationRepository.resolveUserLocationCallCount, 1);
    });

    test(
        'keeps location feedback in loading state and suppresses false unavailable notice while refresh is unresolved',
        () async {
      final refreshCompleter = Completer<bool>();
      userLocationRepository.refreshIfPermittedCompleter = refreshCompleter;

      final initFuture = controller.init();
      await _flushMicrotasks();
      await _flushMicrotasks();

      expect(
        controller.locationFeedbackStateStreamValue.value.kind,
        MapLocationFeedbackKind.loading,
      );
      expect(controller.softLocationNoticeStreamValue.value, '');

      userLocationRepository.locationResolutionPhaseStreamValue
          .addValue(LocationResolutionPhase.unavailable);
      refreshCompleter.complete(false);
      await initFuture;
    });

    test(
        'reconciles to live location after refresh resolves and reloads points from the resolved origin',
        () async {
      final refreshCompleter = Completer<bool>();
      userLocationRepository.refreshIfPermittedCompleter = refreshCompleter;

      final initFuture = controller.init();
      await _flushMicrotasks();
      await _flushMicrotasks();

      expect(
        mapRepository.lastQuery?.origin?.latitude,
        mapRepository.defaultCenter().latitude,
      );
      expect(
        mapRepository.lastQuery?.origin?.longitude,
        mapRepository.defaultCenter().longitude,
      );
      expect(controller.softLocationNoticeStreamValue.value, '');

      final resolvedCoordinate = _buildCoordinate('-20.1234', '-40.2345');
      userLocationRepository.userLocationStreamValue
          .addValue(resolvedCoordinate);
      userLocationRepository.lastKnownLocationStreamValue
          .addValue(resolvedCoordinate);
      userLocationRepository.lastKnownCapturedAtStreamValue
          .addValue(DateTime.now());
      userLocationRepository.locationResolutionPhaseStreamValue
          .addValue(LocationResolutionPhase.resolved);
      refreshCompleter.complete(true);

      await initFuture;
      await _flushMicrotasks();
      await _flushMicrotasks();

      expect(
        controller.locationFeedbackStateStreamValue.value.kind,
        MapLocationFeedbackKind.live,
      );
      expect(
        controller.softLocationNoticeStreamValue.value,
        'Estamos usando sua localização para exibir eventos e lugares próximos a você.',
      );
      expect(
        mapRepository.lastQuery?.origin?.latitude,
        resolvedCoordinate.latitude,
      );
      expect(
        mapRepository.lastQuery?.origin?.longitude,
        resolvedCoordinate.longitude,
      );
    });

    test(
        'does not re-enter poi reload churn when rapid nearby live updates keep the same semantic origin state',
        () async {
      final refreshCompleter = Completer<bool>();
      userLocationRepository.refreshIfPermittedCompleter = refreshCompleter;
      final firstFetch = Completer<List<CityPoiModel>>();
      final reconcileFetch = Completer<List<CityPoiModel>>();
      mapRepository.queuedFetchCompleters
          .addAll(<Completer<List<CityPoiModel>>>[
        firstFetch,
        reconcileFetch,
      ]);
      final statusMessages = <String?>[];
      final loadingStates = <bool>[];
      final mapStatuses = <MapStatus>[];
      final statusSubscription =
          controller.statusMessageStreamValue.stream.listen(statusMessages.add);
      final loadingSubscription =
          controller.isLoading.stream.listen(loadingStates.add);
      final mapStatusSubscription =
          controller.mapStatusStreamValue.stream.listen(mapStatuses.add);
      addTearDown(() async {
        await statusSubscription.cancel();
        await loadingSubscription.cancel();
        await mapStatusSubscription.cancel();
      });

      final initFuture = controller.init();
      await _flushMicrotasks();
      await _flushMicrotasks();

      final firstResolvedCoordinate = _buildCoordinate('-20.1234', '-40.2345');
      userLocationRepository.userLocationStreamValue
          .addValue(firstResolvedCoordinate);
      userLocationRepository.lastKnownLocationStreamValue
          .addValue(firstResolvedCoordinate);
      userLocationRepository.lastKnownCapturedAtStreamValue
          .addValue(DateTime.now());
      userLocationRepository.locationResolutionPhaseStreamValue
          .addValue(LocationResolutionPhase.resolved);
      refreshCompleter.complete(true);

      await _flushMicrotasks();
      await _flushMicrotasks();

      expect(mapRepository.fetchPointsCallCount, 2);
      expect(
        statusMessages.where((message) => message == 'Atualizando pontos...'),
        hasLength(1),
      );
      expect(
        loadingStates.where((value) => value),
        hasLength(2),
      );
      expect(
        mapStatuses.where((status) => status == MapStatus.fetching),
        hasLength(2),
      );

      final burstCoordinates = <CityCoordinate>[
        _buildCoordinate('-20.123401', '-40.234501'),
        _buildCoordinate('-20.123402', '-40.234502'),
        _buildCoordinate('-20.123403', '-40.234503'),
        _buildCoordinate('-20.123404', '-40.234504'),
        _buildCoordinate('-20.123405', '-40.234505'),
        _buildCoordinate('-20.123406', '-40.234506'),
        _buildCoordinate('-20.123407', '-40.234507'),
        _buildCoordinate('-20.123408', '-40.234508'),
      ];
      for (var index = 0; index < burstCoordinates.length; index++) {
        final latestResolvedCoordinate = burstCoordinates[index];
        userLocationRepository.userLocationStreamValue
            .addValue(latestResolvedCoordinate);
        userLocationRepository.lastKnownLocationStreamValue
            .addValue(latestResolvedCoordinate);
        userLocationRepository.lastKnownCapturedAtStreamValue.addValue(
          DateTime.now().add(Duration(milliseconds: index + 1)),
        );
        userLocationRepository.locationResolutionPhaseStreamValue
            .addValue(LocationResolutionPhase.resolved);
      }
      await _flushMicrotasks();
      await _flushMicrotasks();

      expect(
        mapRepository.fetchPointsCallCount,
        2,
        reason:
            'rapid nearby live updates in the same semantic state must not trigger extra poi reloads',
      );
      expect(
        statusMessages.where((message) => message == 'Atualizando pontos...'),
        hasLength(1),
        reason:
            'controller must not re-emit the updating banner during burst churn',
      );
      expect(
        loadingStates.where((value) => value),
        hasLength(2),
        reason:
            'controller must not re-enter loading for semantically equivalent live updates',
      );
      expect(
        mapStatuses.where((status) => status == MapStatus.fetching),
        hasLength(2),
        reason:
            'controller must not re-enter fetching for semantically equivalent live updates',
      );

      reconcileFetch.complete(const <CityPoiModel>[]);
      await _flushMicrotasks();
      await _flushMicrotasks();
      firstFetch.complete(const <CityPoiModel>[]);
      await initFuture;
      await _flushMicrotasks();
      await _flushMicrotasks();

      expect(
        mapRepository.fetchPointsCallCount,
        2,
        reason:
            'same live-location semantic state must not trigger map reload loop',
      );
      expect(
        statusMessages.where((message) => message == 'Atualizando pontos...'),
        hasLength(1),
      );
      expect(
        loadingStates.where((value) => value),
        hasLength(2),
      );
      expect(
        mapStatuses.where((status) => status == MapStatus.fetching),
        hasLength(2),
      );
      expect(
        controller.mapStatusStreamValue.value,
        MapStatus.ready,
      );
      expect(
        controller.statusMessageStreamValue.value,
        isNull,
      );
    });

    test(
        'permission-resolution overlap reloads points only once when live origin resolves during the request',
        () async {
      final resolveCompleter = Completer<String?>();
      userLocationRepository.resolveUserLocationCompleter = resolveCompleter;
      final firstFetch = Completer<List<CityPoiModel>>();
      final reconcileFetch = Completer<List<CityPoiModel>>();
      mapRepository.queuedFetchCompleters
          .addAll(<Completer<List<CityPoiModel>>>[
        firstFetch,
        reconcileFetch,
      ]);
      final statusMessages = <String?>[];
      final loadingStates = <bool>[];
      final mapStatuses = <MapStatus>[];
      final statusSubscription =
          controller.statusMessageStreamValue.stream.listen(statusMessages.add);
      final loadingSubscription =
          controller.isLoading.stream.listen(loadingStates.add);
      final mapStatusSubscription =
          controller.mapStatusStreamValue.stream.listen(mapStatuses.add);
      addTearDown(() async {
        await statusSubscription.cancel();
        await loadingSubscription.cancel();
        await mapStatusSubscription.cancel();
      });

      final initFuture = controller.init();
      await _flushMicrotasks();
      await _flushMicrotasks();

      firstFetch.complete(const <CityPoiModel>[]);
      await initFuture;
      await _flushMicrotasks();
      await _flushMicrotasks();

      expect(userLocationRepository.resolveUserLocationCallCount, 1);
      expect(mapRepository.fetchPointsCallCount, 1);

      final resolvedCoordinate = _buildCoordinate('-20.1234', '-40.2345');
      userLocationRepository.userLocationStreamValue
          .addValue(resolvedCoordinate);
      userLocationRepository.lastKnownLocationStreamValue
          .addValue(resolvedCoordinate);
      userLocationRepository.lastKnownCapturedAtStreamValue
          .addValue(DateTime.now());
      userLocationRepository.locationResolutionPhaseStreamValue
          .addValue(LocationResolutionPhase.resolved);
      await _flushMicrotasks();
      await _flushMicrotasks();

      expect(mapRepository.fetchPointsCallCount, 2);
      expect(
        statusMessages.where((message) => message == 'Atualizando pontos...'),
        hasLength(1),
      );

      resolveCompleter.complete(null);
      await _flushMicrotasks();
      await _flushMicrotasks();

      reconcileFetch.complete(const <CityPoiModel>[]);
      await _flushMicrotasks();
      await _flushMicrotasks();

      expect(
        mapRepository.fetchPointsCallCount,
        2,
        reason:
            'phase-listener reconciliation and resolveUserLocation completion must not double-reload the same origin transition',
      );
      expect(
        statusMessages.where((message) => message == 'Atualizando pontos...'),
        hasLength(1),
      );
      expect(
        loadingStates.where((value) => value),
        hasLength(2),
      );
      expect(
        mapStatuses.where((status) => status == MapStatus.fetching),
        hasLength(2),
      );
    });

    test(
        'soft-gate map entry skips interactive resolution and exposes fixed-location notice',
        () async {
      LocationPermissionGateRuntime.armSoftLocationFallbackEntry();

      await controller.init();
      await _flushMicrotasks();

      expect(userLocationRepository.refreshIfPermittedCallCount, 1);
      expect(userLocationRepository.resolveUserLocationCallCount, 0);
      expect(
        controller.softLocationNoticeStreamValue.value,
        'Sua localização não está disponível, por isso, usamos uma localização de referência para mostrar eventos e locais relevantes.',
      );
      expect(
        mapRepository.lastQuery?.origin?.latitude,
        mapRepository.defaultCenter().latitude,
      );
      expect(
        mapRepository.lastQuery?.origin?.longitude,
        mapRepository.defaultCenter().longitude,
      );
    });

    test('centerOnUser silently no-ops when map is not ready yet', () async {
      final notReadyMapHandle = _FakeMapHandle(isReady: false);
      final localController = _buildMapController(
        poiRepository: _buildPoiRepository(mapRepository: mapRepository),
        userLocationRepository: userLocationRepository,
        telemetryRepository: telemetry,
        mapHandle: notReadyMapHandle,
        appData: _buildAppData(),
      );
      addTearDown(() async {
        await localController.onDispose();
        notReadyMapHandle.dispose();
      });

      userLocationRepository.userLocationStreamValue
          .addValue(_buildCoordinate('-20.1000', '-40.1000'));

      await localController.centerOnUser();
      expect(localController.statusMessageStreamValue.value, isNull);
      expect(notReadyMapHandle.moveCallCount, 0);
    });

    test(
        'centerOnUser does not emit status when target camera already matches the current user location',
        () async {
      final sameCameraHandle = _FakeMapHandle(
        isReady: true,
        initialZoom: 16,
        initialCenter: _buildCoordinate('-20.1000', '-40.1000'),
        treatNoOpMoveAsSuccess: true,
      );
      final localController = _buildMapController(
        poiRepository: _buildPoiRepository(mapRepository: mapRepository),
        userLocationRepository: userLocationRepository,
        telemetryRepository: telemetry,
        mapHandle: sameCameraHandle,
        appData: _buildAppData(),
      );
      addTearDown(() async {
        await localController.onDispose();
        sameCameraHandle.dispose();
      });

      userLocationRepository.userLocationStreamValue
          .addValue(_buildCoordinate('-20.1000', '-40.1000'));

      await localController.centerOnUser();
      await localController.centerOnUser();

      expect(localController.statusMessageStreamValue.value, isNull);
    });

    test(
      'hydrates selected poi from stack query when poi is not in top-level list',
      () async {
        final topPoi = _buildPoi(
          id: 'poi-top',
          refType: 'event',
          refId: 'evt-top',
          stackKey: 'stack-abc',
          stackCount: 2,
        );
        final stackedTarget = _buildPoi(
          id: 'poi-stacked',
          refType: 'event',
          refId: 'evt-stacked',
          stackKey: 'stack-abc',
          stackCount: 2,
        );
        mapRepository.nextPois = <CityPoiModel>[topPoi];
        mapRepository.nextStackItems = <CityPoiModel>[
          topPoi,
          stackedTarget,
        ];

        await controller.init(
          initialPoiQuery: 'event:evt-stacked',
          initialPoiStackQuery: 'stack-abc',
        );
        await _flushMicrotasks();

        expect(mapRepository.lastStackKey, 'stack-abc');
        expect(controller.selectedPoiStreamValue.value?.id, 'poi-stacked');
        expect(
          controller.statusMessageStreamValue.value,
          isNot('POI do link não foi encontrado.'),
        );
      },
    );

    test(
      'hydrates selected poi from backend lookup when typed query is outside loaded payload',
      () async {
        mapRepository.nextPois = <CityPoiModel>[
          _buildPoi(
            id: 'poi-other',
            refType: 'event',
            refId: 'evt-other',
          ),
        ];
        mapRepository.nextLookupPoi = _buildPoi(
          id: 'poi-lookup',
          refType: 'event',
          refId: 'evt-lookup',
          stackKey: 'stack-lookup',
          stackCount: 2,
        );

        await controller.init(initialPoiQuery: 'event:evt-lookup');
        await _flushMicrotasks();

        expect(mapRepository.lastLookupRefType, 'event');
        expect(mapRepository.lastLookupRefId, 'evt-lookup');
        expect(controller.selectedPoiStreamValue.value?.id, 'poi-lookup');
        expect(
          controller.statusMessageStreamValue.value,
          isNot('POI do link não foi encontrado.'),
        );
      },
    );

    test(
      'hydrates initial poi before refreshIfPermitted completes',
      () async {
        final refreshCompleter = Completer<bool>();
        userLocationRepository.refreshIfPermittedCompleter = refreshCompleter;
        mapRepository.nextLookupPoi = _buildPoi(
          id: 'poi-lookup',
          refType: 'event',
          refId: 'evt-lookup',
        );

        var initCompleted = false;
        final initFuture = controller.init(initialPoiQuery: 'event:evt-lookup')
          ..then((_) => initCompleted = true);

        await _flushMicrotasks();
        await _flushMicrotasks();

        expect(mapRepository.lastLookupRefType, 'event');
        expect(mapRepository.lastLookupRefId, 'evt-lookup');
        expect(controller.selectedPoiStreamValue.value?.id, 'poi-lookup');
        expect(
          initCompleted,
          isFalse,
          reason: 'location refresh can continue while poi hydration resolves',
        );

        refreshCompleter.complete(false);
        await initFuture;
      },
    );

    test('sets deterministic status when initial poi query cannot be resolved',
        () async {
      mapRepository.nextPois = <CityPoiModel>[
        _buildPoi(
          id: 'poi-other',
          refType: 'event',
          refId: 'evt-other',
          stackKey: 'stack-other',
        ),
      ];

      await controller.init(initialPoiQuery: 'event:evt-missing');
      await _flushMicrotasks();

      expect(controller.selectedPoiStreamValue.value, isNull);
      expect(
        controller.statusMessageStreamValue.value,
        'POI do link não foi encontrado.',
      );
    });

    test('buildPoiQueryKey normalizes ref_type:ref_id key', () {
      final canonicalPoi = _buildPoi(
        id: 'poi-canonical',
        refType: 'EVENT',
        refId: 'EVT-9000',
      );

      expect(controller.buildPoiQueryKey(canonicalPoi), 'event:evt-9000');
    });

    test('handleMarkerTap focuses selected poi in the upper viewport safe zone',
        () async {
      final fakeMapHandle = _FakeMapHandle(
        initialZoom: 15.4,
        initialCenter: _buildPoi(id: 'seed').coordinate,
      );
      final localController = _buildMapController(
        poiRepository: _buildPoiRepository(mapRepository: mapRepository),
        userLocationRepository: userLocationRepository,
        telemetryRepository: telemetry,
        mapHandle: fakeMapHandle,
        appData: _buildAppData(),
      );
      addTearDown(() async {
        await localController.onDispose();
        fakeMapHandle.dispose();
      });

      final poi = _buildPoi(id: 'poi-focus');
      await localController.handleMarkerTap(poi);
      await _flushMicrotasks();

      expect(localController.selectedPoiStreamValue.value?.id, 'poi-focus');
      expect(fakeMapHandle.moveCallCount, greaterThanOrEqualTo(2));
      expect(
        fakeMapHandle.lastVerticalViewportAnchor,
        closeTo(0.28, 1e-9),
      );
    });

    test(
        'applies initial poi focus after first map event when deep link query is present',
        () async {
      final fakeMapHandle = _FakeMapHandle(isReady: false);
      final targetPoi = _buildPoi(
        id: 'poi-target',
        refType: 'event',
        refId: 'evt-001',
      );
      mapRepository.nextPois = <CityPoiModel>[targetPoi];

      final localController = _buildMapController(
        poiRepository: _buildPoiRepository(mapRepository: mapRepository),
        userLocationRepository: userLocationRepository,
        telemetryRepository: telemetry,
        mapHandle: fakeMapHandle,
        appData: _buildAppData(),
      );
      addTearDown(() async {
        await localController.onDispose();
        fakeMapHandle.dispose();
      });

      await localController.init(initialPoiQuery: 'event:evt-001');
      await _flushMicrotasks();

      expect(localController.selectedPoiStreamValue.value?.id, 'poi-target');
      expect(fakeMapHandle.moveCallCount, 0);

      fakeMapHandle.emitReady();
      await _flushMicrotasks();
      await _flushMicrotasks();

      expect(fakeMapHandle.moveCallCount, 1);
      expect(fakeMapHandle.lastMoveCoordinate, isNotNull);
      expect(
        fakeMapHandle.lastMoveCoordinate!.latitude,
        closeTo(-20.0, 1e-9),
      );
      expect(
        fakeMapHandle.lastMoveCoordinate!.longitude,
        closeTo(-40.0, 1e-9),
      );

      fakeMapHandle.emitReady();
      await _flushMicrotasks();

      expect(
        fakeMapHandle.moveCallCount,
        1,
        reason: 'initial focus must be applied exactly once',
      );
    });
  });

  group('MapScreen safe back', () {
    late _FakeTelemetryRepository telemetry;
    late _FakeCityMapRepository mapRepository;
    late _FakeUserLocationRepository userLocationRepository;
    late PoiRepository poiRepository;
    late MapScreenController controller;

    setUp(() async {
      await GetIt.I.reset(dispose: false);
      LocationPermissionGateRuntime.resetForTesting();
      telemetry = _FakeTelemetryRepository();
      mapRepository = _FakeCityMapRepository();
      userLocationRepository = _FakeUserLocationRepository();
      poiRepository = PoiRepository(
        dataSource: mapRepository,
      );
      controller = _buildMapController(
        poiRepository: poiRepository,
        userLocationRepository: userLocationRepository,
        telemetryRepository: telemetry,
        appData: _buildAppData(),
      );
      GetIt.I.registerSingleton<MapScreenController>(controller);
    });

    tearDown(() async {
      await controller.onDispose();
      mapRepository.dispose();
      userLocationRepository.dispose();
      await GetIt.I.reset(dispose: false);
      LocationPermissionGateRuntime.resetForTesting();
    });

    testWidgets(
        'map root system back falls back to home when no history exists',
        (tester) async {
      final router = _RecordingStackRouter()..canPopResult = false;

      await _pumpMapScreen(
        tester,
        router: router,
        fallbackRoute: const TenantHomeRoute(),
      );

      final popScope = tester.widget<PopScope<dynamic>>(
        find.byWidgetPredicate((widget) => widget is PopScope),
      );
      popScope.onPopInvokedWithResult?.call(false, null);
      await tester.pump();

      expect(router.canPopCallCount, 1);
      expect(router.popCallCount, 0);
      expect(router.replaceAllRoutes, hasLength(1));
      expect(
        router.replaceAllRoutes.single.single.routeName,
        TenantHomeRoute.name,
      );
    });

    testWidgets(
        'map detail system back falls back to city map when no history exists',
        (tester) async {
      final router = _RecordingStackRouter()..canPopResult = false;

      await _pumpMapScreen(
        tester,
        router: router,
        fallbackRoute: CityMapRoute(),
        initialPoiQuery: 'event:evt-001',
      );

      final popScope = tester.widget<PopScope<dynamic>>(
        find.byWidgetPredicate((widget) => widget is PopScope),
      );
      popScope.onPopInvokedWithResult?.call(false, null);
      await tester.pump();

      expect(router.canPopCallCount, 1);
      expect(router.popCallCount, 0);
      expect(router.replaceAllRoutes, hasLength(1));
      expect(
        router.replaceAllRoutes.single.single.routeName,
        CityMapRoute.name,
      );
    });

    testWidgets(
        'map visible back returns to previous route when history exists',
        (tester) async {
      final router = _RecordingStackRouter()..canPopResult = true;

      await _pumpMapScreen(
        tester,
        router: router,
        fallbackRoute: const TenantHomeRoute(),
      );

      await tester.tap(find.byIcon(Icons.arrow_back).first);
      await tester.pump();

      expect(router.canPopCallCount, 1);
      expect(router.popCallCount, 1);
      expect(router.replaceAllRoutes, isEmpty);
    });

    testWidgets('map screen shows filter-first bottom dock and discovery tray',
        (tester) async {
      final router = _RecordingStackRouter()..canPopResult = false;

      await _pumpMapScreen(
        tester,
        router: router,
        fallbackRoute: const TenantHomeRoute(),
      );

      controller.filterOptionsStreamValue.addValue(
        PoiFilterOptions(
          categories: <PoiFilterCategory>[
            _buildCategory(
              key: 'events',
              label: 'Events',
            ),
            _buildCategory(
              key: 'praia',
              label: 'Praia',
            ),
          ],
        ),
      );
      await tester.pump();

      expect(
        find.byKey(const ValueKey<String>('map-location-floating-button')),
        findsOneWidget,
      );
      expect(find.text('Você'), findsNothing);
      expect(find.text('Buscar'), findsNothing);
      expect(find.text('Filtros'), findsNothing);
      expect(
        find.byKey(const ValueKey<String>('map-tray-surface-discovery')),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const ValueKey<String>('map-filter-cluster-wrap-collapsed'),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('map-dock-search-launcher')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('map-filter-cluster-handle')),
        findsNothing,
      );
      expect(find.text('Perto de você'), findsNothing);
      expect(find.text('Ver tudo'), findsNothing);
    });

    testWidgets('selected poi lifts card focus and hides bottom controls band',
        (tester) async {
      final router = _RecordingStackRouter()..canPopResult = false;

      await _pumpMapScreen(
        tester,
        router: router,
        fallbackRoute: const TenantHomeRoute(),
      );

      controller.selectPoi(
        _buildPoi(
          id: 'poi-selected',
          name: 'Praia das Castanheiras',
          category: CityPoiCategory.beach,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 260));

      final cardOpacity = tester.widget<AnimatedOpacity>(
        find.byKey(const ValueKey<String>('map-selected-card-opacity')),
      );

      expect(
        find.byKey(const ValueKey<String>('map-bottom-controls-opacity')),
        findsNothing,
      );
      expect(cardOpacity.opacity, 1);
      expect(
        find.byKey(const ValueKey<String>('map-location-floating-button')),
        findsOneWidget,
      );
      expect(find.text('Você'), findsNothing);
      expect(find.text('Buscar'), findsNothing);
      expect(find.text('Filtros'), findsNothing);
      expect(find.text('Perto de você'), findsNothing);
      expect(find.text('Praia das Castanheiras'), findsOneWidget);
    });

    testWidgets(
        'starting a new poi loading hides the previous selected card immediately',
        (tester) async {
      final router = _RecordingStackRouter()..canPopResult = false;

      await _pumpMapScreen(
        tester,
        router: router,
        fallbackRoute: const TenantHomeRoute(),
      );

      controller.selectPoi(
        _buildPoi(
          id: 'poi-selected',
          name: 'Praia das Castanheiras',
          category: CityPoiCategory.beach,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 260));

      expect(
        find.byKey(const ValueKey<String>('map-selected-card-opacity')),
        findsOneWidget,
      );

      controller.selectedPoiLoadingIdStreamValue.addValue('poi-loading');
      controller.hasSelectedPoiLoadingStreamValue.addValue(true);
      await tester.pump();

      expect(
        find.byKey(const ValueKey<String>('map-selected-card-opacity')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey<String>('map-bottom-controls-opacity')),
        findsNothing,
      );
    });

    testWidgets('overflowing filter cluster exposes handle and expands on tap',
        (tester) async {
      final router = _RecordingStackRouter()..canPopResult = false;

      await _pumpMapScreen(
        tester,
        router: router,
        fallbackRoute: const TenantHomeRoute(),
      );

      controller.filterOptionsStreamValue.addValue(
        PoiFilterOptions(
          categories: List<PoiFilterCategory>.generate(
            13,
            (index) => _buildCategory(
              key: 'category_$index',
              label: 'Categoria $index',
            ),
          ),
        ),
      );
      await tester.pump();

      expect(
        find.byKey(const ValueKey<String>('map-filter-cluster-handle')),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(const ValueKey<String>('map-filter-cluster-handle')),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 260));

      expect(
        find.byKey(const ValueKey<String>('map-tray-surface-filters')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('map-filter-cluster-wrap-expanded')),
        findsOneWidget,
      );
      expect(find.text('Filtrar experiências'), findsNothing);
      expect(find.text('Fechar'), findsNothing);
    });

    testWidgets(
        'dragging overflowing collapsed filter cluster upward expands it',
        (tester) async {
      final router = _RecordingStackRouter()..canPopResult = false;

      await _pumpMapScreen(
        tester,
        router: router,
        fallbackRoute: const TenantHomeRoute(),
      );

      controller.filterOptionsStreamValue.addValue(
        PoiFilterOptions(
          categories: List<PoiFilterCategory>.generate(
            13,
            (index) => _buildCategory(
              key: 'drag_category_$index',
              label: 'Categoria $index',
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.fling(
        find.byKey(const ValueKey<String>('map-tray-surface-discovery')),
        const Offset(0, -160),
        1400,
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 260));

      expect(
        find.byKey(const ValueKey<String>('map-tray-surface-filters')),
        findsOneWidget,
      );
    });

    testWidgets(
        'dragging expanded filter cluster downward collapses to discovery',
        (tester) async {
      final router = _RecordingStackRouter()..canPopResult = false;

      await _pumpMapScreen(
        tester,
        router: router,
        fallbackRoute: const TenantHomeRoute(),
      );

      controller.filterOptionsStreamValue.addValue(
        PoiFilterOptions(
          categories: List<PoiFilterCategory>.generate(
            13,
            (index) => _buildCategory(
              key: 'collapse_category_$index',
              label: 'Categoria $index',
            ),
          ),
        ),
      );
      controller.showFiltersTray();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 260));

      await tester.fling(
        find.byKey(const ValueKey<String>('map-tray-surface-filters')),
        const Offset(0, 160),
        1400,
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 260));

      expect(
        find.byKey(const ValueKey<String>('map-tray-surface-discovery')),
        findsOneWidget,
      );
      expect(find.text('Filtrar experiências'), findsNothing);
    });

    testWidgets('tapping dock search launcher opens search mode',
        (tester) async {
      final router = _RecordingStackRouter()..canPopResult = false;

      await _pumpMapScreen(
        tester,
        router: router,
        fallbackRoute: const TenantHomeRoute(),
      );

      await tester.tap(
        find.byKey(const ValueKey<String>('map-dock-search-launcher')),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 260));

      expect(
        find.byKey(const ValueKey<String>('map-tray-surface-search')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('map-dock-search-launcher')),
        findsNothing,
      );
      expect(find.text('Buscar lugares ou eventos'), findsOneWidget);
    });

    testWidgets('status banner renders above the dock instead of over it',
        (tester) async {
      final router = _RecordingStackRouter()..canPopResult = false;

      await _pumpMapScreen(
        tester,
        router: router,
        fallbackRoute: const TenantHomeRoute(),
      );

      controller.statusMessageStreamValue.addValue('Atualizando pontos...');
      await tester.pump();

      final bannerFinder = find.byKey(
        const ValueKey<String>('map-status-banner'),
      );
      final trayFinder =
          find.byKey(const ValueKey<String>('map-tray-surface-discovery'));

      expect(bannerFinder, findsOneWidget);
      expect(trayFinder, findsOneWidget);
      expect(
        tester.getBottomLeft(bannerFinder).dy,
        lessThan(tester.getTopLeft(trayFinder).dy),
      );
    });

    testWidgets(
        'location utility stays circular and dock search launcher keeps tray height',
        (tester) async {
      final router = _RecordingStackRouter()..canPopResult = false;

      await _pumpMapScreen(
        tester,
        router: router,
        fallbackRoute: const TenantHomeRoute(),
      );

      final locationSize = tester.getSize(
        find.byKey(const ValueKey<String>('map-location-floating-button')),
      );
      final searchSize = tester.getSize(
        find.byKey(const ValueKey<String>('map-dock-search-launcher')),
      );

      expect(locationSize.width, locationSize.height);
      expect(searchSize.width, searchSize.height);
      expect(searchSize.height, 48);
    });

    testWidgets(
        'selected card height follows the selected poi even when stack metadata exists',
        (tester) async {
      final router = _RecordingStackRouter()..canPopResult = false;
      final firstPoi = _buildPoi(
        id: 'stack-a',
        name: 'Primeiro',
        category: CityPoiCategory.beach,
        stackKey: 'stack-key',
        stackCount: 2,
      );
      final secondPoi = _buildPoi(
        id: 'stack-b',
        name: 'Segundo',
        category: CityPoiCategory.restaurant,
        stackKey: 'stack-key',
        stackCount: 2,
      );
      final selectedPoi = _buildPoi(
        id: 'stack-a',
        name: 'Primeiro',
        category: CityPoiCategory.beach,
        stackKey: 'stack-key',
        stackCount: 2,
        stackItems: [firstPoi, secondPoi],
      );

      controller.selectPoi(selectedPoi);
      controller.updatePoiDeckHeight('stack-a', 320);
      controller.updatePoiDeckHeight('stack-b', 440);

      await _pumpMapScreen(
        tester,
        router: router,
        fallbackRoute: const TenantHomeRoute(),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 260));

      final deckFinder =
          find.byKey(const ValueKey<String>('poi-deck-container'));
      expect(deckFinder, findsOneWidget);
      final selectedMeasuredHeight = controller.getPoiDeckHeight('stack-a');
      expect(selectedMeasuredHeight, isNotNull);
      expect(
        tester.getSize(deckFinder).height,
        closeTo(selectedMeasuredHeight!, 0.1),
      );
      expect(
        tester.getSize(deckFinder).height,
        lessThan(controller.getPoiDeckHeight('stack-b')!),
      );
    });

    testWidgets(
        'filtered deck height follows the tallest visible card instead of only the selected poi',
        (tester) async {
      final router = _RecordingStackRouter()..canPopResult = false;
      final selectedPoi = _buildPoi(
        id: 'poi-near',
        name: 'Mais perto',
        distanceMeters: 120,
      );
      final tallerAdjacentPoi = _buildPoi(
        id: 'poi-far',
        name: 'Mais longe',
        distanceMeters: 900,
      );

      controller.filteredPoisStreamValue.addValue(<CityPoiModel>[
        selectedPoi,
        tallerAdjacentPoi,
      ]);
      controller.mapTrayModeStreamValue.addValue(MapTrayMode.filterResults);
      controller.selectPoi(selectedPoi);
      controller.updatePoiDeckHeight('poi-near', 320);
      controller.updatePoiDeckHeight('poi-far', 440);

      await _pumpMapScreen(
        tester,
        router: router,
        fallbackRoute: const TenantHomeRoute(),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 260));

      final viewportHeight =
          tester.view.physicalSize.height / tester.view.devicePixelRatio;
      final expectedDeckHeight = 440.0.clamp(
        280.0,
        (viewportHeight * 0.68).clamp(380.0, 520.0).toDouble(),
      );
      final deckFinder =
          find.byKey(const ValueKey<String>('poi-deck-container'));
      expect(deckFinder, findsOneWidget);
      expect(tester.getSize(deckFinder).height, expectedDeckHeight);
    });

    testWidgets(
        'cluster picker popover stays near map while discovery dock remains active',
        (tester) async {
      final router = _RecordingStackRouter()..canPopResult = false;

      controller.showClusterPicker(
        <CityPoiModel>[
          _buildPoi(id: 'poi-a', name: 'Casa A'),
          _buildPoi(id: 'poi-b', name: 'Casa B'),
        ],
        anchorCoordinate: _buildPoi(id: 'poi-anchor').coordinate,
      );

      await _pumpMapScreen(
        tester,
        router: router,
        fallbackRoute: const TenantHomeRoute(),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 260));

      expect(
        find.byKey(const ValueKey<String>('map-cluster-picker-popover')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('map-tray-surface-discovery')),
        findsOneWidget,
      );
      expect(find.text('Casa A'), findsOneWidget);
      expect(find.text('Casa B'), findsOneWidget);
    });

    testWidgets('search tray shows Nessa área with a scrollable result list',
        (tester) async {
      final router = _RecordingStackRouter()..canPopResult = false;

      await _pumpMapScreen(
        tester,
        router: router,
        fallbackRoute: const TenantHomeRoute(),
      );

      controller.mapTrayModeStreamValue.addValue(MapTrayMode.search);
      controller.filteredPoisStreamValue.addValue(
        List<CityPoiModel>.generate(
          6,
          (index) => _buildPoi(
            id: 'poi-search-$index',
            name: 'Resultado $index',
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Nessa área'), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('map-search-results-scroll')),
        findsOneWidget,
      );
      expect(find.text('Resultado 0'), findsOneWidget);
      expect(find.text('Resultado 5'), findsOneWidget);
    });

    testWidgets(
        'filter results tray keeps filters on top and orders nearest first',
        (tester) async {
      final router = _RecordingStackRouter()..canPopResult = false;

      await _pumpMapScreen(
        tester,
        router: router,
        fallbackRoute: const TenantHomeRoute(),
      );

      controller.mapTrayModeStreamValue.addValue(MapTrayMode.filterResults);
      controller.filterOptionsStreamValue.addValue(
        PoiFilterOptions(
          categories: <PoiFilterCategory>[
            _buildCategory(key: 'event', label: 'Eventos'),
            _buildCategory(key: 'beach', label: 'Praia'),
          ],
        ),
      );
      controller.activeCatalogFilterKeyStreamValue.addValue('beach');
      controller.activeFilterLabelStreamValue.addValue('Praia');
      controller.filteredPoisStreamValue.addValue(
        <CityPoiModel>[
          _buildPoi(id: 'poi-far', name: 'Mais longe').copyWith(
            distanceMetersValue: _buildDistanceValue(900),
          ),
          _buildPoi(id: 'poi-near', name: 'Mais perto').copyWith(
            distanceMetersValue: _buildDistanceValue(120),
          ),
        ],
      );
      await tester.pump();

      expect(find.text('Mais próximos de você'), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('map-filter-results-scroll')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('map-selected-filter-chip')),
        findsOneWidget,
      );

      final nearTop = tester.getTopLeft(find.text('Mais perto')).dy;
      final farTop = tester.getTopLeft(find.text('Mais longe')).dy;
      expect(nearTop, lessThan(farTop));
    });

    testWidgets(
        'filter results tray orders event filters by next start time before distance',
        (tester) async {
      final reference = DateTime.now().toUtc();
      final router = _RecordingStackRouter()..canPopResult = false;

      await _pumpMapScreen(
        tester,
        router: router,
        fallbackRoute: const TenantHomeRoute(),
      );

      controller.mapTrayModeStreamValue.addValue(MapTrayMode.filterResults);
      controller.activeCategoryKeysStreamValue
          .addValue(const <String>{'event'});
      controller.filterOptionsStreamValue.addValue(
        PoiFilterOptions(
          categories: <PoiFilterCategory>[
            _buildCategory(key: 'event', label: 'Eventos'),
          ],
        ),
      );
      controller.activeCatalogFilterKeyStreamValue.addValue('event');
      controller.activeFilterLabelStreamValue.addValue('Eventos');
      controller.filteredPoisStreamValue.addValue(
        <CityPoiModel>[
          _buildPoi(
            id: 'poi-later-near',
            name: 'Mais perto depois',
            refType: 'event',
            refId: 'event-2',
            distanceMeters: 120,
            timeStart: reference.add(const Duration(hours: 6)),
          ),
          _buildPoi(
            id: 'poi-soon-far',
            name: 'Mais longe antes',
            refType: 'event',
            refId: 'event-1',
            distanceMeters: 900,
            timeStart: reference.add(const Duration(hours: 2)),
          ),
          _buildPoi(
            id: 'poi-past-nearest',
            name: 'Já terminou',
            refType: 'event',
            refId: 'event-3',
            distanceMeters: 30,
            timeStart: reference.subtract(const Duration(hours: 5)),
          ),
        ],
      );
      await tester.pump();

      expect(find.text('Próximos eventos'), findsOneWidget);
      expect(find.text('Mais próximos de você'), findsNothing);

      final soonTop = tester.getTopLeft(find.text('Mais longe antes')).dy;
      final laterTop = tester.getTopLeft(find.text('Mais perto depois')).dy;
      final pastTop = tester.getTopLeft(find.text('Já terminou')).dy;
      expect(soonTop, lessThan(laterTop));
      expect(laterTop, lessThan(pastTop));
    });

    testWidgets('selected filter state exposes an explicit clear affordance',
        (tester) async {
      final router = _RecordingStackRouter()..canPopResult = false;

      await _pumpMapScreen(
        tester,
        router: router,
        fallbackRoute: const TenantHomeRoute(),
      );

      controller.filterOptionsStreamValue.addValue(
        PoiFilterOptions(
          categories: <PoiFilterCategory>[
            _buildCategory(
              key: 'restaurant',
              label: 'Restaurantes',
            ),
          ],
        ),
      );
      controller.activeCatalogFilterKeyStreamValue.addValue('restaurant');
      controller.activeFilterLabelStreamValue.addValue('Restaurantes');
      await tester.pump();

      expect(find.text('Restaurantes'), findsWidgets);
      expect(
        find.byKey(const ValueKey<String>('map-selected-filter-clear')),
        findsOneWidget,
      );

      await tester
          .tap(find.byKey(const ValueKey<String>('map-selected-filter-clear')));
      await tester.pump();

      expect(controller.activeFilterLabelStreamValue.value, isNull);
      expect(
        find.byKey(
          const ValueKey<String>('map-filter-cluster-wrap-collapsed'),
        ),
        findsOneWidget,
      );
    });

    testWidgets(
        'selected filter chip shows spinner while filter update is pending',
        (tester) async {
      final router = _RecordingStackRouter()..canPopResult = false;

      await _pumpMapScreen(
        tester,
        router: router,
        fallbackRoute: const TenantHomeRoute(),
      );

      controller.filterOptionsStreamValue.addValue(
        PoiFilterOptions(
          categories: <PoiFilterCategory>[
            _buildCategory(
              key: 'events',
              label: 'Eventos',
            ),
          ],
        ),
      );
      controller.activeCatalogFilterKeyStreamValue.addValue('events');
      controller.pendingFilterLabelStreamValue.addValue('Eventos');
      controller.filterInteractionLockedStreamValue.addValue(true);
      await tester.pump();

      expect(
        find.byKey(const ValueKey<String>('map-selected-filter-loading')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('map-selected-filter-clear')),
        findsNothing,
      );
    });

    testWidgets(
        'selected filter chip adopts override colors for icon-based backend category',
        (tester) async {
      final router = _RecordingStackRouter()..canPopResult = false;

      await _pumpMapScreen(
        tester,
        router: router,
        fallbackRoute: const TenantHomeRoute(),
      );

      controller.filterOptionsStreamValue.addValue(
        PoiFilterOptions(
          categories: <PoiFilterCategory>[
            _buildCategory(
              key: 'eventos',
              label: 'Eventos',
              overrideMarker: true,
              markerOverride: _buildIconMarkerOverride(
                icon: 'music_note',
                colorHex: '#0055AA',
                iconColorHex: '#F3F7FF',
              ),
            ),
          ],
        ),
      );
      controller.activeCatalogFilterKeyStreamValue.addValue('eventos');
      controller.activeFilterLabelStreamValue.addValue('Eventos');
      await tester.pump();

      final chipDecoration = tester.widget<DecoratedBox>(
        find.byKey(const ValueKey<String>('map-selected-filter-chip')),
      );
      final boxDecoration = chipDecoration.decoration as BoxDecoration;
      expect(boxDecoration.color, const Color(0xFF0055AA));

      final selectedIcon = tester.widget<Icon>(
        find.descendant(
          of: find.byKey(const ValueKey<String>('map-selected-filter-chip')),
          matching: find.byIcon(Icons.music_note),
        ),
      );
      expect(selectedIcon.color, const Color(0xFFF3F7FF));
    });

    testWidgets(
        'selected filter chip keeps backend category icon while clear is pending',
        (tester) async {
      final router = _RecordingStackRouter()..canPopResult = false;

      await _pumpMapScreen(
        tester,
        router: router,
        fallbackRoute: const TenantHomeRoute(),
      );

      controller.filterOptionsStreamValue.addValue(
        PoiFilterOptions(
          categories: <PoiFilterCategory>[
            _buildCategory(
              key: 'eventos',
              label: 'Eventos',
              overrideMarker: true,
              markerOverride: _buildIconMarkerOverride(
                icon: 'music_note',
                colorHex: '#0055AA',
                iconColorHex: '#F3F7FF',
              ),
            ),
          ],
        ),
      );
      controller.appliedCatalogFilterKeyStreamValue.addValue('eventos');
      controller.pendingFilterLabelStreamValue.addValue('Eventos');
      controller.filterInteractionLockedStreamValue.addValue(true);
      await tester.pump();

      expect(
        find.byKey(const ValueKey<String>('map-selected-filter-loading')),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const ValueKey<String>('map-selected-filter-chip')),
          matching: find.byIcon(Icons.music_note),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const ValueKey<String>('map-selected-filter-chip')),
          matching: find.byIcon(Icons.tune_rounded),
        ),
        findsNothing,
      );
    });

    testWidgets(
        'active filter keeps backend position instead of jumping to the first slot',
        (tester) async {
      final router = _RecordingStackRouter()..canPopResult = false;

      await _pumpMapScreen(
        tester,
        router: router,
        fallbackRoute: const TenantHomeRoute(),
      );

      controller.filterOptionsStreamValue.addValue(
        PoiFilterOptions(
          categories: <PoiFilterCategory>[
            _buildCategory(
              key: 'events',
              label: 'Eventos',
            ),
            _buildCategory(
              key: 'praia',
              label: 'Praia',
            ),
            _buildCategory(
              key: 'food',
              label: 'Gastronomia',
            ),
          ],
        ),
      );
      controller.activeCatalogFilterKeyStreamValue.addValue('food');
      controller.activeFilterLabelStreamValue.addValue('Gastronomia');
      await tester.pump();

      final positions = <String, Offset>{
        'events': tester.getTopLeft(
          find.byKey(const ValueKey<String>('map-compact-filter-chip-events')),
        ),
        'praia': tester.getTopLeft(
          find.byKey(const ValueKey<String>('map-compact-filter-chip-praia')),
        ),
        'food': tester.getTopLeft(
          find.byKey(const ValueKey<String>('map-selected-filter-chip')),
        ),
      };

      final visualOrder = positions.entries.toList()
        ..sort((left, right) {
          final dy = left.value.dy.compareTo(right.value.dy);
          if (dy != 0) {
            return dy;
          }
          return left.value.dx.compareTo(right.value.dx);
        });

      expect(
        visualOrder.map((entry) => entry.key).toList(growable: false),
        const <String>['events', 'praia', 'food'],
      );
    });

    testWidgets(
        'expanded filter cluster uses only the handle as the collapse affordance',
        (tester) async {
      final router = _RecordingStackRouter()..canPopResult = false;

      await _pumpMapScreen(
        tester,
        router: router,
        fallbackRoute: const TenantHomeRoute(),
      );

      controller.filterOptionsStreamValue.addValue(
        PoiFilterOptions(
          categories: List<PoiFilterCategory>.generate(
            13,
            (index) => _buildCategory(
              key: 'expanded_$index',
              label: 'Expanded $index',
            ),
          ),
        ),
      );
      controller.showFiltersTray();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 260));

      expect(
        find.byKey(const ValueKey<String>('map-filter-cluster-handle')),
        findsOneWidget,
      );
      expect(find.text('Fechar'), findsNothing);
      expect(find.text('Filtrar experiências'), findsNothing);
    });

    testWidgets('filter tray renders only backend catalog entries',
        (tester) async {
      final router = _RecordingStackRouter()..canPopResult = false;

      await _pumpMapScreen(
        tester,
        router: router,
        fallbackRoute: const TenantHomeRoute(),
      );

      controller.filterOptionsStreamValue.addValue(
        PoiFilterOptions(
          categories: <PoiFilterCategory>[
            _buildCategory(
              key: 'curated_backend',
              label: 'Filtro Curado',
            ),
          ],
        ),
      );
      controller.filteredPoisStreamValue.addValue(
        <CityPoiModel>[
          _buildPoi(
            id: 'beach-poi',
            name: 'Praia do Morro',
            category: CityPoiCategory.beach,
          ),
          _buildPoi(
            id: 'restaurant-poi',
            name: 'Cantinho da Moqueca',
            category: CityPoiCategory.restaurant,
          ),
        ],
      );
      controller.showFiltersTray();
      await tester.pump();

      expect(
        find.byKey(
          const ValueKey<String>('map-compact-filter-chip-curated_backend'),
        ),
        findsOneWidget,
      );
      expect(find.text('Praias'), findsNothing);
      expect(find.text('Restaurantes'), findsNothing);
    });

    test(
        'visible catalog categories preserve backend entries and honor tenant ordering',
        () {
      final mapRepository = _FakeCityMapRepository();
      final poiRepository = _buildPoiRepository(mapRepository: mapRepository);
      final userLocationRepository = _FakeUserLocationRepository();
      final telemetry = _FakeTelemetryRepository();
      final baseAppData = _buildAppData();
      final orderedAppData = AppData(
        platformType: baseAppData.platformType,
        portValue: baseAppData.portValue,
        hostnameValue: baseAppData.hostnameValue,
        hrefValue: baseAppData.hrefValue,
        deviceValue: baseAppData.deviceValue,
        nameValue: baseAppData.nameValue,
        typeValue: baseAppData.typeValue,
        themeDataSettings: baseAppData.themeDataSettings,
        tenantIdValue: baseAppData.tenantIdValue,
        profileTypeRegistry: baseAppData.profileTypeRegistry,
        mainDomainValue: baseAppData.mainDomainValue,
        domains: baseAppData.domains,
        appDomains: baseAppData.appDomains,
        telemetrySettings: baseAppData.telemetrySettings,
        telemetryContextSettings: baseAppData.telemetryContextSettings,
        firebaseSettings: baseAppData.firebaseSettings,
        pushSettings: baseAppData.pushSettings,
        tenantDefaultOrigin: baseAppData.tenantDefaultOrigin,
        mapRadiusMinMetersValue: baseAppData.mapRadiusMinMetersValue,
        mapRadiusDefaultMetersValue: baseAppData.mapRadiusDefaultMetersValue,
        mapRadiusMaxMetersValue: baseAppData.mapRadiusMaxMetersValue,
        mapFilterCatalogKeysValue: AppDataMapFilterCatalogKeysValue(
          const <String>['events', 'praia'],
        ),
        mainIconLightUrl: baseAppData.mainIconLightUrl,
        mainIconDarkUrl: baseAppData.mainIconDarkUrl,
        mainColor: baseAppData.mainColor,
        mainLogoLightUrl: baseAppData.mainLogoLightUrl,
        mainLogoDarkUrl: baseAppData.mainLogoDarkUrl,
      );
      final orderedController = _buildMapController(
        poiRepository: poiRepository,
        userLocationRepository: userLocationRepository,
        telemetryRepository: telemetry,
        appData: orderedAppData,
      );

      final visibleCategories = orderedController.visibleCatalogCategories(
        PoiFilterOptions(
          categories: <PoiFilterCategory>[
            _buildCategory(
              key: 'restaurant',
              label: 'Restaurantes',
            ),
            _buildCategory(
              key: 'praia',
              label: 'Praia',
            ),
            _buildCategory(
              key: 'events',
              label: 'Events',
            ),
          ],
        ),
      );

      expect(
        visibleCategories.map((category) => category.key).toList(),
        equals(<String>['events', 'praia', 'restaurant']),
      );
      orderedController.onDispose();
    });

    testWidgets(
        'showFiltersTray retries backend filter fetch when catalog is still missing',
        (tester) async {
      final mapRepository = _FakeCityMapRepository()
        ..throwOnFetchFilters = true;
      final poiRepository = _buildPoiRepository(mapRepository: mapRepository);
      final userLocationRepository = _FakeUserLocationRepository();
      final telemetry = _FakeTelemetryRepository();
      final mapHandle = _FakeMapHandle();
      final retryController = _buildMapController(
        poiRepository: poiRepository,
        userLocationRepository: userLocationRepository,
        telemetryRepository: telemetry,
        mapHandle: mapHandle,
      );

      await retryController.loadFilters(force: true);
      expect(mapRepository.fetchFiltersCallCount, 1);
      expect(retryController.filterOptionsStreamValue.value, isNull);

      mapRepository
        ..throwOnFetchFilters = false
        ..nextFilterOptions = PoiFilterOptions(
          categories: <PoiFilterCategory>[
            _buildCategory(
              key: 'events',
              label: 'Events',
            ),
          ],
        );

      retryController.showFiltersTray();
      await tester.pump();
      await tester.pump();

      expect(mapRepository.fetchFiltersCallCount, 2);
      expect(
        retryController.filterOptionsStreamValue.value?.categories
            .map((category) => category.key)
            .toList(),
        equals(<String>['events']),
      );
      await retryController.onDispose();
    });

    testWidgets(
        'ver detalhes pushes partner detail route for account profile poi',
        (tester) async {
      final router = _RecordingStackRouter()..canPopResult = false;
      final poi = _buildPoi(
        id: 'poi-partner',
        name: 'Casa Marracini',
        refType: 'account_profile',
        refId: '507f1f77bcf86cd799439011',
        refSlug: 'casa-marracini',
        refPath: '/parceiro/casa-marracini',
        category: CityPoiCategory.restaurant,
      );

      controller.selectPoi(poi);

      await _pumpPoiDetailDeck(
        tester,
        controller: controller,
        router: router,
      );

      await tester.tap(find.text('Ver detalhes'));
      await tester.pump();

      expect(router.pushedRoutes, hasLength(1));
      final route = router.pushedRoutes.single;
      expect(route, isA<PartnerDetailRoute>());
      expect((route as PartnerDetailRoute).args?.slug, 'casa-marracini');
    });

    testWidgets('ver detalhes pushes static asset detail route for static poi',
        (tester) async {
      final router = _RecordingStackRouter()..canPopResult = false;
      final poi = _buildPoi(
        id: 'poi-static',
        name: 'Praia das Virtudes',
        refType: 'static',
        refId: 'asset-77',
        refPath: '/static/praia-das-virtudes',
      );

      controller.selectPoi(poi);

      await _pumpPoiDetailDeck(
        tester,
        controller: controller,
        router: router,
      );

      await tester.tap(find.text('Ver detalhes'));
      await tester.pump();

      expect(router.pushedRoutes, hasLength(1));
      final route = router.pushedRoutes.single;
      expect(route, isA<StaticAssetDetailRoute>());
      expect((route as StaticAssetDetailRoute).args?.assetRef, 'asset-77');
    });

    testWidgets('event cards keep the same CTA labels as other pois',
        (tester) async {
      final router = _RecordingStackRouter()..canPopResult = false;
      final poi = _buildPoi(
        id: 'poi-event',
        name: 'Show na Praia',
        refType: 'event',
        refId: 'event-1',
        refSlug: 'show-na-praia',
      );

      controller.selectPoi(poi);

      await _pumpPoiDetailDeck(
        tester,
        controller: controller,
        router: router,
      );

      expect(find.text('Traçar rota'), findsOneWidget);
      expect(find.text('Ver detalhes'), findsOneWidget);
    });

    testWidgets('event cards use the canonical invite icon in the map deck',
        (tester) async {
      final router = _RecordingStackRouter()..canPopResult = false;
      final poi = _buildPoi(
        id: 'poi-event',
        name: 'Show na Praia',
        refType: 'event',
        refId: 'event-1',
        refSlug: 'show-na-praia',
      );

      controller.selectPoi(poi);

      await _pumpPoiDetailDeck(
        tester,
        controller: controller,
        router: router,
      );

      expect(find.byTooltip('Convidar'), findsOneWidget);
      expect(find.byIcon(BooraIcons.inviteSolid), findsOneWidget);
    });

    testWidgets('close button aligns with the top of the selected card',
        (tester) async {
      final router = _RecordingStackRouter()..canPopResult = false;
      final poi = _buildPoi(
        id: 'poi-event',
        name: 'Show na Praia',
        refType: 'event',
        refId: 'event-1',
        refSlug: 'show-na-praia',
      );

      controller.selectPoi(poi);

      await _pumpPoiDetailDeck(
        tester,
        controller: controller,
        router: router,
      );

      final cardTop = tester
          .getTopLeft(
              find.byKey(const ValueKey<String>('poi-detail-card-visual')))
          .dy;
      final cardRight = tester
          .getTopRight(
              find.byKey(const ValueKey<String>('poi-detail-card-visual')))
          .dx;
      final closeRect = tester.getRect(find.byTooltip('Fechar'));
      final closeTop = closeRect.top;
      final closeLeft = tester.getTopLeft(find.byTooltip('Fechar')).dx;
      final closeCenterY = closeRect.center.dy;

      expect(closeTop - cardTop, inInclusiveRange(0, 40));
      expect((closeCenterY - (cardTop + 24)).abs(), lessThanOrEqualTo(16));
      expect(cardRight - closeLeft, inInclusiveRange(0, 72));
    });

    test(
        'static poi hydration merges cover, type, and description from details',
        () async {
      final localStaticAssetsRepository = _FakeStaticAssetsRepository();
      final localController = _buildMapController(
        poiRepository: _buildPoiRepository(
          mapRepository: mapRepository,
          staticAssetsRepository: localStaticAssetsRepository,
        ),
        userLocationRepository: userLocationRepository,
        telemetryRepository: telemetry,
        appData: _buildAppData(),
      );
      addTearDown(() async {
        await localController.onDispose();
      });
      final poi = _buildPoi(
        id: 'poi-static',
        name: 'Praia das Virtudes',
        description: 'Ponto de interesse no mapa',
        refType: 'static',
        refId: 'asset-77',
      );
      final asset = PublicStaticAssetModel(
        idValue: PublicStaticAssetIdValue(defaultValue: 'asset-77'),
        profileTypeValue:
            PublicStaticAssetTypeValue(defaultValue: 'beach_club'),
        displayNameValue:
            PublicStaticAssetNameValue(defaultValue: 'Praia das Virtudes'),
        slugValue: SlugValue()..parse('praia-das-virtudes'),
        coverValue: ThumbUriValue(
            defaultValue: Uri.parse('https://example.com/praia-cover.png')),
        contentValue: PublicStaticAssetDescriptionValue(
          defaultValue:
              '<p>Área de praia com quiosques e vista para o mar.</p>',
          isRequired: false,
        ),
      );
      localStaticAssetsRepository.assetsByRef['asset-77'] = asset;

      await localController.handleMarkerTap(poi);

      final selectedPoi = localController.selectedPoiStreamValue.value;
      expect(selectedPoi, isNotNull);
      expect(selectedPoi!.coverImageUri, 'https://example.com/praia-cover.png');
      expect(selectedPoi.resolvedCategoryLabel, 'beach_club');
      expect(
        selectedPoi.description,
        'Área de praia com quiosques e vista para o mar.',
      );
      expect(selectedPoi.refSlug, 'praia-das-virtudes');
      expect(selectedPoi.refPath, '/static/praia-das-virtudes');
    });

    testWidgets(
        'selected poi from filter results uses filtered carousel and keeps tapped item active',
        (tester) async {
      final router = _RecordingStackRouter()..canPopResult = false;
      final fakeMapHandle = _FakeMapHandle();
      final localController = _buildMapController(
        poiRepository: _buildPoiRepository(mapRepository: mapRepository),
        userLocationRepository: userLocationRepository,
        telemetryRepository: telemetry,
        mapHandle: fakeMapHandle,
        appData: _buildAppData(),
      );
      addTearDown(() async {
        await localController.onDispose();
        fakeMapHandle.dispose();
      });
      final farPoi = _buildPoi(
        id: 'poi-far',
        name: 'Mais longe',
        distanceMeters: 900,
      );
      final selectedPoi = _buildPoi(
        id: 'poi-near',
        name: 'Mais perto',
        distanceMeters: 120,
      );

      localController.filteredPoisStreamValue.addValue(<CityPoiModel>[
        farPoi,
        selectedPoi,
      ]);
      localController.mapTrayModeStreamValue
          .addValue(MapTrayMode.filterResults);
      localController.selectPoi(selectedPoi);

      await _pumpPoiDetailDeck(
        tester,
        controller: localController,
        router: router,
      );

      expect(find.byType(PageView), findsOneWidget);
      expect(find.text('Mais perto'), findsOneWidget);
      expect(localController.poiDeckIndexStreamValue.value, 0);
      final pageView = tester.widget<PageView>(find.byType(PageView));
      expect(pageView.controller?.viewportFraction, 0.82);
      final deckWidth = tester
          .getSize(find.byKey(const ValueKey<String>('poi-deck-container')))
          .width;
      final scaffoldWidth = tester.getSize(find.byType(Scaffold)).width;
      expect(deckWidth, scaffoldWidth);

      await tester.fling(find.byType(PageView), const Offset(-320, 0), 1200);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 320));

      expect(localController.poiDeckIndexStreamValue.value, 1);
      expect(localController.selectedPoiStreamValue.value?.id, 'poi-far');
      expect(find.text('Mais longe'), findsOneWidget);
    });

    testWidgets(
        'dragging filtered carousel with remote-cover cards does not throw while the current card leaves the viewport',
        (tester) async {
      final router = _RecordingStackRouter()..canPopResult = false;
      final fakeMapHandle = _FakeMapHandle();
      final localController = _buildMapController(
        poiRepository: _buildPoiRepository(mapRepository: mapRepository),
        userLocationRepository: userLocationRepository,
        telemetryRepository: telemetry,
        mapHandle: fakeMapHandle,
        appData: _buildAppData(),
      );
      addTearDown(() async {
        await localController.onDispose();
        fakeMapHandle.dispose();
      });

      final firstPoi = _buildPoi(
        id: 'poi-image-a',
        name: 'Praia das Virtudes',
        coverImageUri: 'https://tenant.test/media/praia-das-virtudes-cover.png',
      );
      final secondPoi = _buildPoi(
        id: 'poi-image-b',
        name: 'Praia das Castanheiras',
        coverImageUri:
            'https://tenant.test/media/praia-das-castanheiras-cover.png',
      );

      localController.filteredPoisStreamValue.addValue(<CityPoiModel>[
        firstPoi,
        secondPoi,
      ]);
      localController.mapTrayModeStreamValue
          .addValue(MapTrayMode.filterResults);
      localController.selectPoi(firstPoi);

      await _pumpPoiDetailDeck(
        tester,
        controller: localController,
        router: router,
      );
      await tester.pump(const Duration(milliseconds: 300));

      final pageView = find.byType(PageView);
      expect(pageView, findsOneWidget);

      await tester.drag(pageView, const Offset(-140, 0));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 180));

      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'filtered carousel lazily hydrates semi-visible cards and reuses cached hydration',
        (tester) async {
      final router = _RecordingStackRouter()..canPopResult = false;
      final fakeMapHandle = _FakeMapHandle();
      final localStaticAssetsRepository = _FakeStaticAssetsRepository();
      final localController = _buildMapController(
        poiRepository: _buildPoiRepository(
          mapRepository: mapRepository,
          staticAssetsRepository: localStaticAssetsRepository,
        ),
        userLocationRepository: userLocationRepository,
        telemetryRepository: telemetry,
        mapHandle: fakeMapHandle,
        appData: _buildAppData(),
      );
      addTearDown(() async {
        await localController.onDispose();
        fakeMapHandle.dispose();
      });

      final firstPoi = _buildPoi(
        id: 'poi-static-a',
        name: 'Praia das Virtudes',
        refType: 'static',
        refId: 'asset-1',
        distanceMeters: 120,
      );
      final selectedPoi = _buildPoi(
        id: 'poi-static-b',
        name: 'Praia das Castanheiras',
        refType: 'static',
        refId: 'asset-2',
        distanceMeters: 220,
      );
      final thirdPoi = _buildPoi(
        id: 'poi-static-c',
        name: 'Praia do Meio',
        refType: 'static',
        refId: 'asset-3',
        distanceMeters: 320,
      );

      localStaticAssetsRepository.assetsByRef['asset-1'] =
          _buildPublicStaticAsset(
        id: 'asset-1',
        name: 'Praia das Virtudes',
        slug: 'praia-das-virtudes',
        coverUrl: 'https://tenant.test/media/virtudes-cover.png',
        description: 'Descricao factual da Praia das Virtudes.',
      );
      localStaticAssetsRepository.assetsByRef['asset-2'] =
          _buildPublicStaticAsset(
        id: 'asset-2',
        name: 'Praia das Castanheiras',
        slug: 'praia-das-castanheiras',
        coverUrl: 'https://tenant.test/media/castanheiras-cover.png',
        description: 'Descricao factual da Praia das Castanheiras.',
      );
      localStaticAssetsRepository.assetsByRef['asset-3'] =
          _buildPublicStaticAsset(
        id: 'asset-3',
        name: 'Praia do Meio',
        slug: 'praia-do-meio',
        coverUrl: 'https://tenant.test/media/meio-cover.png',
        description: 'Descricao factual da Praia do Meio.',
      );

      localController.filteredPoisStreamValue.addValue(<CityPoiModel>[
        firstPoi,
        selectedPoi,
        thirdPoi,
      ]);
      localController.mapTrayModeStreamValue
          .addValue(MapTrayMode.filterResults);

      await localController.handleMarkerTap(selectedPoi);
      expect(
        localController.hydratedStaticAssetForPoi(selectedPoi),
        isNotNull,
      );

      await _pumpPoiDetailDeck(
        tester,
        controller: localController,
        router: router,
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 180));

      expect(localController.hydratedStaticAssetForPoi(firstPoi), isNotNull);
      expect(localController.hydratedStaticAssetForPoi(thirdPoi), isNotNull);

      final hydratedDeckPois = localController.deckPoisForSelectedPoi(
        localController.selectedPoiStreamValue.value!,
      );
      expect(
        hydratedDeckPois
            .firstWhere((poi) => poi.id == firstPoi.id)
            .coverImageUri,
        'https://tenant.test/media/virtudes-cover.png',
      );
      expect(
        hydratedDeckPois
            .firstWhere((poi) => poi.id == thirdPoi.id)
            .coverImageUri,
        'https://tenant.test/media/meio-cover.png',
      );

      expect(
        localStaticAssetsRepository.requestedRefs
            .where((ref) => ref == 'asset-1')
            .length,
        1,
      );
      expect(
        localStaticAssetsRepository.requestedRefs
            .where((ref) => ref == 'asset-2')
            .length,
        1,
      );
      expect(
        localStaticAssetsRepository.requestedRefs
            .where((ref) => ref == 'asset-3')
            .length,
        1,
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 180));

      expect(
        localStaticAssetsRepository.requestedRefs
            .where((ref) => ref == 'asset-1')
            .length,
        1,
      );
      expect(
        localStaticAssetsRepository.requestedRefs
            .where((ref) => ref == 'asset-3')
            .length,
        1,
      );
    });
  });

  group('MapScreenController late hydration dependencies', () {
    late _FakeCityMapRepository mapRepository;
    late _FakeUserLocationRepository userLocationRepository;
    late _FakeTelemetryRepository telemetry;

    setUp(() async {
      await GetIt.I.reset(dispose: false);
      mapRepository = _FakeCityMapRepository();
      userLocationRepository = _FakeUserLocationRepository();
      telemetry = _FakeTelemetryRepository();
    });

    tearDown(() async {
      mapRepository.dispose();
      userLocationRepository.dispose();
      await GetIt.I.reset(dispose: false);
    });

    test(
        'marker tap still hydrates account profiles when the profile repository is registered after poi repository construction',
        () async {
      final accountProfilesRepository = _FakeAccountProfilesRepository();
      final poiRepository = PoiRepository(dataSource: mapRepository);
      final fakeMapHandle = _FakeMapHandle();
      final controller = _buildMapController(
        poiRepository: poiRepository,
        userLocationRepository: userLocationRepository,
        telemetryRepository: telemetry,
        mapHandle: fakeMapHandle,
        appData: _buildAppData(),
      );
      addTearDown(() async {
        await controller.onDispose();
        fakeMapHandle.dispose();
      });

      GetIt.I.registerSingleton<AccountProfilesRepositoryContract>(
        accountProfilesRepository,
      );
      accountProfilesRepository.profilesBySlug['casa-marracini'] =
          buildAccountProfileModelFromPrimitives(
        id: '507f1f77bcf86cd799439011',
        name: 'Casa Marracini',
        slug: 'casa-marracini',
        type: 'beach_club_custom',
        avatarUrl: 'https://tenant.test/media/casa-avatar.png',
        coverUrl: 'https://tenant.test/media/casa-cover.png',
      );

      final poi = _buildPoi(
        id: 'poi-partner',
        name: 'Casa Marracini',
        refType: 'account_profile',
        refId: '507f1f77bcf86cd799439011',
        refSlug: 'casa-marracini',
        refPath: '/parceiro/casa-marracini',
      );

      await controller.handleMarkerTap(poi);
      await _flushMicrotasks();

      expect(controller.selectedPoiStreamValue.value?.id, 'poi-partner');
      expect(
        controller.selectedPoiStreamValue.value?.visual?.imageUri,
        'https://tenant.test/media/casa-avatar.png',
      );
      expect(
        controller.selectedPoiStreamValue.value?.coverImageUri,
        'https://tenant.test/media/casa-cover.png',
      );
    });

    test(
        'marker tap still hydrates static assets when the static assets repository is registered after poi repository construction',
        () async {
      final staticAssetsRepository = _FakeStaticAssetsRepository();
      final poiRepository = PoiRepository(dataSource: mapRepository);
      final fakeMapHandle = _FakeMapHandle();
      final controller = _buildMapController(
        poiRepository: poiRepository,
        userLocationRepository: userLocationRepository,
        telemetryRepository: telemetry,
        mapHandle: fakeMapHandle,
        appData: _buildAppData(),
      );
      addTearDown(() async {
        await controller.onDispose();
        fakeMapHandle.dispose();
      });

      GetIt.I.registerSingleton<StaticAssetsRepositoryContract>(
        staticAssetsRepository,
      );
      staticAssetsRepository.assetsByRef['asset-77'] = _buildPublicStaticAsset(
        id: 'asset-77',
        name: 'Praia das Virtudes',
        slug: 'praia-das-virtudes',
        coverUrl: 'https://tenant.test/media/praia-cover.png',
        description: 'Área de praia com quiosques e vista para o mar.',
      );

      final poi = _buildPoi(
        id: 'poi-static',
        name: 'Praia das Virtudes',
        description: 'Ponto de interesse no mapa',
        refType: 'static',
        refId: 'asset-77',
      );

      await controller.handleMarkerTap(poi);
      await _flushMicrotasks();

      expect(controller.selectedPoiStreamValue.value?.id, 'poi-static');
      expect(
        controller.selectedPoiStreamValue.value?.visual?.imageUri,
        'https://tenant.test/media/praia-cover.png',
      );
      expect(
        controller.selectedPoiStreamValue.value?.coverImageUri,
        'https://tenant.test/media/praia-cover.png',
      );
      expect(
        controller.selectedPoiStreamValue.value?.description,
        'Área de praia com quiosques e vista para o mar.',
      );
    });
  });
}

Future<void> _pumpMapScreen(
  WidgetTester tester, {
  required _RecordingStackRouter router,
  required PageRouteInfo<dynamic> fallbackRoute,
  String? initialPoiQuery,
}) async {
  final isPoiDetail = initialPoiQuery != null;
  final routeData = RouteData(
    route: _FakeRouteMatch(
      name: isPoiDetail ? PoiDetailsRoute.name : CityMapRoute.name,
      fullPath: isPoiDetail ? '/mapa/poi' : '/mapa',
      meta: canonicalRouteMeta(
        family: isPoiDetail
            ? CanonicalRouteFamily.poiDetail
            : CanonicalRouteFamily.cityMap,
      ),
      pageRouteInfo:
          isPoiDetail ? PoiDetailsRoute(poi: initialPoiQuery) : CityMapRoute(),
      queryParams: isPoiDetail
          ? <String, dynamic>{'poi': initialPoiQuery}
          : const <String, dynamic>{},
    ),
    router: router,
    stackKey: const ValueKey<String>('stack'),
    pendingChildren: const <RouteMatch>[],
    type: const RouteType.material(),
  );

  await tester.pumpWidget(
    MaterialApp(
      home: StackRouterScope(
        controller: router,
        stateHash: 0,
        child: RouteDataScope(
          routeData: routeData,
          child: MapScreen(
            initialPoiQuery: initialPoiQuery,
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 120));
}

Future<void> _pumpPoiDetailDeck(
  WidgetTester tester, {
  required MapScreenController controller,
  required _RecordingStackRouter router,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: StackRouterScope(
        controller: router,
        stateHash: 0,
        child: Scaffold(
          body: PoiDetailDeck(controller: controller),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 120));
}

class _RecordingStackRouter extends Fake implements StackRouter {
  _RecordingStackRouter();

  bool canPopResult = false;
  int canPopCallCount = 0;
  int popCallCount = 0;
  final List<List<PageRouteInfo<dynamic>>> replaceAllRoutes = [];
  final List<PageRouteInfo<dynamic>> pushedRoutes = [];
  final List<PageRouteInfo<dynamic>> replacedRoutes = [];

  @override
  RootStackRouter get root => _FakeRootStackRouter(currentPath);

  @override
  String get currentPath => '/mapa';

  @override
  bool canPop({
    bool ignoreChildRoutes = false,
    bool ignoreParentRoutes = false,
    bool ignorePagelessRoutes = false,
  }) {
    canPopCallCount += 1;
    return canPopResult;
  }

  @override
  Future<bool> pop<T extends Object?>([T? result]) async {
    popCallCount += 1;
    return canPopResult;
  }

  @override
  Future<void> replaceAll(
    List<PageRouteInfo<dynamic>> routes, {
    OnNavigationFailure? onFailure,
    bool updateExistingRoutes = true,
  }) async {
    replaceAllRoutes.add(List<PageRouteInfo<dynamic>>.from(routes));
  }

  @override
  Future<T?> push<T extends Object?>(
    PageRouteInfo route, {
    OnNavigationFailure? onFailure,
    bool notify = true,
  }) async {
    pushedRoutes.add(route);
    return null;
  }

  @override
  Future<T?> replace<T extends Object?>(
    PageRouteInfo route, {
    OnNavigationFailure? onFailure,
    bool notify = true,
  }) async {
    replacedRoutes.add(route);
    return null;
  }
}

class _FakeRootStackRouter extends Fake implements RootStackRouter {
  _FakeRootStackRouter(this.currentPath);

  @override
  final String currentPath;

  @override
  Object? get pathState => null;

  @override
  RootStackRouter get root => this;
}

class _FakeRouteMatch extends Fake implements RouteMatch {
  _FakeRouteMatch({
    required this.name,
    required this.fullPath,
    required this.meta,
    required this.pageRouteInfo,
    Map<String, dynamic> queryParams = const <String, dynamic>{},
  }) : _queryParams = Parameters(queryParams);

  @override
  final String name;

  @override
  final String fullPath;

  @override
  final Map<String, dynamic> meta;

  final PageRouteInfo<dynamic> pageRouteInfo;

  final Parameters _queryParams;

  @override
  Parameters get queryParams => _queryParams;

  @override
  PageRouteInfo<dynamic> toPageRouteInfo() => pageRouteInfo;
}

class _TestHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return _TestHttpClient();
  }
}

class _TestHttpClient implements HttpClient {
  bool _autoUncompress = true;

  static final List<int> _transparentImage = <int>[
    0x89,
    0x50,
    0x4E,
    0x47,
    0x0D,
    0x0A,
    0x1A,
    0x0A,
    0x00,
    0x00,
    0x00,
    0x0D,
    0x49,
    0x48,
    0x44,
    0x52,
    0x00,
    0x00,
    0x00,
    0x01,
    0x00,
    0x00,
    0x00,
    0x01,
    0x08,
    0x06,
    0x00,
    0x00,
    0x00,
    0x1F,
    0x15,
    0xC4,
    0x89,
    0x00,
    0x00,
    0x00,
    0x0A,
    0x49,
    0x44,
    0x41,
    0x54,
    0x78,
    0x9C,
    0x63,
    0x00,
    0x01,
    0x00,
    0x00,
    0x05,
    0x00,
    0x01,
    0x0D,
    0x0A,
    0x2D,
    0xB4,
    0x00,
    0x00,
    0x00,
    0x00,
    0x49,
    0x45,
    0x4E,
    0x44,
    0xAE,
    0x42,
    0x60,
    0x82,
  ];

  @override
  Future<HttpClientRequest> getUrl(Uri url) async {
    return _TestHttpClientRequest(_transparentImage);
  }

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async {
    return _TestHttpClientRequest(_transparentImage);
  }

  @override
  void close({bool force = false}) {}

  @override
  bool get autoUncompress => _autoUncompress;

  @override
  set autoUncompress(bool value) {
    _autoUncompress = value;
  }

  @override
  Object? noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _TestHttpClientRequest implements HttpClientRequest {
  _TestHttpClientRequest(this._imageBytes);

  final List<int> _imageBytes;

  @override
  Future<HttpClientResponse> close() async {
    return _TestHttpClientResponse(_imageBytes);
  }

  @override
  Object? noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _TestHttpClientResponse extends Stream<List<int>>
    implements HttpClientResponse {
  _TestHttpClientResponse(this._imageBytes);

  final List<int> _imageBytes;

  @override
  int get statusCode => HttpStatus.ok;

  @override
  int get contentLength => _imageBytes.length;

  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int>)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    final controller = StreamController<List<int>>();
    controller.add(_imageBytes);
    controller.close();
    return controller.stream.listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  @override
  Object? noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

MapScreenController _buildMapController({
  required PoiRepositoryContract poiRepository,
  required UserLocationRepositoryContract userLocationRepository,
  required TelemetryRepositoryContract telemetryRepository,
  BellugaMapHandleContract? mapHandle,
  AppData? appData,
  AppDataRepositoryContract? appDataRepository,
}) {
  final resolvedAppData = appData ?? _buildAppData();
  final resolvedAppDataRepository =
      appDataRepository ?? _FakeMapAppDataRepository(resolvedAppData);
  return MapScreenController(
    poiRepository: poiRepository,
    userLocationRepository: userLocationRepository,
    telemetryRepository: telemetryRepository,
    mapHandle: mapHandle,
    appData: resolvedAppData,
    appDataRepository: resolvedAppDataRepository,
    locationOriginService: LocationOriginService(
      appDataRepository: resolvedAppDataRepository,
      userLocationRepository: userLocationRepository,
    ),
  );
}

AppData _buildAppData({
  List<String> mapFilterKeys = const <String>[],
}) {
  final remoteData = {
    'name': 'Tenant Test',
    'type': 'tenant',
    'main_domain': 'https://tenant.test',
    'profile_types': const [
      {
        'type': 'artist',
        'label': 'Artist',
        'allowed_taxonomies': [],
        'capabilities': {
          'is_favoritable': true,
          'is_poi_enabled': true,
        },
      },
    ],
    'domains': ['https://tenant.test'],
    'app_domains': const [],
    'theme_data_settings': {
      'brightness_default': 'light',
      'primary_seed_color': '#FFFFFF',
      'secondary_seed_color': '#000000',
    },
    'main_color': '#FFFFFF',
    'tenant_id': 'tenant-1',
    'telemetry': const {'trackers': []},
    'telemetry_context': const {'location_freshness_minutes': 5},
    'settings': {
      'map_ui': {
        'distance_bounds': {
          'min_meters': 1000,
          'default_meters': 15000,
          'max_meters': 50000,
        },
        'default_origin': {
          'lat': -20.0,
          'lng': -40.0,
          'label': 'Centro',
        },
        'filters': mapFilterKeys
            .map((key) => <String, dynamic>{'key': key})
            .toList(growable: false),
      },
    },
    'firebase': null,
    'push': null,
  };
  const localInfo = {
    'platformType': 'mobile',
    'hostname': 'tenant.test',
    'href': 'https://tenant.test',
    'port': null,
    'device': 'test-device',
  };
  return buildAppDataFromInitialization(
    remoteData: remoteData,
    localInfo: localInfo,
  );
}

class _FakeMapAppDataRepository extends AppDataRepositoryContract {
  _FakeMapAppDataRepository(this._appData);

  final AppData _appData;

  @override
  AppData get appData => _appData;

  @override
  Future<void> init() async {}

  @override
  final StreamValue<ThemeMode?> themeModeStreamValue =
      StreamValue<ThemeMode?>(defaultValue: ThemeMode.light);

  @override
  ThemeMode get themeMode => themeModeStreamValue.value ?? ThemeMode.light;

  @override
  Future<void> setThemeMode(AppThemeModeValue mode) async {
    themeModeStreamValue.addValue(mode.value);
  }

  @override
  final StreamValue<DistanceInMetersValue> maxRadiusMetersStreamValue =
      StreamValue<DistanceInMetersValue>(
    defaultValue: DistanceInMetersValue.fromRaw(50000, defaultValue: 50000),
  );

  @override
  DistanceInMetersValue get maxRadiusMeters => maxRadiusMetersStreamValue.value;

  @override
  bool get hasPersistedMaxRadiusPreference => false;

  @override
  Future<void> setMaxRadiusMeters(DistanceInMetersValue meters) async {
    maxRadiusMetersStreamValue.addValue(meters);
  }
}
