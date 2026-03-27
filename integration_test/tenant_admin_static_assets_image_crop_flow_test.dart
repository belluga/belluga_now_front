import 'package:integration_test/integration_test.dart';
import 'dart:typed_data';

import 'package:belluga_now/domain/repositories/tenant_admin_static_assets_repository_contract.dart';
import 'package:belluga_now/domain/repositories/tenant_admin_taxonomies_repository_contract.dart';
import 'package:belluga_now/domain/services/tenant_admin_external_image_proxy_contract.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_location.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_media_upload.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_paged_result.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_static_asset.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_static_profile_type.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_definition.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_term.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_term_definition.dart';
import 'package:belluga_now/infrastructure/services/tenant_admin/tenant_admin_location_selection_service.dart';
import 'package:belluga_now/presentation/shared/widgets/belluga_network_image.dart';
import 'package:belluga_now/presentation/tenant_admin/static_assets/controllers/tenant_admin_static_assets_controller.dart';
import 'package:belluga_now/presentation/tenant_admin/static_assets/screens/tenant_admin_static_asset_create_screen.dart';
import 'package:belluga_now/presentation/tenant_admin/static_assets/screens/tenant_admin_static_asset_edit_screen.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/utils/tenant_admin_image_ingestion_service.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/widgets/tenant_admin_xfile_preview.dart';
import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';

import 'support/tenant_admin_image_crop_harness.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  tearDownAll(() async {
    await GetIt.I.reset();
  });

  group('Static Asset Image Crop (Device)', () {
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
          body: TenantAdminStaticAssetCreateScreen(),
        ),
      );

      await tester.tap(find.byType(DropdownButtonFormField<String>).last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('POI').last);
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
          body: TenantAdminStaticAssetCreateScreen(),
        ),
      );

      await tester.tap(find.byType(DropdownButtonFormField<String>).last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('POI').last);
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
          body: TenantAdminStaticAssetEditScreen(assetId: 'asset-1'),
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
          body: TenantAdminStaticAssetEditScreen(assetId: 'asset-1'),
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

  group('Static Asset Image Crop (Web URL)', () {
    testWidgets('create: avatar opens crop sheet (1:1)', (tester) async {
      await _registerCreateFakes();
      await pumpWithAutoRoute(
        tester,
        const Scaffold(
          body: TenantAdminStaticAssetCreateScreen(),
        ),
      );

      await tester.tap(find.byType(DropdownButtonFormField<String>).last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('POI').last);
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
          body: TenantAdminStaticAssetCreateScreen(),
        ),
      );

      await tester.tap(find.byType(DropdownButtonFormField<String>).last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('POI').last);
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
          body: TenantAdminStaticAssetEditScreen(assetId: 'asset-1'),
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
          body: TenantAdminStaticAssetEditScreen(assetId: 'asset-1'),
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

  group('Static Asset Media Persistence', () {
    testWidgets(
        'uploaded cover preview is shown and persists on edit reload/list',
        (tester) async {
      final repository = await _registerEditFakes();
      final controller = GetIt.I.get<TenantAdminStaticAssetsController>();

      await pumpWithAutoRoute(
        tester,
        const Scaffold(
          body: TenantAdminStaticAssetEditScreen(assetId: 'asset-1'),
        ),
      );
      await pumpUntilFound(tester, find.text('Editar ativo'));

      final uploadedFile = writeTempPng(
        name: 'uploaded-cover.png',
        width: 1400,
        height: 900,
      );
      controller.updateCoverFile(
        XFile(
          uploadedFile.path,
          name: 'uploaded-cover.png',
          mimeType: 'image/png',
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(TenantAdminXFilePreview), findsOneWidget);

      final saveButton = find.text('Salvar ativo');
      await tester.ensureVisible(saveButton);
      await tester.tap(saveButton);
      await tester.pumpAndSettle();
      await pumpUntilFound(tester, find.text('Ativo atualizado.'));
      final persisted = await repository.fetchStaticAsset('asset-1');
      expect(
        persisted.coverUrl,
        _FakeStaticAssetsRepository.generatedCoverUploadUrl,
      );
      await controller.initEdit('asset-1');
      await tester.pumpAndSettle();

      final editCoverImageFinder = find.byWidgetPredicate((widget) {
        return widget is BellugaNetworkImage &&
            widget.url == _FakeStaticAssetsRepository.generatedCoverUploadUrl;
      });
      await pumpUntilFound(tester, editCoverImageFinder, maxPumps: 300);
      expect(editCoverImageFinder, findsOneWidget);
    });
  });
}

Future<_FakeStaticAssetsRepository> _registerCreateFakes() async {
  await GetIt.I.reset();
  final proxyBytes = writeTempPng(name: 'proxy.png').readAsBytesSync();
  final repository = _FakeStaticAssetsRepository();
  GetIt.I.registerSingleton<TenantAdminExternalImageProxyContract>(
    _FakeExternalImageProxy(proxyBytes),
  );
  GetIt.I.registerSingleton<TenantAdminImageIngestionService>(
    TenantAdminImageIngestionService(),
  );
  GetIt.I.registerSingleton<TenantAdminStaticAssetsController>(
    TenantAdminStaticAssetsController(
      repository: repository,
      taxonomiesRepository: _FakeTaxonomiesRepository(),
      locationSelection: TenantAdminLocationSelectionService(),
    ),
  );
  return repository;
}

Future<_FakeStaticAssetsRepository> _registerEditFakes() async {
  await GetIt.I.reset();
  final proxyBytes = writeTempPng(name: 'proxy.png').readAsBytesSync();
  final repository = _FakeStaticAssetsRepository();
  GetIt.I.registerSingleton<TenantAdminExternalImageProxyContract>(
    _FakeExternalImageProxy(proxyBytes),
  );
  GetIt.I.registerSingleton<TenantAdminImageIngestionService>(
    TenantAdminImageIngestionService(),
  );
  GetIt.I.registerSingleton<TenantAdminStaticAssetsController>(
    TenantAdminStaticAssetsController(
      repository: repository,
      taxonomiesRepository: _FakeTaxonomiesRepository(),
      locationSelection: TenantAdminLocationSelectionService(),
    ),
  );
  return repository;
}

class _FakeExternalImageProxy implements TenantAdminExternalImageProxyContract {
  _FakeExternalImageProxy(this._bytes);

  final Uint8List _bytes;

  @override
  Future<Uint8List> fetchExternalImageBytes({required String imageUrl}) async {
    return _bytes;
  }
}

class _FakeStaticAssetsRepository
    with TenantAdminStaticAssetsPaginationMixin
    implements TenantAdminStaticAssetsRepositoryContract {
  _FakeStaticAssetsRepository({
    List<TenantAdminStaticAsset>? seededAssets,
  }) : _assets = List<TenantAdminStaticAsset>.of(
          seededAssets ??
              [
                TenantAdminStaticAsset(
                  id: 'asset-1',
                  profileType: 'poi',
                  displayName: 'Praia',
                  slug: 'praia',
                  isActive: true,
                  taxonomyTerms: [],
                ),
              ],
        );

  static const String generatedAvatarUploadUrl =
      'https://tenant-a.test/media/static-assets/avatar-uploaded.png';
  static const String generatedCoverUploadUrl =
      'https://tenant-a.test/media/static-assets/cover-uploaded.png';

  final List<TenantAdminStaticAsset> _assets;

  @override
  Future<List<TenantAdminStaticAsset>> fetchStaticAssets() async =>
      List<TenantAdminStaticAsset>.unmodifiable(_assets);

  @override
  Future<TenantAdminPagedResult<TenantAdminStaticAsset>> fetchStaticAssetsPage({
    required int page,
    required int pageSize,
  }) async {
    final items = await fetchStaticAssets();
    if (page <= 0 || pageSize <= 0) {
      return TenantAdminPagedResult<TenantAdminStaticAsset>(
        items: <TenantAdminStaticAsset>[],
        hasMore: false,
      );
    }
    final start = (page - 1) * pageSize;
    if (start >= items.length) {
      return TenantAdminPagedResult<TenantAdminStaticAsset>(
        items: <TenantAdminStaticAsset>[],
        hasMore: false,
      );
    }
    final end = start + pageSize;
    final endIndex = end > items.length ? items.length : end;
    return TenantAdminPagedResult<TenantAdminStaticAsset>(
      items: items.sublist(start, endIndex),
      hasMore: endIndex < items.length,
    );
  }

  @override
  Future<TenantAdminStaticAsset> fetchStaticAsset(String assetId) async {
    for (final asset in _assets) {
      if (asset.id == assetId) {
        return asset;
      }
    }
    return TenantAdminStaticAsset(
      id: assetId,
      profileType: 'poi',
      displayName: 'Praia',
      slug: 'praia',
      isActive: true,
      taxonomyTerms: [],
    );
  }

  @override
  Future<List<TenantAdminStaticProfileTypeDefinition>>
      fetchStaticProfileTypes() async {
    return [
      TenantAdminStaticProfileTypeDefinition(
        type: 'poi',
        label: 'POI',
        allowedTaxonomies: [],
        capabilities: TenantAdminStaticProfileTypeCapabilities(
          isPoiEnabled: false,
          hasBio: true,
          hasContent: true,
          hasTaxonomies: false,
          hasAvatar: true,
          hasCover: true,
        ),
      ),
    ];
  }

  @override
  Future<TenantAdminPagedResult<TenantAdminStaticProfileTypeDefinition>>
      fetchStaticProfileTypesPage({
    required int page,
    required int pageSize,
  }) async {
    final items = await fetchStaticProfileTypes();
    if (page <= 0 || pageSize <= 0) {
      return TenantAdminPagedResult<TenantAdminStaticProfileTypeDefinition>(
        items: <TenantAdminStaticProfileTypeDefinition>[],
        hasMore: false,
      );
    }
    final start = (page - 1) * pageSize;
    if (start >= items.length) {
      return TenantAdminPagedResult<TenantAdminStaticProfileTypeDefinition>(
        items: <TenantAdminStaticProfileTypeDefinition>[],
        hasMore: false,
      );
    }
    final end = start + pageSize;
    final endIndex = end > items.length ? items.length : end;
    return TenantAdminPagedResult<TenantAdminStaticProfileTypeDefinition>(
      items: items.sublist(start, endIndex),
      hasMore: endIndex < items.length,
    );
  }

  @override
  Future<TenantAdminStaticAsset> createStaticAsset({
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
    final resolvedAvatarUrl =
        avatarUpload != null ? generatedAvatarUploadUrl : avatarUrl;
    final resolvedCoverUrl =
        coverUpload != null ? generatedCoverUploadUrl : coverUrl;
    final asset = TenantAdminStaticAsset(
      id: 'asset-created',
      profileType: profileType,
      displayName: displayName,
      slug: 'asset-created',
      isActive: true,
      location: location,
      taxonomyTerms: taxonomyTerms,
      bio: bio,
      content: content,
      avatarUrl: resolvedAvatarUrl,
      coverUrl: resolvedCoverUrl,
    );
    _assets.add(asset);
    return asset;
  }

  @override
  Future<TenantAdminStaticAsset> updateStaticAsset({
    required String assetId,
    String? profileType,
    String? displayName,
    String? slug,
    TenantAdminLocation? location,
    List<TenantAdminTaxonomyTerm>? taxonomyTerms,
    String? bio,
    String? content,
    String? avatarUrl,
    String? coverUrl,
    bool? removeAvatar,
    bool? removeCover,
    TenantAdminMediaUpload? avatarUpload,
    TenantAdminMediaUpload? coverUpload,
  }) async {
    TenantAdminStaticAsset? existing;
    for (final asset in _assets) {
      if (asset.id == assetId) {
        existing = asset;
        break;
      }
    }

    final resolvedAvatarUrl = avatarUpload != null
        ? generatedAvatarUploadUrl
        : avatarUrl ?? existing?.avatarUrl;
    final resolvedCoverUrl = coverUpload != null
        ? generatedCoverUploadUrl
        : coverUrl ?? existing?.coverUrl;

    final updated = TenantAdminStaticAsset(
      id: assetId,
      profileType: profileType ?? existing?.profileType ?? 'poi',
      displayName: displayName ?? existing?.displayName ?? 'Praia',
      slug: slug ?? existing?.slug ?? 'praia',
      isActive: true,
      location: location ?? existing?.location,
      taxonomyTerms: taxonomyTerms ?? existing?.taxonomyTerms ?? [],
      bio: bio ?? existing?.bio,
      content: content ?? existing?.content,
      avatarUrl: resolvedAvatarUrl,
      coverUrl: resolvedCoverUrl,
    );
    final index = _assets.indexWhere((asset) => asset.id == assetId);
    if (index >= 0) {
      _assets[index] = updated;
    } else {
      _assets.add(updated);
    }
    return updated;
  }

  @override
  Future<void> deleteStaticAsset(String assetId) async {
    throw UnimplementedError();
  }

  @override
  Future<TenantAdminStaticAsset> restoreStaticAsset(String assetId) async {
    throw UnimplementedError();
  }

  @override
  Future<void> forceDeleteStaticAsset(String assetId) async {
    throw UnimplementedError();
  }

  @override
  Future<TenantAdminStaticProfileTypeDefinition> createStaticProfileType({
    required String type,
    required String label,
    List<String> allowedTaxonomies = const [],
    required TenantAdminStaticProfileTypeCapabilities capabilities,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<TenantAdminStaticProfileTypeDefinition> updateStaticProfileType({
    required String type,
    String? newType,
    String? label,
    List<String>? allowedTaxonomies,
    TenantAdminStaticProfileTypeCapabilities? capabilities,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteStaticProfileType(String type) async {
    throw UnimplementedError();
  }
}

class _FakeTaxonomiesRepository
    extends TenantAdminTaxonomiesRepositoryContract {
  @override
  Future<List<TenantAdminTaxonomyDefinition>> fetchTaxonomies() async => [];

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
      [];
}
