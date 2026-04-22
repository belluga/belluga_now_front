import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/support/canonical_route_family.dart';
import 'package:belluga_now/application/router/support/canonical_route_meta.dart';
import 'package:belluga_now/domain/repositories/tenant_admin_events_repository_contract.dart';
import 'package:belluga_now/domain/repositories/tenant_admin_taxonomies_repository_contract.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_account_profile.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_event.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_event_account_profile_candidate_type.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_event_temporal_bucket.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_legacy_event_parties_summary.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_location.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_paged_result.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_definition.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_term_definition.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_count_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_value_parsers.dart';
import 'package:belluga_now/presentation/tenant_admin/events/controllers/tenant_admin_events_controller.dart';
import 'package:belluga_now/presentation/tenant_admin/events/screens/tenant_admin_event_form_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:integration_test/integration_test.dart';

import 'support/integration_test_bootstrap.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  IntegrationTestBootstrap.ensureNonProductionLandlordDomain();

  setUp(() async {
    await GetIt.I.reset();
  });

  tearDown(() async {
    await GetIt.I.reset();
  });

  testWidgets(
    'tenant admin create route saves second occurrence details through local mutation',
    (tester) async {
      final eventsRepository = _FakeEventsRepository();
      final taxonomiesRepository = _FakeTaxonomiesRepository();
      final controller = TenantAdminEventsController(
        eventsRepository: eventsRepository,
        taxonomiesRepository: taxonomiesRepository,
      );

      eventsRepository.eventTypes = [_eventType()];
      GetIt.I.registerSingleton<TenantAdminEventsController>(controller);

      await _pumpWithAutoRoute(
        tester,
        const Scaffold(body: TenantAdminEventFormScreen()),
      );
      await _fillRequiredFields(tester, controller: controller);

      await _tapAddOccurrenceFab(tester);

      await tester.tap(
        find.byKey(const Key('tenantAdminOccurrenceAddProfileButton')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Artist A').last);
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.byKey(const Key('tenantAdminOccurrenceLocationOverrideSwitch')),
        250,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const Key('tenantAdminOccurrenceLocationOverrideSwitch')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const Key('tenantAdminOccurrenceLocationMode')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Online').last);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('tenantAdminOccurrenceOnlineUrl')),
        'https://stream.example.com/feira',
      );
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.byKey(const Key('tenantAdminOccurrenceAddProgrammingButton')),
        250,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const Key('tenantAdminOccurrenceAddProgrammingButton')),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('tenantAdminProgrammingTimeField')),
        '13:00',
      );
      await tester.enterText(
        find.byKey(const Key('tenantAdminProgrammingTitleField')),
        'Apresentacao especial',
      );
      await tester.tap(
        find.byKey(const Key('tenantAdminProgrammingAddProfileButton')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Artist A').last);
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const Key('tenantAdminProgrammingSaveButton')),
      );
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.byKey(const Key('tenantAdminOccurrenceSaveButton')),
        250,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.pumpAndSettle();
      await tester
          .tap(find.byKey(const Key('tenantAdminOccurrenceSaveButton')));
      await tester.pumpAndSettle();

      expect(find.text('Datas'), findsOneWidget);
      expect(find.byKey(const Key('tenantAdminEventOccurrenceCard_0')),
          findsOneWidget);
      expect(find.byKey(const Key('tenantAdminEventOccurrenceCard_1')),
          findsOneWidget);

      await tester.scrollUntilVisible(
        find.widgetWithText(FilledButton, 'Criar evento'),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Criar evento'));
      await tester.pumpAndSettle();

      expect(eventsRepository.createEventCalls, 1);
      final submittedOccurrence =
          eventsRepository.lastCreateDraft?.occurrences[1];
      expect(submittedOccurrence, isNotNull);
      expect(
        submittedOccurrence!.relatedAccountProfileIds
            .map((value) => value.value),
        contains('artist-1'),
      );
      expect(submittedOccurrence.hasLocationOverride, isTrue);
      expect(submittedOccurrence.locationOverride?.mode, 'online');
      expect(
        submittedOccurrence.locationOverride?.online?.url,
        'https://stream.example.com/feira',
      );
      expect(submittedOccurrence.programmingItems.single.time, '13:00');
      expect(
        submittedOccurrence.programmingItems.single.accountProfileIds
            .map((value) => value.value),
        contains('artist-1'),
      );
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );

  testWidgets(
    'tenant admin edit route saves a second occurrence through local update mutation',
    (tester) async {
      final eventsRepository = _FakeEventsRepository();
      final taxonomiesRepository = _FakeTaxonomiesRepository();
      final controller = TenantAdminEventsController(
        eventsRepository: eventsRepository,
        taxonomiesRepository: taxonomiesRepository,
      );
      final eventType = _eventType();

      eventsRepository.eventTypes = [eventType];
      GetIt.I.registerSingleton<TenantAdminEventsController>(controller);

      await _pumpWithAutoRoute(
        tester,
        Scaffold(
          body: TenantAdminEventFormScreen(
            existingEvent: _existingEvent(eventType),
          ),
        ),
      );

      await _tapAddOccurrenceFab(tester);
      await tester.scrollUntilVisible(
        find.byKey(const Key('tenantAdminOccurrenceSaveButton')),
        250,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.pumpAndSettle();
      await tester
          .tap(find.byKey(const Key('tenantAdminOccurrenceSaveButton')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('tenantAdminEventOccurrenceCard_1')),
          findsOneWidget);

      await tester.scrollUntilVisible(
        find.widgetWithText(FilledButton, 'Salvar alterações'),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Salvar alterações'));
      await tester.pumpAndSettle();

      expect(eventsRepository.updateEventCalls, 1);
      expect(eventsRepository.lastUpdateEventId, 'evt-existing-1');
      expect(eventsRepository.lastUpdateDraft?.occurrences, hasLength(2));
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );
}

Future<void> _pumpWithAutoRoute(
  WidgetTester tester,
  Widget child,
) async {
  final router = RootStackRouter.build(
    routes: [
      NamedRouteDef(
        name: 'events-form-integration-test',
        path: '/',
        meta: canonicalRouteMeta(
          family: CanonicalRouteFamily.tenantAdminEventsInternal,
          chromeMode: RouteChromeMode.fullscreen,
        ),
        builder: (_, __) => child,
      ),
    ],
  )..ignorePopCompleters = true;

  await tester.pumpWidget(
    MaterialApp.router(
      routeInformationParser: router.defaultRouteParser(),
      routerDelegate: router.delegate(),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _fillRequiredFields(
  WidgetTester tester, {
  required TenantAdminEventsController controller,
}) async {
  await tester.enterText(
    find.widgetWithText(TextFormField, 'Título'),
    'Evento',
  );
  controller.eventContentController.text = '<p>Descrição do evento</p>';
  controller.applyEventStartAt(DateTime(2026, 3, 5, 20));
  await tester.pumpAndSettle();

  await tester.scrollUntilVisible(
    find.text('Physical'),
    250,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();

  await tester.tap(find.text('Physical').last);
  await tester.pumpAndSettle();
  await tester.tap(find.text('Online').last);
  await tester.pumpAndSettle();

  await tester.enterText(
    find.widgetWithText(TextFormField, 'URL online'),
    'https://example.com/live',
  );
  await tester.pumpAndSettle();
}

Future<void> _tapAddOccurrenceFab(WidgetTester tester) async {
  final fab = find.byKey(const Key('tenantAdminEventAddOccurrenceButton'));
  await tester.pumpAndSettle();
  expect(tester.widget<FloatingActionButton>(fab), isA<FloatingActionButton>());
  expect(tester.getTopLeft(fab).dy, greaterThanOrEqualTo(0));
  await tester.tap(fab);
  await tester.pumpAndSettle();
}

TenantAdminEventType _eventType() {
  return TenantAdminEventType(
    idValue: tenantAdminOptionalText('507f1f77bcf86cd799439024'),
    nameValue: tenantAdminRequiredText('Feira'),
    slugValue: tenantAdminRequiredText('feira'),
  );
}

TenantAdminEvent _existingEvent(TenantAdminEventType eventType) {
  return TenantAdminEvent(
    eventIdValue: tenantAdminRequiredText('evt-existing-1'),
    slugValue: tenantAdminRequiredText('event-existing-1'),
    titleValue: tenantAdminRequiredText('Evento existente'),
    contentValue: tenantAdminOptionalText('<p>Descrição existente</p>'),
    type: eventType,
    occurrences: <TenantAdminEventOccurrence>[
      TenantAdminEventOccurrence(
        dateTimeStartValue: tenantAdminDateTime(
          DateTime.utc(2026, 3, 5, 20),
        ),
      ),
    ],
    publication: TenantAdminEventPublication(
      statusValue: tenantAdminRequiredText('draft'),
    ),
    location: TenantAdminEventLocation(
      modeValue: tenantAdminRequiredText('online'),
      online: TenantAdminEventOnlineLocation(
        urlValue: tenantAdminRequiredText('https://example.com/live'),
      ),
    ),
  );
}

class _FakeEventsRepository extends TenantAdminEventsRepositoryContract
    with TenantAdminEventsPaginationMixin {
  List<TenantAdminEventType> eventTypes = <TenantAdminEventType>[];
  TenantAdminEventDraft? lastCreateDraft;
  TenantAdminEventDraft? lastUpdateDraft;
  String? lastUpdateEventId;
  int createEventCalls = 0;
  int updateEventCalls = 0;

  @override
  Future<TenantAdminEvent> createEvent({
    required TenantAdminEventDraft draft,
  }) async {
    createEventCalls += 1;
    lastCreateDraft = draft;
    return _eventFromDraft(draft);
  }

  @override
  Future<TenantAdminEvent> createOwnEvent({
    required TenantAdminEventsRepoString accountSlug,
    required TenantAdminEventDraft draft,
  }) async {
    return _eventFromDraft(draft);
  }

  @override
  Future<void> deleteEvent(TenantAdminEventsRepoString eventId) async {}

  @override
  Future<TenantAdminEvent> fetchEvent(
    TenantAdminEventsRepoString eventIdOrSlug,
  ) async {
    throw UnimplementedError();
  }

  @override
  Future<List<TenantAdminEvent>> fetchEvents({
    TenantAdminEventsRepoString? search,
    TenantAdminEventsRepoString? specificDate,
    TenantAdminEventsRepoString? status,
    TenantAdminEventsRepoString? venueProfileId,
    TenantAdminEventsRepoString? relatedAccountProfileId,
    TenantAdminEventsRepoBool? archived,
    Set<TenantAdminEventTemporalBucket>? temporalBuckets,
  }) async {
    return <TenantAdminEvent>[];
  }

  @override
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
    return tenantAdminPagedResultFromRaw(
      items: <TenantAdminEvent>[],
      hasMore: false,
    );
  }

  @override
  Future<List<TenantAdminEventType>> fetchEventTypes() async {
    return List<TenantAdminEventType>.unmodifiable(eventTypes);
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
    final items = switch (candidateType) {
      TenantAdminEventAccountProfileCandidateType.physicalHost => [
          tenantAdminAccountProfileFromRaw(
            id: 'venue-1',
            accountId: 'acc-venue',
            profileType: 'venue',
            displayName: 'Venue A',
            location: tenantAdminLocationFromRaw(
              latitude: -20.611121,
              longitude: -40.498617,
            ),
          ),
        ],
      TenantAdminEventAccountProfileCandidateType.relatedAccountProfile => [
          tenantAdminAccountProfileFromRaw(
            id: 'artist-1',
            accountId: 'acc-artist',
            profileType: 'artist',
            displayName: 'Artist A',
          ),
        ],
    };
    return tenantAdminPagedResultFromRaw(
      items: items,
      hasMore: false,
    );
  }

  @override
  Future<TenantAdminEvent> updateEvent({
    required TenantAdminEventsRepoString eventId,
    required TenantAdminEventDraft draft,
  }) async {
    updateEventCalls += 1;
    lastUpdateEventId = eventId.value;
    lastUpdateDraft = draft;
    return _eventFromDraft(draft);
  }

  @override
  Future<TenantAdminLegacyEventPartiesSummary>
      fetchLegacyEventPartiesSummary() async {
    return TenantAdminLegacyEventPartiesSummary(
      scannedValue: TenantAdminCountValue(0),
      invalidValue: TenantAdminCountValue(0),
      repairedValue: TenantAdminCountValue(0),
      unchangedValue: TenantAdminCountValue(0),
      failedValue: TenantAdminCountValue(0),
    );
  }

  @override
  Future<TenantAdminLegacyEventPartiesSummary>
      repairLegacyEventParties() async {
    return TenantAdminLegacyEventPartiesSummary(
      scannedValue: TenantAdminCountValue(0),
      invalidValue: TenantAdminCountValue(0),
      repairedValue: TenantAdminCountValue(0),
      unchangedValue: TenantAdminCountValue(0),
      failedValue: TenantAdminCountValue(0),
    );
  }

  TenantAdminEvent _eventFromDraft(TenantAdminEventDraft draft) {
    return TenantAdminEvent(
      eventIdValue: tenantAdminRequiredText('evt-1'),
      slugValue: tenantAdminRequiredText('event-1'),
      titleValue: tenantAdminRequiredText(draft.title),
      contentValue: tenantAdminOptionalText(draft.content),
      type: draft.type,
      occurrences: draft.occurrences,
      publication: draft.publication,
      location: draft.location,
      placeRef: draft.placeRef,
      relatedAccountProfileIdValues: draft.relatedAccountProfileIds,
      taxonomyTerms: draft.taxonomyTerms,
    );
  }
}

class _FakeTaxonomiesRepository
    with TenantAdminTaxonomiesPaginationMixin
    implements TenantAdminTaxonomiesRepositoryContract {
  @override
  Future<TenantAdminTaxonomyDefinition> createTaxonomy({
    required TenantAdminTaxRepoString slug,
    required TenantAdminTaxRepoString name,
    required List<TenantAdminTaxRepoString> appliesTo,
    TenantAdminTaxRepoString? icon,
    TenantAdminTaxRepoString? color,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<TenantAdminTaxonomyTermDefinition> createTerm({
    required TenantAdminTaxRepoString taxonomyId,
    required TenantAdminTaxRepoString slug,
    required TenantAdminTaxRepoString name,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteTaxonomy(TenantAdminTaxRepoString taxonomyId) {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteTerm({
    required TenantAdminTaxRepoString taxonomyId,
    required TenantAdminTaxRepoString termId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<List<TenantAdminTaxonomyDefinition>> fetchTaxonomies() async {
    return [
      tenantAdminTaxonomyDefinitionFromRaw(
        id: 'tax-1',
        slug: 'music_genre',
        name: 'Music Genre',
        appliesTo: ['event'],
        icon: null,
        color: null,
      ),
    ];
  }

  @override
  Future<TenantAdminPagedResult<TenantAdminTaxonomyDefinition>>
      fetchTaxonomiesPage({
    required TenantAdminTaxRepoInt page,
    required TenantAdminTaxRepoInt pageSize,
  }) async {
    final taxonomies = await fetchTaxonomies();
    return tenantAdminPagedResultFromRaw(
      items: taxonomies,
      hasMore: false,
    );
  }

  @override
  Future<List<TenantAdminTaxonomyTermDefinition>> fetchTerms({
    required TenantAdminTaxRepoString taxonomyId,
  }) async {
    return [
      tenantAdminTaxonomyTermDefinitionFromRaw(
        id: 'term-1',
        taxonomyId: 'tax-1',
        slug: 'rock',
        name: 'Rock',
      ),
    ];
  }

  @override
  Future<TenantAdminPagedResult<TenantAdminTaxonomyTermDefinition>>
      fetchTermsPage({
    required TenantAdminTaxRepoString taxonomyId,
    required TenantAdminTaxRepoInt page,
    required TenantAdminTaxRepoInt pageSize,
  }) async {
    final terms = await fetchTerms(taxonomyId: taxonomyId);
    return tenantAdminPagedResultFromRaw(
      items: terms,
      hasMore: false,
    );
  }

  @override
  void resetTaxonomiesState() {}

  @override
  void resetTermsState() {}

  @override
  Future<TenantAdminTaxonomyDefinition> updateTaxonomy({
    required TenantAdminTaxRepoString taxonomyId,
    TenantAdminTaxRepoString? slug,
    TenantAdminTaxRepoString? name,
    List<TenantAdminTaxRepoString>? appliesTo,
    TenantAdminTaxRepoString? icon,
    TenantAdminTaxRepoString? color,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<TenantAdminTaxonomyTermDefinition> updateTerm({
    required TenantAdminTaxRepoString taxonomyId,
    required TenantAdminTaxRepoString termId,
    TenantAdminTaxRepoString? slug,
    TenantAdminTaxRepoString? name,
  }) {
    throw UnimplementedError();
  }
}
