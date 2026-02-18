import 'dart:typed_data';

import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/domain/repositories/tenant_admin_account_profiles_repository_contract.dart';
import 'package:belluga_now/domain/repositories/tenant_admin_accounts_repository_contract.dart';
import 'package:belluga_now/domain/repositories/tenant_admin_taxonomies_repository_contract.dart';
import 'package:belluga_now/domain/services/tenant_admin_external_image_proxy_contract.dart';
import 'package:belluga_now/domain/services/tenant_admin_location_selection_contract.dart';
import 'package:belluga_now/domain/tenant_admin/ownership_state.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_account.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_account_profile.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_document.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_location.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_media_upload.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_profile_type.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_definition.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_term.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_term_definition.dart';
import 'package:belluga_now/infrastructure/services/tenant_admin/tenant_admin_location_selection_service.dart';
import 'package:belluga_now/presentation/tenant_admin/account_profiles/controllers/tenant_admin_account_profiles_controller.dart';
import 'package:belluga_now/presentation/tenant_admin/account_profiles/screens/tenant_admin_account_profile_create_screen.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/utils/tenant_admin_image_ingestion_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await GetIt.I.reset();
    final accountsRepository = _FakeAccountsRepository();
    final profilesRepository = _FakeAccountProfilesRepository();
    final taxonomiesRepository = _FakeTaxonomiesRepository();
    final TenantAdminLocationSelectionContract locationSelectionService =
        TenantAdminLocationSelectionService();

    GetIt.I.registerSingleton<TenantAdminAccountsRepositoryContract>(
      accountsRepository,
    );
    GetIt.I.registerSingleton<TenantAdminAccountProfilesRepositoryContract>(
      profilesRepository,
    );
    GetIt.I.registerSingleton<TenantAdminTaxonomiesRepositoryContract>(
      taxonomiesRepository,
    );
    GetIt.I.registerSingleton<TenantAdminLocationSelectionContract>(
      locationSelectionService,
    );
    GetIt.I.registerSingleton<TenantAdminExternalImageProxyContract>(
      _FakeExternalImageProxy(),
    );
    GetIt.I.registerSingleton<TenantAdminImageIngestionService>(
      TenantAdminImageIngestionService(),
    );

    final controller = TenantAdminAccountProfilesController(
      profilesRepository: profilesRepository,
      accountsRepository: accountsRepository,
      taxonomiesRepository: taxonomiesRepository,
      locationSelectionService: locationSelectionService,
    );

    // Simulate stale singleton controller state from a previous session.
    controller.accountStreamValue.addValue(_account(slug: 'stale-account'));

    GetIt.I.registerSingleton<TenantAdminAccountProfilesController>(controller);
  });

  tearDown(() async {
    await GetIt.I.reset();
  });

  testWidgets('prefers route account slug over cached controller slug on init',
      (tester) async {
    final accountsRepository =
        GetIt.I.get<TenantAdminAccountsRepositoryContract>()
            as _FakeAccountsRepository;

    await _pumpScreen(
      tester,
      const TenantAdminAccountProfileCreateScreen(accountSlug: 'route-account'),
    );

    expect(accountsRepository.fetchAccountBySlugCalls, 1);
    expect(accountsRepository.lastFetchedSlug, 'route-account');
  });
}

Future<void> _pumpScreen(WidgetTester tester, Widget child) async {
  final router = RootStackRouter.build(
    routes: [
      NamedRouteDef(
        name: 'profile-create-test',
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

class _FakeAccountsRepository extends TenantAdminAccountsRepositoryContract {
  int fetchAccountBySlugCalls = 0;
  String? lastFetchedSlug;

  @override
  Future<List<TenantAdminAccount>> fetchAccounts() async {
    return const [];
  }

  @override
  Future<TenantAdminAccount> fetchAccountBySlug(String accountSlug) async {
    fetchAccountBySlugCalls += 1;
    lastFetchedSlug = accountSlug;

    final account = _account(slug: accountSlug);
    // Seed the list stream so watchLoadedAccount has something to resolve.
    accountsStreamValue.addValue([account]);
    return account;
  }

  @override
  Future<TenantAdminAccount> createAccount({
    required String name,
    TenantAdminDocument? document,
    required TenantAdminOwnershipState ownershipState,
    String? organizationId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<TenantAdminAccount> updateAccount({
    required String accountSlug,
    String? name,
    String? slug,
    TenantAdminDocument? document,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteAccount(String accountSlug) {
    throw UnimplementedError();
  }

  @override
  Future<TenantAdminAccount> restoreAccount(String accountSlug) {
    throw UnimplementedError();
  }

  @override
  Future<void> forceDeleteAccount(String accountSlug) {
    throw UnimplementedError();
  }
}

class _FakeAccountProfilesRepository
    extends TenantAdminAccountProfilesRepositoryContract {
  @override
  Future<List<TenantAdminAccountProfile>> fetchAccountProfiles({
    String? accountId,
  }) async {
    return const [];
  }

  @override
  Future<TenantAdminAccountProfile> fetchAccountProfile(
    String accountProfileId,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<List<TenantAdminProfileTypeDefinition>> fetchProfileTypes() async {
    return const [];
  }

  @override
  Future<TenantAdminAccountProfile> createAccountProfile({
    required String accountId,
    required String profileType,
    required String displayName,
    TenantAdminLocation? location,
    List<TenantAdminTaxonomyTerm> taxonomyTerms = const [],
    String? bio,
    String? content,
    String? avatarUrl,
    String? coverUrl,
    TenantAdminMediaUpload? avatarUpload,
    TenantAdminMediaUpload? coverUpload,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<TenantAdminAccountProfile> updateAccountProfile({
    required String accountProfileId,
    String? profileType,
    String? displayName,
    String? slug,
    TenantAdminLocation? location,
    List<TenantAdminTaxonomyTerm>? taxonomyTerms,
    String? bio,
    String? content,
    String? avatarUrl,
    String? coverUrl,
    TenantAdminMediaUpload? avatarUpload,
    TenantAdminMediaUpload? coverUpload,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteAccountProfile(String accountProfileId) {
    throw UnimplementedError();
  }

  @override
  Future<TenantAdminAccountProfile> restoreAccountProfile(
    String accountProfileId,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<void> forceDeleteAccountProfile(String accountProfileId) {
    throw UnimplementedError();
  }

  @override
  Future<TenantAdminProfileTypeDefinition> createProfileType({
    required String type,
    required String label,
    List<String> allowedTaxonomies = const [],
    required TenantAdminProfileTypeCapabilities capabilities,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<TenantAdminProfileTypeDefinition> updateProfileType({
    required String type,
    String? newType,
    String? label,
    List<String>? allowedTaxonomies,
    TenantAdminProfileTypeCapabilities? capabilities,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteProfileType(String type) {
    throw UnimplementedError();
  }
}

class _FakeTaxonomiesRepository extends TenantAdminTaxonomiesRepositoryContract {
  @override
  Future<List<TenantAdminTaxonomyDefinition>> fetchTaxonomies() async {
    return const [];
  }

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
  Future<void> deleteTaxonomy(String taxonomyId) {
    throw UnimplementedError();
  }

  @override
  Future<List<TenantAdminTaxonomyTermDefinition>> fetchTerms({
    required String taxonomyId,
  }) async {
    return const [];
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
  Future<TenantAdminTaxonomyTermDefinition> updateTerm({
    required String taxonomyId,
    required String termId,
    String? slug,
    String? name,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteTerm({
    required String taxonomyId,
    required String termId,
  }) {
    throw UnimplementedError();
  }
}

class _FakeExternalImageProxy implements TenantAdminExternalImageProxyContract {
  @override
  Future<Uint8List> fetchExternalImageBytes({required String imageUrl}) async {
    return Uint8List(0);
  }
}

TenantAdminAccount _account({required String slug}) {
  return TenantAdminAccount(
    id: 'acc-$slug',
    name: slug,
    slug: slug,
    document: const TenantAdminDocument(type: 'cpf', number: '000'),
    ownershipState: TenantAdminOwnershipState.tenantOwned,
  );
}
