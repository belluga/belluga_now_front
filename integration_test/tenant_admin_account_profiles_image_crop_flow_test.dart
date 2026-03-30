import 'package:integration_test/integration_test.dart';
import 'dart:typed_data';

import 'package:belluga_now/domain/repositories/tenant_admin_account_profiles_repository_contract.dart';
import 'package:belluga_now/domain/repositories/tenant_admin_accounts_repository_contract.dart';
import 'package:belluga_now/domain/repositories/tenant_admin_taxonomies_repository_contract.dart';
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
import 'package:belluga_now/presentation/tenant_admin/account_profiles/controllers/tenant_admin_account_profiles_controller.dart';
import 'package:belluga_now/presentation/tenant_admin/account_profiles/screens/tenant_admin_account_profile_create_screen.dart';
import 'package:belluga_now/presentation/tenant_admin/account_profiles/screens/tenant_admin_account_profile_edit_screen.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/utils/tenant_admin_image_ingestion_service.dart';
import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';

import 'support/tenant_admin_image_crop_harness.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_terms.dart';

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
      await confirmCropAndDismiss(tester);
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
      await confirmCropAndDismiss(tester);
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
      await confirmCropAndDismiss(tester);
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
      await confirmCropAndDismiss(tester);
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
      await confirmCropAndDismiss(tester);
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
      await confirmCropAndDismiss(tester);
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
      await confirmCropAndDismiss(tester);
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
      await confirmCropAndDismiss(tester);
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
    return tenantAdminAccountFromRaw(
      id: 'account-1',
      name: 'Yuri Dias',
      slug: 'yuri-dias',
      document: tenantAdminDocumentFromRaw(type: 'cpf', number: '00000000000'),
      ownershipState: TenantAdminOwnershipState.tenantOwned,
    );
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

class _FakeProfilesRepository
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
    return tenantAdminAccountProfileFromRaw(
      id: 'profile-1',
      accountId: 'account-1',
      profileType: 'artist',
      displayName: 'Yuri Diad',
      slug: 'yuri-diad',
      taxonomyTerms: const TenantAdminTaxonomyTerms.empty(),
    );
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
        type: 'artist',
        label: 'Artist',
        allowedTaxonomies: [],
        capabilities: TenantAdminProfileTypeCapabilities(
          isFavoritable: TenantAdminFlagValue(false),
          isPoiEnabled: TenantAdminFlagValue(false),
          hasBio: TenantAdminFlagValue(true),
          hasContent: TenantAdminFlagValue(true),
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

  @override
  Future<List<TenantAdminTaxonomyTermDefinition>> fetchTerms({
    required TenantAdminTaxRepoString taxonomyId,
  }) async =>
      [];
}
