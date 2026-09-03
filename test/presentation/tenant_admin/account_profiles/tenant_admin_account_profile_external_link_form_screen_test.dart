import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/domain/partners/account_profile_external_link.dart';
import 'package:belluga_now/domain/repositories/tenant_admin_account_profiles_repository_contract.dart';
import 'package:belluga_now/domain/repositories/tenant_admin_accounts_repository_contract.dart';
import 'package:belluga_now/domain/repositories/tenant_admin_taxonomies_repository_contract.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_account_profile.dart';
import 'package:belluga_now/infrastructure/services/tenant_admin/tenant_admin_location_selection_service.dart';
import 'package:belluga_now/presentation/tenant_admin/account_profiles/controllers/tenant_admin_account_profiles_controller.dart';
import 'package:belluga_now/presentation/tenant_admin/account_profiles/screens/tenant_admin_account_profile_external_link_form_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mockito/mockito.dart';

class _MockProfilesRepository extends Mock
    implements TenantAdminAccountProfilesRepositoryContract {
  TenantAdminAccountProfile? updateExternalLinkResult;
  TenantAdminAccountProfile? createExternalLinkResult;
  AccountProfileExternalLinkType? createdExternalLinkType;
  AccountProfileExternalLinkUrlValue? createdExternalLinkUrl;
  AccountProfileExternalLinkLabelValue? createdExternalLinkLabel;

  @override
  Future<TenantAdminAccountProfile> createExternalLink({
    required TenantAdminAccountProfilesRepoString accountProfileId,
    required AccountProfileExternalLinkType type,
    required AccountProfileExternalLinkUrlValue url,
    AccountProfileExternalLinkLabelValue? label,
  }) async {
    createdExternalLinkType = type;
    createdExternalLinkUrl = url;
    createdExternalLinkLabel = label;
    final result = createExternalLinkResult;
    if (result == null) {
      throw StateError('createExternalLink was not configured for this test');
    }
    return result;
  }

  @override
  Future<TenantAdminAccountProfile> updateExternalLink({
    required TenantAdminAccountProfilesRepoString accountProfileId,
    required TenantAdminAccountProfilesRepoString externalLinkId,
    required AccountProfileExternalLinkUrlValue url,
    AccountProfileExternalLinkLabelValue? label,
  }) async {
    final result = updateExternalLinkResult;
    if (result == null) {
      throw StateError('updateExternalLink was not configured for this test');
    }
    return result;
  }
}

class _MockAccountsRepository extends Mock
    implements TenantAdminAccountsRepositoryContract {}

class _MockTaxonomiesRepository extends Mock
    implements TenantAdminTaxonomiesRepositoryContract {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late TenantAdminAccountProfilesController controller;
  late _MockProfilesRepository profilesRepository;

  setUp(() {
    profilesRepository = _MockProfilesRepository();
    controller = TenantAdminAccountProfilesController(
      profilesRepository: profilesRepository,
      accountsRepository: _MockAccountsRepository(),
      taxonomiesRepository: _MockTaxonomiesRepository(),
      locationSelectionService: TenantAdminLocationSelectionService(),
    );
    GetIt.I.registerSingleton<TenantAdminAccountProfilesController>(controller);
  });

  tearDown(() async {
    await GetIt.I.reset();
  });

  testWidgets('add screen exposes only available types and valid-only save', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final existing = _parseExternalLink(
      id: 'facebook-link',
      type: AccountProfileExternalLinkType.facebook,
      url: 'https://facebook.com/belluga',
    );
    final profile = tenantAdminAccountProfileFromRaw(
      id: 'profile-1',
      accountId: 'account-1',
      profileType: 'custom',
      displayName: 'Profile One',
      externalLinks: [existing],
      externalLinksLimit: 3,
    );
    controller.adoptExternalLinkRouteProfile(profile);
    final draft = controller.beginExternalLinkDraft(
      accountProfileId: profile.id,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: TenantAdminAccountProfileExternalLinkFormScreen(
          accountSlug: 'account-one',
          accountProfile: profile,
          draft: draft,
        ),
      ),
    );
    await tester.pump();

    final save = find.byKey(const Key('externalLinkSaveButton'));
    expect(save, findsOneWidget);
    expect(tester.widget<FilledButton>(save).onPressed, isNull);
    expect(find.byKey(const Key('externalLinkTypeField')), findsOneWidget);

    await tester.tap(find.byKey(const Key('externalLinkTypeField')));
    await tester.pumpAndSettle();
    expect(find.text('Facebook'), findsNothing);
    await tester.tap(find.text('Instagram').last);
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('externalLinkUrlField')),
      'https://instagram.com/belluga',
    );
    await tester.pump();

    expect(tester.widget<FilledButton>(save).onPressed, isNotNull);
    final popScope = tester.widget<PopScope<dynamic>>(
      find.byWidgetPredicate((widget) => widget is PopScope),
    );
    expect(popScope.canPop, isFalse);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Sair sem salvar?'), findsOneWidget);
    expect(
      find.text('As alterações neste link ainda não foram salvas.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('website add flow requires and submits an accessible label', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final profile = tenantAdminAccountProfileFromRaw(
      id: 'profile-website',
      accountId: 'account-website',
      profileType: 'custom',
      displayName: 'Profile Website',
      externalLinksLimit: 3,
    );
    final updated = tenantAdminAccountProfileFromRaw(
      id: profile.id,
      accountId: profile.accountId,
      profileType: profile.profileType,
      displayName: profile.displayName,
      externalLinks: [
        _parseExternalLink(
          id: 'website-link',
          type: AccountProfileExternalLinkType.website,
          url: 'https://example.org',
          label: 'Official website',
        ),
      ],
      externalLinksLimit: 3,
    );
    profilesRepository.createExternalLinkResult = updated;
    controller.adoptExternalLinkRouteProfile(profile);
    final draft = controller.beginExternalLinkDraft(
      accountProfileId: profile.id,
    );
    final router = _RecordingStackRouter();

    await tester.pumpWidget(
      StackRouterScope(
        controller: router,
        stateHash: 0,
        child: MaterialApp(
          home: TenantAdminAccountProfileExternalLinkFormScreen(
            accountSlug: 'account-website',
            accountProfile: profile,
            draft: draft,
          ),
        ),
      ),
    );
    await tester.pump();

    final save = find.byKey(const Key('externalLinkSaveButton'));
    await tester.tap(find.byKey(const Key('externalLinkTypeField')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Website').last);
    await tester.pumpAndSettle();

    final label = find.byKey(const Key('externalLinkLabelField'));
    expect(label, findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('externalLinkUrlField')),
      'https://example.org',
    );
    await tester.pump();
    expect(tester.widget<FilledButton>(save).onPressed, isNull);

    await tester.enterText(label, 'Official website');
    await tester.pump();
    expect(tester.widget<FilledButton>(save).onPressed, isNotNull);

    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(
      profilesRepository.createdExternalLinkType,
      AccountProfileExternalLinkType.website,
    );
    expect(
      profilesRepository.createdExternalLinkUrl?.value.toString(),
      'https://example.org',
    );
    expect(
      profilesRepository.createdExternalLinkLabel?.value,
      'Official website',
    );
    expect(router.replaceCalls, hasLength(1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('edit screen fixes provider identity and exposes deletion', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final existing = _parseExternalLink(
      id: 'instagram-link',
      type: AccountProfileExternalLinkType.instagram,
      url: 'https://instagram.com/belluga',
    );
    final profile = tenantAdminAccountProfileFromRaw(
      id: 'profile-1',
      accountId: 'account-1',
      profileType: 'custom',
      displayName: 'Profile One',
      externalLinks: [existing],
      externalLinksLimit: 3,
    );
    controller.adoptExternalLinkRouteProfile(profile);
    final draft = controller.beginExternalLinkDraft(
      accountProfileId: profile.id,
      existingLink: existing,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: TenantAdminAccountProfileExternalLinkFormScreen(
          accountSlug: 'account-one',
          accountProfile: profile,
          draft: draft,
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Instagram'), findsNWidgets(2));
    expect(find.byKey(const Key('externalLinkTypeField')), findsNothing);
    expect(find.byKey(const Key('externalLinkDeleteButton')), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('externalLinkSaveButton')))
          .onPressed,
      isNotNull,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('busy mutation blocks system back with explicit feedback', (
    tester,
  ) async {
    final profile = tenantAdminAccountProfileFromRaw(
      id: 'profile-busy',
      accountId: 'account-busy',
      profileType: 'custom',
      displayName: 'Profile Busy',
      externalLinksLimit: 3,
    );
    controller.adoptExternalLinkRouteProfile(profile);
    final draft = controller.beginExternalLinkDraft(
      accountProfileId: profile.id,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: TenantAdminAccountProfileExternalLinkFormScreen(
          accountSlug: 'account-busy',
          accountProfile: profile,
          draft: draft,
        ),
      ),
    );
    draft.setBusy(true);
    await tester.pump();

    await tester.binding.handlePopRoute();
    await tester.pump();

    expect(find.text('Aguarde a conclusão da alteração.'), findsOneWidget);
    expect(find.text('Sair sem salvar?'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('successful mutation requests exactly one parent replacement', (
    tester,
  ) async {
    final existing = _parseExternalLink(
      id: 'instagram-link',
      type: AccountProfileExternalLinkType.instagram,
      url: 'https://instagram.com/belluga',
    );
    final profile = tenantAdminAccountProfileFromRaw(
      id: 'profile-replace-once',
      accountId: 'account-replace-once',
      profileType: 'custom',
      displayName: 'Profile Replace Once',
      externalLinks: [existing],
      externalLinksLimit: 3,
    );
    profilesRepository.updateExternalLinkResult = profile;
    controller.adoptExternalLinkRouteProfile(profile);
    final draft = controller.beginExternalLinkDraft(
      accountProfileId: profile.id,
      existingLink: existing,
    );

    final router = _RecordingStackRouter();
    await tester.pumpWidget(
      StackRouterScope(
        controller: router,
        stateHash: 0,
        child: MaterialApp(
          home: TenantAdminAccountProfileExternalLinkFormScreen(
            accountSlug: 'account-replace-once',
            accountProfile: profile,
            draft: draft,
          ),
        ),
      ),
    );
    await tester.pump();

    final save = find.byKey(const Key('externalLinkSaveButton'));
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(router.replaceCalls, hasLength(1));
    expect(
      router.replaceCalls.single.routeName,
      contains('TenantAdminAccountProfileEditRoute'),
    );

    // A stale second completion cannot schedule a second replacement.
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(router.replaceCalls, hasLength(1));
  });
}

class _RecordingStackRouter extends Fake implements StackRouter {
  final List<PageRouteInfo<dynamic>> replaceCalls = <PageRouteInfo<dynamic>>[];

  @override
  Future<T?> replace<T extends Object?>(
    PageRouteInfo<dynamic> route, {
    OnNavigationFailure? onFailure,
    bool notify = true,
  }) async {
    replaceCalls.add(route);
    return null;
  }
}

AccountProfileExternalLink _parseExternalLink({
  required String id,
  required AccountProfileExternalLinkType type,
  required String url,
  String? label,
}) => AccountProfileExternalLinkRegistry.validateMutation(
  id: AccountProfileExternalLinkIdValue(id),
  type: type,
  url: AccountProfileExternalLinkUrlValue(url),
  label: label == null ? null : AccountProfileExternalLinkLabelValue(label),
);
