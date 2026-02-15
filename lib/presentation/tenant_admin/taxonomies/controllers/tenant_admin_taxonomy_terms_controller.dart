import 'dart:async';

import 'package:belluga_now/domain/repositories/tenant_admin_taxonomies_repository_contract.dart';
import 'package:belluga_now/domain/services/tenant_admin_tenant_scope_contract.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_term_definition.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart' show Disposable, GetIt;
import 'package:stream_value/core/stream_value.dart';

class TenantAdminTaxonomyTermsController implements Disposable {
  TenantAdminTaxonomyTermsController({
    TenantAdminTaxonomiesRepositoryContract? repository,
    TenantAdminTenantScopeContract? tenantScope,
  })  : _repository = repository ??
            GetIt.I.get<TenantAdminTaxonomiesRepositoryContract>(),
        _tenantScope = tenantScope ??
            (GetIt.I.isRegistered<TenantAdminTenantScopeContract>()
                ? GetIt.I.get<TenantAdminTenantScopeContract>()
                : null) {
    _bindTenantScope();
  }

  final TenantAdminTaxonomiesRepositoryContract _repository;
  final TenantAdminTenantScopeContract? _tenantScope;
  static const int _termsPageSize = 20;

  final StreamValue<List<TenantAdminTaxonomyTermDefinition>?> termsStreamValue =
      StreamValue<List<TenantAdminTaxonomyTermDefinition>?>();
  final StreamValue<bool> hasMoreTermsStreamValue =
      StreamValue<bool>(defaultValue: true);
  final StreamValue<bool> isTermsPageLoadingStreamValue =
      StreamValue<bool>(defaultValue: false);
  final StreamValue<bool> isLoadingStreamValue =
      StreamValue<bool>(defaultValue: false);
  final StreamValue<String?> errorStreamValue = StreamValue<String?>();
  final StreamValue<String?> successMessageStreamValue = StreamValue<String?>();
  final StreamValue<String?> actionErrorMessageStreamValue =
      StreamValue<String?>();

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController slugController = TextEditingController();
  final TextEditingController nameController = TextEditingController();

  bool _isDisposed = false;
  bool _isFetchingTermsPage = false;
  bool _hasMoreTerms = true;
  int _currentTermsPage = 0;
  final List<TenantAdminTaxonomyTermDefinition> _fetchedTerms =
      <TenantAdminTaxonomyTermDefinition>[];
  StreamSubscription<String?>? _tenantScopeSubscription;
  String? _lastTenantDomain;
  String? _activeTaxonomyId;

  void _bindTenantScope() {
    if (_tenantScopeSubscription != null || _tenantScope == null) {
      return;
    }
    final tenantScope = _tenantScope;
    _lastTenantDomain =
        _normalizeTenantDomain(tenantScope.selectedTenantDomain);
    _tenantScopeSubscription =
        tenantScope.selectedTenantDomainStreamValue.stream.listen(
      (tenantDomain) {
        if (_isDisposed) return;
        final normalized = _normalizeTenantDomain(tenantDomain);
        if (normalized == _lastTenantDomain) {
          return;
        }
        _lastTenantDomain = normalized;
        final activeTaxonomyId = _activeTaxonomyId;
        _resetTenantScopedState();
        if (normalized != null &&
            activeTaxonomyId != null &&
            activeTaxonomyId.isNotEmpty) {
          unawaited(loadTerms(activeTaxonomyId));
        }
      },
    );
  }

  void initForm(TenantAdminTaxonomyTermDefinition? term) {
    slugController.text = term?.slug ?? '';
    nameController.text = term?.name ?? '';
  }

  void resetForm() {
    slugController.clear();
    nameController.clear();
  }

  Future<void> loadTerms(String taxonomyId) async {
    _activeTaxonomyId = taxonomyId;
    await _waitForTermsFetch();
    _resetTermsPagination();
    termsStreamValue.addValue(null);
    await _fetchTermsPage(taxonomyId: taxonomyId, page: 1);
  }

  Future<void> loadNextTermsPage() async {
    final taxonomyId = _activeTaxonomyId;
    if (_isDisposed ||
        taxonomyId == null ||
        taxonomyId.isEmpty ||
        _isFetchingTermsPage ||
        !_hasMoreTerms) {
      return;
    }
    await _fetchTermsPage(
      taxonomyId: taxonomyId,
      page: _currentTermsPage + 1,
    );
  }

  Future<void> _waitForTermsFetch() async {
    while (_isFetchingTermsPage && !_isDisposed) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
  }

  Future<void> _fetchTermsPage({
    required String taxonomyId,
    required int page,
  }) async {
    if (_isFetchingTermsPage) return;
    if (page > 1 && !_hasMoreTerms) return;

    _isFetchingTermsPage = true;
    if (page > 1 && !_isDisposed) {
      isTermsPageLoadingStreamValue.addValue(true);
    }
    isLoadingStreamValue.addValue(true);
    try {
      final result = await _repository.fetchTermsPage(
        taxonomyId: taxonomyId,
        page: page,
        pageSize: _termsPageSize,
      );
      if (_isDisposed) return;
      if (page == 1) {
        _fetchedTerms
          ..clear()
          ..addAll(result.items);
      } else {
        _fetchedTerms.addAll(result.items);
      }
      _currentTermsPage = page;
      _hasMoreTerms = result.hasMore;
      hasMoreTermsStreamValue.addValue(_hasMoreTerms);
      termsStreamValue.addValue(
        List<TenantAdminTaxonomyTermDefinition>.unmodifiable(_fetchedTerms),
      );
      errorStreamValue.addValue(null);
    } catch (error) {
      if (_isDisposed) return;
      if (page == 1) {
        termsStreamValue.addValue(const <TenantAdminTaxonomyTermDefinition>[]);
      }
      errorStreamValue.addValue(error.toString());
    } finally {
      _isFetchingTermsPage = false;
      if (!_isDisposed) {
        isLoadingStreamValue.addValue(false);
        isTermsPageLoadingStreamValue.addValue(false);
      }
    }
  }

  Future<TenantAdminTaxonomyTermDefinition> createTerm({
    required String taxonomyId,
    required String slug,
    required String name,
  }) async {
    final created = await _repository.createTerm(
      taxonomyId: taxonomyId,
      slug: slug,
      name: name,
    );
    await loadTerms(taxonomyId);
    return created;
  }

  Future<TenantAdminTaxonomyTermDefinition> updateTerm({
    required String taxonomyId,
    required String termId,
    String? slug,
    String? name,
  }) async {
    final updated = await _repository.updateTerm(
      taxonomyId: taxonomyId,
      termId: termId,
      slug: slug,
      name: name,
    );
    await loadTerms(taxonomyId);
    return updated;
  }

  Future<void> deleteTerm({
    required String taxonomyId,
    required String termId,
  }) async {
    await _repository.deleteTerm(taxonomyId: taxonomyId, termId: termId);
    await loadTerms(taxonomyId);
  }

  Future<void> submitCreateTerm({
    required String taxonomyId,
    required String slug,
    required String name,
  }) async {
    try {
      await createTerm(
        taxonomyId: taxonomyId,
        slug: slug,
        name: name,
      );
      if (_isDisposed) return;
      actionErrorMessageStreamValue.addValue(null);
      successMessageStreamValue.addValue('Termo criado.');
    } catch (error) {
      if (_isDisposed) return;
      actionErrorMessageStreamValue.addValue(error.toString());
    }
  }

  Future<void> submitUpdateTerm({
    required String taxonomyId,
    required String termId,
    String? slug,
    String? name,
  }) async {
    try {
      await updateTerm(
        taxonomyId: taxonomyId,
        termId: termId,
        slug: slug,
        name: name,
      );
      if (_isDisposed) return;
      actionErrorMessageStreamValue.addValue(null);
      successMessageStreamValue.addValue('Termo atualizado.');
    } catch (error) {
      if (_isDisposed) return;
      actionErrorMessageStreamValue.addValue(error.toString());
    }
  }

  Future<void> submitDeleteTerm({
    required String taxonomyId,
    required String termId,
  }) async {
    try {
      await deleteTerm(taxonomyId: taxonomyId, termId: termId);
      if (_isDisposed) return;
      actionErrorMessageStreamValue.addValue(null);
      successMessageStreamValue.addValue('Termo removido.');
    } catch (error) {
      if (_isDisposed) return;
      actionErrorMessageStreamValue.addValue(error.toString());
    }
  }

  void clearSuccessMessage() {
    successMessageStreamValue.addValue(null);
  }

  void clearActionErrorMessage() {
    actionErrorMessageStreamValue.addValue(null);
  }

  void _resetTenantScopedState() {
    _resetTermsPagination();
    termsStreamValue.addValue(null);
    errorStreamValue.addValue(null);
    successMessageStreamValue.addValue(null);
    actionErrorMessageStreamValue.addValue(null);
    resetForm();
    _activeTaxonomyId = null;
  }

  void _resetTermsPagination() {
    _fetchedTerms.clear();
    _currentTermsPage = 0;
    _hasMoreTerms = true;
    _isFetchingTermsPage = false;
    hasMoreTermsStreamValue.addValue(true);
    isTermsPageLoadingStreamValue.addValue(false);
  }

  String? _normalizeTenantDomain(String? raw) {
    final trimmed = raw?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    final uri =
        Uri.tryParse(trimmed.contains('://') ? trimmed : 'https://$trimmed');
    if (uri != null && uri.host.trim().isNotEmpty) {
      return uri.host.trim();
    }
    return trimmed;
  }

  void dispose() {
    _isDisposed = true;
    _tenantScopeSubscription?.cancel();
    slugController.dispose();
    nameController.dispose();
    termsStreamValue.dispose();
    hasMoreTermsStreamValue.dispose();
    isTermsPageLoadingStreamValue.dispose();
    isLoadingStreamValue.dispose();
    errorStreamValue.dispose();
    successMessageStreamValue.dispose();
    actionErrorMessageStreamValue.dispose();
  }

  @override
  void onDispose() {
    dispose();
  }
}
