import 'dart:math' as math;

import 'package:belluga_now/domain/tenant_admin/tenant_admin_paged_result.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_definition.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_term_definition.dart';
import 'package:stream_value/core/stream_value.dart';

typedef TenantAdminTaxRepoString = String;
typedef TenantAdminTaxRepoInt = int;
typedef TenantAdminTaxRepoBool = bool;
typedef TenantAdminTaxRepoDouble = double;
typedef TenantAdminTaxRepoDateTime = DateTime;
typedef TenantAdminTaxRepoDynamic = dynamic;

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

  Future<void> loadTaxonomies({TenantAdminTaxRepoInt pageSize = 20}) async {
    await _waitForTaxonomiesFetch();
    _resetTaxonomiesPagination();
    taxonomiesStreamValue.addValue(null);
    await _fetchTaxonomiesPage(page: 1, pageSize: pageSize);
  }

  Future<void> loadNextTaxonomiesPage(
      {TenantAdminTaxRepoInt pageSize = 20}) async {
    if (_paginationState.isFetchingTaxonomiesPage ||
        !_paginationState.hasMoreTaxonomies) {
      return;
    }
    await _fetchTaxonomiesPage(
      page: _paginationState.currentTaxonomiesPage + 1,
      pageSize: pageSize,
    );
  }

  Future<void> loadAllTaxonomies({TenantAdminTaxRepoInt pageSize = 50}) async {
    await loadTaxonomies(pageSize: pageSize);
    var safetyCounter = 0;
    while (hasMoreTaxonomiesStreamValue.value && safetyCounter < 200) {
      safetyCounter += 1;
      await loadNextTaxonomiesPage(pageSize: pageSize);
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
    if (page <= 0 || pageSize <= 0) {
      return TenantAdminPagedResult<TenantAdminTaxonomyDefinition>(
        items: <TenantAdminTaxonomyDefinition>[],
        hasMore: false,
      );
    }
    final startIndex = (page - 1) * pageSize;
    if (startIndex >= taxonomies.length) {
      return TenantAdminPagedResult<TenantAdminTaxonomyDefinition>(
        items: <TenantAdminTaxonomyDefinition>[],
        hasMore: false,
      );
    }
    final endIndex = math.min(startIndex + pageSize, taxonomies.length);
    return TenantAdminPagedResult<TenantAdminTaxonomyDefinition>(
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
    if (page <= 0 || pageSize <= 0) {
      return TenantAdminPagedResult<TenantAdminTaxonomyTermDefinition>(
        items: <TenantAdminTaxonomyTermDefinition>[],
        hasMore: false,
      );
    }
    final startIndex = (page - 1) * pageSize;
    if (startIndex >= terms.length) {
      return TenantAdminPagedResult<TenantAdminTaxonomyTermDefinition>(
        items: <TenantAdminTaxonomyTermDefinition>[],
        hasMore: false,
      );
    }
    final endIndex = math.min(startIndex + pageSize, terms.length);
    return TenantAdminPagedResult<TenantAdminTaxonomyTermDefinition>(
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
    TenantAdminTaxRepoInt pageSize = 20,
  }) async {
    _paginationState.activeTaxonomyId = taxonomyId;
    await _waitForTermsFetch();
    _resetTermsPagination();
    termsStreamValue.addValue(null);
    await _fetchTermsPage(
      taxonomyId: taxonomyId,
      page: 1,
      pageSize: pageSize,
    );
  }

  Future<void> loadNextTermsPage({TenantAdminTaxRepoInt pageSize = 20}) async {
    final taxonomyId = _paginationState.activeTaxonomyId;
    if (taxonomyId == null ||
        taxonomyId.isEmpty ||
        _paginationState.isFetchingTermsPage ||
        !_paginationState.hasMoreTerms) {
      return;
    }
    await _fetchTermsPage(
      taxonomyId: taxonomyId,
      page: _paginationState.currentTermsPage + 1,
      pageSize: pageSize,
    );
  }

  Future<void> loadAllTerms({
    required TenantAdminTaxRepoString taxonomyId,
    TenantAdminTaxRepoInt pageSize = 50,
  }) async {
    await loadTerms(taxonomyId: taxonomyId, pageSize: pageSize);
    var safetyCounter = 0;
    while (hasMoreTermsStreamValue.value && safetyCounter < 200) {
      safetyCounter += 1;
      await loadNextTermsPage(pageSize: pageSize);
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
    while (_paginationState.isFetchingTaxonomiesPage) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
  }

  Future<void> _fetchTaxonomiesPage({
    required TenantAdminTaxRepoInt page,
    required TenantAdminTaxRepoInt pageSize,
  }) async {
    if (_paginationState.isFetchingTaxonomiesPage) return;
    if (page > 1 && !_paginationState.hasMoreTaxonomies) return;

    _paginationState.isFetchingTaxonomiesPage = true;
    if (page > 1) {
      isTaxonomiesPageLoadingStreamValue.addValue(true);
    }
    try {
      final result = await fetchTaxonomiesPage(
        page: page,
        pageSize: pageSize,
      );
      if (page == 1) {
        _paginationState.cachedTaxonomies
          ..clear()
          ..addAll(result.items);
      } else {
        _paginationState.cachedTaxonomies.addAll(result.items);
      }
      _paginationState.currentTaxonomiesPage = page;
      _paginationState.hasMoreTaxonomies = result.hasMore;
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
      taxonomiesErrorStreamValue.addValue(error.toString());
      if (page == 1) {
        taxonomiesStreamValue.addValue(const <TenantAdminTaxonomyDefinition>[]);
      }
    } finally {
      _paginationState.isFetchingTaxonomiesPage = false;
      isTaxonomiesPageLoadingStreamValue.addValue(false);
    }
  }

  void _resetTaxonomiesPagination() {
    _paginationState.cachedTaxonomies.clear();
    _paginationState.currentTaxonomiesPage = 0;
    _paginationState.hasMoreTaxonomies = true;
    _paginationState.isFetchingTaxonomiesPage = false;
    hasMoreTaxonomiesStreamValue.addValue(true);
    isTaxonomiesPageLoadingStreamValue.addValue(false);
  }

  Future<void> _waitForTermsFetch() async {
    while (_paginationState.isFetchingTermsPage) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
  }

  Future<void> _fetchTermsPage({
    required TenantAdminTaxRepoString taxonomyId,
    required TenantAdminTaxRepoInt page,
    required TenantAdminTaxRepoInt pageSize,
  }) async {
    if (_paginationState.isFetchingTermsPage) return;
    if (page > 1 && !_paginationState.hasMoreTerms) return;

    _paginationState.isFetchingTermsPage = true;
    if (page > 1) {
      isTermsPageLoadingStreamValue.addValue(true);
    }
    try {
      final result = await fetchTermsPage(
        taxonomyId: taxonomyId,
        page: page,
        pageSize: pageSize,
      );
      if (page == 1) {
        _paginationState.cachedTerms
          ..clear()
          ..addAll(result.items);
      } else {
        _paginationState.cachedTerms.addAll(result.items);
      }
      _paginationState.currentTermsPage = page;
      _paginationState.hasMoreTerms = result.hasMore;
      hasMoreTermsStreamValue.addValue(_paginationState.hasMoreTerms);
      termsStreamValue.addValue(
        List<TenantAdminTaxonomyTermDefinition>.unmodifiable(
          _paginationState.cachedTerms,
        ),
      );
      termsErrorStreamValue.addValue(null);
    } catch (error) {
      termsErrorStreamValue.addValue(error.toString());
      if (page == 1) {
        termsStreamValue.addValue(const <TenantAdminTaxonomyTermDefinition>[]);
      }
    } finally {
      _paginationState.isFetchingTermsPage = false;
      isTermsPageLoadingStreamValue.addValue(false);
    }
  }

  void _resetTermsPagination() {
    _paginationState.cachedTerms.clear();
    _paginationState.currentTermsPage = 0;
    _paginationState.hasMoreTerms = true;
    _paginationState.isFetchingTermsPage = false;
    hasMoreTermsStreamValue.addValue(true);
    isTermsPageLoadingStreamValue.addValue(false);
  }
}

extension TenantAdminTaxonomiesRepositoryLookup
    on TenantAdminTaxonomiesRepositoryContract {
  Future<TenantAdminTaxonomyDefinition> fetchTaxonomy(
      TenantAdminTaxRepoString taxonomyId) async {
    final normalizedId = taxonomyId.trim();
    if (normalizedId.isEmpty) {
      throw ArgumentError.value(
        taxonomyId,
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
    final normalizedTaxonomyId = taxonomyId.trim();
    final normalizedTermId = termId.trim();
    if (normalizedTaxonomyId.isEmpty) {
      throw ArgumentError.value(
        taxonomyId,
        'taxonomyId',
        'Taxonomy id must not be empty',
      );
    }
    if (normalizedTermId.isEmpty) {
      throw ArgumentError.value(
        termId,
        'termId',
        'Term id must not be empty',
      );
    }

    final terms = await fetchTerms(taxonomyId: normalizedTaxonomyId);
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
  Future<void> loadTaxonomies({TenantAdminTaxRepoInt pageSize = 20}) async {
    await _waitForTaxonomiesFetch();
    _resetTaxonomiesPagination();
    taxonomiesStreamValue.addValue(null);
    await _fetchTaxonomiesPage(page: 1, pageSize: pageSize);
  }

  @override
  Future<void> loadNextTaxonomiesPage(
      {TenantAdminTaxRepoInt pageSize = 20}) async {
    if (_paginationState.isFetchingTaxonomiesPage ||
        !_paginationState.hasMoreTaxonomies) {
      return;
    }
    await _fetchTaxonomiesPage(
      page: _paginationState.currentTaxonomiesPage + 1,
      pageSize: pageSize,
    );
  }

  @override
  Future<void> loadAllTaxonomies({TenantAdminTaxRepoInt pageSize = 50}) async {
    await loadTaxonomies(pageSize: pageSize);
    var safetyCounter = 0;
    while (hasMoreTaxonomiesStreamValue.value && safetyCounter < 200) {
      safetyCounter += 1;
      await loadNextTaxonomiesPage(pageSize: pageSize);
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
    TenantAdminTaxRepoInt pageSize = 20,
  }) async {
    _paginationState.activeTaxonomyId = taxonomyId;
    await _waitForTermsFetch();
    _resetTermsPagination();
    termsStreamValue.addValue(null);
    await _fetchTermsPage(
      taxonomyId: taxonomyId,
      page: 1,
      pageSize: pageSize,
    );
  }

  @override
  Future<void> loadNextTermsPage({TenantAdminTaxRepoInt pageSize = 20}) async {
    final taxonomyId = _paginationState.activeTaxonomyId;
    if (taxonomyId == null ||
        taxonomyId.isEmpty ||
        _paginationState.isFetchingTermsPage ||
        !_paginationState.hasMoreTerms) {
      return;
    }
    await _fetchTermsPage(
      taxonomyId: taxonomyId,
      page: _paginationState.currentTermsPage + 1,
      pageSize: pageSize,
    );
  }

  @override
  Future<void> loadAllTerms({
    required TenantAdminTaxRepoString taxonomyId,
    TenantAdminTaxRepoInt pageSize = 50,
  }) async {
    await loadTerms(taxonomyId: taxonomyId, pageSize: pageSize);
    var safetyCounter = 0;
    while (hasMoreTermsStreamValue.value && safetyCounter < 200) {
      safetyCounter += 1;
      await loadNextTermsPage(pageSize: pageSize);
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
    while (_paginationState.isFetchingTaxonomiesPage) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
  }

  @override
  Future<void> _fetchTaxonomiesPage({
    required TenantAdminTaxRepoInt page,
    required TenantAdminTaxRepoInt pageSize,
  }) async {
    if (_paginationState.isFetchingTaxonomiesPage) return;
    if (page > 1 && !_paginationState.hasMoreTaxonomies) return;

    _paginationState.isFetchingTaxonomiesPage = true;
    if (page > 1) {
      isTaxonomiesPageLoadingStreamValue.addValue(true);
    }
    try {
      final result = await fetchTaxonomiesPage(
        page: page,
        pageSize: pageSize,
      );
      if (page == 1) {
        _paginationState.cachedTaxonomies
          ..clear()
          ..addAll(result.items);
      } else {
        _paginationState.cachedTaxonomies.addAll(result.items);
      }
      _paginationState.currentTaxonomiesPage = page;
      _paginationState.hasMoreTaxonomies = result.hasMore;
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
      taxonomiesErrorStreamValue.addValue(error.toString());
      if (page == 1) {
        taxonomiesStreamValue.addValue(const <TenantAdminTaxonomyDefinition>[]);
      }
    } finally {
      _paginationState.isFetchingTaxonomiesPage = false;
      isTaxonomiesPageLoadingStreamValue.addValue(false);
    }
  }

  @override
  void _resetTaxonomiesPagination() {
    _paginationState.cachedTaxonomies.clear();
    _paginationState.currentTaxonomiesPage = 0;
    _paginationState.hasMoreTaxonomies = true;
    _paginationState.isFetchingTaxonomiesPage = false;
    hasMoreTaxonomiesStreamValue.addValue(true);
    isTaxonomiesPageLoadingStreamValue.addValue(false);
  }

  @override
  Future<void> _waitForTermsFetch() async {
    while (_paginationState.isFetchingTermsPage) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
  }

  @override
  Future<void> _fetchTermsPage({
    required TenantAdminTaxRepoString taxonomyId,
    required TenantAdminTaxRepoInt page,
    required TenantAdminTaxRepoInt pageSize,
  }) async {
    if (_paginationState.isFetchingTermsPage) return;
    if (page > 1 && !_paginationState.hasMoreTerms) return;

    _paginationState.isFetchingTermsPage = true;
    if (page > 1) {
      isTermsPageLoadingStreamValue.addValue(true);
    }
    try {
      final result = await fetchTermsPage(
        taxonomyId: taxonomyId,
        page: page,
        pageSize: pageSize,
      );
      if (page == 1) {
        _paginationState.cachedTerms
          ..clear()
          ..addAll(result.items);
      } else {
        _paginationState.cachedTerms.addAll(result.items);
      }
      _paginationState.currentTermsPage = page;
      _paginationState.hasMoreTerms = result.hasMore;
      hasMoreTermsStreamValue.addValue(_paginationState.hasMoreTerms);
      termsStreamValue.addValue(
        List<TenantAdminTaxonomyTermDefinition>.unmodifiable(
          _paginationState.cachedTerms,
        ),
      );
      termsErrorStreamValue.addValue(null);
    } catch (error) {
      termsErrorStreamValue.addValue(error.toString());
      if (page == 1) {
        termsStreamValue.addValue(const <TenantAdminTaxonomyTermDefinition>[]);
      }
    } finally {
      _paginationState.isFetchingTermsPage = false;
      isTermsPageLoadingStreamValue.addValue(false);
    }
  }

  @override
  void _resetTermsPagination() {
    _paginationState.cachedTerms.clear();
    _paginationState.currentTermsPage = 0;
    _paginationState.hasMoreTerms = true;
    _paginationState.isFetchingTermsPage = false;
    hasMoreTermsStreamValue.addValue(true);
    isTermsPageLoadingStreamValue.addValue(false);
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
      StreamValue<TenantAdminTaxRepoBool>(defaultValue: true);
  final StreamValue<TenantAdminTaxRepoBool> isTaxonomiesPageLoadingStreamValue =
      StreamValue<TenantAdminTaxRepoBool>(defaultValue: false);
  final StreamValue<TenantAdminTaxRepoString?> taxonomiesErrorStreamValue =
      StreamValue<TenantAdminTaxRepoString?>();
  final StreamValue<List<TenantAdminTaxonomyTermDefinition>?> termsStreamValue =
      StreamValue<List<TenantAdminTaxonomyTermDefinition>?>();
  final StreamValue<TenantAdminTaxRepoBool> hasMoreTermsStreamValue =
      StreamValue<TenantAdminTaxRepoBool>(defaultValue: true);
  final StreamValue<TenantAdminTaxRepoBool> isTermsPageLoadingStreamValue =
      StreamValue<TenantAdminTaxRepoBool>(defaultValue: false);
  final StreamValue<TenantAdminTaxRepoString?> termsErrorStreamValue =
      StreamValue<TenantAdminTaxRepoString?>();
  TenantAdminTaxRepoBool isFetchingTaxonomiesPage = false;
  TenantAdminTaxRepoBool hasMoreTaxonomies = true;
  TenantAdminTaxRepoInt currentTaxonomiesPage = 0;
  TenantAdminTaxRepoBool isFetchingTermsPage = false;
  TenantAdminTaxRepoBool hasMoreTerms = true;
  TenantAdminTaxRepoInt currentTermsPage = 0;
  TenantAdminTaxRepoString? activeTaxonomyId;
}
