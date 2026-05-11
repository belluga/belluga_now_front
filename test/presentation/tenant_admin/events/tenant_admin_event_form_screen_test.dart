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
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_term.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_term_definition.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_terms.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_terms_by_taxonomy_id.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_account_profile_id_value.dart';
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
      TenantAdminEventType.withAllowedTaxonomies(
        idValue: tenantAdminOptionalText('507f1f77bcf86cd799439011'),
        nameValue: tenantAdminRequiredText('Feira'),
        slugValue: tenantAdminRequiredText('feira'),
        descriptionValue: tenantAdminOptionalText('Tipo default do teste'),
        allowedTaxonomiesValue: tenantAdminTrimmedStringList(
          [_fixtureTaxonomySlug(1)],
        ),
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
      find.text(_fixtureTermLabel(1)),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(_fixtureTermLabel(1)));
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
        (term) =>
            term.type == _fixtureTaxonomySlug(1) &&
            term.value == _fixtureTermSlug(1),
      ),
      isTrue,
    );
    expect(draft.occurrences.first.dateTimeStart.isUtc, isTrue);
    expect(taxonomiesRepository.fetchTermsCalls, 0);
    expect(taxonomiesRepository.batchFetchTaxonomyIds, [
      ['tax-1'],
    ]);
  });

  testWidgets(
      'single occurrence edit exposes occurrence taxonomy without programming items',
      (tester) async {
    final eventsRepository = _FakeEventsRepository();
    final taxonomiesRepository = _FakeTaxonomiesRepository();
    final controller = TenantAdminEventsController(
      eventsRepository: eventsRepository,
      taxonomiesRepository: taxonomiesRepository,
    );

    final eventType = TenantAdminEventType.withAllowedTaxonomies(
      idValue: tenantAdminOptionalText('507f1f77bcf86cd799439041'),
      nameValue: tenantAdminRequiredText('Show'),
      slugValue: tenantAdminRequiredText('show'),
      allowedTaxonomiesValue: tenantAdminTrimmedStringList(
        [_fixtureTaxonomySlug(1)],
      ),
    );
    eventsRepository.eventTypes = [eventType];
    final existingEvent = TenantAdminEvent(
      eventIdValue: tenantAdminRequiredText('evt-single-occurrence-taxonomy'),
      slugValue: tenantAdminRequiredText('evt-single-occurrence-taxonomy'),
      titleValue: tenantAdminRequiredText('Evento sem programacao'),
      contentValue: tenantAdminOptionalText('<p>Conteudo</p>'),
      type: eventType,
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

    await tester.scrollUntilVisible(
      find.byKey(const Key('tenantAdminEventEditPrimaryOccurrenceButton')),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('tenantAdminEventEditPrimaryOccurrenceButton')),
    );
    await tester.pumpAndSettle();

    final occurrenceTaxonomyChip = find.byKey(
      _occurrenceTaxonomyChipKey(_fixtureTaxonomySlug(1), _fixtureTermSlug(1)),
    );
    expect(find.text('Taxonomias da ocorrência'), findsOneWidget);
    expect(occurrenceTaxonomyChip, findsOneWidget);

    await tester.tap(occurrenceTaxonomyChip);
    await tester.pumpAndSettle();
    await _closeOccurrenceSheet(tester);

    await tester.scrollUntilVisible(
      find.widgetWithText(FilledButton, 'Salvar alterações'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Salvar alterações'));
    await tester.pumpAndSettle();

    final occurrenceTerms =
        eventsRepository.lastUpdateDraft?.occurrences.first.taxonomyTerms;
    expect(
      occurrenceTerms?.any(
        (term) =>
            term.type == _fixtureTaxonomySlug(1) &&
            term.value == _fixtureTermSlug(1),
      ),
      isTrue,
    );
  });

  testWidgets(
      'filters event taxonomy UI and submit payload by selected event type',
      (tester) async {
    final eventsRepository = _FakeEventsRepository();
    final taxonomiesRepository = _FakeTaxonomiesRepository();
    final controller = TenantAdminEventsController(
      eventsRepository: eventsRepository,
      taxonomiesRepository: taxonomiesRepository,
    );

    final eventType = TenantAdminEventType.withAllowedTaxonomies(
      idValue: tenantAdminOptionalText('507f1f77bcf86cd799439031'),
      nameValue: tenantAdminRequiredText('Feira'),
      slugValue: tenantAdminRequiredText('feira'),
      allowedTaxonomiesValue: tenantAdminTrimmedStringList(
        [_fixtureTaxonomySlug(1)],
      ),
    );

    eventsRepository.eventTypes = [eventType];
    final existingEvent = TenantAdminEvent(
      eventIdValue: tenantAdminRequiredText('evt-taxonomy-filter'),
      slugValue: tenantAdminRequiredText('evt-taxonomy-filter'),
      titleValue: tenantAdminRequiredText('Evento com taxonomia legada'),
      contentValue: tenantAdminOptionalText('<p>Conteúdo</p>'),
      type: eventType,
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
      location: TenantAdminEventLocation(
        modeValue: tenantAdminRequiredText('online'),
        online: TenantAdminEventOnlineLocation(
          urlValue: tenantAdminRequiredText('https://example.com/live'),
        ),
      ),
      taxonomyTerms: _tenantAdminTaxonomyTerms([
        tenantAdminTaxonomyTermFromRaw(
          type: _fixtureTaxonomySlug(1),
          value: _fixtureTermSlug(1),
        ),
        tenantAdminTaxonomyTermFromRaw(
          type: _fixtureTaxonomySlug(2),
          value: _fixtureTermSlug(2),
        ),
      ]),
    );

    GetIt.I.registerSingleton<TenantAdminEventsController>(controller);

    await _pumpWithAutoRoute(
      tester,
      Scaffold(
        body: TenantAdminEventFormScreen(existingEvent: existingEvent),
      ),
    );

    await tester.scrollUntilVisible(
      find.text(_fixtureTermLabel(1)),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text(_fixtureTaxonomyLabel(1)), findsOneWidget);
    expect(find.text(_fixtureTermLabel(1)), findsOneWidget);
    expect(find.text(_fixtureTaxonomyLabel(2)), findsNothing);
    expect(find.text(_fixtureTermLabel(2)), findsNothing);

    await tester.scrollUntilVisible(
      find.widgetWithText(FilledButton, 'Salvar alterações'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Salvar alterações'));
    await tester.pumpAndSettle();

    final submittedTerms = eventsRepository.lastUpdateDraft?.taxonomyTerms
        .map((term) => '${term.type}:${term.value}')
        .toList(growable: false);
    expect(
      submittedTerms,
      [_encodedAdminTaxonomyTerm(_fixtureTaxonomySlug(1), _fixtureTermSlug(1))],
    );
    expect(taxonomiesRepository.fetchTermsCalls, 0);
    expect(taxonomiesRepository.batchFetchTaxonomyIds, [
      ['tax-1'],
    ]);
  });

  testWidgets(
      'edit flow keeps taxonomy UI visible when event type catalog omits allowed taxonomies',
      (tester) async {
    final eventsRepository = _FakeEventsRepository();
    final taxonomiesRepository = _FakeTaxonomiesRepository();
    final controller = TenantAdminEventsController(
      eventsRepository: eventsRepository,
      taxonomiesRepository: taxonomiesRepository,
    );

    eventsRepository.eventTypes = [
      TenantAdminEventType(
        idValue: tenantAdminOptionalText('507f1f77bcf86cd799439032'),
        nameValue: tenantAdminRequiredText('Feira'),
        slugValue: tenantAdminRequiredText('feira'),
      ),
    ];

    final existingEvent = TenantAdminEvent(
      eventIdValue: tenantAdminRequiredText('evt-taxonomy-fallback'),
      slugValue: tenantAdminRequiredText('evt-taxonomy-fallback'),
      titleValue: tenantAdminRequiredText('Evento com fallback de taxonomia'),
      contentValue: tenantAdminOptionalText('<p>Conteúdo</p>'),
      type: TenantAdminEventType.withAllowedTaxonomies(
        idValue: tenantAdminOptionalText('507f1f77bcf86cd799439032'),
        nameValue: tenantAdminRequiredText('Feira'),
        slugValue: tenantAdminRequiredText('feira'),
        allowedTaxonomiesValue: tenantAdminTrimmedStringList(
          [_fixtureTaxonomySlug(1)],
        ),
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

    await tester.scrollUntilVisible(
      find.text(_fixtureTermLabel(1)),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text(_fixtureTaxonomyLabel(1)), findsOneWidget);
    expect(find.text(_fixtureTermLabel(1)), findsOneWidget);
    expect(taxonomiesRepository.fetchTermsCalls, 0);
    expect(taxonomiesRepository.batchFetchTaxonomyIds, [
      ['tax-1'],
    ]);
  });

  testWidgets('reloads taxonomy terms in one batch when event type changes',
      (tester) async {
    final eventsRepository = _FakeEventsRepository();
    final taxonomiesRepository = _FakeTaxonomiesRepository();
    final controller = TenantAdminEventsController(
      eventsRepository: eventsRepository,
      taxonomiesRepository: taxonomiesRepository,
    );

    final feiraType = TenantAdminEventType.withAllowedTaxonomies(
      idValue: tenantAdminOptionalText('507f1f77bcf86cd799439033'),
      nameValue: tenantAdminRequiredText('Feira'),
      slugValue: tenantAdminRequiredText('feira'),
      allowedTaxonomiesValue: tenantAdminTrimmedStringList(
        [_fixtureTaxonomySlug(1)],
      ),
    );
    final restauranteType = TenantAdminEventType.withAllowedTaxonomies(
      idValue: tenantAdminOptionalText('507f1f77bcf86cd799439034'),
      nameValue: tenantAdminRequiredText('Restaurante'),
      slugValue: tenantAdminRequiredText('restaurante'),
      allowedTaxonomiesValue: tenantAdminTrimmedStringList(
        [_fixtureTaxonomySlug(2)],
      ),
    );

    eventsRepository.eventTypes = [feiraType, restauranteType];
    final existingEvent = TenantAdminEvent(
      eventIdValue: tenantAdminRequiredText('evt-taxonomy-type-change'),
      slugValue: tenantAdminRequiredText('evt-taxonomy-type-change'),
      titleValue: tenantAdminRequiredText('Evento com troca de tipo'),
      contentValue: tenantAdminOptionalText('<p>Conteúdo</p>'),
      type: feiraType,
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
      location: TenantAdminEventLocation(
        modeValue: tenantAdminRequiredText('online'),
        online: TenantAdminEventOnlineLocation(
          urlValue: tenantAdminRequiredText('https://example.com/live'),
        ),
      ),
      taxonomyTerms: _tenantAdminTaxonomyTerms([
        tenantAdminTaxonomyTermFromRaw(
          type: _fixtureTaxonomySlug(1),
          value: _fixtureTermSlug(1),
        ),
      ]),
    );

    GetIt.I.registerSingleton<TenantAdminEventsController>(controller);

    await _pumpWithAutoRoute(
      tester,
      Scaffold(
        body: TenantAdminEventFormScreen(existingEvent: existingEvent),
      ),
    );

    await tester.scrollUntilVisible(
      find.text(_fixtureTermLabel(1)),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text(_fixtureTaxonomyLabel(1)), findsOneWidget);
    expect(find.text(_fixtureTermLabel(1)), findsOneWidget);
    expect(find.text(_fixtureTaxonomyLabel(2)), findsNothing);
    expect(find.text(_fixtureTermLabel(2)), findsNothing);

    await tester.scrollUntilVisible(
      find.byType(DropdownButtonFormField<String>).first,
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Restaurante').last);
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text(_fixtureTermLabel(2)),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text(_fixtureTaxonomyLabel(1)), findsNothing);
    expect(find.text(_fixtureTermLabel(1)), findsNothing);
    expect(find.text(_fixtureTaxonomyLabel(2)), findsOneWidget);
    expect(find.text(_fixtureTermLabel(2)), findsOneWidget);
    expect(taxonomiesRepository.fetchTermsCalls, 0);
    expect(taxonomiesRepository.batchFetchTaxonomyIds, [
      ['tax-1'],
      ['tax-2'],
    ]);
  });

  testWidgets('hides taxonomy section when selected event type allows none',
      (tester) async {
    final eventsRepository = _FakeEventsRepository();
    final taxonomiesRepository = _FakeTaxonomiesRepository();
    final controller = TenantAdminEventsController(
      eventsRepository: eventsRepository,
      taxonomiesRepository: taxonomiesRepository,
    );

    final eventType = TenantAdminEventType.withAllowedTaxonomies(
      idValue: tenantAdminOptionalText('507f1f77bcf86cd799439032'),
      nameValue: tenantAdminRequiredText('Karaoke'),
      slugValue: tenantAdminRequiredText('karaoke'),
      allowedTaxonomiesValue: tenantAdminTrimmedStringList(const []),
    );

    eventsRepository.eventTypes = [eventType];
    final existingEvent = TenantAdminEvent(
      eventIdValue: tenantAdminRequiredText('evt-karaoke'),
      slugValue: tenantAdminRequiredText('evt-karaoke'),
      titleValue: tenantAdminRequiredText('Evento Karaoke'),
      contentValue: tenantAdminOptionalText('<p>Conteúdo</p>'),
      type: eventType,
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
      location: TenantAdminEventLocation(
        modeValue: tenantAdminRequiredText('online'),
        online: TenantAdminEventOnlineLocation(
          urlValue: tenantAdminRequiredText('https://example.com/live'),
        ),
      ),
      taxonomyTerms: _tenantAdminTaxonomyTerms([
        tenantAdminTaxonomyTermFromRaw(
          type: _fixtureTaxonomySlug(1),
          value: _fixtureTermSlug(1),
        ),
        tenantAdminTaxonomyTermFromRaw(
          type: _fixtureTaxonomySlug(2),
          value: _fixtureTermSlug(2),
        ),
      ]),
    );

    GetIt.I.registerSingleton<TenantAdminEventsController>(controller);

    await _pumpWithAutoRoute(
      tester,
      Scaffold(
        body: TenantAdminEventFormScreen(existingEvent: existingEvent),
      ),
    );

    expect(find.text('Taxonomias'), findsNothing);
    expect(find.text(_fixtureTaxonomyLabel(1)), findsNothing);
    expect(find.text(_fixtureTermLabel(1)), findsNothing);
    expect(find.text(_fixtureTaxonomyLabel(2)), findsNothing);
    expect(find.text(_fixtureTermLabel(2)), findsNothing);

    await tester.scrollUntilVisible(
      find.widgetWithText(FilledButton, 'Salvar alterações'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Salvar alterações'));
    await tester.pumpAndSettle();

    expect(eventsRepository.lastUpdateDraft?.taxonomyTerms.isEmpty, isTrue);
    expect(taxonomiesRepository.fetchTermsCalls, 0);
    expect(taxonomiesRepository.batchFetchTaxonomyIds, isEmpty);
  });

  testWidgets('renders empty state when allowed taxonomy has no terms',
      (tester) async {
    final eventsRepository = _FakeEventsRepository();
    final taxonomiesRepository = _FakeTaxonomiesRepository();
    final controller = TenantAdminEventsController(
      eventsRepository: eventsRepository,
      taxonomiesRepository: taxonomiesRepository,
    );

    final eventType = TenantAdminEventType.withAllowedTaxonomies(
      idValue: tenantAdminOptionalText('507f1f77bcf86cd799439035'),
      nameValue: tenantAdminRequiredText('Feira'),
      slugValue: tenantAdminRequiredText('feira'),
      allowedTaxonomiesValue: tenantAdminTrimmedStringList(
        [_fixtureTaxonomySlug(1), _fixtureTaxonomySlug(3)],
      ),
    );

    eventsRepository.eventTypes = [eventType];
    final existingEvent = TenantAdminEvent(
      eventIdValue: tenantAdminRequiredText('evt-empty-taxonomy'),
      slugValue: tenantAdminRequiredText('evt-empty-taxonomy'),
      titleValue: tenantAdminRequiredText('Evento com taxonomia vazia'),
      contentValue: tenantAdminOptionalText('<p>Conteúdo</p>'),
      type: eventType,
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

    await tester.scrollUntilVisible(
      find.text(_fixtureTermLabel(1)),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('Taxonomias'), findsOneWidget);
    expect(find.text(_fixtureTaxonomyLabel(1)), findsOneWidget);
    expect(find.text(_fixtureTermLabel(1)), findsOneWidget);
    expect(find.text(_fixtureTaxonomyLabel(3)), findsOneWidget);
    expect(
      find.text('Nenhum termo cadastrado para esta taxonomia.'),
      findsOneWidget,
    );
    expect(taxonomiesRepository.fetchTermsCalls, 0);
    expect(taxonomiesRepository.batchFetchTaxonomyIds, hasLength(1));
    expect(
      taxonomiesRepository.batchFetchTaxonomyIds.single,
      unorderedEquals(['tax-1', 'tax-empty']),
    );
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

  testWidgets('dirty event form asks before closing without saving',
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

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Título'),
      'Evento com alteração local',
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Fechar').first);
    await tester.pumpAndSettle();

    expect(find.text('Sair sem salvar?'), findsOneWidget);
    expect(
      find.text('As alterações neste evento ainda não foram salvas.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Continuar editando'));
    await tester.pumpAndSettle();

    expect(find.text('Sair sem salvar?'), findsNothing);
    expect(find.text('Evento com alteração local'), findsOneWidget);
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
    expect(
      find.byKey(const Key('tenantAdminOccurrenceSaveButton')),
      findsNothing,
    );
    expect(find.text('Salvar data'), findsNothing);
    await _closeOccurrenceSheet(tester);

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

  testWidgets('authors occurrence taxonomy overrides from the date editor',
      (tester) async {
    final eventsRepository = _FakeEventsRepository();
    final taxonomiesRepository = _FakeTaxonomiesRepository();
    final controller = TenantAdminEventsController(
      eventsRepository: eventsRepository,
      taxonomiesRepository: taxonomiesRepository,
    );

    eventsRepository.eventTypes = [
      TenantAdminEventType.withAllowedTaxonomies(
        idValue: tenantAdminOptionalText('507f1f77bcf86cd799439023'),
        nameValue: tenantAdminRequiredText('Feira'),
        slugValue: tenantAdminRequiredText('feira'),
        allowedTaxonomiesValue: tenantAdminTrimmedStringList(
          [_fixtureTaxonomySlug(1)],
        ),
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

    final selectedTaxonomyChipKey = _occurrenceTaxonomyChipKey(
        _fixtureTaxonomySlug(1), _fixtureTermSlug(1));
    await tester.scrollUntilVisible(
      find.byKey(selectedTaxonomyChipKey),
      250,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(selectedTaxonomyChipKey));
    await tester.pumpAndSettle();
    await _closeOccurrenceSheet(tester);

    await tester.scrollUntilVisible(
      find.widgetWithText(FilledButton, 'Criar evento'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Criar evento'));
    await tester.pumpAndSettle();

    final occurrenceTerms = eventsRepository
        .lastCreateDraft?.occurrences[1].taxonomyTerms
        .map((term) => '${term.type}:${term.value}')
        .toList(growable: false);
    expect(occurrenceTerms, [
      _encodedAdminTaxonomyTerm(_fixtureTaxonomySlug(1), _fixtureTermSlug(1))
    ]);
  });

  testWidgets(
      'authors occurrence programming optional end time from the date editor',
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
      '17:00',
    );
    await tester.enterText(
      find.byKey(const Key('tenantAdminProgrammingEndTimeField')),
      '18:30',
    );
    await tester.enterText(
      find.byKey(const Key('tenantAdminProgrammingTitleField')),
      'Show com encerramento',
    );
    await _tapProgrammingSaveButton(tester);
    await tester.pumpAndSettle();
    await _closeOccurrenceSheet(tester);

    await tester.scrollUntilVisible(
      find.widgetWithText(FilledButton, 'Criar evento'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Criar evento'));
    await tester.pumpAndSettle();

    final programmingItem = eventsRepository
        .lastCreateDraft?.occurrences[1].programmingItems.single;
    expect(programmingItem?.time, '17:00');
    expect(programmingItem?.endTime, '18:30');
    expect(programmingItem?.title, 'Show com encerramento');
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
    await _closeOccurrenceSheet(tester);

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

  testWidgets(
      'editing unrelated event fields preserves occurrence-owned profiles and programming in update draft',
      (tester) async {
    final eventsRepository = _FakeEventsRepository();
    final taxonomiesRepository = _FakeTaxonomiesRepository();
    final controller = TenantAdminEventsController(
      eventsRepository: eventsRepository,
      taxonomiesRepository: taxonomiesRepository,
    );

    eventsRepository.eventTypes = [
      TenantAdminEventType(
        idValue: tenantAdminOptionalText('507f1f77bcf86cd799439024'),
        nameValue: tenantAdminRequiredText('Feira'),
        slugValue: tenantAdminRequiredText('feira'),
      ),
    ];

    final occurrenceProfile = tenantAdminAccountProfileFromRaw(
      id: 'artist-1',
      accountId: 'acc-artist',
      profileType: 'artist',
      displayName: 'Artist A',
    );

    final existingEvent = TenantAdminEvent(
      eventIdValue: tenantAdminRequiredText('evt-existing-details-1'),
      slugValue: tenantAdminRequiredText('event-existing-details-1'),
      titleValue: tenantAdminRequiredText('Evento com detalhes'),
      contentValue: tenantAdminOptionalText('Conteúdo'),
      type: TenantAdminEventType(
        idValue: tenantAdminOptionalText('507f1f77bcf86cd799439024'),
        nameValue: tenantAdminRequiredText('Feira'),
        slugValue: tenantAdminRequiredText('feira'),
      ),
      location: TenantAdminEventLocation(
        modeValue: tenantAdminRequiredText('physical'),
      ),
      placeRef: TenantAdminEventPlaceRef(
        typeValue: tenantAdminRequiredText('account_profile'),
        idValue: tenantAdminRequiredText('venue-1'),
      ),
      occurrences: <TenantAdminEventOccurrence>[
        TenantAdminEventOccurrence(
          dateTimeStartValue: tenantAdminDateTime(
            DateTime.utc(2026, 4, 20, 20),
          ),
        ),
        TenantAdminEventOccurrence(
          occurrenceIdValue: tenantAdminOptionalText('occ-2'),
          occurrenceSlugValue: tenantAdminOptionalText('occ-2-slug'),
          dateTimeStartValue: tenantAdminDateTime(
            DateTime.utc(2026, 4, 21, 17),
          ),
          relatedAccountProfileIdValues: [
            TenantAdminAccountProfileIdValue('artist-1'),
          ],
          relatedAccountProfiles: [occurrenceProfile],
          programmingItems: [
            TenantAdminEventProgrammingItem(
              timeValue: tenantAdminRequiredText('17:00'),
              titleValue: tenantAdminOptionalText('Show com a banda'),
              accountProfileIdValues: [
                TenantAdminAccountProfileIdValue('artist-1'),
              ],
              linkedAccountProfiles: [occurrenceProfile],
              placeRef: TenantAdminEventPlaceRef(
                typeValue: tenantAdminRequiredText('account_profile'),
                idValue: tenantAdminRequiredText('venue-1'),
              ),
            ),
          ],
        ),
      ],
      publication: TenantAdminEventPublication(
        statusValue: tenantAdminRequiredText('draft'),
      ),
    );

    GetIt.I.registerSingleton<TenantAdminEventsController>(controller);

    await _pumpWithAutoRoute(
      tester,
      Scaffold(
        body: TenantAdminEventFormScreen(existingEvent: existingEvent),
      ),
    );

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Título'),
      'Evento com detalhes atualizado',
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.widgetWithText(FilledButton, 'Salvar alterações'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Salvar alterações'));
    await tester.pumpAndSettle();

    expect(eventsRepository.updateEventCalls, 1);
    expect(eventsRepository.lastUpdateEventId, 'evt-existing-details-1');
    final submittedOccurrence =
        eventsRepository.lastUpdateDraft?.occurrences[1];
    expect(
      submittedOccurrence?.relatedAccountProfileIds
          .map((value) => value.value)
          .toList(growable: false),
      ['artist-1'],
    );
    expect(
      submittedOccurrence?.programmingItems
          .map((item) => item.title)
          .toList(growable: false),
      ['Show com a banda'],
    );
    expect(
      submittedOccurrence?.programmingItems.single.accountProfileIds
          .map((value) => value.value)
          .toList(growable: false),
      ['artist-1'],
    );
    expect(
        submittedOccurrence?.programmingItems.single.placeRef?.id, 'venue-1');
  });

  testWidgets(
      'authors occurrence scoped programming from occurrence participants without promoting event-level related profiles',
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

    expect(
      find.byKey(const Key('tenantAdminOccurrenceLocationOverrideSwitch')),
      findsNothing,
    );
    expect(
      find.byKey(const Key('tenantAdminOccurrenceOnlineUrl')),
      findsNothing,
    );

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
    final linkOccurrenceProfileButton = tester.widget<OutlinedButton>(
      find.byKey(
        const Key('tenantAdminProgrammingLinkOccurrenceProfileButton'),
      ),
    );
    expect(linkOccurrenceProfileButton.onPressed, isNull);
    await tester.tap(
      find.byKey(
        const Key('tenantAdminProgrammingAddOccurrenceProfileButton'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Artist A').last);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('tenantAdminProgrammingProfile_artist-1')),
      findsOneWidget,
    );
    await tester.ensureVisible(
      find.byKey(const Key('tenantAdminProgrammingLocationProfileDropdown')),
    );
    await tester.tap(
      find.byKey(const Key('tenantAdminProgrammingLocationProfileDropdown')),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Sem local específico'), findsWidgets);
    expect(find.bySemanticsLabel('Venue A'), findsWidgets);
    await tester.tap(
      find.byKey(const Key('tenantAdminProgrammingLocationOption_venue-1')),
    );
    await tester.pumpAndSettle();
    await _tapProgrammingSaveButton(tester);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('tenantAdminOccurrenceProgrammingItem_0')),
      findsOneWidget,
    );
    expect(find.text('Local: Venue A'), findsOneWidget);

    await _closeOccurrenceSheet(tester);

    final occurrence =
        controller.eventFormStateStreamValue.value.occurrences[1];
    expect(
      occurrence.relatedAccountProfileIds.map((value) => value.value),
      contains('artist-1'),
    );
    expect(occurrence.programmingItems.single.time, '13:00');
    expect(occurrence.programmingItems.single.title, 'Apresentação especial');
    expect(
      occurrence.programmingItems.single.accountProfileIds
          .map((value) => value.value),
      contains('artist-1'),
    );
    expect(
        occurrence.programmingItems.single.placeRef?.type, 'account_profile');
    expect(occurrence.programmingItems.single.placeRef?.id, 'venue-1');
    expect(
      controller
          .eventFormStateStreamValue.value.selectedRelatedAccountProfileIds,
      isEmpty,
    );
    expect(
      find.byKey(const Key('tenantAdminRelatedProfileChip_artist-1')),
      findsNothing,
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
    expect(submittedOccurrence?.programmingItems.single.time, '13:00');
    expect(
      eventsRepository.lastCreateDraft?.relatedAccountProfileIds
          .map((value) => value.value),
      isEmpty,
    );
  });

  testWidgets(
      'removing an occurrence participant also removes it from occurrence programming links',
      (tester) async {
    final eventsRepository = _FakeEventsRepository();
    final taxonomiesRepository = _FakeTaxonomiesRepository();
    final controller = TenantAdminEventsController(
      eventsRepository: eventsRepository,
      taxonomiesRepository: taxonomiesRepository,
    );

    eventsRepository.eventTypes = [
      TenantAdminEventType(
        idValue: tenantAdminOptionalText('507f1f77bcf86cd799439024'),
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
      find.byKey(
        const Key('tenantAdminProgrammingLinkOccurrenceProfileButton'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Artist A').last);
    await tester.pumpAndSettle();
    await _tapProgrammingSaveButton(tester);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('tenantAdminOccurrenceProgrammingItem_0')),
      findsOneWidget,
    );

    await tester.tap(find.byTooltip('Remover perfil da ocorrência'));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('tenantAdminOccurrenceProfile_artist-1')),
      findsNothing,
    );
    expect(find.text('0 perfil(is) vinculado(s)'), findsOneWidget);

    await _closeOccurrenceSheet(tester);

    final occurrence =
        controller.eventFormStateStreamValue.value.occurrences[1];
    expect(occurrence.relatedAccountProfileIds, isEmpty);
    expect(occurrence.programmingItems.single.title, 'Apresentação especial');
    expect(occurrence.programmingItems.single.accountProfileIds, isEmpty);
  });

  testWidgets('edits occurrence programming item location in admin UI',
      (tester) async {
    final eventsRepository = _FakeEventsRepository();
    final taxonomiesRepository = _FakeTaxonomiesRepository();
    final controller = TenantAdminEventsController(
      eventsRepository: eventsRepository,
      taxonomiesRepository: taxonomiesRepository,
    );

    eventsRepository.eventTypes = [
      TenantAdminEventType(
        idValue: tenantAdminOptionalText('507f1f77bcf86cd799439099'),
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
    await tester.ensureVisible(
      find.byKey(const Key('tenantAdminProgrammingLocationProfileDropdown')),
    );
    await tester.tap(
      find.byKey(const Key('tenantAdminProgrammingLocationProfileDropdown')),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('tenantAdminProgrammingLocationOption_venue-1')),
    );
    await tester.pumpAndSettle();
    await _tapProgrammingSaveButton(tester);
    await tester.pumpAndSettle();

    expect(find.text('Local: Venue A'), findsOneWidget);

    await tester.tap(
      find.byKey(const Key('tenantAdminOccurrenceProgrammingItem_0')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Editar item de programação'), findsOneWidget);

    await tester.ensureVisible(
      find.byKey(const Key('tenantAdminProgrammingLocationProfileDropdown')),
    );
    await tester.tap(
      find.byKey(const Key('tenantAdminProgrammingLocationProfileDropdown')),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('tenantAdminProgrammingLocationOption_none')),
    );
    await tester.pumpAndSettle();
    await _tapProgrammingSaveButton(tester);
    await tester.pumpAndSettle();

    expect(find.text('Local: Venue A'), findsNothing);

    await _closeOccurrenceSheet(tester);

    final occurrence =
        controller.eventFormStateStreamValue.value.occurrences[1];
    expect(occurrence.programmingItems.single.placeRef, isNull);
  });

  testWidgets('programming location picker filters venues by search',
      (tester) async {
    final eventsRepository = _FakeEventsRepository()
      ..physicalHostCandidates = [
        tenantAdminAccountProfileFromRaw(
          id: 'venue-1',
          accountId: 'acc-venue-1',
          profileType: 'venue',
          displayName: 'Venue A',
          location: tenantAdminLocationFromRaw(
            latitude: -20.611121,
            longitude: -40.498617,
          ),
        ),
        tenantAdminAccountProfileFromRaw(
          id: 'venue-2',
          accountId: 'acc-venue-2',
          profileType: 'venue',
          displayName: 'Casa do Jazz',
          location: tenantAdminLocationFromRaw(
            latitude: -20.612121,
            longitude: -40.498917,
          ),
        ),
        tenantAdminAccountProfileFromRaw(
          id: 'venue-3',
          accountId: 'acc-venue-3',
          profileType: 'venue',
          displayName: 'Arena do Sol',
          location: tenantAdminLocationFromRaw(
            latitude: -20.612521,
            longitude: -40.499217,
          ),
        ),
      ];
    final taxonomiesRepository = _FakeTaxonomiesRepository();
    final controller = TenantAdminEventsController(
      eventsRepository: eventsRepository,
      taxonomiesRepository: taxonomiesRepository,
    );

    eventsRepository.eventTypes = [
      TenantAdminEventType(
        idValue: tenantAdminOptionalText('507f1f77bcf86cd799439100'),
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
    await tester.ensureVisible(
      find.byKey(const Key('tenantAdminProgrammingLocationProfileDropdown')),
    );
    await tester.tap(
      find.byKey(const Key('tenantAdminProgrammingLocationProfileDropdown')),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('tenantAdminProgrammingLocationSearchField')),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel('Venue A'), findsWidgets);
    expect(find.bySemanticsLabel('Casa do Jazz'), findsWidgets);
    expect(find.bySemanticsLabel('Arena do Sol'), findsWidgets);

    await tester.enterText(
      find.byKey(const Key('tenantAdminProgrammingLocationSearchField')),
      'Jazz',
    );
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('Sem local específico'), findsWidgets);
    expect(find.bySemanticsLabel('Casa do Jazz'), findsWidgets);
    expect(find.bySemanticsLabel('Venue A'), findsNothing);
    expect(find.bySemanticsLabel('Arena do Sol'), findsNothing);

    await tester.tap(
      find.byKey(const Key('tenantAdminProgrammingLocationOption_venue-2')),
    );
    await tester.pumpAndSettle();
    await _tapProgrammingSaveButton(tester);
    await tester.pumpAndSettle();

    expect(find.text('Local: Casa do Jazz'), findsOneWidget);

    await _closeOccurrenceSheet(tester);

    final occurrence =
        controller.eventFormStateStreamValue.value.occurrences[1];
    expect(occurrence.programmingItems.single.placeRef?.id, 'venue-2');
  });

  testWidgets(
      'single-occurrence root programming is preserved after adding a second date',
      (tester) async {
    final eventsRepository = _FakeEventsRepository();
    final taxonomiesRepository = _FakeTaxonomiesRepository();
    final controller = TenantAdminEventsController(
      eventsRepository: eventsRepository,
      taxonomiesRepository: taxonomiesRepository,
    );

    eventsRepository.eventTypes = [
      TenantAdminEventType(
        idValue: tenantAdminOptionalText('507f1f77bcf86cd799439188'),
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
      find.byKey(const Key('tenantAdminPrimaryOccurrenceProgrammingSection')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('tenantAdminEventOccurrenceCard_0')),
      findsNothing,
    );

    await tester.scrollUntilVisible(
      find.byKey(const Key('tenantAdminPrimaryOccurrenceAddProgrammingButton')),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('tenantAdminPrimaryOccurrenceAddProgrammingButton')),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('tenantAdminProgrammingTimeField')),
      '19:00',
    );
    await tester.enterText(
      find.byKey(const Key('tenantAdminProgrammingTitleField')),
      'Abertura principal',
    );
    await _tapProgrammingSaveButton(tester);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('tenantAdminPrimaryOccurrenceProgrammingItem_0')),
      findsOneWidget,
    );
    expect(find.text('Abertura principal'), findsOneWidget);

    await tester
        .tap(find.byKey(const Key('tenantAdminEventAddOccurrenceButton')));
    await tester.pumpAndSettle();
    await _closeOccurrenceSheet(tester);

    expect(
      find.byKey(const Key('tenantAdminPrimaryOccurrenceProgrammingSection')),
      findsNothing,
    );
    expect(find.byKey(const Key('tenantAdminEventOccurrenceCard_0')),
        findsOneWidget);
    expect(find.byKey(const Key('tenantAdminEventOccurrenceCard_1')),
        findsOneWidget);
    expect(find.text('1 item de programação'), findsOneWidget);

    await tester.ensureVisible(
      find.byKey(const Key('tenantAdminEventOccurrenceCard_0')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('tenantAdminEventOccurrenceCard_0')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('tenantAdminOccurrenceProgrammingItem_0')),
      findsOneWidget,
    );
    expect(find.text('Abertura principal'), findsOneWidget);

    await _closeOccurrenceSheet(tester);

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
      eventsRepository.lastCreateDraft?.occurrences.first.programmingItems
          .map((item) => item.title)
          .toList(growable: false),
      ['Abertura principal'],
    );
  });

  testWidgets(
      'multi-occurrence editor accumulates multiple programming items without occurrence save boundary',
      (tester) async {
    final eventsRepository = _FakeEventsRepository();
    final taxonomiesRepository = _FakeTaxonomiesRepository();
    final controller = TenantAdminEventsController(
      eventsRepository: eventsRepository,
      taxonomiesRepository: taxonomiesRepository,
    );

    eventsRepository.eventTypes = [
      TenantAdminEventType(
        idValue: tenantAdminOptionalText('507f1f77bcf86cd799439189'),
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
    await _closeOccurrenceSheet(tester);

    expect(
        controller.eventFormStateStreamValue.value.occurrences, hasLength(2));

    await tester.ensureVisible(
      find.byKey(const Key('tenantAdminEventOccurrenceCard_1')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('tenantAdminEventOccurrenceCard_1')));
    await tester.pumpAndSettle();

    await _addOccurrenceProgrammingTitleOnly(
      tester,
      time: '10:00',
      title: 'Primeira atividade',
    );
    expect(
      find.byKey(const Key('tenantAdminOccurrenceProgrammingItem_0')),
      findsOneWidget,
    );
    expect(find.text('Primeira atividade'), findsOneWidget);

    await _addOccurrenceProgrammingTitleOnly(
      tester,
      time: '11:00',
      title: 'Segunda atividade',
    );

    expect(
      find.byKey(const Key('tenantAdminOccurrenceProgrammingItem_0')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('tenantAdminOccurrenceProgrammingItem_1')),
      findsOneWidget,
    );
    expect(find.text('Primeira atividade'), findsOneWidget);
    expect(find.text('Segunda atividade'), findsOneWidget);

    await _closeOccurrenceSheet(tester);

    final occurrence =
        controller.eventFormStateStreamValue.value.occurrences[1];
    expect(
      occurrence.programmingItems.map((item) => item.title),
      ['Primeira atividade', 'Segunda atividade'],
    );
  });

  testWidgets(
      'multi-occurrence editor accumulates programming items that add occurrence profiles',
      (tester) async {
    final eventsRepository = _MultipleRelatedCandidatesEventsRepository();
    final taxonomiesRepository = _FakeTaxonomiesRepository();
    final controller = TenantAdminEventsController(
      eventsRepository: eventsRepository,
      taxonomiesRepository: taxonomiesRepository,
    );

    eventsRepository.eventTypes = [
      TenantAdminEventType(
        idValue: tenantAdminOptionalText('507f1f77bcf86cd799439190'),
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
    await _closeOccurrenceSheet(tester);

    await tester.ensureVisible(
      find.byKey(const Key('tenantAdminEventOccurrenceCard_1')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('tenantAdminEventOccurrenceCard_1')));
    await tester.pumpAndSettle();

    await _addOccurrenceProgrammingWithNewProfile(
      tester,
      time: '10:00',
      profileName: 'Artist A',
    );
    expect(
      find.byKey(const Key('tenantAdminOccurrenceProgrammingItem_0')),
      findsOneWidget,
    );
    expect(find.text('Artist A'), findsWidgets);

    await _addOccurrenceProgrammingWithNewProfile(
      tester,
      time: '11:00',
      profileName: 'Artist B',
    );

    expect(
      find.byKey(const Key('tenantAdminOccurrenceProgrammingItem_0')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('tenantAdminOccurrenceProgrammingItem_1')),
      findsOneWidget,
    );
    expect(find.text('Artist A'), findsWidgets);
    expect(find.text('Artist B'), findsWidgets);

    await _closeOccurrenceSheet(tester);

    final occurrence =
        controller.eventFormStateStreamValue.value.occurrences[1];
    expect(
      occurrence.programmingItems.map((item) => item.time),
      ['10:00', '11:00'],
    );
    expect(
      occurrence.relatedAccountProfileIds.map((item) => item.value),
      containsAll(['artist-1', 'artist-2']),
    );
  });

  testWidgets(
      'update multi-occurrence editor accumulates programming items without occurrence save boundary',
      (tester) async {
    final eventsRepository = _MultipleRelatedCandidatesEventsRepository();
    final taxonomiesRepository = _FakeTaxonomiesRepository();
    final controller = TenantAdminEventsController(
      eventsRepository: eventsRepository,
      taxonomiesRepository: taxonomiesRepository,
    );

    final eventType = TenantAdminEventType(
      idValue: tenantAdminOptionalText('507f1f77bcf86cd799439192'),
      nameValue: tenantAdminRequiredText('Feira'),
      slugValue: tenantAdminRequiredText('feira'),
    );
    eventsRepository.eventTypes = [eventType];

    final existingEvent = TenantAdminEvent(
      eventIdValue: tenantAdminRequiredText('evt-existing-programming'),
      slugValue: tenantAdminRequiredText('event-existing-programming'),
      titleValue: tenantAdminRequiredText('Evento existente'),
      contentValue: tenantAdminOptionalText('Conteúdo'),
      type: eventType,
      occurrences: <TenantAdminEventOccurrence>[
        TenantAdminEventOccurrence(
          occurrenceIdValue: tenantAdminOptionalText('occ-1'),
          occurrenceSlugValue: tenantAdminOptionalText('occ-1'),
          dateTimeStartValue: tenantAdminDateTime(
            DateTime.utc(2026, 4, 20, 20),
          ),
        ),
        TenantAdminEventOccurrence(
          occurrenceIdValue: tenantAdminOptionalText('occ-2'),
          occurrenceSlugValue: tenantAdminOptionalText('occ-2'),
          dateTimeStartValue: tenantAdminDateTime(
            DateTime.utc(2026, 4, 21, 20),
          ),
        ),
      ],
      publication: TenantAdminEventPublication(
        statusValue: tenantAdminRequiredText('draft'),
      ),
      location: TenantAdminEventLocation(
        modeValue: tenantAdminRequiredText('physical'),
      ),
      placeRef: TenantAdminEventPlaceRef(
        typeValue: tenantAdminRequiredText('account_profile'),
        idValue: tenantAdminRequiredText('venue-1'),
      ),
    );

    GetIt.I.registerSingleton<TenantAdminEventsController>(controller);

    await _pumpWithAutoRoute(
      tester,
      Scaffold(
        body: TenantAdminEventFormScreen(existingEvent: existingEvent),
      ),
    );

    await tester.ensureVisible(
      find.byKey(const Key('tenantAdminEventOccurrenceCard_1')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('tenantAdminEventOccurrenceCard_1')));
    await tester.pumpAndSettle();

    await _addOccurrenceProgrammingWithNewProfile(
      tester,
      time: '10:00',
      profileName: 'Artist A',
    );
    expect(find.text('Artist A'), findsWidgets);
    expect(
      find.byKey(const Key('tenantAdminOccurrenceProgrammingItem_0')),
      findsOneWidget,
    );

    await _addOccurrenceProgrammingWithNewProfile(
      tester,
      time: '11:00',
      profileName: 'Artist B',
    );

    expect(find.text('Artist A'), findsWidgets);
    expect(find.text('Artist B'), findsWidgets);
    expect(
      find.byKey(const Key('tenantAdminOccurrenceProgrammingItem_0')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('tenantAdminOccurrenceProgrammingItem_1')),
      findsOneWidget,
    );
  });

  testWidgets(
      'update multi-occurrence editor preserves programming items after closing and reopening date',
      (tester) async {
    final eventsRepository = _MultipleRelatedCandidatesEventsRepository();
    final taxonomiesRepository = _FakeTaxonomiesRepository();
    final controller = TenantAdminEventsController(
      eventsRepository: eventsRepository,
      taxonomiesRepository: taxonomiesRepository,
    );

    final eventType = TenantAdminEventType(
      idValue: tenantAdminOptionalText('507f1f77bcf86cd799439193'),
      nameValue: tenantAdminRequiredText('Feira'),
      slugValue: tenantAdminRequiredText('feira'),
    );
    eventsRepository.eventTypes = [eventType];

    final existingEvent = TenantAdminEvent(
      eventIdValue: tenantAdminRequiredText('evt-existing-programming-reopen'),
      slugValue: tenantAdminRequiredText('event-existing-programming-reopen'),
      titleValue: tenantAdminRequiredText('Evento existente'),
      contentValue: tenantAdminOptionalText('Conteúdo'),
      type: eventType,
      occurrences: <TenantAdminEventOccurrence>[
        TenantAdminEventOccurrence(
          occurrenceIdValue: tenantAdminOptionalText('occ-1'),
          occurrenceSlugValue: tenantAdminOptionalText('occ-1'),
          dateTimeStartValue: tenantAdminDateTime(
            DateTime.utc(2026, 4, 20, 20),
          ),
        ),
        TenantAdminEventOccurrence(
          occurrenceIdValue: tenantAdminOptionalText('occ-2'),
          occurrenceSlugValue: tenantAdminOptionalText('occ-2'),
          dateTimeStartValue: tenantAdminDateTime(
            DateTime.utc(2026, 4, 21, 20),
          ),
        ),
      ],
      publication: TenantAdminEventPublication(
        statusValue: tenantAdminRequiredText('draft'),
      ),
      location: TenantAdminEventLocation(
        modeValue: tenantAdminRequiredText('physical'),
      ),
      placeRef: TenantAdminEventPlaceRef(
        typeValue: tenantAdminRequiredText('account_profile'),
        idValue: tenantAdminRequiredText('venue-1'),
      ),
    );

    GetIt.I.registerSingleton<TenantAdminEventsController>(controller);

    await _pumpWithAutoRoute(
      tester,
      Scaffold(
        body: TenantAdminEventFormScreen(existingEvent: existingEvent),
      ),
    );

    await tester.ensureVisible(
      find.byKey(const Key('tenantAdminEventOccurrenceCard_1')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('tenantAdminEventOccurrenceCard_1')));
    await tester.pumpAndSettle();
    await _addOccurrenceProgrammingWithNewProfile(
      tester,
      time: '10:00',
      profileName: 'Artist A',
    );
    await _closeOccurrenceSheet(tester);

    expect(
      controller.eventFormStateStreamValue.value.occurrences[1].programmingItems
          .map((item) => item.time),
      ['10:00'],
    );

    await tester.ensureVisible(
      find.byKey(const Key('tenantAdminEventOccurrenceCard_1')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('tenantAdminEventOccurrenceCard_1')));
    await tester.pumpAndSettle();
    await _addOccurrenceProgrammingWithNewProfile(
      tester,
      time: '11:00',
      profileName: 'Artist B',
    );

    expect(find.text('Artist A'), findsWidgets);
    expect(find.text('Artist B'), findsWidgets);
    expect(
      find.byKey(const Key('tenantAdminOccurrenceProgrammingItem_0')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('tenantAdminOccurrenceProgrammingItem_1')),
      findsOneWidget,
    );

    await _closeOccurrenceSheet(tester);

    expect(
      controller.eventFormStateStreamValue.value.occurrences[1].programmingItems
          .map((item) => item.time),
      ['10:00', '11:00'],
    );
  });

  testWidgets(
      'update event with three occurrences preserves programming items on the third date',
      (tester) async {
    final eventsRepository = _MultipleRelatedCandidatesEventsRepository();
    final taxonomiesRepository = _FakeTaxonomiesRepository();
    final controller = TenantAdminEventsController(
      eventsRepository: eventsRepository,
      taxonomiesRepository: taxonomiesRepository,
    );

    final eventType = TenantAdminEventType(
      idValue: tenantAdminOptionalText('507f1f77bcf86cd799439194'),
      nameValue: tenantAdminRequiredText('Feira'),
      slugValue: tenantAdminRequiredText('feira'),
    );
    eventsRepository.eventTypes = [eventType];

    final existingEvent = TenantAdminEvent(
      eventIdValue: tenantAdminRequiredText('evt-existing-programming-three'),
      slugValue: tenantAdminRequiredText('event-existing-programming-three'),
      titleValue: tenantAdminRequiredText('Evento existente'),
      contentValue: tenantAdminOptionalText('Conteúdo'),
      type: eventType,
      occurrences: <TenantAdminEventOccurrence>[
        TenantAdminEventOccurrence(
          occurrenceIdValue: tenantAdminOptionalText('occ-1'),
          occurrenceSlugValue: tenantAdminOptionalText('occ-1'),
          dateTimeStartValue: tenantAdminDateTime(
            DateTime.utc(2026, 4, 20, 20),
          ),
        ),
        TenantAdminEventOccurrence(
          occurrenceIdValue: tenantAdminOptionalText('occ-2'),
          occurrenceSlugValue: tenantAdminOptionalText('occ-2'),
          dateTimeStartValue: tenantAdminDateTime(
            DateTime.utc(2026, 4, 21, 20),
          ),
        ),
        TenantAdminEventOccurrence(
          occurrenceIdValue: tenantAdminOptionalText('occ-3'),
          occurrenceSlugValue: tenantAdminOptionalText('occ-3'),
          dateTimeStartValue: tenantAdminDateTime(
            DateTime.utc(2026, 4, 22, 20),
          ),
        ),
      ],
      publication: TenantAdminEventPublication(
        statusValue: tenantAdminRequiredText('draft'),
      ),
      location: TenantAdminEventLocation(
        modeValue: tenantAdminRequiredText('physical'),
      ),
      placeRef: TenantAdminEventPlaceRef(
        typeValue: tenantAdminRequiredText('account_profile'),
        idValue: tenantAdminRequiredText('venue-1'),
      ),
    );

    GetIt.I.registerSingleton<TenantAdminEventsController>(controller);

    await _pumpWithAutoRoute(
      tester,
      Scaffold(
        body: TenantAdminEventFormScreen(existingEvent: existingEvent),
      ),
    );

    await tester.ensureVisible(
      find.byKey(const Key('tenantAdminEventOccurrenceCard_2')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('tenantAdminEventOccurrenceCard_2')));
    await tester.pumpAndSettle();

    await _addOccurrenceProgrammingWithNewProfile(
      tester,
      time: '10:00',
      profileName: 'Artist A',
    );
    await _addOccurrenceProgrammingWithNewProfile(
      tester,
      time: '11:00',
      profileName: 'Artist B',
    );

    expect(find.text('Artist A'), findsWidgets);
    expect(find.text('Artist B'), findsWidgets);
    expect(
      find.byKey(const Key('tenantAdminOccurrenceProgrammingItem_0')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('tenantAdminOccurrenceProgrammingItem_1')),
      findsOneWidget,
    );

    await _closeOccurrenceSheet(tester);

    expect(
      controller
          .eventFormStateStreamValue.value.occurrences[0].programmingItems,
      isEmpty,
    );
    expect(
      controller
          .eventFormStateStreamValue.value.occurrences[1].programmingItems,
      isEmpty,
    );
    expect(
      controller.eventFormStateStreamValue.value.occurrences[2].programmingItems
          .map((item) => item.time),
      ['10:00', '11:00'],
    );
  });

  testWidgets(
      'update event with three occurrences preserves programming items when reusing an occurrence profile',
      (tester) async {
    final eventsRepository = _MultipleRelatedCandidatesEventsRepository();
    final taxonomiesRepository = _FakeTaxonomiesRepository();
    final controller = TenantAdminEventsController(
      eventsRepository: eventsRepository,
      taxonomiesRepository: taxonomiesRepository,
    );

    final eventType = TenantAdminEventType(
      idValue: tenantAdminOptionalText('507f1f77bcf86cd799439195'),
      nameValue: tenantAdminRequiredText('Feira'),
      slugValue: tenantAdminRequiredText('feira'),
    );
    eventsRepository.eventTypes = [eventType];

    final existingEvent = TenantAdminEvent(
      eventIdValue: tenantAdminRequiredText('evt-existing-programming-reuse'),
      slugValue: tenantAdminRequiredText('event-existing-programming-reuse'),
      titleValue: tenantAdminRequiredText('Evento existente'),
      contentValue: tenantAdminOptionalText('Conteúdo'),
      type: eventType,
      occurrences: <TenantAdminEventOccurrence>[
        TenantAdminEventOccurrence(
          occurrenceIdValue: tenantAdminOptionalText('occ-1'),
          occurrenceSlugValue: tenantAdminOptionalText('occ-1'),
          dateTimeStartValue: tenantAdminDateTime(
            DateTime.utc(2026, 4, 20, 20),
          ),
        ),
        TenantAdminEventOccurrence(
          occurrenceIdValue: tenantAdminOptionalText('occ-2'),
          occurrenceSlugValue: tenantAdminOptionalText('occ-2'),
          dateTimeStartValue: tenantAdminDateTime(
            DateTime.utc(2026, 4, 21, 20),
          ),
        ),
        TenantAdminEventOccurrence(
          occurrenceIdValue: tenantAdminOptionalText('occ-3'),
          occurrenceSlugValue: tenantAdminOptionalText('occ-3'),
          dateTimeStartValue: tenantAdminDateTime(
            DateTime.utc(2026, 4, 22, 20),
          ),
        ),
      ],
      publication: TenantAdminEventPublication(
        statusValue: tenantAdminRequiredText('draft'),
      ),
      location: TenantAdminEventLocation(
        modeValue: tenantAdminRequiredText('physical'),
      ),
      placeRef: TenantAdminEventPlaceRef(
        typeValue: tenantAdminRequiredText('account_profile'),
        idValue: tenantAdminRequiredText('venue-1'),
      ),
    );

    GetIt.I.registerSingleton<TenantAdminEventsController>(controller);

    await _pumpWithAutoRoute(
      tester,
      Scaffold(
        body: TenantAdminEventFormScreen(existingEvent: existingEvent),
      ),
    );

    await tester.ensureVisible(
      find.byKey(const Key('tenantAdminEventOccurrenceCard_2')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('tenantAdminEventOccurrenceCard_2')));
    await tester.pumpAndSettle();

    await _addOccurrenceProgrammingWithNewProfile(
      tester,
      time: '10:00',
      profileName: 'Artist A',
    );
    await _addOccurrenceProgrammingWithExistingProfile(
      tester,
      time: '11:00',
      profileName: 'Artist A',
    );

    expect(find.text('Artist A'), findsWidgets);
    expect(
      find.byKey(const Key('tenantAdminOccurrenceProgrammingItem_0')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('tenantAdminOccurrenceProgrammingItem_1')),
      findsOneWidget,
    );

    await _closeOccurrenceSheet(tester);

    final occurrence =
        controller.eventFormStateStreamValue.value.occurrences[2];
    expect(
      occurrence.relatedAccountProfileIds.map((item) => item.value),
      ['artist-1'],
    );
    expect(
      occurrence.programmingItems.map((item) => item.time),
      ['10:00', '11:00'],
    );
    expect(
      occurrence.programmingItems
          .expand((item) => item.accountProfileIds)
          .map((item) => item.value),
      ['artist-1', 'artist-1'],
    );
  });

  testWidgets(
      'update event occurrence sheet keeps unsaved programming item after dragging modal',
      (tester) async {
    final eventsRepository = _MultipleRelatedCandidatesEventsRepository();
    final taxonomiesRepository = _FakeTaxonomiesRepository();
    final controller = TenantAdminEventsController(
      eventsRepository: eventsRepository,
      taxonomiesRepository: taxonomiesRepository,
    );

    final eventType = TenantAdminEventType(
      idValue: tenantAdminOptionalText('507f1f77bcf86cd799439196'),
      nameValue: tenantAdminRequiredText('Feira'),
      slugValue: tenantAdminRequiredText('feira'),
    );
    eventsRepository.eventTypes = [eventType];

    final existingEvent = TenantAdminEvent(
      eventIdValue: tenantAdminRequiredText('evt-existing-programming-drag'),
      slugValue: tenantAdminRequiredText('event-existing-programming-drag'),
      titleValue: tenantAdminRequiredText('Evento existente'),
      contentValue: tenantAdminOptionalText('Conteúdo'),
      type: eventType,
      occurrences: <TenantAdminEventOccurrence>[
        TenantAdminEventOccurrence(
          occurrenceIdValue: tenantAdminOptionalText('occ-1'),
          occurrenceSlugValue: tenantAdminOptionalText('occ-1'),
          dateTimeStartValue: tenantAdminDateTime(
            DateTime.utc(2026, 4, 20, 20),
          ),
        ),
        TenantAdminEventOccurrence(
          occurrenceIdValue: tenantAdminOptionalText('occ-2'),
          occurrenceSlugValue: tenantAdminOptionalText('occ-2'),
          dateTimeStartValue: tenantAdminDateTime(
            DateTime.utc(2026, 4, 21, 20),
          ),
        ),
        TenantAdminEventOccurrence(
          occurrenceIdValue: tenantAdminOptionalText('occ-3'),
          occurrenceSlugValue: tenantAdminOptionalText('occ-3'),
          dateTimeStartValue: tenantAdminDateTime(
            DateTime.utc(2026, 4, 22, 20),
          ),
        ),
      ],
      publication: TenantAdminEventPublication(
        statusValue: tenantAdminRequiredText('draft'),
      ),
      location: TenantAdminEventLocation(
        modeValue: tenantAdminRequiredText('physical'),
      ),
      placeRef: TenantAdminEventPlaceRef(
        typeValue: tenantAdminRequiredText('account_profile'),
        idValue: tenantAdminRequiredText('venue-1'),
      ),
    );

    GetIt.I.registerSingleton<TenantAdminEventsController>(controller);

    await _pumpWithAutoRoute(
      tester,
      Scaffold(
        body: TenantAdminEventFormScreen(existingEvent: existingEvent),
      ),
    );

    await tester.ensureVisible(
      find.byKey(const Key('tenantAdminEventOccurrenceCard_2')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('tenantAdminEventOccurrenceCard_2')));
    await tester.pumpAndSettle();

    await _addOccurrenceProgrammingWithNewProfile(
      tester,
      time: '10:00',
      profileName: 'Artist A',
    );

    expect(find.text('Artist A'), findsWidgets);
    expect(
      find.byKey(const Key('tenantAdminOccurrenceProgrammingItem_0')),
      findsOneWidget,
    );

    await tester.drag(find.byType(BottomSheet).last, const Offset(0, 32));
    await tester.pumpAndSettle();

    expect(find.text('Artist A'), findsWidgets);
    expect(
      find.byKey(const Key('tenantAdminOccurrenceProgrammingItem_0')),
      findsOneWidget,
    );
  });

  testWidgets(
      'update event programming item sheet keeps unsaved linked profile after dragging modal',
      (tester) async {
    final eventsRepository = _MultipleRelatedCandidatesEventsRepository();
    final taxonomiesRepository = _FakeTaxonomiesRepository();
    final controller = TenantAdminEventsController(
      eventsRepository: eventsRepository,
      taxonomiesRepository: taxonomiesRepository,
    );

    final eventType = TenantAdminEventType(
      idValue: tenantAdminOptionalText('507f1f77bcf86cd799439197'),
      nameValue: tenantAdminRequiredText('Feira'),
      slugValue: tenantAdminRequiredText('feira'),
    );
    eventsRepository.eventTypes = [eventType];

    final existingEvent = TenantAdminEvent(
      eventIdValue:
          tenantAdminRequiredText('evt-existing-programming-drag-item'),
      slugValue:
          tenantAdminRequiredText('event-existing-programming-drag-item'),
      titleValue: tenantAdminRequiredText('Evento existente'),
      contentValue: tenantAdminOptionalText('Conteúdo'),
      type: eventType,
      occurrences: <TenantAdminEventOccurrence>[
        TenantAdminEventOccurrence(
          occurrenceIdValue: tenantAdminOptionalText('occ-1'),
          occurrenceSlugValue: tenantAdminOptionalText('occ-1'),
          dateTimeStartValue: tenantAdminDateTime(
            DateTime.utc(2026, 4, 20, 20),
          ),
        ),
        TenantAdminEventOccurrence(
          occurrenceIdValue: tenantAdminOptionalText('occ-2'),
          occurrenceSlugValue: tenantAdminOptionalText('occ-2'),
          dateTimeStartValue: tenantAdminDateTime(
            DateTime.utc(2026, 4, 21, 20),
          ),
        ),
        TenantAdminEventOccurrence(
          occurrenceIdValue: tenantAdminOptionalText('occ-3'),
          occurrenceSlugValue: tenantAdminOptionalText('occ-3'),
          dateTimeStartValue: tenantAdminDateTime(
            DateTime.utc(2026, 4, 22, 20),
          ),
        ),
      ],
      publication: TenantAdminEventPublication(
        statusValue: tenantAdminRequiredText('draft'),
      ),
      location: TenantAdminEventLocation(
        modeValue: tenantAdminRequiredText('physical'),
      ),
      placeRef: TenantAdminEventPlaceRef(
        typeValue: tenantAdminRequiredText('account_profile'),
        idValue: tenantAdminRequiredText('venue-1'),
      ),
    );

    GetIt.I.registerSingleton<TenantAdminEventsController>(controller);

    await _pumpWithAutoRoute(
      tester,
      Scaffold(
        body: TenantAdminEventFormScreen(existingEvent: existingEvent),
      ),
    );

    await tester.ensureVisible(
      find.byKey(const Key('tenantAdminEventOccurrenceCard_2')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('tenantAdminEventOccurrenceCard_2')));
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
      '10:00',
    );
    await tester.tap(
      find.byKey(
        const Key('tenantAdminProgrammingAddOccurrenceProfileButton'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Artist A').last);
    await tester.pumpAndSettle();

    expect(find.text('Artist A'), findsWidgets);
    expect(
      find.byKey(const Key('tenantAdminProgrammingProfile_artist-1')),
      findsOneWidget,
    );

    await tester.drag(find.byType(BottomSheet).last, const Offset(0, 32));
    await tester.pumpAndSettle();

    expect(find.text('Artist A'), findsWidgets);
    expect(
      find.byKey(const Key('tenantAdminProgrammingProfile_artist-1')),
      findsOneWidget,
    );
  });

  testWidgets(
      'update event occurrence sheet keeps unsaved programming item after layout metrics change',
      (tester) async {
    final eventsRepository = _MultipleRelatedCandidatesEventsRepository();
    final taxonomiesRepository = _FakeTaxonomiesRepository();
    final controller = TenantAdminEventsController(
      eventsRepository: eventsRepository,
      taxonomiesRepository: taxonomiesRepository,
    );

    final eventType = TenantAdminEventType(
      idValue: tenantAdminOptionalText('507f1f77bcf86cd799439198'),
      nameValue: tenantAdminRequiredText('Feira'),
      slugValue: tenantAdminRequiredText('feira'),
    );
    eventsRepository.eventTypes = [eventType];

    final existingEvent = TenantAdminEvent(
      eventIdValue: tenantAdminRequiredText('evt-existing-programming-dismiss'),
      slugValue: tenantAdminRequiredText('event-existing-programming-dismiss'),
      titleValue: tenantAdminRequiredText('Evento existente'),
      contentValue: tenantAdminOptionalText('Conteúdo'),
      type: eventType,
      occurrences: <TenantAdminEventOccurrence>[
        TenantAdminEventOccurrence(
          occurrenceIdValue: tenantAdminOptionalText('occ-1'),
          occurrenceSlugValue: tenantAdminOptionalText('occ-1'),
          dateTimeStartValue: tenantAdminDateTime(
            DateTime.utc(2026, 4, 20, 20),
          ),
        ),
        TenantAdminEventOccurrence(
          occurrenceIdValue: tenantAdminOptionalText('occ-2'),
          occurrenceSlugValue: tenantAdminOptionalText('occ-2'),
          dateTimeStartValue: tenantAdminDateTime(
            DateTime.utc(2026, 4, 21, 20),
          ),
        ),
        TenantAdminEventOccurrence(
          occurrenceIdValue: tenantAdminOptionalText('occ-3'),
          occurrenceSlugValue: tenantAdminOptionalText('occ-3'),
          dateTimeStartValue: tenantAdminDateTime(
            DateTime.utc(2026, 4, 22, 20),
          ),
        ),
      ],
      publication: TenantAdminEventPublication(
        statusValue: tenantAdminRequiredText('draft'),
      ),
      location: TenantAdminEventLocation(
        modeValue: tenantAdminRequiredText('physical'),
      ),
      placeRef: TenantAdminEventPlaceRef(
        typeValue: tenantAdminRequiredText('account_profile'),
        idValue: tenantAdminRequiredText('venue-1'),
      ),
    );

    GetIt.I.registerSingleton<TenantAdminEventsController>(controller);

    await _pumpWithAutoRoute(
      tester,
      Scaffold(
        body: TenantAdminEventFormScreen(existingEvent: existingEvent),
      ),
    );

    await tester.ensureVisible(
      find.byKey(const Key('tenantAdminEventOccurrenceCard_2')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('tenantAdminEventOccurrenceCard_2')));
    await tester.pumpAndSettle();

    await _addOccurrenceProgrammingWithNewProfile(
      tester,
      time: '10:00',
      profileName: 'Artist A',
    );

    expect(find.text('Artist A'), findsWidgets);
    expect(
      find.byKey(const Key('tenantAdminOccurrenceProgrammingItem_0')),
      findsOneWidget,
    );

    tester.view.physicalSize = const Size(1000, 760);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpAndSettle();

    expect(find.text('Artist A'), findsWidgets);
    expect(
      find.byKey(const Key('tenantAdminOccurrenceProgrammingItem_0')),
      findsOneWidget,
    );
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

  testWidgets('physical mode venue picker filters venues by search',
      (tester) async {
    final eventsRepository = _FakeEventsRepository()
      ..physicalHostCandidates = [
        tenantAdminAccountProfileFromRaw(
          id: 'venue-1',
          accountId: 'acc-venue-1',
          profileType: 'venue',
          displayName: 'Venue A',
          location: tenantAdminLocationFromRaw(
            latitude: -20.611121,
            longitude: -40.498617,
          ),
        ),
        tenantAdminAccountProfileFromRaw(
          id: 'venue-2',
          accountId: 'acc-venue-2',
          profileType: 'venue',
          displayName: 'Casa do Jazz',
          location: tenantAdminLocationFromRaw(
            latitude: -20.612121,
            longitude: -40.498917,
          ),
        ),
        tenantAdminAccountProfileFromRaw(
          id: 'venue-3',
          accountId: 'acc-venue-3',
          profileType: 'venue',
          displayName: 'Arena do Sol',
          location: tenantAdminLocationFromRaw(
            latitude: -20.612521,
            longitude: -40.499217,
          ),
        ),
      ];
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
      find.text('Online'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Online').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Physical').last);
    await tester.pumpAndSettle();

    await tester.ensureVisible(
      find.byKey(const Key('tenantAdminEventLocationProfileDropdown')),
    );
    await tester.tap(
      find.byKey(const Key('tenantAdminEventLocationProfileDropdown')),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('tenantAdminEventLocationSearchField')),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel('Venue A'), findsWidgets);
    expect(find.bySemanticsLabel('Casa do Jazz'), findsWidgets);
    expect(find.bySemanticsLabel('Arena do Sol'), findsWidgets);

    await tester.enterText(
      find.byKey(const Key('tenantAdminEventLocationSearchField')),
      'Jazz',
    );
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('Casa do Jazz'), findsWidgets);
    expect(find.bySemanticsLabel('Venue A'), findsNothing);
    expect(find.bySemanticsLabel('Arena do Sol'), findsNothing);

    await tester.tap(
      find.byKey(const Key('tenantAdminEventLocationOption_venue-2')),
    );
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
    expect(draft!.location?.mode, 'physical');
    expect(draft.location?.latitude, -20.612121);
    expect(draft.location?.longitude, -40.498917);
    expect(draft.location?.online, isNull);
    expect(draft.placeRef?.id, 'venue-2');
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
    expect(
      find.text('Limite: 100 KB por campo. O backend valida o envio final.'),
      findsOneWidget,
    );
    expect(find.textContaining('/ 100 KB'), findsOneWidget);
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

Future<void> _closeOccurrenceSheet(WidgetTester tester) async {
  final closeButton = find.byKey(const Key('tenantAdminOccurrenceCloseButton'));
  await tester.ensureVisible(closeButton);
  await tester.pumpAndSettle();
  await tester.tap(closeButton);
  await tester.pumpAndSettle();
}

Future<void> _tapProgrammingSaveButton(WidgetTester tester) async {
  final saveButton = find.byKey(const Key('tenantAdminProgrammingSaveButton'));
  await tester.ensureVisible(saveButton);
  await tester.pumpAndSettle();
  await tester.tap(saveButton);
  await tester.pumpAndSettle();
}

Future<void> _addOccurrenceProgrammingTitleOnly(
  WidgetTester tester, {
  required String time,
  required String title,
}) async {
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
    time,
  );
  await tester.enterText(
    find.byKey(const Key('tenantAdminProgrammingTitleField')),
    title,
  );
  await _tapProgrammingSaveButton(tester);
}

Future<void> _addOccurrenceProgrammingWithNewProfile(
  WidgetTester tester, {
  required String time,
  required String profileName,
}) async {
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
    time,
  );
  await tester.tap(
    find.byKey(
      const Key('tenantAdminProgrammingAddOccurrenceProfileButton'),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text(profileName).last);
  await tester.pumpAndSettle();
  await _tapProgrammingSaveButton(tester);
}

Future<void> _addOccurrenceProgrammingWithExistingProfile(
  WidgetTester tester, {
  required String time,
  required String profileName,
}) async {
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
    time,
  );
  await tester.tap(
    find.byKey(
      const Key('tenantAdminProgrammingLinkOccurrenceProfileButton'),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text(profileName).last);
  await tester.pumpAndSettle();
  await _tapProgrammingSaveButton(tester);
}

TenantAdminTaxonomyTerms _tenantAdminTaxonomyTerms(
  Iterable<TenantAdminTaxonomyTerm> items,
) {
  final terms = TenantAdminTaxonomyTerms();
  for (final item in items) {
    terms.add(item);
  }
  return terms;
}

class _FakeEventsRepository extends TenantAdminEventsRepositoryContract
    with TenantAdminEventsPaginationMixin {
  List<TenantAdminEventType> eventTypes = <TenantAdminEventType>[];
  List<TenantAdminAccountProfile> physicalHostCandidates =
      <TenantAdminAccountProfile>[
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
  ];
  List<TenantAdminAccountProfile> relatedAccountProfileCandidates =
      <TenantAdminAccountProfile>[
    tenantAdminAccountProfileFromRaw(
      id: 'artist-1',
      accountId: 'acc-artist',
      profileType: 'artist',
      displayName: 'Artist A',
    ),
  ];
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
      TenantAdminEventAccountProfileCandidateType.physicalHost =>
        physicalHostCandidates,
      TenantAdminEventAccountProfileCandidateType.relatedAccountProfile =>
        relatedAccountProfileCandidates,
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

String _fixtureTaxonomySlug(int index) => 'fixture_taxonomy_$index';

String _fixtureTermSlug(int index) => 'fixture_term_$index';

String _fixtureTaxonomyLabel(int index) => 'Fixture Taxonomy $index';

String _fixtureTermLabel(int index) => 'Fixture Term $index';

String _encodedAdminTaxonomyTerm(String taxonomySlug, String termSlug) {
  return '$taxonomySlug:$termSlug';
}

Key _occurrenceTaxonomyChipKey(String taxonomySlug, String termSlug) {
  return Key('tenantAdminOccurrenceTaxonomy_${taxonomySlug}_$termSlug');
}

class _FakeTaxonomiesRepository
    with TenantAdminTaxonomiesPaginationMixin
    implements
        TenantAdminTaxonomiesRepositoryContract,
        TenantAdminTaxonomiesBatchTermsRepositoryContract {
  int fetchTermsCalls = 0;
  final List<List<String>> batchFetchTaxonomyIds = <List<String>>[];

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
        slug: _fixtureTaxonomySlug(1),
        name: _fixtureTaxonomyLabel(1),
        appliesTo: ['event'],
        icon: null,
        color: null,
      ),
      tenantAdminTaxonomyDefinitionFromRaw(
        id: 'tax-2',
        slug: _fixtureTaxonomySlug(2),
        name: _fixtureTaxonomyLabel(2),
        appliesTo: ['event'],
        icon: null,
        color: null,
      ),
      tenantAdminTaxonomyDefinitionFromRaw(
        id: 'tax-empty',
        slug: _fixtureTaxonomySlug(3),
        name: _fixtureTaxonomyLabel(3),
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
    fetchTermsCalls += 1;
    return _termsForTaxonomyId(taxonomyId.value);
  }

  @override
  Future<TenantAdminTaxonomyTermsByTaxonomyId> fetchTermsByTaxonomyIds({
    required List<TenantAdminTaxRepoString> taxonomyIds,
    TenantAdminTaxRepoInt? termLimit,
  }) async {
    final ids = taxonomyIds
        .map((taxonomyId) => taxonomyId.value)
        .toList(growable: false);
    batchFetchTaxonomyIds.add(ids);
    return TenantAdminTaxonomyTermsByTaxonomyId(
      entries: ids
          .map(
            (taxonomyId) => TenantAdminTaxonomyTermsForTaxonomyId(
              taxonomyIdValue: tenantAdminRequiredText(taxonomyId),
              terms: _termsForTaxonomyId(taxonomyId),
            ),
          )
          .toList(growable: false),
    );
  }

  List<TenantAdminTaxonomyTermDefinition> _termsForTaxonomyId(
    String taxonomyId,
  ) {
    if (taxonomyId == 'tax-empty') {
      return const <TenantAdminTaxonomyTermDefinition>[];
    }
    if (taxonomyId == 'tax-2') {
      return [
        tenantAdminTaxonomyTermDefinitionFromRaw(
          id: 'term-2',
          taxonomyId: 'tax-2',
          slug: _fixtureTermSlug(2),
          name: _fixtureTermLabel(2),
        ),
      ];
    }
    return [
      tenantAdminTaxonomyTermDefinitionFromRaw(
        id: 'term-1',
        taxonomyId: 'tax-1',
        slug: _fixtureTermSlug(1),
        name: _fixtureTermLabel(1),
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

class _MultipleRelatedCandidatesEventsRepository extends _FakeEventsRepository {
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
    return tenantAdminPagedResultFromRaw(
      items: [
        tenantAdminAccountProfileFromRaw(
          id: 'artist-1',
          accountId: 'acc-artist-1',
          profileType: 'artist',
          displayName: 'Artist A',
        ),
        tenantAdminAccountProfileFromRaw(
          id: 'artist-2',
          accountId: 'acc-artist-2',
          profileType: 'artist',
          displayName: 'Artist B',
        ),
      ],
      hasMore: false,
    );
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
