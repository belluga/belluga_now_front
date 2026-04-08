import 'package:belluga_now/domain/repositories/schedule_repository_contract.dart';
import 'package:belluga_now/domain/repositories/value_objects/schedule_repository_contract_values.dart';
import 'package:belluga_now/domain/schedule/event_delta_model.dart';
import 'package:belluga_now/domain/schedule/event_model.dart';
import 'package:belluga_now/domain/schedule/paged_events_result.dart';
import 'package:belluga_now/domain/schedule/value_objects/home_agenda_boolean_value.dart';
import 'package:belluga_now/domain/schedule/value_objects/home_agenda_captured_at_value.dart';
import 'package:belluga_now/domain/schedule/value_objects/home_agenda_page_value.dart';
import 'package:belluga_now/domain/schedule/value_objects/home_agenda_search_query_value.dart';
import 'package:belluga_now/domain/map/value_objects/distance_in_meters_value.dart';
import 'package:belluga_now/domain/map/value_objects/latitude_value.dart';
import 'package:belluga_now/domain/map/value_objects/longitude_value.dart';
import 'package:stream_value/core/stream_value.dart';

class IntegrationTestScheduleRepositoryFake extends ScheduleRepositoryContract {
  @override
  final StreamValue<HomeAgendaCacheSnapshot?> homeAgendaStreamValue =
      StreamValue<HomeAgendaCacheSnapshot?>();

  @override
  HomeAgendaCacheSnapshot? readHomeAgenda({
    required ScheduleRepoBool showPastOnly,
    required ScheduleRepoString searchQuery,
    required ScheduleRepoBool confirmedOnly,
    ScheduleRepoDouble? originLat,
    ScheduleRepoDouble? originLng,
    ScheduleRepoDouble? maxDistanceMeters,
  }) {
    final snapshot = homeAgendaStreamValue.value;
    if (snapshot == null) return null;
    if (snapshot.showPastOnly != showPastOnly.value) return null;
    if (snapshot.searchQuery != searchQuery.value) return null;
    if (snapshot.confirmedOnly != confirmedOnly.value) return null;
    if (snapshot.originLat != originLat?.value) return null;
    if (snapshot.originLng != originLng?.value) return null;
    if (snapshot.maxDistanceMeters != maxDistanceMeters?.value) return null;
    return snapshot;
  }

  HomeAgendaCacheSnapshot _buildHomeAgendaSnapshot({
    required List<EventModel> events,
    required int page,
    required bool hasMore,
    required ScheduleRepoBool showPastOnly,
    required ScheduleRepoString searchQuery,
    required ScheduleRepoBool confirmedOnly,
    ScheduleRepoDouble? originLat,
    ScheduleRepoDouble? originLng,
    ScheduleRepoDouble? maxDistanceMeters,
  }) {
    final now = DateTime.now();
    return HomeAgendaCacheSnapshot(
      events: List<EventModel>.unmodifiable(events),
      hasMoreValue: HomeAgendaBooleanValue(defaultValue: hasMore)
        ..parse(hasMore.toString()),
      pageValue: HomeAgendaPageValue(defaultValue: page)..parse(page.toString()),
      showPastOnlyValue: HomeAgendaBooleanValue(defaultValue: showPastOnly.value)
        ..parse(showPastOnly.value.toString()),
      searchQueryValue: HomeAgendaSearchQueryValue(
        defaultValue: searchQuery.value,
      )..parse(searchQuery.value),
      confirmedOnlyValue:
          HomeAgendaBooleanValue(defaultValue: confirmedOnly.value)
            ..parse(confirmedOnly.value.toString()),
      capturedAtValue: HomeAgendaCapturedAtValue(defaultValue: now)
        ..parse(now.toIso8601String()),
      originLatValue: originLat == null
          ? null
          : (LatitudeValue()..parse(originLat.value.toString())),
      originLngValue: originLng == null
          ? null
          : (LongitudeValue()..parse(originLng.value.toString())),
      maxDistanceMetersValue: maxDistanceMeters == null
          ? null
          : (DistanceInMetersValue(defaultValue: maxDistanceMeters.value)
            ..parse(maxDistanceMeters.value.toString())),
    );
  }

  @override
  Future<HomeAgendaCacheSnapshot> loadHomeAgenda({
    required ScheduleRepoBool showPastOnly,
    required ScheduleRepoString searchQuery,
    required ScheduleRepoBool confirmedOnly,
    ScheduleRepoDouble? originLat,
    ScheduleRepoDouble? originLng,
    ScheduleRepoDouble? maxDistanceMeters,
  }) async {
    final pageResult = await getEventsPage(
      page: ScheduleRepoInt.fromRaw(1, defaultValue: 1),
      pageSize: ScheduleRepoInt.fromRaw(25, defaultValue: 25),
      showPastOnly: showPastOnly,
      searchQuery: searchQuery,
      confirmedOnly: confirmedOnly,
      originLat: originLat,
      originLng: originLng,
      maxDistanceMeters: maxDistanceMeters,
    );
    final snapshot = _buildHomeAgendaSnapshot(
      events: pageResult.events,
      page: 1,
      hasMore: pageResult.hasMore,
      showPastOnly: showPastOnly,
      searchQuery: searchQuery,
      confirmedOnly: confirmedOnly,
      originLat: originLat,
      originLng: originLng,
      maxDistanceMeters: maxDistanceMeters,
    );
    homeAgendaStreamValue.addValue(snapshot);
    return snapshot;
  }

  @override
  Future<HomeAgendaCacheSnapshot?> loadNextHomeAgendaPage({
    required ScheduleRepoBool showPastOnly,
    required ScheduleRepoString searchQuery,
    required ScheduleRepoBool confirmedOnly,
    ScheduleRepoDouble? originLat,
    ScheduleRepoDouble? originLng,
    ScheduleRepoDouble? maxDistanceMeters,
  }) async {
    final current = readHomeAgenda(
      showPastOnly: showPastOnly,
      searchQuery: searchQuery,
      confirmedOnly: confirmedOnly,
      originLat: originLat,
      originLng: originLng,
      maxDistanceMeters: maxDistanceMeters,
    );
    if (current == null || !current.hasMore) {
      return current;
    }

    final nextPage = current.page + 1;
    final pageResult = await getEventsPage(
      page: ScheduleRepoInt.fromRaw(nextPage, defaultValue: nextPage),
      pageSize: ScheduleRepoInt.fromRaw(25, defaultValue: 25),
      showPastOnly: showPastOnly,
      searchQuery: searchQuery,
      confirmedOnly: confirmedOnly,
      originLat: originLat,
      originLng: originLng,
      maxDistanceMeters: maxDistanceMeters,
    );
    final snapshot = _buildHomeAgendaSnapshot(
      events: <EventModel>[
        ...current.events,
        ...pageResult.events,
      ],
      page: nextPage,
      hasMore: pageResult.hasMore,
      showPastOnly: showPastOnly,
      searchQuery: searchQuery,
      confirmedOnly: confirmedOnly,
      originLat: originLat,
      originLng: originLng,
      maxDistanceMeters: maxDistanceMeters,
    );
    homeAgendaStreamValue.addValue(snapshot);
    return snapshot;
  }

  @override
  Future<EventModel?> getEventBySlug(ScheduleRepoString slug) async => null;

  @override
  Future<PagedEventsResult> getEventsPage({
    required ScheduleRepoInt page,
    required ScheduleRepoInt pageSize,
    required ScheduleRepoBool showPastOnly,
    ScheduleRepoString? searchQuery,
    List<ScheduleRepoString>? categories,
    List<ScheduleRepoString>? tags,
    ScheduleRepoTaxonomyEntries? taxonomy,
    ScheduleRepoBool? confirmedOnly,
    ScheduleRepoBool? liveNowOnly,
    ScheduleRepoDouble? originLat,
    ScheduleRepoDouble? originLng,
    ScheduleRepoDouble? maxDistanceMeters,
  }) async =>
      pagedEventsResultFromRaw(events: <EventModel>[], hasMore: false);

  @override
  Stream<EventDeltaModel> watchEventsStream({
    ScheduleRepoString? searchQuery,
    List<ScheduleRepoString>? categories,
    List<ScheduleRepoString>? tags,
    ScheduleRepoTaxonomyEntries? taxonomy,
    ScheduleRepoBool? confirmedOnly,
    ScheduleRepoDouble? originLat,
    ScheduleRepoDouble? originLng,
    ScheduleRepoDouble? maxDistanceMeters,
    ScheduleRepoString? lastEventId,
    ScheduleRepoBool? showPastOnly,
  }) =>
      const Stream<EventDeltaModel>.empty();

  @override
  Stream<void> watchEventsSignal({
    required ScheduleRepositoryContractDeltaHandler onDelta,
    ScheduleRepoString? searchQuery,
    List<ScheduleRepoString>? categories,
    List<ScheduleRepoString>? tags,
    ScheduleRepoTaxonomyEntries? taxonomy,
    ScheduleRepoBool? confirmedOnly,
    ScheduleRepoDouble? originLat,
    ScheduleRepoDouble? originLng,
    ScheduleRepoDouble? maxDistanceMeters,
    ScheduleRepoString? lastEventId,
    ScheduleRepoBool? showPastOnly,
  }) {
    return watchEventsStream(
      searchQuery: searchQuery,
      categories: categories,
      tags: tags,
      taxonomy: taxonomy,
      confirmedOnly: confirmedOnly,
      originLat: originLat,
      originLng: originLng,
      maxDistanceMeters: maxDistanceMeters,
      lastEventId: lastEventId,
      showPastOnly: showPastOnly,
    ).map((delta) {
      onDelta(delta);
    });
  }
}
