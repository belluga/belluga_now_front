import 'package:belluga_now/application/application.dart';
import 'package:belluga_now/application/application_contract.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/domain/repositories/admin_mode_repository_contract.dart';
import 'package:belluga_now/domain/repositories/app_data_repository_contract.dart';
import 'package:belluga_now/domain/repositories/landlord_auth_repository_contract.dart';
import 'package:belluga_now/domain/repositories/landlord_tenants_repository_contract.dart';
import 'package:belluga_now/domain/repositories/tenant_admin_events_repository_contract.dart';
import 'package:belluga_now/domain/repositories/tenant_admin_taxonomies_repository_contract.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_account_profile.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_event.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_event_account_profile_candidate_type.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_paged_result.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_definition.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_term_definition.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_value_parsers.dart';
import 'package:belluga_now/infrastructure/platform/app_data_local_info_source/app_data_local_info_source.dart';
import 'package:belluga_now/infrastructure/repositories/app_data_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:integration_test/integration_test.dart';
import 'package:stream_value/core/stream_value.dart';

import 'support/fake_landlord_app_data_backend.dart';
import 'support/integration_test_bootstrap.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  IntegrationTestBootstrap.ensureNonProductionLandlordDomain();

  Future<void> _waitForFinder(
    WidgetTester tester,
    Finder finder, {
    Duration timeout = const Duration(seconds: 20),
    Duration step = const Duration(milliseconds: 200),
  }) async {
    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      await tester.pump(step);
      if (finder.evaluate().isNotEmpty) {
        return;
      }
    }
    throw TestFailure(
      'Timed out waiting for ${finder.describeMatch(Plurality.one)}.',
    );
  }

  testWidgets(
    'event soft delete hides from active list and appears in archived list',
    (tester) async {
      final getIt = GetIt.I;
      await getIt.reset();

      getIt.registerSingleton<AppDataRepositoryContract>(
        AppDataRepository(
          backend: const FakeLandlordAppDataBackend(),
          localInfoSource: AppDataLocalInfoSource(),
        ),
      );
      getIt.registerSingleton<AdminModeRepositoryContract>(
        _InMemoryAdminModeRepository(),
      );
      getIt.registerSingleton<LandlordAuthRepositoryContract>(
        _FakeLandlordAuthRepository(hasValidSession: true),
      );
      getIt.registerSingleton<LandlordTenantsRepositoryContract>(
        _FakeLandlordTenantsRepository(),
      );
      getIt.registerSingleton<TenantAdminEventsRepositoryContract>(
        _FakeTenantAdminEventsRepository(),
      );
      getIt.registerSingleton<TenantAdminTaxonomiesRepositoryContract>(
        _NoopTaxonomiesRepository(),
      );

      final app = Application();
      getIt.registerSingleton<ApplicationContract>(app);
      await app.init();

      await tester.runAsync(() async {
        final adminModeRepo = getIt<AdminModeRepositoryContract>();
        await adminModeRepo.setLandlordMode();
      });

      app.appRouter.replaceAll(
        [
          TenantAdminShellRoute(
            children: [TenantAdminEventsRoute()],
          ),
        ],
      );

      await tester.pumpWidget(app);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      final tenantOption = find.text('Guarappari');
      if (tenantOption.evaluate().isNotEmpty) {
        await tester.tap(tenantOption.first);
        await tester.pumpAndSettle(const Duration(seconds: 2));
      }

      final eventsNav = find.text('Eventos');
      if (eventsNav.evaluate().isNotEmpty) {
        await tester.tap(eventsNav.first);
        await tester.pumpAndSettle(const Duration(seconds: 1));
      }

      const eventTitle = 'Delete Visibility Event';
      await _waitForFinder(tester, find.text(eventTitle));

      final eventTile = find.ancestor(
        of: find.text(eventTitle).first,
        matching: find.byType(ListTile),
      );
      final deleteMenuButton = find.descendant(
        of: eventTile,
        matching: find.byType(PopupMenuButton<String>),
      );
      await tester.tap(deleteMenuButton.first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Remover').first);
      await tester.pumpAndSettle();

      await _waitForFinder(tester, find.byType(AlertDialog));
      final dialogDeleteButton = find.descendant(
        of: find.byType(AlertDialog).first,
        matching: find.text('Remover'),
      );
      await tester.tap(dialogDeleteButton.first);
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      expect(find.text(eventTitle), findsNothing);

      final visibilityField = find.text('Ativos');
      await tester.ensureVisible(visibilityField.first);
      await tester.tap(visibilityField.first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Arquivados').last);
      await tester.pumpAndSettle();

      await _waitForFinder(tester, find.text(eventTitle));
    },
  );
}

class _InMemoryAdminModeRepository implements AdminModeRepositoryContract {
  final StreamValue<AdminMode> _modeStreamValue =
      StreamValue<AdminMode>(defaultValue: AdminMode.user);

  @override
  StreamValue<AdminMode> get modeStreamValue => _modeStreamValue;

  @override
  AdminMode get mode => _modeStreamValue.value;

  @override
  bool get isLandlordMode => mode == AdminMode.landlord;

  @override
  Future<void> init() async {}

  @override
  Future<void> setLandlordMode() async {
    _modeStreamValue.addValue(AdminMode.landlord);
  }

  @override
  Future<void> setUserMode() async {
    _modeStreamValue.addValue(AdminMode.user);
  }
}

class _FakeLandlordAuthRepository implements LandlordAuthRepositoryContract {
  _FakeLandlordAuthRepository({required bool hasValidSession})
      : _hasValidSession = hasValidSession;

  bool _hasValidSession;

  @override
  bool get hasValidSession => _hasValidSession;

  @override
  String get token => _hasValidSession ? 'token' : '';

  @override
  Future<void> init() async {}

  @override
  Future<void> loginWithEmailPassword(
      LandlordAuthRepositoryContractPrimString email,
      LandlordAuthRepositoryContractPrimString password) async {
    _hasValidSession = true;
  }

  @override
  Future<void> logout() async {
    _hasValidSession = false;
  }
}

class _FakeLandlordTenantsRepository
    implements LandlordTenantsRepositoryContract {
  @override
  Future<List<LandlordTenantOption>> fetchTenants() async {
    return [
      landlordTenantOptionFromRaw(
        id: 'tenant-guarappari',
        name: 'Guarappari',
        mainDomain: 'guarappari.local.test',
      ),
    ];
  }
}

class _FakeTenantAdminEventsRepository
    with TenantAdminEventsPaginationMixin
    implements TenantAdminEventsRepositoryContract {
  _FakeTenantAdminEventsRepository()
      : _events = <TenantAdminEvent>[
          TenantAdminEvent(
            eventIdValue: tenantAdminRequiredText('event-delete-1'),
            slugValue: tenantAdminRequiredText('delete-visibility-event'),
            titleValue: tenantAdminRequiredText('Delete Visibility Event'),
            contentValue: tenantAdminOptionalText(
              'Event used to validate soft delete visibility.',
            ),
            type: TenantAdminEventType(
              nameValue: tenantAdminRequiredText('Show'),
              slugValue: tenantAdminRequiredText('show'),
            ),
            occurrences: [
              TenantAdminEventOccurrence(
                dateTimeStartValue:
                    tenantAdminDateTime(DateTime(2026, 3, 5, 20)),
              ),
            ],
            publication: TenantAdminEventPublication(
              statusValue: tenantAdminRequiredText('published'),
            ),
            deletedAtValue: tenantAdminOptionalDateTime(null),
          ),
        ];

  final List<TenantAdminEvent> _events;

  @override
  Future<TenantAdminEvent> createEvent({
    required TenantAdminEventDraft draft,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<TenantAdminEvent> createOwnEvent({
    required TenantAdminEventsRepoString accountSlug,
    required TenantAdminEventDraft draft,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<TenantAdminEvent> updateEvent({
    required TenantAdminEventsRepoString eventId,
    required TenantAdminEventDraft draft,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteEvent(TenantAdminEventsRepoString eventId) async {
    final index = _events.indexWhere((event) => event.eventId == eventId.value);
    if (index < 0) {
      return;
    }
    final current = _events[index];
    _events[index] = TenantAdminEvent(
      eventIdValue: tenantAdminRequiredText(current.eventId),
      slugValue: tenantAdminRequiredText(current.slug),
      titleValue: tenantAdminRequiredText(current.title),
      contentValue: tenantAdminOptionalText(current.content),
      type: current.type,
      occurrences: current.occurrences,
      publication: current.publication,
      location: current.location,
      placeRef: current.placeRef,
      artistIdValues: current.artistIds,
      eventParties: current.eventParties,
      taxonomyTerms: current.taxonomyTerms,
      createdAtValue: tenantAdminOptionalDateTime(current.createdAt),
      updatedAtValue: tenantAdminOptionalDateTime(DateTime.now().toUtc()),
      deletedAtValue: tenantAdminOptionalDateTime(DateTime.now().toUtc()),
    );
  }

  @override
  Future<List<TenantAdminEvent>> fetchEvents({
    TenantAdminEventsRepoString? search,
    TenantAdminEventsRepoString? status,
    TenantAdminEventsRepoBool? archived,
  }) async {
    return _filterEvents(
      status: status?.value,
      archived: archived?.value ?? false,
    );
  }

  @override
  Future<TenantAdminPagedResult<TenantAdminEvent>> fetchEventsPage({
    required TenantAdminEventsRepoInt page,
    required TenantAdminEventsRepoInt pageSize,
    TenantAdminEventsRepoString? search,
    TenantAdminEventsRepoString? status,
    TenantAdminEventsRepoBool? archived,
  }) async {
    final filtered = _filterEvents(
      status: status?.value,
      archived: archived?.value ?? false,
    );
    if (page.value <= 0 || pageSize.value <= 0) {
      return tenantAdminPagedResultFromRaw(
        items: <TenantAdminEvent>[],
        hasMore: false,
      );
    }
    final start = (page.value - 1) * pageSize.value;
    if (start >= filtered.length) {
      return tenantAdminPagedResultFromRaw(
        items: <TenantAdminEvent>[],
        hasMore: false,
      );
    }
    final end = (start + pageSize.value) > filtered.length
        ? filtered.length
        : (start + pageSize.value);
    return tenantAdminPagedResultFromRaw(
      items: filtered.sublist(start, end),
      hasMore: end < filtered.length,
    );
  }

  List<TenantAdminEvent> _filterEvents({
    String? status,
    required bool archived,
  }) {
    final normalizedStatus = status?.trim();

    return _events.where((event) {
      final isArchived = event.deletedAt != null;
      if (archived != isArchived) {
        return false;
      }
      if (normalizedStatus != null &&
          normalizedStatus.isNotEmpty &&
          event.publication.status != normalizedStatus) {
        return false;
      }
      return true;
    }).toList(growable: false);
  }

  @override
  Future<TenantAdminEvent> fetchEvent(
      TenantAdminEventsRepoString eventIdOrSlug) async {
    return _events.first;
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
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<TenantAdminTaxonomyTermDefinition> createTerm({
    required TenantAdminTaxRepoString taxonomyId,
    required TenantAdminTaxRepoString slug,
    required TenantAdminTaxRepoString name,
  }) async {
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
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<TenantAdminTaxonomyTermDefinition> updateTerm({
    required TenantAdminTaxRepoString taxonomyId,
    required TenantAdminTaxRepoString termId,
    TenantAdminTaxRepoString? slug,
    TenantAdminTaxRepoString? name,
  }) async {
    throw UnimplementedError();
  }
}
