import 'dart:io';

import 'package:auto_route/auto_route.dart';
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
import 'package:belluga_now/domain/services/tenant_admin_external_image_proxy_contract.dart';
import 'package:belluga_now/infrastructure/services/tenant_admin/tenant_admin_location_selection_service.dart';
import 'package:belluga_now/presentation/tenant_admin/accounts/controllers/tenant_admin_accounts_controller.dart';
import 'package:belluga_now/presentation/tenant_admin/accounts/screens/tenant_admin_account_create_screen.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/utils/tenant_admin_image_ingestion_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:stream_value/core/stream_value.dart';

class _FakeAccountsRepository
    with TenantAdminAccountsRepositoryPaginationMixin
    implements TenantAdminAccountsRepositoryContract {
  @override
  final StreamValue<List<TenantAdminAccount>?> accountsStreamValue =
      StreamValue<List<TenantAdminAccount>?>(defaultValue: const []);

  @override
  final StreamValue<bool> hasMoreAccountsStreamValue =
      StreamValue<bool>(defaultValue: false);

  @override
  final StreamValue<bool> isAccountsPageLoadingStreamValue =
      StreamValue<bool>(defaultValue: false);

  @override
  final StreamValue<String?> accountsErrorStreamValue = StreamValue<String?>();

  @override
  Future<void> loadAccounts(
      {int pageSize = 20, TenantAdminOwnershipState? ownershipState}) async {}

  @override
  Future<void> loadNextAccountsPage(
      {int pageSize = 20, TenantAdminOwnershipState? ownershipState}) async {}

  @override
  void resetAccountsState() {}

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
    TenantAdminOwnershipState? ownershipState,
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
    with TenantAdminProfileTypesPaginationMixin
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
                  hasContent: false,
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
    String? content,
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
            hasContent: false,
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
    String? content,
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
    with TenantAdminTaxonomiesPaginationMixin
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
  TestWidgetsFlutterBinding.ensureInitialized();

  const pathProviderChannel = MethodChannel('plugins.flutter.io/path_provider');
  final fallbackTempDir =
      Directory.systemTemp.createTempSync('tenant-admin-account-create-test');

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProviderChannel, (call) async {
      if (call.method == 'getTemporaryDirectory') {
        return fallbackTempDir.path;
      }
      return null;
    });
  });

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
    GetIt.I.registerSingleton<TenantAdminExternalImageProxyContract>(
      _FakeExternalImageProxy(),
    );
    GetIt.I.registerSingleton<TenantAdminImageIngestionService>(
      TenantAdminImageIngestionService(),
    );
    GetIt.I.registerSingleton<TenantAdminAccountsController>(
      TenantAdminAccountsController(
        locationSelectionService: locationSelectionService,
      ),
    );
  });

  tearDown(() async {
    await GetIt.I.reset();
  });

  tearDownAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProviderChannel, null);
    if (fallbackTempDir.existsSync()) {
      fallbackTempDir.deleteSync(recursive: true);
    }
  });

  testWidgets(
      'requires location and shows map pick for POI-enabled profile type',
      (tester) async {
    await _pumpWithAutoRoute(
      tester,
      Scaffold(
        body: TenantAdminAccountCreateScreen(),
      ),
    );

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
    await _pumpWithAutoRoute(
      tester,
      Scaffold(
        body: TenantAdminAccountCreateScreen(),
      ),
    );

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

    expect(find.text('Remover'), findsNothing);
    final controller = GetIt.I.get<TenantAdminAccountsController>();
    controller.updateCreateAvatarFile(avatarFile);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('tenant_admin_account_create_avatar_remove')),
      findsOneWidget,
    );

    final avatarRemove = find.byKey(
      const ValueKey('tenant_admin_account_create_avatar_remove'),
    );
    await tester.ensureVisible(avatarRemove);
    await tester.tap(avatarRemove, warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(find.text('Remover'), findsNothing);
    controller.updateCreateCoverFile(coverFile);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('tenant_admin_account_create_cover_remove')),
      findsOneWidget,
    );
  });

  testWidgets('disables avatar pick and shows progress when busy', (tester) async {
    await _pumpWithAutoRoute(
      tester,
      const Scaffold(
        body: TenantAdminAccountCreateScreen(),
      ),
    );

    final profileTypeDropdown = find.byType(DropdownButtonFormField<String>);
    await tester.ensureVisible(profileTypeDropdown.last);
    await tester.tap(profileTypeDropdown.last, warnIfMissed: false);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Venue').last);
    await tester.pumpAndSettle();

    final controller = GetIt.I.get<TenantAdminAccountsController>();
    controller.updateCreateAvatarBusy(true);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byType(LinearProgressIndicator), findsAtLeastNWidgets(1));

    final pickButton =
        find.byKey(const ValueKey('tenant_admin_account_create_avatar_pick'));
    final button = tester.widget<FilledButton>(pickButton);
    expect(button.onPressed, isNull);
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
          hasContent: false,
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

    await _pumpWithAutoRoute(
      tester,
      const Scaffold(
        body: TenantAdminAccountCreateScreen(),
      ),
    );

    await tester.tap(find.byType(DropdownButtonFormField<String>).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Completo').last);
    await tester.pumpAndSettle();

    expect(find.text('Bio'), findsOneWidget);
    expect(find.text('Taxonomias'), findsOneWidget);
    expect(find.text('Urbana'), findsOneWidget);

    await tester.enterText(
        find.widgetWithText(TextFormField, 'Nome'), 'Conta A');
    final controller = GetIt.I.get<TenantAdminAccountsController>();
    controller.bioController.text = '<p>Bio teste</p>';
    await tester.pump();
    final urbanaChip = find.text('Urbana').last;
    await tester.ensureVisible(urbanaChip);
    await tester.tap(urbanaChip, warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(controller.bioController.text, '<p>Bio teste</p>');
    expect(
      controller.selectedTaxonomyTermsStreamValue.value['genre'],
      equals({'urbana'}),
    );
  });
}

Future<void> _pumpWithAutoRoute(
  WidgetTester tester,
  Widget child,
) async {
  final router = RootStackRouter.build(
    routes: [
      NamedRouteDef(
        name: 'account-create-test',
        path: '/',
        builder: (_, __) => child,
      ),
    ],
  );

  await tester.pumpWidget(
    MaterialApp.router(
      routeInformationParser: router.defaultRouteParser(),
      routerDelegate: router.delegate(),
    ),
  );
  await tester.pumpAndSettle();
}

XFile _createTempImageFile(String name) {
  final dir = Directory.systemTemp.createTempSync('belluga_test_');
  final file = File('${dir.path}/$name');
  final image = img.Image(width: 64, height: 64);
  img.fill(image, color: img.ColorRgb8(120, 45, 180));
  file.writeAsBytesSync(img.encodePng(image), flush: true);
  return XFile(file.path, name: name, mimeType: 'image/png');
}

class _FakeExternalImageProxy implements TenantAdminExternalImageProxyContract {
  @override
  Future<Uint8List> fetchExternalImageBytes({required String imageUrl}) async {
    throw UnimplementedError();
  }
}
