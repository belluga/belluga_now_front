import 'package:auto_route/auto_route.dart';
import 'package:belluga_form_validation/belluga_form_validation.dart';
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
import 'package:belluga_now/domain/tenant_admin/tenant_admin_nested_profile_group.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_paged_result.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_definition.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_term.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_term_definition.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_terms.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_terms_by_taxonomy_id.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_account_profile_id_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_count_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_value_parsers.dart';
import 'package:belluga_now/presentation/tenant_admin/events/controllers/tenant_admin_event_occurrence_editor_draft.dart';
import 'package:belluga_now/presentation/tenant_admin/events/controllers/tenant_admin_events_controller.dart';
import 'package:belluga_now/presentation/tenant_admin/events/models/tenant_admin_event_form_validation_config.dart';
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
        allowedTaxonomiesValue: tenantAdminTrimmedStringList([
          _fixtureTaxonomySlug(1),
        ]),
      ),
    ];

    GetIt.I.registerSingleton<TenantAdminEventsController>(controller);

    await _pumpWithAutoRoute(
      tester,
      const Scaffold(body: TenantAdminEventFormScreen()),
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
        allowedTaxonomiesValue: tenantAdminTrimmedStringList([
          _fixtureTaxonomySlug(1),
        ]),
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
        _occurrenceTaxonomyChipKey(
          _fixtureTaxonomySlug(1),
          _fixtureTermSlug(1),
        ),
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
    },
  );

  testWidgets(
    'single occurrence edit hydrates legacy event-level profile groups into occurrence programming',
    (tester) async {
      final eventsRepository = _FakeEventsRepository();
      final taxonomiesRepository = _FakeTaxonomiesRepository();
      final controller = TenantAdminEventsController(
        eventsRepository: eventsRepository,
        taxonomiesRepository: taxonomiesRepository,
      );

      final eventType = TenantAdminEventType(
        idValue: tenantAdminOptionalText('507f1f77bcf86cd799439141'),
        nameValue: tenantAdminRequiredText('Show'),
        slugValue: tenantAdminRequiredText('show'),
      );
      final preservedProfile = tenantAdminAccountProfileFromRaw(
        id: 'artist-zulu',
        accountId: 'acc-artist-zulu',
        profileType: 'artist',
        displayName: 'Zulu Artist',
      );
      final existingEvent = TenantAdminEvent(
        eventIdValue: tenantAdminRequiredText('evt-single-occurrence-profiles'),
        slugValue: tenantAdminRequiredText('evt-single-occurrence-profiles'),
        titleValue: tenantAdminRequiredText('Evento com perfil legado'),
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
        relatedAccountProfiles: [preservedProfile],
        relatedAccountProfileIdValues: [
          TenantAdminAccountProfileIdValue('artist-zulu'),
        ],
        profileGroups: [
          TenantAdminNestedProfileGroup(
            idValue: TenantAdminNestedProfileGroupTextValue('artists'),
            labelValue: TenantAdminNestedProfileGroupTextValue('Artistas'),
            orderValue: TenantAdminNestedProfileGroupOrderValue(0),
            accountProfileIdValues: [
              TenantAdminNestedProfileGroupTextValue('artist-zulu'),
            ],
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

      final linkOccurrenceProfileButton = tester.widget<OutlinedButton>(
        find.byKey(
          const Key('tenantAdminProgrammingLinkOccurrenceProfileButton'),
        ),
      );
      expect(linkOccurrenceProfileButton.onPressed, isNotNull);

      final addOccurrenceProfileButton = tester.widget<OutlinedButton>(
        find.byKey(
          const Key('tenantAdminProgrammingAddOccurrenceProfileButton_artists'),
        ),
      );
      expect(addOccurrenceProfileButton.onPressed, isNotNull);
    },
  );

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
        allowedTaxonomiesValue: tenantAdminTrimmedStringList([
          _fixtureTaxonomySlug(1),
        ]),
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
      expect(submittedTerms, [
        _encodedAdminTaxonomyTerm(_fixtureTaxonomySlug(1), _fixtureTermSlug(1)),
      ]);
      expect(taxonomiesRepository.fetchTermsCalls, 0);
      expect(taxonomiesRepository.batchFetchTaxonomyIds, [
        ['tax-1'],
      ]);
    },
  );

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
          allowedTaxonomiesValue: tenantAdminTrimmedStringList([
            _fixtureTaxonomySlug(1),
          ]),
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
    },
  );

  testWidgets('reloads taxonomy terms in one batch when event type changes', (
    tester,
  ) async {
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
      allowedTaxonomiesValue: tenantAdminTrimmedStringList([
        _fixtureTaxonomySlug(1),
      ]),
    );
    final restauranteType = TenantAdminEventType.withAllowedTaxonomies(
      idValue: tenantAdminOptionalText('507f1f77bcf86cd799439034'),
      nameValue: tenantAdminRequiredText('Restaurante'),
      slugValue: tenantAdminRequiredText('restaurante'),
      allowedTaxonomiesValue: tenantAdminTrimmedStringList([
        _fixtureTaxonomySlug(2),
      ]),
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
      Scaffold(body: TenantAdminEventFormScreen(existingEvent: existingEvent)),
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

  testWidgets('hides taxonomy section when selected event type allows none', (
    tester,
  ) async {
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
      Scaffold(body: TenantAdminEventFormScreen(existingEvent: existingEvent)),
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

  testWidgets('renders empty state when allowed taxonomy has no terms', (
    tester,
  ) async {
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
      allowedTaxonomiesValue: tenantAdminTrimmedStringList([
        _fixtureTaxonomySlug(1),
        _fixtureTaxonomySlug(3),
      ]),
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
      Scaffold(body: TenantAdminEventFormScreen(existingEvent: existingEvent)),
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
      const Scaffold(body: TenantAdminEventFormScreen()),
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

  testWidgets('clears optional end date from the first occurrence form', (
    tester,
  ) async {
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
      const Scaffold(body: TenantAdminEventFormScreen()),
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

  testWidgets('dirty event form asks before closing without saving', (
    tester,
  ) async {
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
      const Scaffold(body: TenantAdminEventFormScreen()),
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

  testWidgets('adds a second occurrence date before create submit', (
    tester,
  ) async {
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
      const Scaffold(body: TenantAdminEventFormScreen()),
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
    await tester.tap(
      find.byKey(const Key('tenantAdminEventAddOccurrenceButton')),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('tenantAdminOccurrenceSaveButton')),
      findsNothing,
    );
    expect(find.text('Salvar data'), findsNothing);
    await _closeOccurrenceSheet(tester);

    expect(
      controller.eventFormStateStreamValue.value.occurrences,
      hasLength(2),
    );
    expect(find.text('Datas'), findsOneWidget);
    expect(
      find.byKey(const Key('tenantAdminEventOccurrenceCard_0')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('tenantAdminEventOccurrenceCard_1')),
      findsOneWidget,
    );

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
      isTrue,
    );
  });

  testWidgets('authors occurrence taxonomy overrides from the date editor', (
    tester,
  ) async {
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
        allowedTaxonomiesValue: tenantAdminTrimmedStringList([
          _fixtureTaxonomySlug(1),
        ]),
      ),
    ];

    GetIt.I.registerSingleton<TenantAdminEventsController>(controller);

    await _pumpWithAutoRoute(
      tester,
      const Scaffold(body: TenantAdminEventFormScreen()),
    );

    await _fillRequiredFields(tester, controller: controller);
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('tenantAdminEventAddOccurrenceButton')),
    );
    await tester.pumpAndSettle();

    final selectedTaxonomyChipKey = _occurrenceTaxonomyChipKey(
      _fixtureTaxonomySlug(1),
      _fixtureTermSlug(1),
    );
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
        .lastCreateDraft
        ?.occurrences[1]
        .taxonomyTerms
        .map((term) => '${term.type}:${term.value}')
        .toList(growable: false);
    expect(occurrenceTerms, [
      _encodedAdminTaxonomyTerm(_fixtureTaxonomySlug(1), _fixtureTermSlug(1)),
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
        const Scaffold(body: TenantAdminEventFormScreen()),
      );

      await _fillRequiredFields(tester, controller: controller);
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const Key('tenantAdminEventAddOccurrenceButton')),
      );
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.byKey(const Key('tenantAdminOccurrenceAddProgrammingButton')),
        250,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(const Key('tenantAdminOccurrenceAddProgrammingButton')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const Key('tenantAdminOccurrenceAddProgrammingButton')),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(const Key('tenantAdminProgrammingTimeField')),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('tenantAdminProgrammingTimeField')),
        '17:00',
      );
      await tester.ensureVisible(
        find.byKey(const Key('tenantAdminProgrammingEndTimeField')),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('tenantAdminProgrammingEndTimeField')),
        '18:30',
      );
      await tester.ensureVisible(
        find.byKey(const Key('tenantAdminProgrammingTitleEditor')),
      );
      await tester.pumpAndSettle();
      await _enterProgrammingTitle(tester, 'Show com encerramento');
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
          .lastCreateDraft
          ?.occurrences[1]
          .programmingItems
          .single;
      expect(programmingItem?.time, '17:00');
      expect(programmingItem?.endTime, '18:30');
      expect(
        programmingItem?.title,
        _programmingTitleContains('Show com encerramento'),
      );
    },
  );

  testWidgets('adds a second occurrence date before edit submit', (
    tester,
  ) async {
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
          dateTimeStartValue: tenantAdminDateTime(DateTime.utc(2026, 3, 5, 20)),
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
      Scaffold(body: TenantAdminEventFormScreen(existingEvent: existingEvent)),
    );

    await tester.pumpAndSettle();
    expect(
      tester.widget<FloatingActionButton>(
        find.byKey(const Key('tenantAdminEventAddOccurrenceButton')),
      ),
      isA<FloatingActionButton>(),
    );

    await tester.tap(
      find.byKey(const Key('tenantAdminEventAddOccurrenceButton')),
    );
    await tester.pumpAndSettle();
    await _closeOccurrenceSheet(tester);

    expect(
      controller.eventFormStateStreamValue.value.occurrences,
      hasLength(2),
    );
    expect(
      find.byKey(const Key('tenantAdminEventOccurrenceCard_0')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('tenantAdminEventOccurrenceCard_1')),
      findsOneWidget,
    );

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
                timeValue: tenantAdminOptionalText('17:00'),
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
        submittedOccurrence?.programmingItems.single.placeRef?.id,
        'venue-1',
      );
    },
  );

  test(
    'occurrence draft preserves programming end time when removing a related profile',
    () {
      final relatedProfile = tenantAdminAccountProfileFromRaw(
        id: 'artist-1',
        accountId: 'acc-artist-1',
        profileType: 'artist',
        displayName: 'Artist A',
      );
      final draft = TenantAdminEventOccurrenceEditorDraft(
        existing: null,
        startAt: DateTime.utc(2026, 4, 20, 20),
        endAt: null,
        relatedProfileIds: [TenantAdminAccountProfileIdValue('artist-1')],
        relatedProfiles: [relatedProfile],
        programmingItems: [
          TenantAdminEventProgrammingItem(
            timeValue: tenantAdminOptionalText('17:00'),
            endTimeValue: tenantAdminOptionalText('18:30'),
            titleValue: tenantAdminOptionalText('Show com encerramento'),
            accountProfileIdValues: [
              TenantAdminAccountProfileIdValue('artist-1'),
            ],
            linkedAccountProfiles: [relatedProfile],
          ),
        ],
      );

      draft.removeRelatedProfile('artist-1');

      final programmingItem = draft.programmingItems.single;
      expect(programmingItem.accountProfileIds, isEmpty);
      expect(programmingItem.linkedAccountProfiles, isEmpty);
      expect(programmingItem.time, '17:00');
      expect(programmingItem.endTime, '18:30');
      expect(programmingItem.title, 'Show com encerramento');
    },
  );

  testWidgets(
    'disables adding occurrence programming profile until an occurrence group exists',
    (tester) async {
      final eventsRepository = _FakeEventsRepository();
      final taxonomiesRepository = _FakeTaxonomiesRepository();
      final controller = TenantAdminEventsController(
        eventsRepository: eventsRepository,
        taxonomiesRepository: taxonomiesRepository,
      );

      eventsRepository.eventTypes = [
        TenantAdminEventType(
          idValue: tenantAdminOptionalText('507f1f77bcf86cd799439123'),
          nameValue: tenantAdminRequiredText('Feira'),
          slugValue: tenantAdminRequiredText('feira'),
        ),
      ];

      GetIt.I.registerSingleton<TenantAdminEventsController>(controller);

      await _pumpWithAutoRoute(
        tester,
        const Scaffold(body: TenantAdminEventFormScreen()),
      );

      await _fillRequiredFields(tester, controller: controller);
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const Key('tenantAdminEventAddOccurrenceButton')),
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

      expect(
        find.byKey(
          const Key(
            'tenantAdminProgrammingAddOccurrenceProfileGroupRequiredText',
          ),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const Key('tenantAdminProgrammingAddOccurrenceProfileGroupDropdown'),
        ),
        findsNothing,
      );
      final addOccurrenceProfileButton = tester.widget<OutlinedButton>(
        find.byKey(
          const Key('tenantAdminProgrammingAddOccurrenceProfileButton'),
        ),
      );
      expect(addOccurrenceProfileButton.onPressed, isNull);
    },
  );

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
        const Scaffold(body: TenantAdminEventFormScreen()),
      );

      await _fillRequiredFields(tester, controller: controller);
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const Key('tenantAdminEventAddOccurrenceButton')),
      );
      await tester.pumpAndSettle();

      final occurrenceGroupId = await _addOccurrenceProfileGroup(
        tester,
        controller,
        occurrenceIndex: 1,
        label: 'Bandas',
      );

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
      await _enterProgrammingTitle(tester, 'Apresentação especial');
      final linkOccurrenceProfileButton = tester.widget<OutlinedButton>(
        find.byKey(
          const Key('tenantAdminProgrammingLinkOccurrenceProfileButton'),
        ),
      );
      expect(linkOccurrenceProfileButton.onPressed, isNull);
      expect(
        find.byKey(
          const Key('tenantAdminProgrammingAddOccurrenceProfileButton'),
        ),
        findsNothing,
      );
      final addOccurrenceProfileButton = tester.widget<OutlinedButton>(
        find.byKey(
          Key(
            'tenantAdminProgrammingAddOccurrenceProfileButton_$occurrenceGroupId',
          ),
        ),
      );
      expect(addOccurrenceProfileButton.onPressed, isNotNull);
      final addOccurrenceProfileButtonFinder = find.byKey(
        Key(
          'tenantAdminProgrammingAddOccurrenceProfileButton_$occurrenceGroupId',
        ),
      );
      await tester.ensureVisible(addOccurrenceProfileButtonFinder);
      await tester.pumpAndSettle();
      await tester.tap(addOccurrenceProfileButtonFinder);
      await tester.pumpAndSettle();
      final artistAChoice = find.text('Artist A').last;
      await tester.ensureVisible(artistAChoice);
      await tester.pumpAndSettle();
      await tester.tap(artistAChoice);
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
      expect(occurrence.profileGroups.single.id, occurrenceGroupId);
      expect(
        occurrence.profileGroups.single.accountProfileIdValues.map(
          (entry) => entry.value,
        ),
        contains('artist-1'),
      );
      expect(occurrence.programmingItems.single.time, '13:00');
      expect(
        occurrence.programmingItems.single.title,
        _programmingTitleContains('Apresentação especial'),
      );
      expect(
        occurrence.programmingItems.single.accountProfileIds.map(
          (value) => value.value,
        ),
        contains('artist-1'),
      );
      expect(
        occurrence.programmingItems.single.placeRef?.type,
        'account_profile',
      );
      expect(occurrence.programmingItems.single.placeRef?.id, 'venue-1');
      expect(
        controller
            .eventFormStateStreamValue
            .value
            .selectedRelatedAccountProfileIds,
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
        eventsRepository.lastCreateDraft?.relatedAccountProfileIds.map(
          (value) => value.value,
        ),
        isEmpty,
      );
    },
  );

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
        const Scaffold(body: TenantAdminEventFormScreen()),
      );

      await _fillRequiredFields(tester, controller: controller);
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const Key('tenantAdminEventAddOccurrenceButton')),
      );
      await tester.pumpAndSettle();

      final occurrenceGroupId = await _addOccurrenceProfileGroup(
        tester,
        controller,
        occurrenceIndex: 1,
        label: 'Participantes',
      );
      await _selectProfileInGroup(
        tester,
        keyPrefix: 'OccurrenceProfile',
        groupId: occurrenceGroupId,
        profileId: 'artist-1',
      );

      await tester.scrollUntilVisible(
        find.byKey(const Key('tenantAdminOccurrenceAddProgrammingButton')),
        250,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(const Key('tenantAdminOccurrenceAddProgrammingButton')),
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
      await _enterProgrammingTitle(tester, 'Apresentação especial');
      final linkOccurrenceProfileButton = find.byKey(
        const Key('tenantAdminProgrammingLinkOccurrenceProfileButton'),
      );
      await tester.ensureVisible(linkOccurrenceProfileButton);
      await tester.pumpAndSettle();
      await tester.tap(linkOccurrenceProfileButton);
      await tester.pumpAndSettle();
      final artistAChoice = find.text('Artist A').last;
      await tester.ensureVisible(artistAChoice);
      await tester.pumpAndSettle();
      await tester.tap(artistAChoice);
      await tester.pumpAndSettle();
      await _tapProgrammingSaveButton(tester);
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('tenantAdminOccurrenceProgrammingItem_0')),
        findsOneWidget,
      );

      await _selectProfileInGroup(
        tester,
        keyPrefix: 'OccurrenceProfile',
        groupId: occurrenceGroupId,
        profileId: 'artist-1',
      );

      expect(
        controller
            .eventFormStateStreamValue
            .value
            .occurrences[1]
            .relatedAccountProfileIds,
        isEmpty,
      );
      expect(find.text('1 perfil(is) selecionado(s)'), findsNothing);
      expect(find.text('Selecionar perfis'), findsOneWidget);

      await _closeOccurrenceSheet(tester);

      final occurrence =
          controller.eventFormStateStreamValue.value.occurrences[1];
      expect(occurrence.relatedAccountProfileIds, isEmpty);
      expect(
        occurrence.programmingItems.single.title,
        _programmingTitleContains('Apresentação especial'),
      );
      expect(occurrence.programmingItems.single.accountProfileIds, isEmpty);
    },
  );

  testWidgets('edits occurrence programming item location in admin UI', (
    tester,
  ) async {
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
      const Scaffold(body: TenantAdminEventFormScreen()),
    );

    await _fillRequiredFields(tester, controller: controller);
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('tenantAdminEventAddOccurrenceButton')),
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
    await _enterProgrammingTitle(tester, 'Apresentação especial');
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

  testWidgets('programming location picker filters venues by search', (
    tester,
  ) async {
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
      const Scaffold(body: TenantAdminEventFormScreen()),
    );

    await _fillRequiredFields(tester, controller: controller);
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('tenantAdminEventAddOccurrenceButton')),
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
    await _enterProgrammingTitle(tester, 'Apresentação especial');
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
    await tester.pump(const Duration(milliseconds: 350));
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
    'programming location picker should fetch backend search results beyond the bootstrap venue slice',
    (tester) async {
      final eventsRepository =
          _SearchDrivenPhysicalHostCandidatesEventsRepository();
      final taxonomiesRepository = _FakeTaxonomiesRepository();
      final controller = TenantAdminEventsController(
        eventsRepository: eventsRepository,
        taxonomiesRepository: taxonomiesRepository,
      );

      eventsRepository.eventTypes = [
        TenantAdminEventType(
          idValue: tenantAdminOptionalText('507f1f77bcf86cd799439101'),
          nameValue: tenantAdminRequiredText('Feira'),
          slugValue: tenantAdminRequiredText('feira'),
        ),
      ];

      GetIt.I.registerSingleton<TenantAdminEventsController>(controller);

      await _pumpWithAutoRoute(
        tester,
        const Scaffold(body: TenantAdminEventFormScreen()),
      );

      await _fillRequiredFields(tester, controller: controller);
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const Key('tenantAdminEventAddOccurrenceButton')),
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
      await _enterProgrammingTitle(tester, 'Apresentação especial');
      await tester.ensureVisible(
        find.byKey(const Key('tenantAdminProgrammingLocationProfileDropdown')),
      );
      await tester.tap(
        find.byKey(const Key('tenantAdminProgrammingLocationProfileDropdown')),
        warnIfMissed: false,
      );
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel('Venue Bootstrap A'), findsWidgets);
      expect(find.bySemanticsLabel('Arena Bootstrap B'), findsWidgets);
      expect(find.bySemanticsLabel('Casa do Jazz'), findsNothing);

      await tester.enterText(
        find.byKey(const Key('tenantAdminProgrammingLocationSearchField')),
        'Jazz',
      );
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      expect(eventsRepository.physicalHostSearchRequests.last, ('jazz', 1));
      expect(find.bySemanticsLabel('Casa do Jazz'), findsWidgets);
      expect(find.bySemanticsLabel('Jazz sem POI'), findsNothing);
      expect(find.bySemanticsLabel('Venue Bootstrap A'), findsNothing);
      expect(find.bySemanticsLabel('Arena Bootstrap B'), findsNothing);
    },
  );

  testWidgets('programming location picker loads later venue pages on scroll', (
    tester,
  ) async {
    final eventsRepository = _PagedPhysicalHostCandidatesEventsRepository();
    final taxonomiesRepository = _FakeTaxonomiesRepository();
    final controller = TenantAdminEventsController(
      eventsRepository: eventsRepository,
      taxonomiesRepository: taxonomiesRepository,
    );

    eventsRepository.eventTypes = [
      TenantAdminEventType(
        idValue: tenantAdminOptionalText('507f1f77bcf86cd799439102'),
        nameValue: tenantAdminRequiredText('Feira'),
        slugValue: tenantAdminRequiredText('feira'),
      ),
    ];

    GetIt.I.registerSingleton<TenantAdminEventsController>(controller);

    await _pumpWithAutoRoute(
      tester,
      const Scaffold(body: TenantAdminEventFormScreen()),
    );

    await _fillRequiredFields(tester, controller: controller);
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('tenantAdminEventAddOccurrenceButton')),
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
    await _enterProgrammingTitle(tester, 'Apresentação especial');
    await tester.ensureVisible(
      find.byKey(const Key('tenantAdminProgrammingLocationProfileDropdown')),
    );
    await tester.tap(
      find.byKey(const Key('tenantAdminProgrammingLocationProfileDropdown')),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('Venue Page Two Target'), findsNothing);
    expect(eventsRepository.physicalHostPageRequests, [('', 1)]);

    await tester.scrollUntilVisible(
      find.bySemanticsLabel('Venue Page Two Target'),
      250,
      scrollable: find.descendant(
        of: find.byKey(const Key('tenantAdminProgrammingLocationOptionsList')),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.pumpAndSettle();

    expect(eventsRepository.physicalHostPageRequests, [('', 1), ('', 2)]);
    expect(find.bySemanticsLabel('Venue Page Two Target'), findsWidgets);
  });

  testWidgets(
    'existing programming item keeps saved off-page venue label from location_profile',
    (tester) async {
      final eventsRepository =
          _SearchDrivenPhysicalHostCandidatesEventsRepository();
      final taxonomiesRepository = _FakeTaxonomiesRepository();
      final controller = TenantAdminEventsController(
        eventsRepository: eventsRepository,
        taxonomiesRepository: taxonomiesRepository,
      );

      final eventType = TenantAdminEventType(
        idValue: tenantAdminOptionalText('507f1f77bcf86cd799439103'),
        nameValue: tenantAdminRequiredText('Feira'),
        slugValue: tenantAdminRequiredText('feira'),
      );
      eventsRepository.eventTypes = [eventType];

      final savedVenue = tenantAdminAccountProfileFromRaw(
        id: 'venue-jazz-1',
        accountId: 'acc-venue-jazz-1',
        profileType: 'venue',
        displayName: 'Casa do Jazz',
        location: tenantAdminLocationFromRaw(
          latitude: -20.612121,
          longitude: -40.498917,
        ),
      );
      final existingEvent = TenantAdminEvent(
        eventIdValue: tenantAdminRequiredText('evt-existing-programming-venue'),
        slugValue: tenantAdminRequiredText('event-existing-programming-venue'),
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
            programmingItems: [
              TenantAdminEventProgrammingItem(
                timeValue: tenantAdminOptionalText('19:00'),
                titleValue: tenantAdminOptionalText('Pocket show'),
                accountProfileIdValues: [
                  TenantAdminAccountProfileIdValue('artist-1'),
                ],
                linkedAccountProfiles: [
                  tenantAdminAccountProfileFromRaw(
                    id: 'artist-1',
                    accountId: 'acc-artist-1',
                    profileType: 'artist',
                    displayName: 'Artist One',
                  ),
                ],
                locationProfile: savedVenue,
                placeRef: TenantAdminEventPlaceRef(
                  typeValue: tenantAdminRequiredText('account_profile'),
                  idValue: tenantAdminRequiredText(savedVenue.id),
                ),
              ),
            ],
          ),
        ],
        publication: TenantAdminEventPublication(
          statusValue: tenantAdminRequiredText('draft'),
        ),
        location: TenantAdminEventLocation(
          modeValue: tenantAdminRequiredText('physical'),
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

      expect(find.text('Local: Casa do Jazz'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.byKey(const Key('tenantAdminPrimaryOccurrenceProgrammingItem_0')),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const Key('tenantAdminPrimaryOccurrenceProgrammingItem_0')),
        warnIfMissed: false,
      );
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel('Local da programação'), findsOneWidget);
      expect(find.text('Casa do Jazz'), findsWidgets);

      final locationDropdown = find.byKey(
        const Key('tenantAdminProgrammingLocationProfileDropdown'),
      );
      await tester.ensureVisible(locationDropdown);
      await tester.pumpAndSettle();
      await tester.tap(locationDropdown, warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(
        find.byKey(
          const Key('tenantAdminProgrammingLocationOption_venue-jazz-1'),
        ),
        findsOneWidget,
      );
      expect(find.text('Casa do Jazz'), findsWidgets);
      expect(find.text('venue-jazz-1'), findsNothing);
    },
  );

  testWidgets(
    'single-occurrence event programming is preserved after adding a second date',
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
        const Scaffold(body: TenantAdminEventFormScreen()),
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
        find.byKey(
          const Key('tenantAdminPrimaryOccurrenceAddProgrammingButton'),
        ),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(
          const Key('tenantAdminPrimaryOccurrenceAddProgrammingButton'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('tenantAdminProgrammingTimeField')),
        '19:00',
      );
      await _enterProgrammingTitle(tester, 'Abertura principal');
      await _tapProgrammingSaveButton(tester);
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('tenantAdminPrimaryOccurrenceProgrammingItem_0')),
        findsOneWidget,
      );
      expect(find.textContaining('Abertura principal'), findsOneWidget);

      await tester.tap(
        find.byKey(const Key('tenantAdminEventAddOccurrenceButton')),
      );
      await tester.pumpAndSettle();
      await _closeOccurrenceSheet(tester);

      expect(
        find.byKey(const Key('tenantAdminPrimaryOccurrenceProgrammingSection')),
        findsNothing,
      );
      expect(
        find.byKey(const Key('tenantAdminEventOccurrenceCard_0')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('tenantAdminEventOccurrenceCard_1')),
        findsOneWidget,
      );
      expect(find.text('1 item de programação'), findsOneWidget);

      await tester.ensureVisible(
        find.byKey(const Key('tenantAdminEventOccurrenceCard_0')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const Key('tenantAdminEventOccurrenceCard_0')),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('tenantAdminOccurrenceProgrammingItem_0')),
        findsOneWidget,
      );
      expect(find.textContaining('Abertura principal'), findsOneWidget);

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
      final createdRootProgrammingTitles = eventsRepository
          .lastCreateDraft
          ?.occurrences
          .first
          .programmingItems
          .map((item) => item.title)
          .toList(growable: false);
      expect(createdRootProgrammingTitles, hasLength(1));
      expect(
        createdRootProgrammingTitles?.single,
        _programmingTitleContains('Abertura principal'),
      );
    },
  );

  testWidgets(
    'edit flow keeps event-level programming on the first occurrence after adding a second date and editing second-occurrence programming',
    (tester) async {
      final eventsRepository = _FakeEventsRepository();
      final taxonomiesRepository = _FakeTaxonomiesRepository();
      final controller = TenantAdminEventsController(
        eventsRepository: eventsRepository,
        taxonomiesRepository: taxonomiesRepository,
      );

      final eventType = TenantAdminEventType(
        idValue: tenantAdminOptionalText('507f1f77bcf86cd799439188-edit'),
        nameValue: tenantAdminRequiredText('Feira'),
        slugValue: tenantAdminRequiredText('feira'),
      );
      eventsRepository.eventTypes = [eventType];

      final existingEvent = TenantAdminEvent(
        eventIdValue: tenantAdminRequiredText('evt-existing-root-programming'),
        slugValue: tenantAdminRequiredText('evt-existing-root-programming'),
        titleValue: tenantAdminRequiredText('Evento existente'),
        contentValue: tenantAdminOptionalText('<p>Descrição existente</p>'),
        type: eventType,
        occurrences: <TenantAdminEventOccurrence>[
          TenantAdminEventOccurrence(
            occurrenceIdValue: tenantAdminOptionalText('occ-1'),
            occurrenceSlugValue: tenantAdminOptionalText('occ-1'),
            dateTimeStartValue: tenantAdminDateTime(
              DateTime.utc(2026, 3, 5, 20),
            ),
            dateTimeEndValue: tenantAdminOptionalDateTime(
              DateTime.utc(2026, 3, 5, 22),
            ),
          ),
        ],
        publication: TenantAdminEventPublication(
          statusValue: tenantAdminRequiredText('published'),
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

      await tester.scrollUntilVisible(
        find.byKey(
          const Key('tenantAdminPrimaryOccurrenceAddProgrammingButton'),
        ),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(
          const Key('tenantAdminPrimaryOccurrenceAddProgrammingButton'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('tenantAdminProgrammingTimeField')),
        '09:30',
      );
      await _enterProgrammingTitle(tester, 'Programação raiz');
      await _tapProgrammingSaveButton(tester);
      await tester.pumpAndSettle();

      expect(find.textContaining('Programação raiz'), findsOneWidget);

      await tester.ensureVisible(
        find.byKey(const Key('tenantAdminEventAddOccurrenceButton')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const Key('tenantAdminEventAddOccurrenceButton')),
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
      await _enterProgrammingTitle(tester, 'Programação local');
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

      await tester.tap(
        find.byKey(const Key('tenantAdminOccurrenceProgrammingItem_0')),
      );
      await tester.pumpAndSettle();
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

      await _closeOccurrenceSheet(tester);

      expect(
        find.byKey(const Key('tenantAdminPrimaryOccurrenceProgrammingSection')),
        findsNothing,
      );
      expect(find.text('1 item de programação'), findsNWidgets(2));

      await tester.ensureVisible(
        find.byKey(const Key('tenantAdminEventOccurrenceCard_0')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const Key('tenantAdminEventOccurrenceCard_0')),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Programação raiz'), findsOneWidget);
      expect(find.text('Programação local'), findsNothing);
      await _closeOccurrenceSheet(tester);

      await tester.ensureVisible(
        find.widgetWithText(FilledButton, 'Salvar alterações'),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Salvar alterações'));
      await tester.pumpAndSettle();

      expect(eventsRepository.lastUpdateDraft?.occurrences, hasLength(2));
      final updatedRootProgrammingTitles = eventsRepository
          .lastUpdateDraft
          ?.occurrences
          .first
          .programmingItems
          .map((item) => item.title)
          .toList(growable: false);
      expect(updatedRootProgrammingTitles, hasLength(1));
      expect(
        updatedRootProgrammingTitles?.single,
        _programmingTitleContains('Programação raiz'),
      );
      final updatedSecondOccurrenceProgrammingTitles = eventsRepository
          .lastUpdateDraft
          ?.occurrences[1]
          .programmingItems
          .map((item) => item.title)
          .toList(growable: false);
      expect(updatedSecondOccurrenceProgrammingTitles, hasLength(1));
      expect(
        updatedSecondOccurrenceProgrammingTitles?.single,
        _programmingTitleContains('Programação local'),
      );
      expect(
        eventsRepository
            .lastUpdateDraft
            ?.occurrences[1]
            .programmingItems
            .single
            .placeRef,
        isNull,
      );
    },
  );

  testWidgets(
    'edit submit preserves hydrated occurrence order when existing occurrences arrive out of order',
    (tester) async {
      final eventsRepository = _FakeEventsRepository();
      final taxonomiesRepository = _FakeTaxonomiesRepository();
      final controller = TenantAdminEventsController(
        eventsRepository: eventsRepository,
        taxonomiesRepository: taxonomiesRepository,
      );

      final eventType = TenantAdminEventType(
        idValue: tenantAdminOptionalText('507f1f77bcf86cd799439188-order'),
        nameValue: tenantAdminRequiredText('Feira'),
        slugValue: tenantAdminRequiredText('feira'),
      );
      eventsRepository.eventTypes = [eventType];

      final existingEvent = TenantAdminEvent(
        eventIdValue: tenantAdminRequiredText('evt-existing-out-of-order'),
        slugValue: tenantAdminRequiredText('evt-existing-out-of-order'),
        titleValue: tenantAdminRequiredText('Evento fora de ordem'),
        contentValue: tenantAdminOptionalText('<p>Descrição existente</p>'),
        type: eventType,
        occurrences: <TenantAdminEventOccurrence>[
          TenantAdminEventOccurrence(
            occurrenceIdValue: tenantAdminOptionalText('occ-2'),
            occurrenceSlugValue: tenantAdminOptionalText('occ-2'),
            dateTimeStartValue: tenantAdminDateTime(
              DateTime.utc(2026, 3, 6, 20),
            ),
            dateTimeEndValue: tenantAdminOptionalDateTime(
              DateTime.utc(2026, 3, 6, 22),
            ),
            programmingItems: [
              TenantAdminEventProgrammingItem(
                timeValue: tenantAdminOptionalText('13:00'),
                titleValue: tenantAdminOptionalText('Programação local'),
              ),
            ],
          ),
          TenantAdminEventOccurrence(
            occurrenceIdValue: tenantAdminOptionalText('occ-1'),
            occurrenceSlugValue: tenantAdminOptionalText('occ-1'),
            dateTimeStartValue: tenantAdminDateTime(
              DateTime.utc(2026, 3, 5, 20),
            ),
            dateTimeEndValue: tenantAdminOptionalDateTime(
              DateTime.utc(2026, 3, 5, 22),
            ),
            programmingItems: [
              TenantAdminEventProgrammingItem(
                timeValue: tenantAdminOptionalText('09:30'),
                titleValue: tenantAdminOptionalText('Programação raiz'),
              ),
            ],
          ),
        ],
        publication: TenantAdminEventPublication(
          statusValue: tenantAdminRequiredText('published'),
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
        find.widgetWithText(FilledButton, 'Salvar alterações'),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Salvar alterações'));
      await tester.pumpAndSettle();

      expect(
        eventsRepository.lastUpdateDraft?.occurrences
            .map((occurrence) => occurrence.occurrenceId)
            .toList(growable: false),
        ['occ-2', 'occ-1'],
      );
      final reorderedFirstOccurrenceProgrammingTitles = eventsRepository
          .lastUpdateDraft
          ?.occurrences
          .first
          .programmingItems
          .map((item) => item.title)
          .toList(growable: false);
      expect(reorderedFirstOccurrenceProgrammingTitles, hasLength(1));
      expect(
        reorderedFirstOccurrenceProgrammingTitles?.single,
        _programmingTitleContains('Programação local'),
      );
      final reorderedSecondOccurrenceProgrammingTitles = eventsRepository
          .lastUpdateDraft
          ?.occurrences[1]
          .programmingItems
          .map((item) => item.title)
          .toList(growable: false);
      expect(reorderedSecondOccurrenceProgrammingTitles, hasLength(1));
      expect(
        reorderedSecondOccurrenceProgrammingTitles?.single,
        _programmingTitleContains('Programação raiz'),
      );
    },
  );

  testWidgets(
    'root related profile groups remain visible after the event has multiple occurrences',
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
        const Scaffold(body: TenantAdminEventFormScreen()),
      );

      await _fillRequiredFields(tester, controller: controller);
      await tester.pumpAndSettle();

      expect(find.text('Abas de perfis relacionados'), findsOneWidget);

      await tester.tap(
        find.byKey(const Key('tenantAdminEventAddOccurrenceButton')),
      );
      await tester.pumpAndSettle();
      await _closeOccurrenceSheet(tester);

      expect(find.text('Abas de perfis relacionados'), findsOneWidget);
      expect(
        find.byKey(const Key('tenantAdminEventOccurrenceCard_0')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('tenantAdminEventOccurrenceCard_1')),
        findsOneWidget,
      );
    },
  );

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
        const Scaffold(body: TenantAdminEventFormScreen()),
      );

      await _fillRequiredFields(tester, controller: controller);
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const Key('tenantAdminEventAddOccurrenceButton')),
      );
      await tester.pumpAndSettle();
      await _closeOccurrenceSheet(tester);

      expect(
        controller.eventFormStateStreamValue.value.occurrences,
        hasLength(2),
      );

      await tester.ensureVisible(
        find.byKey(const Key('tenantAdminEventOccurrenceCard_1')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const Key('tenantAdminEventOccurrenceCard_1')),
      );
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
      expect(occurrence.programmingItems.map((item) => item.title), [
        _programmingTitleContains('Primeira atividade'),
        _programmingTitleContains('Segunda atividade'),
      ]);
    },
  );

  testWidgets(
    'occurrence programming cards reserve drag for sequential items and keep identities through controller operations',
    (tester) async {
      final eventsRepository = _FakeEventsRepository();
      final taxonomiesRepository = _FakeTaxonomiesRepository();
      final controller = TenantAdminEventsController(
        eventsRepository: eventsRepository,
        taxonomiesRepository: taxonomiesRepository,
      );

      eventsRepository.eventTypes = [
        TenantAdminEventType(
          idValue: tenantAdminOptionalText('507f1f77bcf86cd799439202'),
          nameValue: tenantAdminRequiredText('Feira'),
          slugValue: tenantAdminRequiredText('feira'),
        ),
      ];

      GetIt.I.registerSingleton<TenantAdminEventsController>(controller);
      await _pumpWithAutoRoute(
        tester,
        const Scaffold(body: TenantAdminEventFormScreen()),
      );
      await _fillRequiredFields(tester, controller: controller);
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const Key('tenantAdminEventAddOccurrenceButton')),
      );
      await tester.pumpAndSettle();
      await _closeOccurrenceSheet(tester);

      await tester.ensureVisible(
        find.byKey(const Key('tenantAdminEventOccurrenceCard_1')),
      );
      await tester.tap(
        find.byKey(const Key('tenantAdminEventOccurrenceCard_1')),
      );
      await tester.pumpAndSettle();

      await _addOccurrenceProgrammingTitleOnly(
        tester,
        time: '09:00',
        title: 'Abertura fixa',
      );
      await _addOccurrenceProgrammingUntimedTitleOnly(
        tester,
        time: '10:00',
        title: 'Intervenção sequencial',
      );
      await tester.pumpAndSettle();

      expect(find.text('Fixo'), findsOneWidget);
      expect(find.text('Sequencial'), findsOneWidget);
      expect(
        find.byKey(const Key('tenantAdminOccurrenceProgrammingDrag_0')),
        findsNothing,
      );
      expect(
        find.byKey(const Key('tenantAdminOccurrenceProgrammingDrag_1')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('tenantAdminOccurrenceProgrammingInsert_0')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('tenantAdminOccurrenceProgrammingInsert_1')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('tenantAdminOccurrenceProgrammingInsert_2')),
        findsOneWidget,
      );

      final occurrenceKey = controller.occurrenceKeyAt(1)!;
      final originalEntries = controller.programmingItemsForOccurrenceKey(
        occurrenceKey,
      );
      final fixedEntry = originalEntries.first;
      final sequentialEntry = originalEntries.last;

      controller.moveOccurrenceProgrammingItem(
        occurrenceKey: occurrenceKey,
        itemKey: sequentialEntry.key,
        targetIndex: 0,
      );

      final movedEntries = controller.programmingItemsForOccurrenceKey(
        occurrenceKey,
      );
      expect(movedEntries.map((entry) => entry.key), [
        sequentialEntry.key,
        fixedEntry.key,
      ]);

      controller.moveOccurrenceProgrammingItem(
        occurrenceKey: occurrenceKey,
        itemKey: fixedEntry.key,
        targetIndex: 2,
      );
      expect(
        controller
            .programmingItemsForOccurrenceKey(occurrenceKey)
            .map((entry) => entry.key),
        [sequentialEntry.key, fixedEntry.key],
      );

      controller.insertOccurrenceProgrammingItem(
        occurrenceKey: occurrenceKey,
        index: 1,
        item: TenantAdminEventProgrammingItem(
          titleValue: tenantAdminOptionalText('Ponte sequencial'),
        ),
      );

      final insertedEntries = controller.programmingItemsForOccurrenceKey(
        occurrenceKey,
      );
      expect(insertedEntries[0].key, sequentialEntry.key);
      expect(insertedEntries[2].key, fixedEntry.key);
      expect(insertedEntries.map((entry) => entry.value.title), [
        _programmingTitleContains('Intervenção sequencial'),
        _programmingTitleContains('Ponte sequencial'),
        _programmingTitleContains('Abertura fixa'),
      ]);
    },
  );

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
        const Scaffold(body: TenantAdminEventFormScreen()),
      );

      await _fillRequiredFields(tester, controller: controller);
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const Key('tenantAdminEventAddOccurrenceButton')),
      );
      await tester.pumpAndSettle();
      await _closeOccurrenceSheet(tester);

      await tester.ensureVisible(
        find.byKey(const Key('tenantAdminEventOccurrenceCard_1')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const Key('tenantAdminEventOccurrenceCard_1')),
      );
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
      expect(occurrence.programmingItems.map((item) => item.time), [
        '10:00',
        '11:00',
      ]);
      expect(
        occurrence.relatedAccountProfileIds.map((item) => item.value),
        containsAll(['artist-1', 'artist-2']),
      );
    },
  );

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
      await tester.tap(
        find.byKey(const Key('tenantAdminEventOccurrenceCard_1')),
      );
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
    },
  );

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
        eventIdValue: tenantAdminRequiredText(
          'evt-existing-programming-reopen',
        ),
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
      await tester.tap(
        find.byKey(const Key('tenantAdminEventOccurrenceCard_1')),
      );
      await tester.pumpAndSettle();
      await _addOccurrenceProgrammingWithNewProfile(
        tester,
        time: '10:00',
        profileName: 'Artist A',
      );
      await _closeOccurrenceSheet(tester);

      expect(
        controller
            .eventFormStateStreamValue
            .value
            .occurrences[1]
            .programmingItems
            .map((item) => item.time),
        ['10:00'],
      );

      await tester.ensureVisible(
        find.byKey(const Key('tenantAdminEventOccurrenceCard_1')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const Key('tenantAdminEventOccurrenceCard_1')),
      );
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
        controller
            .eventFormStateStreamValue
            .value
            .occurrences[1]
            .programmingItems
            .map((item) => item.time),
        ['10:00', '11:00'],
      );
    },
  );

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
      await tester.tap(
        find.byKey(const Key('tenantAdminEventOccurrenceCard_2')),
      );
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
            .eventFormStateStreamValue
            .value
            .occurrences[0]
            .programmingItems,
        isEmpty,
      );
      expect(
        controller
            .eventFormStateStreamValue
            .value
            .occurrences[1]
            .programmingItems,
        isEmpty,
      );
      expect(
        controller
            .eventFormStateStreamValue
            .value
            .occurrences[2]
            .programmingItems
            .map((item) => item.time),
        ['10:00', '11:00'],
      );
    },
  );

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
      await tester.tap(
        find.byKey(const Key('tenantAdminEventOccurrenceCard_2')),
      );
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
      expect(occurrence.relatedAccountProfileIds.map((item) => item.value), [
        'artist-1',
      ]);
      expect(occurrence.programmingItems.map((item) => item.time), [
        '10:00',
        '11:00',
      ]);
      expect(
        occurrence.programmingItems
            .expand((item) => item.accountProfileIds)
            .map((item) => item.value),
        ['artist-1', 'artist-1'],
      );
    },
  );

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
      await tester.tap(
        find.byKey(const Key('tenantAdminEventOccurrenceCard_2')),
      );
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
    },
  );

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
        eventIdValue: tenantAdminRequiredText(
          'evt-existing-programming-drag-item',
        ),
        slugValue: tenantAdminRequiredText(
          'event-existing-programming-drag-item',
        ),
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
      await tester.tap(
        find.byKey(const Key('tenantAdminEventOccurrenceCard_2')),
      );
      await tester.pumpAndSettle();

      await _ensureOccurrenceProgrammingGroup(tester);
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
      await _setProgrammingTimedState(tester, isTimed: true);
      await _tapFirstProgrammingAddOccurrenceProfileButton(tester);
      await _tapVisibleText(tester, 'Artist A');

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
    },
  );

  testWidgets(
    'turning off timed programming submits a sequenced item without time or end time',
    (tester) async {
      final eventsRepository = _FakeEventsRepository();
      final taxonomiesRepository = _FakeTaxonomiesRepository();
      final controller = TenantAdminEventsController(
        eventsRepository: eventsRepository,
        taxonomiesRepository: taxonomiesRepository,
      );

      final eventType = TenantAdminEventType(
        idValue: tenantAdminOptionalText('507f1f77bcf86cd799439199'),
        nameValue: tenantAdminRequiredText('Feira'),
        slugValue: tenantAdminRequiredText('feira'),
      );
      eventsRepository.eventTypes = [eventType];

      final existingEvent = TenantAdminEvent(
        eventIdValue: tenantAdminRequiredText(
          'evt-existing-programming-untimed',
        ),
        slugValue: tenantAdminRequiredText(
          'event-existing-programming-untimed',
        ),
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
        find.byKey(const Key('tenantAdminEventEditPrimaryOccurrenceButton')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const Key('tenantAdminEventEditPrimaryOccurrenceButton')),
      );
      await tester.pumpAndSettle();

      await _addOccurrenceProgrammingUntimedTitleOnly(
        tester,
        time: '10:00',
        title: 'Logo após o bloco anterior',
      );

      expect(
        find.byKey(const Key('tenantAdminOccurrenceProgrammingItem_0')),
        findsOneWidget,
      );

      await _closeOccurrenceSheet(tester);

      await tester.scrollUntilVisible(
        find.widgetWithText(FilledButton, 'Salvar alterações'),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Salvar alterações'));
      await tester.pumpAndSettle();

      final submittedOccurrence =
          eventsRepository.lastUpdateDraft?.occurrences.single;
      final submittedProgrammingItem =
          submittedOccurrence?.programmingItems.single;
      expect(submittedProgrammingItem?.isSequential, isTrue);
      expect(submittedProgrammingItem?.time, isEmpty);
      expect(submittedProgrammingItem?.endTime, isNull);
      expect(
        submittedProgrammingItem?.title,
        _programmingTitleContains('Logo após o bloco anterior'),
      );
    },
  );

  testWidgets(
    'programming item editor uses rich text editor and renders sequencial label in occurrence sheet',
    (tester) async {
      final eventsRepository = _FakeEventsRepository();
      final taxonomiesRepository = _FakeTaxonomiesRepository();
      final controller = TenantAdminEventsController(
        eventsRepository: eventsRepository,
        taxonomiesRepository: taxonomiesRepository,
      );

      eventsRepository.eventTypes = [
        TenantAdminEventType(
          idValue: tenantAdminOptionalText('507f1f77bcf86cd799439197'),
          nameValue: tenantAdminRequiredText('Feira'),
          slugValue: tenantAdminRequiredText('feira'),
        ),
      ];

      GetIt.I.registerSingleton<TenantAdminEventsController>(controller);

      await _pumpWithAutoRoute(
        tester,
        const Scaffold(body: TenantAdminEventFormScreen()),
      );

      await _fillRequiredFields(tester, controller: controller);
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const Key('tenantAdminEventAddOccurrenceButton')),
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

      expect(_programmingTitleEditorFinder(), findsOneWidget);
      expect(find.text('Item com horário'), findsOneWidget);
      expect(find.text('Usa faixa de horário explícita.'), findsOneWidget);
      expect(
        find.byKey(const Key('tenantAdminProgrammingCloseButton')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('tenantAdminProgrammingTimeField')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('tenantAdminProgrammingEndTimeField')),
        findsOneWidget,
      );

      await tester.enterText(
        find.byKey(const Key('tenantAdminProgrammingTimeField')),
        '09:00',
      );
      await _enterProgrammingTitle(tester, 'Abertura sequencial');
      await _setProgrammingTimedState(tester, isTimed: false);

      expect(find.text('Item sequencial sem horário.'), findsOneWidget);
      expect(
        find.byKey(const Key('tenantAdminProgrammingTimeField')),
        findsNothing,
      );
      expect(
        find.byKey(const Key('tenantAdminProgrammingEndTimeField')),
        findsNothing,
      );

      await _tapProgrammingSaveButton(tester);
      await tester.pumpAndSettle();

      expect(find.text('Sequencial'), findsOneWidget);
      expect(find.text('Abertura sequencial'), findsOneWidget);
    },
  );

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
        eventIdValue: tenantAdminRequiredText(
          'evt-existing-programming-dismiss',
        ),
        slugValue: tenantAdminRequiredText(
          'event-existing-programming-dismiss',
        ),
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
      await tester.tap(
        find.byKey(const Key('tenantAdminEventOccurrenceCard_2')),
      );
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
    },
  );

  testWidgets('uses own-account endpoint when account slug is provided', (
    tester,
  ) async {
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
      const Scaffold(body: TenantAdminEventFormScreen()),
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

  testWidgets(
    'shows inline validation when physical mode has no selected host',
    (tester) async {
      final eventsRepository = _FakeEventsRepository()
        ..physicalHostCandidates = const <TenantAdminAccountProfile>[];
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
        const Scaffold(body: TenantAdminEventFormScreen()),
      );

      await _fillRequiredFields(tester, controller: controller);
      await tester.tap(find.text('Online').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Physical').last);
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.widgetWithText(FilledButton, 'Criar evento'),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Criar evento'));
      await tester.pumpAndSettle();

      expect(eventsRepository.createEventCalls, 0);
      expect(
        find.text('Host físico é obrigatório para physical.'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'renders backend place_ref validation inline on the location group',
    (tester) async {
      final eventsRepository = _FakeEventsRepository()
        ..createEventError = FormValidationFailure(
          statusCode: 422,
          message: 'validation.required_if',
          fieldErrors: <String, List<String>>{
            'place_ref': const <String>['validation.required_if'],
          },
        );
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
        const Scaffold(body: TenantAdminEventFormScreen()),
      );

      await _fillRequiredFields(tester, controller: controller);
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
      await tester.tap(
        find.byKey(const Key('tenantAdminEventLocationOption_venue-1')),
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

      expect(eventsRepository.createEventCalls, 1);
      expect(find.text('validation.required_if'), findsOneWidget);
      expect(
        controller.eventValidationStreamValue.value.errorsForGroup(
          TenantAdminEventFormValidationTargets.location,
        ),
        contains('validation.required_if'),
      );
      expect(
        controller.eventValidationStreamValue.value.errorsForGlobal(),
        isEmpty,
      );
    },
  );

  testWidgets(
    'renders backend type.id validation inline on the event type field',
    (tester) async {
      final eventsRepository = _FakeEventsRepository()
        ..createEventError = FormValidationFailure(
          statusCode: 422,
          message: 'The given data was invalid.',
          fieldErrors: <String, List<String>>{
            'type.id': const <String>['Tipo de evento invalido.'],
          },
        );
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
        const Scaffold(body: TenantAdminEventFormScreen()),
      );

      await _fillRequiredFields(tester, controller: controller);

      await tester.scrollUntilVisible(
        find.widgetWithText(FilledButton, 'Criar evento'),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Criar evento'));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(eventsRepository.createEventCalls, 1);
      expect(find.text('Tipo de evento invalido.'), findsOneWidget);
      expect(
        controller.eventValidationStreamValue.value.errorForField(
          TenantAdminEventFormValidationTargets.eventType,
        ),
        'Tipo de evento invalido.',
      );
    },
  );

  testWidgets(
    'renders backend place_ref.id validation inline on the location group',
    (tester) async {
      final eventsRepository = _FakeEventsRepository()
        ..createEventError = FormValidationFailure(
          statusCode: 422,
          message: 'The given data was invalid.',
          fieldErrors: <String, List<String>>{
            'place_ref.id': const <String>['Host físico inválido.'],
          },
        );
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
        const Scaffold(body: TenantAdminEventFormScreen()),
      );

      await _fillRequiredFields(tester, controller: controller);
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
      await tester.tap(
        find.byKey(const Key('tenantAdminEventLocationOption_venue-1')),
      );
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.widgetWithText(FilledButton, 'Criar evento'),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Criar evento'));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(eventsRepository.createEventCalls, 1);
      expect(find.text('Host físico inválido.'), findsOneWidget);
      expect(
        controller.eventValidationStreamValue.value.errorsForGroup(
          TenantAdminEventFormValidationTargets.location,
        ),
        contains('Host físico inválido.'),
      );
      expect(
        controller.eventValidationStreamValue.value.errorsForGlobal(),
        isEmpty,
      );
    },
  );

  testWidgets(
    'renders backend event_parties validation inline on the related profiles section',
    (tester) async {
      final eventsRepository = _FakeEventsRepository()
        ..createEventError = FormValidationFailure(
          statusCode: 422,
          message: 'The given data was invalid.',
          fieldErrors: <String, List<String>>{
            'event_parties.0.party_ref_id': const <String>[
              'Perfil relacionado inválido.',
            ],
          },
        );
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
        const Scaffold(body: TenantAdminEventFormScreen()),
      );

      await _fillRequiredFields(tester, controller: controller);

      await tester.scrollUntilVisible(
        find.widgetWithText(FilledButton, 'Criar evento'),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Criar evento'));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(eventsRepository.createEventCalls, 1);
      expect(find.text('Perfil relacionado inválido.'), findsOneWidget);
      expect(
        controller.eventValidationStreamValue.value.errorsForGroup(
          TenantAdminEventFormValidationTargets.relatedProfiles,
        ),
        contains('Perfil relacionado inválido.'),
      );
      expect(
        controller.eventValidationStreamValue.value.errorsForGlobal(),
        isEmpty,
      );
    },
  );

  testWidgets(
    'renders backend occurrence programming validation inline on the schedule group',
    (tester) async {
      final eventsRepository = _FakeEventsRepository()
        ..createEventError = FormValidationFailure(
          statusCode: 422,
          message: 'The given data was invalid.',
          fieldErrors: <String, List<String>>{
            'occurrences.0.programming_items.0.place_ref.id': const <String>[
              'Host da programação inválido.',
            ],
          },
        );
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
        const Scaffold(body: TenantAdminEventFormScreen()),
      );

      await _fillRequiredFields(tester, controller: controller);

      await tester.scrollUntilVisible(
        find.widgetWithText(FilledButton, 'Criar evento'),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Criar evento'));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(eventsRepository.createEventCalls, 1);
      expect(find.text('Host da programação inválido.'), findsOneWidget);
      expect(
        controller.eventValidationStreamValue.value.errorsForGroup(
          TenantAdminEventFormValidationTargets.schedule,
        ),
        contains('Host da programação inválido.'),
      );
      expect(
        controller.eventValidationStreamValue.value.errorsForGlobal(),
        isEmpty,
      );
    },
  );

  testWidgets('physical mode venue picker filters venues by search', (
    tester,
  ) async {
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
      const Scaffold(body: TenantAdminEventFormScreen()),
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
    await tester.pump(const Duration(milliseconds: 350));
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

  testWidgets(
    'physical mode venue picker should fetch backend search results beyond the bootstrap venue slice',
    (tester) async {
      final eventsRepository =
          _SearchDrivenPhysicalHostCandidatesEventsRepository();
      final taxonomiesRepository = _FakeTaxonomiesRepository();
      final controller = TenantAdminEventsController(
        eventsRepository: eventsRepository,
        taxonomiesRepository: taxonomiesRepository,
      );

      eventsRepository.eventTypes = [
        TenantAdminEventType(
          idValue: tenantAdminOptionalText('507f1f77bcf86cd799439016'),
          nameValue: tenantAdminRequiredText('Live'),
          slugValue: tenantAdminRequiredText('live'),
          descriptionValue: tenantAdminOptionalText('Tipo de evento: Live'),
        ),
      ];

      GetIt.I.registerSingleton<TenantAdminEventsController>(controller);

      await _pumpWithAutoRoute(
        tester,
        const Scaffold(body: TenantAdminEventFormScreen()),
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

      expect(find.bySemanticsLabel('Venue Bootstrap A'), findsWidgets);
      expect(find.bySemanticsLabel('Arena Bootstrap B'), findsWidgets);
      expect(find.bySemanticsLabel('Casa do Jazz'), findsNothing);

      await tester.enterText(
        find.byKey(const Key('tenantAdminEventLocationSearchField')),
        'Jazz',
      );
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      expect(eventsRepository.physicalHostSearchRequests.last, ('jazz', 1));
      expect(find.bySemanticsLabel('Casa do Jazz'), findsWidgets);
      expect(find.bySemanticsLabel('Jazz sem POI'), findsNothing);
      expect(find.bySemanticsLabel('Venue Bootstrap A'), findsNothing);
      expect(find.bySemanticsLabel('Arena Bootstrap B'), findsNothing);
    },
  );

  testWidgets(
    'submits physical venue selected from remote search beyond the bootstrap venue slice',
    (tester) async {
      final eventsRepository =
          _SearchDrivenPhysicalHostCandidatesEventsRepository();
      final taxonomiesRepository = _FakeTaxonomiesRepository();
      final controller = TenantAdminEventsController(
        eventsRepository: eventsRepository,
        taxonomiesRepository: taxonomiesRepository,
      );

      eventsRepository.eventTypes = [
        TenantAdminEventType(
          idValue: tenantAdminOptionalText('507f1f77bcf86cd799439016'),
          nameValue: tenantAdminRequiredText('Live'),
          slugValue: tenantAdminRequiredText('live'),
          descriptionValue: tenantAdminOptionalText('Tipo de evento: Live'),
        ),
      ];

      GetIt.I.registerSingleton<TenantAdminEventsController>(controller);

      await _pumpWithAutoRoute(
        tester,
        const Scaffold(body: TenantAdminEventFormScreen()),
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

      await tester.enterText(
        find.byKey(const Key('tenantAdminEventLocationSearchField')),
        'Jazz',
      );
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const Key('tenantAdminEventLocationOption_venue-jazz-1')),
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
      expect(draft.placeRef?.id, 'venue-jazz-1');
    },
  );

  testWidgets(
    'submits account-scoped physical venue selected from remote search beyond the bootstrap venue slice',
    (tester) async {
      final eventsRepository =
          _SearchDrivenPhysicalHostCandidatesEventsRepository();
      final taxonomiesRepository = _FakeTaxonomiesRepository();
      final controller = TenantAdminEventsController(
        eventsRepository: eventsRepository,
        taxonomiesRepository: taxonomiesRepository,
      );

      eventsRepository.eventTypes = [
        TenantAdminEventType(
          idValue: tenantAdminOptionalText('507f1f77bcf86cd799439016'),
          nameValue: tenantAdminRequiredText('Live'),
          slugValue: tenantAdminRequiredText('live'),
          descriptionValue: tenantAdminOptionalText('Tipo de evento: Live'),
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

      await tester.enterText(
        find.byKey(const Key('tenantAdminEventLocationSearchField')),
        'Jazz',
      );
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const Key('tenantAdminEventLocationOption_venue-jazz-1')),
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

      final draft = eventsRepository.lastCreateOwnDraft;
      expect(eventsRepository.lastCreateOwnAccountSlug, 'school-account');
      expect(draft, isNotNull);
      expect(draft!.location?.mode, 'physical');
      expect(draft.location?.latitude, -20.612121);
      expect(draft.location?.longitude, -40.498917);
      expect(draft.placeRef?.id, 'venue-jazz-1');
    },
  );

  testWidgets(
    'keeps remote physical venue resolution after picker caches are replaced',
    (tester) async {
      final eventsRepository =
          _SearchDrivenPhysicalHostCandidatesEventsRepository();
      final taxonomiesRepository = _FakeTaxonomiesRepository();
      final controller = TenantAdminEventsController(
        eventsRepository: eventsRepository,
        taxonomiesRepository: taxonomiesRepository,
      );

      eventsRepository.eventTypes = [
        TenantAdminEventType(
          idValue: tenantAdminOptionalText('507f1f77bcf86cd799439016'),
          nameValue: tenantAdminRequiredText('Live'),
          slugValue: tenantAdminRequiredText('live'),
          descriptionValue: tenantAdminOptionalText('Tipo de evento: Live'),
        ),
      ];

      GetIt.I.registerSingleton<TenantAdminEventsController>(controller);

      await _pumpWithAutoRoute(
        tester,
        const Scaffold(body: TenantAdminEventFormScreen()),
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

      await tester.enterText(
        find.byKey(const Key('tenantAdminEventLocationSearchField')),
        'Jazz',
      );
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const Key('tenantAdminEventLocationOption_venue-jazz-1')),
      );
      await tester.pumpAndSettle();

      controller.accountProfilePickerResultsStreamValue.addValue(const []);
      controller.venueCandidatesStreamValue.addValue(const []);
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
      expect(draft.placeRef?.id, 'venue-jazz-1');
    },
  );

  testWidgets(
    'physical mode venue picker remains tappable when bootstrap venues are empty and search loads remote candidates',
    (tester) async {
      final eventsRepository =
          _EmptyBootstrapSearchDrivenPhysicalHostCandidatesEventsRepository();
      final taxonomiesRepository = _FakeTaxonomiesRepository();
      final controller = TenantAdminEventsController(
        eventsRepository: eventsRepository,
        taxonomiesRepository: taxonomiesRepository,
      );

      eventsRepository.eventTypes = [
        TenantAdminEventType(
          idValue: tenantAdminOptionalText('507f1f77bcf86cd799439018'),
          nameValue: tenantAdminRequiredText('Live'),
          slugValue: tenantAdminRequiredText('live'),
          descriptionValue: tenantAdminOptionalText('Tipo de evento: Live'),
        ),
      ];

      GetIt.I.registerSingleton<TenantAdminEventsController>(controller);

      await _pumpWithAutoRoute(
        tester,
        const Scaffold(body: TenantAdminEventFormScreen()),
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
      expect(eventsRepository.physicalHostSearchRequests, [('', 1)]);

      await tester.enterText(
        find.byKey(const Key('tenantAdminEventLocationSearchField')),
        'Jazz',
      );
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      expect(eventsRepository.physicalHostSearchRequests.last, ('jazz', 1));
      expect(find.bySemanticsLabel('Casa do Jazz'), findsWidgets);
      expect(find.bySemanticsLabel('Jazz sem POI'), findsNothing);
    },
  );

  testWidgets('physical mode venue picker loads later venue pages on scroll', (
    tester,
  ) async {
    final eventsRepository = _PagedPhysicalHostCandidatesEventsRepository();
    final taxonomiesRepository = _FakeTaxonomiesRepository();
    final controller = TenantAdminEventsController(
      eventsRepository: eventsRepository,
      taxonomiesRepository: taxonomiesRepository,
    );

    eventsRepository.eventTypes = [
      TenantAdminEventType(
        idValue: tenantAdminOptionalText('507f1f77bcf86cd799439017'),
        nameValue: tenantAdminRequiredText('Live'),
        slugValue: tenantAdminRequiredText('live'),
      ),
    ];

    GetIt.I.registerSingleton<TenantAdminEventsController>(controller);

    await _pumpWithAutoRoute(
      tester,
      const Scaffold(body: TenantAdminEventFormScreen()),
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

    expect(find.bySemanticsLabel('Venue Page Two Target'), findsNothing);
    expect(eventsRepository.physicalHostPageRequests, [('', 1)]);

    await tester.scrollUntilVisible(
      find.bySemanticsLabel('Venue Page Two Target'),
      250,
      scrollable: find.descendant(
        of: find.byKey(const Key('tenantAdminEventLocationOptionsList')),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.pumpAndSettle();

    expect(eventsRepository.physicalHostPageRequests, [('', 1), ('', 2)]);
    expect(find.bySemanticsLabel('Venue Page Two Target'), findsWidgets);
  });

  testWidgets('submits without description text (content optional)', (
    tester,
  ) async {
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
      const Scaffold(body: TenantAdminEventFormScreen()),
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
    'related account profile group selector keeps checkbox state canonical',
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
        const Scaffold(body: TenantAdminEventFormScreen()),
      );

      final groupId = await _addEventProfileGroup(
        tester,
        controller,
        label: 'Participantes',
      );
      await _selectProfileInGroup(
        tester,
        keyPrefix: 'EventProfile',
        groupId: groupId,
        profileId: 'artist-1',
      );

      expect(
        controller
            .eventFormStateStreamValue
            .value
            .selectedRelatedAccountProfileIds,
        ['artist-1'],
      );

      final candidateKey = Key(
        'EventProfileNestedAccountCandidate_${groupId}_artist-1',
      );
      final selectedTile = tester.widget<CheckboxListTile>(
        find.byKey(candidateKey),
      );
      expect(selectedTile.value, isTrue);

      await tester.tap(find.byKey(candidateKey));
      await tester.pumpAndSettle();

      expect(
        controller
            .eventFormStateStreamValue
            .value
            .selectedRelatedAccountProfileIds,
        isEmpty,
      );
    },
  );

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
        const Scaffold(body: TenantAdminEventFormScreen()),
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

      final groupId = await _addEventProfileGroup(
        tester,
        controller,
        label: 'Participantes',
      );
      expect(groupId, isNotEmpty);
      expect(find.text('Nenhum perfil disponivel.'), findsOneWidget);
    },
  );

  testWidgets(
    'related account profile group selector filters loaded candidates after typing',
    (tester) async {
      final eventsRepository = _MultipleRelatedCandidatesEventsRepository();
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
        const Scaffold(body: TenantAdminEventFormScreen()),
      );

      final groupId = await _addEventProfileGroup(
        tester,
        controller,
        label: 'Participantes',
      );
      await _openProfileGroupSelector(
        tester,
        keyPrefix: 'EventProfile',
        groupId: groupId,
      );

      expect(find.text('Artist A'), findsOneWidget);
      expect(find.text('Artist B'), findsOneWidget);

      await _searchProfileGroupSelector(
        tester,
        keyPrefix: 'EventProfile',
        groupId: groupId,
        query: 'B',
      );

      expect(find.text('Artist B'), findsOneWidget);
      expect(find.text('Artist A'), findsNothing);
    },
  );

  testWidgets(
    'adding a filtered related account profile keeps its summary visible on the form',
    (tester) async {
      final eventsRepository = _MultipleRelatedCandidatesEventsRepository();
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
        const Scaffold(body: TenantAdminEventFormScreen()),
      );

      final groupId = await _addEventProfileGroup(
        tester,
        controller,
        label: 'Participantes',
      );
      await _openProfileGroupSelector(
        tester,
        keyPrefix: 'EventProfile',
        groupId: groupId,
      );
      await _searchProfileGroupSelector(
        tester,
        keyPrefix: 'EventProfile',
        groupId: groupId,
        query: 'B',
      );
      await tester.tap(
        find.byKey(
          Key('EventProfileNestedAccountCandidate_${groupId}_artist-2'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.widgetWithText(InputChip, 'Artist B'), findsOneWidget);
      expect(find.text('Perfil não disponível na lista atual'), findsNothing);
    },
  );

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
        const Scaffold(body: TenantAdminEventFormScreen()),
      );

      final groupId = await _addEventProfileGroup(
        tester,
        controller,
        label: 'Participantes',
      );
      await _openProfileGroupSelector(
        tester,
        keyPrefix: 'EventProfile',
        groupId: groupId,
      );
      await _searchProfileGroupSelector(
        tester,
        keyPrefix: 'EventProfile',
        groupId: groupId,
        query: '021',
      );
      await tester.tap(
        find.byKey(
          Key(
            'EventProfileNestedAccountCandidate_${groupId}_artist-page-2-021',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.widgetWithText(InputChip, 'Legacy Artist Page 2 021'),
        findsOneWidget,
      );
      expect(find.text('Perfil não disponível na lista atual'), findsNothing);
    },
  );

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
        profileGroups: [
          TenantAdminNestedProfileGroup(
            idValue: TenantAdminNestedProfileGroupTextValue('artists'),
            labelValue: TenantAdminNestedProfileGroupTextValue('Artistas'),
            orderValue: TenantAdminNestedProfileGroupOrderValue(0),
            accountProfileIdValues: [
              TenantAdminNestedProfileGroupTextValue('artist-zulu'),
            ],
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
    },
  );

  testWidgets(
    'mounted edit reuse reinitializes controllers when existing event changes',
    (tester) async {
      final eventsRepository = _FakeEventsRepository();
      final taxonomiesRepository = _FakeTaxonomiesRepository();
      final controller = TenantAdminEventsController(
        eventsRepository: eventsRepository,
        taxonomiesRepository: taxonomiesRepository,
      );

      final eventType = TenantAdminEventType(
        idValue: tenantAdminOptionalText('507f1f77bcf86cd799439104'),
        nameValue: tenantAdminRequiredText('Show'),
        slugValue: tenantAdminRequiredText('show'),
      );
      eventsRepository.eventTypes = [eventType];

      final firstEvent = _buildMountedReuseEditEvent(
        type: eventType,
        eventId: 'evt-mounted-reuse',
        title: 'Evento occ-1',
        firstOccurrenceId: 'occ-1',
        secondOccurrenceId: 'occ-2',
      );
      final secondEvent = _buildMountedReuseEditEvent(
        type: eventType,
        eventId: 'evt-mounted-reuse',
        title: 'Evento occ-2',
        firstOccurrenceId: 'occ-2',
        secondOccurrenceId: 'occ-1',
      );
      final currentEvent = ValueNotifier<TenantAdminEvent>(firstEvent);

      GetIt.I.registerSingleton<TenantAdminEventsController>(controller);

      await _pumpWithAutoRoute(
        tester,
        ValueListenableBuilder<TenantAdminEvent>(
          valueListenable: currentEvent,
          builder: (context, event, _) {
            return Scaffold(
              body: TenantAdminEventFormScreen(existingEvent: event),
            );
          },
        ),
      );
      await tester.pumpAndSettle();

      expect(controller.eventTitleController.text, 'Evento occ-1');
      expect(
        controller
            .eventFormStateStreamValue
            .value
            .occurrences
            .first
            .occurrenceId,
        'occ-1',
      );

      await tester.enterText(find.byType(TextFormField).first, 'Titulo sujo');
      await tester.pump();
      expect(controller.eventTitleController.text, 'Titulo sujo');

      currentEvent.value = secondEvent;
      await tester.pump();
      await tester.pumpAndSettle();

      expect(controller.eventTitleController.text, 'Evento occ-2');
      expect(
        controller
            .eventFormStateStreamValue
            .value
            .occurrences
            .first
            .occurrenceId,
        'occ-2',
      );
    },
  );

  testWidgets(
    'mounted own-create reuse ignores stale dependency loads when account slug changes',
    (tester) async {
      final eventsRepository = _AccountScopedDelayedCandidatesEventsRepository(
        physicalHostCandidatesByAccountSlug:
            <String, List<TenantAdminAccountProfile>>{
              'school-a': <TenantAdminAccountProfile>[
                tenantAdminAccountProfileFromRaw(
                  id: 'venue-school-a',
                  accountId: 'acc-venue-school-a',
                  profileType: 'venue',
                  displayName: 'Venue School A',
                  location: tenantAdminLocationFromRaw(
                    latitude: -20.611121,
                    longitude: -40.498617,
                  ),
                ),
              ],
              'school-b': <TenantAdminAccountProfile>[
                tenantAdminAccountProfileFromRaw(
                  id: 'venue-school-b',
                  accountId: 'acc-venue-school-b',
                  profileType: 'venue',
                  displayName: 'Venue School B',
                  location: tenantAdminLocationFromRaw(
                    latitude: -20.612121,
                    longitude: -40.499617,
                  ),
                ),
              ],
            },
        delayByAccountSlug: <String, Duration>{
          'school-a': const Duration(milliseconds: 200),
          'school-b': Duration.zero,
        },
      );
      final taxonomiesRepository = _FakeTaxonomiesRepository();
      final controller = TenantAdminEventsController(
        eventsRepository: eventsRepository,
        taxonomiesRepository: taxonomiesRepository,
      );
      controller.eventTypeCatalogStreamValue.addValue(const []);

      final currentAccountSlug = ValueNotifier<String>('school-a');

      GetIt.I.registerSingleton<TenantAdminEventsController>(controller);

      await _pumpWithAutoRoute(
        tester,
        ValueListenableBuilder<String>(
          valueListenable: currentAccountSlug,
          builder: (context, accountSlug, _) {
            return Scaffold(
              body: TenantAdminEventFormScreen(
                accountSlugForOwnCreate: accountSlug,
              ),
            );
          },
        ),
      );

      await tester.pump();
      currentAccountSlug.value = 'school-b';
      await tester.pump();
      await tester.pump();

      expect(
        controller.eventFormStateStreamValue.value.selectedVenue?.id,
        'venue-school-b',
      );
      expect(
        controller.venueCandidatesStreamValue.value.map((venue) => venue.id),
        ['venue-school-b'],
      );

      await tester.pump(const Duration(milliseconds: 250));
      await tester.pumpAndSettle();

      expect(
        controller.eventFormStateStreamValue.value.selectedVenue?.id,
        'venue-school-b',
      );
      expect(
        controller.venueCandidatesStreamValue.value.map((venue) => venue.id),
        ['venue-school-b'],
      );
    },
  );

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
        profileGroups: [
          TenantAdminNestedProfileGroup(
            idValue: TenantAdminNestedProfileGroupTextValue('artists'),
            labelValue: TenantAdminNestedProfileGroupTextValue('Artistas'),
            orderValue: TenantAdminNestedProfileGroupOrderValue(0),
            accountProfileIdValues: [
              TenantAdminNestedProfileGroupTextValue('artist-zulu'),
            ],
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
    },
  );

  testWidgets(
    'editing occurrence groups keeps occurrence-owned selected summaries visible',
    (tester) async {
      final eventsRepository = _EmptyCandidatesEventsRepository();
      final taxonomiesRepository = _FakeTaxonomiesRepository();
      final controller = TenantAdminEventsController(
        eventsRepository: eventsRepository,
        taxonomiesRepository: taxonomiesRepository,
      );

      eventsRepository.eventTypes = [
        TenantAdminEventType(
          idValue: tenantAdminOptionalText('507f1f77bcf86cd799439103'),
          nameValue: tenantAdminRequiredText('Show'),
          slugValue: tenantAdminRequiredText('show'),
        ),
      ];

      final bandaAzul = tenantAdminAccountProfileFromRaw(
        id: 'occ-banda-azul',
        accountId: 'acc-occ-banda-azul',
        profileType: 'artist',
        displayName: 'Manual v0208 Banda Azul',
        slug: 'manual-v0208-banda-azul',
      );
      final bandaVerde = tenantAdminAccountProfileFromRaw(
        id: 'occ-banda-verde',
        accountId: 'acc-occ-banda-verde',
        profileType: 'artist',
        displayName: 'Manual v0208 Banda Verde',
        slug: 'manual-v0208-banda-verde',
      );
      final expositorSol = tenantAdminAccountProfileFromRaw(
        id: 'occ-expositor-sol',
        accountId: 'acc-occ-expositor-sol',
        profileType: 'exhibitor',
        displayName: 'Manual v0208 Expositor Sol',
        slug: 'manual-v0208-expositor-sol',
      );
      final expositorMar = tenantAdminAccountProfileFromRaw(
        id: 'occ-expositor-mar',
        accountId: 'acc-occ-expositor-mar',
        profileType: 'exhibitor',
        displayName: 'Manual v0208 Expositor Mar',
        slug: 'manual-v0208-expositor-mar',
      );

      final existingEvent = TenantAdminEvent(
        eventIdValue: tenantAdminRequiredText('evt-edit-occurrence-groups'),
        slugValue: tenantAdminRequiredText('event-edit-occurrence-groups'),
        titleValue: tenantAdminRequiredText('Evento em edição'),
        contentValue: tenantAdminOptionalText('Conteúdo'),
        type: TenantAdminEventType(
          idValue: tenantAdminOptionalText('507f1f77bcf86cd799439103'),
          nameValue: tenantAdminRequiredText('Show'),
          slugValue: tenantAdminRequiredText('show'),
        ),
        occurrences: <TenantAdminEventOccurrence>[
          TenantAdminEventOccurrence(
            dateTimeStartValue: tenantAdminDateTime(
              DateTime.utc(2026, 6, 7, 3),
            ),
          ),
          TenantAdminEventOccurrence(
            occurrenceIdValue: tenantAdminOptionalText('occurrence-2'),
            dateTimeStartValue: tenantAdminDateTime(
              DateTime.utc(2026, 6, 8, 3),
            ),
            relatedAccountProfileIdValues: [
              TenantAdminAccountProfileIdValue(bandaAzul.id),
              TenantAdminAccountProfileIdValue(bandaVerde.id),
              TenantAdminAccountProfileIdValue(expositorSol.id),
              TenantAdminAccountProfileIdValue(expositorMar.id),
            ],
            relatedAccountProfiles: [
              bandaAzul,
              bandaVerde,
              expositorSol,
              expositorMar,
            ],
            profileGroups: [
              TenantAdminNestedProfileGroup(
                idValue: TenantAdminNestedProfileGroupTextValue('outro-grupo'),
                labelValue: TenantAdminNestedProfileGroupTextValue(
                  'Outro Grupo',
                ),
                orderValue: TenantAdminNestedProfileGroupOrderValue(0),
                accountProfileIdValues: [
                  TenantAdminNestedProfileGroupTextValue(bandaAzul.id),
                  TenantAdminNestedProfileGroupTextValue(bandaVerde.id),
                  TenantAdminNestedProfileGroupTextValue(expositorSol.id),
                  TenantAdminNestedProfileGroupTextValue(expositorMar.id),
                ],
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

      await tester.scrollUntilVisible(
        find.byKey(const Key('tenantAdminEventOccurrenceCard_1')),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const Key('tenantAdminEventOccurrenceCard_1')),
      );
      await tester.pumpAndSettle();

      expect(find.text('4 perfil(is) selecionado(s)'), findsOneWidget);
      expect(
        find.widgetWithText(InputChip, 'Manual v0208 Banda Azul'),
        findsOneWidget,
      );
      expect(
        find.widgetWithText(InputChip, 'Manual v0208 Banda Verde'),
        findsOneWidget,
      );
      expect(
        find.widgetWithText(InputChip, 'Manual v0208 Expositor Sol'),
        findsOneWidget,
      );
      expect(
        find.widgetWithText(InputChip, 'Manual v0208 Expositor Mar'),
        findsOneWidget,
      );
    },
  );

  testWidgets('uses rich text editor for event description content', (
    tester,
  ) async {
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
      const Scaffold(body: TenantAdminEventFormScreen()),
    );

    expect(find.byType(TenantAdminRichTextEditor), findsOneWidget);
    expect(find.text('Descrição (opcional)'), findsOneWidget);
    expect(
      find.text('Limite: 100 KB por campo. O backend valida o envio final.'),
      findsOneWidget,
    );
    expect(find.textContaining('/ 100 KB'), findsOneWidget);
    expect(
      find.widgetWithText(TextFormField, 'Descrição (opcional)'),
      findsNothing,
    );
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
        const Scaffold(body: TenantAdminEventFormScreen()),
      );

      await _fillRequiredFields(
        tester,
        controller: controller,
        includeDescription: false,
      );

      controller.eventContentController.text =
          '<p><strong>Olá 🎉</strong> <u>mundo</u> <a href="https://example.com">link</a> <s>riscado</s></p>';
      await tester.pumpAndSettle();

      final expected =
          '<p><strong>Olá 🎉</strong> mundo link <s>riscado</s></p>';
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
    },
  );
}

Future<void> _pumpWithAutoRoute(WidgetTester tester, Widget child) async {
  final router = RootStackRouter.build(
    routes: [
      NamedRouteDef(
        name: 'events-form-test',
        path: '/',
        meta: canonicalRouteMeta(
          family: CanonicalRouteFamily.tenantAdminEventsInternal,
          chromeMode: RouteChromeMode.fullscreen,
        ),
        builder: (context, routeData) => child,
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
    find.widgetWithText(TextFormField, 'Título'),
    'Evento',
  );
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

Future<String> _addEventProfileGroup(
  WidgetTester tester,
  TenantAdminEventsController controller, {
  String? label,
}) async {
  await tester.scrollUntilVisible(
    find.byKey(const Key('TenantAdminEventProfileGroupAdd')),
    250,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('TenantAdminEventProfileGroupAdd')));
  await tester.pumpAndSettle();

  final group = controller.eventFormStateStreamValue.value.profileGroups.last;
  if (label != null) {
    await tester.enterText(
      find.byKey(Key('EventProfileNestedGroupLabel_${group.id}')),
      label,
    );
    await tester.pumpAndSettle();
  }
  return group.id;
}

Future<String> _addOccurrenceProfileGroup(
  WidgetTester tester,
  TenantAdminEventsController controller, {
  required int occurrenceIndex,
  String? label,
}) async {
  await tester.scrollUntilVisible(
    find.byKey(const Key('TenantAdminOccurrenceProfileGroupAdd')),
    250,
    scrollable: find.byType(Scrollable).last,
  );
  await tester.pumpAndSettle();
  await tester.tap(
    find.byKey(const Key('TenantAdminOccurrenceProfileGroupAdd')),
  );
  await tester.pumpAndSettle();

  final group = controller
      .eventFormStateStreamValue
      .value
      .occurrences[occurrenceIndex]
      .profileGroups
      .last;
  if (label != null) {
    await tester.enterText(
      find.byKey(Key('OccurrenceProfileNestedGroupLabel_${group.id}')),
      label,
    );
    await tester.pumpAndSettle();
  }
  return group.id;
}

Future<void> _openProfileGroupSelector(
  WidgetTester tester, {
  required String keyPrefix,
  required String groupId,
}) async {
  await tester.ensureVisible(
    find.byKey(Key('${keyPrefix}NestedAccountSelector_$groupId')),
  );
  await tester.pumpAndSettle();
  await tester.tap(
    find.byKey(Key('${keyPrefix}NestedAccountSelector_$groupId')),
  );
  await tester.pumpAndSettle();
}

Future<void> _selectProfileInGroup(
  WidgetTester tester, {
  required String keyPrefix,
  required String groupId,
  required String profileId,
}) async {
  final candidate = find.byKey(
    Key('${keyPrefix}NestedAccountCandidate_${groupId}_$profileId'),
  );
  if (candidate.evaluate().isEmpty) {
    await _openProfileGroupSelector(
      tester,
      keyPrefix: keyPrefix,
      groupId: groupId,
    );
  }
  await tester.ensureVisible(candidate);
  await tester.pumpAndSettle();
  await tester.tap(candidate);
  await tester.pumpAndSettle();
}

Future<void> _searchProfileGroupSelector(
  WidgetTester tester, {
  required String keyPrefix,
  required String groupId,
  required String query,
}) async {
  await tester.enterText(
    find.byKey(Key('${keyPrefix}NestedAccountSearch_$groupId')),
    query,
  );
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
  await tester.ensureVisible(
    find.byKey(const Key('tenantAdminOccurrenceAddProgrammingButton')),
  );
  await tester.pumpAndSettle();
  await tester.tap(
    find.byKey(const Key('tenantAdminOccurrenceAddProgrammingButton')),
  );
  await tester.pumpAndSettle();
  await _setProgrammingTimedState(tester, isTimed: true);
  await tester.enterText(
    find.byKey(const Key('tenantAdminProgrammingTimeField')),
    time,
  );
  await _enterProgrammingTitle(tester, title);
  await _tapProgrammingSaveButton(tester);
}

Future<void> _addOccurrenceProgrammingUntimedTitleOnly(
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
  await tester.ensureVisible(
    find.byKey(const Key('tenantAdminOccurrenceAddProgrammingButton')),
  );
  await tester.pumpAndSettle();
  await tester.tap(
    find.byKey(const Key('tenantAdminOccurrenceAddProgrammingButton')),
  );
  await tester.pumpAndSettle();
  await _setProgrammingTimedState(tester, isTimed: true);
  await tester.enterText(
    find.byKey(const Key('tenantAdminProgrammingTimeField')),
    time,
  );
  await _enterProgrammingTitle(tester, title);
  await _setProgrammingTimedState(tester, isTimed: false);
  await _tapProgrammingSaveButton(tester);
}

Future<void> _enterProgrammingTitle(WidgetTester tester, String title) async {
  final editor = _programmingTitleEditorFinder();
  final editorWidget = tester.widget(editor) as dynamic;
  editorWidget.controller.text = title;
  await tester.pumpAndSettle();
}

Finder _programmingTitleEditorFinder() {
  return find.byWidgetPredicate(
    (widget) =>
        widget is TenantAdminRichTextEditor &&
        widget.key == const Key('tenantAdminProgrammingTitleEditor'),
    description:
        'TenantAdminRichTextEditor keyed tenantAdminProgrammingTitleEditor',
  );
}

Matcher _programmingTitleContains(String expected) {
  return predicate<String?>(
    (value) => _programmingTitlePlainText(value).contains(expected),
    'programming title containing "$expected" after HTML normalization',
  );
}

String _programmingTitlePlainText(String? title) {
  final normalized = title?.trim();
  if (normalized == null || normalized.isEmpty) {
    return '';
  }
  return normalized
      .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'</p\s*>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'<[^>]+>'), '')
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

Future<void> _ensureOccurrenceProgrammingGroup(
  WidgetTester tester, {
  String label = 'Grupo de programação',
}) async {
  if (find.text(label).evaluate().isNotEmpty) {
    return;
  }

  await tester.scrollUntilVisible(
    find.byKey(const Key('TenantAdminOccurrenceProfileGroupAdd')),
    250,
    scrollable: find.byType(Scrollable).last,
  );
  await tester.pumpAndSettle();
  await tester.tap(
    find.byKey(const Key('TenantAdminOccurrenceProfileGroupAdd')),
  );
  await tester.pumpAndSettle();

  final labelField = find
      .byWidgetPredicate(
        (widget) =>
            widget is TextFormField &&
            widget.key.toString().contains(
              'OccurrenceProfileNestedGroupLabel_',
            ),
      )
      .last;
  await tester.enterText(labelField, label);
  await tester.pumpAndSettle();
}

Future<void> _addOccurrenceProgrammingWithNewProfile(
  WidgetTester tester, {
  required String time,
  required String profileName,
}) async {
  await _ensureOccurrenceProgrammingGroup(tester);
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
  await _setProgrammingTimedState(tester, isTimed: true);
  await tester.enterText(
    find.byKey(const Key('tenantAdminProgrammingTimeField')),
    time,
  );
  await _tapFirstProgrammingAddOccurrenceProfileButton(tester);
  await _tapVisibleText(tester, profileName);
  await _tapProgrammingSaveButton(tester);
}

Future<void> _tapFirstProgrammingAddOccurrenceProfileButton(
  WidgetTester tester,
) async {
  final addProfileButton = find
      .byWidgetPredicate(
        (widget) =>
            widget is OutlinedButton &&
            widget.key.toString().contains(
              'tenantAdminProgrammingAddOccurrenceProfileButton_',
            ),
      )
      .first;
  await tester.scrollUntilVisible(
    addProfileButton,
    200,
    scrollable: find.byType(Scrollable).last,
  );
  await tester.pumpAndSettle();
  await tester.ensureVisible(addProfileButton);
  await tester.pumpAndSettle();
  await tester.tap(addProfileButton);
  await tester.pumpAndSettle();
}

Future<void> _tapVisibleText(WidgetTester tester, String text) async {
  final textFinder = find.text(text).last;
  final tappableAncestor = find.ancestor(
    of: textFinder,
    matching: find.byWidgetPredicate(
      (widget) =>
          widget is ListTile ||
          widget is InkWell ||
          widget is OutlinedButton ||
          widget is FilledButton,
    ),
  );
  final choice = tappableAncestor.evaluate().isNotEmpty
      ? tappableAncestor.last
      : textFinder;
  await _bringIntoView(tester, choice);
  await tester.pumpAndSettle();
  await tester.tap(choice.hitTestable().last, warnIfMissed: false);
  await tester.pumpAndSettle();
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
  await _setProgrammingTimedState(tester, isTimed: true);
  await tester.enterText(
    find.byKey(const Key('tenantAdminProgrammingTimeField')),
    time,
  );
  final linkProfileButton = find.byKey(
    const Key('tenantAdminProgrammingLinkOccurrenceProfileButton'),
  );
  await _bringIntoView(tester, linkProfileButton);
  await tester.pumpAndSettle();
  await tester.tap(linkProfileButton.hitTestable().last, warnIfMissed: false);
  await tester.pumpAndSettle();
  await _tapVisibleText(tester, profileName);
  await _tapProgrammingSaveButton(tester);
}

Future<void> _bringIntoView(WidgetTester tester, Finder finder) async {
  for (var attempt = 0; attempt < 8; attempt++) {
    await tester.pumpAndSettle();
    final hitTestable = finder.hitTestable();
    if (hitTestable.evaluate().isNotEmpty) {
      return;
    }
    final rect = tester.getRect(finder);
    final scrollable = find.byType(Scrollable).last;
    final dy = rect.bottom > 560 ? -160.0 : 160.0;
    await tester.drag(scrollable, Offset(0, dy));
  }
  await tester.pumpAndSettle();
}

Future<void> _setProgrammingTimedState(
  WidgetTester tester, {
  required bool isTimed,
}) async {
  final timedToggle = find.byKey(
    const Key('tenantAdminProgrammingTimedToggle'),
  );
  await tester.ensureVisible(timedToggle);
  await tester.pumpAndSettle();
  final toggle = tester.widget<SwitchListTile>(timedToggle);
  if (toggle.value == isTimed) {
    return;
  }
  await tester.tap(timedToggle);
  await tester.pumpAndSettle();
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
  Object? createEventError;
  Object? createOwnEventError;
  Object? updateEventError;
  int createEventCalls = 0;
  int createOwnEventCalls = 0;
  int updateEventCalls = 0;

  @override
  Future<TenantAdminEvent> createEvent({
    required TenantAdminEventDraft draft,
  }) async {
    createEventCalls += 1;
    lastCreateDraft = draft;
    if (createEventError != null) {
      throw createEventError!;
    }
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
    if (createOwnEventError != null) {
      throw createOwnEventError!;
    }
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
    final sourceItems = switch (candidateType) {
      TenantAdminEventAccountProfileCandidateType.physicalHost =>
        physicalHostCandidates,
      TenantAdminEventAccountProfileCandidateType.relatedAccountProfile =>
        relatedAccountProfileCandidates,
    };
    final normalizedSearch = search?.value.trim().toLowerCase() ?? '';
    final items = normalizedSearch.isEmpty
        ? sourceItems
        : sourceItems
              .where((profile) {
                final displayName = profile.displayName.toLowerCase();
                final profileType = profile.profileType.toLowerCase();
                return displayName.contains(normalizedSearch) ||
                    profileType.contains(normalizedSearch);
              })
              .toList(growable: false);
    return tenantAdminPagedResultFromRaw(items: items, hasMore: false);
  }

  @override
  Future<TenantAdminEvent> updateEvent({
    required TenantAdminEventsRepoString eventId,
    required TenantAdminEventDraft draft,
  }) async {
    updateEventCalls += 1;
    lastUpdateEventId = eventId.value;
    lastUpdateDraft = draft;
    if (updateEventError != null) {
      throw updateEventError!;
    }
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

TenantAdminEvent _buildMountedReuseEditEvent({
  required TenantAdminEventType type,
  required String eventId,
  required String title,
  required String firstOccurrenceId,
  required String secondOccurrenceId,
}) {
  return TenantAdminEvent(
    eventIdValue: tenantAdminRequiredText(eventId),
    slugValue: tenantAdminRequiredText('$eventId-slug'),
    titleValue: tenantAdminRequiredText(title),
    contentValue: tenantAdminOptionalText('Conteudo de $title'),
    type: type,
    occurrences: <TenantAdminEventOccurrence>[
      TenantAdminEventOccurrence(
        occurrenceIdValue: tenantAdminOptionalText(firstOccurrenceId),
        dateTimeStartValue: tenantAdminDateTime(DateTime.utc(2026, 7, 1, 20)),
      ),
      TenantAdminEventOccurrence(
        occurrenceIdValue: tenantAdminOptionalText(secondOccurrenceId),
        dateTimeStartValue: tenantAdminDateTime(DateTime.utc(2026, 7, 2, 20)),
      ),
    ],
    publication: TenantAdminEventPublication(
      statusValue: tenantAdminRequiredText('draft'),
    ),
  );
}

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
        TenantAdminTaxonomiesScopedLookupRepositoryContract,
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
    return tenantAdminPagedResultFromRaw(items: taxonomies, hasMore: false);
  }

  @override
  Future<List<TenantAdminTaxonomyDefinition>> fetchTaxonomiesBySlugs({
    required List<TenantAdminTaxRepoString> slugs,
    TenantAdminTaxRepoString? appliesTo,
  }) async {
    final allowedSlugs = slugs
        .map((entry) => entry.value.trim())
        .where((entry) => entry.isNotEmpty)
        .toSet();
    final appliesToFilter = appliesTo?.value.trim();
    return (await fetchTaxonomies())
        .where((taxonomy) => allowedSlugs.contains(taxonomy.slug))
        .where(
          (taxonomy) =>
              appliesToFilter == null ||
              appliesToFilter.isEmpty ||
              taxonomy.appliesTo.contains(appliesToFilter),
        )
        .toList(growable: false);
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
    return tenantAdminPagedResultFromRaw(items: terms, hasMore: false);
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

class _SearchDrivenPhysicalHostCandidatesEventsRepository
    extends _FakeEventsRepository {
  final List<(String, int)> physicalHostSearchRequests = <(String, int)>[];
  late final List<TenantAdminAccountProfile> _physicalHostCatalog =
      <TenantAdminAccountProfile>[
        tenantAdminAccountProfileFromRaw(
          id: 'venue-bootstrap-a',
          accountId: 'acc-venue-bootstrap-a',
          profileType: 'venue',
          displayName: 'Venue Bootstrap A',
          location: tenantAdminLocationFromRaw(
            latitude: -20.611121,
            longitude: -40.498617,
          ),
        ),
        tenantAdminAccountProfileFromRaw(
          id: 'venue-bootstrap-b',
          accountId: 'acc-venue-bootstrap-b',
          profileType: 'venue',
          displayName: 'Arena Bootstrap B',
          location: tenantAdminLocationFromRaw(
            latitude: -20.612521,
            longitude: -40.499217,
          ),
        ),
        tenantAdminAccountProfileFromRaw(
          id: 'venue-jazz-1',
          accountId: 'acc-venue-jazz-1',
          profileType: 'venue',
          displayName: 'Casa do Jazz',
          location: tenantAdminLocationFromRaw(
            latitude: -20.612121,
            longitude: -40.498917,
          ),
        ),
        tenantAdminAccountProfileFromRaw(
          id: 'non-poi-jazz-1',
          accountId: 'acc-non-poi-jazz-1',
          profileType: 'artist',
          displayName: 'Jazz sem POI',
        ),
      ];

  @override
  Future<TenantAdminPagedResult<TenantAdminAccountProfile>>
  fetchEventAccountProfileCandidatesPage({
    required TenantAdminEventAccountProfileCandidateType candidateType,
    required TenantAdminEventsRepoInt page,
    required TenantAdminEventsRepoInt pageSize,
    TenantAdminEventsRepoString? search,
    TenantAdminEventsRepoString? accountSlug,
  }) async {
    if (candidateType !=
        TenantAdminEventAccountProfileCandidateType.physicalHost) {
      return super.fetchEventAccountProfileCandidatesPage(
        candidateType: candidateType,
        page: page,
        pageSize: pageSize,
        search: search,
        accountSlug: accountSlug,
      );
    }

    final normalizedSearch = search?.value.trim().toLowerCase() ?? '';
    physicalHostSearchRequests.add((normalizedSearch, page.value));

    final eligibleCatalog = _physicalHostCatalog
        .where((profile) => profile.location != null)
        .toList(growable: false);
    final items = normalizedSearch.isEmpty
        ? eligibleCatalog.take(2).toList(growable: false)
        : eligibleCatalog
              .where((profile) {
                final displayName = profile.displayName.toLowerCase();
                final profileType = profile.profileType.toLowerCase();
                return displayName.contains(normalizedSearch) ||
                    profileType.contains(normalizedSearch);
              })
              .toList(growable: false);

    return tenantAdminPagedResultFromRaw(items: items, hasMore: false);
  }
}

class _EmptyBootstrapSearchDrivenPhysicalHostCandidatesEventsRepository
    extends _FakeEventsRepository {
  final List<(String, int)> physicalHostSearchRequests = <(String, int)>[];
  late final List<TenantAdminAccountProfile> _physicalHostCatalog =
      <TenantAdminAccountProfile>[
        tenantAdminAccountProfileFromRaw(
          id: 'venue-jazz-1',
          accountId: 'acc-venue-jazz-1',
          profileType: 'venue',
          displayName: 'Casa do Jazz',
          location: tenantAdminLocationFromRaw(
            latitude: -20.612121,
            longitude: -40.498917,
          ),
        ),
        tenantAdminAccountProfileFromRaw(
          id: 'non-poi-jazz-1',
          accountId: 'acc-non-poi-jazz-1',
          profileType: 'artist',
          displayName: 'Jazz sem POI',
        ),
      ];

  @override
  Future<TenantAdminPagedResult<TenantAdminAccountProfile>>
  fetchEventAccountProfileCandidatesPage({
    required TenantAdminEventAccountProfileCandidateType candidateType,
    required TenantAdminEventsRepoInt page,
    required TenantAdminEventsRepoInt pageSize,
    TenantAdminEventsRepoString? search,
    TenantAdminEventsRepoString? accountSlug,
  }) async {
    if (candidateType !=
        TenantAdminEventAccountProfileCandidateType.physicalHost) {
      return super.fetchEventAccountProfileCandidatesPage(
        candidateType: candidateType,
        page: page,
        pageSize: pageSize,
        search: search,
        accountSlug: accountSlug,
      );
    }

    final normalizedSearch = search?.value.trim().toLowerCase() ?? '';
    physicalHostSearchRequests.add((normalizedSearch, page.value));

    final eligibleCatalog = _physicalHostCatalog
        .where((profile) => profile.location != null)
        .toList(growable: false);
    final items = normalizedSearch.isEmpty
        ? const <TenantAdminAccountProfile>[]
        : eligibleCatalog
              .where((profile) {
                final displayName = profile.displayName.toLowerCase();
                final profileType = profile.profileType.toLowerCase();
                return displayName.contains(normalizedSearch) ||
                    profileType.contains(normalizedSearch);
              })
              .toList(growable: false);

    return tenantAdminPagedResultFromRaw(items: items, hasMore: false);
  }
}

class _PagedPhysicalHostCandidatesEventsRepository
    extends _FakeEventsRepository {
  final List<(String, int)> physicalHostPageRequests = <(String, int)>[];
  late final List<TenantAdminAccountProfile> _physicalHostCatalog =
      List<TenantAdminAccountProfile>.generate(
        12,
        (index) => tenantAdminAccountProfileFromRaw(
          id: index == 10 ? 'venue-page-two-target' : 'venue-page-$index',
          accountId: index == 10
              ? 'acc-venue-page-two-target'
              : 'acc-venue-$index',
          profileType: 'venue',
          displayName: index == 10
              ? 'Venue Page Two Target'
              : 'Venue Page ${index + 1}',
          location: tenantAdminLocationFromRaw(
            latitude: -20.611121 - (index * 0.0001),
            longitude: -40.498617 - (index * 0.0001),
          ),
        ),
      );

  @override
  Future<TenantAdminPagedResult<TenantAdminAccountProfile>>
  fetchEventAccountProfileCandidatesPage({
    required TenantAdminEventAccountProfileCandidateType candidateType,
    required TenantAdminEventsRepoInt page,
    required TenantAdminEventsRepoInt pageSize,
    TenantAdminEventsRepoString? search,
    TenantAdminEventsRepoString? accountSlug,
  }) async {
    if (candidateType !=
        TenantAdminEventAccountProfileCandidateType.physicalHost) {
      return super.fetchEventAccountProfileCandidatesPage(
        candidateType: candidateType,
        page: page,
        pageSize: pageSize,
        search: search,
        accountSlug: accountSlug,
      );
    }

    final normalizedSearch = search?.value.trim().toLowerCase() ?? '';
    physicalHostPageRequests.add((normalizedSearch, page.value));

    final filtered = _physicalHostCatalog
        .where((profile) {
          final displayName = profile.displayName.toLowerCase();
          final profileType = profile.profileType.toLowerCase();
          return normalizedSearch.isEmpty ||
              displayName.contains(normalizedSearch) ||
              profileType.contains(normalizedSearch);
        })
        .toList(growable: false);

    const pageLength = 6;
    final start = (page.value - 1) * pageLength;
    if (start >= filtered.length) {
      return tenantAdminPagedResultFromRaw(
        items: const <TenantAdminAccountProfile>[],
        hasMore: false,
      );
    }
    final end = start + pageLength > filtered.length
        ? filtered.length
        : start + pageLength;

    return tenantAdminPagedResultFromRaw(
      items: filtered.sublist(start, end),
      hasMore: end < filtered.length,
    );
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

class _AccountScopedDelayedCandidatesEventsRepository
    extends _FakeEventsRepository {
  _AccountScopedDelayedCandidatesEventsRepository({
    required this.physicalHostCandidatesByAccountSlug,
    required this.delayByAccountSlug,
  });

  final Map<String, List<TenantAdminAccountProfile>>
  physicalHostCandidatesByAccountSlug;
  final Map<String, Duration> delayByAccountSlug;

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
      final normalizedAccountSlug = accountSlug?.value.trim() ?? '';
      final delay = delayByAccountSlug[normalizedAccountSlug];
      if (delay != null && delay > Duration.zero) {
        await Future<void>.delayed(delay);
      }

      final items =
          physicalHostCandidatesByAccountSlug[normalizedAccountSlug] ??
          const <TenantAdminAccountProfile>[];
      return tenantAdminPagedResultFromRaw(items: items, hasMore: false);
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
