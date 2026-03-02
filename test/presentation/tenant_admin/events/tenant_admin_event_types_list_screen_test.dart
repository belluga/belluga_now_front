import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/domain/repositories/tenant_admin_events_repository_contract.dart';
import 'package:belluga_now/domain/repositories/tenant_admin_taxonomies_repository_contract.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_account_profile.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_event.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_paged_result.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_definition.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_term_definition.dart';
import 'package:belluga_now/presentation/tenant_admin/events/controllers/tenant_admin_events_controller.dart';
import 'package:belluga_now/presentation/tenant_admin/events/screens/tenant_admin_event_types_list_screen.dart';
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

  testWidgets('reacts when a new event type is upserted in controller stream',
      (tester) async {
    final controller = TenantAdminEventsController(
      eventsRepository: _NoopEventsRepository(),
      taxonomiesRepository: _NoopTaxonomiesRepository(),
    );
    GetIt.I.registerSingleton<TenantAdminEventsController>(controller);

    final router = RootStackRouter.build(
      routes: [
        NamedRouteDef(
          name: 'event-types-test',
          path: '/',
          builder: (_, __) => const TenantAdminEventTypesListScreen(),
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

    expect(find.text('Nenhum tipo cadastrado'), findsOneWidget);

    controller.upsertEventTypeCatalogItem(
      const TenantAdminEventType(
        name: 'Festival',
        slug: 'festival',
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Festival'), findsOneWidget);
    expect(find.textContaining('festival'), findsOneWidget);
  });
}

class _NoopEventsRepository
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
  Future<TenantAdminEvent> fetchEvent(String eventIdOrSlug) {
    throw UnimplementedError();
  }

  @override
  Future<List<TenantAdminEvent>> fetchEvents({
    String? search,
    String? status,
    bool archived = false,
  }) async {
    return const <TenantAdminEvent>[];
  }

  @override
  Future<TenantAdminPagedResult<TenantAdminEvent>> fetchEventsPage({
    required int page,
    required int pageSize,
    String? search,
    String? status,
    bool archived = false,
  }) async {
    return const TenantAdminPagedResult<TenantAdminEvent>(
      items: <TenantAdminEvent>[],
      hasMore: false,
    );
  }

  @override
  Future<TenantAdminEventPartyCandidates> fetchPartyCandidates({
    String? search,
    String? accountSlug,
  }) async {
    return const TenantAdminEventPartyCandidates(
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
    return const <TenantAdminTaxonomyDefinition>[];
  }

  @override
  Future<TenantAdminPagedResult<TenantAdminTaxonomyDefinition>>
      fetchTaxonomiesPage({
    required int page,
    required int pageSize,
  }) async {
    return const TenantAdminPagedResult<TenantAdminTaxonomyDefinition>(
      items: <TenantAdminTaxonomyDefinition>[],
      hasMore: false,
    );
  }

  @override
  Future<List<TenantAdminTaxonomyTermDefinition>> fetchTerms({
    required String taxonomyId,
  }) async {
    return const <TenantAdminTaxonomyTermDefinition>[];
  }

  @override
  Future<TenantAdminPagedResult<TenantAdminTaxonomyTermDefinition>>
      fetchTermsPage({
    required String taxonomyId,
    required int page,
    required int pageSize,
  }) async {
    return const TenantAdminPagedResult<TenantAdminTaxonomyTermDefinition>(
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
