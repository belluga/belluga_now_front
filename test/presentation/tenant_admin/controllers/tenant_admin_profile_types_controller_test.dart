import 'package:belluga_now/domain/repositories/tenant_admin_account_profiles_repository_contract.dart';
import 'package:belluga_now/domain/repositories/tenant_admin_taxonomies_repository_contract.dart';
import 'package:belluga_now/domain/services/tenant_admin_tenant_scope_contract.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_location.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_media_upload.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_paged_result.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_profile_type.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_account_profile.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_definition.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_term.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_term_definition.dart';
import 'package:belluga_now/presentation/tenant_admin/profile_types/controllers/tenant_admin_profile_types_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stream_value/core/stream_value.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_terms.dart';

class _FakeAccountProfilesRepository
    with TenantAdminProfileTypesPaginationMixin
    implements TenantAdminAccountProfilesRepositoryContract {
  _FakeAccountProfilesRepository(this._types);

  List<TenantAdminProfileTypeDefinition> _types;
  int deleteCalls = 0;
  int projectionImpactCount = 0;
  String? lastProjectionImpactType;

  @override
  Future<List<TenantAdminProfileTypeDefinition>> fetchProfileTypes() async =>
      _types;

  @override
  Future<TenantAdminPagedResult<TenantAdminProfileTypeDefinition>>
      fetchProfileTypesPage({
    required TenantAdminAccountProfilesRepoInt page,
    required TenantAdminAccountProfilesRepoInt pageSize,
  }) async {
    final types = await fetchProfileTypes();
    final start = (page.value - 1) * pageSize.value;
    if (page.value <= 0 || pageSize.value <= 0 || start >= types.length) {
      return tenantAdminPagedResultFromRaw(
        items: <TenantAdminProfileTypeDefinition>[],
        hasMore: false,
      );
    }
    final end = start + pageSize.value < types.length
        ? start + pageSize.value
        : types.length;
    return tenantAdminPagedResultFromRaw(
      items: types.sublist(start, end),
      hasMore: end < types.length,
    );
  }

  @override
  Future<TenantAdminProfileTypeDefinition> createProfileType({
    required TenantAdminAccountProfilesRepoString type,
    required TenantAdminAccountProfilesRepoString label,
    List<TenantAdminAccountProfilesRepoString> allowedTaxonomies = const [],
    required TenantAdminProfileTypeCapabilities capabilities,
  }) async {
    final created = tenantAdminProfileTypeDefinitionFromRaw(
      type: type.value,
      label: label.value,
      allowedTaxonomies:
          allowedTaxonomies.map((entry) => entry.value).toList(growable: false),
      capabilities: capabilities,
    );
    _types = [..._types, created];
    return created;
  }

  @override
  Future<TenantAdminProfileTypeDefinition> updateProfileType({
    required TenantAdminAccountProfilesRepoString type,
    TenantAdminAccountProfilesRepoString? newType,
    TenantAdminAccountProfilesRepoString? label,
    List<TenantAdminAccountProfilesRepoString>? allowedTaxonomies,
    TenantAdminProfileTypeCapabilities? capabilities,
  }) async {
    final updated = tenantAdminProfileTypeDefinitionFromRaw(
      type: newType?.value ?? type.value,
      label: label?.value ?? 'Updated',
      allowedTaxonomies: allowedTaxonomies
              ?.map((entry) => entry.value)
              .toList(growable: false) ??
          <String>[],
      capabilities: capabilities ??
          TenantAdminProfileTypeCapabilities(
            isFavoritable: TenantAdminFlagValue(true),
            isPoiEnabled: TenantAdminFlagValue(false),
            hasBio: TenantAdminFlagValue(false),
            hasContent: TenantAdminFlagValue(false),
            hasTaxonomies: TenantAdminFlagValue(false),
            hasAvatar: TenantAdminFlagValue(false),
            hasCover: TenantAdminFlagValue(false),
            hasEvents: TenantAdminFlagValue(false),
          ),
    );
    _types = _types.map((entry) {
      if (entry.type == type.value) {
        return updated;
      }
      return entry;
    }).toList(growable: false);
    return updated;
  }

  @override
  Future<void> deleteProfileType(
      TenantAdminAccountProfilesRepoString type) async {
    deleteCalls += 1;
    _types = _types.where((entry) => entry.type != type.value).toList();
  }

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
      accountId: 'acc-1',
      profileType: 'venue',
      displayName: 'Perfil',
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
    return tenantAdminAccountProfileFromRaw(
      id: 'profile-1',
      accountId: 'acc-1',
      profileType: 'venue',
      displayName: 'Perfil',
    );
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
    return tenantAdminAccountProfileFromRaw(
      id: 'profile-1',
      accountId: 'acc-1',
      profileType: 'venue',
      displayName: 'Perfil',
    );
  }

  @override
  Future<void> deleteAccountProfile(
      TenantAdminAccountProfilesRepoString accountProfileId) async {}

  @override
  Future<TenantAdminAccountProfile> restoreAccountProfile(
    TenantAdminAccountProfilesRepoString accountProfileId,
  ) async {
    return tenantAdminAccountProfileFromRaw(
      id: 'profile-1',
      accountId: 'acc-1',
      profileType: 'venue',
      displayName: 'Perfil',
    );
  }

  @override
  Future<void> forceDeleteAccountProfile(
      TenantAdminAccountProfilesRepoString accountProfileId) async {}

  @override
  Future<TenantAdminAccountProfilesRepoInt>
      fetchProfileTypeMapPoiProjectionImpact({
    required TenantAdminAccountProfilesRepoString type,
  }) async {
    lastProjectionImpactType = type.value;
    return tenantAdminAccountProfilesRepoInt(
      projectionImpactCount,
      defaultValue: 0,
    );
  }
}

class _FakeTaxonomiesRepository
    with TenantAdminTaxonomiesPaginationMixin
    implements TenantAdminTaxonomiesRepositoryContract {
  _FakeTaxonomiesRepository(this.taxonomies);

  List<TenantAdminTaxonomyDefinition> taxonomies;

  @override
  Future<List<TenantAdminTaxonomyDefinition>> fetchTaxonomies() async =>
      taxonomies;

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
  Future<void> deleteTaxonomy(TenantAdminTaxRepoString taxonomyId) {
    throw UnimplementedError();
  }

  @override
  Future<TenantAdminPagedResult<TenantAdminTaxonomyDefinition>>
      fetchTaxonomiesPage({
    required TenantAdminTaxRepoInt page,
    required TenantAdminTaxRepoInt pageSize,
  }) async {
    final start = (page.value - 1) * pageSize.value;
    if (page.value <= 0 || pageSize.value <= 0 || start >= taxonomies.length) {
      return tenantAdminPagedResultFromRaw(
        items: <TenantAdminTaxonomyDefinition>[],
        hasMore: false,
      );
    }
    final end = (start + pageSize.value) < taxonomies.length
        ? (start + pageSize.value)
        : taxonomies.length;
    return tenantAdminPagedResultFromRaw(
      items: taxonomies.sublist(start, end),
      hasMore: end < taxonomies.length,
    );
  }

  @override
  Future<List<TenantAdminTaxonomyTermDefinition>> fetchTerms({
    required TenantAdminTaxRepoString taxonomyId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<TenantAdminPagedResult<TenantAdminTaxonomyTermDefinition>>
      fetchTermsPage({
    required TenantAdminTaxRepoString taxonomyId,
    required TenantAdminTaxRepoInt page,
    required TenantAdminTaxRepoInt pageSize,
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
  Future<TenantAdminTaxonomyTermDefinition> updateTerm({
    required TenantAdminTaxRepoString taxonomyId,
    required TenantAdminTaxRepoString termId,
    TenantAdminTaxRepoString? slug,
    TenantAdminTaxRepoString? name,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteTerm({
    required TenantAdminTaxRepoString taxonomyId,
    required TenantAdminTaxRepoString termId,
  }) {
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
  }) {
    throw UnimplementedError();
  }
}

void main() {
  test('appends profile type pages and stops when hasMore is false', () async {
    final types = List<TenantAdminProfileTypeDefinition>.generate(
      25,
      (index) => tenantAdminProfileTypeDefinitionFromRaw(
        type: 'type-$index',
        label: 'Type $index',
        allowedTaxonomies: [],
        capabilities: TenantAdminProfileTypeCapabilities(
          isFavoritable: TenantAdminFlagValue(false),
          isPoiEnabled: TenantAdminFlagValue(false),
          hasBio: TenantAdminFlagValue(false),
          hasContent: TenantAdminFlagValue(false),
          hasTaxonomies: TenantAdminFlagValue(false),
          hasAvatar: TenantAdminFlagValue(false),
          hasCover: TenantAdminFlagValue(false),
          hasEvents: TenantAdminFlagValue(false),
        ),
      ),
    );
    final repository = _FakeAccountProfilesRepository(types);
    final controller =
        TenantAdminProfileTypesController(repository: repository);

    await controller.loadTypes();
    expect(controller.typesStreamValue.value?.length, 20);
    expect(controller.hasMoreTypesStreamValue.value, isTrue);

    await controller.loadNextTypesPage();
    expect(controller.typesStreamValue.value?.length, 25);
    await Future<void>.delayed(const Duration(milliseconds: 1));
    expect(controller.hasMoreTypesStreamValue.value, isFalse);

    await controller.loadNextTypesPage();
    expect(controller.typesStreamValue.value?.length, 25);
  });

  test('createType reloads registry list', () async {
    final repository = _FakeAccountProfilesRepository([]);
    final controller =
        TenantAdminProfileTypesController(repository: repository);

    await controller.createType(
      type: 'venue',
      label: 'Venue',
      allowedTaxonomies: [],
      capabilities: TenantAdminProfileTypeCapabilities(
        isFavoritable: TenantAdminFlagValue(true),
        isPoiEnabled: TenantAdminFlagValue(true),
        hasBio: TenantAdminFlagValue(false),
        hasContent: TenantAdminFlagValue(false),
        hasTaxonomies: TenantAdminFlagValue(false),
        hasAvatar: TenantAdminFlagValue(false),
        hasCover: TenantAdminFlagValue(false),
        hasEvents: TenantAdminFlagValue(false),
      ),
    );

    expect(controller.typesStreamValue.value?.length, 1);
  });

  test('deleteType removes entry', () async {
    final repository = _FakeAccountProfilesRepository([
      tenantAdminProfileTypeDefinitionFromRaw(
        type: 'venue',
        label: 'Venue',
        allowedTaxonomies: [],
        capabilities: TenantAdminProfileTypeCapabilities(
          isFavoritable: TenantAdminFlagValue(true),
          isPoiEnabled: TenantAdminFlagValue(true),
          hasBio: TenantAdminFlagValue(false),
          hasContent: TenantAdminFlagValue(false),
          hasTaxonomies: TenantAdminFlagValue(false),
          hasAvatar: TenantAdminFlagValue(false),
          hasCover: TenantAdminFlagValue(false),
          hasEvents: TenantAdminFlagValue(false),
        ),
      ),
    ]);
    final controller =
        TenantAdminProfileTypesController(repository: repository);

    await controller.loadTypes();
    expect(controller.typesStreamValue.value?.length, 1);

    await controller.deleteType('venue');

    expect(repository.deleteCalls, 1);
    expect(controller.typesStreamValue.value?.length, 0);
  });

  test('reloads registry when tenant scope changes', () async {
    final repository = _FakeAccountProfilesRepository([
      tenantAdminProfileTypeDefinitionFromRaw(
        type: 'artist',
        label: 'Artist',
        allowedTaxonomies: [],
        capabilities: TenantAdminProfileTypeCapabilities(
          isFavoritable: TenantAdminFlagValue(true),
          isPoiEnabled: TenantAdminFlagValue(false),
          hasBio: TenantAdminFlagValue(true),
          hasContent: TenantAdminFlagValue(false),
          hasTaxonomies: TenantAdminFlagValue(false),
          hasAvatar: TenantAdminFlagValue(true),
          hasCover: TenantAdminFlagValue(true),
          hasEvents: TenantAdminFlagValue(true),
        ),
      ),
    ]);
    final tenantScope = _FakeTenantScope('tenant-a.test');
    final controller = TenantAdminProfileTypesController(
      repository: repository,
      tenantScope: tenantScope,
    );

    await controller.loadTypes();
    expect(controller.typesStreamValue.value?.first.type, 'artist');

    repository._types = [
      tenantAdminProfileTypeDefinitionFromRaw(
        type: 'venue',
        label: 'Venue',
        allowedTaxonomies: [],
        capabilities: TenantAdminProfileTypeCapabilities(
          isFavoritable: TenantAdminFlagValue(true),
          isPoiEnabled: TenantAdminFlagValue(true),
          hasBio: TenantAdminFlagValue(false),
          hasContent: TenantAdminFlagValue(false),
          hasTaxonomies: TenantAdminFlagValue(false),
          hasAvatar: TenantAdminFlagValue(false),
          hasCover: TenantAdminFlagValue(false),
          hasEvents: TenantAdminFlagValue(false),
        ),
      ),
    ];
    tenantScope.selectTenantDomain('tenant-b.test');
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    expect(controller.typesStreamValue.value?.first.type, 'venue');
  });

  test('loads available taxonomies filtered by account_profile target',
      () async {
    final repository = _FakeAccountProfilesRepository([]);
    final taxonomiesRepository = _FakeTaxonomiesRepository([
      tenantAdminTaxonomyDefinitionFromRaw(
        id: '1',
        slug: 'music_genre',
        name: 'Music Genre',
        appliesTo: ['account_profile'],
        icon: null,
        color: null,
      ),
      tenantAdminTaxonomyDefinitionFromRaw(
        id: '2',
        slug: 'event_type',
        name: 'Event Type',
        appliesTo: ['event'],
        icon: null,
        color: null,
      ),
    ]);
    final controller = TenantAdminProfileTypesController(
      repository: repository,
      taxonomiesRepository: taxonomiesRepository,
    );

    await controller.loadAvailableTaxonomies();

    expect(controller.availableTaxonomiesStreamValue.value.length, 1);
    expect(
      controller.availableTaxonomiesStreamValue.value.first.slug,
      'music_genre',
    );
  });

  test('ignores non-listed taxonomy slug when toggling selection', () async {
    final repository = _FakeAccountProfilesRepository([]);
    final taxonomiesRepository = _FakeTaxonomiesRepository([
      tenantAdminTaxonomyDefinitionFromRaw(
        id: '1',
        slug: 'music_genre',
        name: 'Music Genre',
        appliesTo: ['account_profile'],
        icon: null,
        color: null,
      ),
    ]);
    final controller = TenantAdminProfileTypesController(
      repository: repository,
      taxonomiesRepository: taxonomiesRepository,
    );

    await controller.loadAvailableTaxonomies();
    controller.toggleAllowedTaxonomy('invalid_slug');
    controller.toggleAllowedTaxonomy('music_genre');

    expect(controller.selectedAllowedTaxonomies, ['music_genre']);
  });

  test('submitUpdateType keeps detail stream aligned with saved values',
      () async {
    final repository = _FakeAccountProfilesRepository([
      tenantAdminProfileTypeDefinitionFromRaw(
        type: 'artist',
        label: 'Artist',
        allowedTaxonomies: [],
        capabilities: TenantAdminProfileTypeCapabilities(
          isFavoritable: TenantAdminFlagValue(false),
          isPoiEnabled: TenantAdminFlagValue(false),
          hasBio: TenantAdminFlagValue(false),
          hasContent: TenantAdminFlagValue(false),
          hasTaxonomies: TenantAdminFlagValue(false),
          hasAvatar: TenantAdminFlagValue(false),
          hasCover: TenantAdminFlagValue(false),
          hasEvents: TenantAdminFlagValue(false),
        ),
      ),
    ]);
    final controller =
        TenantAdminProfileTypesController(repository: repository);

    controller.initDetailType(tenantAdminProfileTypeDefinitionFromRaw(
      type: 'artist',
      label: 'Artist',
      allowedTaxonomies: [],
      capabilities: TenantAdminProfileTypeCapabilities(
        isFavoritable: TenantAdminFlagValue(false),
        isPoiEnabled: TenantAdminFlagValue(false),
        hasBio: TenantAdminFlagValue(false),
        hasContent: TenantAdminFlagValue(false),
        hasTaxonomies: TenantAdminFlagValue(false),
        hasAvatar: TenantAdminFlagValue(false),
        hasCover: TenantAdminFlagValue(false),
        hasEvents: TenantAdminFlagValue(false),
      ),
    ));

    await controller.submitUpdateType(
      type: 'artist',
      newType: 'artist-pro',
      label: 'Artist Pro',
    );

    final detail = controller.detailTypeStreamValue.value;
    expect(detail, isNotNull);
    expect(detail!.type, 'artist-pro');
    expect(detail.label, 'Artist Pro');
  });

  test('previewDisableProjectionCount delegates to repository', () async {
    final repository = _FakeAccountProfilesRepository([]);
    repository.projectionImpactCount = 67;
    final controller =
        TenantAdminProfileTypesController(repository: repository);

    final count = await controller.previewDisableProjectionCount('venue');

    expect(count, 67);
    expect(repository.lastProjectionImpactType, 'venue');
  });
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
