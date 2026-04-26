import 'dart:math' as math;

import 'package:belluga_now/domain/repositories/value_objects/tenant_admin_events_repository_contract_values.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_account_profile.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_event.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_event_account_profile_candidate_type.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_event_temporal_bucket.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_legacy_event_parties_summary.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_media_upload.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_paged_result.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_poi_visual.dart';
import 'package:stream_value/core/stream_value.dart';

typedef TenantAdminEventsRepoString
    = TenantAdminEventsRepositoryContractTextValue;
typedef TenantAdminEventsRepoInt = TenantAdminEventsRepositoryContractIntValue;
typedef TenantAdminEventsRepoBool
    = TenantAdminEventsRepositoryContractBoolValue;

abstract class TenantAdminEventsRepositoryContract {
  static final TenantAdminEventsRepoInt _defaultPageSize =
      TenantAdminEventsRepoInt.fromRaw(20, defaultValue: 20);
  static final TenantAdminEventsRepoBool _defaultArchived =
      TenantAdminEventsRepoBool.fromRaw(false, defaultValue: false);

  static final Expando<_TenantAdminEventsPaginationState>
      _eventsStateByRepository = Expando<_TenantAdminEventsPaginationState>();
  static final Expando<_TenantAdminEventAccountProfileCandidatesPaginationState>
      _accountProfileCandidatesStateByRepository =
      Expando<_TenantAdminEventAccountProfileCandidatesPaginationState>();

  _TenantAdminEventsPaginationState get _eventsPaginationState =>
      _eventsStateByRepository[this] ??= _TenantAdminEventsPaginationState();
  _TenantAdminEventAccountProfileCandidatesPaginationState
      get _accountProfileCandidatesPaginationState =>
          _accountProfileCandidatesStateByRepository[this] ??=
              _TenantAdminEventAccountProfileCandidatesPaginationState();

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
    TenantAdminEventsRepoString? specificDate,
    TenantAdminEventsRepoString? status,
    TenantAdminEventsRepoString? venueProfileId,
    TenantAdminEventsRepoString? relatedAccountProfileId,
    TenantAdminEventsRepoBool? archived,
    Set<TenantAdminEventTemporalBucket>? temporalBuckets,
  }) async {
    await _waitForEventsFetch();
    _resetEventsPagination();
    eventsStreamValue.addValue(null);
    await _fetchEventsPage(
      page: TenantAdminEventsRepoInt.fromRaw(1, defaultValue: 1),
      pageSize: pageSize ?? _defaultPageSize,
      search: search,
      specificDate: specificDate,
      status: status,
      venueProfileId: venueProfileId,
      relatedAccountProfileId: relatedAccountProfileId,
      archived: archived ?? _defaultArchived,
      temporalBuckets: temporalBuckets,
    );
  }

  Future<void> loadNextEventsPage({
    TenantAdminEventsRepoInt? pageSize,
    TenantAdminEventsRepoString? search,
    TenantAdminEventsRepoString? specificDate,
    TenantAdminEventsRepoString? status,
    TenantAdminEventsRepoString? venueProfileId,
    TenantAdminEventsRepoString? relatedAccountProfileId,
    TenantAdminEventsRepoBool? archived,
    Set<TenantAdminEventTemporalBucket>? temporalBuckets,
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
      specificDate: specificDate,
      status: status,
      venueProfileId: venueProfileId,
      relatedAccountProfileId: relatedAccountProfileId,
      archived: archived ?? _defaultArchived,
      temporalBuckets: temporalBuckets,
    );
  }

  void resetEventsState() {
    _resetEventsPagination();
    eventsStreamValue.addValue(null);
    eventsErrorStreamValue.addValue(null);
  }

  void setEventsState(List<TenantAdminEvent>? events) {
    eventsStreamValue.addValue(events);
  }

  Future<List<TenantAdminEvent>> fetchEvents({
    TenantAdminEventsRepoString? search,
    TenantAdminEventsRepoString? specificDate,
    TenantAdminEventsRepoString? status,
    TenantAdminEventsRepoString? venueProfileId,
    TenantAdminEventsRepoString? relatedAccountProfileId,
    TenantAdminEventsRepoBool? archived,
    Set<TenantAdminEventTemporalBucket>? temporalBuckets,
  });

  Future<TenantAdminPagedResult<TenantAdminEvent>> fetchEventsPage({
    required TenantAdminEventsRepoInt page,
    required TenantAdminEventsRepoInt pageSize,
    TenantAdminEventsRepoString? search,
    TenantAdminEventsRepoString? specificDate,
    TenantAdminEventsRepoString? status,
    TenantAdminEventsRepoString? venueProfileId,
    TenantAdminEventsRepoString? relatedAccountProfileId,
    TenantAdminEventsRepoBool? archived,
    Set<TenantAdminEventTemporalBucket>? temporalBuckets,
  }) async {
    final events = await fetchEvents(
      search: search,
      specificDate: specificDate,
      status: status,
      venueProfileId: venueProfileId,
      relatedAccountProfileId: relatedAccountProfileId,
      archived: archived,
      temporalBuckets: temporalBuckets,
    );

    if (page.value <= 0 || pageSize.value <= 0) {
      return tenantAdminPagedResultFromRaw(
        items: <TenantAdminEvent>[],
        hasMore: false,
      );
    }

    final startIndex = (page.value - 1) * pageSize.value;
    if (startIndex >= events.length) {
      return tenantAdminPagedResultFromRaw(
        items: <TenantAdminEvent>[],
        hasMore: false,
      );
    }

    final endIndex = math.min(startIndex + pageSize.value, events.length);
    return tenantAdminPagedResultFromRaw(
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

  Future<TenantAdminLegacyEventPartiesSummary>
      fetchLegacyEventPartiesSummary() {
    throw UnimplementedError();
  }

  Future<TenantAdminLegacyEventPartiesSummary> repairLegacyEventParties() {
    throw UnimplementedError();
  }

  Future<List<TenantAdminEventType>> fetchEventTypes() async {
    return const <TenantAdminEventType>[];
  }

  Future<TenantAdminEventType> createEventType({
    required TenantAdminEventsRepoString name,
    required TenantAdminEventsRepoString slug,
    TenantAdminEventsRepoString? description,
    List<TenantAdminEventsRepoString>? allowedTaxonomies,
  }) {
    throw UnimplementedError();
  }

  Future<TenantAdminEventType> createEventTypeWithVisual({
    required TenantAdminEventsRepoString name,
    required TenantAdminEventsRepoString slug,
    TenantAdminEventsRepoString? description,
    List<TenantAdminEventsRepoString>? allowedTaxonomies,
    TenantAdminPoiVisual? visual,
    TenantAdminMediaUpload? typeAssetUpload,
  }) {
    throw UnimplementedError();
  }

  Future<TenantAdminEventType> updateEventType({
    required TenantAdminEventsRepoString eventTypeId,
    TenantAdminEventsRepoString? name,
    TenantAdminEventsRepoString? slug,
    TenantAdminEventsRepoString? description,
    List<TenantAdminEventsRepoString>? allowedTaxonomies,
  }) {
    throw UnimplementedError();
  }

  Future<TenantAdminEventType> updateEventTypeWithVisual({
    required TenantAdminEventsRepoString eventTypeId,
    TenantAdminEventsRepoString? name,
    TenantAdminEventsRepoString? slug,
    TenantAdminEventsRepoString? description,
    List<TenantAdminEventsRepoString>? allowedTaxonomies,
    TenantAdminPoiVisual? visual,
    TenantAdminMediaUpload? typeAssetUpload,
    TenantAdminEventsRepoBool? removeTypeAsset,
  }) {
    throw UnimplementedError();
  }

  Future<void> deleteEventType(TenantAdminEventsRepoString eventTypeId) async {}

  Future<TenantAdminPagedResult<TenantAdminAccountProfile>>
      fetchEventAccountProfileCandidatesPage({
    required TenantAdminEventAccountProfileCandidateType candidateType,
    required TenantAdminEventsRepoInt page,
    required TenantAdminEventsRepoInt pageSize,
    TenantAdminEventsRepoString? search,
    TenantAdminEventsRepoString? accountSlug,
  });

  Future<TenantAdminPagedResult<TenantAdminAccountProfile>>
      loadEventAccountProfileCandidates({
    required TenantAdminEventAccountProfileCandidateType candidateType,
    TenantAdminEventsRepoString? search,
    TenantAdminEventsRepoString? accountSlug,
  }) async {
    await _waitForEventAccountProfileCandidatesFetch();
    _resetEventAccountProfileCandidatesPagination();

    return _fetchEventAccountProfileCandidatesPageInternal(
      candidateType: candidateType,
      page: TenantAdminEventsRepoInt.fromRaw(1, defaultValue: 1),
      search: search,
      accountSlug: accountSlug,
    );
  }

  Future<TenantAdminPagedResult<TenantAdminAccountProfile>>
      loadNextEventAccountProfileCandidates({
    required TenantAdminEventAccountProfileCandidateType candidateType,
    TenantAdminEventsRepoString? search,
    TenantAdminEventsRepoString? accountSlug,
  }) async {
    if (_accountProfileCandidatesPaginationState.isFetching.value ||
        !_accountProfileCandidatesPaginationState.hasMore.value) {
      return tenantAdminPagedResultFromRaw(
        items: List<TenantAdminAccountProfile>.unmodifiable(
          _accountProfileCandidatesPaginationState.cachedItems,
        ),
        hasMore: _accountProfileCandidatesPaginationState.hasMore.value,
      );
    }

    return _fetchEventAccountProfileCandidatesPageInternal(
      candidateType: candidateType,
      page: TenantAdminEventsRepoInt.fromRaw(
        _accountProfileCandidatesPaginationState.currentPage.value + 1,
        defaultValue: 1,
      ),
      search: search,
      accountSlug: accountSlug,
    );
  }

  Future<List<TenantAdminAccountProfile>>
      fetchAllEventAccountProfileCandidates({
    required TenantAdminEventAccountProfileCandidateType candidateType,
    TenantAdminEventsRepoString? search,
    TenantAdminEventsRepoString? accountSlug,
  }) async {
    await _waitForEventAccountProfileCandidatesFetch();

    final items = <TenantAdminAccountProfile>[];
    var currentPage = 1;
    var hasMore = true;

    while (hasMore) {
      final result = await fetchEventAccountProfileCandidatesPage(
        candidateType: candidateType,
        page: TenantAdminEventsRepoInt.fromRaw(
          currentPage,
          defaultValue: currentPage,
        ),
        pageSize: _eventAccountProfileCandidatesPageSize(candidateType),
        search: search,
        accountSlug: accountSlug,
      );
      items.addAll(result.items);
      hasMore = result.hasMore;
      currentPage += 1;
    }

    return List<TenantAdminAccountProfile>.unmodifiable(items);
  }

  Future<void> _waitForEventsFetch() async {
    while (_eventsPaginationState.isFetchingEventsPage.value) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
  }

  Future<void> _waitForEventAccountProfileCandidatesFetch() async {
    while (_accountProfileCandidatesPaginationState.isFetching.value) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
  }

  Future<void> _fetchEventsPage({
    required TenantAdminEventsRepoInt page,
    required TenantAdminEventsRepoInt pageSize,
    TenantAdminEventsRepoString? search,
    TenantAdminEventsRepoString? specificDate,
    TenantAdminEventsRepoString? status,
    TenantAdminEventsRepoString? venueProfileId,
    TenantAdminEventsRepoString? relatedAccountProfileId,
    required TenantAdminEventsRepoBool archived,
    Set<TenantAdminEventTemporalBucket>? temporalBuckets,
  }) async {
    if (_eventsPaginationState.isFetchingEventsPage.value) {
      return;
    }
    if (page.value > 1 && !_eventsPaginationState.hasMoreEvents.value) {
      return;
    }

    _eventsPaginationState.isFetchingEventsPage =
        TenantAdminEventsRepoBool.fromRaw(true, defaultValue: true);
    if (page.value > 1) {
      isEventsPageLoadingStreamValue.addValue(
          TenantAdminEventsRepoBool.fromRaw(true, defaultValue: true));
    }

    try {
      final result = await fetchEventsPage(
        page: page,
        pageSize: pageSize,
        search: search,
        specificDate: specificDate,
        status: status,
        venueProfileId: venueProfileId,
        relatedAccountProfileId: relatedAccountProfileId,
        archived: archived,
        temporalBuckets: temporalBuckets,
      );

      if (page.value == 1) {
        _eventsPaginationState.cachedEvents
          ..clear()
          ..addAll(result.items);
      } else {
        _eventsPaginationState.cachedEvents.addAll(result.items);
      }

      _eventsPaginationState.currentEventsPage = page;
      _eventsPaginationState.hasMoreEvents = TenantAdminEventsRepoBool.fromRaw(
          result.hasMore,
          defaultValue: result.hasMore);
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
      _eventsPaginationState.isFetchingEventsPage =
          TenantAdminEventsRepoBool.fromRaw(false, defaultValue: false);
      isEventsPageLoadingStreamValue.addValue(
          TenantAdminEventsRepoBool.fromRaw(false, defaultValue: false));
    }
  }

  void _resetEventsPagination() {
    _eventsPaginationState.cachedEvents.clear();
    _eventsPaginationState.currentEventsPage =
        TenantAdminEventsRepoInt.fromRaw(0, defaultValue: 0);
    _eventsPaginationState.hasMoreEvents =
        TenantAdminEventsRepoBool.fromRaw(true, defaultValue: true);
    _eventsPaginationState.isFetchingEventsPage =
        TenantAdminEventsRepoBool.fromRaw(false, defaultValue: false);
    hasMoreEventsStreamValue
        .addValue(TenantAdminEventsRepoBool.fromRaw(true, defaultValue: true));
    isEventsPageLoadingStreamValue.addValue(
        TenantAdminEventsRepoBool.fromRaw(false, defaultValue: false));
  }

  Future<TenantAdminPagedResult<TenantAdminAccountProfile>>
      _fetchEventAccountProfileCandidatesPageInternal({
    required TenantAdminEventAccountProfileCandidateType candidateType,
    required TenantAdminEventsRepoInt page,
    TenantAdminEventsRepoString? search,
    TenantAdminEventsRepoString? accountSlug,
  }) async {
    if (_accountProfileCandidatesPaginationState.isFetching.value) {
      return tenantAdminPagedResultFromRaw(
        items: List<TenantAdminAccountProfile>.unmodifiable(
          _accountProfileCandidatesPaginationState.cachedItems,
        ),
        hasMore: _accountProfileCandidatesPaginationState.hasMore.value,
      );
    }
    if (page.value > 1 &&
        !_accountProfileCandidatesPaginationState.hasMore.value) {
      return tenantAdminPagedResultFromRaw(
        items: List<TenantAdminAccountProfile>.unmodifiable(
          _accountProfileCandidatesPaginationState.cachedItems,
        ),
        hasMore: false,
      );
    }

    _accountProfileCandidatesPaginationState.isFetching =
        TenantAdminEventsRepoBool.fromRaw(true, defaultValue: true);

    try {
      final result = await fetchEventAccountProfileCandidatesPage(
        candidateType: candidateType,
        page: page,
        pageSize: _eventAccountProfileCandidatesPageSize(candidateType),
        search: search,
        accountSlug: accountSlug,
      );

      if (page.value <= 1) {
        _accountProfileCandidatesPaginationState.cachedItems
          ..clear()
          ..addAll(result.items);
      } else {
        _accountProfileCandidatesPaginationState.cachedItems
            .addAll(result.items);
      }

      _accountProfileCandidatesPaginationState.currentPage = page;
      _accountProfileCandidatesPaginationState.hasMore =
          TenantAdminEventsRepoBool.fromRaw(
        result.hasMore,
        defaultValue: result.hasMore,
      );

      return tenantAdminPagedResultFromRaw(
        items: List<TenantAdminAccountProfile>.unmodifiable(
          _accountProfileCandidatesPaginationState.cachedItems,
        ),
        hasMore: result.hasMore,
      );
    } finally {
      _accountProfileCandidatesPaginationState.isFetching =
          TenantAdminEventsRepoBool.fromRaw(false, defaultValue: false);
    }
  }

  void _resetEventAccountProfileCandidatesPagination() {
    _accountProfileCandidatesPaginationState.cachedItems.clear();
    _accountProfileCandidatesPaginationState.currentPage =
        TenantAdminEventsRepoInt.fromRaw(0, defaultValue: 0);
    _accountProfileCandidatesPaginationState.hasMore =
        TenantAdminEventsRepoBool.fromRaw(true, defaultValue: true);
    _accountProfileCandidatesPaginationState.isFetching =
        TenantAdminEventsRepoBool.fromRaw(false, defaultValue: false);
  }

  TenantAdminEventsRepoInt _eventAccountProfileCandidatesPageSize(
    TenantAdminEventAccountProfileCandidateType candidateType,
  ) {
    final rawValue = switch (candidateType) {
      TenantAdminEventAccountProfileCandidateType.relatedAccountProfile => 20,
      TenantAdminEventAccountProfileCandidateType.physicalHost => 50,
    };

    return TenantAdminEventsRepoInt.fromRaw(
      rawValue,
      defaultValue: rawValue,
    );
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
  static final Expando<_TenantAdminEventAccountProfileCandidatesPaginationState>
      _accountProfileCandidatesStateByRepository =
      Expando<_TenantAdminEventAccountProfileCandidatesPaginationState>();

  _TenantAdminEventsPaginationState get _mixinEventsPaginationState =>
      _eventsStateByRepository[this] ??= _TenantAdminEventsPaginationState();
  _TenantAdminEventAccountProfileCandidatesPaginationState
      get _mixinAccountProfileCandidatesPaginationState =>
          _accountProfileCandidatesStateByRepository[this] ??=
              _TenantAdminEventAccountProfileCandidatesPaginationState();

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
    TenantAdminEventsRepoString? specificDate,
    TenantAdminEventsRepoString? status,
    TenantAdminEventsRepoString? venueProfileId,
    TenantAdminEventsRepoString? relatedAccountProfileId,
    TenantAdminEventsRepoBool? archived,
    Set<TenantAdminEventTemporalBucket>? temporalBuckets,
  }) async {
    await _waitForEventsFetchMixin();
    _resetEventsPaginationMixin();
    eventsStreamValue.addValue(null);
    await _fetchEventsPageMixin(
      page: TenantAdminEventsRepoInt.fromRaw(1, defaultValue: 1),
      pageSize: pageSize ?? _defaultPageSize,
      search: search,
      specificDate: specificDate,
      status: status,
      venueProfileId: venueProfileId,
      relatedAccountProfileId: relatedAccountProfileId,
      archived: archived ?? _defaultArchived,
      temporalBuckets: temporalBuckets,
    );
  }

  @override
  Future<void> loadNextEventsPage({
    TenantAdminEventsRepoInt? pageSize,
    TenantAdminEventsRepoString? search,
    TenantAdminEventsRepoString? specificDate,
    TenantAdminEventsRepoString? status,
    TenantAdminEventsRepoString? venueProfileId,
    TenantAdminEventsRepoString? relatedAccountProfileId,
    TenantAdminEventsRepoBool? archived,
    Set<TenantAdminEventTemporalBucket>? temporalBuckets,
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
      specificDate: specificDate,
      status: status,
      venueProfileId: venueProfileId,
      relatedAccountProfileId: relatedAccountProfileId,
      archived: archived ?? _defaultArchived,
      temporalBuckets: temporalBuckets,
    );
  }

  @override
  void resetEventsState() {
    _resetEventsPaginationMixin();
    eventsStreamValue.addValue(null);
    eventsErrorStreamValue.addValue(null);
  }

  @override
  void setEventsState(List<TenantAdminEvent>? events) {
    eventsStreamValue.addValue(events);
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
    List<TenantAdminEventsRepoString>? allowedTaxonomies,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<TenantAdminEventType> updateEventType({
    required TenantAdminEventsRepoString eventTypeId,
    TenantAdminEventsRepoString? name,
    TenantAdminEventsRepoString? slug,
    TenantAdminEventsRepoString? description,
    List<TenantAdminEventsRepoString>? allowedTaxonomies,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteEventType(TenantAdminEventsRepoString eventTypeId) async {}

  @override
  Future<TenantAdminPagedResult<TenantAdminAccountProfile>>
      loadEventAccountProfileCandidates({
    required TenantAdminEventAccountProfileCandidateType candidateType,
    TenantAdminEventsRepoString? search,
    TenantAdminEventsRepoString? accountSlug,
  }) async {
    await _waitForEventAccountProfileCandidatesFetchMixin();
    _resetEventAccountProfileCandidatesPaginationMixin();

    return _fetchEventAccountProfileCandidatesPageMixin(
      candidateType: candidateType,
      page: TenantAdminEventsRepoInt.fromRaw(1, defaultValue: 1),
      search: search,
      accountSlug: accountSlug,
    );
  }

  @override
  Future<TenantAdminPagedResult<TenantAdminAccountProfile>>
      loadNextEventAccountProfileCandidates({
    required TenantAdminEventAccountProfileCandidateType candidateType,
    TenantAdminEventsRepoString? search,
    TenantAdminEventsRepoString? accountSlug,
  }) async {
    if (_mixinAccountProfileCandidatesPaginationState.isFetching.value ||
        !_mixinAccountProfileCandidatesPaginationState.hasMore.value) {
      return tenantAdminPagedResultFromRaw(
        items: List<TenantAdminAccountProfile>.unmodifiable(
          _mixinAccountProfileCandidatesPaginationState.cachedItems,
        ),
        hasMore: _mixinAccountProfileCandidatesPaginationState.hasMore.value,
      );
    }

    return _fetchEventAccountProfileCandidatesPageMixin(
      candidateType: candidateType,
      page: TenantAdminEventsRepoInt.fromRaw(
        _mixinAccountProfileCandidatesPaginationState.currentPage.value + 1,
        defaultValue: 1,
      ),
      search: search,
      accountSlug: accountSlug,
    );
  }

  @override
  Future<List<TenantAdminAccountProfile>>
      fetchAllEventAccountProfileCandidates({
    required TenantAdminEventAccountProfileCandidateType candidateType,
    TenantAdminEventsRepoString? search,
    TenantAdminEventsRepoString? accountSlug,
  }) async {
    await _waitForEventAccountProfileCandidatesFetchMixin();

    final items = <TenantAdminAccountProfile>[];
    var currentPage = 1;
    var hasMore = true;

    while (hasMore) {
      final result = await fetchEventAccountProfileCandidatesPage(
        candidateType: candidateType,
        page: TenantAdminEventsRepoInt.fromRaw(
          currentPage,
          defaultValue: currentPage,
        ),
        pageSize: _eventAccountProfileCandidatesPageSizeMixin(candidateType),
        search: search,
        accountSlug: accountSlug,
      );
      items.addAll(result.items);
      hasMore = result.hasMore;
      currentPage += 1;
    }

    return List<TenantAdminAccountProfile>.unmodifiable(items);
  }

  Future<void> _waitForEventsFetchMixin() async {
    while (_mixinEventsPaginationState.isFetchingEventsPage.value) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
  }

  Future<void> _waitForEventAccountProfileCandidatesFetchMixin() async {
    while (_mixinAccountProfileCandidatesPaginationState.isFetching.value) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
  }

  Future<void> _fetchEventsPageMixin({
    required TenantAdminEventsRepoInt page,
    required TenantAdminEventsRepoInt pageSize,
    TenantAdminEventsRepoString? search,
    TenantAdminEventsRepoString? specificDate,
    TenantAdminEventsRepoString? status,
    TenantAdminEventsRepoString? venueProfileId,
    TenantAdminEventsRepoString? relatedAccountProfileId,
    required TenantAdminEventsRepoBool archived,
    Set<TenantAdminEventTemporalBucket>? temporalBuckets,
  }) async {
    if (_mixinEventsPaginationState.isFetchingEventsPage.value) {
      return;
    }
    if (page.value > 1 && !_mixinEventsPaginationState.hasMoreEvents.value) {
      return;
    }

    _mixinEventsPaginationState.isFetchingEventsPage =
        TenantAdminEventsRepoBool.fromRaw(true, defaultValue: true);
    if (page.value > 1) {
      isEventsPageLoadingStreamValue.addValue(
          TenantAdminEventsRepoBool.fromRaw(true, defaultValue: true));
    }

    try {
      final result = await fetchEventsPage(
        page: page,
        pageSize: pageSize,
        search: search,
        specificDate: specificDate,
        status: status,
        venueProfileId: venueProfileId,
        relatedAccountProfileId: relatedAccountProfileId,
        archived: archived,
        temporalBuckets: temporalBuckets,
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
          TenantAdminEventsRepoBool.fromRaw(result.hasMore,
              defaultValue: result.hasMore);
      hasMoreEventsStreamValue
          .addValue(_mixinEventsPaginationState.hasMoreEvents);
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
      _mixinEventsPaginationState.isFetchingEventsPage =
          TenantAdminEventsRepoBool.fromRaw(false, defaultValue: false);
      isEventsPageLoadingStreamValue.addValue(
          TenantAdminEventsRepoBool.fromRaw(false, defaultValue: false));
    }
  }

  void _resetEventsPaginationMixin() {
    _mixinEventsPaginationState.cachedEvents.clear();
    _mixinEventsPaginationState.currentEventsPage =
        TenantAdminEventsRepoInt.fromRaw(0, defaultValue: 0);
    _mixinEventsPaginationState.hasMoreEvents =
        TenantAdminEventsRepoBool.fromRaw(true, defaultValue: true);
    _mixinEventsPaginationState.isFetchingEventsPage =
        TenantAdminEventsRepoBool.fromRaw(false, defaultValue: false);
    hasMoreEventsStreamValue
        .addValue(TenantAdminEventsRepoBool.fromRaw(true, defaultValue: true));
    isEventsPageLoadingStreamValue.addValue(
        TenantAdminEventsRepoBool.fromRaw(false, defaultValue: false));
  }

  Future<TenantAdminPagedResult<TenantAdminAccountProfile>>
      _fetchEventAccountProfileCandidatesPageMixin({
    required TenantAdminEventAccountProfileCandidateType candidateType,
    required TenantAdminEventsRepoInt page,
    TenantAdminEventsRepoString? search,
    TenantAdminEventsRepoString? accountSlug,
  }) async {
    if (_mixinAccountProfileCandidatesPaginationState.isFetching.value) {
      return tenantAdminPagedResultFromRaw(
        items: List<TenantAdminAccountProfile>.unmodifiable(
          _mixinAccountProfileCandidatesPaginationState.cachedItems,
        ),
        hasMore: _mixinAccountProfileCandidatesPaginationState.hasMore.value,
      );
    }
    if (page.value > 1 &&
        !_mixinAccountProfileCandidatesPaginationState.hasMore.value) {
      return tenantAdminPagedResultFromRaw(
        items: List<TenantAdminAccountProfile>.unmodifiable(
          _mixinAccountProfileCandidatesPaginationState.cachedItems,
        ),
        hasMore: false,
      );
    }

    _mixinAccountProfileCandidatesPaginationState.isFetching =
        TenantAdminEventsRepoBool.fromRaw(true, defaultValue: true);

    try {
      final result = await fetchEventAccountProfileCandidatesPage(
        candidateType: candidateType,
        page: page,
        pageSize: _eventAccountProfileCandidatesPageSizeMixin(candidateType),
        search: search,
        accountSlug: accountSlug,
      );

      if (page.value <= 1) {
        _mixinAccountProfileCandidatesPaginationState.cachedItems
          ..clear()
          ..addAll(result.items);
      } else {
        _mixinAccountProfileCandidatesPaginationState.cachedItems
            .addAll(result.items);
      }

      _mixinAccountProfileCandidatesPaginationState.currentPage = page;
      _mixinAccountProfileCandidatesPaginationState.hasMore =
          TenantAdminEventsRepoBool.fromRaw(
        result.hasMore,
        defaultValue: result.hasMore,
      );

      return tenantAdminPagedResultFromRaw(
        items: List<TenantAdminAccountProfile>.unmodifiable(
          _mixinAccountProfileCandidatesPaginationState.cachedItems,
        ),
        hasMore: result.hasMore,
      );
    } finally {
      _mixinAccountProfileCandidatesPaginationState.isFetching =
          TenantAdminEventsRepoBool.fromRaw(false, defaultValue: false);
    }
  }

  void _resetEventAccountProfileCandidatesPaginationMixin() {
    _mixinAccountProfileCandidatesPaginationState.cachedItems.clear();
    _mixinAccountProfileCandidatesPaginationState.currentPage =
        TenantAdminEventsRepoInt.fromRaw(0, defaultValue: 0);
    _mixinAccountProfileCandidatesPaginationState.hasMore =
        TenantAdminEventsRepoBool.fromRaw(true, defaultValue: true);
    _mixinAccountProfileCandidatesPaginationState.isFetching =
        TenantAdminEventsRepoBool.fromRaw(false, defaultValue: false);
  }

  TenantAdminEventsRepoInt _eventAccountProfileCandidatesPageSizeMixin(
    TenantAdminEventAccountProfileCandidateType candidateType,
  ) {
    final rawValue = switch (candidateType) {
      TenantAdminEventAccountProfileCandidateType.relatedAccountProfile => 20,
      TenantAdminEventAccountProfileCandidateType.physicalHost => 50,
    };

    return TenantAdminEventsRepoInt.fromRaw(
      rawValue,
      defaultValue: rawValue,
    );
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
  TenantAdminEventsRepoBool isFetchingEventsPage =
      TenantAdminEventsRepoBool.fromRaw(false, defaultValue: false);
  TenantAdminEventsRepoBool hasMoreEvents =
      TenantAdminEventsRepoBool.fromRaw(true, defaultValue: true);
  TenantAdminEventsRepoInt currentEventsPage =
      TenantAdminEventsRepoInt.fromRaw(0, defaultValue: 0);
}

class _TenantAdminEventAccountProfileCandidatesPaginationState {
  final List<TenantAdminAccountProfile> cachedItems =
      <TenantAdminAccountProfile>[];
  TenantAdminEventsRepoBool isFetching =
      TenantAdminEventsRepoBool.fromRaw(false, defaultValue: false);
  TenantAdminEventsRepoBool hasMore =
      TenantAdminEventsRepoBool.fromRaw(true, defaultValue: true);
  TenantAdminEventsRepoInt currentPage =
      TenantAdminEventsRepoInt.fromRaw(0, defaultValue: 0);
}
