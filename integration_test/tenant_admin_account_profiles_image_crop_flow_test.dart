import 'dart:typed_data';

import 'package:belluga_now/domain/repositories/tenant_admin_account_profiles_repository_contract.dart';
import 'package:belluga_now/domain/repositories/tenant_admin_accounts_repository_contract.dart';
import 'package:belluga_now/domain/repositories/tenant_admin_taxonomies_repository_contract.dart';
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
import 'package:belluga_now/presentation/tenant_admin/account_profiles/controllers/tenant_admin_account_profiles_controller.dart';
import 'package:belluga_now/presentation/tenant_admin/account_profiles/screens/tenant_admin_account_profile_create_screen.dart';
import 'package:belluga_now/presentation/tenant_admin/account_profiles/screens/tenant_admin_account_profile_edit_screen.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/utils/tenant_admin_image_ingestion_service.dart';
import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:integration_test/integration_test.dart';

import 'support/tenant_admin_image_crop_harness.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  tearDownAll(() async {
    await GetIt.I.reset();
  });

  group('Account Profile Image Crop (Device)', () {
    testWidgets('create: avatar opens crop sheet (1:1)', (tester) async {
      final tmp = writeTempPng(name: 'picked.png');
      final originalPicker = ImagePickerPlatform.instance;
      ImagePickerPlatform.instance = FakeImagePickerPlatform(tmp.path);
      addTearDown(() {
        ImagePickerPlatform.instance = originalPicker;
      });

      await _registerCreateFakes();
      await pumpWithAutoRoute(
        tester,
        const Scaffold(
          body: TenantAdminAccountProfileCreateScreen(accountSlug: 'yuri-dias'),
        ),
      );

      // Select a profile type that enables avatar/cover.
      await tester.tap(find.byType(DropdownButtonFormField<String>).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Artist').last);
      await tester.pumpAndSettle();

      await openDeviceCropFlow(
        tester: tester,
        trigger: find.text('Adicionar avatar'),
        expectedTitle: 'Recortar avatar',
      );
      final crop = tester.widget<Crop>(find.byType(Crop));
      expect(crop.aspectRatio, closeTo(1.0, 0.0001));
    });

    testWidgets('create: cover opens crop sheet (16:9)', (tester) async {
      final tmp = writeTempPng(name: 'picked.png', width: 1200, height: 1800);
      final originalPicker = ImagePickerPlatform.instance;
      ImagePickerPlatform.instance = FakeImagePickerPlatform(tmp.path);
      addTearDown(() {
        ImagePickerPlatform.instance = originalPicker;
      });

      await _registerCreateFakes();
      await pumpWithAutoRoute(
        tester,
        const Scaffold(
          body: TenantAdminAccountProfileCreateScreen(accountSlug: 'yuri-dias'),
        ),
      );

      await tester.tap(find.byType(DropdownButtonFormField<String>).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Artist').last);
      await tester.pumpAndSettle();

      await openDeviceCropFlow(
        tester: tester,
        trigger: find.text('Adicionar capa'),
        expectedTitle: 'Recortar capa',
      );
      final crop = tester.widget<Crop>(find.byType(Crop));
      expect(crop.aspectRatio, closeTo(16 / 9, 0.0001));
    });

    testWidgets('edit: avatar opens crop sheet (1:1)', (tester) async {
      final tmp = writeTempPng(name: 'picked.png');
      final originalPicker = ImagePickerPlatform.instance;
      ImagePickerPlatform.instance = FakeImagePickerPlatform(tmp.path);
      addTearDown(() {
        ImagePickerPlatform.instance = originalPicker;
      });

      await _registerEditFakes();
      await pumpWithAutoRoute(
        tester,
        const Scaffold(
          body: TenantAdminAccountProfileEditScreen(
            accountSlug: 'yuri-dias',
            accountProfileId: 'profile-1',
          ),
        ),
      );

      await pumpUntilFound(tester, find.text('Adicionar avatar'));
      await openDeviceCropFlow(
        tester: tester,
        trigger: find.text('Adicionar avatar'),
        expectedTitle: 'Recortar avatar',
      );
      final crop = tester.widget<Crop>(find.byType(Crop));
      expect(crop.aspectRatio, closeTo(1.0, 0.0001));
    });

    testWidgets('edit: cover opens crop sheet (16:9)', (tester) async {
      final tmp = writeTempPng(name: 'picked.png', width: 1200, height: 1800);
      final originalPicker = ImagePickerPlatform.instance;
      ImagePickerPlatform.instance = FakeImagePickerPlatform(tmp.path);
      addTearDown(() {
        ImagePickerPlatform.instance = originalPicker;
      });

      await _registerEditFakes();
      await pumpWithAutoRoute(
        tester,
        const Scaffold(
          body: TenantAdminAccountProfileEditScreen(
            accountSlug: 'yuri-dias',
            accountProfileId: 'profile-1',
          ),
        ),
      );

      await pumpUntilFound(tester, find.text('Adicionar capa'));
      await openDeviceCropFlow(
        tester: tester,
        trigger: find.text('Adicionar capa'),
        expectedTitle: 'Recortar capa',
      );
      final crop = tester.widget<Crop>(find.byType(Crop));
      expect(crop.aspectRatio, closeTo(16 / 9, 0.0001));
    });
  });

  group('Account Profile Image Crop (Web URL)', () {
    testWidgets('create: avatar opens crop sheet (1:1)', (tester) async {
      await _registerCreateFakes();
      await pumpWithAutoRoute(
        tester,
        const Scaffold(
          body: TenantAdminAccountProfileCreateScreen(accountSlug: 'yuri-dias'),
        ),
      );

      await tester.tap(find.byType(DropdownButtonFormField<String>).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Artist').last);
      await tester.pumpAndSettle();

      await openWebCropFlow(
        tester: tester,
        trigger: find.text('Adicionar avatar'),
        urlSheetTitle: 'URL do avatar',
        url: 'https://example.com/avatar.png',
        expectedCropTitle: 'Recortar avatar',
      );
      expectCropAspectRatio(tester, 1.0);
    });

    testWidgets('create: cover opens crop sheet (16:9)', (tester) async {
      await _registerCreateFakes();
      await pumpWithAutoRoute(
        tester,
        const Scaffold(
          body: TenantAdminAccountProfileCreateScreen(accountSlug: 'yuri-dias'),
        ),
      );

      await tester.tap(find.byType(DropdownButtonFormField<String>).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Artist').last);
      await tester.pumpAndSettle();

      await openWebCropFlow(
        tester: tester,
        trigger: find.text('Adicionar capa'),
        urlSheetTitle: 'URL da capa',
        url: 'https://example.com/cover.png',
        expectedCropTitle: 'Recortar capa',
      );
      expectCropAspectRatio(tester, 16 / 9);
    });

    testWidgets('edit: avatar opens crop sheet (1:1)', (tester) async {
      await _registerEditFakes();
      await pumpWithAutoRoute(
        tester,
        const Scaffold(
          body: TenantAdminAccountProfileEditScreen(
            accountSlug: 'yuri-dias',
            accountProfileId: 'profile-1',
          ),
        ),
      );

      await pumpUntilFound(tester, find.text('Adicionar avatar'));
      await openWebCropFlow(
        tester: tester,
        trigger: find.text('Adicionar avatar'),
        urlSheetTitle: 'URL do avatar',
        url: 'https://example.com/avatar.png',
        expectedCropTitle: 'Recortar avatar',
      );
      expectCropAspectRatio(tester, 1.0);
    });

    testWidgets('edit: cover opens crop sheet (16:9)', (tester) async {
      await _registerEditFakes();
      await pumpWithAutoRoute(
        tester,
        const Scaffold(
          body: TenantAdminAccountProfileEditScreen(
            accountSlug: 'yuri-dias',
            accountProfileId: 'profile-1',
          ),
        ),
      );

      await pumpUntilFound(tester, find.text('Adicionar capa'));
      await openWebCropFlow(
        tester: tester,
        trigger: find.text('Adicionar capa'),
        urlSheetTitle: 'URL da capa',
        url: 'https://example.com/cover.png',
        expectedCropTitle: 'Recortar capa',
      );
      expectCropAspectRatio(tester, 16 / 9);
    });
  });
}

Future<void> _registerCreateFakes() async {
  await GetIt.I.reset();
  final proxyBytes = writeTempPng(name: 'proxy.png').readAsBytesSync();
  GetIt.I.registerSingleton<TenantAdminExternalImageProxyContract>(
    _FakeExternalImageProxy(proxyBytes),
  );
  GetIt.I.registerSingleton<TenantAdminImageIngestionService>(
    TenantAdminImageIngestionService(),
  );
  GetIt.I.registerSingleton<TenantAdminAccountProfilesController>(
    TenantAdminAccountProfilesController(
      profilesRepository: _FakeProfilesRepository(),
      accountsRepository: _FakeAccountsRepository(),
      taxonomiesRepository: _FakeTaxonomiesRepository(),
      locationSelectionService: TenantAdminLocationSelectionService(),
    ),
  );
}

Future<void> _registerEditFakes() async {
  await GetIt.I.reset();
  final proxyBytes = writeTempPng(name: 'proxy.png').readAsBytesSync();
  GetIt.I.registerSingleton<TenantAdminExternalImageProxyContract>(
    _FakeExternalImageProxy(proxyBytes),
  );
  GetIt.I.registerSingleton<TenantAdminImageIngestionService>(
    TenantAdminImageIngestionService(),
  );
  GetIt.I.registerSingleton<TenantAdminAccountProfilesController>(
    TenantAdminAccountProfilesController(
      profilesRepository: _FakeProfilesRepository(),
      accountsRepository: _FakeAccountsRepository(),
      taxonomiesRepository: _FakeTaxonomiesRepository(),
      locationSelectionService: TenantAdminLocationSelectionService(),
    ),
  );
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
    return const TenantAdminAccount(
      id: 'account-1',
      name: 'Yuri Dias',
      slug: 'yuri-dias',
      document: TenantAdminDocument(type: 'cpf', number: '00000000000'),
      ownershipState: TenantAdminOwnershipState.tenantOwned,
    );
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

class _FakeProfilesRepository
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
    return const TenantAdminAccountProfile(
      id: 'profile-1',
      accountId: 'account-1',
      profileType: 'artist',
      displayName: 'Yuri Diad',
      slug: 'yuri-diad',
      taxonomyTerms: [],
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
        type: 'artist',
        label: 'Artist',
        allowedTaxonomies: [],
        capabilities: TenantAdminProfileTypeCapabilities(
          isFavoritable: false,
          isPoiEnabled: false,
          hasBio: true,
          hasContent: true,
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

  @override
  Future<List<TenantAdminTaxonomyTermDefinition>> fetchTerms({
    required String taxonomyId,
  }) async =>
      const [];
}
