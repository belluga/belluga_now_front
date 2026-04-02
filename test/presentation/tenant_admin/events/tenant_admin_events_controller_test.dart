import 'package:belluga_now/domain/repositories/landlord_auth_repository_contract.dart';
import 'package:belluga_now/domain/repositories/tenant_admin_events_repository_contract.dart';
import 'package:belluga_now/domain/repositories/tenant_admin_taxonomies_repository_contract.dart';
import 'package:belluga_now/domain/services/tenant_admin_tenant_scope_contract.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_account_profile.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_event.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_event_account_profile_candidate_type.dart';
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
      'account-scoped loadFormDependencies uses dedicated event types endpoint and account-profile candidate pages',
      () async {
    final eventsRepository = _AccountScopedEventsRepository();
    final controller = TenantAdminEventsController(
      eventsRepository: eventsRepository,
      taxonomiesRepository: _NoopTaxonomiesRepository(),
    );

    await controller.loadFormDependencies(accountSlug: 'my-account');

    expect(eventsRepository.fetchEventTypesCalls, 1);
    expect(eventsRepository.fetchEventsCalls, 0);
    expect(eventsRepository.accountProfileCandidatePageCalls, 2);
    expect(eventsRepository.lastAccountProfileCandidatesAccountSlug, 'my-account');
    expect(
      eventsRepository.candidateTypes,
      containsAll(<TenantAdminEventAccountProfileCandidateType>[
        TenantAdminEventAccountProfileCandidateType.physicalHost,
        TenantAdminEventAccountProfileCandidateType.artist,
      ]),
    );
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
        idValue: tenantAdminOptionalText('507f1f77bcf86cd799439011'),
        nameValue: tenantAdminRequiredText('Show'),
        slugValue: tenantAdminRequiredText('show'),
        descriptionValue: tenantAdminOptionalText('Legacy description'),
      ),
    );

    expect(eventsRepository.lastUpdateDescription, isNull);
  });

  test('artist search is backend-driven, paginated, and resets on query change',
      () async {
    final eventsRepository = _SearchableArtistCandidatesRepository();
    final controller = TenantAdminEventsController(
      eventsRepository: eventsRepository,
      taxonomiesRepository: _NoopTaxonomiesRepository(),
    );

    await controller.loadFormDependencies();
    await controller.prepareArtistPicker();

    controller.updateArtistSearchQuery('zulu');
    await controller.retryArtistSearch();

    expect(
      controller.artistSearchResultsStreamValue.value
          .map((artist) => artist.displayName)
          .toList(growable: false),
      ['Zulu Artist 1'],
    );
    expect(eventsRepository.artistSearchRequests.last, ('zulu', 1));

    await controller.loadNextArtistSearchPage();

    expect(
      controller.artistSearchResultsStreamValue.value
          .map((artist) => artist.displayName)
          .toList(growable: false),
      ['Zulu Artist 1', 'Zulu Artist 2'],
    );
    expect(eventsRepository.artistSearchRequests.last, ('zulu', 2));

    controller.updateArtistSearchQuery('echo');
    await controller.retryArtistSearch();

    expect(
      controller.artistSearchResultsStreamValue.value
          .map((artist) => artist.displayName)
          .toList(growable: false),
      ['Echo Artist'],
    );
    expect(eventsRepository.artistSearchRequests.last, ('echo', 1));
  });
}

TenantAdminEventDraft _buildDraft() {
  return TenantAdminEventDraft(
    titleValue: tenantAdminRequiredText('My event'),
    contentValue: tenantAdminOptionalText('Content'),
    type: TenantAdminEventType(
      nameValue: tenantAdminRequiredText('Show'),
      slugValue: tenantAdminRequiredText('show'),
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
  Future<TenantAdminEvent> fetchEvent(
      TenantAdminEventsRepoString eventIdOrSlug) async {
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
    return tenantAdminPagedResultFromRaw(
      items: <TenantAdminEvent>[],
      hasMore: false,
    );
  }

  @override
  Future<TenantAdminPagedResult<TenantAdminAccountProfile>>
      fetchEventAccountProfileCandidatesPage({
    required TenantAdminEventAccountProfileCandidateType candidateType,
    required TenantAdminEventsRepoInt page,
    required TenantAdminEventsRepoInt pageSize,
    TenantAdminEventsRepoString? search,
    TenantAdminEventsRepoString? accountSlug,
  }) async {
    return tenantAdminPagedResultFromRaw(
      items: const <TenantAdminAccountProfile>[],
      hasMore: false,
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
    required TenantAdminTaxRepoString slug,
    required TenantAdminTaxRepoString name,
    required List<TenantAdminTaxRepoString> appliesTo,
    TenantAdminTaxRepoString? icon,
    TenantAdminTaxRepoString? color,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<TenantAdminTaxonomyTermDefinition> createTerm({
    required TenantAdminTaxRepoString taxonomyId,
    required TenantAdminTaxRepoString slug,
    required TenantAdminTaxRepoString name,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteTaxonomy(TenantAdminTaxRepoString taxonomyId) async {}

  @override
  Future<void> deleteTerm({
    required TenantAdminTaxRepoString taxonomyId,
    required TenantAdminTaxRepoString termId,
  }) async {}

  @override
  Future<List<TenantAdminTaxonomyDefinition>> fetchTaxonomies() async {
    return <TenantAdminTaxonomyDefinition>[];
  }

  @override
  Future<TenantAdminPagedResult<TenantAdminTaxonomyDefinition>>
      fetchTaxonomiesPage({
    required TenantAdminTaxRepoInt page,
    required TenantAdminTaxRepoInt pageSize,
  }) async {
    return tenantAdminPagedResultFromRaw(
      items: <TenantAdminTaxonomyDefinition>[],
      hasMore: false,
    );
  }

  @override
  Future<List<TenantAdminTaxonomyTermDefinition>> fetchTerms({
    required TenantAdminTaxRepoString taxonomyId,
  }) async {
    return <TenantAdminTaxonomyTermDefinition>[];
  }

  @override
  Future<TenantAdminPagedResult<TenantAdminTaxonomyTermDefinition>>
      fetchTermsPage({
    required TenantAdminTaxRepoString taxonomyId,
    required TenantAdminTaxRepoInt page,
    required TenantAdminTaxRepoInt pageSize,
  }) async {
    return tenantAdminPagedResultFromRaw(
      items: <TenantAdminTaxonomyTermDefinition>[],
      hasMore: false,
    );
  }

  @override
  Future<TenantAdminTaxonomyDefinition> updateTaxonomy({
    required TenantAdminTaxRepoString taxonomyId,
    TenantAdminTaxRepoString? slug,
    TenantAdminTaxRepoString? name,
    List<TenantAdminTaxRepoString>? appliesTo,
    TenantAdminTaxRepoString? icon,
    TenantAdminTaxRepoString? color,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<TenantAdminTaxonomyTermDefinition> updateTerm({
    required TenantAdminTaxRepoString taxonomyId,
    required TenantAdminTaxRepoString termId,
    TenantAdminTaxRepoString? slug,
    TenantAdminTaxRepoString? name,
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
  Future<TenantAdminEvent> fetchEvent(
      TenantAdminEventsRepoString eventIdOrSlug) async {
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
    return tenantAdminPagedResultFromRaw(
      items: <TenantAdminEvent>[],
      hasMore: false,
    );
  }

  @override
  Future<TenantAdminPagedResult<TenantAdminAccountProfile>>
      fetchEventAccountProfileCandidatesPage({
    required TenantAdminEventAccountProfileCandidateType candidateType,
    required TenantAdminEventsRepoInt page,
    required TenantAdminEventsRepoInt pageSize,
    TenantAdminEventsRepoString? search,
    TenantAdminEventsRepoString? accountSlug,
  }) async {
    return tenantAdminPagedResultFromRaw(
      items: const <TenantAdminAccountProfile>[],
      hasMore: false,
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
  void selectTenantDomain(Object tenantDomain) {
    selectedTenantDomainStreamValue.addValue(
      tenantDomain is String
          ? tenantDomain
          : (tenantDomain as dynamic).value as String,
    );
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
  Future<void> loginWithEmailPassword(
      LandlordAuthRepositoryContractPrimString email,
      LandlordAuthRepositoryContractPrimString password) async {}

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
  int accountProfileCandidatePageCalls = 0;
  int createOwnCalls = 0;
  String? lastAccountProfileCandidatesAccountSlug;
  final List<TenantAdminEventAccountProfileCandidateType> candidateTypes =
      <TenantAdminEventAccountProfileCandidateType>[];

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
      eventIdValue: tenantAdminRequiredText('evt-own'),
      slugValue: tenantAdminRequiredText('own-event'),
      titleValue: tenantAdminRequiredText(draft.title),
      contentValue: tenantAdminOptionalText(draft.content),
      type: draft.type,
      publication: draft.publication,
      occurrences: draft.occurrences,
      artistIdValues: draft.artistIds,
      taxonomyTerms: draft.taxonomyTerms,
      location: draft.location,
      placeRef: draft.placeRef,
    );
  }

  @override
  Future<void> deleteEvent(TenantAdminEventsRepoString eventId) async {}

  @override
  Future<TenantAdminEvent> fetchEvent(
      TenantAdminEventsRepoString eventIdOrSlug) async {
    throw UnimplementedError();
  }

  @override
  Future<List<TenantAdminEventType>> fetchEventTypes() async {
    fetchEventTypesCalls += 1;
    return [
      TenantAdminEventType(
        idValue: tenantAdminOptionalText('507f1f77bcf86cd799439099'),
        nameValue: tenantAdminRequiredText('Show'),
        slugValue: tenantAdminRequiredText('show'),
        descriptionValue: tenantAdminOptionalText('Tipo de evento: Show'),
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
    return tenantAdminPagedResultFromRaw(
      items: <TenantAdminEvent>[],
      hasMore: false,
    );
  }

  @override
  Future<TenantAdminPagedResult<TenantAdminAccountProfile>>
      fetchEventAccountProfileCandidatesPage({
    required TenantAdminEventAccountProfileCandidateType candidateType,
    required TenantAdminEventsRepoInt page,
    required TenantAdminEventsRepoInt pageSize,
    TenantAdminEventsRepoString? search,
    TenantAdminEventsRepoString? accountSlug,
  }) async {
    accountProfileCandidatePageCalls += 1;
    lastAccountProfileCandidatesAccountSlug = accountSlug?.value;
    candidateTypes.add(candidateType);
    return tenantAdminPagedResultFromRaw(
      items: const <TenantAdminAccountProfile>[],
      hasMore: false,
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
      idValue: tenantAdminOptionalText(eventTypeId.value),
      nameValue: tenantAdminRequiredText(name?.value ?? 'Show'),
      slugValue: tenantAdminRequiredText(slug?.value ?? 'show'),
      descriptionValue: tenantAdminOptionalText(description?.value),
    );
  }
}

class _SearchableArtistCandidatesRepository extends _AccountScopedEventsRepository {
  final List<(String, int)> artistSearchRequests = <(String, int)>[];

  @override
  Future<TenantAdminPagedResult<TenantAdminAccountProfile>>
      fetchEventAccountProfileCandidatesPage({
    required TenantAdminEventAccountProfileCandidateType candidateType,
    required TenantAdminEventsRepoInt page,
    required TenantAdminEventsRepoInt pageSize,
    TenantAdminEventsRepoString? search,
    TenantAdminEventsRepoString? accountSlug,
  }) async {
    if (candidateType ==
        TenantAdminEventAccountProfileCandidateType.physicalHost) {
      return tenantAdminPagedResultFromRaw(
        items: const <TenantAdminAccountProfile>[],
        hasMore: false,
      );
    }

    final normalizedSearch = search?.value.trim().toLowerCase() ?? '';
    artistSearchRequests.add((normalizedSearch, page.value));

    final result = switch ((normalizedSearch, page.value)) {
      ('', 1) => (
          <TenantAdminAccountProfile>[
            tenantAdminAccountProfileFromRaw(
              id: 'artist-bootstrap',
              accountId: 'acc-bootstrap',
              profileType: 'artist',
              displayName: 'Bootstrap Artist',
            ),
          ],
          true,
        ),
      ('', 2) => (
          <TenantAdminAccountProfile>[
            tenantAdminAccountProfileFromRaw(
              id: 'artist-bootstrap-2',
              accountId: 'acc-bootstrap-2',
              profileType: 'artist',
              displayName: 'Bootstrap Artist 2',
            ),
          ],
          false,
        ),
      ('zulu', 1) => (
          <TenantAdminAccountProfile>[
            tenantAdminAccountProfileFromRaw(
              id: 'artist-zulu-1',
              accountId: 'acc-zulu-1',
              profileType: 'artist',
              displayName: 'Zulu Artist 1',
            ),
          ],
          true,
        ),
      ('zulu', 2) => (
          <TenantAdminAccountProfile>[
            tenantAdminAccountProfileFromRaw(
              id: 'artist-zulu-2',
              accountId: 'acc-zulu-2',
              profileType: 'artist',
              displayName: 'Zulu Artist 2',
            ),
          ],
          false,
        ),
      ('echo', 1) => (
          <TenantAdminAccountProfile>[
            tenantAdminAccountProfileFromRaw(
              id: 'artist-echo-1',
              accountId: 'acc-echo-1',
              profileType: 'artist',
              displayName: 'Echo Artist',
            ),
          ],
          false,
        ),
      _ => (
          const <TenantAdminAccountProfile>[],
          false,
        ),
    };

    return tenantAdminPagedResultFromRaw(
      items: result.$1,
      hasMore: result.$2,
    );
  }
}
