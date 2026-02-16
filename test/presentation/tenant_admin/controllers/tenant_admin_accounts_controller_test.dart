import 'dart:async';

import 'package:belluga_now/domain/repositories/tenant_admin_account_profiles_repository_contract.dart';
import 'package:belluga_now/domain/repositories/tenant_admin_accounts_repository_contract.dart';
import 'package:belluga_now/domain/tenant_admin/ownership_state.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_account.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_account_profile.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_document.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_location.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_media_upload.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_paged_accounts_result.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_paged_result.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_profile_type.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_term.dart';
import 'package:belluga_now/domain/services/tenant_admin_location_selection_contract.dart';
import 'package:belluga_now/domain/services/tenant_admin_tenant_scope_contract.dart';
import 'package:belluga_now/infrastructure/services/tenant_admin/tenant_admin_location_selection_service.dart';
import 'package:belluga_now/presentation/tenant_admin/accounts/controllers/tenant_admin_accounts_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stream_value/core/stream_value.dart';

class _FakeAccountsRepository implements TenantAdminAccountsRepositoryContract {
  _FakeAccountsRepository(this._accounts);

  List<TenantAdminAccount> _accounts;
  Completer<void>? fetchAccountsGate;
  int fetchAccountsCalls = 0;
  int createCalls = 0;

  @override
  Future<List<TenantAdminAccount>> fetchAccounts() async {
    fetchAccountsCalls += 1;
    final gate = fetchAccountsGate;
    if (gate != null) {
      await gate.future;
    }
    return _accounts;
  }

  @override
  Future<TenantAdminPagedAccountsResult> fetchAccountsPage({
    required int page,
    required int pageSize,
  }) async {
    final all = await fetchAccounts();
    final startIndex = (page - 1) * pageSize;
    if (startIndex >= all.length || page <= 0 || pageSize <= 0) {
      return const TenantAdminPagedAccountsResult(
        accounts: <TenantAdminAccount>[],
        hasMore: false,
      );
    }
    final endIndex =
        startIndex + pageSize > all.length ? all.length : startIndex + pageSize;
    return TenantAdminPagedAccountsResult(
      accounts: all.sublist(startIndex, endIndex),
      hasMore: endIndex < all.length,
    );
  }

  @override
  Future<TenantAdminAccount> fetchAccountBySlug(String accountSlug) async {
    return _accounts.firstWhere(
      (account) => account.slug == accountSlug,
      orElse: () => _accounts.first,
    );
  }

  @override
  Future<TenantAdminAccount> createAccount({
    required String name,
    TenantAdminDocument? document,
    required TenantAdminOwnershipState ownershipState,
    String? organizationId,
  }) async {
    createCalls += 1;
    final created = TenantAdminAccount(
      id: 'acc-$createCalls',
      name: name,
      slug: 'acc-$createCalls',
      document:
          document ?? const TenantAdminDocument(type: 'cpf', number: '000'),
      ownershipState: ownershipState,
      organizationId: organizationId,
    );
    _accounts = [..._accounts, created];
    return created;
  }

  @override
  Future<TenantAdminAccount> updateAccount({
    required String accountSlug,
    String? name,
    TenantAdminDocument? document,
  }) async {
    return fetchAccountBySlug(accountSlug);
  }

  @override
  Future<void> deleteAccount(String accountSlug) async {}

  @override
  Future<TenantAdminAccount> restoreAccount(String accountSlug) async {
    return fetchAccountBySlug(accountSlug);
  }

  @override
  Future<void> forceDeleteAccount(String accountSlug) async {}
}

class _FakeAccountProfilesRepository
    implements TenantAdminAccountProfilesRepositoryContract {
  _FakeAccountProfilesRepository(this._types);

  final List<TenantAdminProfileTypeDefinition> _types;
  int createProfileCalls = 0;
  String? lastCreateDisplayName;

  @override
  Future<List<TenantAdminProfileTypeDefinition>> fetchProfileTypes() async =>
      _types;

  @override
  Future<TenantAdminPagedResult<TenantAdminProfileTypeDefinition>>
      fetchProfileTypesPage({
    required int page,
    required int pageSize,
  }) async {
    final types = await fetchProfileTypes();
    final start = (page - 1) * pageSize;
    if (page <= 0 || pageSize <= 0 || start >= types.length) {
      return const TenantAdminPagedResult<TenantAdminProfileTypeDefinition>(
        items: <TenantAdminProfileTypeDefinition>[],
        hasMore: false,
      );
    }
    final end =
        start + pageSize < types.length ? start + pageSize : types.length;
    return TenantAdminPagedResult<TenantAdminProfileTypeDefinition>(
      items: types.sublist(start, end),
      hasMore: end < types.length,
    );
  }

  @override
  Future<TenantAdminAccountProfile> createAccountProfile({
    required String accountId,
    required String profileType,
    required String displayName,
    TenantAdminLocation? location,
    List<TenantAdminTaxonomyTerm> taxonomyTerms = const [],
    String? bio,
    String? avatarUrl,
    String? coverUrl,
    TenantAdminMediaUpload? avatarUpload,
    TenantAdminMediaUpload? coverUpload,
  }) async {
    createProfileCalls += 1;
    lastCreateDisplayName = displayName;
    return TenantAdminAccountProfile(
      id: 'profile-$createProfileCalls',
      accountId: accountId,
      profileType: profileType,
      displayName: displayName,
      location: location,
      taxonomyTerms: taxonomyTerms,
    );
  }

  @override
  Future<List<TenantAdminAccountProfile>> fetchAccountProfiles({
    String? accountId,
  }) async =>
      const [];

  @override
  Future<TenantAdminAccountProfile> fetchAccountProfile(
    String accountProfileId,
  ) async {
    return const TenantAdminAccountProfile(
      id: 'profile-1',
      accountId: 'acc-1',
      profileType: 'venue',
      displayName: 'Perfil',
    );
  }

  @override
  Future<TenantAdminAccountProfile> updateAccountProfile({
    required String accountProfileId,
    String? profileType,
    String? displayName,
    TenantAdminLocation? location,
    List<TenantAdminTaxonomyTerm>? taxonomyTerms,
    String? bio,
    String? avatarUrl,
    String? coverUrl,
    TenantAdminMediaUpload? avatarUpload,
    TenantAdminMediaUpload? coverUpload,
  }) async {
    return const TenantAdminAccountProfile(
      id: 'profile-1',
      accountId: 'acc-1',
      profileType: 'venue',
      displayName: 'Perfil',
    );
  }

  @override
  Future<void> deleteAccountProfile(String accountProfileId) async {}

  @override
  Future<TenantAdminAccountProfile> restoreAccountProfile(
    String accountProfileId,
  ) async {
    return const TenantAdminAccountProfile(
      id: 'profile-1',
      accountId: 'acc-1',
      profileType: 'venue',
      displayName: 'Perfil',
    );
  }

  @override
  Future<void> forceDeleteAccountProfile(String accountProfileId) async {}

  @override
  Future<TenantAdminProfileTypeDefinition> createProfileType({
    required String type,
    required String label,
    List<String> allowedTaxonomies = const [],
    required TenantAdminProfileTypeCapabilities capabilities,
  }) async {
    return TenantAdminProfileTypeDefinition(
      type: type,
      label: label,
      allowedTaxonomies: allowedTaxonomies,
      capabilities: capabilities,
    );
  }

  @override
  Future<TenantAdminProfileTypeDefinition> updateProfileType({
    required String type,
    String? label,
    List<String>? allowedTaxonomies,
    TenantAdminProfileTypeCapabilities? capabilities,
  }) async {
    return TenantAdminProfileTypeDefinition(
      type: type,
      label: label ?? 'Updated',
      allowedTaxonomies: allowedTaxonomies ?? const [],
      capabilities: capabilities ??
          const TenantAdminProfileTypeCapabilities(
            isFavoritable: true,
            isPoiEnabled: true,
            hasBio: false,
            hasTaxonomies: false,
            hasAvatar: false,
            hasCover: false,
            hasEvents: false,
          ),
    );
  }

  @override
  Future<void> deleteProfileType(String type) async {}
}

void main() {
  test('loads profile types and accounts on init', () async {
    final accountsRepository = _FakeAccountsRepository([
      TenantAdminAccount(
        id: 'acc-1',
        name: 'Conta',
        slug: 'conta',
        document: const TenantAdminDocument(type: 'cpf', number: '000'),
        ownershipState: TenantAdminOwnershipState.tenantOwned,
      ),
    ]);
    final profilesRepository = _FakeAccountProfilesRepository(const [
      TenantAdminProfileTypeDefinition(
        type: 'venue',
        label: 'Venue',
        allowedTaxonomies: [],
        capabilities: TenantAdminProfileTypeCapabilities(
          isFavoritable: true,
          isPoiEnabled: true,
          hasBio: false,
          hasTaxonomies: false,
          hasAvatar: false,
          hasCover: false,
          hasEvents: false,
        ),
      ),
    ]);

    final TenantAdminLocationSelectionContract locationSelectionService =
        TenantAdminLocationSelectionService();
    final controller = TenantAdminAccountsController(
      accountsRepository: accountsRepository,
      profilesRepository: profilesRepository,
      locationSelectionService: locationSelectionService,
    );

    await controller.init();

    expect(controller.accountsStreamValue.value?.length, 1);
    expect(controller.profileTypesStreamValue.value.length, 1);
  });

  test('createAccountWithProfile updates accounts list', () async {
    final accountsRepository = _FakeAccountsRepository([]);
    final profilesRepository = _FakeAccountProfilesRepository(const [
      TenantAdminProfileTypeDefinition(
        type: 'venue',
        label: 'Venue',
        allowedTaxonomies: [],
        capabilities: TenantAdminProfileTypeCapabilities(
          isFavoritable: true,
          isPoiEnabled: true,
          hasBio: false,
          hasTaxonomies: false,
          hasAvatar: false,
          hasCover: false,
          hasEvents: false,
        ),
      ),
    ]);

    final TenantAdminLocationSelectionContract locationSelectionService =
        TenantAdminLocationSelectionService();
    final controller = TenantAdminAccountsController(
      accountsRepository: accountsRepository,
      profilesRepository: profilesRepository,
      locationSelectionService: locationSelectionService,
    );

    await controller.createAccountWithProfile(
      name: 'Nova Conta',
      ownershipState: TenantAdminOwnershipState.tenantOwned,
      profileType: 'venue',
      location: const TenantAdminLocation(latitude: -20.0, longitude: -40.0),
    );

    expect(accountsRepository.createCalls, 1);
    expect(profilesRepository.createProfileCalls, 1);
    expect(profilesRepository.lastCreateDisplayName, 'Nova Conta');
    expect(controller.accountsStreamValue.value?.length, 1);
  });

  test('init reloads when tenant scope changes', () async {
    final accountsRepository = _FakeAccountsRepository([
      TenantAdminAccount(
        id: 'acc-1',
        name: 'Conta A',
        slug: 'conta-a',
        document: const TenantAdminDocument(type: 'cpf', number: '000'),
        ownershipState: TenantAdminOwnershipState.tenantOwned,
      ),
    ]);
    final profilesRepository = _FakeAccountProfilesRepository(const [
      TenantAdminProfileTypeDefinition(
        type: 'venue',
        label: 'Venue',
        allowedTaxonomies: [],
        capabilities: TenantAdminProfileTypeCapabilities(
          isFavoritable: true,
          isPoiEnabled: true,
          hasBio: false,
          hasTaxonomies: false,
          hasAvatar: false,
          hasCover: false,
          hasEvents: false,
        ),
      ),
    ]);
    final tenantScope = _FakeTenantScope('tenant-a.test');
    final TenantAdminLocationSelectionContract locationSelectionService =
        TenantAdminLocationSelectionService();
    final controller = TenantAdminAccountsController(
      accountsRepository: accountsRepository,
      profilesRepository: profilesRepository,
      locationSelectionService: locationSelectionService,
      tenantScope: tenantScope,
    );

    await controller.init();
    expect(controller.accountsStreamValue.value?.first.slug, 'conta-a');

    accountsRepository._accounts = [
      TenantAdminAccount(
        id: 'acc-2',
        name: 'Conta B',
        slug: 'conta-b',
        document: const TenantAdminDocument(type: 'cpf', number: '111'),
        ownershipState: TenantAdminOwnershipState.tenantOwned,
      ),
    ];
    tenantScope.selectTenantDomain('tenant-b.test');

    await controller.init();
    expect(controller.accountsStreamValue.value?.first.slug, 'conta-b');
  });

  test('keeps accounts stream null while first page is loading', () async {
    final accountsRepository = _FakeAccountsRepository([
      TenantAdminAccount(
        id: 'acc-1',
        name: 'Conta',
        slug: 'conta',
        document: const TenantAdminDocument(type: 'cpf', number: '000'),
        ownershipState: TenantAdminOwnershipState.tenantOwned,
      ),
    ]);
    accountsRepository.fetchAccountsGate = Completer<void>();
    final profilesRepository = _FakeAccountProfilesRepository(const []);
    final TenantAdminLocationSelectionContract locationSelectionService =
        TenantAdminLocationSelectionService();
    final controller = TenantAdminAccountsController(
      accountsRepository: accountsRepository,
      profilesRepository: profilesRepository,
      locationSelectionService: locationSelectionService,
    );

    final loadFuture = controller.loadAccounts();
    await Future<void>.delayed(Duration.zero);
    expect(controller.accountsStreamValue.value, isNull);

    accountsRepository.fetchAccountsGate?.complete();
    await loadFuture;
    expect(controller.accountsStreamValue.value?.length, 1);
  });

  test('appends pages and stops when hasMore becomes false', () async {
    final accounts = List<TenantAdminAccount>.generate(
      45,
      (index) => TenantAdminAccount(
        id: 'acc-$index',
        name: 'Conta $index',
        slug: 'conta-$index',
        document: TenantAdminDocument(type: 'cpf', number: '$index'),
        ownershipState: TenantAdminOwnershipState.tenantOwned,
      ),
    );
    final accountsRepository = _FakeAccountsRepository(accounts);
    final profilesRepository = _FakeAccountProfilesRepository(const []);
    final TenantAdminLocationSelectionContract locationSelectionService =
        TenantAdminLocationSelectionService();
    final controller = TenantAdminAccountsController(
      accountsRepository: accountsRepository,
      profilesRepository: profilesRepository,
      locationSelectionService: locationSelectionService,
    );

    await controller.loadAccounts();
    expect(controller.accountsStreamValue.value?.length, 20);
    expect(controller.hasMoreAccountsStreamValue.value, isTrue);

    await controller.loadNextAccountsPage();
    expect(controller.accountsStreamValue.value?.length, 40);
    expect(controller.hasMoreAccountsStreamValue.value, isTrue);

    await controller.loadNextAccountsPage();
    expect(controller.accountsStreamValue.value?.length, 45);
    expect(controller.hasMoreAccountsStreamValue.value, isFalse);

    await controller.loadNextAccountsPage();
    expect(controller.accountsStreamValue.value?.length, 45);
    expect(accountsRepository.fetchAccountsCalls, 3);
  });
}

class _FakeTenantScope implements TenantAdminTenantScopeContract {
  _FakeTenantScope(String initialDomain)
      : _selectedTenantDomainStreamValue =
            StreamValue<String?>(defaultValue: initialDomain);

  final StreamValue<String?> _selectedTenantDomainStreamValue;

  @override
  String? get selectedTenantDomain => _selectedTenantDomainStreamValue.value;

  @override
  String get selectedTenantAdminBaseUrl =>
      'https://${selectedTenantDomain ?? ''}/admin/api';

  @override
  StreamValue<String?> get selectedTenantDomainStreamValue =>
      _selectedTenantDomainStreamValue;

  @override
  void clearSelectedTenantDomain() {
    _selectedTenantDomainStreamValue.addValue(null);
  }

  @override
  void selectTenantDomain(String tenantDomain) {
    _selectedTenantDomainStreamValue.addValue(tenantDomain.trim());
  }
}
