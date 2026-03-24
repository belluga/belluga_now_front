import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/domain/repositories/tenant_admin_events_repository_contract.dart';
import 'package:belluga_now/domain/repositories/tenant_admin_taxonomies_repository_contract.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_account_profile.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_event.dart';
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
              child: Text('EDIT-EVENT-ROUTE:${args.event.title}'),
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
    required String accountSlug,
    required TenantAdminEventDraft draft,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteEvent(String eventId) async {}

  @override
  Future<TenantAdminEvent> fetchEvent(String eventIdOrSlug) async {
    return _seedEvent;
  }

  @override
  Future<List<TenantAdminEvent>> fetchEvents({
    String? search,
    String? status,
    bool archived = false,
  }) async {
    return <TenantAdminEvent>[_seedEvent];
  }

  @override
  Future<TenantAdminPagedResult<TenantAdminEvent>> fetchEventsPage({
    required int page,
    required int pageSize,
    String? search,
    String? status,
    bool archived = false,
  }) async {
    if (page > 1) {
      return TenantAdminPagedResult<TenantAdminEvent>(
        items: <TenantAdminEvent>[],
        hasMore: false,
      );
    }

    return TenantAdminPagedResult<TenantAdminEvent>(
      items: <TenantAdminEvent>[_seedEvent],
      hasMore: false,
    );
  }

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

  @override
  Future<TenantAdminEvent> updateEvent({
    required String eventId,
    required TenantAdminEventDraft draft,
  }) {
    throw UnimplementedError();
  }

  static final TenantAdminEvent _seedEvent = TenantAdminEvent(
    eventId: 'evt-1',
    slug: 'seed-event',
    title: 'Seed Event',
    content: 'Seed Content',
    type: TenantAdminEventType(name: 'Show', slug: 'show'),
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
