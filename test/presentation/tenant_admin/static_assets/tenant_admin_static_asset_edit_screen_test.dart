import 'dart:typed_data';

import 'package:auto_route/auto_route.dart';
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
import 'package:belluga_now/presentation/tenant_admin/shared/widgets/tenant_admin_image_upload_field.dart';
import 'package:belluga_now/presentation/tenant_admin/static_assets/controllers/tenant_admin_static_assets_controller.dart';
import 'package:belluga_now/presentation/tenant_admin/static_assets/screens/tenant_admin_static_asset_edit_screen.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/utils/tenant_admin_image_ingestion_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await GetIt.I.reset();
  });

  tearDown(() async {
    await GetIt.I.reset();
  });

  testWidgets(
      'opens slug per-field edit sheet and surfaces uniqueness errors from backend',
      (tester) async {
    final assetsRepository = _FakeStaticAssetsRepository(
      asset: _sampleAsset(),
      failSlugUpdate: true,
    );
    await _pumpScreen(
      tester,
      assetsRepository: assetsRepository,
      taxonomiesRepository: _FakeTaxonomiesRepository(),
    );

    await tester.tap(find.byTooltip('Editar slug'));
    await tester.pumpAndSettle();

    expect(find.text('Editar slug do ativo'), findsOneWidget);

    final slugField = find.descendant(
      of: find.byType(BottomSheet),
      matching: find.byType(TextFormField),
    );
    await tester.enterText(slugField, 'slug-duplicado');

    await tester.tap(
      find.descendant(
        of: find.byType(BottomSheet),
        matching: find.text('Salvar'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('FormatException: slug already exists'),
        findsOneWidget);
  });

  testWidgets('auto-saves taxonomy selection after chip toggle',
      (tester) async {
    final assetsRepository = _FakeStaticAssetsRepository(
      asset: _sampleAsset(),
    );
    await _pumpScreen(
      tester,
      assetsRepository: assetsRepository,
      taxonomiesRepository: _FakeTaxonomiesRepository(),
    );

    final chipFinder = find.widgetWithText(FilterChip, 'Rock');
    expect(chipFinder, findsOneWidget);
    expect(_chipSelected(tester, chipFinder), isFalse);

    await tester.tap(chipFinder);
    await tester.pumpAndSettle();

    final sentTerms = assetsRepository.lastUpdatedTaxonomyTerms;
    expect(sentTerms, isNotNull);
    expect(sentTerms, hasLength(1));
    expect(sentTerms!.first.type, 'genre');
    expect(sentTerms.first.value, 'rock');
    expect(_chipSelected(tester, chipFinder), isTrue);
  });

  testWidgets('rolls back taxonomy selection when auto-save fails',
      (tester) async {
    final assetsRepository = _FakeStaticAssetsRepository(
      asset: _sampleAsset(),
      failTaxonomyUpdate: true,
    );
    await _pumpScreen(
      tester,
      assetsRepository: assetsRepository,
      taxonomiesRepository: _FakeTaxonomiesRepository(),
    );

    final chipFinder = find.widgetWithText(FilterChip, 'Rock');
    expect(chipFinder, findsOneWidget);
    expect(_chipSelected(tester, chipFinder), isFalse);

    await tester.tap(chipFinder);
    await tester.pumpAndSettle();

    expect(_chipSelected(tester, chipFinder), isFalse);
    expect(
      find.text('Nao foi possivel salvar a taxonomia. Alteracao desfeita.'),
      findsOneWidget,
    );
  });

  testWidgets('renders persisted avatar and cover URLs in media section',
      (tester) async {
    const avatarUrl = 'https://tenant-a.test/media/static-assets/avatar.png';
    const coverUrl = 'https://tenant-a.test/media/static-assets/cover.png';
    final assetsRepository = _FakeStaticAssetsRepository(
      asset: _sampleAsset(
        avatarUrl: avatarUrl,
        coverUrl: coverUrl,
      ),
      profileTypeCapabilities: TenantAdminStaticProfileTypeCapabilities(
        isPoiEnabled: TenantAdminFlagValue(false),
        hasBio: TenantAdminFlagValue(false),
        hasTaxonomies: TenantAdminFlagValue(true),
        hasAvatar: TenantAdminFlagValue(true),
        hasCover: TenantAdminFlagValue(true),
        hasContent: TenantAdminFlagValue(false),
      ),
    );
    await _pumpScreen(
      tester,
      assetsRepository: assetsRepository,
      taxonomiesRepository: _FakeTaxonomiesRepository(),
    );

    final avatarImageFinder = find.byWidgetPredicate((widget) {
      return widget is BellugaNetworkImage && widget.url == avatarUrl;
    });
    final coverImageFinder = find.byWidgetPredicate((widget) {
      return widget is BellugaNetworkImage && widget.url == coverUrl;
    });

    expect(avatarImageFinder, findsOneWidget);
    expect(coverImageFinder, findsOneWidget);
    expect(find.byType(TenantAdminImageUploadField), findsNWidgets(2));
  });

  testWidgets('sends explicit remove avatar flag when clearing persisted media',
      (tester) async {
    final assetsRepository = _FakeStaticAssetsRepository(
      asset: _sampleAsset(
        avatarUrl: 'https://tenant-a.test/media/static-assets/avatar.png',
        coverUrl: 'https://tenant-a.test/media/static-assets/cover.png',
      ),
      profileTypeCapabilities: TenantAdminStaticProfileTypeCapabilities(
        isPoiEnabled: TenantAdminFlagValue(false),
        hasBio: TenantAdminFlagValue(false),
        hasTaxonomies: TenantAdminFlagValue(true),
        hasAvatar: TenantAdminFlagValue(true),
        hasCover: TenantAdminFlagValue(true),
        hasContent: TenantAdminFlagValue(false),
      ),
    );
    await _pumpScreen(
      tester,
      assetsRepository: assetsRepository,
      taxonomiesRepository: _FakeTaxonomiesRepository(),
    );

    final scrollable = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(
      find.text('Remover').first,
      200,
      scrollable: scrollable,
    );
    await tester.tap(find.text('Remover').first);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Salvar ativo'),
      200,
      scrollable: scrollable,
    );
    await tester.tap(find.text('Salvar ativo'));
    await tester.pumpAndSettle();

    expect(assetsRepository.lastRemoveAvatar, isTrue);
    expect(assetsRepository.lastRemoveCover, isNot(true));
    expect(assetsRepository.asset.avatarUrl, isNull);
    expect(assetsRepository.asset.coverUrl, isNotNull);
  });
}

Future<void> _pumpScreen(
  WidgetTester tester, {
  required _FakeStaticAssetsRepository assetsRepository,
  required _FakeTaxonomiesRepository taxonomiesRepository,
}) async {
  final controller = TenantAdminStaticAssetsController(
    repository: assetsRepository,
    taxonomiesRepository: taxonomiesRepository,
    locationSelection: TenantAdminLocationSelectionService(),
  );
  GetIt.I.registerSingleton<TenantAdminStaticAssetsController>(controller);
  GetIt.I.registerSingleton<TenantAdminExternalImageProxyContract>(
    _FakeExternalImageProxy(),
  );
  GetIt.I.registerSingleton<TenantAdminImageIngestionService>(
    TenantAdminImageIngestionService(),
  );
  final router = _buildTestRouter(
    TenantAdminStaticAssetEditScreen(assetId: 'asset-1'),
  );

  await tester.pumpWidget(
    MaterialApp.router(
      routeInformationParser: router.defaultRouteParser(),
      routerDelegate: router.delegate(),
    ),
  );
  await tester.pumpAndSettle();
}

RootStackRouter _buildTestRouter(Widget child) {
  return RootStackRouter.build(
    routes: [
      NamedRouteDef(
        name: 'static-asset-edit-test',
        path: '/',
        builder: (_, __) => child,
      ),
    ],
  )..ignorePopCompleters = true;
}

TenantAdminStaticAsset _sampleAsset({
  String? avatarUrl,
  String? coverUrl,
}) {
  return tenantAdminStaticAssetFromRaw(
    id: 'asset-1',
    profileType: 'poi',
    displayName: 'Praia da Serra',
    slug: 'praia-da-serra',
    isActive: true,
    avatarUrl: avatarUrl,
    coverUrl: coverUrl,
    taxonomyTerms: const TenantAdminTaxonomyTerms.empty(),
  );
}

bool _chipSelected(WidgetTester tester, Finder chipFinder) {
  final chip = tester.widget<FilterChip>(chipFinder);
  return chip.selected;
}

class _FakeExternalImageProxy implements TenantAdminExternalImageProxyContract {
  @override
  Future<Uint8List> fetchExternalImageBytes({required Object imageUrl}) async {
    throw UnimplementedError();
  }
}

class _FakeStaticAssetsRepository
    with TenantAdminStaticAssetsPaginationMixin
    implements TenantAdminStaticAssetsRepositoryContract {
  _FakeStaticAssetsRepository({
    required this.asset,
    this.failSlugUpdate = false,
    this.failTaxonomyUpdate = false,
    TenantAdminStaticProfileTypeCapabilities? profileTypeCapabilities,
  }) : profileTypeCapabilities = profileTypeCapabilities ??
            TenantAdminStaticProfileTypeCapabilities(
              isPoiEnabled: TenantAdminFlagValue(false),
              hasBio: TenantAdminFlagValue(false),
              hasTaxonomies: TenantAdminFlagValue(true),
              hasAvatar: TenantAdminFlagValue(false),
              hasCover: TenantAdminFlagValue(false),
              hasContent: TenantAdminFlagValue(false),
            );

  TenantAdminStaticAsset asset;
  final bool failSlugUpdate;
  final bool failTaxonomyUpdate;
  final TenantAdminStaticProfileTypeCapabilities profileTypeCapabilities;

  String? lastUpdatedSlug;
  List<TenantAdminTaxonomyTerm>? lastUpdatedTaxonomyTerms;
  bool? lastRemoveAvatar;
  bool? lastRemoveCover;

  @override
  Future<TenantAdminStaticAsset> createStaticAsset({
    required TenantAdminStaticAssetsRepoString profileType,
    required TenantAdminStaticAssetsRepoString displayName,
    TenantAdminLocation? location,
    TenantAdminTaxonomyTerms taxonomyTerms =
        const TenantAdminTaxonomyTerms.empty(),
    TenantAdminStaticAssetsRepoString? bio,
    TenantAdminStaticAssetsRepoString? content,
    TenantAdminStaticAssetsRepoString? avatarUrl,
    TenantAdminStaticAssetsRepoString? coverUrl,
    TenantAdminMediaUpload? avatarUpload,
    TenantAdminMediaUpload? coverUpload,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<TenantAdminStaticProfileTypeDefinition> createStaticProfileType({
    required TenantAdminStaticAssetsRepoString type,
    required TenantAdminStaticAssetsRepoString label,
    List<TenantAdminStaticAssetsRepoString>? allowedTaxonomies,
    required TenantAdminStaticProfileTypeCapabilities capabilities,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteStaticAsset(
      TenantAdminStaticAssetsRepoString assetId) async {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteStaticProfileType(
      TenantAdminStaticAssetsRepoString type) async {
    throw UnimplementedError();
  }

  @override
  Future<TenantAdminStaticAsset> fetchStaticAsset(
    TenantAdminStaticAssetsRepoString assetId,
  ) async {
    return asset;
  }

  @override
  Future<List<TenantAdminStaticAsset>> fetchStaticAssets() async {
    return [asset];
  }

  @override
  Future<TenantAdminPagedResult<TenantAdminStaticAsset>> fetchStaticAssetsPage({
    required TenantAdminStaticAssetsRepoInt page,
    required TenantAdminStaticAssetsRepoInt pageSize,
  }) async {
    final assets = await fetchStaticAssets();
    final start = (page.value - 1) * pageSize.value;
    if (page.value <= 0 || pageSize.value <= 0 || start >= assets.length) {
      return tenantAdminPagedResultFromRaw(
        items: <TenantAdminStaticAsset>[],
        hasMore: false,
      );
    }
    final end = start + pageSize.value < assets.length
        ? start + pageSize.value
        : assets.length;
    return tenantAdminPagedResultFromRaw(
      items: assets.sublist(start, end),
      hasMore: end < assets.length,
    );
  }

  @override
  Future<List<TenantAdminStaticProfileTypeDefinition>>
      fetchStaticProfileTypes() async {
    return [
      tenantAdminStaticProfileTypeDefinitionFromRaw(
        type: 'poi',
        label: 'POI',
        allowedTaxonomies: ['genre'],
        capabilities: profileTypeCapabilities,
      ),
    ];
  }

  @override
  Future<TenantAdminPagedResult<TenantAdminStaticProfileTypeDefinition>>
      fetchStaticProfileTypesPage({
    required TenantAdminStaticAssetsRepoInt page,
    required TenantAdminStaticAssetsRepoInt pageSize,
  }) async {
    final profileTypes = await fetchStaticProfileTypes();
    final start = (page.value - 1) * pageSize.value;
    if (page.value <= 0 ||
        pageSize.value <= 0 ||
        start >= profileTypes.length) {
      return tenantAdminPagedResultFromRaw(
        items: <TenantAdminStaticProfileTypeDefinition>[],
        hasMore: false,
      );
    }
    final end = start + pageSize.value < profileTypes.length
        ? start + pageSize.value
        : profileTypes.length;
    return tenantAdminPagedResultFromRaw(
      items: profileTypes.sublist(start, end),
      hasMore: end < profileTypes.length,
    );
  }

  @override
  Future<void> forceDeleteStaticAsset(
    TenantAdminStaticAssetsRepoString assetId,
  ) async {
    throw UnimplementedError();
  }

  @override
  Future<TenantAdminStaticAsset> restoreStaticAsset(
    TenantAdminStaticAssetsRepoString assetId,
  ) async {
    throw UnimplementedError();
  }

  @override
  Future<TenantAdminStaticAsset> updateStaticAsset({
    required TenantAdminStaticAssetsRepoString assetId,
    TenantAdminStaticAssetsRepoString? profileType,
    TenantAdminStaticAssetsRepoString? displayName,
    TenantAdminStaticAssetsRepoString? slug,
    TenantAdminLocation? location,
    TenantAdminTaxonomyTerms? taxonomyTerms,
    TenantAdminStaticAssetsRepoString? bio,
    TenantAdminStaticAssetsRepoString? content,
    TenantAdminStaticAssetsRepoString? avatarUrl,
    TenantAdminStaticAssetsRepoString? coverUrl,
    TenantAdminStaticAssetsRepoBool? removeAvatar,
    TenantAdminStaticAssetsRepoBool? removeCover,
    TenantAdminMediaUpload? avatarUpload,
    TenantAdminMediaUpload? coverUpload,
  }) async {
    lastRemoveAvatar = removeAvatar?.value;
    lastRemoveCover = removeCover?.value;
    if (slug != null) {
      if (failSlugUpdate) {
        throw const FormatException('slug already exists');
      }
      lastUpdatedSlug = slug.value;
    }
    if (taxonomyTerms != null) {
      if (failTaxonomyUpdate) {
        throw Exception('taxonomy update failed');
      }
      lastUpdatedTaxonomyTerms =
          List<TenantAdminTaxonomyTerm>.from(taxonomyTerms.items);
    }
    asset = tenantAdminStaticAssetFromRaw(
      id: asset.id,
      profileType: profileType?.value ?? asset.profileType,
      displayName: displayName?.value ?? asset.displayName,
      slug: slug?.value ?? asset.slug,
      isActive: asset.isActive,
      avatarUrl: removeAvatar?.value == true
          ? null
          : (avatarUrl?.value ?? asset.avatarUrl),
      coverUrl: removeCover?.value == true
          ? null
          : (coverUrl?.value ?? asset.coverUrl),
      bio: bio?.value ?? asset.bio,
      content: content?.value ?? asset.content,
      taxonomyTerms: taxonomyTerms ?? asset.taxonomyTerms,
      location: location ?? asset.location,
    );
    return asset;
  }

  @override
  Future<TenantAdminStaticProfileTypeDefinition> updateStaticProfileType({
    required TenantAdminStaticAssetsRepoString type,
    TenantAdminStaticAssetsRepoString? newType,
    TenantAdminStaticAssetsRepoString? label,
    List<TenantAdminStaticAssetsRepoString>? allowedTaxonomies,
    TenantAdminStaticProfileTypeCapabilities? capabilities,
  }) async {
    throw UnimplementedError();
  }
}

class _FakeTaxonomiesRepository
    with TenantAdminTaxonomiesPaginationMixin
    implements TenantAdminTaxonomiesRepositoryContract {
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
  Future<TenantAdminTaxonomyTermDefinition> createTerm({
    required TenantAdminTaxRepoString taxonomyId,
    required TenantAdminTaxRepoString slug,
    required TenantAdminTaxRepoString name,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteTaxonomy(TenantAdminTaxRepoString taxonomyId) async {
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
  Future<List<TenantAdminTaxonomyDefinition>> fetchTaxonomies() async {
    return [
      tenantAdminTaxonomyDefinitionFromRaw(
        id: 'tax-1',
        slug: 'genre',
        name: 'Genero',
        appliesTo: ['static_asset'],
        icon: null,
        color: null,
      ),
    ];
  }

  @override
  Future<TenantAdminPagedResult<TenantAdminTaxonomyDefinition>>
      fetchTaxonomiesPage({
    required TenantAdminTaxRepoInt page,
    required TenantAdminTaxRepoInt pageSize,
  }) async {
    final taxonomies = await fetchTaxonomies();
    final start = (page.value - 1) * pageSize.value;
    if (page.value <= 0 || pageSize.value <= 0 || start >= taxonomies.length) {
      return tenantAdminPagedResultFromRaw(
        items: <TenantAdminTaxonomyDefinition>[],
        hasMore: false,
      );
    }
    final end = start + pageSize.value < taxonomies.length
        ? start + pageSize.value
        : taxonomies.length;
    return tenantAdminPagedResultFromRaw(
      items: taxonomies.sublist(start, end),
      hasMore: end < taxonomies.length,
    );
  }

  @override
  Future<List<TenantAdminTaxonomyTermDefinition>> fetchTerms({
    required TenantAdminTaxRepoString taxonomyId,
  }) async {
    if (taxonomyId.value != 'tax-1') {
      return [];
    }
    return [
      tenantAdminTaxonomyTermDefinitionFromRaw(
        id: 'term-1',
        taxonomyId: 'tax-1',
        slug: 'rock',
        name: 'Rock',
      ),
    ];
  }

  @override
  Future<TenantAdminPagedResult<TenantAdminTaxonomyTermDefinition>>
      fetchTermsPage({
    required TenantAdminTaxRepoString taxonomyId,
    required TenantAdminTaxRepoInt page,
    required TenantAdminTaxRepoInt pageSize,
  }) async {
    final terms = await fetchTerms(taxonomyId: taxonomyId);
    final start = (page.value - 1) * pageSize.value;
    if (page.value <= 0 || pageSize.value <= 0 || start >= terms.length) {
      return tenantAdminPagedResultFromRaw(
        items: <TenantAdminTaxonomyTermDefinition>[],
        hasMore: false,
      );
    }
    final end = start + pageSize.value < terms.length
        ? start + pageSize.value
        : terms.length;
    return tenantAdminPagedResultFromRaw(
      items: terms.sublist(start, end),
      hasMore: end < terms.length,
    );
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
  Future<TenantAdminTaxonomyTermDefinition> updateTerm({
    required TenantAdminTaxRepoString taxonomyId,
    required TenantAdminTaxRepoString termId,
    TenantAdminTaxRepoString? slug,
    TenantAdminTaxRepoString? name,
  }) async {
    throw UnimplementedError();
  }
}
