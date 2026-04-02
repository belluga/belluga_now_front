import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/domain/repositories/tenant_admin_events_repository_contract.dart';
import 'package:belluga_now/domain/repositories/tenant_admin_taxonomies_repository_contract.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_account_profile.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_event.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_event_account_profile_candidate_type.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_paged_result.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_definition.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_term_definition.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_value_parsers.dart';
import 'package:belluga_now/presentation/tenant_admin/events/controllers/tenant_admin_events_controller.dart';
import 'package:belluga_now/presentation/tenant_admin/events/screens/tenant_admin_events_screen.dart';
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

class _EventsRepositoryWithSeedData
    with TenantAdminEventsPaginationMixin
    implements TenantAdminEventsRepositoryContract {
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
    TenantAdminEventsRepoString? status,
    TenantAdminEventsRepoBool? archived,
  }) async {
    return <TenantAdminEvent>[_seedEvent];
  }

  @override
  Future<TenantAdminPagedResult<TenantAdminEvent>> fetchEventsPage({
    required TenantAdminEventsRepoInt page,
    required TenantAdminEventsRepoInt pageSize,
    TenantAdminEventsRepoString? search,
    TenantAdminEventsRepoString? status,
    TenantAdminEventsRepoBool? archived,
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
