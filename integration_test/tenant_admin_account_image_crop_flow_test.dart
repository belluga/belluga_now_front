import 'package:integration_test/integration_test.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/domain/repositories/tenant_admin_account_profiles_repository_contract.dart';
import 'package:belluga_now/domain/repositories/tenant_admin_accounts_repository_contract.dart';
import 'package:belluga_now/domain/repositories/tenant_admin_taxonomies_repository_contract.dart';
import 'package:belluga_now/domain/services/tenant_admin_location_selection_contract.dart';
import 'package:belluga_now/domain/services/tenant_admin_external_image_proxy_contract.dart';
import 'package:belluga_now/domain/tenant_admin/ownership_state.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_account.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_account_onboarding_result.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_account_profile.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_document.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_location.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_media_upload.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_profile_type.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_definition.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_term_definition.dart';
import 'package:belluga_now/infrastructure/services/tenant_admin/tenant_admin_location_selection_service.dart';
import 'package:belluga_now/presentation/tenant_admin/accounts/controllers/tenant_admin_account_create_controller.dart';
import 'package:belluga_now/presentation/tenant_admin/accounts/screens/tenant_admin_account_create_screen.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/utils/tenant_admin_image_ingestion_service.dart';
import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:image/image.dart' as img;

import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  tearDownAll(() async {
    await GetIt.I.reset();
  });

  testWidgets('device image selection opens crop sheet for avatar',
      (tester) async {
    final tmpFile = _writeTempImage('picked.png');
    final originalImagePicker = ImagePickerPlatform.instance;
    ImagePickerPlatform.instance = _FakeImagePickerPlatform(tmpFile.path);
    addTearDown(() {
      ImagePickerPlatform.instance = originalImagePicker;
    });

    await GetIt.I.reset();
    _registerFakes();

    await _pumpWithAutoRoute(
      tester,
      const Scaffold(
        body: TenantAdminAccountCreateScreen(),
      ),
    );

    await tester.tap(find.byType(DropdownButtonFormField<String>).last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    await tester.tap(find.text('Venue').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    final pick = find.byKey(
      const ValueKey('tenant_admin_account_create_avatar_pick'),
    );
    await tester.ensureVisible(pick);
    await tester.tap(pick, warnIfMissed: false);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    // Select device in source sheet.
    await _pumpUntilFound(tester, find.text('Do dispositivo'));
    await tester.tap(find.text('Do dispositivo').last, warnIfMissed: false);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    await _pumpUntilFound(tester, find.text('Recortar avatar'));
    expect(find.text('Recortar avatar'), findsOneWidget);
    expect(find.text('Usar'), findsOneWidget);
    await _pumpUntilFound(tester, find.byType(Crop));
    final crop = tester.widget<Crop>(find.byType(Crop));
    expect(crop.aspectRatio, 1.0);
    await _confirmCropAndDismiss(tester);
  });

  testWidgets('device image selection opens crop sheet for cover',
      (tester) async {
    final tmpFile = _writeTempImage('picked_cover.png');
    final originalImagePicker = ImagePickerPlatform.instance;
    ImagePickerPlatform.instance = _FakeImagePickerPlatform(tmpFile.path);
    addTearDown(() {
      ImagePickerPlatform.instance = originalImagePicker;
    });

    await GetIt.I.reset();
    _registerFakes();

    await _pumpWithAutoRoute(
      tester,
      const Scaffold(
        body: TenantAdminAccountCreateScreen(),
      ),
    );

    await tester.tap(find.byType(DropdownButtonFormField<String>).last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    await tester.tap(find.text('Venue').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    final pick = find.byKey(
      const ValueKey('tenant_admin_account_create_cover_pick'),
    );
    await tester.ensureVisible(pick);
    await tester.tap(pick, warnIfMissed: false);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    await _pumpUntilFound(tester, find.text('Do dispositivo'));
    await tester.tap(find.text('Do dispositivo').last, warnIfMissed: false);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    await _pumpUntilFound(tester, find.text('Recortar capa'));
    expect(find.text('Recortar capa'), findsOneWidget);
    expect(find.text('Usar'), findsOneWidget);
    await _pumpUntilFound(tester, find.byType(Crop));
    final crop = tester.widget<Crop>(find.byType(Crop));
    expect(crop.aspectRatio, closeTo(16 / 9, 0.0001));
    await _confirmCropAndDismiss(tester);
  });

  testWidgets('web url selection opens crop sheet for avatar', (tester) async {
    await GetIt.I.reset();
    _registerFakes();

    await _pumpWithAutoRoute(
      tester,
      const Scaffold(
        body: TenantAdminAccountCreateScreen(),
      ),
    );

    await tester.tap(find.byType(DropdownButtonFormField<String>).last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    await tester.tap(find.text('Venue').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    final pick = find.byKey(
      const ValueKey('tenant_admin_account_create_avatar_pick'),
    );
    await _openWebCropFlow(
      tester: tester,
      trigger: pick,
      urlSheetTitle: 'URL do avatar',
      expectedCropTitle: 'Recortar avatar',
    );
    await _pumpUntilFound(tester, find.byType(Crop));
    final crop = tester.widget<Crop>(find.byType(Crop));
    expect(crop.aspectRatio, 1.0);
    await _confirmCropAndDismiss(tester);
  });

  testWidgets('web url selection opens crop sheet for cover', (tester) async {
    await GetIt.I.reset();
    _registerFakes();

    await _pumpWithAutoRoute(
      tester,
      const Scaffold(
        body: TenantAdminAccountCreateScreen(),
      ),
    );

    await tester.tap(find.byType(DropdownButtonFormField<String>).last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    await tester.tap(find.text('Venue').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    final pick = find.byKey(
      const ValueKey('tenant_admin_account_create_cover_pick'),
    );
    await _openWebCropFlow(
      tester: tester,
      trigger: pick,
      urlSheetTitle: 'URL da capa',
      expectedCropTitle: 'Recortar capa',
    );
    await _pumpUntilFound(tester, find.byType(Crop));
    final crop = tester.widget<Crop>(find.byType(Crop));
    expect(crop.aspectRatio, closeTo(16 / 9, 0.0001));
    await _confirmCropAndDismiss(tester);
  });
}

Future<void> _pumpWithAutoRoute(
  WidgetTester tester,
  Widget child,
) async {
  final router = RootStackRouter.build(
    routes: [
      NamedRouteDef(
        name: 'account-create-integration-test',
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

Future<void> _pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  Duration step = const Duration(milliseconds: 100),
  int maxPumps = 120,
}) async {
  for (var i = 0; i < maxPumps; i++) {
    if (finder.evaluate().isNotEmpty) return;
    await tester.pump(step);
  }
  fail('Timed out waiting for widget: $finder');
}

Future<void> _pumpUntilGone(
  WidgetTester tester,
  Finder finder, {
  Duration step = const Duration(milliseconds: 100),
  int maxPumps = 120,
}) async {
  for (var i = 0; i < maxPumps; i++) {
    if (finder.evaluate().isEmpty) return;
    await tester.pump(step);
  }
  fail('Timed out waiting for widget to disappear: $finder');
}

Future<void> _confirmCropAndDismiss(WidgetTester tester) async {
  final closeButton = find.byIcon(Icons.close);
  if (closeButton.evaluate().isNotEmpty) {
    await tester.ensureVisible(closeButton.last);
    await tester.tap(closeButton.last, warnIfMissed: false);
  } else {
    final cancelButton = find.text('Cancelar').last;
    await tester.ensureVisible(cancelButton);
    await tester.tap(cancelButton, warnIfMissed: false);
  }
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 350));
  await _pumpUntilGone(tester, find.byType(Crop), maxPumps: 600);
}

Future<void> _openWebCropFlow({
  required WidgetTester tester,
  required Finder trigger,
  required String urlSheetTitle,
  required String expectedCropTitle,
  String url = 'https://example.com/image.png',
}) async {
  await tester.ensureVisible(trigger);
  await tester.tap(trigger, warnIfMissed: false);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 350));

  await _pumpUntilFound(tester, find.text('Da web'));
  await tester.tap(find.text('Da web').last, warnIfMissed: false);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 350));

  await _pumpUntilFound(tester, find.text(urlSheetTitle));
  await tester.enterText(find.byType(TextFormField).last, url);
  await tester.pump();
  await tester.tap(find.text('Salvar').last, warnIfMissed: false);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 350));

  await _pumpUntilFound(tester, find.text(expectedCropTitle));
  expect(find.text(expectedCropTitle), findsOneWidget);
  expect(find.text('Usar'), findsOneWidget);
}

void _registerFakes() {
  final proxyBytes = _writeTempImage('proxy.png').readAsBytesSync();
  GetIt.I
    ..registerSingleton<TenantAdminAccountsRepositoryContract>(
      _FakeAccountsRepository(),
    )
    ..registerSingleton<TenantAdminAccountProfilesRepositoryContract>(
      _FakeAccountProfilesRepository(),
    )
    ..registerSingleton<TenantAdminTaxonomiesRepositoryContract>(
      _FakeTaxonomiesRepository(),
    )
    ..registerSingleton<TenantAdminLocationSelectionContract>(
      TenantAdminLocationSelectionService(),
    )
    ..registerSingleton<TenantAdminExternalImageProxyContract>(
      _FakeExternalImageProxy(proxyBytes),
    )
    ..registerSingleton<TenantAdminImageIngestionService>(
      TenantAdminImageIngestionService(),
    )
    ..registerFactory<TenantAdminAccountCreateController>(
      TenantAdminAccountCreateController.new,
    );
}

File _writeTempImage(String name) {
  final dir = Directory.systemTemp.createTempSync('belluga_integration_');
  final file = File('${dir.path}/$name');
  final image = img.Image(width: 1600, height: 900);
  img.fill(image, color: img.ColorRgb8(120, 45, 180));
  file.writeAsBytesSync(img.encodePng(image), flush: true);
  return file;
}

class _FakeImagePickerPlatform extends ImagePickerPlatform {
  _FakeImagePickerPlatform(this.path);

  final String path;

  @override
  Future<XFile?> getImage({
    required ImageSource source,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
    int? imageQuality,
    double? maxWidth,
    double? maxHeight,
  }) async {
    return XFile(path, name: 'picked.png', mimeType: 'image/png');
  }
}

class _FakeExternalImageProxy implements TenantAdminExternalImageProxyContract {
  _FakeExternalImageProxy(this._bytes);

  final Uint8List _bytes;

  @override
  Future<Uint8List> fetchExternalImageBytes({required Object imageUrl}) async {
    return _bytes;
  }
}

class _FakeAccountsRepository extends TenantAdminAccountsRepositoryContract {
  @override
  Future<List<TenantAdminAccount>> fetchAccounts() async => [];

  @override
  Future<TenantAdminAccount> fetchAccountBySlug(
    TenantAdminAccountsRepositoryContractPrimString accountSlug,
  ) async {
    throw UnimplementedError();
  }

  @override
  Future<TenantAdminAccount> createAccount({
    required TenantAdminAccountsRepositoryContractPrimString name,
    TenantAdminDocument? document,
    required TenantAdminOwnershipState ownershipState,
    TenantAdminAccountsRepositoryContractPrimString? organizationId,
  }) async {
    throw UnimplementedError();
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
    throw UnimplementedError();
  }

  @override
  Future<void> deleteAccount(
    TenantAdminAccountsRepositoryContractPrimString accountSlug,
  ) async {
    throw UnimplementedError();
  }

  @override
  Future<TenantAdminAccount> restoreAccount(
    TenantAdminAccountsRepositoryContractPrimString accountSlug,
  ) async {
    throw UnimplementedError();
  }

  @override
  Future<void> forceDeleteAccount(
    TenantAdminAccountsRepositoryContractPrimString accountSlug,
  ) async {
    throw UnimplementedError();
  }
}

class _FakeAccountProfilesRepository
    extends TenantAdminAccountProfilesRepositoryContract {
  @override
  Future<List<TenantAdminAccountProfile>> fetchAccountProfiles({
    TenantAdminAccountProfilesRepoString? accountId,
  }) async =>
      [];

  @override
  Future<TenantAdminAccountProfile> fetchAccountProfile(
    TenantAdminAccountProfilesRepoString accountProfileId,
  ) async {
    throw UnimplementedError();
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
    throw UnimplementedError();
  }

  @override
  Future<void> deleteAccountProfile(
      TenantAdminAccountProfilesRepoString accountProfileId) async {
    throw UnimplementedError();
  }

  @override
  Future<TenantAdminAccountProfile> restoreAccountProfile(
    TenantAdminAccountProfilesRepoString accountProfileId,
  ) async {
    throw UnimplementedError();
  }

  @override
  Future<void> forceDeleteAccountProfile(
      TenantAdminAccountProfilesRepoString accountProfileId) async {
    throw UnimplementedError();
  }

  @override
  Future<List<TenantAdminProfileTypeDefinition>> fetchProfileTypes() async {
    return [
      tenantAdminProfileTypeDefinitionFromRaw(
        type: 'venue',
        label: 'Venue',
        allowedTaxonomies: [],
        capabilities: TenantAdminProfileTypeCapabilities(
          isFavoritable: TenantAdminFlagValue(true),
          isPoiEnabled: TenantAdminFlagValue(false),
          hasBio: TenantAdminFlagValue(false),
          hasContent: TenantAdminFlagValue(false),
          hasTaxonomies: TenantAdminFlagValue(false),
          hasAvatar: TenantAdminFlagValue(true),
          hasCover: TenantAdminFlagValue(true),
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
    throw UnimplementedError();
  }

  @override
  Future<TenantAdminProfileTypeDefinition> updateProfileType({
    required TenantAdminAccountProfilesRepoString type,
    TenantAdminAccountProfilesRepoString? newType,
    TenantAdminAccountProfilesRepoString? label,
    List<TenantAdminAccountProfilesRepoString>? allowedTaxonomies,
    TenantAdminProfileTypeCapabilities? capabilities,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteProfileType(
      TenantAdminAccountProfilesRepoString type) async {
    throw UnimplementedError();
  }
}

class _FakeTaxonomiesRepository
    extends TenantAdminTaxonomiesRepositoryContract {
  @override
  Future<List<TenantAdminTaxonomyDefinition>> fetchTaxonomies() async => [];

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
  Future<void> deleteTaxonomy(TenantAdminTaxRepoString taxonomyId) async {
    throw UnimplementedError();
  }

  @override
  Future<List<TenantAdminTaxonomyTermDefinition>> fetchTerms({
    required TenantAdminTaxRepoString taxonomyId,
  }) async =>
      [];

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
  }) async {
    throw UnimplementedError();
  }
}
