import 'package:belluga_now/domain/repositories/landlord_auth_repository_contract.dart';
import 'package:belluga_now/domain/repositories/tenant_admin_events_repository_contract.dart';
import 'package:belluga_now/domain/repositories/tenant_admin_taxonomies_repository_contract.dart';
import 'package:belluga_now/domain/services/tenant_admin_tenant_scope_contract.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_account_profile.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_event.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_paged_result.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_definition.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_term_definition.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_value_parsers.dart';
import 'package:belluga_now/presentation/tenant_admin/events/controllers/tenant_admin_events_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stream_value/core/stream_value.dart';

void main() {
  test('deleteEvent rethrows repository errors and updates error stream',
      () async {
    final eventsRepository = _FailingDeleteEventsRepository();
    final controller = TenantAdminEventsController(
      eventsRepository: eventsRepository,
      taxonomiesRepository: _NoopTaxonomiesRepository(),
      landlordAuthRepository:
          _FakeLandlordAuthRepositoryWithToken('landlord-token'),
    );

    await expectLater(
      () => controller.deleteEvent('evt-1'),
      throwsA(isA<StateError>()),
    );

    final error = controller.eventsErrorStreamValue.value;
    expect(error, isNotNull);
    expect(error, contains('delete failed'));
  });

  test('loadEvents forwards archived filter to repository', () async {
    final eventsRepository = _TrackingEventsRepository();
    final controller = TenantAdminEventsController(
      eventsRepository: eventsRepository,
      taxonomiesRepository: _NoopTaxonomiesRepository(),
      landlordAuthRepository:
          _FakeLandlordAuthRepositoryWithToken('landlord-token'),
    );

    controller.updateArchivedFilter(true);
    await controller.loadEvents();

    expect(eventsRepository.lastLoadArchived, isTrue);
  });

  test(
      'account-scoped loadFormDependencies uses dedicated event types endpoint and account party candidates',
      () async {
    final eventsRepository = _AccountScopedEventsRepository();
    final controller = TenantAdminEventsController(
      eventsRepository: eventsRepository,
      taxonomiesRepository: _NoopTaxonomiesRepository(),
    );

    await controller.loadFormDependencies(accountSlug: 'my-account');

    expect(eventsRepository.fetchEventTypesCalls, 1);
    expect(eventsRepository.fetchEventsCalls, 0);
    expect(eventsRepository.partyCandidatesCalls, 1);
    expect(eventsRepository.lastPartyCandidatesAccountSlug, 'my-account');
  });

  test('account-scoped submitCreate does not refresh tenant-admin events list',
      () async {
    final eventsRepository = _AccountScopedEventsRepository();
    final controller = TenantAdminEventsController(
      eventsRepository: eventsRepository,
      taxonomiesRepository: _NoopTaxonomiesRepository(),
    );

    final created = await controller.submitCreate(
      _buildDraft(),
      accountSlug: 'my-account',
    );

    expect(created, isNotNull);
    expect(eventsRepository.createOwnCalls, 1);
    expect(eventsRepository.fetchEventsPageCalls, 0);
    expect(controller.submitErrorMessageStreamValue.value, isNull);
  });

  test('submitCreate ignores concurrent submission while loading', () async {
    final eventsRepository = _AccountScopedEventsRepository();
    final controller = TenantAdminEventsController(
      eventsRepository: eventsRepository,
      taxonomiesRepository: _NoopTaxonomiesRepository(),
    );

    final first = controller.submitCreate(
      _buildDraft(),
      accountSlug: 'my-account',
    );
    final second = controller.submitCreate(
      _buildDraft(),
      accountSlug: 'my-account',
    );

    final secondResult = await second;
    await first;

    expect(secondResult, isNull);
    expect(eventsRepository.createOwnCalls, 1);
  });

  test('tenant scope change without landlord token skips admin events load',
      () async {
    final eventsRepository = _TrackingEventsRepository();
    final tenantScope = _FakeTenantScope();
    final controller = TenantAdminEventsController(
      eventsRepository: eventsRepository,
      taxonomiesRepository: _NoopTaxonomiesRepository(),
      tenantScope: tenantScope,
      landlordAuthRepository: _FakeLandlordAuthRepositoryWithToken(''),
    );

    tenantScope.selectTenantDomain('guarappari.belluga.space');
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(eventsRepository.fetchEventsCalls, 0);
    expect(eventsRepository.fetchEventsPageCalls, 0);
    expect(controller.eventsStreamValue.value, isEmpty);
    expect(controller.eventsErrorStreamValue.value, isNull);
  });

  test('saveEventType sends null description when edit description is cleared',
      () async {
    final eventsRepository = _EventTypeUpdateTrackingRepository();
    final controller = TenantAdminEventsController(
      eventsRepository: eventsRepository,
      taxonomiesRepository: _NoopTaxonomiesRepository(),
      landlordAuthRepository:
          _FakeLandlordAuthRepositoryWithToken('landlord-token'),
    );

    await controller.saveEventType(
      name: 'Show',
      slug: 'show',
      description: '   ',
      existingType: TenantAdminEventType(
        id: '507f1f77bcf86cd799439011',
        name: 'Show',
        slug: 'show',
        description: 'Legacy description',
      ),
    );

    expect(eventsRepository.lastUpdateDescription, isNull);
  });
}

TenantAdminEventDraft _buildDraft() {
  return TenantAdminEventDraft(
    title: 'My event',
    content: 'Content',
    type: TenantAdminEventType(
      name: 'Show',
      slug: 'show',
    ),
    occurrences: [
      TenantAdminEventOccurrence(
        dateTimeStartValue: tenantAdminDateTime(DateTime(2026, 3, 5, 20)),
      ),
    ],
    publication: TenantAdminEventPublication(
      statusValue: tenantAdminRequiredText('draft'),
    ),
  );
}

class _FailingDeleteEventsRepository
    with TenantAdminEventsPaginationMixin
    implements TenantAdminEventsRepositoryContract {
  @override
  Future<TenantAdminEvent> createEvent({
    required TenantAdminEventDraft draft,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<TenantAdminEvent> createOwnEvent({
    required TenantAdminEventsRepoString accountSlug,
    required TenantAdminEventDraft draft,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteEvent(TenantAdminEventsRepoString eventId) async {
    throw StateError('delete failed');
  }

  @override
  Future<TenantAdminEvent> fetchEvent(TenantAdminEventsRepoString eventIdOrSlug) async {
    throw UnimplementedError();
  }

  @override
  Future<List<TenantAdminEvent>> fetchEvents({
    TenantAdminEventsRepoString? search,
    TenantAdminEventsRepoString? status,
    TenantAdminEventsRepoBool? archived,
  }) async {
    return <TenantAdminEvent>[];
  }

  @override
  Future<TenantAdminPagedResult<TenantAdminEvent>> fetchEventsPage({
    required TenantAdminEventsRepoInt page,
    required TenantAdminEventsRepoInt pageSize,
    TenantAdminEventsRepoString? search,
    TenantAdminEventsRepoString? status,
    TenantAdminEventsRepoBool? archived,
  }) async {
    return TenantAdminPagedResult<TenantAdminEvent>(
      items: <TenantAdminEvent>[],
      hasMore: false,
    );
  }

  @override
  Future<TenantAdminEventPartyCandidates> fetchPartyCandidates({
    TenantAdminEventsRepoString? search,
    TenantAdminEventsRepoString? accountSlug,
  }) async {
    return TenantAdminEventPartyCandidates(
      venues: <TenantAdminAccountProfile>[],
      artists: <TenantAdminAccountProfile>[],
    );
  }

  @override
  Future<TenantAdminEvent> updateEvent({
    required TenantAdminEventsRepoString eventId,
    required TenantAdminEventDraft draft,
  }) async {
    throw UnimplementedError();
  }
}

class _NoopTaxonomiesRepository
    with TenantAdminTaxonomiesPaginationMixin
    implements TenantAdminTaxonomiesRepositoryContract {
  @override
  Future<TenantAdminTaxonomyDefinition> createTaxonomy({
    required String slug,
    required String name,
    required List<String> appliesTo,
    String? icon,
    String? color,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<TenantAdminTaxonomyTermDefinition> createTerm({
    required String taxonomyId,
    required String slug,
    required String name,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteTaxonomy(String taxonomyId) async {}

  @override
  Future<void> deleteTerm({
    required String taxonomyId,
    required String termId,
  }) async {}

  @override
  Future<List<TenantAdminTaxonomyDefinition>> fetchTaxonomies() async {
    return <TenantAdminTaxonomyDefinition>[];
  }

  @override
  Future<TenantAdminPagedResult<TenantAdminTaxonomyDefinition>>
      fetchTaxonomiesPage({
    required int page,
    required int pageSize,
  }) async {
    return TenantAdminPagedResult<TenantAdminTaxonomyDefinition>(
      items: <TenantAdminTaxonomyDefinition>[],
      hasMore: false,
    );
  }

  @override
  Future<List<TenantAdminTaxonomyTermDefinition>> fetchTerms({
    required String taxonomyId,
  }) async {
    return <TenantAdminTaxonomyTermDefinition>[];
  }

  @override
  Future<TenantAdminPagedResult<TenantAdminTaxonomyTermDefinition>>
      fetchTermsPage({
    required String taxonomyId,
    required int page,
    required int pageSize,
  }) async {
    return TenantAdminPagedResult<TenantAdminTaxonomyTermDefinition>(
      items: <TenantAdminTaxonomyTermDefinition>[],
      hasMore: false,
    );
  }

  @override
  Future<TenantAdminTaxonomyDefinition> updateTaxonomy({
    required String taxonomyId,
    String? slug,
    String? name,
    List<String>? appliesTo,
    String? icon,
    String? color,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<TenantAdminTaxonomyTermDefinition> updateTerm({
    required String taxonomyId,
    required String termId,
    String? slug,
    String? name,
  }) async {
    throw UnimplementedError();
  }
}

class _TrackingEventsRepository
    with TenantAdminEventsPaginationMixin
    implements TenantAdminEventsRepositoryContract {
  int fetchEventsCalls = 0;
  int fetchEventsPageCalls = 0;
  bool? lastLoadArchived;

  @override
  Future<TenantAdminEvent> createEvent({
    required TenantAdminEventDraft draft,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<TenantAdminEvent> createOwnEvent({
    required TenantAdminEventsRepoString accountSlug,
    required TenantAdminEventDraft draft,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteEvent(TenantAdminEventsRepoString eventId) async {}

  @override
  Future<TenantAdminEvent> fetchEvent(TenantAdminEventsRepoString eventIdOrSlug) async {
    throw UnimplementedError();
  }

  @override
  Future<List<TenantAdminEvent>> fetchEvents({
    TenantAdminEventsRepoString? search,
    TenantAdminEventsRepoString? status,
    TenantAdminEventsRepoBool? archived,
  }) async {
    fetchEventsCalls += 1;
    lastLoadArchived = archived?.value;
    return <TenantAdminEvent>[];
  }

  @override
  Future<TenantAdminPagedResult<TenantAdminEvent>> fetchEventsPage({
    required TenantAdminEventsRepoInt page,
    required TenantAdminEventsRepoInt pageSize,
    TenantAdminEventsRepoString? search,
    TenantAdminEventsRepoString? status,
    TenantAdminEventsRepoBool? archived,
  }) async {
    fetchEventsPageCalls += 1;
    lastLoadArchived = archived?.value;
    return TenantAdminPagedResult<TenantAdminEvent>(
      items: <TenantAdminEvent>[],
      hasMore: false,
    );
  }

  @override
  Future<TenantAdminEventPartyCandidates> fetchPartyCandidates({
    TenantAdminEventsRepoString? search,
    TenantAdminEventsRepoString? accountSlug,
  }) async {
    return TenantAdminEventPartyCandidates(
      venues: <TenantAdminAccountProfile>[],
      artists: <TenantAdminAccountProfile>[],
    );
  }

  @override
  Future<TenantAdminEvent> updateEvent({
    required TenantAdminEventsRepoString eventId,
    required TenantAdminEventDraft draft,
  }) async {
    throw UnimplementedError();
  }
}

class _FakeTenantScope implements TenantAdminTenantScopeContract {
  @override
  final StreamValue<String?> selectedTenantDomainStreamValue =
      StreamValue<String?>(defaultValue: null);

  @override
  String? get selectedTenantDomain => selectedTenantDomainStreamValue.value;

  @override
  String get selectedTenantAdminBaseUrl {
    final selected = selectedTenantDomain?.trim() ?? '';
    if (selected.isEmpty) {
      return '';
    }
    final host = selected.contains('://')
        ? (Uri.tryParse(selected)?.host ?? selected)
        : selected;
    return 'https://$host/admin/api';
  }

  @override
  void clearSelectedTenantDomain() {
    selectedTenantDomainStreamValue.addValue(null);
  }

  @override
  void selectTenantDomain(String tenantDomain) {
    selectedTenantDomainStreamValue.addValue(tenantDomain);
  }
}

class _FakeLandlordAuthRepositoryWithToken
    implements LandlordAuthRepositoryContract {
  _FakeLandlordAuthRepositoryWithToken(this._token);

  String _token;

  @override
  bool get hasValidSession => _token.trim().isNotEmpty;

  @override
  String get token => _token;

  @override
  Future<void> init() async {}

  @override
  Future<void> loginWithEmailPassword(String email, String password) async {}

  @override
  Future<void> logout() async {
    _token = '';
  }
}

class _AccountScopedEventsRepository
    with TenantAdminEventsPaginationMixin
    implements TenantAdminEventsRepositoryContract {
  int fetchEventTypesCalls = 0;
  int fetchEventsCalls = 0;
  int fetchEventsPageCalls = 0;
  int partyCandidatesCalls = 0;
  int createOwnCalls = 0;
  String? lastPartyCandidatesAccountSlug;

  @override
  Future<TenantAdminEvent> createEvent({
    required TenantAdminEventDraft draft,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<TenantAdminEvent> createOwnEvent({
    required TenantAdminEventsRepoString accountSlug,
    required TenantAdminEventDraft draft,
  }) async {
    createOwnCalls += 1;
    return TenantAdminEvent(
      eventId: 'evt-own',
      slug: 'own-event',
      title: draft.title,
      content: draft.content,
      type: draft.type,
      publication: draft.publication,
      occurrences: draft.occurrences,
      artistIds: draft.artistIds,
      taxonomyTerms: draft.taxonomyTerms,
      location: draft.location,
      placeRef: draft.placeRef,
    );
  }

  @override
  Future<void> deleteEvent(TenantAdminEventsRepoString eventId) async {}

  @override
  Future<TenantAdminEvent> fetchEvent(TenantAdminEventsRepoString eventIdOrSlug) async {
    throw UnimplementedError();
  }

  @override
  Future<List<TenantAdminEventType>> fetchEventTypes() async {
    fetchEventTypesCalls += 1;
    return [
      TenantAdminEventType(
        id: '507f1f77bcf86cd799439099',
        name: 'Show',
        slug: 'show',
        description: 'Tipo de evento: Show',
      ),
    ];
  }

  @override
  Future<List<TenantAdminEvent>> fetchEvents({
    TenantAdminEventsRepoString? search,
    TenantAdminEventsRepoString? status,
    TenantAdminEventsRepoBool? archived,
  }) async {
    fetchEventsCalls += 1;
    return <TenantAdminEvent>[];
  }

  @override
  Future<TenantAdminPagedResult<TenantAdminEvent>> fetchEventsPage({
    required TenantAdminEventsRepoInt page,
    required TenantAdminEventsRepoInt pageSize,
    TenantAdminEventsRepoString? search,
    TenantAdminEventsRepoString? status,
    TenantAdminEventsRepoBool? archived,
  }) async {
    fetchEventsPageCalls += 1;
    return TenantAdminPagedResult<TenantAdminEvent>(
      items: <TenantAdminEvent>[],
      hasMore: false,
    );
  }

  @override
  Future<TenantAdminEventPartyCandidates> fetchPartyCandidates({
    TenantAdminEventsRepoString? search,
    TenantAdminEventsRepoString? accountSlug,
  }) async {
    partyCandidatesCalls += 1;
    lastPartyCandidatesAccountSlug = accountSlug?.value;
    return TenantAdminEventPartyCandidates(
      venues: <TenantAdminAccountProfile>[],
      artists: <TenantAdminAccountProfile>[],
    );
  }

  @override
  Future<TenantAdminEvent> updateEvent({
    required TenantAdminEventsRepoString eventId,
    required TenantAdminEventDraft draft,
  }) async {
    throw UnimplementedError();
  }
}

class _EventTypeUpdateTrackingRepository
    extends _AccountScopedEventsRepository {
  String? lastUpdateDescription;

  @override
  Future<TenantAdminEventType> updateEventType({
    required TenantAdminEventsRepoString eventTypeId,
    TenantAdminEventsRepoString? name,
    TenantAdminEventsRepoString? slug,
    TenantAdminEventsRepoString? description,
  }) async {
    lastUpdateDescription = description?.value;
    return TenantAdminEventType(
      id: eventTypeId.value,
      name: name?.value ?? 'Show',
      slug: slug?.value ?? 'show',
      description: description?.value,
    );
  }
}
