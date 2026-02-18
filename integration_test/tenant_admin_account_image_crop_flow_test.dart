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
import 'package:belluga_now/domain/tenant_admin/tenant_admin_account_profile.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_document.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_location.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_media_upload.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_profile_type.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_definition.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_term.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_term_definition.dart';
import 'package:belluga_now/infrastructure/services/tenant_admin/tenant_admin_location_selection_service.dart';
import 'package:belluga_now/presentation/tenant_admin/accounts/controllers/tenant_admin_accounts_controller.dart';
import 'package:belluga_now/presentation/tenant_admin/accounts/screens/tenant_admin_account_create_screen.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/utils/tenant_admin_image_ingestion_service.dart';
import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:image/image.dart' as img;
import 'package:integration_test/integration_test.dart';
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
    final crop = tester.widget<Crop>(find.byType(Crop));
    expect(crop.aspectRatio, 1.0);
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
    final crop = tester.widget<Crop>(find.byType(Crop));
    expect(crop.aspectRatio, closeTo(16 / 9, 0.0001));
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
    final crop = tester.widget<Crop>(find.byType(Crop));
    expect(crop.aspectRatio, 1.0);
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
    final crop = tester.widget<Crop>(find.byType(Crop));
    expect(crop.aspectRatio, closeTo(16 / 9, 0.0001));
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
    ..registerSingleton<TenantAdminAccountsController>(
      TenantAdminAccountsController(),
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
  Future<Uint8List> fetchExternalImageBytes({required String imageUrl}) async {
    return _bytes;
  }
}

class _FakeAccountsRepository extends TenantAdminAccountsRepositoryContract {
  @override
  Future<List<TenantAdminAccount>> fetchAccounts() async => const [];

  @override
  Future<TenantAdminAccount> fetchAccountBySlug(String accountSlug) async {
    throw UnimplementedError();
  }

  @override
  Future<TenantAdminAccount> createAccount({
    required String name,
    TenantAdminDocument? document,
    required TenantAdminOwnershipState ownershipState,
    String? organizationId,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<TenantAdminAccount> updateAccount({
    required String accountSlug,
    String? name,
    String? slug,
    TenantAdminDocument? document,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteAccount(String accountSlug) async {
    throw UnimplementedError();
  }

  @override
  Future<TenantAdminAccount> restoreAccount(String accountSlug) async {
    throw UnimplementedError();
  }

  @override
  Future<void> forceDeleteAccount(String accountSlug) async {
    throw UnimplementedError();
  }
}

class _FakeAccountProfilesRepository
    extends TenantAdminAccountProfilesRepositoryContract {
  @override
  Future<List<TenantAdminAccountProfile>> fetchAccountProfiles({
    String? accountId,
  }) async =>
      const [];

  @override
  Future<TenantAdminAccountProfile> fetchAccountProfile(
    String accountProfileId,
  ) async {
    throw UnimplementedError();
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
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteAccountProfile(String accountProfileId) async {
    throw UnimplementedError();
  }

  @override
  Future<TenantAdminAccountProfile> restoreAccountProfile(
    String accountProfileId,
  ) async {
    throw UnimplementedError();
  }

  @override
  Future<void> forceDeleteAccountProfile(String accountProfileId) async {
    throw UnimplementedError();
  }

  @override
  Future<List<TenantAdminProfileTypeDefinition>> fetchProfileTypes() async {
    return const [
      TenantAdminProfileTypeDefinition(
        type: 'venue',
        label: 'Venue',
        allowedTaxonomies: [],
        capabilities: TenantAdminProfileTypeCapabilities(
          isFavoritable: true,
          isPoiEnabled: false,
          hasBio: false,
          hasContent: false,
          hasTaxonomies: false,
          hasAvatar: true,
          hasCover: true,
          hasEvents: false,
        ),
      ),
    ];
  }

  @override
  Future<TenantAdminProfileTypeDefinition> createProfileType({
    required String type,
    required String label,
    List<String> allowedTaxonomies = const [],
    required TenantAdminProfileTypeCapabilities capabilities,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<TenantAdminProfileTypeDefinition> updateProfileType({
    required String type,
    String? newType,
    String? label,
    List<String>? allowedTaxonomies,
    TenantAdminProfileTypeCapabilities? capabilities,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteProfileType(String type) async {
    throw UnimplementedError();
  }
}

class _FakeTaxonomiesRepository
    extends TenantAdminTaxonomiesRepositoryContract {
  @override
  Future<List<TenantAdminTaxonomyDefinition>> fetchTaxonomies() async =>
      const [];

  @override
  Future<TenantAdminTaxonomyDefinition> createTaxonomy({
    required String slug,
    required String name,
    required List<String> appliesTo,
    String? icon,
    String? color,
  }) async {
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
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteTaxonomy(String taxonomyId) async {
    throw UnimplementedError();
  }

  @override
  Future<List<TenantAdminTaxonomyTermDefinition>> fetchTerms({
    required String taxonomyId,
  }) async =>
      const [];

  @override
  Future<TenantAdminTaxonomyTermDefinition> createTerm({
    required String taxonomyId,
    required String slug,
    required String name,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<TenantAdminTaxonomyTermDefinition> updateTerm({
    required String taxonomyId,
    required String termId,
    String? slug,
    String? name,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteTerm({
    required String taxonomyId,
    required String termId,
  }) async {
    throw UnimplementedError();
  }
}
