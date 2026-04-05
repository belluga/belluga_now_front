import 'dart:async';

import 'package:belluga_now/domain/repositories/schedule_repository_contract.dart';
import 'package:belluga_now/infrastructure/dal/dto/schedule/event_delta_dto.dart';
import 'package:belluga_now/infrastructure/dal/dto/schedule/event_dto.dart';
import 'package:belluga_now/infrastructure/dal/dto/schedule/event_page_dto.dart';
import 'package:belluga_now/infrastructure/repositories/schedule_repository.dart';
import 'package:belluga_now/infrastructure/services/schedule_backend_contract.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('getEventsPage maps events when event type description is null',
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

    final result = await repository.getEventsPage(
      page: ScheduleRepoInt.fromRaw(1, defaultValue: 1),
      pageSize: ScheduleRepoInt.fromRaw(25, defaultValue: 25),
      showPastOnly: ScheduleRepoBool.fromRaw(false, defaultValue: false),
    );

    expect(result.events, hasLength(1));
    expect(result.events.first.type.description.value, isEmpty);
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
    );

    expect(event, isNotNull);
    expect(event!.id.value, '507f1f77bcf86cd799439081');
    expect(backend.fetchEventDetailCalls, 1);
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

  test('getEventsPage forwards liveNowOnly to backend', () async {
    final backend = _CapturingScheduleBackend();
    final repository = ScheduleRepository(backend: backend);

    await repository.getEventsPage(
      page: ScheduleRepoInt.fromRaw(1, defaultValue: 1),
      pageSize: ScheduleRepoInt.fromRaw(25, defaultValue: 25),
      showPastOnly: ScheduleRepoBool.fromRaw(false, defaultValue: false),
      liveNowOnly: ScheduleRepoBool.fromRaw(true, defaultValue: true),
    );

    expect(backend.requests, hasLength(1));
    expect(backend.requests.first.liveNowOnly, isTrue);
  });

  test('getEventsPage keeps standard upcoming request as single backend call',
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

    final result = await repository.getEventsPage(
      page: ScheduleRepoInt.fromRaw(1, defaultValue: 1),
      pageSize: ScheduleRepoInt.fromRaw(25, defaultValue: 25),
      showPastOnly: ScheduleRepoBool.fromRaw(false, defaultValue: false),
    );

    final ids = result.events.map((event) => event.id.value).toList();
    expect(ids, [upcomingId]);
    expect(backend.requests, hasLength(1));
    expect(backend.requests.single.liveNowOnly, isFalse);
  });

  test('getEventsPage maps events when event content is null', () async {
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

    final result = await repository.getEventsPage(
      page: ScheduleRepoInt.fromRaw(1, defaultValue: 1),
      pageSize: ScheduleRepoInt.fromRaw(25, defaultValue: 25),
      showPastOnly: ScheduleRepoBool.fromRaw(false, defaultValue: false),
    );

    expect(result.events, hasLength(1));
    expect(result.events.first.content.valueText, isEmpty);
  });

  test('getEventsPage maps events when type description and content are null',
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

    final result = await repository.getEventsPage(
      page: ScheduleRepoInt.fromRaw(1, defaultValue: 1),
      pageSize: ScheduleRepoInt.fromRaw(25, defaultValue: 25),
      showPastOnly: ScheduleRepoBool.fromRaw(false, defaultValue: false),
    );

    expect(result.events, hasLength(1));
    expect(result.events.first.type.description.value, isEmpty);
    expect(result.events.first.content.valueText, isEmpty);
  });

  test(
      'loadEventsPage ignores second first-page request while one is in-flight',
      () async {
    final backend = _BlockingFirstPageScheduleBackend();
    final repository = ScheduleRepository(backend: backend);

    final firstLoadFuture = repository.loadEventsPage(
      showPastOnly: ScheduleRepoBool.fromRaw(false, defaultValue: false),
    );

    await backend.waitUntilFirstRequestStarts();

    await repository.loadEventsPage(
      showPastOnly: ScheduleRepoBool.fromRaw(false, defaultValue: false),
    );

    expect(
      backend.fetchEventsPageCalls,
      1,
      reason: 'A second first-page request must be ignored while in-flight.',
    );

    backend.releaseFirstRequest();
    await firstLoadFuture;

    expect(repository.currentPagedEventsPage.value, 1);
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
  int fetchEventDetailCalls = 0;
  int fetchEventsPageCalls = 0;

  @override
  Future<EventDTO?> fetchEventDetail({required String eventIdOrSlug}) async {
    fetchEventDetailCalls += 1;
    return detailResponses?[eventIdOrSlug];
  }

  @override
  Future<EventPageDTO> fetchEventsPage({
    required int page,
    required int pageSize,
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
        liveNowOnly: liveNowOnly,
        originLat: originLat,
        originLng: originLng,
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

class _BlockingFirstPageScheduleBackend implements ScheduleBackendContract {
  final Completer<void> _firstRequestStarted = Completer<void>();
  final Completer<void> _releaseFirstRequest = Completer<void>();
  int fetchEventsPageCalls = 0;

  Future<void> waitUntilFirstRequestStarts() => _firstRequestStarted.future;

  void releaseFirstRequest() {
    if (!_releaseFirstRequest.isCompleted) {
      _releaseFirstRequest.complete();
    }
  }

  @override
  Future<EventDTO?> fetchEventDetail({required String eventIdOrSlug}) async =>
      null;

  @override
  Future<EventPageDTO> fetchEventsPage({
    required int page,
    required int pageSize,
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
    if (fetchEventsPageCalls == 1) {
      if (!_firstRequestStarted.isCompleted) {
        _firstRequestStarted.complete();
      }
      await _releaseFirstRequest.future;
    }

    return EventPageDTO(events: const [], hasMore: false);
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
    required this.liveNowOnly,
    required this.originLat,
    required this.originLng,
  });

  final int page;
  final bool liveNowOnly;
  final double? originLat;
  final double? originLng;
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
