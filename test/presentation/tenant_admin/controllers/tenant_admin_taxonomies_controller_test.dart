import 'package:belluga_now/domain/repositories/tenant_admin_taxonomies_repository_contract.dart';
import 'package:belluga_now/domain/services/tenant_admin_tenant_scope_contract.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_paged_result.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_definition.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_term_definition.dart';
import 'package:belluga_now/presentation/tenant_admin/taxonomies/controllers/tenant_admin_taxonomies_controller.dart';
import 'package:belluga_now/presentation/tenant_admin/taxonomies/controllers/tenant_admin_taxonomy_terms_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stream_value/core/stream_value.dart';

void main() {
  test('taxonomies controller appends pages and respects hasMore', () async {
    final repository = _FakeTaxonomiesRepository(
      taxonomies: List<TenantAdminTaxonomyDefinition>.generate(
        23,
        (index) => tenantAdminTaxonomyDefinitionFromRaw(
          id: 'tax-$index',
          slug: 'slug-$index',
          name: 'Tax $index',
          appliesTo: ['account_profile'],
          icon: null,
          color: null,
        ),
      ),
      termsByTaxonomy: {},
    );
    final controller = TenantAdminTaxonomiesController(repository: repository);

    await controller.loadTaxonomies();
    expect(controller.taxonomiesStreamValue.value?.length, 20);
    expect(controller.hasMoreTaxonomiesStreamValue.value, isTrue);

    await controller.loadNextTaxonomiesPage();
    expect(controller.taxonomiesStreamValue.value?.length, 23);
    expect(controller.hasMoreTaxonomiesStreamValue.value, isFalse);

    await controller.loadNextTaxonomiesPage();
    expect(controller.taxonomiesStreamValue.value?.length, 23);
  });

  test('taxonomy terms controller appends pages and respects hasMore',
      () async {
    final repository = _FakeTaxonomiesRepository(
      taxonomies: [],
      termsByTaxonomy: {
        'tax-a': List<TenantAdminTaxonomyTermDefinition>.generate(
          22,
          (index) => tenantAdminTaxonomyTermDefinitionFromRaw(
            id: 'term-$index',
            taxonomyId: 'tax-a',
            slug: 'slug-$index',
            name: 'Term $index',
          ),
        ),
      },
    );
    final controller = TenantAdminTaxonomyTermsController(
      repository: repository,
    );

    await controller.loadTerms('tax-a');
    expect(controller.termsStreamValue.value?.length, 20);
    expect(controller.hasMoreTermsStreamValue.value, isTrue);

    await controller.loadNextTermsPage();
    expect(controller.termsStreamValue.value?.length, 22);
    expect(controller.hasMoreTermsStreamValue.value, isFalse);

    await controller.loadNextTermsPage();
    expect(controller.termsStreamValue.value?.length, 22);
  });

  test('taxonomies controller reloads taxonomy list on tenant switch',
      () async {
    final repository = _FakeTaxonomiesRepository(
      taxonomies: [
        tenantAdminTaxonomyDefinitionFromRaw(
          id: 'tax-a',
          slug: 'slug-a',
          name: 'Tax A',
          appliesTo: ['account_profile'],
          icon: null,
          color: null,
        ),
      ],
      termsByTaxonomy: {
        'tax-a': [
          tenantAdminTaxonomyTermDefinitionFromRaw(
            id: 'term-a',
            taxonomyId: 'tax-a',
            slug: 'term-a',
            name: 'Term A',
          ),
        ],
      },
    );
    final tenantScope = _FakeTenantScope('tenant-a.test');
    final controller = TenantAdminTaxonomiesController(
      repository: repository,
      tenantScope: tenantScope,
    );

    await controller.loadTaxonomies();
    expect(controller.taxonomiesStreamValue.value?.first.slug, 'slug-a');

    repository.taxonomies = [
      tenantAdminTaxonomyDefinitionFromRaw(
        id: 'tax-b',
        slug: 'slug-b',
        name: 'Tax B',
        appliesTo: ['account_profile'],
        icon: null,
        color: null,
      ),
    ];
    tenantScope.selectTenantDomain('tenant-b.test');
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    expect(controller.taxonomiesStreamValue.value?.first.slug, 'slug-b');
  });

  test('taxonomy terms controller reloads terms on tenant switch', () async {
    final repository = _FakeTaxonomiesRepository(
      taxonomies: [],
      termsByTaxonomy: {
        'tax-a': [
          tenantAdminTaxonomyTermDefinitionFromRaw(
            id: 'term-a',
            taxonomyId: 'tax-a',
            slug: 'term-a',
            name: 'Term A',
          ),
        ],
      },
    );
    final tenantScope = _FakeTenantScope('tenant-a.test');
    final controller = TenantAdminTaxonomyTermsController(
      repository: repository,
      tenantScope: tenantScope,
    );

    await controller.loadTerms('tax-a');
    expect(controller.termsStreamValue.value?.first.slug, 'term-a');

    repository.termsByTaxonomy = {
      'tax-a': [
        tenantAdminTaxonomyTermDefinitionFromRaw(
          id: 'term-b',
          taxonomyId: 'tax-a',
          slug: 'term-b',
          name: 'Term B',
        ),
      ],
    };
    tenantScope.selectTenantDomain('tenant-b.test');
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    expect(controller.termsStreamValue.value?.first.slug, 'term-b');
  });
}

class _FakeTaxonomiesRepository
    with TenantAdminTaxonomiesPaginationMixin
    implements TenantAdminTaxonomiesRepositoryContract {
  _FakeTaxonomiesRepository({
    required this.taxonomies,
    required this.termsByTaxonomy,
  });

  List<TenantAdminTaxonomyDefinition> taxonomies;
  Map<String, List<TenantAdminTaxonomyTermDefinition>> termsByTaxonomy;

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
      termsByTaxonomy[taxonomyId.value] ?? [];

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
