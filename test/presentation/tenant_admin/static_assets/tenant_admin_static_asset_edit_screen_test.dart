import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/domain/repositories/tenant_admin_static_assets_repository_contract.dart';
import 'package:belluga_now/domain/repositories/tenant_admin_taxonomies_repository_contract.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_location.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_media_upload.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_paged_result.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_static_asset.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_static_profile_type.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_definition.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_term.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_term_definition.dart';
import 'package:belluga_now/infrastructure/services/tenant_admin/tenant_admin_location_selection_service.dart';
import 'package:belluga_now/presentation/tenant_admin/static_assets/controllers/tenant_admin_static_assets_controller.dart';
import 'package:belluga_now/presentation/tenant_admin/static_assets/screens/tenant_admin_static_asset_edit_screen.dart';
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
  final router = _buildTestRouter(
    const TenantAdminStaticAssetEditScreen(assetId: 'asset-1'),
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

TenantAdminStaticAsset _sampleAsset() {
  return const TenantAdminStaticAsset(
    id: 'asset-1',
    profileType: 'poi',
    displayName: 'Praia da Serra',
    slug: 'praia-da-serra',
    isActive: true,
    taxonomyTerms: [],
  );
}

bool _chipSelected(WidgetTester tester, Finder chipFinder) {
  final chip = tester.widget<FilterChip>(chipFinder);
  return chip.selected;
}

class _FakeStaticAssetsRepository
    with TenantAdminStaticAssetsPaginationMixin
    implements TenantAdminStaticAssetsRepositoryContract {
  _FakeStaticAssetsRepository({
    required this.asset,
    this.failSlugUpdate = false,
    this.failTaxonomyUpdate = false,
  });

  TenantAdminStaticAsset asset;
  final bool failSlugUpdate;
  final bool failTaxonomyUpdate;

  String? lastUpdatedSlug;
  List<TenantAdminTaxonomyTerm>? lastUpdatedTaxonomyTerms;

  @override
  Future<TenantAdminStaticAsset> createStaticAsset({
    required String profileType,
    required String displayName,
    TenantAdminLocation? location,
    List<TenantAdminTaxonomyTerm> taxonomyTerms = const [],
    List<String> tags = const [],
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
  Future<TenantAdminStaticProfileTypeDefinition> createStaticProfileType({
    required String type,
    required String label,
    List<String> allowedTaxonomies = const [],
    required TenantAdminStaticProfileTypeCapabilities capabilities,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteStaticAsset(String assetId) async {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteStaticProfileType(String type) async {
    throw UnimplementedError();
  }

  @override
  Future<TenantAdminStaticAsset> fetchStaticAsset(String assetId) async {
    return asset;
  }

  @override
  Future<List<TenantAdminStaticAsset>> fetchStaticAssets() async {
    return [asset];
  }

  @override
  Future<TenantAdminPagedResult<TenantAdminStaticAsset>> fetchStaticAssetsPage({
    required int page,
    required int pageSize,
  }) async {
    final assets = await fetchStaticAssets();
    final start = (page - 1) * pageSize;
    if (page <= 0 || pageSize <= 0 || start >= assets.length) {
      return const TenantAdminPagedResult<TenantAdminStaticAsset>(
        items: <TenantAdminStaticAsset>[],
        hasMore: false,
      );
    }
    final end =
        start + pageSize < assets.length ? start + pageSize : assets.length;
    return TenantAdminPagedResult<TenantAdminStaticAsset>(
      items: assets.sublist(start, end),
      hasMore: end < assets.length,
    );
  }

  @override
  Future<List<TenantAdminStaticProfileTypeDefinition>>
      fetchStaticProfileTypes() async {
    return const [
      TenantAdminStaticProfileTypeDefinition(
        type: 'poi',
        label: 'POI',
        allowedTaxonomies: ['genre'],
        capabilities: TenantAdminStaticProfileTypeCapabilities(
          isPoiEnabled: false,
          hasBio: false,
          hasTaxonomies: true,
          hasAvatar: false,
          hasCover: false,
          hasContent: false,
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
    final profileTypes = await fetchStaticProfileTypes();
    final start = (page - 1) * pageSize;
    if (page <= 0 || pageSize <= 0 || start >= profileTypes.length) {
      return const TenantAdminPagedResult<
          TenantAdminStaticProfileTypeDefinition>(
        items: <TenantAdminStaticProfileTypeDefinition>[],
        hasMore: false,
      );
    }
    final end = start + pageSize < profileTypes.length
        ? start + pageSize
        : profileTypes.length;
    return TenantAdminPagedResult<TenantAdminStaticProfileTypeDefinition>(
      items: profileTypes.sublist(start, end),
      hasMore: end < profileTypes.length,
    );
  }

  @override
  Future<void> forceDeleteStaticAsset(String assetId) async {
    throw UnimplementedError();
  }

  @override
  Future<TenantAdminStaticAsset> restoreStaticAsset(String assetId) async {
    throw UnimplementedError();
  }

  @override
  Future<TenantAdminStaticAsset> updateStaticAsset({
    required String assetId,
    String? profileType,
    String? displayName,
    String? slug,
    TenantAdminLocation? location,
    List<TenantAdminTaxonomyTerm>? taxonomyTerms,
    List<String>? tags,
    String? bio,
    String? content,
    String? avatarUrl,
    String? coverUrl,
    TenantAdminMediaUpload? avatarUpload,
    TenantAdminMediaUpload? coverUpload,
  }) async {
    if (slug != null) {
      if (failSlugUpdate) {
        throw const FormatException('slug already exists');
      }
      lastUpdatedSlug = slug;
    }
    if (taxonomyTerms != null) {
      if (failTaxonomyUpdate) {
        throw Exception('taxonomy update failed');
      }
      lastUpdatedTaxonomyTerms = List<TenantAdminTaxonomyTerm>.from(
        taxonomyTerms,
      );
    }
    asset = TenantAdminStaticAsset(
      id: asset.id,
      profileType: profileType ?? asset.profileType,
      displayName: displayName ?? asset.displayName,
      slug: slug ?? asset.slug,
      isActive: asset.isActive,
      avatarUrl: avatarUrl ?? asset.avatarUrl,
      coverUrl: coverUrl ?? asset.coverUrl,
      bio: bio ?? asset.bio,
      content: content ?? asset.content,
      tags: tags ?? asset.tags,
      categories: asset.categories,
      taxonomyTerms: taxonomyTerms ?? asset.taxonomyTerms,
      location: location ?? asset.location,
    );
    return asset;
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
}

class _FakeTaxonomiesRepository
    with TenantAdminTaxonomiesPaginationMixin
    implements TenantAdminTaxonomiesRepositoryContract {
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
  Future<TenantAdminTaxonomyTermDefinition> createTerm({
    required String taxonomyId,
    required String slug,
    required String name,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteTaxonomy(String taxonomyId) async {
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
  Future<List<TenantAdminTaxonomyDefinition>> fetchTaxonomies() async {
    return const [
      TenantAdminTaxonomyDefinition(
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
    required int page,
    required int pageSize,
  }) async {
    final taxonomies = await fetchTaxonomies();
    final start = (page - 1) * pageSize;
    if (page <= 0 || pageSize <= 0 || start >= taxonomies.length) {
      return const TenantAdminPagedResult<TenantAdminTaxonomyDefinition>(
        items: <TenantAdminTaxonomyDefinition>[],
        hasMore: false,
      );
    }
    final end = start + pageSize < taxonomies.length
        ? start + pageSize
        : taxonomies.length;
    return TenantAdminPagedResult<TenantAdminTaxonomyDefinition>(
      items: taxonomies.sublist(start, end),
      hasMore: end < taxonomies.length,
    );
  }

  @override
  Future<List<TenantAdminTaxonomyTermDefinition>> fetchTerms({
    required String taxonomyId,
  }) async {
    if (taxonomyId != 'tax-1') {
      return const [];
    }
    return const [
      TenantAdminTaxonomyTermDefinition(
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
    required String taxonomyId,
    required int page,
    required int pageSize,
  }) async {
    final terms = await fetchTerms(taxonomyId: taxonomyId);
    final start = (page - 1) * pageSize;
    if (page <= 0 || pageSize <= 0 || start >= terms.length) {
      return const TenantAdminPagedResult<TenantAdminTaxonomyTermDefinition>(
        items: <TenantAdminTaxonomyTermDefinition>[],
        hasMore: false,
      );
    }
    final end =
        start + pageSize < terms.length ? start + pageSize : terms.length;
    return TenantAdminPagedResult<TenantAdminTaxonomyTermDefinition>(
      items: terms.sublist(start, end),
      hasMore: end < terms.length,
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
}
