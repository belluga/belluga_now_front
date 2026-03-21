import 'dart:math' as math;

import 'package:belluga_now/domain/tenant_admin/tenant_admin_event.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_paged_result.dart';
import 'package:stream_value/core/stream_value.dart';

abstract class TenantAdminEventsRepositoryContract {
  static final Expando<_TenantAdminEventsPaginationState>
      _eventsStateByRepository = Expando<_TenantAdminEventsPaginationState>();

  _TenantAdminEventsPaginationState get _eventsPaginationState =>
      _eventsStateByRepository[this] ??= _TenantAdminEventsPaginationState();

  StreamValue<List<TenantAdminEvent>?> get eventsStreamValue =>
      _eventsPaginationState.eventsStreamValue;

  StreamValue<bool> get hasMoreEventsStreamValue =>
      _eventsPaginationState.hasMoreEventsStreamValue;

  StreamValue<bool> get isEventsPageLoadingStreamValue =>
      _eventsPaginationState.isEventsPageLoadingStreamValue;

  StreamValue<String?> get eventsErrorStreamValue =>
      _eventsPaginationState.eventsErrorStreamValue;

  Future<void> loadEvents({
    int pageSize = 20,
    String? search,
    String? status,
    bool archived = false,
  }) async {
    await _waitForEventsFetch();
    _resetEventsPagination();
    eventsStreamValue.addValue(null);
    await _fetchEventsPage(
      page: 1,
      pageSize: pageSize,
      search: search,
      status: status,
      archived: archived,
    );
  }

  Future<void> loadNextEventsPage({
    int pageSize = 20,
    String? search,
    String? status,
    bool archived = false,
  }) async {
    if (_eventsPaginationState.isFetchingEventsPage ||
        !_eventsPaginationState.hasMoreEvents) {
      return;
    }
    await _fetchEventsPage(
      page: _eventsPaginationState.currentEventsPage + 1,
      pageSize: pageSize,
      search: search,
      status: status,
      archived: archived,
    );
  }

  void resetEventsState() {
    _resetEventsPagination();
    eventsStreamValue.addValue(null);
    eventsErrorStreamValue.addValue(null);
  }

  Future<List<TenantAdminEvent>> fetchEvents({
    String? search,
    String? status,
    bool archived = false,
  });

  Future<TenantAdminPagedResult<TenantAdminEvent>> fetchEventsPage({
    required int page,
    required int pageSize,
    String? search,
    String? status,
    bool archived = false,
  }) async {
    final events = await fetchEvents(
      search: search,
      status: status,
      archived: archived,
    );

    if (page <= 0 || pageSize <= 0) {
      return const TenantAdminPagedResult<TenantAdminEvent>(
        items: <TenantAdminEvent>[],
        hasMore: false,
      );
    }

    final startIndex = (page - 1) * pageSize;
    if (startIndex >= events.length) {
      return const TenantAdminPagedResult<TenantAdminEvent>(
        items: <TenantAdminEvent>[],
        hasMore: false,
      );
    }

    final endIndex = math.min(startIndex + pageSize, events.length);
    return TenantAdminPagedResult<TenantAdminEvent>(
      items: events.sublist(startIndex, endIndex),
      hasMore: endIndex < events.length,
    );
  }

  Future<TenantAdminEvent> fetchEvent(String eventIdOrSlug);

  Future<TenantAdminEvent> createEvent({
    required TenantAdminEventDraft draft,
  });

  Future<TenantAdminEvent> createOwnEvent({
    required String accountSlug,
    required TenantAdminEventDraft draft,
  });

  Future<TenantAdminEvent> updateEvent({
    required String eventId,
    required TenantAdminEventDraft draft,
  });

  Future<void> deleteEvent(String eventId);

  Future<List<TenantAdminEventType>> fetchEventTypes() async {
    return const <TenantAdminEventType>[];
  }

  Future<TenantAdminEventType> createEventType({
    required String name,
    required String slug,
    String? description,
  }) {
    throw UnimplementedError();
  }

  Future<TenantAdminEventType> updateEventType({
    required String eventTypeId,
    String? name,
    String? slug,
    String? description,
  }) {
    throw UnimplementedError();
  }

  Future<void> deleteEventType(String eventTypeId) async {}

  Future<TenantAdminEventPartyCandidates> fetchPartyCandidates({
    String? search,
    String? accountSlug,
  });

  Future<void> _waitForEventsFetch() async {
    while (_eventsPaginationState.isFetchingEventsPage) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
  }

  Future<void> _fetchEventsPage({
    required int page,
    required int pageSize,
    String? search,
    String? status,
    required bool archived,
  }) async {
    if (_eventsPaginationState.isFetchingEventsPage) {
      return;
    }
    if (page > 1 && !_eventsPaginationState.hasMoreEvents) {
      return;
    }

    _eventsPaginationState.isFetchingEventsPage = true;
    if (page > 1) {
      isEventsPageLoadingStreamValue.addValue(true);
    }

    try {
      final result = await fetchEventsPage(
        page: page,
        pageSize: pageSize,
        search: search,
        status: status,
        archived: archived,
      );

      if (page == 1) {
        _eventsPaginationState.cachedEvents
          ..clear()
          ..addAll(result.items);
      } else {
        _eventsPaginationState.cachedEvents.addAll(result.items);
      }

      _eventsPaginationState.currentEventsPage = page;
      _eventsPaginationState.hasMoreEvents = result.hasMore;
      hasMoreEventsStreamValue.addValue(_eventsPaginationState.hasMoreEvents);
      eventsStreamValue.addValue(
        List<TenantAdminEvent>.unmodifiable(
          _eventsPaginationState.cachedEvents,
        ),
      );
      eventsErrorStreamValue.addValue(null);
    } catch (error) {
      eventsErrorStreamValue.addValue(error.toString());
      if (page == 1) {
        eventsStreamValue.addValue(const <TenantAdminEvent>[]);
      }
    } finally {
      _eventsPaginationState.isFetchingEventsPage = false;
      isEventsPageLoadingStreamValue.addValue(false);
    }
  }

  void _resetEventsPagination() {
    _eventsPaginationState.cachedEvents.clear();
    _eventsPaginationState.currentEventsPage = 0;
    _eventsPaginationState.hasMoreEvents = true;
    _eventsPaginationState.isFetchingEventsPage = false;
    hasMoreEventsStreamValue.addValue(true);
    isEventsPageLoadingStreamValue.addValue(false);
  }
}

mixin TenantAdminEventsPaginationMixin
    implements TenantAdminEventsRepositoryContract {
  static final Expando<_TenantAdminEventsPaginationState>
      _eventsStateByRepository = Expando<_TenantAdminEventsPaginationState>();

  _TenantAdminEventsPaginationState get _mixinEventsPaginationState =>
      _eventsStateByRepository[this] ??= _TenantAdminEventsPaginationState();

  @override
  StreamValue<List<TenantAdminEvent>?> get eventsStreamValue =>
      _mixinEventsPaginationState.eventsStreamValue;

  @override
  StreamValue<bool> get hasMoreEventsStreamValue =>
      _mixinEventsPaginationState.hasMoreEventsStreamValue;

  @override
  StreamValue<bool> get isEventsPageLoadingStreamValue =>
      _mixinEventsPaginationState.isEventsPageLoadingStreamValue;

  @override
  StreamValue<String?> get eventsErrorStreamValue =>
      _mixinEventsPaginationState.eventsErrorStreamValue;

  @override
  Future<void> loadEvents({
    int pageSize = 20,
    String? search,
    String? status,
    bool archived = false,
  }) async {
    await _waitForEventsFetchMixin();
    _resetEventsPaginationMixin();
    eventsStreamValue.addValue(null);
    await _fetchEventsPageMixin(
      page: 1,
      pageSize: pageSize,
      search: search,
      status: status,
      archived: archived,
    );
  }

  @override
  Future<void> loadNextEventsPage({
    int pageSize = 20,
    String? search,
    String? status,
    bool archived = false,
  }) async {
    if (_mixinEventsPaginationState.isFetchingEventsPage ||
        !_mixinEventsPaginationState.hasMoreEvents) {
      return;
    }
    await _fetchEventsPageMixin(
      page: _mixinEventsPaginationState.currentEventsPage + 1,
      pageSize: pageSize,
      search: search,
      status: status,
      archived: archived,
    );
  }

  @override
  void resetEventsState() {
    _resetEventsPaginationMixin();
    eventsStreamValue.addValue(null);
    eventsErrorStreamValue.addValue(null);
  }

  @override
  Future<List<TenantAdminEventType>> fetchEventTypes() async {
    return const <TenantAdminEventType>[];
  }

  @override
  Future<TenantAdminEventType> createEventType({
    required String name,
    required String slug,
    String? description,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<TenantAdminEventType> updateEventType({
    required String eventTypeId,
    String? name,
    String? slug,
    String? description,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteEventType(String eventTypeId) async {}

  Future<void> _waitForEventsFetchMixin() async {
    while (_mixinEventsPaginationState.isFetchingEventsPage) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
  }

  Future<void> _fetchEventsPageMixin({
    required int page,
    required int pageSize,
    String? search,
    String? status,
    required bool archived,
  }) async {
    if (_mixinEventsPaginationState.isFetchingEventsPage) {
      return;
    }
    if (page > 1 && !_mixinEventsPaginationState.hasMoreEvents) {
      return;
    }

    _mixinEventsPaginationState.isFetchingEventsPage = true;
    if (page > 1) {
      isEventsPageLoadingStreamValue.addValue(true);
    }

    try {
      final result = await fetchEventsPage(
        page: page,
        pageSize: pageSize,
        search: search,
        status: status,
        archived: archived,
      );
      if (page == 1) {
        _mixinEventsPaginationState.cachedEvents
          ..clear()
          ..addAll(result.items);
      } else {
        _mixinEventsPaginationState.cachedEvents.addAll(result.items);
      }
      _mixinEventsPaginationState.currentEventsPage = page;
      _mixinEventsPaginationState.hasMoreEvents = result.hasMore;
      hasMoreEventsStreamValue.addValue(
        _mixinEventsPaginationState.hasMoreEvents,
      );
      eventsStreamValue.addValue(
        List<TenantAdminEvent>.unmodifiable(
          _mixinEventsPaginationState.cachedEvents,
        ),
      );
      eventsErrorStreamValue.addValue(null);
    } catch (error) {
      eventsErrorStreamValue.addValue(error.toString());
      if (page == 1) {
        eventsStreamValue.addValue(const <TenantAdminEvent>[]);
      }
    } finally {
      _mixinEventsPaginationState.isFetchingEventsPage = false;
      isEventsPageLoadingStreamValue.addValue(false);
    }
  }

  void _resetEventsPaginationMixin() {
    _mixinEventsPaginationState.cachedEvents.clear();
    _mixinEventsPaginationState.currentEventsPage = 0;
    _mixinEventsPaginationState.hasMoreEvents = true;
    _mixinEventsPaginationState.isFetchingEventsPage = false;
    hasMoreEventsStreamValue.addValue(true);
    isEventsPageLoadingStreamValue.addValue(false);
  }
}

class _TenantAdminEventsPaginationState {
  final List<TenantAdminEvent> cachedEvents = <TenantAdminEvent>[];
  final StreamValue<List<TenantAdminEvent>?> eventsStreamValue =
      StreamValue<List<TenantAdminEvent>?>();
  final StreamValue<bool> hasMoreEventsStreamValue =
      StreamValue<bool>(defaultValue: true);
  final StreamValue<bool> isEventsPageLoadingStreamValue =
      StreamValue<bool>(defaultValue: false);
  final StreamValue<String?> eventsErrorStreamValue = StreamValue<String?>();
  bool isFetchingEventsPage = false;
  bool hasMoreEvents = true;
  int currentEventsPage = 0;
}
