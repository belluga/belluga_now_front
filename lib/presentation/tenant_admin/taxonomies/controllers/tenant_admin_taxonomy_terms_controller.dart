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

  StreamValue<List<TenantAdminTaxonomyTermDefinition>?> get termsStreamValue =>
      _repository.termsStreamValue;
  StreamValue<bool> get hasMoreTermsStreamValue =>
      _repository.hasMoreTermsStreamValue;
  StreamValue<bool> get isTermsPageLoadingStreamValue =>
      _repository.isTermsPageLoadingStreamValue;
  final StreamValue<String?> errorStreamValue = StreamValue<String?>();
  final StreamValue<String?> successMessageStreamValue = StreamValue<String?>();
  final StreamValue<String?> actionErrorMessageStreamValue =
      StreamValue<String?>();
  final StreamValue<TenantAdminTaxonomyTermDefinition?> detailTermStreamValue =
      StreamValue<TenantAdminTaxonomyTermDefinition?>();
  final StreamValue<bool> detailSavingStreamValue =
      StreamValue<bool>(defaultValue: false);

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController slugController = TextEditingController();
  final TextEditingController nameController = TextEditingController();

  bool _isDisposed = false;
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
    await _repository.loadTerms(
      taxonomyId: taxonomyId,
      pageSize: _termsPageSize,
    );
    errorStreamValue.addValue(_repository.termsErrorStreamValue.value);
  }

  Future<void> loadNextTermsPage() async {
    final taxonomyId = _activeTaxonomyId;
    if (_isDisposed || taxonomyId == null || taxonomyId.isEmpty) {
      return;
    }
    await _repository.loadNextTermsPage(pageSize: _termsPageSize);
    errorStreamValue.addValue(_repository.termsErrorStreamValue.value);
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

  void initDetailTerm(TenantAdminTaxonomyTermDefinition term) {
    detailTermStreamValue.addValue(term);
    detailSavingStreamValue.addValue(false);
  }

  void clearDetailTerm() {
    detailTermStreamValue.addValue(null);
    detailSavingStreamValue.addValue(false);
  }

  Future<TenantAdminTaxonomyTermDefinition?> submitDetailTermUpdate({
    required String taxonomyId,
    required String termId,
    String? slug,
    String? name,
  }) async {
    if (detailSavingStreamValue.value) {
      return null;
    }
    detailSavingStreamValue.addValue(true);
    try {
      final updated = await updateTerm(
        taxonomyId: taxonomyId,
        termId: termId,
        slug: slug,
        name: name,
      );
      if (_isDisposed) return null;
      detailTermStreamValue.addValue(updated);
      actionErrorMessageStreamValue.addValue(null);
      return updated;
    } catch (error) {
      if (_isDisposed) return null;
      actionErrorMessageStreamValue.addValue(error.toString());
      return null;
    } finally {
      if (!_isDisposed) {
        detailSavingStreamValue.addValue(false);
      }
    }
  }

  void _resetTenantScopedState() {
    _repository.resetTermsState();
    termsStreamValue.addValue(null);
    errorStreamValue.addValue(null);
    successMessageStreamValue.addValue(null);
    actionErrorMessageStreamValue.addValue(null);
    resetForm();
    _activeTaxonomyId = null;
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
    errorStreamValue.dispose();
    successMessageStreamValue.dispose();
    actionErrorMessageStreamValue.dispose();
    detailTermStreamValue.dispose();
    detailSavingStreamValue.dispose();
  }

  @override
  void onDispose() {
    dispose();
  }
}
