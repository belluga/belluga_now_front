import 'dart:math' as math;

import 'package:belluga_now/domain/repositories/value_objects/tenant_admin_events_repository_contract_values.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_event.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_paged_result.dart';
import 'package:stream_value/core/stream_value.dart';

typedef TenantAdminEventsRepoString = TenantAdminEventsRepositoryContractTextValue;
typedef TenantAdminEventsRepoInt = TenantAdminEventsRepositoryContractIntValue;
typedef TenantAdminEventsRepoBool = TenantAdminEventsRepositoryContractBoolValue;

abstract class TenantAdminEventsRepositoryContract {
  static final TenantAdminEventsRepoInt _defaultPageSize =
      TenantAdminEventsRepoInt.fromRaw(20, defaultValue: 20);
  static final TenantAdminEventsRepoBool _defaultArchived =
      TenantAdminEventsRepoBool.fromRaw(false, defaultValue: false);

  static final Expando<_TenantAdminEventsPaginationState>
      _eventsStateByRepository = Expando<_TenantAdminEventsPaginationState>();

  _TenantAdminEventsPaginationState get _eventsPaginationState =>
      _eventsStateByRepository[this] ??= _TenantAdminEventsPaginationState();

  StreamValue<List<TenantAdminEvent>?> get eventsStreamValue =>
      _eventsPaginationState.eventsStreamValue;

  StreamValue<TenantAdminEventsRepoBool> get hasMoreEventsStreamValue =>
      _eventsPaginationState.hasMoreEventsStreamValue;

  StreamValue<TenantAdminEventsRepoBool> get isEventsPageLoadingStreamValue =>
      _eventsPaginationState.isEventsPageLoadingStreamValue;

  StreamValue<TenantAdminEventsRepoString?> get eventsErrorStreamValue =>
      _eventsPaginationState.eventsErrorStreamValue;

  Future<void> loadEvents({
    TenantAdminEventsRepoInt? pageSize,
    TenantAdminEventsRepoString? search,
    TenantAdminEventsRepoString? status,
    TenantAdminEventsRepoBool? archived,
  }) async {
    await _waitForEventsFetch();
    _resetEventsPagination();
    eventsStreamValue.addValue(null);
    await _fetchEventsPage(
      page: TenantAdminEventsRepoInt.fromRaw(1, defaultValue: 1),
      pageSize: pageSize ?? _defaultPageSize,
      search: search,
      status: status,
      archived: archived ?? _defaultArchived,
    );
  }

  Future<void> loadNextEventsPage({
    TenantAdminEventsRepoInt? pageSize,
    TenantAdminEventsRepoString? search,
    TenantAdminEventsRepoString? status,
    TenantAdminEventsRepoBool? archived,
  }) async {
    if (_eventsPaginationState.isFetchingEventsPage.value ||
        !_eventsPaginationState.hasMoreEvents.value) {
      return;
    }
    await _fetchEventsPage(
      page: TenantAdminEventsRepoInt.fromRaw(
        _eventsPaginationState.currentEventsPage.value + 1,
        defaultValue: 1,
      ),
      pageSize: pageSize ?? _defaultPageSize,
      search: search,
      status: status,
      archived: archived ?? _defaultArchived,
    );
  }

  void resetEventsState() {
    _resetEventsPagination();
    eventsStreamValue.addValue(null);
    eventsErrorStreamValue.addValue(null);
  }

  Future<List<TenantAdminEvent>> fetchEvents({
    TenantAdminEventsRepoString? search,
    TenantAdminEventsRepoString? status,
    TenantAdminEventsRepoBool? archived,
  });

  Future<TenantAdminPagedResult<TenantAdminEvent>> fetchEventsPage({
    required TenantAdminEventsRepoInt page,
    required TenantAdminEventsRepoInt pageSize,
    TenantAdminEventsRepoString? search,
    TenantAdminEventsRepoString? status,
    TenantAdminEventsRepoBool? archived,
  }) async {
    final events = await fetchEvents(
      search: search,
      status: status,
      archived: archived,
    );

    if (page.value <= 0 || pageSize.value <= 0) {
      return TenantAdminPagedResult<TenantAdminEvent>(
        items: <TenantAdminEvent>[],
        hasMore: false,
      );
    }

    final startIndex = (page.value - 1) * pageSize.value;
    if (startIndex >= events.length) {
      return TenantAdminPagedResult<TenantAdminEvent>(
        items: <TenantAdminEvent>[],
        hasMore: false,
      );
    }

    final endIndex = math.min(startIndex + pageSize.value, events.length);
    return TenantAdminPagedResult<TenantAdminEvent>(
      items: events.sublist(startIndex, endIndex),
      hasMore: endIndex < events.length,
    );
  }

  Future<TenantAdminEvent> fetchEvent(
    TenantAdminEventsRepoString eventIdOrSlug,
  );

  Future<TenantAdminEvent> createEvent({
    required TenantAdminEventDraft draft,
  });

  Future<TenantAdminEvent> createOwnEvent({
    required TenantAdminEventsRepoString accountSlug,
    required TenantAdminEventDraft draft,
  });

  Future<TenantAdminEvent> updateEvent({
    required TenantAdminEventsRepoString eventId,
    required TenantAdminEventDraft draft,
  });

  Future<void> deleteEvent(TenantAdminEventsRepoString eventId);

  Future<List<TenantAdminEventType>> fetchEventTypes() async {
    return const <TenantAdminEventType>[];
  }

  Future<TenantAdminEventType> createEventType({
    required TenantAdminEventsRepoString name,
    required TenantAdminEventsRepoString slug,
    TenantAdminEventsRepoString? description,
  }) {
    throw UnimplementedError();
  }

  Future<TenantAdminEventType> updateEventType({
    required TenantAdminEventsRepoString eventTypeId,
    TenantAdminEventsRepoString? name,
    TenantAdminEventsRepoString? slug,
    TenantAdminEventsRepoString? description,
  }) {
    throw UnimplementedError();
  }

  Future<void> deleteEventType(TenantAdminEventsRepoString eventTypeId) async {}

  Future<TenantAdminEventPartyCandidates> fetchPartyCandidates({
    TenantAdminEventsRepoString? search,
    TenantAdminEventsRepoString? accountSlug,
  });

  Future<void> _waitForEventsFetch() async {
    while (_eventsPaginationState.isFetchingEventsPage.value) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
  }

  Future<void> _fetchEventsPage({
    required TenantAdminEventsRepoInt page,
    required TenantAdminEventsRepoInt pageSize,
    TenantAdminEventsRepoString? search,
    TenantAdminEventsRepoString? status,
    required TenantAdminEventsRepoBool archived,
  }) async {
    if (_eventsPaginationState.isFetchingEventsPage.value) {
      return;
    }
    if (page.value > 1 && !_eventsPaginationState.hasMoreEvents.value) {
      return;
    }

    _eventsPaginationState.isFetchingEventsPage = TenantAdminEventsRepoBool.fromRaw(true, defaultValue: true);
    if (page.value > 1) {
      isEventsPageLoadingStreamValue.addValue(TenantAdminEventsRepoBool.fromRaw(true, defaultValue: true));
    }

    try {
      final result = await fetchEventsPage(
        page: page,
        pageSize: pageSize,
        search: search,
        status: status,
        archived: archived,
      );

      if (page.value == 1) {
        _eventsPaginationState.cachedEvents
          ..clear()
          ..addAll(result.items);
      } else {
        _eventsPaginationState.cachedEvents.addAll(result.items);
      }

      _eventsPaginationState.currentEventsPage = page;
      _eventsPaginationState.hasMoreEvents =
          TenantAdminEventsRepoBool.fromRaw(result.hasMore, defaultValue: result.hasMore);
      hasMoreEventsStreamValue.addValue(_eventsPaginationState.hasMoreEvents);
      eventsStreamValue.addValue(
        List<TenantAdminEvent>.unmodifiable(
          _eventsPaginationState.cachedEvents,
        ),
      );
      eventsErrorStreamValue.addValue(null);
    } catch (error) {
      eventsErrorStreamValue.addValue(
        TenantAdminEventsRepoString.fromRaw(error.toString()),
      );
      if (page.value == 1) {
        eventsStreamValue.addValue(const <TenantAdminEvent>[]);
      }
    } finally {
      _eventsPaginationState.isFetchingEventsPage = TenantAdminEventsRepoBool.fromRaw(false, defaultValue: false);
      isEventsPageLoadingStreamValue.addValue(TenantAdminEventsRepoBool.fromRaw(false, defaultValue: false));
    }
  }

  void _resetEventsPagination() {
    _eventsPaginationState.cachedEvents.clear();
    _eventsPaginationState.currentEventsPage = TenantAdminEventsRepoInt.fromRaw(0, defaultValue: 0);
    _eventsPaginationState.hasMoreEvents = TenantAdminEventsRepoBool.fromRaw(true, defaultValue: true);
    _eventsPaginationState.isFetchingEventsPage = TenantAdminEventsRepoBool.fromRaw(false, defaultValue: false);
    hasMoreEventsStreamValue.addValue(TenantAdminEventsRepoBool.fromRaw(true, defaultValue: true));
    isEventsPageLoadingStreamValue.addValue(TenantAdminEventsRepoBool.fromRaw(false, defaultValue: false));
  }
}

mixin TenantAdminEventsPaginationMixin
    implements TenantAdminEventsRepositoryContract {
  static final TenantAdminEventsRepoInt _defaultPageSize =
      TenantAdminEventsRepoInt.fromRaw(20, defaultValue: 20);
  static final TenantAdminEventsRepoBool _defaultArchived =
      TenantAdminEventsRepoBool.fromRaw(false, defaultValue: false);

  static final Expando<_TenantAdminEventsPaginationState>
      _eventsStateByRepository = Expando<_TenantAdminEventsPaginationState>();

  _TenantAdminEventsPaginationState get _mixinEventsPaginationState =>
      _eventsStateByRepository[this] ??= _TenantAdminEventsPaginationState();

  @override
  StreamValue<List<TenantAdminEvent>?> get eventsStreamValue =>
      _mixinEventsPaginationState.eventsStreamValue;

  @override
  StreamValue<TenantAdminEventsRepoBool> get hasMoreEventsStreamValue =>
      _mixinEventsPaginationState.hasMoreEventsStreamValue;

  @override
  StreamValue<TenantAdminEventsRepoBool> get isEventsPageLoadingStreamValue =>
      _mixinEventsPaginationState.isEventsPageLoadingStreamValue;

  @override
  StreamValue<TenantAdminEventsRepoString?> get eventsErrorStreamValue =>
      _mixinEventsPaginationState.eventsErrorStreamValue;

  @override
  Future<void> loadEvents({
    TenantAdminEventsRepoInt? pageSize,
    TenantAdminEventsRepoString? search,
    TenantAdminEventsRepoString? status,
    TenantAdminEventsRepoBool? archived,
  }) async {
    await _waitForEventsFetchMixin();
    _resetEventsPaginationMixin();
    eventsStreamValue.addValue(null);
    await _fetchEventsPageMixin(
      page: TenantAdminEventsRepoInt.fromRaw(1, defaultValue: 1),
      pageSize: pageSize ?? _defaultPageSize,
      search: search,
      status: status,
      archived: archived ?? _defaultArchived,
    );
  }

  @override
  Future<void> loadNextEventsPage({
    TenantAdminEventsRepoInt? pageSize,
    TenantAdminEventsRepoString? search,
    TenantAdminEventsRepoString? status,
    TenantAdminEventsRepoBool? archived,
  }) async {
    if (_mixinEventsPaginationState.isFetchingEventsPage.value ||
        !_mixinEventsPaginationState.hasMoreEvents.value) {
      return;
    }
    await _fetchEventsPageMixin(
      page: TenantAdminEventsRepoInt.fromRaw(
        _mixinEventsPaginationState.currentEventsPage.value + 1,
        defaultValue: 1,
      ),
      pageSize: pageSize ?? _defaultPageSize,
      search: search,
      status: status,
      archived: archived ?? _defaultArchived,
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
    required TenantAdminEventsRepoString name,
    required TenantAdminEventsRepoString slug,
    TenantAdminEventsRepoString? description,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<TenantAdminEventType> updateEventType({
    required TenantAdminEventsRepoString eventTypeId,
    TenantAdminEventsRepoString? name,
    TenantAdminEventsRepoString? slug,
    TenantAdminEventsRepoString? description,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteEventType(TenantAdminEventsRepoString eventTypeId) async {}

  Future<void> _waitForEventsFetchMixin() async {
    while (_mixinEventsPaginationState.isFetchingEventsPage.value) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
  }

  Future<void> _fetchEventsPageMixin({
    required TenantAdminEventsRepoInt page,
    required TenantAdminEventsRepoInt pageSize,
    TenantAdminEventsRepoString? search,
    TenantAdminEventsRepoString? status,
    required TenantAdminEventsRepoBool archived,
  }) async {
    if (_mixinEventsPaginationState.isFetchingEventsPage.value) {
      return;
    }
    if (page.value > 1 && !_mixinEventsPaginationState.hasMoreEvents.value) {
      return;
    }

    _mixinEventsPaginationState.isFetchingEventsPage = TenantAdminEventsRepoBool.fromRaw(true, defaultValue: true);
    if (page.value > 1) {
      isEventsPageLoadingStreamValue.addValue(TenantAdminEventsRepoBool.fromRaw(true, defaultValue: true));
    }

    try {
      final result = await fetchEventsPage(
        page: page,
        pageSize: pageSize,
        search: search,
        status: status,
        archived: archived,
      );
      if (page.value == 1) {
        _mixinEventsPaginationState.cachedEvents
          ..clear()
          ..addAll(result.items);
      } else {
        _mixinEventsPaginationState.cachedEvents.addAll(result.items);
      }
      _mixinEventsPaginationState.currentEventsPage = page;
      _mixinEventsPaginationState.hasMoreEvents =
          TenantAdminEventsRepoBool.fromRaw(result.hasMore, defaultValue: result.hasMore);
      hasMoreEventsStreamValue.addValue(_mixinEventsPaginationState.hasMoreEvents);
      eventsStreamValue.addValue(
        List<TenantAdminEvent>.unmodifiable(
          _mixinEventsPaginationState.cachedEvents,
        ),
      );
      eventsErrorStreamValue.addValue(null);
    } catch (error) {
      eventsErrorStreamValue.addValue(
        TenantAdminEventsRepoString.fromRaw(error.toString()),
      );
      if (page.value == 1) {
        eventsStreamValue.addValue(const <TenantAdminEvent>[]);
      }
    } finally {
      _mixinEventsPaginationState.isFetchingEventsPage = TenantAdminEventsRepoBool.fromRaw(false, defaultValue: false);
      isEventsPageLoadingStreamValue.addValue(TenantAdminEventsRepoBool.fromRaw(false, defaultValue: false));
    }
  }

  void _resetEventsPaginationMixin() {
    _mixinEventsPaginationState.cachedEvents.clear();
    _mixinEventsPaginationState.currentEventsPage = TenantAdminEventsRepoInt.fromRaw(0, defaultValue: 0);
    _mixinEventsPaginationState.hasMoreEvents = TenantAdminEventsRepoBool.fromRaw(true, defaultValue: true);
    _mixinEventsPaginationState.isFetchingEventsPage = TenantAdminEventsRepoBool.fromRaw(false, defaultValue: false);
    hasMoreEventsStreamValue.addValue(TenantAdminEventsRepoBool.fromRaw(true, defaultValue: true));
    isEventsPageLoadingStreamValue.addValue(TenantAdminEventsRepoBool.fromRaw(false, defaultValue: false));
  }
}

class _TenantAdminEventsPaginationState {
  final List<TenantAdminEvent> cachedEvents = <TenantAdminEvent>[];
  final StreamValue<List<TenantAdminEvent>?> eventsStreamValue =
      StreamValue<List<TenantAdminEvent>?>();
  final StreamValue<TenantAdminEventsRepoBool> hasMoreEventsStreamValue =
      StreamValue<TenantAdminEventsRepoBool>(
    defaultValue: TenantAdminEventsRepoBool.fromRaw(true, defaultValue: true),
  );
  final StreamValue<TenantAdminEventsRepoBool> isEventsPageLoadingStreamValue =
      StreamValue<TenantAdminEventsRepoBool>(
    defaultValue: TenantAdminEventsRepoBool.fromRaw(false, defaultValue: false),
  );
  final StreamValue<TenantAdminEventsRepoString?> eventsErrorStreamValue =
      StreamValue<TenantAdminEventsRepoString?>();
  TenantAdminEventsRepoBool isFetchingEventsPage = TenantAdminEventsRepoBool.fromRaw(false, defaultValue: false);
  TenantAdminEventsRepoBool hasMoreEvents = TenantAdminEventsRepoBool.fromRaw(true, defaultValue: true);
  TenantAdminEventsRepoInt currentEventsPage = TenantAdminEventsRepoInt.fromRaw(0, defaultValue: 0);
}
