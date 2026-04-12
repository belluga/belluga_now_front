import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/domain/repositories/landlord_auth_repository_contract.dart';
import 'package:belluga_now/domain/repositories/tenant_admin_events_repository_contract.dart';
import 'package:belluga_now/domain/repositories/tenant_admin_taxonomies_repository_contract.dart';
import 'package:belluga_now/domain/services/tenant_admin_tenant_scope_contract.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_account_profile.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_event.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_event_account_profile_candidate_type.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_event_temporal_bucket.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_legacy_event_parties_summary.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_paged_result.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_definition.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_term_definition.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_count_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_value_parsers.dart';
import 'package:belluga_now/infrastructure/repositories/tenant_admin/tenant_admin_events_repository.dart';
import 'package:dio/dio.dart';
import 'package:belluga_now/presentation/tenant_admin/events/controllers/tenant_admin_events_controller.dart';
import 'package:belluga_now/presentation/tenant_admin/events/screens/tenant_admin_events_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await GetIt.I.reset();
  });

  tearDown(() async {
    await GetIt.I.reset();
  });

  testWidgets('create FAB opens the full-page create route', (tester) async {
    final controller = TenantAdminEventsController(
      eventsRepository: _EventsRepositoryWithSeedData(),
      taxonomiesRepository: _NoopTaxonomiesRepository(),
    );

    GetIt.I.registerSingleton<TenantAdminEventsController>(controller);

    await _pumpEventsRouter(tester);

    expect(find.byType(TenantAdminEventsScreen), findsOneWidget);
    await tester.tap(
      find.byKey(const ValueKey<String>('tenant-admin-events-create-fab')),
    );
    await tester.pumpAndSettle();

    expect(find.text('CREATE-EVENT-ROUTE'), findsOneWidget);
  });

  testWidgets('edit action opens the full-page edit route', (tester) async {
    final controller = TenantAdminEventsController(
      eventsRepository: _EventsRepositoryWithSeedData(),
      taxonomiesRepository: _NoopTaxonomiesRepository(),
    );

    GetIt.I.registerSingleton<TenantAdminEventsController>(controller);

    await _pumpEventsRouter(tester);

    await tester.tap(find.text('Seed Event'));
    await tester.pumpAndSettle();

    expect(find.textContaining('EDIT-EVENT-ROUTE:'), findsOneWidget);
  });

  testWidgets(
      'screen groups events by date and applies specific date, venue, and related profile filters',
      (tester) async {
    final repository = _FilterableEventsRepository();
    final controller = TenantAdminEventsController(
      eventsRepository: repository,
      taxonomiesRepository: _NoopTaxonomiesRepository(),
      landlordAuthRepository: _ScreenLandlordAuthRepository(),
    );

    GetIt.I.registerSingleton<TenantAdminEventsController>(controller);

    await _pumpEventsRouter(tester);

    expect(find.byType(TextField), findsNothing);
    expect(find.text('Buscar perfil'), findsNothing);
    expect(find.text('Filtered Event Match'), findsOneWidget);
    expect(find.text('Other Event Miss'), findsOneWidget);
    expect(
      find.byKey(
        const ValueKey<String>('tenant-admin-events-date-section-2026-04-10'),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const ValueKey<String>('tenant-admin-events-date-section-2026-04-12'),
      ),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(
        const ValueKey<String>('tenant-admin-events-date-filter-button'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('10').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(
        const ValueKey<String>('tenant-admin-events-venue-filter-button'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Main Venue Candidate'));
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(
        const ValueKey<String>('tenant-admin-events-related-filter-button'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('DJ Filter Candidate').last);
    await tester.pumpAndSettle();

    expect(find.text('Filtered Event Match'), findsOneWidget);
    expect(find.text('Other Event Miss'), findsNothing);
    expect(
      find.byKey(
        const ValueKey<String>('tenant-admin-events-date-section-2026-04-10'),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const ValueKey<String>('tenant-admin-events-date-section-2026-04-12'),
      ),
      findsNothing,
    );
    expect(repository.lastSpecificDate, '2026-04-10');
    expect(repository.lastVenueProfileId, 'venue-main');
    expect(repository.lastRelatedAccountProfileId, 'artist-main');
  });

  testWidgets(
      'screen keeps date groups continuous across appended pages and resets them when filters change',
      (tester) async {
    final repository = _PagedGroupingEventsRepository();
    final controller = TenantAdminEventsController(
      eventsRepository: repository,
      taxonomiesRepository: _NoopTaxonomiesRepository(),
      landlordAuthRepository: _ScreenLandlordAuthRepository(),
    );

    GetIt.I.registerSingleton<TenantAdminEventsController>(controller);

    await _pumpEventsRouter(tester);

    expect(find.text('Boundary Event Page 2'), findsNothing);
    expect(
      find.byKey(
        const ValueKey<String>('tenant-admin-events-date-section-2026-04-13'),
      ),
      findsOneWidget,
    );
    expect(repository.pageRequests, equals(<(int, String?)>[(1, null)]));

    await controller.loadNextEventsPage();
    await tester.pumpAndSettle();

    expect(find.text('Boundary Event Page 2'), findsOneWidget);
    expect(
      find.byKey(
        const ValueKey<String>('tenant-admin-events-date-section-2026-04-13'),
      ),
      findsOneWidget,
    );
    expect(
      repository.pageRequests,
      equals(<(int, String?)>[(1, null), (2, null)]),
    );

    controller.selectSpecificDateFilter(DateTime(2026, 4, 13));
    await controller.applyFilters();
    await tester.pumpAndSettle();

    expect(
      find.byKey(
        const ValueKey<String>('tenant-admin-events-date-section-2026-04-14'),
      ),
      findsNothing,
    );
    expect(
      find.byKey(
        const ValueKey<String>('tenant-admin-events-date-section-2026-04-13'),
      ),
      findsOneWidget,
    );
    expect(find.text('Boundary Event Page 2'), findsOneWidget);
    expect(
      repository.pageRequests,
      equals(<(int, String?)>[
        (1, null),
        (2, null),
        (1, '2026-04-13'),
      ]),
    );
  });

  testWidgets(
      'screen renders events from backend payload when related account profiles are summarized',
      (tester) async {
    final dio = Dio()
      ..httpClientAdapter = _EventsScreenSummarizedRelatedProfilesAdapter();
    final scope = _ScreenTenantScope('https://tenant-a.test/admin/api');
    final repository = TenantAdminEventsRepository(
      dio: dio,
      tenantScope: scope,
    );

    GetIt.I.registerSingleton<LandlordAuthRepositoryContract>(
      _ScreenLandlordAuthRepository(),
    );

    final controller = TenantAdminEventsController(
      eventsRepository: repository,
      taxonomiesRepository: _NoopTaxonomiesRepository(),
      landlordAuthRepository: GetIt.I.get<LandlordAuthRepositoryContract>(),
    );

    GetIt.I.registerSingleton<TenantAdminEventsController>(controller);

    await _pumpEventsRouter(tester);

    expect(find.text('Summarized Artist Event'), findsOneWidget);
    expect(find.textContaining('Casa Solar'), findsOneWidget);
    expect(find.textContaining('DJ Summary'), findsOneWidget);
    expect(find.text('Unable to load events.'), findsNothing);
    expect(controller.eventsErrorStreamValue.value, isNull);
  });

  testWidgets('legacy check dialog shows counts and repair result', (
    tester,
  ) async {
    final controller = TenantAdminEventsController(
      eventsRepository: _LegacySummaryEventsRepository(),
      taxonomiesRepository: _NoopTaxonomiesRepository(),
    );

    GetIt.I.registerSingleton<TenantAdminEventsController>(controller);

    await _pumpEventsRouter(tester);

    await tester.tap(
      find.byKey(
          const ValueKey<String>('tenant-admin-events-legacy-check-button')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Eventos legados'), findsOneWidget);
    expect(find.text('Escaneados: 12'), findsOneWidget);
    expect(find.text('Inválidos: 4'), findsOneWidget);

    await tester.tap(
      find.byKey(
          const ValueKey<String>('tenant-admin-events-repair-legacy-button')),
    );
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('Corrigidos: 4'), findsOneWidget);
    expect(find.text('Inválidos: 0'), findsOneWidget);
  });

  testWidgets('temporal chips default to now and future and allow adding past',
      (tester) async {
    final controller = TenantAdminEventsController(
      eventsRepository: _EventsRepositoryWithSeedData(),
      taxonomiesRepository: _NoopTaxonomiesRepository(),
    );

    GetIt.I.registerSingleton<TenantAdminEventsController>(controller);

    await _pumpEventsRouter(tester);

    final pastChip = tester.widget<FilterChip>(
      find
          .byKey(
            const ValueKey<String>('tenant-admin-events-temporal-past'),
          )
          .first,
    );
    final nowChip = tester.widget<FilterChip>(
      find
          .byKey(
            const ValueKey<String>('tenant-admin-events-temporal-now'),
          )
          .first,
    );
    final futureChip = tester.widget<FilterChip>(
      find
          .byKey(
            const ValueKey<String>('tenant-admin-events-temporal-future'),
          )
          .first,
    );

    expect(pastChip.selected, isFalse);
    expect(nowChip.selected, isTrue);
    expect(futureChip.selected, isTrue);

    await tester.tap(
      find
          .byKey(
            const ValueKey<String>('tenant-admin-events-temporal-past'),
          )
          .first,
    );
    await tester.pumpAndSettle();

    final updatedPastChip = tester.widget<FilterChip>(
      find
          .byKey(
            const ValueKey<String>('tenant-admin-events-temporal-past'),
          )
          .first,
    );
    expect(updatedPastChip.selected, isTrue);
  });
}

Future<void> _pumpEventsRouter(WidgetTester tester) async {
  final router = RootStackRouter.build(
    routes: [
      NamedRouteDef(
        name: 'events-test-root',
        path: '/',
        builder: (_, __) => const Scaffold(
          body: TenantAdminEventsScreen(),
        ),
      ),
      NamedRouteDef(
        name: TenantAdminEventCreateRoute.name,
        path: '/events/create',
        builder: (_, __) => const Scaffold(
          body: Center(child: Text('CREATE-EVENT-ROUTE')),
        ),
      ),
      NamedRouteDef(
        name: TenantAdminEventEditRoute.name,
        path: '/events/edit',
        builder: (_, data) {
          final args = data.argsAs<TenantAdminEventEditRouteArgs>();
          return Scaffold(
            body: Center(
              child: Text('EDIT-EVENT-ROUTE:${args.event!.title}'),
            ),
          );
        },
      ),
      NamedRouteDef(
        name: TenantAdminEventTypesRoute.name,
        path: '/events/types',
        builder: (_, __) => const Scaffold(
          body: Center(child: Text('EVENT-TYPES-ROUTE')),
        ),
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

class _EventsRepositoryWithSeedData extends TenantAdminEventsRepositoryContract
    with TenantAdminEventsPaginationMixin {
  @override
  Future<TenantAdminEvent> createEvent({required TenantAdminEventDraft draft}) {
    throw UnimplementedError();
  }

  @override
  Future<TenantAdminEvent> createOwnEvent({
    required TenantAdminEventsRepoString accountSlug,
    required TenantAdminEventDraft draft,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteEvent(TenantAdminEventsRepoString eventId) async {}

  @override
  Future<TenantAdminEvent> fetchEvent(
      TenantAdminEventsRepoString eventIdOrSlug) async {
    return _seedEvent;
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
    return <TenantAdminEvent>[_seedEvent];
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
    if (page.value > 1) {
      return tenantAdminPagedResultFromRaw(
        items: <TenantAdminEvent>[],
        hasMore: false,
      );
    }

    return tenantAdminPagedResultFromRaw(
      items: <TenantAdminEvent>[_seedEvent],
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
  }) {
    throw UnimplementedError();
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

  static final TenantAdminEvent _seedEvent = TenantAdminEvent(
    eventIdValue: tenantAdminRequiredText('evt-1'),
    slugValue: tenantAdminRequiredText('seed-event'),
    titleValue: tenantAdminRequiredText('Seed Event'),
    contentValue: tenantAdminOptionalText('Seed Content'),
    type: TenantAdminEventType(
      nameValue: tenantAdminRequiredText('Show'),
      slugValue: tenantAdminRequiredText('show'),
    ),
    occurrences: <TenantAdminEventOccurrence>[
      TenantAdminEventOccurrence(
        dateTimeStartValue: tenantAdminDateTime(DateTime.utc(2026, 3, 5, 20)),
      ),
    ],
    publication: TenantAdminEventPublication(
      statusValue: tenantAdminRequiredText('draft'),
    ),
  );
}

class _FilterableEventsRepository extends TenantAdminEventsRepositoryContract
    with TenantAdminEventsPaginationMixin {
  String? lastSpecificDate;
  String? lastVenueProfileId;
  String? lastRelatedAccountProfileId;

  @override
  Future<TenantAdminEvent> createEvent({required TenantAdminEventDraft draft}) {
    throw UnimplementedError();
  }

  @override
  Future<TenantAdminEvent> createOwnEvent({
    required TenantAdminEventsRepoString accountSlug,
    required TenantAdminEventDraft draft,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteEvent(TenantAdminEventsRepoString eventId) async {}

  @override
  Future<TenantAdminEvent> fetchEvent(
    TenantAdminEventsRepoString eventIdOrSlug,
  ) async {
    return _events.first;
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
    lastSpecificDate = specificDate?.value;
    lastVenueProfileId = venueProfileId?.value;
    lastRelatedAccountProfileId = relatedAccountProfileId?.value;
    final normalizedSpecificDate = specificDate?.value.trim();

    return _events.where((event) {
      final eventDate = event.occurrences.first.dateTimeStart;
      final year = eventDate.year.toString().padLeft(4, '0');
      final month = eventDate.month.toString().padLeft(2, '0');
      final day = eventDate.day.toString().padLeft(2, '0');
      final eventDateKey = '$year-$month-$day';
      final matchesSpecificDate = normalizedSpecificDate == null ||
          normalizedSpecificDate.isEmpty ||
          eventDateKey == normalizedSpecificDate;
      final matchesVenue =
          venueProfileId == null || event.placeRef?.id == venueProfileId.value;
      final matchesRelated = relatedAccountProfileId == null ||
          event.relatedAccountProfiles.any(
            (profile) => profile.id == relatedAccountProfileId.value,
          );

      return matchesSpecificDate && matchesVenue && matchesRelated;
    }).toList(growable: false);
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
    final items = await fetchEvents(
      search: search,
      specificDate: specificDate,
      status: status,
      venueProfileId: venueProfileId,
      relatedAccountProfileId: relatedAccountProfileId,
      archived: archived,
      temporalBuckets: temporalBuckets,
    );

    return tenantAdminPagedResultFromRaw(
      items: items,
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
    final items = switch (candidateType) {
      TenantAdminEventAccountProfileCandidateType.physicalHost => [
          tenantAdminAccountProfileFromRaw(
            id: 'venue-main',
            accountId: 'account-venue-main',
            profileType: 'venue',
            displayName: 'Main Venue Candidate',
          ),
          tenantAdminAccountProfileFromRaw(
            id: 'venue-other',
            accountId: 'account-venue-other',
            profileType: 'venue',
            displayName: 'Other Venue Candidate',
          ),
        ],
      TenantAdminEventAccountProfileCandidateType.relatedAccountProfile => [
          tenantAdminAccountProfileFromRaw(
            id: 'artist-main',
            accountId: 'account-artist-main',
            profileType: 'artist',
            displayName: 'DJ Filter Candidate',
          ),
          tenantAdminAccountProfileFromRaw(
            id: 'artist-other',
            accountId: 'account-artist-other',
            profileType: 'artist',
            displayName: 'Other Related Candidate',
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
  }) {
    throw UnimplementedError();
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

  static final List<TenantAdminEvent> _events = [
    TenantAdminEvent(
      eventIdValue: tenantAdminRequiredText('evt-filtered'),
      slugValue: tenantAdminRequiredText('filtered-event-match'),
      titleValue: tenantAdminRequiredText('Filtered Event Match'),
      contentValue: tenantAdminOptionalText('Content'),
      type: TenantAdminEventType(
        nameValue: tenantAdminRequiredText('Show'),
        slugValue: tenantAdminRequiredText('show'),
      ),
      placeRef: TenantAdminEventPlaceRef(
        typeValue: tenantAdminRequiredText('account_profile'),
        idValue: tenantAdminRequiredText('venue-main'),
      ),
      occurrences: <TenantAdminEventOccurrence>[
        TenantAdminEventOccurrence(
          dateTimeStartValue:
              tenantAdminDateTime(DateTime.utc(2026, 4, 10, 20)),
        ),
      ],
      publication: TenantAdminEventPublication(
        statusValue: tenantAdminRequiredText('published'),
      ),
      relatedAccountProfiles: [
        tenantAdminAccountProfileFromRaw(
          id: 'artist-main',
          accountId: 'account-artist-main',
          profileType: 'artist',
          displayName: 'DJ Filter Candidate',
        ),
      ],
    ),
    TenantAdminEvent(
      eventIdValue: tenantAdminRequiredText('evt-other'),
      slugValue: tenantAdminRequiredText('other-event-miss'),
      titleValue: tenantAdminRequiredText('Other Event Miss'),
      contentValue: tenantAdminOptionalText('Content'),
      type: TenantAdminEventType(
        nameValue: tenantAdminRequiredText('Show'),
        slugValue: tenantAdminRequiredText('show'),
      ),
      placeRef: TenantAdminEventPlaceRef(
        typeValue: tenantAdminRequiredText('account_profile'),
        idValue: tenantAdminRequiredText('venue-other'),
      ),
      occurrences: <TenantAdminEventOccurrence>[
        TenantAdminEventOccurrence(
          dateTimeStartValue:
              tenantAdminDateTime(DateTime.utc(2026, 4, 12, 20)),
        ),
      ],
      publication: TenantAdminEventPublication(
        statusValue: tenantAdminRequiredText('draft'),
      ),
      relatedAccountProfiles: [
        tenantAdminAccountProfileFromRaw(
          id: 'artist-other',
          accountId: 'account-artist-other',
          profileType: 'artist',
          displayName: 'Other Related Candidate',
        ),
      ],
    ),
  ];
}

class _PagedGroupingEventsRepository extends TenantAdminEventsRepositoryContract
    with TenantAdminEventsPaginationMixin {
  final List<(int, String?)> pageRequests = <(int, String?)>[];

  @override
  Future<TenantAdminEvent> createEvent({required TenantAdminEventDraft draft}) {
    throw UnimplementedError();
  }

  @override
  Future<TenantAdminEvent> createOwnEvent({
    required TenantAdminEventsRepoString accountSlug,
    required TenantAdminEventDraft draft,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteEvent(TenantAdminEventsRepoString eventId) async {}

  @override
  Future<TenantAdminEvent> fetchEvent(
    TenantAdminEventsRepoString eventIdOrSlug,
  ) async {
    return _orderedEvents.first;
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
    final normalizedSpecificDate = specificDate?.value.trim();
    return _orderedEvents.where((event) {
      if (normalizedSpecificDate == null || normalizedSpecificDate.isEmpty) {
        return true;
      }

      final eventDate = event.occurrences.first.dateTimeStart;
      final year = eventDate.year.toString().padLeft(4, '0');
      final month = eventDate.month.toString().padLeft(2, '0');
      final day = eventDate.day.toString().padLeft(2, '0');
      return '$year-$month-$day' == normalizedSpecificDate;
    }).toList(growable: false);
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
    pageRequests.add((page.value, specificDate?.value));
    final items = await fetchEvents(
      specificDate: specificDate,
      venueProfileId: venueProfileId,
      relatedAccountProfileId: relatedAccountProfileId,
      archived: archived,
      temporalBuckets: temporalBuckets,
    );
    const effectivePageSize = 2;
    final start = (page.value - 1) * effectivePageSize;
    if (start >= items.length) {
      return tenantAdminPagedResultFromRaw(
        items: const <TenantAdminEvent>[],
        hasMore: false,
      );
    }
    final end = start + effectivePageSize > items.length
        ? items.length
        : start + effectivePageSize;
    return tenantAdminPagedResultFromRaw(
      items: items.sublist(start, end),
      hasMore: end < items.length,
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
  }) {
    throw UnimplementedError();
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

  static final List<TenantAdminEvent> _orderedEvents = <TenantAdminEvent>[
    _event(
      id: 'evt-top',
      slug: 'top',
      title: 'Top Event',
      start: DateTime.utc(2026, 4, 14, 20, 0),
    ),
    _event(
      id: 'evt-boundary-page1',
      slug: 'boundary-page1',
      title: 'Boundary Event Page 1',
      start: DateTime.utc(2026, 4, 13, 22, 0),
    ),
    _event(
      id: 'evt-boundary-page2',
      slug: 'boundary-page2',
      title: 'Boundary Event Page 2',
      start: DateTime.utc(2026, 4, 13, 11, 0),
    ),
  ];

  static TenantAdminEvent _event({
    required String id,
    required String slug,
    required String title,
    required DateTime start,
  }) {
    return TenantAdminEvent(
      eventIdValue: tenantAdminRequiredText(id),
      slugValue: tenantAdminRequiredText(slug),
      titleValue: tenantAdminRequiredText(title),
      contentValue: tenantAdminOptionalText('Content'),
      type: TenantAdminEventType(
        nameValue: tenantAdminRequiredText('Show'),
        slugValue: tenantAdminRequiredText('show'),
      ),
      occurrences: <TenantAdminEventOccurrence>[
        TenantAdminEventOccurrence(
          dateTimeStartValue: tenantAdminDateTime(start),
          dateTimeEndValue: tenantAdminOptionalDateTime(
            start.add(const Duration(hours: 2)),
          ),
        ),
      ],
      publication: TenantAdminEventPublication(
        statusValue: tenantAdminRequiredText('draft'),
      ),
    );
  }
}

class _LegacySummaryEventsRepository extends _EventsRepositoryWithSeedData {
  @override
  Future<TenantAdminLegacyEventPartiesSummary>
      fetchLegacyEventPartiesSummary() async {
    return TenantAdminLegacyEventPartiesSummary(
      scannedValue: TenantAdminCountValue(12),
      invalidValue: TenantAdminCountValue(4),
      repairedValue: TenantAdminCountValue(0),
      unchangedValue: TenantAdminCountValue(8),
      failedValue: TenantAdminCountValue(0),
    );
  }

  @override
  Future<TenantAdminLegacyEventPartiesSummary>
      repairLegacyEventParties() async {
    return TenantAdminLegacyEventPartiesSummary(
      scannedValue: TenantAdminCountValue(12),
      invalidValue: TenantAdminCountValue(0),
      repairedValue: TenantAdminCountValue(4),
      unchangedValue: TenantAdminCountValue(8),
      failedValue: TenantAdminCountValue(0),
    );
  }
}

class _ScreenLandlordAuthRepository implements LandlordAuthRepositoryContract {
  @override
  bool get hasValidSession => true;

  @override
  String get token => 'screen-landlord-token';

  @override
  Future<void> init() async {}

  @override
  Future<void> loginWithEmailPassword(
    LandlordAuthRepositoryContractPrimString email,
    LandlordAuthRepositoryContractPrimString password,
  ) async {}

  @override
  Future<void> logout() async {}
}

class _ScreenTenantScope implements TenantAdminTenantScopeContract {
  _ScreenTenantScope(String initialBaseUrl) {
    _selectedTenantDomainStreamValue.addValue(initialBaseUrl);
  }

  final StreamValue<String?> _selectedTenantDomainStreamValue =
      StreamValue<String?>(defaultValue: null);

  @override
  String? get selectedTenantDomain => _selectedTenantDomainStreamValue.value;

  @override
  String get selectedTenantAdminBaseUrl => selectedTenantDomain ?? '';

  @override
  StreamValue<String?> get selectedTenantDomainStreamValue =>
      _selectedTenantDomainStreamValue;

  @override
  void clearSelectedTenantDomain() {
    _selectedTenantDomainStreamValue.addValue(null);
  }

  @override
  void selectTenantDomain(Object tenantDomain) {
    _selectedTenantDomainStreamValue.addValue(
      (tenantDomain is String
              ? tenantDomain
              : (tenantDomain as dynamic).value as String)
          .trim(),
    );
  }
}

class _EventsScreenSummarizedRelatedProfilesAdapter
    implements HttpClientAdapter {
  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (options.path.endsWith('/admin/api/v1/events') &&
        options.method == 'GET') {
      return ResponseBody.fromString(
        '''
        {
          "data": [
            {
              "event_id": "evt-summary-screen-1",
              "slug": "summarized-artist-event",
              "title": "Summarized Artist Event",
              "content": "Content",
              "type": { "name": "Show", "slug": "show" },
              "publication": { "status": "draft" },
              "venue": {
                "id": "venue-summary-screen-1",
                "display_name": "Casa Solar",
                "profile_type": "venue"
              },
              "occurrences": [
                { "date_time_start": "2026-03-05T20:00:00Z" }
              ],
              "event_parties": [
                {
                  "party_type": "artist",
                  "party_ref_id": "artist-summary-screen-1",
                  "permissions": { "can_edit": true }
                }
              ],
              "linked_account_profiles": [
                {
                  "id": "artist-summary-screen-1",
                  "account_id": "artist-summary-screen-1",
                  "display_name": "DJ Summary",
                  "profile_type": "artist",
                  "avatar_url": "https://example.com/dj-summary.jpg",
                  "slug": "dj-summary-screen"
                }
              ]
            }
          ],
          "current_page": 1,
          "last_page": 1,
          "per_page": 20,
          "total": 1
        }
        ''',
        200,
        headers: {
          Headers.contentTypeHeader: ['application/json'],
        },
      );
    }

    return ResponseBody.fromString(
      '{"data": {}}',
      200,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
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
