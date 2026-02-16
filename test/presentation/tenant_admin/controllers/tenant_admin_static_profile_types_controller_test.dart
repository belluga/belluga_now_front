import 'package:belluga_now/domain/repositories/tenant_admin_static_assets_repository_contract.dart';
import 'package:belluga_now/domain/repositories/tenant_admin_taxonomies_repository_contract.dart';
import 'package:belluga_now/domain/services/tenant_admin_tenant_scope_contract.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_location.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_media_upload.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_paged_result.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_static_asset.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_static_profile_type.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_definition.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_term.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_term_definition.dart';
import 'package:belluga_now/presentation/tenant_admin/static_profile_types/controllers/tenant_admin_static_profile_types_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stream_value/core/stream_value.dart';

void main() {
  test('appends static profile type pages and stops when hasMore is false',
      () async {
    final assetsRepository = _FakeStaticAssetsRepository(
      types: List<TenantAdminStaticProfileTypeDefinition>.generate(
        24,
        (index) => TenantAdminStaticProfileTypeDefinition(
          type: 'type-$index',
          label: 'Type $index',
          allowedTaxonomies: const [],
          capabilities: const TenantAdminStaticProfileTypeCapabilities(
            isPoiEnabled: false,
            hasBio: false,
            hasTaxonomies: false,
            hasAvatar: false,
            hasCover: false,
            hasContent: false,
          ),
        ),
      ),
    );
    final controller = TenantAdminStaticProfileTypesController(
      repository: assetsRepository,
      taxonomiesRepository: _FakeTaxonomiesRepository(taxonomies: const []),
    );

    await controller.loadTypes();
    expect(controller.typesStreamValue.value?.length, 20);
    expect(controller.hasMoreTypesStreamValue.value, isTrue);

    await controller.loadNextTypesPage();
    expect(controller.typesStreamValue.value?.length, 24);
    expect(controller.hasMoreTypesStreamValue.value, isFalse);

    await controller.loadNextTypesPage();
    expect(controller.typesStreamValue.value?.length, 24);
  });

  test('reloads static profile types and taxonomies when tenant changes',
      () async {
    final assetsRepository = _FakeStaticAssetsRepository(
      types: const [
        TenantAdminStaticProfileTypeDefinition(
          type: 'type-a',
          label: 'Type A',
          allowedTaxonomies: [],
          capabilities: TenantAdminStaticProfileTypeCapabilities(
            isPoiEnabled: false,
            hasBio: false,
            hasTaxonomies: false,
            hasAvatar: false,
            hasCover: false,
            hasContent: false,
          ),
        ),
      ],
    );
    final taxonomiesRepository = _FakeTaxonomiesRepository(
      taxonomies: const [
        TenantAdminTaxonomyDefinition(
          id: 'tax-a',
          slug: 'slug-a',
          name: 'Tax A',
          appliesTo: ['static_asset'],
          icon: null,
          color: null,
        ),
      ],
    );
    final tenantScope = _FakeTenantScope('tenant-a.test');
    final controller = TenantAdminStaticProfileTypesController(
      repository: assetsRepository,
      taxonomiesRepository: taxonomiesRepository,
      tenantScope: tenantScope,
    );

    await controller.loadTypes();
    await controller.loadTaxonomies();
    expect(controller.typesStreamValue.value?.first.type, 'type-a');
    expect(controller.taxonomiesStreamValue.value.first.slug, 'slug-a');

    assetsRepository.types = const [
      TenantAdminStaticProfileTypeDefinition(
        type: 'type-b',
        label: 'Type B',
        allowedTaxonomies: [],
        capabilities: TenantAdminStaticProfileTypeCapabilities(
          isPoiEnabled: true,
          hasBio: true,
          hasTaxonomies: true,
          hasAvatar: true,
          hasCover: true,
          hasContent: true,
        ),
      ),
    ];
    taxonomiesRepository.taxonomies = const [
      TenantAdminTaxonomyDefinition(
        id: 'tax-b',
        slug: 'slug-b',
        name: 'Tax B',
        appliesTo: ['static_asset'],
        icon: null,
        color: null,
      ),
    ];
    tenantScope.selectTenantDomain('tenant-b.test');
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    expect(controller.typesStreamValue.value?.first.type, 'type-b');
    expect(controller.taxonomiesStreamValue.value.first.slug, 'slug-b');
  });
}

class _FakeStaticAssetsRepository
    implements TenantAdminStaticAssetsRepositoryContract {
  _FakeStaticAssetsRepository({
    required this.types,
  });

  List<TenantAdminStaticProfileTypeDefinition> types;

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
  Future<List<TenantAdminStaticAsset>> fetchStaticAssets() async => const [];

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
  Future<TenantAdminStaticAsset> fetchStaticAsset(String assetId) async {
    throw UnimplementedError();
  }

  @override
  Future<List<TenantAdminStaticProfileTypeDefinition>>
      fetchStaticProfileTypes() async => types;

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
    String? label,
    List<String>? allowedTaxonomies,
    TenantAdminStaticProfileTypeCapabilities? capabilities,
  }) {
    throw UnimplementedError();
  }
}

class _FakeTaxonomiesRepository
    implements TenantAdminTaxonomiesRepositoryContract {
  _FakeTaxonomiesRepository({
    required this.taxonomies,
  });

  List<TenantAdminTaxonomyDefinition> taxonomies;

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
  Future<List<TenantAdminTaxonomyDefinition>> fetchTaxonomies() async =>
      taxonomies;

  @override
  Future<TenantAdminPagedResult<TenantAdminTaxonomyDefinition>>
      fetchTaxonomiesPage({
    required int page,
    required int pageSize,
  }) async {
    final entries = await fetchTaxonomies();
    final start = (page - 1) * pageSize;
    if (page <= 0 || pageSize <= 0 || start >= entries.length) {
      return const TenantAdminPagedResult<TenantAdminTaxonomyDefinition>(
        items: <TenantAdminTaxonomyDefinition>[],
        hasMore: false,
      );
    }
    final end =
        start + pageSize < entries.length ? start + pageSize : entries.length;
    return TenantAdminPagedResult<TenantAdminTaxonomyDefinition>(
      items: entries.sublist(start, end),
      hasMore: end < entries.length,
    );
  }

  @override
  Future<List<TenantAdminTaxonomyTermDefinition>> fetchTerms({
    required String taxonomyId,
  }) async =>
      const [];

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

class _FakeTenantScope implements TenantAdminTenantScopeContract {
  _FakeTenantScope(String initialDomain)
      : _selectedTenantDomainStreamValue =
            StreamValue<String?>(defaultValue: initialDomain);

  final StreamValue<String?> _selectedTenantDomainStreamValue;

  @override
  String? get selectedTenantDomain => _selectedTenantDomainStreamValue.value;

  @override
  String get selectedTenantAdminBaseUrl =>
      'https://${selectedTenantDomain ?? ''}/admin/api';

  @override
  StreamValue<String?> get selectedTenantDomainStreamValue =>
      _selectedTenantDomainStreamValue;

  @override
  void clearSelectedTenantDomain() {
    _selectedTenantDomainStreamValue.addValue(null);
  }

  @override
  void selectTenantDomain(String tenantDomain) {
    _selectedTenantDomainStreamValue.addValue(tenantDomain.trim());
  }
}
