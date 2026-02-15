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
        (index) => TenantAdminTaxonomyDefinition(
          id: 'tax-$index',
          slug: 'slug-$index',
          name: 'Tax $index',
          appliesTo: const ['account_profile'],
          icon: null,
          color: null,
        ),
      ),
      termsByTaxonomy: const {},
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
      taxonomies: const [],
      termsByTaxonomy: {
        'tax-a': List<TenantAdminTaxonomyTermDefinition>.generate(
          22,
          (index) => TenantAdminTaxonomyTermDefinition(
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
      taxonomies: const [
        TenantAdminTaxonomyDefinition(
          id: 'tax-a',
          slug: 'slug-a',
          name: 'Tax A',
          appliesTo: ['account_profile'],
          icon: null,
          color: null,
        ),
      ],
      termsByTaxonomy: const {
        'tax-a': [
          TenantAdminTaxonomyTermDefinition(
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

    repository.taxonomies = const [
      TenantAdminTaxonomyDefinition(
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
      taxonomies: const [],
      termsByTaxonomy: const {
        'tax-a': [
          TenantAdminTaxonomyTermDefinition(
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

    repository.termsByTaxonomy = const {
      'tax-a': [
        TenantAdminTaxonomyTermDefinition(
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
    implements TenantAdminTaxonomiesRepositoryContract {
  _FakeTaxonomiesRepository({
    required this.taxonomies,
    required this.termsByTaxonomy,
  });

  List<TenantAdminTaxonomyDefinition> taxonomies;
  Map<String, List<TenantAdminTaxonomyTermDefinition>> termsByTaxonomy;

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
      termsByTaxonomy[taxonomyId] ?? const [];

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
