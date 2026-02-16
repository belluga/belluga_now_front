import 'dart:async';

import 'package:belluga_now/domain/repositories/tenant_admin_taxonomies_repository_contract.dart';
import 'package:belluga_now/domain/services/tenant_admin_tenant_scope_contract.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_definition.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_term_definition.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart' show Disposable, GetIt;
import 'package:stream_value/core/stream_value.dart';

class TenantAdminTaxonomiesController implements Disposable {
  TenantAdminTaxonomiesController({
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
  static const int _taxonomiesPageSize = 20;
  static const int _termsPageSize = 20;

  StreamValue<List<TenantAdminTaxonomyDefinition>?> get taxonomiesStreamValue =>
      _repository.taxonomiesStreamValue;
  StreamValue<bool> get hasMoreTaxonomiesStreamValue =>
      _repository.hasMoreTaxonomiesStreamValue;
  StreamValue<bool> get isTaxonomiesPageLoadingStreamValue =>
      _repository.isTaxonomiesPageLoadingStreamValue;
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
  final StreamValue<bool> detailTermSavingStreamValue =
      StreamValue<bool>(defaultValue: false);
  final StreamValue<Set<String>> taxonomyAppliesToSelectionStreamValue =
      StreamValue<Set<String>>(defaultValue: const {});
  final StreamValue<bool> isTaxonomySlugAutoEnabledStreamValue =
      StreamValue<bool>(defaultValue: true);
  final StreamValue<bool> isTermSlugAutoEnabledStreamValue =
      StreamValue<bool>(defaultValue: true);

  final GlobalKey<FormState> taxonomyFormKey = GlobalKey<FormState>();
  final TextEditingController slugController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController iconController = TextEditingController();
  final TextEditingController colorController = TextEditingController();

  final GlobalKey<FormState> termFormKey = GlobalKey<FormState>();
  final TextEditingController termSlugController = TextEditingController();
  final TextEditingController termNameController = TextEditingController();

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
        if (normalized != null) {
          unawaited(loadTaxonomies());
          if (activeTaxonomyId != null && activeTaxonomyId.isNotEmpty) {
            unawaited(loadTerms(activeTaxonomyId));
          }
        }
      },
    );
  }

  Future<void> loadTaxonomies() async {
    await _repository.loadTaxonomies(pageSize: _taxonomiesPageSize);
    errorStreamValue.addValue(_repository.taxonomiesErrorStreamValue.value);
  }

  Future<void> loadNextTaxonomiesPage() async {
    if (_isDisposed) {
      return;
    }
    await _repository.loadNextTaxonomiesPage(pageSize: _taxonomiesPageSize);
    errorStreamValue.addValue(_repository.taxonomiesErrorStreamValue.value);
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

  Future<void> submitCreateTaxonomy({
    required String slug,
    required String name,
    required List<String> appliesTo,
    String? icon,
    String? color,
  }) async {
    try {
      await _repository.createTaxonomy(
        slug: slug,
        name: name,
        appliesTo: appliesTo,
        icon: icon,
        color: color,
      );
      if (_isDisposed) return;
      successMessageStreamValue.addValue('Taxonomia criada.');
      await loadTaxonomies();
    } catch (error) {
      if (_isDisposed) return;
      actionErrorMessageStreamValue.addValue(error.toString());
    }
  }

  Future<void> submitUpdateTaxonomy({
    required String taxonomyId,
    String? slug,
    String? name,
    List<String>? appliesTo,
    String? icon,
    String? color,
  }) async {
    try {
      await _repository.updateTaxonomy(
        taxonomyId: taxonomyId,
        slug: slug,
        name: name,
        appliesTo: appliesTo,
        icon: icon,
        color: color,
      );
      if (_isDisposed) return;
      successMessageStreamValue.addValue('Taxonomia atualizada.');
      await loadTaxonomies();
    } catch (error) {
      if (_isDisposed) return;
      actionErrorMessageStreamValue.addValue(error.toString());
    }
  }

  Future<void> submitDeleteTaxonomy(String taxonomyId) async {
    try {
      await _repository.deleteTaxonomy(taxonomyId);
      if (_isDisposed) return;
      if (_activeTaxonomyId == taxonomyId) {
        _activeTaxonomyId = null;
        _repository.resetTermsState();
        termsStreamValue.addValue(const <TenantAdminTaxonomyTermDefinition>[]);
      }
      successMessageStreamValue.addValue('Taxonomia removida.');
      await loadTaxonomies();
    } catch (error) {
      if (_isDisposed) return;
      actionErrorMessageStreamValue.addValue(error.toString());
    }
  }

  Future<void> submitCreateTerm({
    required String taxonomyId,
    required String slug,
    required String name,
  }) async {
    try {
      await _repository.createTerm(
        taxonomyId: taxonomyId,
        slug: slug,
        name: name,
      );
      if (_isDisposed) return;
      successMessageStreamValue.addValue('Termo criado.');
      await loadTerms(taxonomyId);
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
      successMessageStreamValue.addValue('Termo atualizado.');
      await loadTerms(taxonomyId);
    } catch (error) {
      if (_isDisposed) return;
      actionErrorMessageStreamValue.addValue(error.toString());
    }
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

  Future<void> submitDeleteTerm({
    required String taxonomyId,
    required String termId,
  }) async {
    try {
      await _repository.deleteTerm(
        taxonomyId: taxonomyId,
        termId: termId,
      );
      if (_isDisposed) return;
      successMessageStreamValue.addValue('Termo removido.');
      await loadTerms(taxonomyId);
    } catch (error) {
      if (_isDisposed) return;
      actionErrorMessageStreamValue.addValue(error.toString());
    }
  }

  void initTaxonomyForm(TenantAdminTaxonomyDefinition? taxonomy) {
    slugController.text = taxonomy?.slug ?? '';
    nameController.text = taxonomy?.name ?? '';
    iconController.text = taxonomy?.icon ?? '';
    colorController.text = taxonomy?.color ?? '';
    taxonomyAppliesToSelectionStreamValue
        .addValue((taxonomy?.appliesTo ?? const []).toSet());
    isTaxonomySlugAutoEnabledStreamValue.addValue(true);
  }

  void resetTaxonomyForm() {
    slugController.clear();
    nameController.clear();
    iconController.clear();
    colorController.clear();
    taxonomyAppliesToSelectionStreamValue.addValue(const {});
    isTaxonomySlugAutoEnabledStreamValue.addValue(true);
  }

  Set<String> get selectedAppliesToTargets =>
      taxonomyAppliesToSelectionStreamValue.value;

  bool get isTaxonomySlugAutoEnabled =>
      isTaxonomySlugAutoEnabledStreamValue.value;

  void toggleTaxonomyAppliesToTarget(String target, bool selected) {
    final next = Set<String>.from(selectedAppliesToTargets);
    if (selected) {
      next.add(target);
    } else {
      next.remove(target);
    }
    taxonomyAppliesToSelectionStreamValue.addValue(next);
  }

  void setTaxonomySlugAutoEnabled(bool enabled) {
    isTaxonomySlugAutoEnabledStreamValue.addValue(enabled);
  }

  void initTermForm(TenantAdminTaxonomyTermDefinition? term) {
    termSlugController.text = term?.slug ?? '';
    termNameController.text = term?.name ?? '';
    isTermSlugAutoEnabledStreamValue.addValue(true);
  }

  void resetTermForm() {
    termSlugController.clear();
    termNameController.clear();
    isTermSlugAutoEnabledStreamValue.addValue(true);
  }

  bool get isTermSlugAutoEnabled => isTermSlugAutoEnabledStreamValue.value;

  void setTermSlugAutoEnabled(bool enabled) {
    isTermSlugAutoEnabledStreamValue.addValue(enabled);
  }

  void clearSuccessMessage() {
    successMessageStreamValue.addValue(null);
  }

  void clearActionErrorMessage() {
    actionErrorMessageStreamValue.addValue(null);
  }

  void initDetailTerm(TenantAdminTaxonomyTermDefinition term) {
    detailTermStreamValue.addValue(term);
    detailTermSavingStreamValue.addValue(false);
  }

  void clearDetailTerm() {
    detailTermStreamValue.addValue(null);
    detailTermSavingStreamValue.addValue(false);
  }

  Future<TenantAdminTaxonomyTermDefinition?> submitDetailTermUpdate({
    required String taxonomyId,
    required String termId,
    String? slug,
    String? name,
  }) async {
    if (detailTermSavingStreamValue.value) {
      return null;
    }
    detailTermSavingStreamValue.addValue(true);
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
        detailTermSavingStreamValue.addValue(false);
      }
    }
  }

  void _resetTenantScopedState() {
    _repository.resetTaxonomiesState();
    _repository.resetTermsState();
    taxonomiesStreamValue.addValue(null);
    termsStreamValue.addValue(null);
    errorStreamValue.addValue(null);
    successMessageStreamValue.addValue(null);
    actionErrorMessageStreamValue.addValue(null);
    detailTermStreamValue.addValue(null);
    detailTermSavingStreamValue.addValue(false);
    _activeTaxonomyId = null;
    resetTaxonomyForm();
    resetTermForm();
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
    iconController.dispose();
    colorController.dispose();
    termSlugController.dispose();
    termNameController.dispose();
    errorStreamValue.dispose();
    successMessageStreamValue.dispose();
    actionErrorMessageStreamValue.dispose();
    detailTermStreamValue.dispose();
    detailTermSavingStreamValue.dispose();
    taxonomyAppliesToSelectionStreamValue.dispose();
    isTaxonomySlugAutoEnabledStreamValue.dispose();
    isTermSlugAutoEnabledStreamValue.dispose();
  }

  @override
  void onDispose() {
    dispose();
  }
}
