import 'package:belluga_now/domain/repositories/schedule_repository_contract.dart';
import 'package:belluga_now/infrastructure/dal/dto/schedule/event_delta_dto.dart';
import 'package:belluga_now/infrastructure/dal/dto/schedule/event_dto.dart';
import 'package:belluga_now/infrastructure/dal/dto/schedule/event_page_dto.dart';
import 'package:belluga_now/infrastructure/repositories/schedule_repository.dart';
import 'package:belluga_now/infrastructure/services/schedule_backend_contract.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('loadHomeAgenda maps events when event type description is null',
      () async {
    final backend = _CapturingScheduleBackend(
      pagedResponses: [
        EventPageDTO(
          events: [
            _buildEventDto(
              eventId: '507f1f77bcf86cd799439031',
              occurrenceId: '507f1f77bcf86cd799439032',
              typeDescription: null,
            ),
          ],
          hasMore: false,
        ),
      ],
    );
    final repository = ScheduleRepository(backend: backend);

    final result = await repository.loadHomeAgenda(
      showPastOnly: ScheduleRepoBool.fromRaw(false, defaultValue: false),
      searchQuery: ScheduleRepoString.fromRaw('', defaultValue: ''),
      confirmedOnly: ScheduleRepoBool.fromRaw(false, defaultValue: false),
    );

    expect(result, hasLength(1));
    expect(result.first.type.description.value, isEmpty);
    expect(repository.homeAgendaStreamValue.value, result);
    expect(
      await repository.loadMoreHomeAgenda(
        showPastOnly: ScheduleRepoBool.fromRaw(false, defaultValue: false),
        searchQuery: ScheduleRepoString.fromRaw('', defaultValue: ''),
        confirmedOnly: ScheduleRepoBool.fromRaw(false, defaultValue: false),
      ),
      result,
    );
  });

  test('loadMoreHomeAgenda appends items while keeping page state private',
      () async {
    final backend = _CapturingScheduleBackend(
      pagedResponses: [
        EventPageDTO(
          events: [
            _buildEventDto(
              eventId: '507f1f77bcf86cd799439091',
              occurrenceId: '507f1f77bcf86cd799439092',
            ),
          ],
          hasMore: true,
        ),
        EventPageDTO(
          events: [
            _buildEventDto(
              eventId: '507f1f77bcf86cd799439093',
              occurrenceId: '507f1f77bcf86cd799439094',
            ),
          ],
          hasMore: false,
        ),
      ],
    );
    final repository = ScheduleRepository(backend: backend);
    final showPastOnly = ScheduleRepoBool.fromRaw(false, defaultValue: false);
    final searchQuery = ScheduleRepoString.fromRaw('', defaultValue: '');
    final confirmedOnly = ScheduleRepoBool.fromRaw(false, defaultValue: false);

    final firstPage = await repository.loadHomeAgenda(
      showPastOnly: showPastOnly,
      searchQuery: searchQuery,
      confirmedOnly: confirmedOnly,
    );
    final secondPage = await repository.loadMoreHomeAgenda(
      showPastOnly: showPastOnly,
      searchQuery: searchQuery,
      confirmedOnly: confirmedOnly,
    );

    expect(firstPage.map((event) => event.id.value), [
      '507f1f77bcf86cd799439091',
    ]);
    expect(secondPage.map((event) => event.id.value), [
      '507f1f77bcf86cd799439091',
      '507f1f77bcf86cd799439093',
    ]);
    expect(backend.requests.map((request) => request.page), [1, 2]);
    expect(
      backend.requests.map((request) => request.pageSize),
      [null, null],
      reason: 'Home agenda follows backend default batch size.',
    );
    expect(
        repository
            .readHomeAgenda(
              showPastOnly: showPastOnly,
              searchQuery: searchQuery,
              confirmedOnly: confirmedOnly,
            )
            ?.map((event) => event.id.value),
        [
          '507f1f77bcf86cd799439091',
          '507f1f77bcf86cd799439093',
        ]);
    expect(
      await repository.loadMoreHomeAgenda(
        showPastOnly: showPastOnly,
        searchQuery: searchQuery,
        confirmedOnly: confirmedOnly,
      ),
      hasLength(2),
    );
  });

  test('loadHomeAgenda forwards category and taxonomy filters to backend',
      () async {
    final backend = _CapturingScheduleBackend(
      pagedResponses: [
        EventPageDTO(
          events: [_buildEventDto()],
          hasMore: false,
        ),
      ],
    );
    final repository = ScheduleRepository(backend: backend);
    final taxonomy = ScheduleRepoTaxonomyEntries()
      ..add(
        ScheduleRepoTaxonomyEntry(
          type: ScheduleRepoString.fromRaw('music_styles'),
          term: ScheduleRepoString.fromRaw('rock'),
        ),
      );

    await repository.loadHomeAgenda(
      showPastOnly: ScheduleRepoBool.fromRaw(false, defaultValue: false),
      searchQuery: ScheduleRepoString.fromRaw('', defaultValue: ''),
      confirmedOnly: ScheduleRepoBool.fromRaw(false, defaultValue: false),
      categories: [
        ScheduleRepoString.fromRaw('show'),
      ],
      taxonomy: taxonomy,
    );

    expect(backend.requests.single.categories, const ['show']);
    expect(backend.requests.single.taxonomy, const [
      {'type': 'music_styles', 'value': 'rock'},
    ]);
    expect(
      repository.readHomeAgenda(
        showPastOnly: ScheduleRepoBool.fromRaw(false, defaultValue: false),
        searchQuery: ScheduleRepoString.fromRaw('', defaultValue: ''),
        confirmedOnly: ScheduleRepoBool.fromRaw(false, defaultValue: false),
        categories: [
          ScheduleRepoString.fromRaw('show'),
        ],
        taxonomy: taxonomy,
      ),
      isNotNull,
    );
    expect(
      repository.readHomeAgenda(
        showPastOnly: ScheduleRepoBool.fromRaw(false, defaultValue: false),
        searchQuery: ScheduleRepoString.fromRaw('', defaultValue: ''),
        confirmedOnly: ScheduleRepoBool.fromRaw(false, defaultValue: false),
        categories: [
          ScheduleRepoString.fromRaw('fair'),
        ],
        taxonomy: taxonomy,
      ),
      isNull,
    );
  });

  test('getEventBySlug returns backend detail without catalog fallback',
      () async {
    final backend = _CapturingScheduleBackend(
      detailResponses: {
        'event-slug': _buildEventDto(
          eventId: '507f1f77bcf86cd799439081',
          occurrenceId: '507f1f77bcf86cd799439082',
        ),
      },
    );
    final repository = ScheduleRepository(backend: backend);

    final event = await repository.getEventBySlug(
      ScheduleRepoString.fromRaw('event-slug', defaultValue: ''),
      occurrenceId: ScheduleRepoString.fromRaw(
        '507f1f77bcf86cd799439082',
        defaultValue: '',
      ),
    );

    expect(event, isNotNull);
    expect(event!.id.value, '507f1f77bcf86cd799439081');
    expect(backend.fetchEventDetailCalls, 1);
    expect(backend.lastOccurrenceId, '507f1f77bcf86cd799439082');
    expect(backend.fetchEventsPageCalls, 0);
  });

  test('getEventBySlug does not scan catalog after backend miss', () async {
    final backend = _CapturingScheduleBackend();
    final repository = ScheduleRepository(backend: backend);

    final event = await repository.getEventBySlug(
      ScheduleRepoString.fromRaw('missing-slug', defaultValue: ''),
    );

    expect(event, isNull);
    expect(backend.fetchEventDetailCalls, 1);
    expect(backend.fetchEventsPageCalls, 0);
  });

  test('refreshDiscoveryLiveNowEvents forwards liveNowOnly to backend',
      () async {
    final backend = _CapturingScheduleBackend();
    final repository = ScheduleRepository(backend: backend);

    await repository.refreshDiscoveryLiveNowEvents();

    expect(backend.requests, hasLength(1));
    expect(backend.requests.first.liveNowOnly, isTrue);
  });

  test('loadEventSearch keeps standard upcoming request as single backend call',
      () async {
    const upcomingId = '507f1f77bcf86cd799439061';
    const upcomingOccurrenceId = '507f1f77bcf86cd799439062';

    final backend = _CapturingScheduleBackend(
      pagedResponses: [
        EventPageDTO(
          events: [
            _buildEventDto(
              eventId: upcomingId,
              occurrenceId: upcomingOccurrenceId,
              startsAtIso: '2099-01-01T22:00:00+00:00',
            ),
          ],
          hasMore: false,
        ),
      ],
    );
    final repository = ScheduleRepository(backend: backend);

    final result = await repository.loadEventSearch(
      showPastOnly: ScheduleRepoBool.fromRaw(false, defaultValue: false),
    );

    final ids = result.map((event) => event.id.value).toList();
    expect(ids, [upcomingId]);
    expect(backend.requests, hasLength(1));
    expect(backend.requests.single.liveNowOnly, isFalse);
  });

  test('loadEventSearch maps events when event content is null', () async {
    final backend = _CapturingScheduleBackend(
      pagedResponses: [
        EventPageDTO(
          events: [
            _buildEventDto(
              eventId: '507f1f77bcf86cd799439041',
              occurrenceId: '507f1f77bcf86cd799439042',
              eventContent: null,
            ),
          ],
          hasMore: false,
        ),
      ],
    );
    final repository = ScheduleRepository(backend: backend);

    final result = await repository.loadEventSearch(
      showPastOnly: ScheduleRepoBool.fromRaw(false, defaultValue: false),
    );

    expect(result, hasLength(1));
    expect(result.first.content.valueText, isEmpty);
  });

  test('loadEventSearch maps events when type description and content are null',
      () async {
    final backend = _CapturingScheduleBackend(
      pagedResponses: [
        EventPageDTO(
          events: [
            _buildEventDto(
              eventId: '507f1f77bcf86cd799439051',
              occurrenceId: '507f1f77bcf86cd799439052',
              typeDescription: null,
              eventContent: null,
            ),
          ],
          hasMore: false,
        ),
      ],
    );
    final repository = ScheduleRepository(backend: backend);

    final result = await repository.loadEventSearch(
      showPastOnly: ScheduleRepoBool.fromRaw(false, defaultValue: false),
    );

    expect(result, hasLength(1));
    expect(result.first.type.description.value, isEmpty);
    expect(result.first.content.valueText, isEmpty);
  });
}

class _CapturingScheduleBackend implements ScheduleBackendContract {
  _CapturingScheduleBackend({
    this.pagedResponses,
    this.detailResponses,
  });

  final List<EventPageDTO>? pagedResponses;
  final Map<String, EventDTO>? detailResponses;
  final List<_AgendaRequestSample> requests = <_AgendaRequestSample>[];
  String? lastOccurrenceId;
  int fetchEventDetailCalls = 0;
  int fetchEventsPageCalls = 0;

  @override
  Future<EventDTO?> fetchEventDetail({
    required String eventIdOrSlug,
    String? occurrenceId,
  }) async {
    fetchEventDetailCalls += 1;
    lastOccurrenceId = occurrenceId;
    return detailResponses?[eventIdOrSlug];
  }

  @override
  Future<EventPageDTO> fetchEventsPage({
    required int page,
    int? pageSize,
    required bool showPastOnly,
    bool liveNowOnly = false,
    String? searchQuery,
    List<String>? categories,
    List<String>? tags,
    List<Map<String, String>>? taxonomy,
    bool confirmedOnly = false,
    double? originLat,
    double? originLng,
    double? maxDistanceMeters,
  }) async {
    fetchEventsPageCalls += 1;
    requests.add(
      _AgendaRequestSample(
        page: page,
        pageSize: pageSize,
        liveNowOnly: liveNowOnly,
        originLat: originLat,
        originLng: originLng,
        categories: categories,
        taxonomy: taxonomy,
      ),
    );
    if (pagedResponses != null) {
      final index = page - 1;
      if (index < 0 || index >= pagedResponses!.length) {
        return EventPageDTO(events: const [], hasMore: false);
      }
      return pagedResponses![index];
    }
    if (page > 1) {
      return EventPageDTO(events: const [], hasMore: false);
    }
    return EventPageDTO(
      events: [_buildEventDto()],
      hasMore: false,
    );
  }

  @override
  Stream<EventDeltaDTO> watchEventsStream({
    String? searchQuery,
    List<String>? categories,
    List<String>? tags,
    List<Map<String, String>>? taxonomy,
    bool confirmedOnly = false,
    double? originLat,
    double? originLng,
    double? maxDistanceMeters,
    String? lastEventId,
    bool showPastOnly = false,
  }) {
    return const Stream<EventDeltaDTO>.empty();
  }
}

class _AgendaRequestSample {
  const _AgendaRequestSample({
    required this.page,
    required this.pageSize,
    required this.liveNowOnly,
    required this.originLat,
    required this.originLng,
    required this.categories,
    required this.taxonomy,
  });

  final int page;
  final int? pageSize;
  final bool liveNowOnly;
  final double? originLat;
  final double? originLng;
  final List<String>? categories;
  final List<Map<String, String>>? taxonomy;
}

EventDTO _buildEventDto({
  String eventId = '507f1f77bcf86cd799439001',
  String occurrenceId = '507f1f77bcf86cd799439002',
  String startsAtIso = '2099-01-01T20:00:00+00:00',
  String? typeDescription = 'Show ao vivo',
  String? eventContent = 'Conteudo do evento',
}) {
  return EventDTO.fromJson({
    'event_id': eventId,
    'occurrence_id': occurrenceId,
    'slug': 'event-slug-$eventId',
    'title': 'Evento Teste',
    'content': eventContent,
    'date_time_start': startsAtIso,
    'date_time_end': '2099-01-01T23:00:00+00:00',
    'location': 'Guarapari, ES',
    'type': {
      'id': 'type-1',
      'name': 'Show',
      'slug': 'show',
      'description': typeDescription,
      'color': '#FF00AA',
    },
    'artists': const [],
    'thumb': null,
    'venue': null,
  });
}
