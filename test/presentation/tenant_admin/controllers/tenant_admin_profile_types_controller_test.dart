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

class _FakeAccountProfilesRepository
    with TenantAdminProfileTypesPaginationMixin
    implements TenantAdminAccountProfilesRepositoryContract {
  _FakeAccountProfilesRepository(this._types);

  List<TenantAdminProfileTypeDefinition> _types;
  int deleteCalls = 0;

  @override
  Future<List<TenantAdminProfileTypeDefinition>> fetchProfileTypes() async =>
      _types;

  @override
  Future<TenantAdminPagedResult<TenantAdminProfileTypeDefinition>>
      fetchProfileTypesPage({
    required int page,
    required int pageSize,
  }) async {
    final types = await fetchProfileTypes();
    final start = (page - 1) * pageSize;
    if (page <= 0 || pageSize <= 0 || start >= types.length) {
      return const TenantAdminPagedResult<TenantAdminProfileTypeDefinition>(
        items: <TenantAdminProfileTypeDefinition>[],
        hasMore: false,
      );
    }
    final end =
        start + pageSize < types.length ? start + pageSize : types.length;
    return TenantAdminPagedResult<TenantAdminProfileTypeDefinition>(
      items: types.sublist(start, end),
      hasMore: end < types.length,
    );
  }

  @override
  Future<TenantAdminProfileTypeDefinition> createProfileType({
    required String type,
    required String label,
    List<String> allowedTaxonomies = const [],
    required TenantAdminProfileTypeCapabilities capabilities,
  }) async {
    final created = TenantAdminProfileTypeDefinition(
      type: type,
      label: label,
      allowedTaxonomies: allowedTaxonomies,
      capabilities: capabilities,
    );
    _types = [..._types, created];
    return created;
  }

  @override
  Future<TenantAdminProfileTypeDefinition> updateProfileType({
    required String type,
    String? newType,
    String? label,
    List<String>? allowedTaxonomies,
    TenantAdminProfileTypeCapabilities? capabilities,
  }) async {
    return TenantAdminProfileTypeDefinition(
      type: type,
      label: label ?? 'Updated',
      allowedTaxonomies: allowedTaxonomies ?? const [],
      capabilities: capabilities ??
          const TenantAdminProfileTypeCapabilities(
            isFavoritable: true,
            isPoiEnabled: false,
            hasBio: false,
            hasContent: false,
          hasTaxonomies: false,
            hasAvatar: false,
            hasCover: false,
            hasEvents: false,
          ),
    );
  }

  @override
  Future<void> deleteProfileType(String type) async {
    deleteCalls += 1;
    _types = _types.where((entry) => entry.type != type).toList();
  }

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
      accountId: 'acc-1',
      profileType: 'venue',
      displayName: 'Perfil',
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
    return const TenantAdminAccountProfile(
      id: 'profile-1',
      accountId: 'acc-1',
      profileType: 'venue',
      displayName: 'Perfil',
    );
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
    return const TenantAdminAccountProfile(
      id: 'profile-1',
      accountId: 'acc-1',
      profileType: 'venue',
      displayName: 'Perfil',
    );
  }

  @override
  Future<void> deleteAccountProfile(String accountProfileId) async {}

  @override
  Future<TenantAdminAccountProfile> restoreAccountProfile(
    String accountProfileId,
  ) async {
    return const TenantAdminAccountProfile(
      id: 'profile-1',
      accountId: 'acc-1',
      profileType: 'venue',
      displayName: 'Perfil',
    );
  }

  @override
  Future<void> forceDeleteAccountProfile(String accountProfileId) async {}
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
    required String slug,
    required String name,
    required List<String> appliesTo,
    String? icon,
    String? color,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteTaxonomy(String taxonomyId) {
    throw UnimplementedError();
  }

  @override
  Future<TenantAdminPagedResult<TenantAdminTaxonomyDefinition>>
      fetchTaxonomiesPage({
    required int page,
    required int pageSize,
  }) async {
    final start = (page - 1) * pageSize;
    if (page <= 0 || pageSize <= 0 || start >= taxonomies.length) {
      return const TenantAdminPagedResult<TenantAdminTaxonomyDefinition>(
        items: <TenantAdminTaxonomyDefinition>[],
        hasMore: false,
      );
    }
    final end = (start + pageSize) < taxonomies.length
        ? (start + pageSize)
        : taxonomies.length;
    return TenantAdminPagedResult<TenantAdminTaxonomyDefinition>(
      items: taxonomies.sublist(start, end),
      hasMore: end < taxonomies.length,
    );
  }

  @override
  Future<List<TenantAdminTaxonomyTermDefinition>> fetchTerms({
    required String taxonomyId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<TenantAdminPagedResult<TenantAdminTaxonomyTermDefinition>>
      fetchTermsPage({
    required String taxonomyId,
    required int page,
    required int pageSize,
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
  Future<TenantAdminTaxonomyTermDefinition> updateTerm({
    required String taxonomyId,
    required String termId,
    String? slug,
    String? name,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteTerm({
    required String taxonomyId,
    required String termId,
  }) {
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
  }) {
    throw UnimplementedError();
  }
}

void main() {
  test('appends profile type pages and stops when hasMore is false', () async {
    final types = List<TenantAdminProfileTypeDefinition>.generate(
      25,
      (index) => TenantAdminProfileTypeDefinition(
        type: 'type-$index',
        label: 'Type $index',
        allowedTaxonomies: const [],
        capabilities: const TenantAdminProfileTypeCapabilities(
          isFavoritable: false,
          isPoiEnabled: false,
          hasBio: false,
          hasContent: false,
          hasTaxonomies: false,
          hasAvatar: false,
          hasCover: false,
          hasEvents: false,
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
    expect(controller.hasMoreTypesStreamValue.value, isFalse);

    await controller.loadNextTypesPage();
    expect(controller.typesStreamValue.value?.length, 25);
  });

  test('createType reloads registry list', () async {
    final repository = _FakeAccountProfilesRepository(const []);
    final controller =
        TenantAdminProfileTypesController(repository: repository);

    await controller.createType(
      type: 'venue',
      label: 'Venue',
      allowedTaxonomies: const [],
      capabilities: const TenantAdminProfileTypeCapabilities(
        isFavoritable: true,
        isPoiEnabled: true,
        hasBio: false,
        hasContent: false,
          hasTaxonomies: false,
        hasAvatar: false,
        hasCover: false,
        hasEvents: false,
      ),
    );

    expect(controller.typesStreamValue.value?.length, 1);
  });

  test('deleteType removes entry', () async {
    final repository = _FakeAccountProfilesRepository(const [
      TenantAdminProfileTypeDefinition(
        type: 'venue',
        label: 'Venue',
        allowedTaxonomies: [],
        capabilities: TenantAdminProfileTypeCapabilities(
          isFavoritable: true,
          isPoiEnabled: true,
          hasBio: false,
          hasContent: false,
          hasTaxonomies: false,
          hasAvatar: false,
          hasCover: false,
          hasEvents: false,
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
    final repository = _FakeAccountProfilesRepository(const [
      TenantAdminProfileTypeDefinition(
        type: 'artist',
        label: 'Artist',
        allowedTaxonomies: [],
        capabilities: TenantAdminProfileTypeCapabilities(
          isFavoritable: true,
          isPoiEnabled: false,
          hasBio: true,
          hasContent: false,
          hasTaxonomies: false,
          hasAvatar: true,
          hasCover: true,
          hasEvents: true,
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

    repository._types = const [
      TenantAdminProfileTypeDefinition(
        type: 'venue',
        label: 'Venue',
        allowedTaxonomies: [],
        capabilities: TenantAdminProfileTypeCapabilities(
          isFavoritable: true,
          isPoiEnabled: true,
          hasBio: false,
          hasContent: false,
          hasTaxonomies: false,
          hasAvatar: false,
          hasCover: false,
          hasEvents: false,
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
    final repository = _FakeAccountProfilesRepository(const []);
    final taxonomiesRepository = _FakeTaxonomiesRepository([
      const TenantAdminTaxonomyDefinition(
        id: '1',
        slug: 'music_genre',
        name: 'Music Genre',
        appliesTo: ['account_profile'],
        icon: null,
        color: null,
      ),
      const TenantAdminTaxonomyDefinition(
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
    final repository = _FakeAccountProfilesRepository(const []);
    final taxonomiesRepository = _FakeTaxonomiesRepository([
      const TenantAdminTaxonomyDefinition(
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
