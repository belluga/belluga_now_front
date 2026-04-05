import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/domain/repositories/tenant_admin_events_repository_contract.dart';
import 'package:belluga_now/domain/repositories/tenant_admin_taxonomies_repository_contract.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_account_profile.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_event.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_event_account_profile_candidate_type.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_legacy_event_parties_summary.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_location.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_paged_result.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_definition.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_term_definition.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_count_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_value_parsers.dart';
import 'package:belluga_now/presentation/tenant_admin/events/controllers/tenant_admin_events_controller.dart';
import 'package:belluga_now/presentation/tenant_admin/events/screens/tenant_admin_event_form_screen.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/widgets/tenant_admin_rich_text_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await GetIt.I.reset();
  });

  tearDown(() async {
    await GetIt.I.reset();
  });

  testWidgets('submits selected taxonomy terms on create', (tester) async {
    final eventsRepository = _FakeEventsRepository();
    final taxonomiesRepository = _FakeTaxonomiesRepository();
    final controller = TenantAdminEventsController(
      eventsRepository: eventsRepository,
      taxonomiesRepository: taxonomiesRepository,
    );

    eventsRepository.eventTypes = [
      TenantAdminEventType(
        idValue: tenantAdminOptionalText('507f1f77bcf86cd799439011'),
        nameValue: tenantAdminRequiredText('Feira'),
        slugValue: tenantAdminRequiredText('feira'),
        descriptionValue: tenantAdminOptionalText('Tipo default do teste'),
      ),
    ];

    GetIt.I.registerSingleton<TenantAdminEventsController>(controller);

    await _pumpWithAutoRoute(
      tester,
      const Scaffold(
        body: TenantAdminEventFormScreen(),
      ),
    );

    await _fillRequiredFields(tester, controller: controller);
    await tester.scrollUntilVisible(
      find.text('Rock'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rock'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.widgetWithText(FilledButton, 'Criar evento'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Criar evento'));
    await tester.pumpAndSettle();

    final draft = eventsRepository.lastCreateDraft;
    expect(draft, isNotNull);
    expect(
      draft!.taxonomyTerms.any(
        (term) => term.type == 'music_genre' && term.value == 'rock',
      ),
      isTrue,
    );
    expect(draft.occurrences.first.dateTimeStart.isUtc, isTrue);
  });

  testWidgets('guards against duplicate create submit taps', (tester) async {
    final eventsRepository = _FakeEventsRepository();
    final taxonomiesRepository = _FakeTaxonomiesRepository();
    final controller = TenantAdminEventsController(
      eventsRepository: eventsRepository,
      taxonomiesRepository: taxonomiesRepository,
    );

    eventsRepository.eventTypes = [
      TenantAdminEventType(
        idValue: tenantAdminOptionalText('507f1f77bcf86cd799439021'),
        nameValue: tenantAdminRequiredText('Feira'),
        slugValue: tenantAdminRequiredText('feira'),
      ),
    ];

    GetIt.I.registerSingleton<TenantAdminEventsController>(controller);

    await _pumpWithAutoRoute(
      tester,
      const Scaffold(
        body: TenantAdminEventFormScreen(),
      ),
    );

    await _fillRequiredFields(tester, controller: controller);
    await tester.scrollUntilVisible(
      find.widgetWithText(FilledButton, 'Criar evento'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    final action = find.widgetWithText(FilledButton, 'Criar evento');
    await tester.tap(action);
    await tester.tap(action);
    await tester.pumpAndSettle();

    expect(eventsRepository.createEventCalls, 1);
  });

  testWidgets('uses own-account endpoint when account slug is provided',
      (tester) async {
    final eventsRepository = _FakeEventsRepository();
    final taxonomiesRepository = _FakeTaxonomiesRepository();
    final controller = TenantAdminEventsController(
      eventsRepository: eventsRepository,
      taxonomiesRepository: taxonomiesRepository,
    );

    eventsRepository.eventTypes = [
      TenantAdminEventType(
        idValue: tenantAdminOptionalText('507f1f77bcf86cd799439012'),
        nameValue: tenantAdminRequiredText('Workshop'),
        slugValue: tenantAdminRequiredText('workshop'),
        descriptionValue: tenantAdminOptionalText('Tipo de evento: Workshop'),
      ),
    ];

    GetIt.I.registerSingleton<TenantAdminEventsController>(controller);

    await _pumpWithAutoRoute(
      tester,
      const Scaffold(
        body: TenantAdminEventFormScreen(
          accountSlugForOwnCreate: 'school-account',
        ),
      ),
    );

    await _fillRequiredFields(tester, controller: controller);
    await tester.scrollUntilVisible(
      find.widgetWithText(FilledButton, 'Criar evento'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Criar evento'));
    await tester.pumpAndSettle();

    expect(eventsRepository.lastCreateOwnAccountSlug, 'school-account');
    expect(eventsRepository.lastCreateOwnDraft, isNotNull);
  });

  testWidgets('online mode omits venue coordinates on submit', (tester) async {
    final eventsRepository = _FakeEventsRepository();
    final taxonomiesRepository = _FakeTaxonomiesRepository();
    final controller = TenantAdminEventsController(
      eventsRepository: eventsRepository,
      taxonomiesRepository: taxonomiesRepository,
    );

    eventsRepository.eventTypes = [
      TenantAdminEventType(
        idValue: tenantAdminOptionalText('507f1f77bcf86cd799439015'),
        nameValue: tenantAdminRequiredText('Live'),
        slugValue: tenantAdminRequiredText('live'),
        descriptionValue: tenantAdminOptionalText('Tipo de evento: Live'),
      ),
    ];

    GetIt.I.registerSingleton<TenantAdminEventsController>(controller);

    await _pumpWithAutoRoute(
      tester,
      const Scaffold(
        body: TenantAdminEventFormScreen(),
      ),
    );

    await _fillRequiredFields(tester, controller: controller);
    await tester.scrollUntilVisible(
      find.widgetWithText(FilledButton, 'Criar evento'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Criar evento'));
    await tester.pumpAndSettle();

    final draft = eventsRepository.lastCreateDraft;
    expect(draft, isNotNull);
    expect(draft!.location?.mode, 'online');
    expect(draft.location?.latitude, isNull);
    expect(draft.location?.longitude, isNull);
    expect(draft.location?.online?.url, 'https://example.com/live');
    expect(draft.placeRef, isNull);
  });

  testWidgets('submits without description text (content optional)',
      (tester) async {
    final eventsRepository = _FakeEventsRepository();
    final taxonomiesRepository = _FakeTaxonomiesRepository();
    final controller = TenantAdminEventsController(
      eventsRepository: eventsRepository,
      taxonomiesRepository: taxonomiesRepository,
    );

    eventsRepository.eventTypes = [
      TenantAdminEventType(
        idValue: tenantAdminOptionalText('507f1f77bcf86cd799439016'),
        nameValue: tenantAdminRequiredText('Show'),
        slugValue: tenantAdminRequiredText('show'),
      ),
    ];

    GetIt.I.registerSingleton<TenantAdminEventsController>(controller);

    await _pumpWithAutoRoute(
      tester,
      const Scaffold(
        body: TenantAdminEventFormScreen(),
      ),
    );

    await _fillRequiredFields(
      tester,
      controller: controller,
      includeDescription: false,
    );
    await tester.scrollUntilVisible(
      find.widgetWithText(FilledButton, 'Criar evento'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Criar evento'));
    await tester.pumpAndSettle();

    final draft = eventsRepository.lastCreateDraft;
    expect(draft, isNotNull);
    expect(draft!.content, isEmpty);
    expect(draft.location?.mode, 'online');
    expect(draft.placeRef, isNull);
  });

  testWidgets(
      'artist picker disables already selected artists on subsequent open',
      (tester) async {
    final eventsRepository = _FakeEventsRepository();
    final taxonomiesRepository = _FakeTaxonomiesRepository();
    final controller = TenantAdminEventsController(
      eventsRepository: eventsRepository,
      taxonomiesRepository: taxonomiesRepository,
    );

    eventsRepository.eventTypes = [
      TenantAdminEventType(
        idValue: tenantAdminOptionalText('507f1f77bcf86cd799439013'),
        nameValue: tenantAdminRequiredText('Show'),
        slugValue: tenantAdminRequiredText('show'),
        descriptionValue: tenantAdminOptionalText('Tipo de evento: Show'),
      ),
    ];

    GetIt.I.registerSingleton<TenantAdminEventsController>(controller);

    await _pumpWithAutoRoute(
      tester,
      const Scaffold(
        body: TenantAdminEventFormScreen(),
      ),
    );

    await tester.scrollUntilVisible(
      find.widgetWithText(OutlinedButton, 'Adicionar artista'),
      280,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(OutlinedButton, 'Adicionar artista'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ListTile, 'Artist A').first);
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(OutlinedButton, 'Adicionar artista'));
    await tester.pumpAndSettle();

    final disabledTile = tester.widget<ListTile>(
      find.widgetWithText(ListTile, 'Artist A').last,
    );
    expect(disabledTile.enabled, isFalse);
  });

  testWidgets('shows explicit empty states when no host/artist candidates',
      (tester) async {
    final eventsRepository = _EmptyCandidatesEventsRepository();
    final taxonomiesRepository = _FakeTaxonomiesRepository();
    final controller = TenantAdminEventsController(
      eventsRepository: eventsRepository,
      taxonomiesRepository: taxonomiesRepository,
    );

    eventsRepository.eventTypes = [
      TenantAdminEventType(
        idValue: tenantAdminOptionalText('507f1f77bcf86cd799439014'),
        nameValue: tenantAdminRequiredText('Show'),
        slugValue: tenantAdminRequiredText('show'),
        descriptionValue: tenantAdminOptionalText('Tipo de evento: Show'),
      ),
    ];

    GetIt.I.registerSingleton<TenantAdminEventsController>(controller);

    await _pumpWithAutoRoute(
      tester,
      const Scaffold(
        body: TenantAdminEventFormScreen(),
      ),
    );

    await tester.scrollUntilVisible(
      find.text('Nenhum perfil elegível para host físico.'),
      280,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Nenhum perfil elegível para host físico.'),
      findsOneWidget,
    );

    await tester.scrollUntilVisible(
      find.text('Use a busca para localizar artistas além da primeira página carregada.'),
      280,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Use a busca para localizar artistas além da primeira página carregada.',
      ),
      findsOneWidget,
    );
    final addArtistButton = tester.widget<OutlinedButton>(
      find.widgetWithText(OutlinedButton, 'Adicionar artista'),
    );
    expect(addArtistButton.onPressed, isNotNull);
  });

  testWidgets('artist picker performs backend search after typing',
      (tester) async {
    final eventsRepository = _SearchableCandidatesEventsRepository();
    final taxonomiesRepository = _FakeTaxonomiesRepository();
    final controller = TenantAdminEventsController(
      eventsRepository: eventsRepository,
      taxonomiesRepository: taxonomiesRepository,
    );

    eventsRepository.eventTypes = [
      TenantAdminEventType(
        idValue: tenantAdminOptionalText('507f1f77bcf86cd799439099'),
        nameValue: tenantAdminRequiredText('Show'),
        slugValue: tenantAdminRequiredText('show'),
      ),
    ];

    GetIt.I.registerSingleton<TenantAdminEventsController>(controller);

    await _pumpWithAutoRoute(
      tester,
      const Scaffold(
        body: TenantAdminEventFormScreen(),
      ),
    );

    await tester.scrollUntilVisible(
      find.widgetWithText(OutlinedButton, 'Adicionar artista'),
      280,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(OutlinedButton, 'Adicionar artista'));
    await tester.pumpAndSettle();

    expect(find.text('Artist A'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextField, 'Buscar artista'),
      'Zulu',
    );
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();

    expect(find.text('Zulu Artist'), findsOneWidget);
    expect(find.text('Artist A'), findsNothing);
    expect(eventsRepository.recordedSearchTerms, contains('Zulu'));
  });

  testWidgets('uses rich text editor for event description content',
      (tester) async {
    final eventsRepository = _FakeEventsRepository();
    final taxonomiesRepository = _FakeTaxonomiesRepository();
    final controller = TenantAdminEventsController(
      eventsRepository: eventsRepository,
      taxonomiesRepository: taxonomiesRepository,
    );

    eventsRepository.eventTypes = [
      TenantAdminEventType(
        idValue: tenantAdminOptionalText('507f1f77bcf86cd799439120'),
        nameValue: tenantAdminRequiredText('Show'),
        slugValue: tenantAdminRequiredText('show'),
      ),
    ];

    GetIt.I.registerSingleton<TenantAdminEventsController>(controller);

    await _pumpWithAutoRoute(
      tester,
      const Scaffold(
        body: TenantAdminEventFormScreen(),
      ),
    );

    expect(find.byType(TenantAdminRichTextEditor), findsOneWidget);
    expect(find.text('Descrição (opcional)'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Descrição (opcional)'), findsNothing);
  });
}

Future<void> _pumpWithAutoRoute(
  WidgetTester tester,
  Widget child,
) async {
  final router = RootStackRouter.build(
    routes: [
      NamedRouteDef(
        name: 'events-form-test',
        path: '/',
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
  bool includeDescription = true,
}) async {
  await tester.enterText(
      find.widgetWithText(TextFormField, 'Título'), 'Evento');
  if (includeDescription) {
    controller.eventContentController.text = '<p>Descrição do evento</p>';
    await tester.pumpAndSettle();
  }
  final startField = tester
      .widget<TextFormField>(find.widgetWithText(TextFormField, 'Início'));
  startField.controller!.text = '2026-03-05 20:00';
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

class _FakeEventsRepository
    with TenantAdminEventsPaginationMixin
    implements TenantAdminEventsRepositoryContract {
  List<TenantAdminEventType> eventTypes = <TenantAdminEventType>[];
  TenantAdminEventDraft? lastCreateDraft;
  TenantAdminEventDraft? lastCreateOwnDraft;
  String? lastCreateOwnAccountSlug;
  int createEventCalls = 0;
  int createOwnEventCalls = 0;

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
    createOwnEventCalls += 1;
    lastCreateOwnAccountSlug = accountSlug.value;
    lastCreateOwnDraft = draft;
    return _eventFromDraft(draft);
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
      TenantAdminEventAccountProfileCandidateType.artist => [
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
  Future<TenantAdminLegacyEventPartiesSummary> repairLegacyEventParties() async {
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
      artistIdValues: draft.artistIds,
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

class _EmptyCandidatesEventsRepository extends _FakeEventsRepository {
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
}

class _SearchableCandidatesEventsRepository extends _FakeEventsRepository {
  final List<String> recordedSearchTerms = <String>[];

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
      return super.fetchEventAccountProfileCandidatesPage(
        candidateType: candidateType,
        page: page,
        pageSize: pageSize,
        search: search,
        accountSlug: accountSlug,
      );
    }

    final normalizedSearch = search?.value.trim() ?? '';
    if (normalizedSearch.isNotEmpty) {
      recordedSearchTerms.add(normalizedSearch);
    }

    final items = normalizedSearch.toLowerCase() == 'zulu'
        ? <TenantAdminAccountProfile>[
            tenantAdminAccountProfileFromRaw(
              id: 'artist-zulu',
              accountId: 'acc-zulu',
              profileType: 'artist',
              displayName: 'Zulu Artist',
            ),
          ]
        : <TenantAdminAccountProfile>[
            tenantAdminAccountProfileFromRaw(
              id: 'artist-1',
              accountId: 'acc-artist',
              profileType: 'artist',
              displayName: 'Artist A',
            ),
          ];

    return tenantAdminPagedResultFromRaw(
      items: items,
      hasMore: false,
    );
  }
}
