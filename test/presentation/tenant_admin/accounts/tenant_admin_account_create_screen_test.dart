import 'dart:io';

import 'package:belluga_now/domain/repositories/tenant_admin_account_profiles_repository_contract.dart';
import 'package:belluga_now/domain/repositories/tenant_admin_accounts_repository_contract.dart';
import 'package:belluga_now/domain/repositories/tenant_admin_taxonomies_repository_contract.dart';
import 'package:belluga_now/domain/tenant_admin/ownership_state.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_account.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_account_profile.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_document.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_location.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_media_upload.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_paged_accounts_result.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_paged_result.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_profile_type.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_definition.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_term.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_term_definition.dart';
import 'package:belluga_now/domain/services/tenant_admin_location_selection_contract.dart';
import 'package:belluga_now/infrastructure/services/tenant_admin/tenant_admin_location_selection_service.dart';
import 'package:belluga_now/presentation/tenant_admin/accounts/controllers/tenant_admin_accounts_controller.dart';
import 'package:belluga_now/presentation/tenant_admin/accounts/screens/tenant_admin_account_create_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';

class _FakeAccountsRepository implements TenantAdminAccountsRepositoryContract {
  @override
  Future<TenantAdminAccount> createAccount({
    required String name,
    TenantAdminDocument? document,
    required TenantAdminOwnershipState ownershipState,
    String? organizationId,
  }) async {
    return TenantAdminAccount(
      id: 'acc-1',
      name: name,
      slug: 'acc-1',
      document:
          document ?? const TenantAdminDocument(type: 'cpf', number: '000'),
      ownershipState: ownershipState,
      organizationId: organizationId,
    );
  }

  @override
  Future<void> deleteAccount(String accountSlug) async {}

  @override
  Future<TenantAdminAccount> fetchAccountBySlug(String accountSlug) async {
    return TenantAdminAccount(
      id: 'acc-1',
      name: 'Conta',
      slug: accountSlug,
      document: const TenantAdminDocument(type: 'cpf', number: '000'),
      ownershipState: TenantAdminOwnershipState.tenantOwned,
    );
  }

  @override
  Future<List<TenantAdminAccount>> fetchAccounts() async {
    return const [];
  }

  @override
  Future<TenantAdminPagedAccountsResult> fetchAccountsPage({
    required int page,
    required int pageSize,
  }) async {
    return const TenantAdminPagedAccountsResult(
      accounts: <TenantAdminAccount>[],
      hasMore: false,
    );
  }

  @override
  Future<void> forceDeleteAccount(String accountSlug) async {}

  @override
  Future<TenantAdminAccount> restoreAccount(String accountSlug) async {
    return TenantAdminAccount(
      id: 'acc-1',
      name: 'Conta',
      slug: accountSlug,
      document: const TenantAdminDocument(type: 'cpf', number: '000'),
      ownershipState: TenantAdminOwnershipState.tenantOwned,
    );
  }

  @override
  Future<TenantAdminAccount> updateAccount({
    required String accountSlug,
    String? name,
    String? slug,
    TenantAdminDocument? document,
  }) async {
    return TenantAdminAccount(
      id: 'acc-1',
      name: name ?? 'Conta',
      slug: accountSlug,
      document:
          document ?? const TenantAdminDocument(type: 'cpf', number: '000'),
      ownershipState: TenantAdminOwnershipState.tenantOwned,
    );
  }
}

class _FakeAccountProfilesRepository
    implements TenantAdminAccountProfilesRepositoryContract {
  _FakeAccountProfilesRepository({
    List<TenantAdminProfileTypeDefinition>? profileTypes,
  }) : _profileTypes = profileTypes ??
            const [
              TenantAdminProfileTypeDefinition(
                type: 'venue',
                label: 'Venue',
                allowedTaxonomies: [],
                capabilities: TenantAdminProfileTypeCapabilities(
                  isFavoritable: true,
                  isPoiEnabled: true,
                  hasBio: false,
                  hasTaxonomies: false,
                  hasAvatar: true,
                  hasCover: true,
                  hasEvents: false,
                ),
              ),
            ];

  List<TenantAdminProfileTypeDefinition> _profileTypes;
  String? lastCreateBio;
  List<TenantAdminTaxonomyTerm> lastCreateTaxonomyTerms = const [];

  @override
  Future<List<TenantAdminProfileTypeDefinition>> fetchProfileTypes() async {
    return _profileTypes;
  }

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
    lastCreateBio = bio;
    lastCreateTaxonomyTerms = List<TenantAdminTaxonomyTerm>.from(taxonomyTerms);
    return TenantAdminAccountProfile(
      id: 'profile-1',
      accountId: accountId,
      profileType: profileType,
      displayName: displayName,
      location: location,
      taxonomyTerms: taxonomyTerms,
    );
  }

  @override
  Future<void> deleteAccountProfile(String accountProfileId) async {}

  @override
  Future<void> forceDeleteAccountProfile(String accountProfileId) async {}

  @override
  Future<TenantAdminAccountProfile> fetchAccountProfile(
      String accountProfileId) async {
    return const TenantAdminAccountProfile(
      id: 'profile-1',
      accountId: 'acc-1',
      profileType: 'venue',
      displayName: 'Perfil',
    );
  }

  @override
  Future<List<TenantAdminAccountProfile>> fetchAccountProfiles({
    String? accountId,
  }) async {
    return const [];
  }

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
  Future<void> deleteProfileType(String type) async {}

  @override
  Future<TenantAdminAccountProfile> restoreAccountProfile(
      String accountProfileId) async {
    return const TenantAdminAccountProfile(
      id: 'profile-1',
      accountId: 'acc-1',
      profileType: 'venue',
      displayName: 'Perfil',
    );
  }

  @override
  Future<TenantAdminProfileTypeDefinition> updateProfileType({
    required String type,
    String? newType,
    String? label,
    List<String>? allowedTaxonomies,
    TenantAdminProfileTypeCapabilities? capabilities,
  }) async {
    return TenantAdminProfileTypeDefinition(
      type: type,
      label: label ?? 'Venue',
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
  Future<TenantAdminAccountProfile> updateAccountProfile({
    required String accountProfileId,
    String? profileType,
    String? displayName,
    String? slug,
    TenantAdminLocation? location,
    List<TenantAdminTaxonomyTerm>? taxonomyTerms,
    String? bio,
    String? avatarUrl,
    String? coverUrl,
    TenantAdminMediaUpload? avatarUpload,
    TenantAdminMediaUpload? coverUpload,
  }) async {
    return TenantAdminAccountProfile(
      id: accountProfileId,
      accountId: 'acc-1',
      profileType: profileType ?? 'venue',
      displayName: displayName ?? 'Perfil',
      location: location,
      taxonomyTerms: taxonomyTerms ?? const [],
    );
  }
}

class _FakeTaxonomiesRepository
    implements TenantAdminTaxonomiesRepositoryContract {
  _FakeTaxonomiesRepository({
    List<TenantAdminTaxonomyDefinition>? taxonomies,
    Map<String, List<TenantAdminTaxonomyTermDefinition>>? termsByTaxonomyId,
  })  : _taxonomies = taxonomies ?? const [],
        _termsByTaxonomyId = termsByTaxonomyId ?? const {};

  List<TenantAdminTaxonomyDefinition> _taxonomies;
  Map<String, List<TenantAdminTaxonomyTermDefinition>> _termsByTaxonomyId;

  @override
  Future<TenantAdminTaxonomyDefinition> createTaxonomy({
    required String slug,
    required String name,
    required List<String> appliesTo,
    String? icon,
    String? color,
  }) async {
    return TenantAdminTaxonomyDefinition(
      id: 'tax-1',
      slug: slug,
      name: name,
      appliesTo: appliesTo,
      icon: icon,
      color: color,
    );
  }

  @override
  Future<TenantAdminTaxonomyTermDefinition> createTerm({
    required String taxonomyId,
    required String slug,
    required String name,
  }) async {
    return TenantAdminTaxonomyTermDefinition(
      id: 'term-1',
      taxonomyId: taxonomyId,
      slug: slug,
      name: name,
    );
  }

  @override
  Future<void> deleteTaxonomy(String taxonomyId) async {}

  @override
  Future<void> deleteTerm({
    required String taxonomyId,
    required String termId,
  }) async {}

  @override
  Future<List<TenantAdminTaxonomyDefinition>> fetchTaxonomies() async =>
      List<TenantAdminTaxonomyDefinition>.from(_taxonomies);

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
  }) async =>
      List<TenantAdminTaxonomyTermDefinition>.from(
        _termsByTaxonomyId[taxonomyId] ?? const [],
      );

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
  }) async {
    return TenantAdminTaxonomyDefinition(
      id: taxonomyId,
      slug: slug ?? 'taxonomy',
      name: name ?? 'Taxonomy',
      appliesTo: appliesTo ?? const [],
      icon: icon,
      color: color,
    );
  }

  @override
  Future<TenantAdminTaxonomyTermDefinition> updateTerm({
    required String taxonomyId,
    required String termId,
    String? slug,
    String? name,
  }) async {
    return TenantAdminTaxonomyTermDefinition(
      id: termId,
      taxonomyId: taxonomyId,
      slug: slug ?? 'term',
      name: name ?? 'Term',
    );
  }
}

void main() {
  final originalImagePicker = ImagePickerPlatform.instance;

  setUp(() async {
    await GetIt.I.reset();
    GetIt.I.registerSingleton<TenantAdminAccountsRepositoryContract>(
      _FakeAccountsRepository(),
    );
    GetIt.I.registerSingleton<TenantAdminAccountProfilesRepositoryContract>(
      _FakeAccountProfilesRepository(),
    );
    GetIt.I.registerSingleton<TenantAdminTaxonomiesRepositoryContract>(
      _FakeTaxonomiesRepository(),
    );
    final TenantAdminLocationSelectionContract locationSelectionService =
        TenantAdminLocationSelectionService();
    GetIt.I.registerSingleton<TenantAdminLocationSelectionContract>(
      locationSelectionService,
    );
    GetIt.I.registerSingleton<TenantAdminAccountsController>(
      TenantAdminAccountsController(
        locationSelectionService: locationSelectionService,
      ),
    );
  });

  tearDown(() async {
    await GetIt.I.reset();
    ImagePickerPlatform.instance = originalImagePicker;
  });

  testWidgets(
      'requires location and shows map pick for POI-enabled profile type',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TenantAdminAccountCreateScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final profileTypeDropdown = find.byType(DropdownButtonFormField<String>);
    await tester.ensureVisible(profileTypeDropdown.last);
    await tester.tap(profileTypeDropdown.last, warnIfMissed: false);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Venue').last);
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nome'),
      'Conta Teste',
    );

    expect(
      find.byKey(const ValueKey('tenant_admin_account_create_map_pick')),
      findsOneWidget,
    );

    final saveButton =
        find.byKey(const ValueKey('tenant_admin_account_create_save'));
    await tester.ensureVisible(saveButton);
    await tester.tap(saveButton, warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(
      find.text('Localização é obrigatória para este perfil.'),
      findsOneWidget,
    );
  });

  testWidgets('shows selected avatar and allows clear', (tester) async {
    final avatarFile = _createTempImageFile('avatar.png');
    final coverFile = _createTempImageFile('cover.png');
    ImagePickerPlatform.instance = _FakeImagePickerPlatform([
      avatarFile,
      coverFile,
    ]);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TenantAdminAccountCreateScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('tenant_admin_account_create_avatar_pick')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('tenant_admin_account_create_cover_pick')),
      findsNothing,
    );

    final profileTypeDropdown = find.byType(DropdownButtonFormField<String>);
    await tester.ensureVisible(profileTypeDropdown.last);
    await tester.tap(profileTypeDropdown.last, warnIfMissed: false);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Venue').last);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('tenant_admin_account_create_avatar_pick')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('tenant_admin_account_create_cover_pick')),
      findsOneWidget,
    );

    expect(find.byIcon(Icons.person_outline), findsOneWidget);
    expect(find.text('Remover'), findsNothing);

    final avatarPick =
        find.byKey(const ValueKey('tenant_admin_account_create_avatar_pick'));
    await tester.ensureVisible(avatarPick);
    await tester.tap(avatarPick);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Do dispositivo').last);
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.person_outline), findsNothing);
    expect(find.text('Remover'), findsOneWidget);

    final avatarRemove = find.byKey(
      const ValueKey('tenant_admin_account_create_avatar_remove'),
    );
    await tester.tap(avatarRemove);
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.person_outline), findsOneWidget);
    expect(find.text('Remover'), findsNothing);

    final coverPick =
        find.byKey(const ValueKey('tenant_admin_account_create_cover_pick'));
    await tester.ensureVisible(coverPick);
    await tester.tap(coverPick);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Do dispositivo').last);
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.image_outlined), findsNothing);
    expect(find.text('Remover'), findsOneWidget);
  });

  testWidgets('shows bio and taxonomy fields in account create flow', (
    tester,
  ) async {
    final profilesRepository =
        GetIt.I.get<TenantAdminAccountProfilesRepositoryContract>()
            as _FakeAccountProfilesRepository;
    profilesRepository._profileTypes = const [
      TenantAdminProfileTypeDefinition(
        type: 'complete',
        label: 'Completo',
        allowedTaxonomies: ['genre'],
        capabilities: TenantAdminProfileTypeCapabilities(
          isFavoritable: true,
          isPoiEnabled: false,
          hasBio: true,
          hasTaxonomies: true,
          hasAvatar: false,
          hasCover: false,
          hasEvents: false,
        ),
      ),
    ];
    final taxonomiesRepository =
        GetIt.I.get<TenantAdminTaxonomiesRepositoryContract>()
            as _FakeTaxonomiesRepository;
    taxonomiesRepository
      .._taxonomies = const [
        TenantAdminTaxonomyDefinition(
          id: 'tax-1',
          slug: 'genre',
          name: 'Genero',
          appliesTo: ['account_profile'],
          icon: null,
          color: null,
        ),
      ]
      .._termsByTaxonomyId = const {
        'tax-1': [
          TenantAdminTaxonomyTermDefinition(
            id: 'term-1',
            taxonomyId: 'tax-1',
            slug: 'urbana',
            name: 'Urbana',
          ),
        ],
      };

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: TenantAdminAccountCreateScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(DropdownButtonFormField<String>).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Completo').last);
    await tester.pumpAndSettle();

    expect(find.text('Bio'), findsOneWidget);
    expect(find.text('Taxonomias'), findsOneWidget);
    expect(find.text('Urbana'), findsOneWidget);

    await tester.enterText(
        find.widgetWithText(TextFormField, 'Nome'), 'Conta A');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Bio'), '<p>Bio teste</p>');
    final urbanaChip = find.text('Urbana').last;
    await tester.ensureVisible(urbanaChip);
    await tester.tap(urbanaChip, warnIfMissed: false);
    await tester.pumpAndSettle();
    final controller = GetIt.I.get<TenantAdminAccountsController>();
    expect(controller.bioController.text, '<p>Bio teste</p>');
    expect(
      controller.selectedTaxonomyTermsStreamValue.value['genre'],
      equals({'urbana'}),
    );
  });
}

XFile _createTempImageFile(String name) {
  final dir = Directory.systemTemp.createTempSync('belluga_test_');
  final file = File('${dir.path}/$name');
  file.writeAsBytesSync([0, 1, 2, 3, 4]);
  return XFile(file.path, name: name, mimeType: 'image/png');
}

class _FakeImagePickerPlatform extends ImagePickerPlatform {
  _FakeImagePickerPlatform(this._queue);

  final List<XFile> _queue;

  @override
  Future<XFile?> getImageFromSource({
    required ImageSource source,
    ImagePickerOptions options = const ImagePickerOptions(),
  }) async {
    if (_queue.isEmpty) return null;
    return _queue.removeAt(0);
  }
}
