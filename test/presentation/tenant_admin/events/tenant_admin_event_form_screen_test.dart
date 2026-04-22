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
import 'package:belluga_now/presentation/tenant_admin/shared/widgets/tenant_admin_rich_text_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
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

  testWidgets('clears optional end date from the first occurrence form',
      (tester) async {
    final eventsRepository = _FakeEventsRepository();
    final taxonomiesRepository = _FakeTaxonomiesRepository();
    final controller = TenantAdminEventsController(
      eventsRepository: eventsRepository,
      taxonomiesRepository: taxonomiesRepository,
    );

    eventsRepository.eventTypes = [
      TenantAdminEventType(
        idValue: tenantAdminOptionalText('507f1f77bcf86cd799439020'),
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
    final endAt = DateTime(2026, 3, 5, 22);
    controller.applyEventEndAt(endAt);
    await tester.pumpAndSettle();

    expect(controller.eventFormStateStreamValue.value.endAt, endAt);

    await tester.scrollUntilVisible(
      find.text('Fim (opcional)'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Limpar').first);
    await tester.pumpAndSettle();

    expect(controller.eventFormStateStreamValue.value.endAt, isNull);
    expect(controller.eventEndController.text, isEmpty);
    expect(
      controller.eventFormStateStreamValue.value.occurrences.first.dateTimeEnd,
      isNull,
    );
  });

  testWidgets('adds a second occurrence date before create submit',
      (tester) async {
    final eventsRepository = _FakeEventsRepository();
    final taxonomiesRepository = _FakeTaxonomiesRepository();
    final controller = TenantAdminEventsController(
      eventsRepository: eventsRepository,
      taxonomiesRepository: taxonomiesRepository,
    );

    eventsRepository.eventTypes = [
      TenantAdminEventType(
        idValue: tenantAdminOptionalText('507f1f77bcf86cd799439022'),
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
    await tester.pumpAndSettle();
    expect(
      tester.widget<FloatingActionButton>(
        find.byKey(const Key('tenantAdminEventAddOccurrenceButton')),
      ),
      isA<FloatingActionButton>(),
    );
    expect(
      tester
          .getTopLeft(
            find.byKey(const Key('tenantAdminEventAddOccurrenceButton')),
          )
          .dy,
      greaterThanOrEqualTo(0),
    );
    await tester
        .tap(find.byKey(const Key('tenantAdminEventAddOccurrenceButton')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const Key('tenantAdminOccurrenceSaveButton')),
      250,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    final occurrenceSaveButton =
        find.byKey(const Key('tenantAdminOccurrenceSaveButton'));
    await tester.tapAt(
      tester.getTopLeft(occurrenceSaveButton) + const Offset(24, 12),
    );
    await tester.pumpAndSettle();

    expect(
        controller.eventFormStateStreamValue.value.occurrences, hasLength(2));
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

    expect(eventsRepository.lastCreateDraft?.occurrences, hasLength(2));
    expect(
        eventsRepository.lastCreateDraft?.occurrences.first.dateTimeStart.isUtc,
        isTrue);
  });

  testWidgets('adds a second occurrence date before edit submit',
      (tester) async {
    final eventsRepository = _FakeEventsRepository();
    final taxonomiesRepository = _FakeTaxonomiesRepository();
    final controller = TenantAdminEventsController(
      eventsRepository: eventsRepository,
      taxonomiesRepository: taxonomiesRepository,
    );
    final eventType = TenantAdminEventType(
      idValue: tenantAdminOptionalText('507f1f77bcf86cd799439024'),
      nameValue: tenantAdminRequiredText('Feira'),
      slugValue: tenantAdminRequiredText('feira'),
    );

    eventsRepository.eventTypes = [eventType];

    final existingEvent = TenantAdminEvent(
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

    GetIt.I.registerSingleton<TenantAdminEventsController>(controller);

    await _pumpWithAutoRoute(
      tester,
      Scaffold(
        body: TenantAdminEventFormScreen(existingEvent: existingEvent),
      ),
    );

    await tester.pumpAndSettle();
    expect(
      tester.widget<FloatingActionButton>(
        find.byKey(const Key('tenantAdminEventAddOccurrenceButton')),
      ),
      isA<FloatingActionButton>(),
    );

    await tester
        .tap(find.byKey(const Key('tenantAdminEventAddOccurrenceButton')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const Key('tenantAdminOccurrenceSaveButton')),
      250,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('tenantAdminOccurrenceSaveButton')));
    await tester.pumpAndSettle();

    expect(
        controller.eventFormStateStreamValue.value.occurrences, hasLength(2));
    expect(find.byKey(const Key('tenantAdminEventOccurrenceCard_0')),
        findsOneWidget);
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
  });

  testWidgets('authors occurrence scoped profile location and programming',
      (tester) async {
    final eventsRepository = _FakeEventsRepository();
    final taxonomiesRepository = _FakeTaxonomiesRepository();
    final controller = TenantAdminEventsController(
      eventsRepository: eventsRepository,
      taxonomiesRepository: taxonomiesRepository,
    );

    eventsRepository.eventTypes = [
      TenantAdminEventType(
        idValue: tenantAdminOptionalText('507f1f77bcf86cd799439023'),
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
    await tester.pumpAndSettle();
    await tester
        .tap(find.byKey(const Key('tenantAdminEventAddOccurrenceButton')));
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const Key('tenantAdminOccurrenceAddProfileButton')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Artist A').last);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('tenantAdminOccurrenceProfile_artist-1')),
      findsOneWidget,
    );

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
    await tester
        .tap(find.byKey(const Key('tenantAdminOccurrenceLocationMode')));
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
      'Apresentação especial',
    );
    await tester.tap(
      find.byKey(const Key('tenantAdminProgrammingAddProfileButton')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Artist A').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('tenantAdminProgrammingSaveButton')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('tenantAdminOccurrenceProgrammingItem_0')),
      findsOneWidget,
    );

    await tester.scrollUntilVisible(
      find.byKey(const Key('tenantAdminOccurrenceSaveButton')),
      250,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('tenantAdminOccurrenceSaveButton')));
    await tester.pumpAndSettle();

    final occurrence =
        controller.eventFormStateStreamValue.value.occurrences[1];
    expect(
      occurrence.relatedAccountProfileIds.map((value) => value.value),
      contains('artist-1'),
    );
    expect(occurrence.hasLocationOverride, isTrue);
    expect(occurrence.locationOverride?.mode, 'online');
    expect(occurrence.locationOverride?.online?.url,
        'https://stream.example.com/feira');
    expect(occurrence.programmingItems.single.time, '13:00');
    expect(occurrence.programmingItems.single.title, 'Apresentação especial');
    expect(
      occurrence.programmingItems.single.accountProfileIds
          .map((value) => value.value),
      contains('artist-1'),
    );

    await tester.scrollUntilVisible(
      find.widgetWithText(FilledButton, 'Criar evento'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Criar evento'));
    await tester.pumpAndSettle();

    final submittedOccurrence =
        eventsRepository.lastCreateDraft?.occurrences[1];
    expect(submittedOccurrence?.hasLocationOverride, isTrue);
    expect(submittedOccurrence?.programmingItems.single.time, '13:00');
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
      'related account profile picker disables already selected profiles on subsequent open',
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
      find.widgetWithText(OutlinedButton, 'Adicionar perfil'),
      280,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(OutlinedButton, 'Adicionar perfil'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ListTile, 'Artist A').first);
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(OutlinedButton, 'Adicionar perfil'));
    await tester.pumpAndSettle();

    final disabledTile = tester.widget<ListTile>(
      find.widgetWithText(ListTile, 'Artist A').last,
    );
    expect(disabledTile.enabled, isFalse);
  });

  testWidgets(
      'shows explicit empty states when no host/related profile candidates',
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
      find.text(
          'Use a busca para localizar perfis relacionados além da primeira página carregada.'),
      280,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Use a busca para localizar perfis relacionados além da primeira página carregada.',
      ),
      findsOneWidget,
    );
    final addArtistButton = tester.widget<OutlinedButton>(
      find.widgetWithText(OutlinedButton, 'Adicionar perfil'),
    );
    expect(addArtistButton.onPressed, isNotNull);
  });

  testWidgets(
      'related account profile picker performs backend search after typing',
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
      find.widgetWithText(OutlinedButton, 'Adicionar perfil'),
      280,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(OutlinedButton, 'Adicionar perfil'));
    await tester.pumpAndSettle();

    expect(find.text('Artist A'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextField, 'Buscar perfil relacionado'),
      'Zulu',
    );
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();

    expect(find.text('Zulu Artist'), findsOneWidget);
    expect(find.text('Artist A'), findsNothing);
    expect(eventsRepository.recordedSearchTerms, contains('Zulu'));
  });

  testWidgets(
      'adding a searched related account profile keeps its summary visible on the form',
      (tester) async {
    final eventsRepository = _SearchableCandidatesEventsRepository();
    final taxonomiesRepository = _FakeTaxonomiesRepository();
    final controller = TenantAdminEventsController(
      eventsRepository: eventsRepository,
      taxonomiesRepository: taxonomiesRepository,
    );

    eventsRepository.eventTypes = [
      TenantAdminEventType(
        idValue: tenantAdminOptionalText('507f1f77bcf86cd799439100'),
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
      find.widgetWithText(OutlinedButton, 'Adicionar perfil'),
      280,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(OutlinedButton, 'Adicionar perfil'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextField, 'Buscar perfil relacionado'),
      'Zulu',
    );
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ListTile, 'Zulu Artist'));
    await tester.pumpAndSettle();

    expect(find.text('Zulu Artist'), findsOneWidget);
    expect(find.text('Perfil não disponível na lista atual'), findsNothing);
  });

  testWidgets(
      'adding a later-page related account profile keeps its summary visible on the form',
      (tester) async {
    final eventsRepository = _PagedRelatedCandidatesEventsRepository();
    final taxonomiesRepository = _FakeTaxonomiesRepository();
    final controller = TenantAdminEventsController(
      eventsRepository: eventsRepository,
      taxonomiesRepository: taxonomiesRepository,
    );

    eventsRepository.eventTypes = [
      TenantAdminEventType(
        idValue: tenantAdminOptionalText('507f1f77bcf86cd799439100'),
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
      find.widgetWithText(OutlinedButton, 'Adicionar perfil'),
      280,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(OutlinedButton, 'Adicionar perfil'));
    await tester.pumpAndSettle();

    expect(find.text('Legacy Artist Page 2 021'), findsNothing);

    await tester.dragUntilVisible(
      find.text('Legacy Artist Page 2 021'),
      find.byKey(
        const ValueKey<String>(
            'tenant-admin-related-account-profile-picker-list'),
      ),
      const Offset(0, -280),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ListTile, 'Legacy Artist Page 2 021'));
    await tester.pumpAndSettle();

    expect(find.text('Legacy Artist Page 2 021'), findsOneWidget);
    expect(find.text('Perfil não disponível na lista atual'), findsNothing);
  });

  testWidgets(
      'editing preserves selected related account profile summaries after candidate preload completes',
      (tester) async {
    final eventsRepository = _DelayedRelatedCandidatesEventsRepository();
    final taxonomiesRepository = _FakeTaxonomiesRepository();
    final controller = TenantAdminEventsController(
      eventsRepository: eventsRepository,
      taxonomiesRepository: taxonomiesRepository,
    );

    eventsRepository.eventTypes = [
      TenantAdminEventType(
        idValue: tenantAdminOptionalText('507f1f77bcf86cd799439101'),
        nameValue: tenantAdminRequiredText('Show'),
        slugValue: tenantAdminRequiredText('show'),
      ),
    ];

    final preservedProfile = tenantAdminAccountProfileFromRaw(
      id: 'artist-zulu',
      accountId: 'acc-zulu',
      profileType: 'artist',
      displayName: 'Zulu Artist',
      slug: 'zulu-artist',
    );

    final existingEvent = TenantAdminEvent(
      eventIdValue: tenantAdminRequiredText('evt-edit-1'),
      slugValue: tenantAdminRequiredText('event-edit-1'),
      titleValue: tenantAdminRequiredText('Evento em edição'),
      contentValue: tenantAdminOptionalText('Conteúdo'),
      type: TenantAdminEventType(
        idValue: tenantAdminOptionalText('507f1f77bcf86cd799439101'),
        nameValue: tenantAdminRequiredText('Show'),
        slugValue: tenantAdminRequiredText('show'),
      ),
      occurrences: <TenantAdminEventOccurrence>[
        TenantAdminEventOccurrence(
          dateTimeStartValue: tenantAdminDateTime(
            DateTime.utc(2026, 4, 20, 20),
          ),
        ),
      ],
      publication: TenantAdminEventPublication(
        statusValue: tenantAdminRequiredText('draft'),
      ),
      relatedAccountProfiles: [preservedProfile],
      eventParties: [
        TenantAdminEventParty(
          partyTypeValue: tenantAdminRequiredText('artist'),
          partyRefIdValue: tenantAdminRequiredText('artist-zulu'),
          canEditValue: tenantAdminFlag(false),
        ),
      ],
    );

    GetIt.I.registerSingleton<TenantAdminEventsController>(controller);

    await _pumpWithAutoRoute(
      tester,
      Scaffold(
        body: TenantAdminEventFormScreen(existingEvent: existingEvent),
      ),
    );

    expect(find.text('Zulu Artist'), findsOneWidget);
    expect(find.text('Perfil não disponível na lista atual'), findsNothing);

    await tester.pump(eventsRepository.delay);
    await tester.pumpAndSettle();

    expect(find.text('Zulu Artist'), findsOneWidget);
    expect(find.text('Perfil não disponível na lista atual'), findsNothing);
  });

  testWidgets(
      'candidate preload failure keeps selected related account profile summaries visible',
      (tester) async {
    final eventsRepository = _FailingRelatedCandidatesEventsRepository();
    final taxonomiesRepository = _FakeTaxonomiesRepository();
    final controller = TenantAdminEventsController(
      eventsRepository: eventsRepository,
      taxonomiesRepository: taxonomiesRepository,
    );

    eventsRepository.eventTypes = [
      TenantAdminEventType(
        idValue: tenantAdminOptionalText('507f1f77bcf86cd799439102'),
        nameValue: tenantAdminRequiredText('Show'),
        slugValue: tenantAdminRequiredText('show'),
      ),
    ];

    final preservedProfile = tenantAdminAccountProfileFromRaw(
      id: 'artist-zulu',
      accountId: 'acc-zulu',
      profileType: 'artist',
      displayName: 'Zulu Artist',
      slug: 'zulu-artist',
    );

    final existingEvent = TenantAdminEvent(
      eventIdValue: tenantAdminRequiredText('evt-edit-2'),
      slugValue: tenantAdminRequiredText('event-edit-2'),
      titleValue: tenantAdminRequiredText('Evento em edição'),
      contentValue: tenantAdminOptionalText('Conteúdo'),
      type: TenantAdminEventType(
        idValue: tenantAdminOptionalText('507f1f77bcf86cd799439102'),
        nameValue: tenantAdminRequiredText('Show'),
        slugValue: tenantAdminRequiredText('show'),
      ),
      occurrences: <TenantAdminEventOccurrence>[
        TenantAdminEventOccurrence(
          dateTimeStartValue: tenantAdminDateTime(
            DateTime.utc(2026, 4, 20, 20),
          ),
        ),
      ],
      publication: TenantAdminEventPublication(
        statusValue: tenantAdminRequiredText('draft'),
      ),
      relatedAccountProfiles: [preservedProfile],
      eventParties: [
        TenantAdminEventParty(
          partyTypeValue: tenantAdminRequiredText('artist'),
          partyRefIdValue: tenantAdminRequiredText('artist-zulu'),
          canEditValue: tenantAdminFlag(false),
        ),
      ],
    );

    GetIt.I.registerSingleton<TenantAdminEventsController>(controller);

    await _pumpWithAutoRoute(
      tester,
      Scaffold(
        body: TenantAdminEventFormScreen(existingEvent: existingEvent),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Zulu Artist'), findsOneWidget);
    expect(find.text('Perfil não disponível na lista atual'), findsNothing);
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
    expect(find.widgetWithText(TextFormField, 'Descrição (opcional)'),
        findsNothing);
  });

  testWidgets(
      'normalizes description content to the approved HTML subset before submit',
      (tester) async {
    final eventsRepository = _FakeEventsRepository();
    final taxonomiesRepository = _FakeTaxonomiesRepository();
    final controller = TenantAdminEventsController(
      eventsRepository: eventsRepository,
      taxonomiesRepository: taxonomiesRepository,
    );

    eventsRepository.eventTypes = [
      TenantAdminEventType(
        idValue: tenantAdminOptionalText('507f1f77bcf86cd799439017'),
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

    controller.eventContentController.text =
        '<p><strong>Olá 🎉</strong> <u>mundo</u> <a href="https://example.com">link</a> <s>riscado</s></p>';
    await tester.pumpAndSettle();

    final expected = '<p><strong>Olá 🎉</strong> mundo link <s>riscado</s></p>';
    expect(controller.eventContentController.text, expected);
    expect(controller.eventContentController.text, isNot(contains('<u>')));
    expect(controller.eventContentController.text, isNot(contains('<a')));
    expect(controller.eventContentController.text, contains('🎉'));

    final quillEditor = tester.widget<QuillEditor>(find.byType(QuillEditor));
    expect(
      quillEditor.controller.document.toDelta().toJson(),
      equals([
        {
          'insert': 'Olá 🎉',
          'attributes': {'bold': true},
        },
        {'insert': ' mundo link '},
        {
          'insert': 'riscado',
          'attributes': {'strike': true},
        },
        {'insert': '\n'},
      ]),
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
    expect(draft!.content, expected);
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
  bool includeDescription = true,
}) async {
  await tester.enterText(
      find.widgetWithText(TextFormField, 'Título'), 'Evento');
  if (includeDescription) {
    controller.eventContentController.text = '<p>Descrição do evento</p>';
    await tester.pumpAndSettle();
  }
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

class _FakeEventsRepository extends TenantAdminEventsRepositoryContract
    with TenantAdminEventsPaginationMixin {
  List<TenantAdminEventType> eventTypes = <TenantAdminEventType>[];
  TenantAdminEventDraft? lastCreateDraft;
  TenantAdminEventDraft? lastCreateOwnDraft;
  TenantAdminEventDraft? lastUpdateDraft;
  String? lastCreateOwnAccountSlug;
  String? lastUpdateEventId;
  int createEventCalls = 0;
  int createOwnEventCalls = 0;
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

class _PagedRelatedCandidatesEventsRepository extends _FakeEventsRepository {
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

    final firstPageItems = List<TenantAdminAccountProfile>.generate(
      20,
      (index) => tenantAdminAccountProfileFromRaw(
        id: 'artist-page-1-${index + 1}',
        accountId: 'acc-page-1-${index + 1}',
        profileType: 'artist',
        displayName:
            'Legacy Artist Page 1 ${(index + 1).toString().padLeft(3, '0')}',
      ),
      growable: false,
    );
    final pageTwoItems = <TenantAdminAccountProfile>[
      tenantAdminAccountProfileFromRaw(
        id: 'artist-page-2-021',
        accountId: 'acc-page-2-021',
        profileType: 'artist',
        displayName: 'Legacy Artist Page 2 021',
      ),
    ];

    return tenantAdminPagedResultFromRaw(
      items: page.value == 1 ? firstPageItems : pageTwoItems,
      hasMore: page.value == 1,
    );
  }
}

class _DelayedRelatedCandidatesEventsRepository extends _FakeEventsRepository {
  final Duration delay = const Duration(milliseconds: 200);

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
        TenantAdminEventAccountProfileCandidateType.relatedAccountProfile) {
      await Future<void>.delayed(delay);
    }

    return super.fetchEventAccountProfileCandidatesPage(
      candidateType: candidateType,
      page: page,
      pageSize: pageSize,
      search: search,
      accountSlug: accountSlug,
    );
  }
}

class _FailingRelatedCandidatesEventsRepository extends _FakeEventsRepository {
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
        TenantAdminEventAccountProfileCandidateType.relatedAccountProfile) {
      throw Exception('candidate preload failed');
    }

    return super.fetchEventAccountProfileCandidatesPage(
      candidateType: candidateType,
      page: page,
      pageSize: pageSize,
      search: search,
      accountSlug: accountSlug,
    );
  }
}
