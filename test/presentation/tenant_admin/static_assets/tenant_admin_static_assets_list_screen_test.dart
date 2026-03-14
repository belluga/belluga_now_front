import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
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
import 'package:belluga_now/presentation/shared/widgets/belluga_network_image.dart';
import 'package:belluga_now/presentation/tenant_admin/static_assets/controllers/tenant_admin_static_assets_controller.dart';
import 'package:belluga_now/presentation/tenant_admin/static_assets/screens/tenant_admin_static_assets_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

void main() {
  setUp(() async {
    await GetIt.I.reset();
  });

  tearDown(() async {
    await GetIt.I.reset();
  });

  testWidgets('renders asset list card with cover and avatar URLs', (
    tester,
  ) async {
    const coverUrl = 'https://tenant-a.test/media/static-assets/cover.png';
    const avatarUrl = 'https://tenant-a.test/media/static-assets/avatar.png';

    final controller = TenantAdminStaticAssetsController(
      repository: _FakeStaticAssetsRepository(
        assets: const [
          TenantAdminStaticAsset(
            id: 'asset-1',
            profileType: 'poi',
            displayName: 'Praia da Serra',
            slug: 'praia-da-serra',
            isActive: true,
            coverUrl: coverUrl,
            avatarUrl: avatarUrl,
          ),
        ],
      ),
      taxonomiesRepository: _FakeTaxonomiesRepository(),
      locationSelection: TenantAdminLocationSelectionService(),
    );
    GetIt.I.registerSingleton<TenantAdminStaticAssetsController>(controller);

    await tester
        .pumpWidget(_buildTestApp(const TenantAdminStaticAssetsListScreen()));
    await tester.pumpAndSettle();

    expect(
      find.byKey(
          const ValueKey<String>('tenant_admin_static_asset_card_asset-1')),
      findsOneWidget,
    );

    final coverImageFinder = find.byWidgetPredicate((widget) {
      return widget is BellugaNetworkImage &&
          widget.url == coverUrl &&
          widget.height == 120;
    });
    final avatarImageFinder = find.byWidgetPredicate((widget) {
      return widget is BellugaNetworkImage &&
          widget.url == avatarUrl &&
          widget.width == 40 &&
          widget.height == 40;
    });

    expect(coverImageFinder, findsOneWidget);
    expect(avatarImageFinder, findsOneWidget);
  });

  testWidgets('reloads assets list when returning from detail route',
      (tester) async {
    final repository = _FakeStaticAssetsRepository(
      assets: const [
        TenantAdminStaticAsset(
          id: 'asset-1',
          profileType: 'poi',
          displayName: 'Praia da Serra',
          slug: 'praia-da-serra',
          isActive: true,
        ),
      ],
    );
    final controller = TenantAdminStaticAssetsController(
      repository: repository,
      taxonomiesRepository: _FakeTaxonomiesRepository(),
      locationSelection: TenantAdminLocationSelectionService(),
    );
    GetIt.I.registerSingleton<TenantAdminStaticAssetsController>(controller);

    await tester
        .pumpWidget(_buildTestApp(const TenantAdminStaticAssetsListScreen()));
    await tester.pumpAndSettle();

    expect(repository.loadStaticAssetsCalls, 1);

    await tester.tap(find.byKey(
        const ValueKey<String>('tenant_admin_static_asset_card_asset-1')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey<String>('static_asset_detail_close')),
      findsOneWidget,
    );

    await tester
        .tap(find.byKey(const ValueKey<String>('static_asset_detail_close')));
    await tester.pumpAndSettle();

    expect(repository.loadStaticAssetsCalls, 2);
  });

  testWidgets('reloads assets list when returning from create route',
      (tester) async {
    final repository = _FakeStaticAssetsRepository(
      assets: const [
        TenantAdminStaticAsset(
          id: 'asset-1',
          profileType: 'poi',
          displayName: 'Praia da Serra',
          slug: 'praia-da-serra',
          isActive: true,
        ),
      ],
    );
    final controller = TenantAdminStaticAssetsController(
      repository: repository,
      taxonomiesRepository: _FakeTaxonomiesRepository(),
      locationSelection: TenantAdminLocationSelectionService(),
    );
    GetIt.I.registerSingleton<TenantAdminStaticAssetsController>(controller);

    await tester
        .pumpWidget(_buildTestApp(const TenantAdminStaticAssetsListScreen()));
    await tester.pumpAndSettle();

    expect(repository.loadStaticAssetsCalls, 1);

    await tester.tap(find.text('Criar ativo'));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey<String>('static_asset_create_close')),
      findsOneWidget,
    );

    await tester
        .tap(find.byKey(const ValueKey<String>('static_asset_create_close')));
    await tester.pumpAndSettle();

    expect(repository.loadStaticAssetsCalls, 2);
  });
}

Widget _buildTestApp(Widget child) {
  final router = RootStackRouter.build(
    routes: [
      NamedRouteDef(
        name: 'static-assets-list-test',
        path: '/',
        builder: (_, __) => child,
      ),
      NamedRouteDef(
        name: TenantAdminStaticAssetDetailRoute.name,
        path: '/static-assets/:assetId',
        builder: (_, __) => const _TestStaticAssetDetailRouteScreen(),
      ),
      NamedRouteDef(
        name: TenantAdminStaticAssetCreateRoute.name,
        path: '/static-assets/create',
        builder: (_, __) => const _TestStaticAssetCreateRouteScreen(),
      ),
    ],
  )..ignorePopCompleters = true;

  return MaterialApp.router(
    routeInformationParser: router.defaultRouteParser(),
    routerDelegate: router.delegate(),
  );
}

class _TestStaticAssetDetailRouteScreen extends StatelessWidget {
  const _TestStaticAssetDetailRouteScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: FilledButton(
          key: const ValueKey<String>('static_asset_detail_close'),
          onPressed: () => context.router.maybePop(),
          child: const Text('Voltar'),
        ),
      ),
    );
  }
}

class _TestStaticAssetCreateRouteScreen extends StatelessWidget {
  const _TestStaticAssetCreateRouteScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: FilledButton(
          key: const ValueKey<String>('static_asset_create_close'),
          onPressed: () => context.router.maybePop(),
          child: const Text('Voltar'),
        ),
      ),
    );
  }
}

class _FakeStaticAssetsRepository
    with TenantAdminStaticAssetsPaginationMixin
    implements TenantAdminStaticAssetsRepositoryContract {
  _FakeStaticAssetsRepository({
    required this.assets,
  });

  final List<TenantAdminStaticAsset> assets;
  int loadStaticAssetsCalls = 0;

  @override
  Future<void> loadStaticAssets({int pageSize = 20}) async {
    loadStaticAssetsCalls += 1;
    await super.loadStaticAssets(pageSize: pageSize);
  }

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
  }) {
    throw UnimplementedError();
  }

  @override
  Future<TenantAdminStaticProfileTypeDefinition> createStaticProfileType({
    required String type,
    required String label,
    List<String> allowedTaxonomies = const [],
    required TenantAdminStaticProfileTypeCapabilities capabilities,
  }) {
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
  Future<List<TenantAdminStaticAsset>> fetchStaticAssets() async => assets;

  @override
  Future<TenantAdminPagedResult<TenantAdminStaticAsset>> fetchStaticAssetsPage({
    required int page,
    required int pageSize,
  }) async {
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
  Future<TenantAdminStaticAsset> fetchStaticAsset(String assetId) async {
    return assets.firstWhere((asset) => asset.id == assetId);
  }

  @override
  Future<List<TenantAdminStaticProfileTypeDefinition>>
      fetchStaticProfileTypes() async {
    return const [];
  }

  @override
  Future<TenantAdminPagedResult<TenantAdminStaticProfileTypeDefinition>>
      fetchStaticProfileTypesPage({
    required int page,
    required int pageSize,
  }) async {
    return const TenantAdminPagedResult<TenantAdminStaticProfileTypeDefinition>(
      items: <TenantAdminStaticProfileTypeDefinition>[],
      hasMore: false,
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
  }) {
    throw UnimplementedError();
  }

  @override
  Future<TenantAdminStaticProfileTypeDefinition> updateStaticProfileType({
    required String type,
    String? newType,
    String? label,
    List<String>? allowedTaxonomies,
    TenantAdminStaticProfileTypeCapabilities? capabilities,
  }) {
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
  }) {
    throw UnimplementedError();
  }

  @override
  Future<TenantAdminTaxonomyTermDefinition> createTerm({
    required String taxonomyId,
    required String slug,
    required String name,
  }) {
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
    return const [];
  }

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
  }) async {
    return const [];
  }

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
  }) {
    throw UnimplementedError();
  }

  @override
  Future<TenantAdminTaxonomyTermDefinition> updateTerm({
    required String taxonomyId,
    required String termId,
    String? slug,
    String? name,
  }) {
    throw UnimplementedError();
  }
}
