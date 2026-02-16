import 'dart:math' as math;

import 'package:belluga_now/domain/tenant_admin/tenant_admin_paged_result.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_definition.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_term_definition.dart';
import 'package:stream_value/core/stream_value.dart';

abstract class TenantAdminTaxonomiesRepositoryContract {
  static final Expando<_TenantAdminTaxonomiesPaginationState>
      _paginationStateByRepository =
      Expando<_TenantAdminTaxonomiesPaginationState>();

  _TenantAdminTaxonomiesPaginationState get _paginationState =>
      _paginationStateByRepository[this] ??=
          _TenantAdminTaxonomiesPaginationState();

  StreamValue<List<TenantAdminTaxonomyDefinition>?> get taxonomiesStreamValue =>
      _paginationState.taxonomiesStreamValue;

  StreamValue<bool> get hasMoreTaxonomiesStreamValue =>
      _paginationState.hasMoreTaxonomiesStreamValue;

  StreamValue<bool> get isTaxonomiesPageLoadingStreamValue =>
      _paginationState.isTaxonomiesPageLoadingStreamValue;

  StreamValue<String?> get taxonomiesErrorStreamValue =>
      _paginationState.taxonomiesErrorStreamValue;

  StreamValue<List<TenantAdminTaxonomyTermDefinition>?> get termsStreamValue =>
      _paginationState.termsStreamValue;

  StreamValue<bool> get hasMoreTermsStreamValue =>
      _paginationState.hasMoreTermsStreamValue;

  StreamValue<bool> get isTermsPageLoadingStreamValue =>
      _paginationState.isTermsPageLoadingStreamValue;

  StreamValue<String?> get termsErrorStreamValue =>
      _paginationState.termsErrorStreamValue;

  Future<void> loadTaxonomies({int pageSize = 20}) async {
    await _waitForTaxonomiesFetch();
    _resetTaxonomiesPagination();
    taxonomiesStreamValue.addValue(null);
    await _fetchTaxonomiesPage(page: 1, pageSize: pageSize);
  }

  Future<void> loadNextTaxonomiesPage({int pageSize = 20}) async {
    if (_paginationState.isFetchingTaxonomiesPage ||
        !_paginationState.hasMoreTaxonomies) {
      return;
    }
    await _fetchTaxonomiesPage(
      page: _paginationState.currentTaxonomiesPage + 1,
      pageSize: pageSize,
    );
  }

  void resetTaxonomiesState() {
    _resetTaxonomiesPagination();
    taxonomiesStreamValue.addValue(null);
    taxonomiesErrorStreamValue.addValue(null);
  }

  Future<List<TenantAdminTaxonomyDefinition>> fetchTaxonomies();
  Future<TenantAdminPagedResult<TenantAdminTaxonomyDefinition>>
      fetchTaxonomiesPage({
    required int page,
    required int pageSize,
  }) async {
    final taxonomies = await fetchTaxonomies();
    if (page <= 0 || pageSize <= 0) {
      return const TenantAdminPagedResult<TenantAdminTaxonomyDefinition>(
        items: <TenantAdminTaxonomyDefinition>[],
        hasMore: false,
      );
    }
    final startIndex = (page - 1) * pageSize;
    if (startIndex >= taxonomies.length) {
      return const TenantAdminPagedResult<TenantAdminTaxonomyDefinition>(
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
    required String slug,
    required String name,
    required List<String> appliesTo,
    String? icon,
    String? color,
  });
  Future<TenantAdminTaxonomyDefinition> updateTaxonomy({
    required String taxonomyId,
    String? slug,
    String? name,
    List<String>? appliesTo,
    String? icon,
    String? color,
  });
  Future<void> deleteTaxonomy(String taxonomyId);
  Future<List<TenantAdminTaxonomyTermDefinition>> fetchTerms({
    required String taxonomyId,
  });
  Future<TenantAdminPagedResult<TenantAdminTaxonomyTermDefinition>>
      fetchTermsPage({
    required String taxonomyId,
    required int page,
    required int pageSize,
  }) async {
    final terms = await fetchTerms(taxonomyId: taxonomyId);
    if (page <= 0 || pageSize <= 0) {
      return const TenantAdminPagedResult<TenantAdminTaxonomyTermDefinition>(
        items: <TenantAdminTaxonomyTermDefinition>[],
        hasMore: false,
      );
    }
    final startIndex = (page - 1) * pageSize;
    if (startIndex >= terms.length) {
      return const TenantAdminPagedResult<TenantAdminTaxonomyTermDefinition>(
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
    required String taxonomyId,
    required String slug,
    required String name,
  });

  Future<void> loadTerms({
    required String taxonomyId,
    int pageSize = 20,
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

  Future<void> loadNextTermsPage({int pageSize = 20}) async {
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

  void resetTermsState() {
    _paginationState.activeTaxonomyId = null;
    _resetTermsPagination();
    termsStreamValue.addValue(null);
    termsErrorStreamValue.addValue(null);
  }

  Future<TenantAdminTaxonomyTermDefinition> updateTerm({
    required String taxonomyId,
    required String termId,
    String? slug,
    String? name,
  });
  Future<void> deleteTerm({
    required String taxonomyId,
    required String termId,
  });

  Future<void> _waitForTaxonomiesFetch() async {
    while (_paginationState.isFetchingTaxonomiesPage) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
  }

  Future<void> _fetchTaxonomiesPage({
    required int page,
    required int pageSize,
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
    required String taxonomyId,
    required int page,
    required int pageSize,
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
  StreamValue<bool> get hasMoreTaxonomiesStreamValue =>
      _paginationState.hasMoreTaxonomiesStreamValue;

  @override
  StreamValue<bool> get isTaxonomiesPageLoadingStreamValue =>
      _paginationState.isTaxonomiesPageLoadingStreamValue;

  @override
  StreamValue<String?> get taxonomiesErrorStreamValue =>
      _paginationState.taxonomiesErrorStreamValue;

  @override
  StreamValue<List<TenantAdminTaxonomyTermDefinition>?> get termsStreamValue =>
      _paginationState.termsStreamValue;

  @override
  StreamValue<bool> get hasMoreTermsStreamValue =>
      _paginationState.hasMoreTermsStreamValue;

  @override
  StreamValue<bool> get isTermsPageLoadingStreamValue =>
      _paginationState.isTermsPageLoadingStreamValue;

  @override
  StreamValue<String?> get termsErrorStreamValue =>
      _paginationState.termsErrorStreamValue;

  @override
  Future<void> loadTaxonomies({int pageSize = 20}) async {
    await _waitForTaxonomiesFetch();
    _resetTaxonomiesPagination();
    taxonomiesStreamValue.addValue(null);
    await _fetchTaxonomiesPage(page: 1, pageSize: pageSize);
  }

  @override
  Future<void> loadNextTaxonomiesPage({int pageSize = 20}) async {
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
  void resetTaxonomiesState() {
    _resetTaxonomiesPagination();
    taxonomiesStreamValue.addValue(null);
    taxonomiesErrorStreamValue.addValue(null);
  }

  @override
  Future<void> loadTerms({
    required String taxonomyId,
    int pageSize = 20,
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
  Future<void> loadNextTermsPage({int pageSize = 20}) async {
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
    required int page,
    required int pageSize,
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
    required String taxonomyId,
    required int page,
    required int pageSize,
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
  final StreamValue<bool> hasMoreTaxonomiesStreamValue =
      StreamValue<bool>(defaultValue: true);
  final StreamValue<bool> isTaxonomiesPageLoadingStreamValue =
      StreamValue<bool>(defaultValue: false);
  final StreamValue<String?> taxonomiesErrorStreamValue =
      StreamValue<String?>();
  final StreamValue<List<TenantAdminTaxonomyTermDefinition>?> termsStreamValue =
      StreamValue<List<TenantAdminTaxonomyTermDefinition>?>();
  final StreamValue<bool> hasMoreTermsStreamValue =
      StreamValue<bool>(defaultValue: true);
  final StreamValue<bool> isTermsPageLoadingStreamValue =
      StreamValue<bool>(defaultValue: false);
  final StreamValue<String?> termsErrorStreamValue = StreamValue<String?>();
  bool isFetchingTaxonomiesPage = false;
  bool hasMoreTaxonomies = true;
  int currentTaxonomiesPage = 0;
  bool isFetchingTermsPage = false;
  bool hasMoreTerms = true;
  int currentTermsPage = 0;
  String? activeTaxonomyId;
}
