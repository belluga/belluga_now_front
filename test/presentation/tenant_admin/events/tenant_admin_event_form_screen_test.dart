import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/domain/repositories/tenant_admin_events_repository_contract.dart';
import 'package:belluga_now/domain/repositories/tenant_admin_taxonomies_repository_contract.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_account_profile.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_event.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_location.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_paged_result.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_definition.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_term_definition.dart';
import 'package:belluga_now/presentation/tenant_admin/events/controllers/tenant_admin_events_controller.dart';
import 'package:belluga_now/presentation/tenant_admin/events/screens/tenant_admin_event_form_screen.dart';
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
        id: '507f1f77bcf86cd799439011',
        name: 'Feira',
        slug: 'feira',
        description: 'Tipo default do teste',
      ),
    ];

    GetIt.I.registerSingleton<TenantAdminEventsController>(controller);

    await _pumpWithAutoRoute(
      tester,
      const Scaffold(
        body: TenantAdminEventFormScreen(),
      ),
    );

    await _fillRequiredFields(tester);
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
        id: '507f1f77bcf86cd799439021',
        name: 'Feira',
        slug: 'feira',
      ),
    ];

    GetIt.I.registerSingleton<TenantAdminEventsController>(controller);

    await _pumpWithAutoRoute(
      tester,
      const Scaffold(
        body: TenantAdminEventFormScreen(),
      ),
    );

    await _fillRequiredFields(tester);
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
        id: '507f1f77bcf86cd799439012',
        name: 'Workshop',
        slug: 'workshop',
        description: 'Tipo de evento: Workshop',
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

    await _fillRequiredFields(tester);
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
        id: '507f1f77bcf86cd799439015',
        name: 'Live',
        slug: 'live',
        description: 'Tipo de evento: Live',
      ),
    ];

    GetIt.I.registerSingleton<TenantAdminEventsController>(controller);

    await _pumpWithAutoRoute(
      tester,
      const Scaffold(
        body: TenantAdminEventFormScreen(),
      ),
    );

    await _fillRequiredFields(tester);
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
        id: '507f1f77bcf86cd799439016',
        name: 'Show',
        slug: 'show',
      ),
    ];

    GetIt.I.registerSingleton<TenantAdminEventsController>(controller);

    await _pumpWithAutoRoute(
      tester,
      const Scaffold(
        body: TenantAdminEventFormScreen(),
      ),
    );

    await _fillRequiredFields(tester, includeDescription: false);
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
        id: '507f1f77bcf86cd799439013',
        name: 'Show',
        slug: 'show',
        description: 'Tipo de evento: Show',
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
        id: '507f1f77bcf86cd799439014',
        name: 'Show',
        slug: 'show',
        description: 'Tipo de evento: Show',
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
      find.text('Nenhum artista elegível encontrado.'),
      280,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('Nenhum artista elegível encontrado.'), findsOneWidget);
    final addArtistButton = tester.widget<OutlinedButton>(
      find.widgetWithText(OutlinedButton, 'Adicionar artista'),
    );
    expect(addArtistButton.onPressed, isNull);
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
  bool includeDescription = true,
}) async {
  await tester.enterText(
      find.widgetWithText(TextFormField, 'Título'), 'Evento');
  if (includeDescription) {
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Descrição (opcional)'),
      'Descrição do evento',
    );
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
    required String accountSlug,
    required TenantAdminEventDraft draft,
  }) async {
    createOwnEventCalls += 1;
    lastCreateOwnAccountSlug = accountSlug;
    lastCreateOwnDraft = draft;
    return _eventFromDraft(draft);
  }

  @override
  Future<void> deleteEvent(String eventId) async {}

  @override
  Future<TenantAdminEvent> fetchEvent(String eventIdOrSlug) async {
    throw UnimplementedError();
  }

  @override
  Future<List<TenantAdminEvent>> fetchEvents({
    String? search,
    String? status,
    bool archived = false,
  }) async {
    return <TenantAdminEvent>[];
  }

  @override
  Future<TenantAdminPagedResult<TenantAdminEvent>> fetchEventsPage({
    required int page,
    required int pageSize,
    String? search,
    String? status,
    bool archived = false,
  }) async {
    return TenantAdminPagedResult<TenantAdminEvent>(
      items: <TenantAdminEvent>[],
      hasMore: false,
    );
  }

  @override
  Future<List<TenantAdminEventType>> fetchEventTypes() async {
    return List<TenantAdminEventType>.unmodifiable(eventTypes);
  }

  @override
  Future<TenantAdminEventPartyCandidates> fetchPartyCandidates({
    String? search,
    String? accountSlug,
  }) async {
    return TenantAdminEventPartyCandidates(
      venues: [
        TenantAdminAccountProfile(
          id: 'venue-1',
          accountId: 'acc-venue',
          profileType: 'venue',
          displayName: 'Venue A',
          location: TenantAdminLocation(
            latitude: -20.611121,
            longitude: -40.498617,
          ),
        ),
      ],
      artists: [
        TenantAdminAccountProfile(
          id: 'artist-1',
          accountId: 'acc-artist',
          profileType: 'artist',
          displayName: 'Artist A',
        ),
      ],
    );
  }

  @override
  Future<TenantAdminEvent> updateEvent({
    required String eventId,
    required TenantAdminEventDraft draft,
  }) async {
    return _eventFromDraft(draft);
  }

  TenantAdminEvent _eventFromDraft(TenantAdminEventDraft draft) {
    return TenantAdminEvent(
      eventId: 'evt-1',
      slug: 'event-1',
      title: draft.title,
      content: draft.content,
      type: draft.type,
      occurrences: draft.occurrences,
      publication: draft.publication,
      location: draft.location,
      placeRef: draft.placeRef,
      artistIds: draft.artistIds,
      taxonomyTerms: draft.taxonomyTerms,
    );
  }
}

class _FakeTaxonomiesRepository
    with TenantAdminTaxonomiesPaginationMixin
    implements TenantAdminTaxonomiesRepositoryContract {
  @override
  Future<TenantAdminTaxonomyDefinition> createTaxonomy({
    required String slug,
    required String name,
    required List<String> appliesTo,
    String? icon,
    String? color,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<TenantAdminTaxonomyTermDefinition> createTerm({
    required String taxonomyId,
    required String slug,
    required String name,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteTaxonomy(String taxonomyId) {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteTerm({
    required String taxonomyId,
    required String termId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<List<TenantAdminTaxonomyDefinition>> fetchTaxonomies() async {
    return [
      TenantAdminTaxonomyDefinition(
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
    required int page,
    required int pageSize,
  }) async {
    final taxonomies = await fetchTaxonomies();
    return TenantAdminPagedResult<TenantAdminTaxonomyDefinition>(
      items: taxonomies,
      hasMore: false,
    );
  }

  @override
  Future<List<TenantAdminTaxonomyTermDefinition>> fetchTerms({
    required String taxonomyId,
  }) async {
    return [
      TenantAdminTaxonomyTermDefinition(
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
    required String taxonomyId,
    required int page,
    required int pageSize,
  }) async {
    final terms = await fetchTerms(taxonomyId: taxonomyId);
    return TenantAdminPagedResult<TenantAdminTaxonomyTermDefinition>(
      items: terms,
      hasMore: false,
    );
  }

  @override
  Future<void> loadNextTaxonomiesPage({int pageSize = 20}) async {}

  @override
  Future<void> loadNextTermsPage({int pageSize = 20}) async {}

  @override
  Future<void> loadTaxonomies({int pageSize = 20}) async {
    final result = await fetchTaxonomiesPage(page: 1, pageSize: pageSize);
    taxonomiesStreamValue.addValue(result.items);
    hasMoreTaxonomiesStreamValue.addValue(result.hasMore);
    taxonomiesErrorStreamValue.addValue(null);
  }

  @override
  Future<void> loadTerms({
    required String taxonomyId,
    int pageSize = 20,
  }) async {
    final result = await fetchTermsPage(
      taxonomyId: taxonomyId,
      page: 1,
      pageSize: pageSize,
    );
    termsStreamValue.addValue(result.items);
    hasMoreTermsStreamValue.addValue(result.hasMore);
    termsErrorStreamValue.addValue(null);
  }

  @override
  void resetTaxonomiesState() {}

  @override
  void resetTermsState() {}

  @override
  Future<TenantAdminTaxonomyDefinition> updateTaxonomy({
    required String taxonomyId,
    String? slug,
    String? name,
    List<String>? appliesTo,
    String? icon,
    String? color,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<TenantAdminTaxonomyTermDefinition> updateTerm({
    required String taxonomyId,
    required String termId,
    String? slug,
    String? name,
  }) {
    throw UnimplementedError();
  }
}

class _EmptyCandidatesEventsRepository extends _FakeEventsRepository {
  @override
  Future<TenantAdminEventPartyCandidates> fetchPartyCandidates({
    String? search,
    String? accountSlug,
  }) async {
    return TenantAdminEventPartyCandidates(
      venues: <TenantAdminAccountProfile>[],
      artists: <TenantAdminAccountProfile>[],
    );
  }
}
