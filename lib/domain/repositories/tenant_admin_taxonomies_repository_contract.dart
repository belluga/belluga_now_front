import 'dart:math' as math;

import 'package:belluga_now/domain/repositories/value_objects/tenant_admin_taxonomies_repository_contract_values.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_paged_result.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_definition.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_term_definition.dart';
import 'package:stream_value/core/stream_value.dart';

export 'package:belluga_now/domain/repositories/tenant_admin_taxonomies_batch_terms_repository_contract.dart';
export 'package:belluga_now/domain/repositories/value_objects/tenant_admin_taxonomies_repository_contract_values.dart';

typedef TenantAdminTaxRepoString
    = TenantAdminTaxonomiesRepositoryContractTextValue;
typedef TenantAdminTaxRepoInt = TenantAdminTaxonomiesRepositoryContractIntValue;
typedef TenantAdminTaxRepoBool
    = TenantAdminTaxonomiesRepositoryContractBoolValue;

abstract class TenantAdminTaxonomiesRepositoryContract {
  static final Expando<_TenantAdminTaxonomiesPaginationState>
      _paginationStateByRepository =
      Expando<_TenantAdminTaxonomiesPaginationState>();

  _TenantAdminTaxonomiesPaginationState get _paginationState =>
      _paginationStateByRepository[this] ??=
          _TenantAdminTaxonomiesPaginationState();

  StreamValue<List<TenantAdminTaxonomyDefinition>?> get taxonomiesStreamValue =>
      _paginationState.taxonomiesStreamValue;

  StreamValue<TenantAdminTaxRepoBool> get hasMoreTaxonomiesStreamValue =>
      _paginationState.hasMoreTaxonomiesStreamValue;

  StreamValue<TenantAdminTaxRepoBool> get isTaxonomiesPageLoadingStreamValue =>
      _paginationState.isTaxonomiesPageLoadingStreamValue;

  StreamValue<TenantAdminTaxRepoString?> get taxonomiesErrorStreamValue =>
      _paginationState.taxonomiesErrorStreamValue;

  StreamValue<List<TenantAdminTaxonomyTermDefinition>?> get termsStreamValue =>
      _paginationState.termsStreamValue;

  StreamValue<TenantAdminTaxRepoBool> get hasMoreTermsStreamValue =>
      _paginationState.hasMoreTermsStreamValue;

  StreamValue<TenantAdminTaxRepoBool> get isTermsPageLoadingStreamValue =>
      _paginationState.isTermsPageLoadingStreamValue;

  StreamValue<TenantAdminTaxRepoString?> get termsErrorStreamValue =>
      _paginationState.termsErrorStreamValue;

  Future<void> loadTaxonomies({TenantAdminTaxRepoInt? pageSize}) async {
    final effectivePageSize = pageSize ??
        tenantAdminTaxRepoInt(
          20,
          defaultValue: 20,
        );
    await _waitForTaxonomiesFetch();
    _resetTaxonomiesPagination();
    taxonomiesStreamValue.addValue(null);
    await _fetchTaxonomiesPage(
      page: tenantAdminTaxRepoInt(
        1,
        defaultValue: 1,
      ),
      pageSize: effectivePageSize,
    );
  }

  Future<void> loadNextTaxonomiesPage({TenantAdminTaxRepoInt? pageSize}) async {
    final effectivePageSize = pageSize ??
        tenantAdminTaxRepoInt(
          20,
          defaultValue: 20,
        );
    if (_paginationState.isFetchingTaxonomiesPage.value ||
        !_paginationState.hasMoreTaxonomies.value) {
      return;
    }
    await _fetchTaxonomiesPage(
      page: tenantAdminTaxRepoInt(
        _paginationState.currentTaxonomiesPage.value + 1,
        defaultValue: 1,
      ),
      pageSize: effectivePageSize,
    );
  }

  Future<void> loadAllTaxonomies({TenantAdminTaxRepoInt? pageSize}) async {
    final effectivePageSize = pageSize ??
        tenantAdminTaxRepoInt(
          50,
          defaultValue: 50,
        );
    await loadTaxonomies(pageSize: effectivePageSize);
    var safetyCounter = 0;
    while (hasMoreTaxonomiesStreamValue.value.value && safetyCounter < 200) {
      safetyCounter += 1;
      await loadNextTaxonomiesPage(pageSize: effectivePageSize);
    }
  }

  void resetTaxonomiesState() {
    _resetTaxonomiesPagination();
    taxonomiesStreamValue.addValue(null);
    taxonomiesErrorStreamValue.addValue(null);
  }

  Future<List<TenantAdminTaxonomyDefinition>> fetchTaxonomies();
  Future<TenantAdminPagedResult<TenantAdminTaxonomyDefinition>>
      fetchTaxonomiesPage({
    required TenantAdminTaxRepoInt page,
    required TenantAdminTaxRepoInt pageSize,
  }) async {
    final taxonomies = await fetchTaxonomies();
    if (page.value <= 0 || pageSize.value <= 0) {
      return tenantAdminPagedResultFromRaw(
        items: <TenantAdminTaxonomyDefinition>[],
        hasMore: false,
      );
    }
    final startIndex = (page.value - 1) * pageSize.value;
    if (startIndex >= taxonomies.length) {
      return tenantAdminPagedResultFromRaw(
        items: <TenantAdminTaxonomyDefinition>[],
        hasMore: false,
      );
    }
    final endIndex = math.min(startIndex + pageSize.value, taxonomies.length);
    return tenantAdminPagedResultFromRaw(
      items: taxonomies.sublist(startIndex, endIndex),
      hasMore: endIndex < taxonomies.length,
    );
  }

  Future<TenantAdminTaxonomyDefinition> createTaxonomy({
    required TenantAdminTaxRepoString slug,
    required TenantAdminTaxRepoString name,
    required List<TenantAdminTaxRepoString> appliesTo,
    TenantAdminTaxRepoString? icon,
    TenantAdminTaxRepoString? color,
  });
  Future<TenantAdminTaxonomyDefinition> updateTaxonomy({
    required TenantAdminTaxRepoString taxonomyId,
    TenantAdminTaxRepoString? slug,
    TenantAdminTaxRepoString? name,
    List<TenantAdminTaxRepoString>? appliesTo,
    TenantAdminTaxRepoString? icon,
    TenantAdminTaxRepoString? color,
  });
  Future<void> deleteTaxonomy(TenantAdminTaxRepoString taxonomyId);
  Future<List<TenantAdminTaxonomyTermDefinition>> fetchTerms({
    required TenantAdminTaxRepoString taxonomyId,
  });

  Future<TenantAdminPagedResult<TenantAdminTaxonomyTermDefinition>>
      fetchTermsPage({
    required TenantAdminTaxRepoString taxonomyId,
    required TenantAdminTaxRepoInt page,
    required TenantAdminTaxRepoInt pageSize,
  }) async {
    final terms = await fetchTerms(taxonomyId: taxonomyId);
    if (page.value <= 0 || pageSize.value <= 0) {
      return tenantAdminPagedResultFromRaw(
        items: <TenantAdminTaxonomyTermDefinition>[],
        hasMore: false,
      );
    }
    final startIndex = (page.value - 1) * pageSize.value;
    if (startIndex >= terms.length) {
      return tenantAdminPagedResultFromRaw(
        items: <TenantAdminTaxonomyTermDefinition>[],
        hasMore: false,
      );
    }
    final endIndex = math.min(startIndex + pageSize.value, terms.length);
    return tenantAdminPagedResultFromRaw(
      items: terms.sublist(startIndex, endIndex),
      hasMore: endIndex < terms.length,
    );
  }

  Future<TenantAdminTaxonomyTermDefinition> createTerm({
    required TenantAdminTaxRepoString taxonomyId,
    required TenantAdminTaxRepoString slug,
    required TenantAdminTaxRepoString name,
  });

  Future<void> loadTerms({
    required TenantAdminTaxRepoString taxonomyId,
    TenantAdminTaxRepoInt? pageSize,
  }) async {
    final effectivePageSize = pageSize ??
        tenantAdminTaxRepoInt(
          20,
          defaultValue: 20,
        );
    _paginationState.activeTaxonomyId = taxonomyId;
    await _waitForTermsFetch();
    _resetTermsPagination();
    termsStreamValue.addValue(null);
    await _fetchTermsPage(
      taxonomyId: taxonomyId,
      page: tenantAdminTaxRepoInt(
        1,
        defaultValue: 1,
      ),
      pageSize: effectivePageSize,
    );
  }

  Future<void> loadNextTermsPage({TenantAdminTaxRepoInt? pageSize}) async {
    final effectivePageSize = pageSize ??
        tenantAdminTaxRepoInt(
          20,
          defaultValue: 20,
        );
    final taxonomyId = _paginationState.activeTaxonomyId;
    if (taxonomyId == null ||
        taxonomyId.value.isEmpty ||
        _paginationState.isFetchingTermsPage.value ||
        !_paginationState.hasMoreTerms.value) {
      return;
    }
    await _fetchTermsPage(
      taxonomyId: taxonomyId,
      page: tenantAdminTaxRepoInt(
        _paginationState.currentTermsPage.value + 1,
        defaultValue: 1,
      ),
      pageSize: effectivePageSize,
    );
  }

  Future<void> loadAllTerms({
    required TenantAdminTaxRepoString taxonomyId,
    TenantAdminTaxRepoInt? pageSize,
  }) async {
    final effectivePageSize = pageSize ??
        tenantAdminTaxRepoInt(
          50,
          defaultValue: 50,
        );
    await loadTerms(taxonomyId: taxonomyId, pageSize: effectivePageSize);
    var safetyCounter = 0;
    while (hasMoreTermsStreamValue.value.value && safetyCounter < 200) {
      safetyCounter += 1;
      await loadNextTermsPage(pageSize: effectivePageSize);
    }
  }

  void resetTermsState() {
    _paginationState.activeTaxonomyId = null;
    _resetTermsPagination();
    termsStreamValue.addValue(null);
    termsErrorStreamValue.addValue(null);
  }

  Future<TenantAdminTaxonomyTermDefinition> updateTerm({
    required TenantAdminTaxRepoString taxonomyId,
    required TenantAdminTaxRepoString termId,
    TenantAdminTaxRepoString? slug,
    TenantAdminTaxRepoString? name,
  });
  Future<void> deleteTerm({
    required TenantAdminTaxRepoString taxonomyId,
    required TenantAdminTaxRepoString termId,
  });

  Future<void> _waitForTaxonomiesFetch() async {
    while (_paginationState.isFetchingTaxonomiesPage.value) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
  }

  Future<void> _fetchTaxonomiesPage({
    required TenantAdminTaxRepoInt page,
    required TenantAdminTaxRepoInt pageSize,
  }) async {
    if (_paginationState.isFetchingTaxonomiesPage.value) return;
    if (page.value > 1 && !_paginationState.hasMoreTaxonomies.value) return;

    _paginationState.isFetchingTaxonomiesPage = tenantAdminTaxRepoBool(
      true,
      defaultValue: true,
    );
    if (page.value > 1) {
      isTaxonomiesPageLoadingStreamValue.addValue(
        tenantAdminTaxRepoBool(
          true,
          defaultValue: true,
        ),
      );
    }
    try {
      final result = await fetchTaxonomiesPage(
        page: page,
        pageSize: pageSize,
      );
      if (page.value == 1) {
        _paginationState.cachedTaxonomies
          ..clear()
          ..addAll(result.items);
      } else {
        _paginationState.cachedTaxonomies.addAll(result.items);
      }
      _paginationState.currentTaxonomiesPage = page;
      _paginationState.hasMoreTaxonomies = tenantAdminTaxRepoBool(
        result.hasMore,
        defaultValue: true,
      );
      hasMoreTaxonomiesStreamValue.addValue(
        _paginationState.hasMoreTaxonomies,
      );
      taxonomiesStreamValue.addValue(
        List<TenantAdminTaxonomyDefinition>.unmodifiable(
          _paginationState.cachedTaxonomies,
        ),
      );
      taxonomiesErrorStreamValue.addValue(null);
    } catch (error) {
      taxonomiesErrorStreamValue.addValue(
        tenantAdminTaxRepoString(error.toString()),
      );
      if (page.value == 1) {
        taxonomiesStreamValue.addValue(const <TenantAdminTaxonomyDefinition>[]);
      }
    } finally {
      _paginationState.isFetchingTaxonomiesPage = tenantAdminTaxRepoBool(
        false,
        defaultValue: false,
      );
      isTaxonomiesPageLoadingStreamValue.addValue(
        tenantAdminTaxRepoBool(
          false,
          defaultValue: false,
        ),
      );
    }
  }

  void _resetTaxonomiesPagination() {
    _paginationState.cachedTaxonomies.clear();
    _paginationState.currentTaxonomiesPage = tenantAdminTaxRepoInt(
      0,
      defaultValue: 0,
    );
    _paginationState.hasMoreTaxonomies = tenantAdminTaxRepoBool(
      true,
      defaultValue: true,
    );
    _paginationState.isFetchingTaxonomiesPage = tenantAdminTaxRepoBool(
      false,
      defaultValue: false,
    );
    hasMoreTaxonomiesStreamValue.addValue(
      tenantAdminTaxRepoBool(
        true,
        defaultValue: true,
      ),
    );
    isTaxonomiesPageLoadingStreamValue.addValue(
      tenantAdminTaxRepoBool(
        false,
        defaultValue: false,
      ),
    );
  }

  Future<void> _waitForTermsFetch() async {
    while (_paginationState.isFetchingTermsPage.value) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
  }

  Future<void> _fetchTermsPage({
    required TenantAdminTaxRepoString taxonomyId,
    required TenantAdminTaxRepoInt page,
    required TenantAdminTaxRepoInt pageSize,
  }) async {
    if (_paginationState.isFetchingTermsPage.value) return;
    if (page.value > 1 && !_paginationState.hasMoreTerms.value) return;

    _paginationState.isFetchingTermsPage = tenantAdminTaxRepoBool(
      true,
      defaultValue: true,
    );
    if (page.value > 1) {
      isTermsPageLoadingStreamValue.addValue(
        tenantAdminTaxRepoBool(
          true,
          defaultValue: true,
        ),
      );
    }
    try {
      final result = await fetchTermsPage(
        taxonomyId: taxonomyId,
        page: page,
        pageSize: pageSize,
      );
      if (page.value == 1) {
        _paginationState.cachedTerms
          ..clear()
          ..addAll(result.items);
      } else {
        _paginationState.cachedTerms.addAll(result.items);
      }
      _paginationState.currentTermsPage = page;
      _paginationState.hasMoreTerms = tenantAdminTaxRepoBool(
        result.hasMore,
        defaultValue: true,
      );
      hasMoreTermsStreamValue.addValue(_paginationState.hasMoreTerms);
      termsStreamValue.addValue(
        List<TenantAdminTaxonomyTermDefinition>.unmodifiable(
          _paginationState.cachedTerms,
        ),
      );
      termsErrorStreamValue.addValue(null);
    } catch (error) {
      termsErrorStreamValue.addValue(
        tenantAdminTaxRepoString(error.toString()),
      );
      if (page.value == 1) {
        termsStreamValue.addValue(const <TenantAdminTaxonomyTermDefinition>[]);
      }
    } finally {
      _paginationState.isFetchingTermsPage = tenantAdminTaxRepoBool(
        false,
        defaultValue: false,
      );
      isTermsPageLoadingStreamValue.addValue(
        tenantAdminTaxRepoBool(
          false,
          defaultValue: false,
        ),
      );
    }
  }

  void _resetTermsPagination() {
    _paginationState.cachedTerms.clear();
    _paginationState.currentTermsPage = tenantAdminTaxRepoInt(
      0,
      defaultValue: 0,
    );
    _paginationState.hasMoreTerms = tenantAdminTaxRepoBool(
      true,
      defaultValue: true,
    );
    _paginationState.isFetchingTermsPage = tenantAdminTaxRepoBool(
      false,
      defaultValue: false,
    );
    hasMoreTermsStreamValue.addValue(
      tenantAdminTaxRepoBool(
        true,
        defaultValue: true,
      ),
    );
    isTermsPageLoadingStreamValue.addValue(
      tenantAdminTaxRepoBool(
        false,
        defaultValue: false,
      ),
    );
  }
}

extension TenantAdminTaxonomiesRepositoryLookup
    on TenantAdminTaxonomiesRepositoryContract {
  Future<TenantAdminTaxonomyDefinition> fetchTaxonomy(
      TenantAdminTaxRepoString taxonomyId) async {
    final normalizedId = taxonomyId.value.trim();
    if (normalizedId.isEmpty) {
      throw ArgumentError.value(
        taxonomyId.value,
        'taxonomyId',
        'Taxonomy id must not be empty',
      );
    }

    final taxonomies = await fetchTaxonomies();
    for (final taxonomy in taxonomies) {
      if (taxonomy.id == normalizedId) {
        return taxonomy;
      }
    }

    throw StateError('Taxonomy not found for id: $normalizedId');
  }

  Future<TenantAdminTaxonomyTermDefinition> fetchTerm({
    required TenantAdminTaxRepoString taxonomyId,
    required TenantAdminTaxRepoString termId,
  }) async {
    final normalizedTaxonomyId = taxonomyId.value.trim();
    final normalizedTermId = termId.value.trim();
    if (normalizedTaxonomyId.isEmpty) {
      throw ArgumentError.value(
        taxonomyId.value,
        'taxonomyId',
        'Taxonomy id must not be empty',
      );
    }
    if (normalizedTermId.isEmpty) {
      throw ArgumentError.value(
        termId.value,
        'termId',
        'Term id must not be empty',
      );
    }

    final terms = await fetchTerms(
      taxonomyId: tenantAdminTaxRepoString(
        normalizedTaxonomyId,
        defaultValue: '',
        isRequired: true,
      ),
    );
    for (final term in terms) {
      if (term.id == normalizedTermId) {
        return term;
      }
    }

    throw StateError(
      'Taxonomy term not found for taxonomyId=$normalizedTaxonomyId and termId=$normalizedTermId',
    );
  }
}

mixin TenantAdminTaxonomiesPaginationMixin
    implements TenantAdminTaxonomiesRepositoryContract {
  static final Expando<_TenantAdminTaxonomiesPaginationState>
      _paginationStateByRepository =
      Expando<_TenantAdminTaxonomiesPaginationState>();

  @override
  _TenantAdminTaxonomiesPaginationState get _paginationState =>
      _paginationStateByRepository[this] ??=
          _TenantAdminTaxonomiesPaginationState();

  @override
  StreamValue<List<TenantAdminTaxonomyDefinition>?> get taxonomiesStreamValue =>
      _paginationState.taxonomiesStreamValue;

  @override
  StreamValue<TenantAdminTaxRepoBool> get hasMoreTaxonomiesStreamValue =>
      _paginationState.hasMoreTaxonomiesStreamValue;

  @override
  StreamValue<TenantAdminTaxRepoBool> get isTaxonomiesPageLoadingStreamValue =>
      _paginationState.isTaxonomiesPageLoadingStreamValue;

  @override
  StreamValue<TenantAdminTaxRepoString?> get taxonomiesErrorStreamValue =>
      _paginationState.taxonomiesErrorStreamValue;

  @override
  StreamValue<List<TenantAdminTaxonomyTermDefinition>?> get termsStreamValue =>
      _paginationState.termsStreamValue;

  @override
  StreamValue<TenantAdminTaxRepoBool> get hasMoreTermsStreamValue =>
      _paginationState.hasMoreTermsStreamValue;

  @override
  StreamValue<TenantAdminTaxRepoBool> get isTermsPageLoadingStreamValue =>
      _paginationState.isTermsPageLoadingStreamValue;

  @override
  StreamValue<TenantAdminTaxRepoString?> get termsErrorStreamValue =>
      _paginationState.termsErrorStreamValue;

  @override
  Future<void> loadTaxonomies({TenantAdminTaxRepoInt? pageSize}) async {
    final effectivePageSize = pageSize ??
        tenantAdminTaxRepoInt(
          20,
          defaultValue: 20,
        );
    await _waitForTaxonomiesFetch();
    _resetTaxonomiesPagination();
    taxonomiesStreamValue.addValue(null);
    await _fetchTaxonomiesPage(
      page: tenantAdminTaxRepoInt(
        1,
        defaultValue: 1,
      ),
      pageSize: effectivePageSize,
    );
  }

  @override
  Future<void> loadNextTaxonomiesPage({TenantAdminTaxRepoInt? pageSize}) async {
    final effectivePageSize = pageSize ??
        tenantAdminTaxRepoInt(
          20,
          defaultValue: 20,
        );
    if (_paginationState.isFetchingTaxonomiesPage.value ||
        !_paginationState.hasMoreTaxonomies.value) {
      return;
    }
    await _fetchTaxonomiesPage(
      page: tenantAdminTaxRepoInt(
        _paginationState.currentTaxonomiesPage.value + 1,
        defaultValue: 1,
      ),
      pageSize: effectivePageSize,
    );
  }

  @override
  Future<void> loadAllTaxonomies({TenantAdminTaxRepoInt? pageSize}) async {
    final effectivePageSize = pageSize ??
        tenantAdminTaxRepoInt(
          50,
          defaultValue: 50,
        );
    await loadTaxonomies(pageSize: effectivePageSize);
    var safetyCounter = 0;
    while (hasMoreTaxonomiesStreamValue.value.value && safetyCounter < 200) {
      safetyCounter += 1;
      await loadNextTaxonomiesPage(pageSize: effectivePageSize);
    }
  }

  @override
  void resetTaxonomiesState() {
    _resetTaxonomiesPagination();
    taxonomiesStreamValue.addValue(null);
    taxonomiesErrorStreamValue.addValue(null);
  }

  @override
  Future<void> loadTerms({
    required TenantAdminTaxRepoString taxonomyId,
    TenantAdminTaxRepoInt? pageSize,
  }) async {
    final effectivePageSize = pageSize ??
        tenantAdminTaxRepoInt(
          20,
          defaultValue: 20,
        );
    _paginationState.activeTaxonomyId = taxonomyId;
    await _waitForTermsFetch();
    _resetTermsPagination();
    termsStreamValue.addValue(null);
    await _fetchTermsPage(
      taxonomyId: taxonomyId,
      page: tenantAdminTaxRepoInt(
        1,
        defaultValue: 1,
      ),
      pageSize: effectivePageSize,
    );
  }

  @override
  Future<void> loadNextTermsPage({TenantAdminTaxRepoInt? pageSize}) async {
    final effectivePageSize = pageSize ??
        tenantAdminTaxRepoInt(
          20,
          defaultValue: 20,
        );
    final taxonomyId = _paginationState.activeTaxonomyId;
    if (taxonomyId == null ||
        taxonomyId.value.isEmpty ||
        _paginationState.isFetchingTermsPage.value ||
        !_paginationState.hasMoreTerms.value) {
      return;
    }
    await _fetchTermsPage(
      taxonomyId: taxonomyId,
      page: tenantAdminTaxRepoInt(
        _paginationState.currentTermsPage.value + 1,
        defaultValue: 1,
      ),
      pageSize: effectivePageSize,
    );
  }

  @override
  Future<void> loadAllTerms({
    required TenantAdminTaxRepoString taxonomyId,
    TenantAdminTaxRepoInt? pageSize,
  }) async {
    final effectivePageSize = pageSize ??
        tenantAdminTaxRepoInt(
          50,
          defaultValue: 50,
        );
    await loadTerms(taxonomyId: taxonomyId, pageSize: effectivePageSize);
    var safetyCounter = 0;
    while (hasMoreTermsStreamValue.value.value && safetyCounter < 200) {
      safetyCounter += 1;
      await loadNextTermsPage(pageSize: effectivePageSize);
    }
  }

  @override
  void resetTermsState() {
    _paginationState.activeTaxonomyId = null;
    _resetTermsPagination();
    termsStreamValue.addValue(null);
    termsErrorStreamValue.addValue(null);
  }

  @override
  Future<void> _waitForTaxonomiesFetch() async {
    while (_paginationState.isFetchingTaxonomiesPage.value) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
  }

  @override
  Future<void> _fetchTaxonomiesPage({
    required TenantAdminTaxRepoInt page,
    required TenantAdminTaxRepoInt pageSize,
  }) async {
    if (_paginationState.isFetchingTaxonomiesPage.value) return;
    if (page.value > 1 && !_paginationState.hasMoreTaxonomies.value) return;

    _paginationState.isFetchingTaxonomiesPage = tenantAdminTaxRepoBool(
      true,
      defaultValue: true,
    );
    if (page.value > 1) {
      isTaxonomiesPageLoadingStreamValue.addValue(
        tenantAdminTaxRepoBool(
          true,
          defaultValue: true,
        ),
      );
    }
    try {
      final result = await fetchTaxonomiesPage(
        page: page,
        pageSize: pageSize,
      );
      if (page.value == 1) {
        _paginationState.cachedTaxonomies
          ..clear()
          ..addAll(result.items);
      } else {
        _paginationState.cachedTaxonomies.addAll(result.items);
      }
      _paginationState.currentTaxonomiesPage = page;
      _paginationState.hasMoreTaxonomies = tenantAdminTaxRepoBool(
        result.hasMore,
        defaultValue: true,
      );
      hasMoreTaxonomiesStreamValue.addValue(
        _paginationState.hasMoreTaxonomies,
      );
      taxonomiesStreamValue.addValue(
        List<TenantAdminTaxonomyDefinition>.unmodifiable(
          _paginationState.cachedTaxonomies,
        ),
      );
      taxonomiesErrorStreamValue.addValue(null);
    } catch (error) {
      taxonomiesErrorStreamValue.addValue(
        tenantAdminTaxRepoString(error.toString()),
      );
      if (page.value == 1) {
        taxonomiesStreamValue.addValue(const <TenantAdminTaxonomyDefinition>[]);
      }
    } finally {
      _paginationState.isFetchingTaxonomiesPage = tenantAdminTaxRepoBool(
        false,
        defaultValue: false,
      );
      isTaxonomiesPageLoadingStreamValue.addValue(
        tenantAdminTaxRepoBool(
          false,
          defaultValue: false,
        ),
      );
    }
  }

  @override
  void _resetTaxonomiesPagination() {
    _paginationState.cachedTaxonomies.clear();
    _paginationState.currentTaxonomiesPage = tenantAdminTaxRepoInt(
      0,
      defaultValue: 0,
    );
    _paginationState.hasMoreTaxonomies = tenantAdminTaxRepoBool(
      true,
      defaultValue: true,
    );
    _paginationState.isFetchingTaxonomiesPage = tenantAdminTaxRepoBool(
      false,
      defaultValue: false,
    );
    hasMoreTaxonomiesStreamValue.addValue(
      tenantAdminTaxRepoBool(
        true,
        defaultValue: true,
      ),
    );
    isTaxonomiesPageLoadingStreamValue.addValue(
      tenantAdminTaxRepoBool(
        false,
        defaultValue: false,
      ),
    );
  }

  @override
  Future<void> _waitForTermsFetch() async {
    while (_paginationState.isFetchingTermsPage.value) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
  }

  @override
  Future<void> _fetchTermsPage({
    required TenantAdminTaxRepoString taxonomyId,
    required TenantAdminTaxRepoInt page,
    required TenantAdminTaxRepoInt pageSize,
  }) async {
    if (_paginationState.isFetchingTermsPage.value) return;
    if (page.value > 1 && !_paginationState.hasMoreTerms.value) return;

    _paginationState.isFetchingTermsPage = tenantAdminTaxRepoBool(
      true,
      defaultValue: true,
    );
    if (page.value > 1) {
      isTermsPageLoadingStreamValue.addValue(
        tenantAdminTaxRepoBool(
          true,
          defaultValue: true,
        ),
      );
    }
    try {
      final result = await fetchTermsPage(
        taxonomyId: taxonomyId,
        page: page,
        pageSize: pageSize,
      );
      if (page.value == 1) {
        _paginationState.cachedTerms
          ..clear()
          ..addAll(result.items);
      } else {
        _paginationState.cachedTerms.addAll(result.items);
      }
      _paginationState.currentTermsPage = page;
      _paginationState.hasMoreTerms = tenantAdminTaxRepoBool(
        result.hasMore,
        defaultValue: true,
      );
      hasMoreTermsStreamValue.addValue(_paginationState.hasMoreTerms);
      termsStreamValue.addValue(
        List<TenantAdminTaxonomyTermDefinition>.unmodifiable(
          _paginationState.cachedTerms,
        ),
      );
      termsErrorStreamValue.addValue(null);
    } catch (error) {
      termsErrorStreamValue.addValue(
        tenantAdminTaxRepoString(error.toString()),
      );
      if (page.value == 1) {
        termsStreamValue.addValue(const <TenantAdminTaxonomyTermDefinition>[]);
      }
    } finally {
      _paginationState.isFetchingTermsPage = tenantAdminTaxRepoBool(
        false,
        defaultValue: false,
      );
      isTermsPageLoadingStreamValue.addValue(
        tenantAdminTaxRepoBool(
          false,
          defaultValue: false,
        ),
      );
    }
  }

  @override
  void _resetTermsPagination() {
    _paginationState.cachedTerms.clear();
    _paginationState.currentTermsPage = tenantAdminTaxRepoInt(
      0,
      defaultValue: 0,
    );
    _paginationState.hasMoreTerms = tenantAdminTaxRepoBool(
      true,
      defaultValue: true,
    );
    _paginationState.isFetchingTermsPage = tenantAdminTaxRepoBool(
      false,
      defaultValue: false,
    );
    hasMoreTermsStreamValue.addValue(
      tenantAdminTaxRepoBool(
        true,
        defaultValue: true,
      ),
    );
    isTermsPageLoadingStreamValue.addValue(
      tenantAdminTaxRepoBool(
        false,
        defaultValue: false,
      ),
    );
  }
}

class _TenantAdminTaxonomiesPaginationState {
  final List<TenantAdminTaxonomyDefinition> cachedTaxonomies =
      <TenantAdminTaxonomyDefinition>[];
  final List<TenantAdminTaxonomyTermDefinition> cachedTerms =
      <TenantAdminTaxonomyTermDefinition>[];
  final StreamValue<List<TenantAdminTaxonomyDefinition>?>
      taxonomiesStreamValue =
      StreamValue<List<TenantAdminTaxonomyDefinition>?>();
  final StreamValue<TenantAdminTaxRepoBool> hasMoreTaxonomiesStreamValue =
      StreamValue<TenantAdminTaxRepoBool>(
    defaultValue: tenantAdminTaxRepoBool(
      true,
      defaultValue: true,
    ),
  );
  final StreamValue<TenantAdminTaxRepoBool> isTaxonomiesPageLoadingStreamValue =
      StreamValue<TenantAdminTaxRepoBool>(
    defaultValue: tenantAdminTaxRepoBool(
      false,
      defaultValue: false,
    ),
  );
  final StreamValue<TenantAdminTaxRepoString?> taxonomiesErrorStreamValue =
      StreamValue<TenantAdminTaxRepoString?>();
  final StreamValue<List<TenantAdminTaxonomyTermDefinition>?> termsStreamValue =
      StreamValue<List<TenantAdminTaxonomyTermDefinition>?>();
  final StreamValue<TenantAdminTaxRepoBool> hasMoreTermsStreamValue =
      StreamValue<TenantAdminTaxRepoBool>(
    defaultValue: tenantAdminTaxRepoBool(
      true,
      defaultValue: true,
    ),
  );
  final StreamValue<TenantAdminTaxRepoBool> isTermsPageLoadingStreamValue =
      StreamValue<TenantAdminTaxRepoBool>(
    defaultValue: tenantAdminTaxRepoBool(
      false,
      defaultValue: false,
    ),
  );
  final StreamValue<TenantAdminTaxRepoString?> termsErrorStreamValue =
      StreamValue<TenantAdminTaxRepoString?>();
  TenantAdminTaxRepoBool isFetchingTaxonomiesPage = tenantAdminTaxRepoBool(
    false,
    defaultValue: false,
  );
  TenantAdminTaxRepoBool hasMoreTaxonomies = tenantAdminTaxRepoBool(
    true,
    defaultValue: true,
  );
  TenantAdminTaxRepoInt currentTaxonomiesPage = tenantAdminTaxRepoInt(
    0,
    defaultValue: 0,
  );
  TenantAdminTaxRepoBool isFetchingTermsPage = tenantAdminTaxRepoBool(
    false,
    defaultValue: false,
  );
  TenantAdminTaxRepoBool hasMoreTerms = tenantAdminTaxRepoBool(
    true,
    defaultValue: true,
  );
  TenantAdminTaxRepoInt currentTermsPage = tenantAdminTaxRepoInt(
    0,
    defaultValue: 0,
  );
  TenantAdminTaxRepoString? activeTaxonomyId;
}
