import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/application/router/support/canonical_route_family.dart';
import 'package:belluga_now/application/router/support/canonical_route_meta.dart';
import 'package:belluga_now/domain/app_data/app_data.dart';
import 'package:belluga_now/domain/partners/account_profile_model.dart';
import 'package:belluga_now/domain/partners/paged_account_profiles_result.dart';
import 'package:belluga_now/domain/repositories/account_profiles_repository_contract.dart';
import 'package:belluga_now/domain/repositories/tenant_admin_account_profiles_repository_contract.dart';
import 'package:belluga_now/domain/repositories/tenant_admin_accounts_repository_contract.dart';
import 'package:belluga_now/domain/repositories/tenant_admin_taxonomies_repository_contract.dart';
import 'package:belluga_now/domain/services/tenant_admin_location_selection_contract.dart';
import 'package:belluga_now/domain/tenant_admin/ownership_state.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_account.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_account_onboarding_result.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_account_profile.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_document.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_location.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_media_upload.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_paged_accounts_result.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_profile_type.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_definition.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_term_definition.dart';
import 'package:belluga_now/presentation/tenant_admin/account_profiles/controllers/tenant_admin_account_profiles_controller.dart';
import 'package:belluga_now/presentation/tenant_admin/account_profiles/screens/tenant_admin_account_profile_edit_screen.dart';
import 'package:belluga_now/presentation/tenant_admin/accounts/controllers/tenant_admin_account_detail_controller.dart';
import 'package:belluga_now/presentation/tenant_admin/accounts/screens/tenant_admin_account_detail_screen.dart';
import 'package:belluga_now/presentation/tenant_public/partners/account_profile_detail_screen.dart';
import 'package:belluga_now/presentation/tenant_public/partners/controllers/account_profile_detail_controller.dart';
import 'package:belluga_now/testing/account_profile_model_factory.dart';
import 'package:belluga_now/testing/app_data_test_factory.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:integration_test/integration_test.dart';
import 'package:stream_value/core/stream_value.dart';

import 'support/integration_test_bootstrap.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  IntegrationTestBootstrap.ensureNonProductionLandlordDomain();

  setUp(() async {
    await GetIt.I.reset();
    GetIt.I.registerSingleton<AppData>(_buildAppData());
  });

  tearDown(() async {
    await GetIt.I.reset();
  });

  testWidgets(
    'tenant admin edit persists rich bio/content and admin/public readback remains faithful',
    (tester) async {
      final accountsRepository = _RichTextAccountsRepository();
      final profilesRepository = _RichTextProfilesRepository();
      final taxonomiesRepository = _EmptyTaxonomiesRepository();
      final adminController = TenantAdminAccountProfilesController(
        profilesRepository: profilesRepository,
        accountsRepository: accountsRepository,
        taxonomiesRepository: taxonomiesRepository,
        locationSelectionService: _NoopLocationSelectionService(),
      );
      GetIt.I.registerSingleton<TenantAdminAccountProfilesController>(
        adminController,
      );

      await _pumpAdminRoute(
        tester,
        const TenantAdminAccountProfileEditScreen(
          accountSlug: 'casa-cultural',
          accountProfileId: 'profile-rich-1',
        ),
      );

      const editedBio = '<h2>Bio Heading 🎉</h2>'
          '<p><strong>Bold bio</strong><br />Second bio line</p>'
          '<blockquote>Bio quote</blockquote>'
          '<ul><li>Bio bullet</li></ul>';
      const editedContent = '<h3>Content Heading</h3>'
          '<p><em>Italic content</em> and <s>strike content</s> 😄</p>'
          '<ol><li>Content ordered</li></ol>';

      adminController.bioController.text = editedBio;
      adminController.contentController.text = editedContent;
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.widgetWithText(FilledButton, 'Salvar alteracoes'),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Salvar alteracoes'));
      await tester.pumpAndSettle();

      expect(profilesRepository.updateCalls, 1);
      expect(profilesRepository.current.bio, contains('Bio Heading 🎉'));
      expect(profilesRepository.current.bio, contains('Bold bio'));
      expect(profilesRepository.current.bio, contains('Bio quote'));
      expect(profilesRepository.current.bio, contains('Bio bullet'));
      expect(profilesRepository.current.content, contains('Content Heading'));
      expect(profilesRepository.current.content, contains('Italic content'));
      expect(profilesRepository.current.content, contains('strike content'));
      expect(profilesRepository.current.content, contains('😄'));
      expect(profilesRepository.current.content, contains('Content ordered'));

      await GetIt.I.unregister<TenantAdminAccountProfilesController>();
      GetIt.I.registerSingleton<TenantAdminAccountDetailController>(
        TenantAdminAccountDetailController(
          profilesRepository: profilesRepository,
          accountsRepository: accountsRepository,
        ),
      );

      await _pumpAdminRoute(
        tester,
        const TenantAdminAccountDetailScreen(accountSlug: 'casa-cultural'),
      );

      expect(find.text('Bio'), findsOneWidget);
      expect(find.text('Conteúdo'), findsOneWidget);
      expect(find.text('Bio Heading 🎉'), findsOneWidget);
      expect(find.text('Bold bio'), findsOneWidget);
      expect(find.text('Second bio line'), findsOneWidget);
      expect(find.text('Bio quote'), findsOneWidget);
      expect(find.text('Bio bullet'), findsOneWidget);
      expect(find.text('Content Heading'), findsOneWidget);
      expect(find.textContaining('Italic content'), findsWidgets);
      expect(find.textContaining('strike content'), findsWidgets);
      expect(find.textContaining('😄'), findsWidgets);
      expect(find.text('Content ordered'), findsOneWidget);
      expect(find.textContaining('<h2>'), findsNothing);
      expect(find.textContaining('<strong>'), findsNothing);

      final publicRepository = _PublicAccountProfilesRepository(
        _publicProfileFromAdmin(profilesRepository.current),
      );
      GetIt.I.registerSingleton<AccountProfileDetailController>(
        AccountProfileDetailController(
          accountProfilesRepository: publicRepository,
        ),
      );

      await tester.pumpWidget(
        _PublicRouteHost(
          child: AccountProfileDetailScreen(
            accountProfile: publicRepository.profile,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Sobre'), findsNWidgets(2));
      expect(find.text('Conteúdo'), findsOneWidget);
      expect(find.text('Bio Heading 🎉'), findsOneWidget);
      expect(find.text('Bold bio'), findsOneWidget);
      expect(find.text('Second bio line'), findsOneWidget);
      expect(find.text('Bio quote'), findsOneWidget);
      expect(find.text('Bio bullet'), findsOneWidget);
      expect(find.text('Content Heading'), findsOneWidget);
      expect(find.textContaining('Italic content'), findsWidgets);
      expect(find.textContaining('strike content'), findsWidgets);
      expect(find.textContaining('😄'), findsWidgets);
      expect(find.text('Content ordered'), findsOneWidget);
      expect(find.textContaining('<h3>'), findsNothing);
      expect(find.textContaining('<em>'), findsNothing);
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );
}

Future<void> _pumpAdminRoute(WidgetTester tester, Widget child) async {
  final router = RootStackRouter.build(
    routes: [
      NamedRouteDef(
        name: 'account-profile-rich-text-integration-test',
        path: '/',
        meta: canonicalRouteMeta(
          family: CanonicalRouteFamily.tenantAdminAccountsInternal,
          chromeMode: RouteChromeMode.fullscreen,
        ),
        builder: (_, __) => child,
      ),
    ],
  )..ignorePopCompleters = true;

  await tester.pumpWidget(
    MaterialApp.router(
      locale: const Locale('pt', 'BR'),
      supportedLocales: const <Locale>[Locale('pt', 'BR')],
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routeInformationParser: router.defaultRouteParser(),
      routerDelegate: router.delegate(),
    ),
  );
  await tester.pumpAndSettle();
}

class _PublicRouteHost extends StatelessWidget {
  const _PublicRouteHost({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final router = _RecordingStackRouter();
    final routeData = RouteData(
      route: _FakeRouteMatch(fullPath: '/parceiro/casa-cultural'),
      router: router,
      stackKey: const ValueKey<String>('stack'),
      pendingChildren: const [],
      type: const RouteType.material(),
    );

    return StackRouterScope(
      controller: router,
      stateHash: 0,
      child: MaterialApp(
        locale: const Locale('pt', 'BR'),
        supportedLocales: const <Locale>[Locale('pt', 'BR')],
        localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: RouteDataScope(
          routeData: routeData,
          child: child,
        ),
      ),
    );
  }
}

class _RecordingStackRouter extends Fake implements StackRouter {
  @override
  RootStackRouter get root => _FakeRootStackRouter('/parceiro/casa-cultural');

  @override
  Future<T?> pushPath<T extends Object?>(
    String path, {
    bool includePrefixMatches = false,
    OnNavigationFailure? onFailure,
  }) async {
    return null;
  }

  @override
  Future<T?> replacePath<T extends Object?>(
    String path, {
    bool includePrefixMatches = false,
    OnNavigationFailure? onFailure,
  }) async {
    return null;
  }
}

class _FakeRootStackRouter extends Fake implements RootStackRouter {
  _FakeRootStackRouter(this.currentPath);

  @override
  final String currentPath;

  @override
  Object? get pathState => null;

  @override
  RootStackRouter get root => this;
}

class _FakeRouteMatch extends Fake implements RouteMatch {
  _FakeRouteMatch({required this.fullPath})
      : meta = canonicalRouteMeta(
          family: CanonicalRouteFamily.partnerDetail,
        );

  @override
  final String fullPath;

  @override
  String get name => PartnerDetailRoute.name;

  @override
  final Map<String, dynamic> meta;

  @override
  Parameters get queryParams => const Parameters({});

  @override
  PageRouteInfo<dynamic> toPageRouteInfo() => const DiscoveryRoute();
}

class _RichTextAccountsRepository
    extends TenantAdminAccountsRepositoryContract {
  final TenantAdminAccount account = tenantAdminAccountFromRaw(
    id: 'account-rich-1',
    name: 'Casa Cultural',
    slug: 'casa-cultural',
    document: tenantAdminDocumentFromRaw(type: 'cnpj', number: '000'),
    ownershipState: TenantAdminOwnershipState.tenantOwned,
  );

  @override
  Future<List<TenantAdminAccount>> fetchAccounts() async => [account];

  @override
  Future<TenantAdminPagedAccountsResult> fetchAccountsPage({
    required TenantAdminAccountsRepositoryContractPrimInt page,
    required TenantAdminAccountsRepositoryContractPrimInt pageSize,
    TenantAdminOwnershipState? ownershipState,
    TenantAdminAccountsRepositoryContractPrimString? searchQuery,
  }) async {
    return tenantAdminPagedAccountsResultFromRaw(
      accounts: [account],
      hasMore: false,
    );
  }

  @override
  Future<TenantAdminAccount> fetchAccountBySlug(
    TenantAdminAccountsRepositoryContractPrimString accountSlug,
  ) async {
    return account;
  }

  @override
  Future<TenantAdminAccount> createAccount({
    required TenantAdminAccountsRepositoryContractPrimString name,
    TenantAdminDocument? document,
    required TenantAdminOwnershipState ownershipState,
    TenantAdminAccountsRepositoryContractPrimString? organizationId,
  }) async {
    return account;
  }

  @override
  Future<TenantAdminAccountOnboardingResult> createAccountOnboarding({
    required TenantAdminAccountsRepositoryContractPrimString name,
    required TenantAdminOwnershipState ownershipState,
    required TenantAdminAccountsRepositoryContractPrimString profileType,
    TenantAdminLocation? location,
    TenantAdminTaxonomyTerms taxonomyTerms =
        const TenantAdminTaxonomyTerms.empty(),
    TenantAdminAccountsRepositoryContractPrimString? bio,
    TenantAdminAccountsRepositoryContractPrimString? content,
    TenantAdminMediaUpload? avatarUpload,
    TenantAdminMediaUpload? coverUpload,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<TenantAdminAccount> updateAccount({
    required TenantAdminAccountsRepositoryContractPrimString accountSlug,
    TenantAdminAccountsRepositoryContractPrimString? name,
    TenantAdminAccountsRepositoryContractPrimString? slug,
    TenantAdminDocument? document,
    TenantAdminOwnershipState? ownershipState,
  }) async {
    return account;
  }

  @override
  Future<void> deleteAccount(
    TenantAdminAccountsRepositoryContractPrimString accountSlug,
  ) async {}

  @override
  Future<TenantAdminAccount> restoreAccount(
    TenantAdminAccountsRepositoryContractPrimString accountSlug,
  ) async {
    return account;
  }

  @override
  Future<void> forceDeleteAccount(
    TenantAdminAccountsRepositoryContractPrimString accountSlug,
  ) async {}
}

class _RichTextProfilesRepository
    extends TenantAdminAccountProfilesRepositoryContract {
  _RichTextProfilesRepository()
      : current = tenantAdminAccountProfileFromRaw(
          id: 'profile-rich-1',
          accountId: 'account-rich-1',
          profileType: 'rich',
          displayName: 'Casa Cultural',
          slug: 'casa-cultural',
          bio: '<p>Bio inicial</p>',
          content: '<p>Conteudo inicial</p>',
        );

  TenantAdminAccountProfile current;
  int updateCalls = 0;

  @override
  Future<List<TenantAdminAccountProfile>> fetchAccountProfiles({
    TenantAdminAccountProfilesRepoString? accountId,
  }) async {
    return [current];
  }

  @override
  Future<TenantAdminAccountProfile> fetchAccountProfile(
    TenantAdminAccountProfilesRepoString accountProfileId,
  ) async {
    return current;
  }

  @override
  Future<TenantAdminAccountProfile> createAccountProfile({
    required TenantAdminAccountProfilesRepoString accountId,
    required TenantAdminAccountProfilesRepoString profileType,
    required TenantAdminAccountProfilesRepoString displayName,
    TenantAdminLocation? location,
    TenantAdminTaxonomyTerms taxonomyTerms =
        const TenantAdminTaxonomyTerms.empty(),
    TenantAdminAccountProfilesRepoString? bio,
    TenantAdminAccountProfilesRepoString? content,
    TenantAdminAccountProfilesRepoString? avatarUrl,
    TenantAdminAccountProfilesRepoString? coverUrl,
    TenantAdminMediaUpload? avatarUpload,
    TenantAdminMediaUpload? coverUpload,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<TenantAdminAccountProfile> updateAccountProfile({
    required TenantAdminAccountProfilesRepoString accountProfileId,
    TenantAdminAccountProfilesRepoString? profileType,
    TenantAdminAccountProfilesRepoString? displayName,
    TenantAdminAccountProfilesRepoString? slug,
    TenantAdminLocation? location,
    TenantAdminTaxonomyTerms? taxonomyTerms,
    TenantAdminAccountProfilesRepoString? bio,
    TenantAdminAccountProfilesRepoString? content,
    TenantAdminAccountProfilesRepoString? avatarUrl,
    TenantAdminAccountProfilesRepoString? coverUrl,
    TenantAdminAccountProfilesRepoBool? removeAvatar,
    TenantAdminAccountProfilesRepoBool? removeCover,
    TenantAdminMediaUpload? avatarUpload,
    TenantAdminMediaUpload? coverUpload,
  }) async {
    updateCalls += 1;
    current = tenantAdminAccountProfileFromRaw(
      id: current.id,
      accountId: current.accountId,
      profileType: profileType?.value ?? current.profileType,
      displayName: displayName?.value ?? current.displayName,
      slug: slug?.value ?? current.slug,
      location: location,
      taxonomyTerms: taxonomyTerms ?? current.taxonomyTerms,
      bio: bio?.value ?? current.bio,
      content: content?.value ?? current.content,
      avatarUrl: avatarUrl?.value ?? current.avatarUrl,
      coverUrl: coverUrl?.value ?? current.coverUrl,
    );
    return current;
  }

  @override
  Future<void> deleteAccountProfile(
    TenantAdminAccountProfilesRepoString accountProfileId,
  ) async {}

  @override
  Future<TenantAdminAccountProfile> restoreAccountProfile(
    TenantAdminAccountProfilesRepoString accountProfileId,
  ) async {
    return current;
  }

  @override
  Future<void> forceDeleteAccountProfile(
    TenantAdminAccountProfilesRepoString accountProfileId,
  ) async {}

  @override
  Future<List<TenantAdminProfileTypeDefinition>> fetchProfileTypes() async {
    return [
      tenantAdminProfileTypeDefinitionFromRaw(
        type: 'rich',
        label: 'Rich Profile',
        allowedTaxonomies: const [],
        capabilities: TenantAdminProfileTypeCapabilities(
          isFavoritable: TenantAdminFlagValue(true),
          isPoiEnabled: TenantAdminFlagValue(false),
          hasBio: TenantAdminFlagValue(true),
          hasContent: TenantAdminFlagValue(true),
          hasTaxonomies: TenantAdminFlagValue(false),
          hasAvatar: TenantAdminFlagValue(false),
          hasCover: TenantAdminFlagValue(false),
          hasEvents: TenantAdminFlagValue(false),
        ),
      ),
    ];
  }

  @override
  Future<TenantAdminProfileTypeDefinition> createProfileType({
    required TenantAdminAccountProfilesRepoString type,
    required TenantAdminAccountProfilesRepoString label,
    List<TenantAdminAccountProfilesRepoString> allowedTaxonomies = const [],
    required TenantAdminProfileTypeCapabilities capabilities,
  }) async {
    return tenantAdminProfileTypeDefinitionFromRaw(
      type: type.value,
      label: label.value,
      allowedTaxonomies: allowedTaxonomies.map((value) => value.value).toList(),
      capabilities: capabilities,
    );
  }

  @override
  Future<TenantAdminProfileTypeDefinition> updateProfileType({
    required TenantAdminAccountProfilesRepoString type,
    TenantAdminAccountProfilesRepoString? newType,
    TenantAdminAccountProfilesRepoString? label,
    List<TenantAdminAccountProfilesRepoString>? allowedTaxonomies,
    TenantAdminProfileTypeCapabilities? capabilities,
  }) async {
    return tenantAdminProfileTypeDefinitionFromRaw(
      type: newType?.value ?? type.value,
      label: label?.value ?? 'Rich Profile',
      allowedTaxonomies:
          allowedTaxonomies?.map((value) => value.value).toList() ?? const [],
      capabilities: capabilities ??
          TenantAdminProfileTypeCapabilities(
            isFavoritable: TenantAdminFlagValue(true),
            isPoiEnabled: TenantAdminFlagValue(false),
            hasBio: TenantAdminFlagValue(true),
            hasContent: TenantAdminFlagValue(true),
            hasTaxonomies: TenantAdminFlagValue(false),
            hasAvatar: TenantAdminFlagValue(false),
            hasCover: TenantAdminFlagValue(false),
            hasEvents: TenantAdminFlagValue(false),
          ),
    );
  }

  @override
  Future<void> deleteProfileType(
      TenantAdminAccountProfilesRepoString type) async {}
}

class _EmptyTaxonomiesRepository
    extends TenantAdminTaxonomiesRepositoryContract {
  @override
  Future<List<TenantAdminTaxonomyDefinition>> fetchTaxonomies() async => [];

  @override
  Future<List<TenantAdminTaxonomyTermDefinition>> fetchTerms({
    required TenantAdminTaxRepoString taxonomyId,
  }) async {
    return [];
  }

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
  Future<void> deleteTaxonomy(TenantAdminTaxRepoString slug) async {}

  @override
  Future<TenantAdminTaxonomyTermDefinition> createTerm({
    required TenantAdminTaxRepoString taxonomyId,
    required TenantAdminTaxRepoString slug,
    required TenantAdminTaxRepoString name,
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

  @override
  Future<void> deleteTerm({
    required TenantAdminTaxRepoString taxonomyId,
    required TenantAdminTaxRepoString termId,
  }) async {}
}

class _NoopLocationSelectionService
    implements TenantAdminLocationSelectionContract {
  @override
  StreamValue<TenantAdminLocation?> locationStreamValue =
      StreamValue<TenantAdminLocation?>();

  @override
  StreamValue<TenantAdminLocation?> confirmedLocationStreamValue =
      StreamValue<TenantAdminLocation?>();

  @override
  TenantAdminLocation? get currentLocation => locationStreamValue.value;

  @override
  TenantAdminLocation? get confirmedLocation =>
      confirmedLocationStreamValue.value;

  @override
  void setInitialLocation(TenantAdminLocation? location) {
    locationStreamValue.addValue(location);
  }

  @override
  void setLocation(TenantAdminLocation location) {
    locationStreamValue.addValue(location);
  }

  @override
  void confirmSelection() {
    final location = locationStreamValue.value;
    if (location == null) {
      return;
    }
    confirmedLocationStreamValue.addValue(location);
  }

  @override
  void clearConfirmedLocation() {
    confirmedLocationStreamValue.addValue(null);
  }
}

class _PublicAccountProfilesRepository
    extends AccountProfilesRepositoryContract {
  _PublicAccountProfilesRepository(this.profile) {
    selectedAccountProfileStreamValue.addValue(profile);
  }

  final AccountProfileModel profile;
  final Set<String> _favoriteIds = <String>{};

  @override
  Future<void> init() async {}

  @override
  Future<PagedAccountProfilesResult> fetchAccountProfilesPage({
    required AccountProfilesRepositoryContractPrimInt page,
    required AccountProfilesRepositoryContractPrimInt pageSize,
    AccountProfilesRepositoryContractPrimString? query,
    AccountProfilesRepositoryContractPrimString? typeFilter,
    List<AccountProfilesRepositoryContractPrimString>? typeFilters,
    List<dynamic>? taxonomyFilters,
  }) async {
    return pagedAccountProfilesResultFromRaw(
      profiles: [profile],
      hasMore: false,
    );
  }

  @override
  Future<AccountProfileModel?> getAccountProfileBySlug(
    AccountProfilesRepositoryContractPrimString slug,
  ) async {
    return slug.value == profile.slug ? profile : null;
  }

  @override
  Future<List<AccountProfileModel>> fetchNearbyAccountProfiles({
    AccountProfilesRepositoryContractPrimInt? pageSize,
    List<AccountProfilesRepositoryContractPrimString>? typeFilters,
    List<dynamic>? taxonomyFilters,
  }) async {
    return [profile];
  }

  @override
  Future<void> toggleFavorite(
    AccountProfilesRepositoryContractPrimString accountProfileId,
  ) async {
    if (_favoriteIds.contains(accountProfileId.value)) {
      _favoriteIds.remove(accountProfileId.value);
    } else {
      _favoriteIds.add(accountProfileId.value);
    }
    favoriteAccountProfileIdsStreamValue.addValue(
      _favoriteIds
          .map(AccountProfilesRepositoryContractPrimString.fromRaw)
          .toSet(),
    );
  }

  @override
  AccountProfilesRepositoryContractPrimBool isFavorite(
    AccountProfilesRepositoryContractPrimString accountProfileId,
  ) {
    return AccountProfilesRepositoryContractPrimBool.fromRaw(
      _favoriteIds.contains(accountProfileId.value),
      defaultValue: false,
    );
  }

  @override
  List<AccountProfileModel> getFavoriteAccountProfiles() => const [];
}

AccountProfileModel _publicProfileFromAdmin(TenantAdminAccountProfile profile) {
  return buildAccountProfileModelFromPrimitives(
    id: '507f1f77bcf86cd799439888',
    name: profile.displayName,
    slug: profile.slug ?? 'casa-cultural',
    type: profile.profileType,
    bio: profile.bio,
    content: profile.content,
  );
}

AppData _buildAppData() {
  final remoteData = {
    'name': 'Tenant Test',
    'type': 'tenant',
    'main_domain': 'https://tenant.test',
    'profile_types': [
      {
        'type': 'rich',
        'label': 'Rich Profile',
        'allowed_taxonomies': const [],
        'visual': {
          'mode': 'icon',
          'icon': 'store',
          'color': '#0F766E',
          'icon_color': '#FFFFFF',
        },
        'capabilities': {
          'is_favoritable': true,
          'is_poi_enabled': false,
          'has_events': false,
          'has_bio': true,
          'has_content': true,
        },
      },
    ],
    'domains': ['https://tenant.test'],
    'app_domains': const [],
    'theme_data_settings': {
      'brightness_default': 'light',
      'primary_seed_color': '#0F766E',
      'secondary_seed_color': '#F97316',
    },
    'main_color': '#0F766E',
    'tenant_id': 'tenant-1',
    'telemetry': const {'trackers': []},
    'telemetry_context': const {'location_freshness_minutes': 5},
    'firebase': null,
    'push': null,
  };
  final localInfo = {
    'platformType': 'mobile',
    'hostname': 'tenant.test',
    'href': 'https://tenant.test',
    'port': null,
    'device': 'test-device',
  };
  return buildAppDataFromInitialization(
    remoteData: remoteData,
    localInfo: localInfo,
  );
}
