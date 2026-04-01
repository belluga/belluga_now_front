import 'package:belluga_now/domain/repositories/tenant_admin_static_assets_repository_contract.dart';
import 'package:belluga_now/domain/repositories/tenant_admin_taxonomies_repository_contract.dart';
import 'package:belluga_now/domain/services/tenant_admin_tenant_scope_contract.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_location.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_media_upload.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_paged_result.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_static_asset.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_static_profile_type.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_definition.dart';
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
        (index) => tenantAdminStaticProfileTypeDefinitionFromRaw(
          type: 'type-$index',
          label: 'Type $index',
          allowedTaxonomies: [],
          capabilities: TenantAdminStaticProfileTypeCapabilities(
            isPoiEnabled: TenantAdminFlagValue(false),
            hasBio: TenantAdminFlagValue(false),
            hasTaxonomies: TenantAdminFlagValue(false),
            hasAvatar: TenantAdminFlagValue(false),
            hasCover: TenantAdminFlagValue(false),
            hasContent: TenantAdminFlagValue(false),
          ),
        ),
      ),
    );
    final controller = TenantAdminStaticProfileTypesController(
      repository: assetsRepository,
      taxonomiesRepository: _FakeTaxonomiesRepository(taxonomies: []),
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
      types: [
        tenantAdminStaticProfileTypeDefinitionFromRaw(
          type: 'type-a',
          label: 'Type A',
          allowedTaxonomies: [],
          capabilities: TenantAdminStaticProfileTypeCapabilities(
            isPoiEnabled: TenantAdminFlagValue(false),
            hasBio: TenantAdminFlagValue(false),
            hasTaxonomies: TenantAdminFlagValue(false),
            hasAvatar: TenantAdminFlagValue(false),
            hasCover: TenantAdminFlagValue(false),
            hasContent: TenantAdminFlagValue(false),
          ),
        ),
      ],
    );
    final taxonomiesRepository = _FakeTaxonomiesRepository(
      taxonomies: [
        tenantAdminTaxonomyDefinitionFromRaw(
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

    assetsRepository.types = [
      tenantAdminStaticProfileTypeDefinitionFromRaw(
        type: 'type-b',
        label: 'Type B',
        allowedTaxonomies: [],
        capabilities: TenantAdminStaticProfileTypeCapabilities(
          isPoiEnabled: TenantAdminFlagValue(true),
          hasBio: TenantAdminFlagValue(true),
          hasTaxonomies: TenantAdminFlagValue(true),
          hasAvatar: TenantAdminFlagValue(true),
          hasCover: TenantAdminFlagValue(true),
          hasContent: TenantAdminFlagValue(true),
        ),
      ),
    ];
    taxonomiesRepository.taxonomies = [
      tenantAdminTaxonomyDefinitionFromRaw(
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

  test('submitUpdateType keeps detail stream aligned with saved values',
      () async {
    final assetsRepository = _FakeStaticAssetsRepository(
      types: [
        tenantAdminStaticProfileTypeDefinitionFromRaw(
          type: 'place',
          label: 'Place',
          allowedTaxonomies: [],
          capabilities: TenantAdminStaticProfileTypeCapabilities(
            isPoiEnabled: TenantAdminFlagValue(false),
            hasBio: TenantAdminFlagValue(false),
            hasTaxonomies: TenantAdminFlagValue(false),
            hasAvatar: TenantAdminFlagValue(false),
            hasCover: TenantAdminFlagValue(false),
            hasContent: TenantAdminFlagValue(false),
          ),
        ),
      ],
    );
    final controller = TenantAdminStaticProfileTypesController(
      repository: assetsRepository,
      taxonomiesRepository: _FakeTaxonomiesRepository(taxonomies: []),
    );

    controller.initDetailType(
      tenantAdminStaticProfileTypeDefinitionFromRaw(
        type: 'place',
        label: 'Place',
        allowedTaxonomies: [],
        capabilities: TenantAdminStaticProfileTypeCapabilities(
          isPoiEnabled: TenantAdminFlagValue(false),
          hasBio: TenantAdminFlagValue(false),
          hasTaxonomies: TenantAdminFlagValue(false),
          hasAvatar: TenantAdminFlagValue(false),
          hasCover: TenantAdminFlagValue(false),
          hasContent: TenantAdminFlagValue(false),
        ),
      ),
    );

    await controller.submitUpdateType(
      type: 'place',
      newType: 'venue',
      label: 'Venue',
    );

    final detail = controller.detailTypeStreamValue.value;
    expect(detail, isNotNull);
    expect(detail!.type, 'venue');
    expect(detail.label, 'Venue');
  });

  test('previewDisableProjectionCount delegates to repository', () async {
    final assetsRepository = _FakeStaticAssetsRepository(types: []);
    assetsRepository.projectionImpactCount = 42;
    final controller = TenantAdminStaticProfileTypesController(
      repository: assetsRepository,
      taxonomiesRepository: _FakeTaxonomiesRepository(taxonomies: []),
    );

    final count = await controller.previewDisableProjectionCount('beach');

    expect(count, 42);
    expect(assetsRepository.lastProjectionImpactType, 'beach');
  });
}

class _FakeStaticAssetsRepository
    with TenantAdminStaticAssetsPaginationMixin
    implements TenantAdminStaticAssetsRepositoryContract {
  _FakeStaticAssetsRepository({
    required this.types,
  });

  List<TenantAdminStaticProfileTypeDefinition> types;
  int projectionImpactCount = 0;
  String? lastProjectionImpactType;

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
  }) {
    throw UnimplementedError();
  }

  @override
  Future<TenantAdminStaticProfileTypeDefinition> createStaticProfileType({
    required TenantAdminStaticAssetsRepoString type,
    required TenantAdminStaticAssetsRepoString label,
    List<TenantAdminStaticAssetsRepoString>? allowedTaxonomies,
    required TenantAdminStaticProfileTypeCapabilities capabilities,
  }) {
    final created = tenantAdminStaticProfileTypeDefinitionFromRaw(
      type: type.value,
      label: label.value,
      allowedTaxonomies: allowedTaxonomies
              ?.map((entry) => entry.value)
              .toList(growable: false) ??
          const [],
      capabilities: capabilities,
    );
    types = [...types, created];
    return Future.value(created);
  }

  @override
  Future<void> deleteStaticAsset(
      TenantAdminStaticAssetsRepoString assetId) async {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteStaticProfileType(
      TenantAdminStaticAssetsRepoString type) async {
    types = types
        .where((entry) => entry.type != type.value)
        .toList(growable: false);
  }

  @override
  Future<List<TenantAdminStaticAsset>> fetchStaticAssets() async => [];

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
  Future<TenantAdminStaticAsset> fetchStaticAsset(
    TenantAdminStaticAssetsRepoString assetId,
  ) async {
    throw UnimplementedError();
  }

  @override
  Future<List<TenantAdminStaticProfileTypeDefinition>>
      fetchStaticProfileTypes() async => types;

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
  }) {
    throw UnimplementedError();
  }

  @override
  Future<TenantAdminStaticProfileTypeDefinition> updateStaticProfileType({
    required TenantAdminStaticAssetsRepoString type,
    TenantAdminStaticAssetsRepoString? newType,
    TenantAdminStaticAssetsRepoString? label,
    List<TenantAdminStaticAssetsRepoString>? allowedTaxonomies,
    TenantAdminStaticProfileTypeCapabilities? capabilities,
  }) {
    final current = types.firstWhere(
      (entry) => entry.type == type.value,
      orElse: () => tenantAdminStaticProfileTypeDefinitionFromRaw(
        type: type.value,
        label: type.value,
        allowedTaxonomies: [],
        capabilities: TenantAdminStaticProfileTypeCapabilities(
          isPoiEnabled: TenantAdminFlagValue(false),
          hasBio: TenantAdminFlagValue(false),
          hasTaxonomies: TenantAdminFlagValue(false),
          hasAvatar: TenantAdminFlagValue(false),
          hasCover: TenantAdminFlagValue(false),
          hasContent: TenantAdminFlagValue(false),
        ),
      ),
    );
    final updated = tenantAdminStaticProfileTypeDefinitionFromRaw(
      type: newType?.value ?? current.type,
      label: label?.value ?? current.label,
      allowedTaxonomies: allowedTaxonomies
              ?.map((entry) => entry.value)
              .toList(growable: false) ??
          current.allowedTaxonomies,
      capabilities: capabilities ?? current.capabilities,
    );
    types = types.map((entry) {
      if (entry.type == type.value) {
        return updated;
      }
      return entry;
    }).toList(growable: false);
    return Future.value(updated);
  }

  @override
  Future<TenantAdminStaticAssetsRepoInt>
      fetchStaticProfileTypeMapPoiProjectionImpact({
    required TenantAdminStaticAssetsRepoString type,
  }) async {
    lastProjectionImpactType = type.value;
    return TenantAdminStaticAssetsRepoInt.fromRaw(projectionImpactCount);
  }
}

class _FakeTaxonomiesRepository
    with TenantAdminTaxonomiesPaginationMixin
    implements TenantAdminTaxonomiesRepositoryContract {
  _FakeTaxonomiesRepository({
    required this.taxonomies,
  });

  List<TenantAdminTaxonomyDefinition> taxonomies;

  @override
  Future<TenantAdminTaxonomyDefinition> createTaxonomy({
    required TenantAdminTaxRepoString slug,
    required TenantAdminTaxRepoString name,
    required List<TenantAdminTaxRepoString> appliesTo,
    TenantAdminTaxRepoString? icon,
    TenantAdminTaxRepoString? color,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<TenantAdminTaxonomyTermDefinition> createTerm({
    required TenantAdminTaxRepoString taxonomyId,
    required TenantAdminTaxRepoString slug,
    required TenantAdminTaxRepoString name,
  }) {
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
  Future<List<TenantAdminTaxonomyDefinition>> fetchTaxonomies() async =>
      taxonomies;

  @override
  Future<TenantAdminPagedResult<TenantAdminTaxonomyDefinition>>
      fetchTaxonomiesPage({
    required TenantAdminTaxRepoInt page,
    required TenantAdminTaxRepoInt pageSize,
  }) async {
    final entries = await fetchTaxonomies();
    final start = (page.value - 1) * pageSize.value;
    if (page.value <= 0 || pageSize.value <= 0 || start >= entries.length) {
      return tenantAdminPagedResultFromRaw(
        items: <TenantAdminTaxonomyDefinition>[],
        hasMore: false,
      );
    }
    final end = start + pageSize.value < entries.length
        ? start + pageSize.value
        : entries.length;
    return tenantAdminPagedResultFromRaw(
      items: entries.sublist(start, end),
      hasMore: end < entries.length,
    );
  }

  @override
  Future<List<TenantAdminTaxonomyTermDefinition>> fetchTerms({
    required TenantAdminTaxRepoString taxonomyId,
  }) async =>
      [];

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
  }) {
    throw UnimplementedError();
  }

  @override
  Future<TenantAdminTaxonomyTermDefinition> updateTerm({
    required TenantAdminTaxRepoString taxonomyId,
    required TenantAdminTaxRepoString termId,
    TenantAdminTaxRepoString? slug,
    TenantAdminTaxRepoString? name,
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
  void selectTenantDomain(Object tenantDomain) {
    _selectedTenantDomainStreamValue.addValue((tenantDomain is String
            ? tenantDomain
            : (tenantDomain as dynamic).value as String)
        .trim());
  }
}
