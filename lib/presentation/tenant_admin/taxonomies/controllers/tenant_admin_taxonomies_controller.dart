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
    _bindPaginationMirrors();
  }

  final TenantAdminTaxonomiesRepositoryContract _repository;
  final TenantAdminTenantScopeContract? _tenantScope;
  StreamValue<List<TenantAdminTaxonomyDefinition>?> get taxonomiesStreamValue =>
      _repository.taxonomiesStreamValue;
  final StreamValue<bool> hasMoreTaxonomiesStreamValue =
      StreamValue<bool>(defaultValue: false);
  final StreamValue<bool> isTaxonomiesPageLoadingStreamValue =
      StreamValue<bool>(defaultValue: false);
  StreamValue<List<TenantAdminTaxonomyTermDefinition>?> get termsStreamValue =>
      _repository.termsStreamValue;
  final StreamValue<bool> hasMoreTermsStreamValue =
      StreamValue<bool>(defaultValue: false);
  final StreamValue<bool> isTermsPageLoadingStreamValue =
      StreamValue<bool>(defaultValue: false);
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
  final ScrollController taxonomiesListScrollController = ScrollController();
  final ScrollController termsListScrollController = ScrollController();

  bool _isDisposed = false;
  bool _taxonomiesListScrollBound = false;
  bool _termsListScrollBound = false;
  StreamSubscription<String?>? _tenantScopeSubscription;
  StreamSubscription<TenantAdminTaxRepoBool>? _hasMoreTaxonomiesSubscription;
  StreamSubscription<TenantAdminTaxRepoBool>?
      _isTaxonomiesPageLoadingSubscription;
  StreamSubscription<TenantAdminTaxRepoBool>? _hasMoreTermsSubscription;
  StreamSubscription<TenantAdminTaxRepoBool>? _isTermsPageLoadingSubscription;
  String? _lastTenantDomain;
  String? _activeTaxonomyId;

  void _bindPaginationMirrors() {
    _syncPaginationMirrors();
    _hasMoreTaxonomiesSubscription ??=
        _repository.hasMoreTaxonomiesStreamValue.stream.listen((value) {
      if (_isDisposed) return;
      hasMoreTaxonomiesStreamValue.addValue(value.value);
    });
    _isTaxonomiesPageLoadingSubscription ??=
        _repository.isTaxonomiesPageLoadingStreamValue.stream.listen((value) {
      if (_isDisposed) return;
      isTaxonomiesPageLoadingStreamValue.addValue(value.value);
    });
    _hasMoreTermsSubscription ??=
        _repository.hasMoreTermsStreamValue.stream.listen((value) {
      if (_isDisposed) return;
      hasMoreTermsStreamValue.addValue(value.value);
    });
    _isTermsPageLoadingSubscription ??=
        _repository.isTermsPageLoadingStreamValue.stream.listen((value) {
      if (_isDisposed) return;
      isTermsPageLoadingStreamValue.addValue(value.value);
    });
  }

  void _syncPaginationMirrors() {
    hasMoreTaxonomiesStreamValue
        .addValue(_repository.hasMoreTaxonomiesStreamValue.value.value);
    isTaxonomiesPageLoadingStreamValue
        .addValue(_repository.isTaxonomiesPageLoadingStreamValue.value.value);
    hasMoreTermsStreamValue
        .addValue(_repository.hasMoreTermsStreamValue.value.value);
    isTermsPageLoadingStreamValue
        .addValue(_repository.isTermsPageLoadingStreamValue.value.value);
  }

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
    await _repository.loadTaxonomies();
    errorStreamValue
        .addValue(_repository.taxonomiesErrorStreamValue.value?.value);
    _syncPaginationMirrors();
  }

  Future<void> loadNextTaxonomiesPage() async {
    if (_isDisposed) {
      return;
    }
    await _repository.loadNextTaxonomiesPage();
    errorStreamValue
        .addValue(_repository.taxonomiesErrorStreamValue.value?.value);
    _syncPaginationMirrors();
  }

  Future<void> loadTerms(String taxonomyId) async {
    _activeTaxonomyId = taxonomyId;
    await _repository.loadTerms(
      taxonomyId: TenantAdminTaxRepoString.fromRaw(
        taxonomyId,
        defaultValue: '',
        isRequired: true,
      ),
    );
    errorStreamValue.addValue(_repository.termsErrorStreamValue.value?.value);
    _syncPaginationMirrors();
  }

  Future<void> loadNextTermsPage() async {
    final taxonomyId = _activeTaxonomyId;
    if (_isDisposed || taxonomyId == null || taxonomyId.isEmpty) {
      return;
    }
    await _repository.loadNextTermsPage();
    errorStreamValue.addValue(_repository.termsErrorStreamValue.value?.value);
    _syncPaginationMirrors();
  }

  void bindTaxonomiesListScrollPagination() {
    if (_taxonomiesListScrollBound) {
      return;
    }
    _taxonomiesListScrollBound = true;
    taxonomiesListScrollController.addListener(_handleTaxonomiesListScroll);
  }

  void unbindTaxonomiesListScrollPagination() {
    if (!_taxonomiesListScrollBound) {
      return;
    }
    _taxonomiesListScrollBound = false;
    taxonomiesListScrollController.removeListener(_handleTaxonomiesListScroll);
  }

  void bindTermsListScrollPagination() {
    if (_termsListScrollBound) {
      return;
    }
    _termsListScrollBound = true;
    termsListScrollController.addListener(_handleTermsListScroll);
  }

  void unbindTermsListScrollPagination() {
    if (!_termsListScrollBound) {
      return;
    }
    _termsListScrollBound = false;
    termsListScrollController.removeListener(_handleTermsListScroll);
  }

  void _handleTaxonomiesListScroll() {
    if (!taxonomiesListScrollController.hasClients) {
      return;
    }
    final position = taxonomiesListScrollController.position;
    const threshold = 320.0;
    if (position.pixels + threshold >= position.maxScrollExtent) {
      unawaited(loadNextTaxonomiesPage());
    }
  }

  void _handleTermsListScroll() {
    if (!termsListScrollController.hasClients) {
      return;
    }
    final position = termsListScrollController.position;
    const threshold = 320.0;
    if (position.pixels + threshold >= position.maxScrollExtent) {
      unawaited(loadNextTermsPage());
    }
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
        slug: TenantAdminTaxRepoString.fromRaw(
          slug,
          defaultValue: '',
          isRequired: true,
        ),
        name: TenantAdminTaxRepoString.fromRaw(
          name,
          defaultValue: '',
          isRequired: true,
        ),
        appliesTo: appliesTo
            .map(TenantAdminTaxRepoString.fromRaw)
            .toList(growable: false),
        icon: icon == null ? null : TenantAdminTaxRepoString.fromRaw(icon),
        color: color == null ? null : TenantAdminTaxRepoString.fromRaw(color),
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
        taxonomyId: TenantAdminTaxRepoString.fromRaw(
          taxonomyId,
          defaultValue: '',
          isRequired: true,
        ),
        slug: slug == null ? null : TenantAdminTaxRepoString.fromRaw(slug),
        name: name == null ? null : TenantAdminTaxRepoString.fromRaw(name),
        appliesTo: appliesTo
            ?.map(TenantAdminTaxRepoString.fromRaw)
            .toList(growable: false),
        icon: icon == null ? null : TenantAdminTaxRepoString.fromRaw(icon),
        color: color == null ? null : TenantAdminTaxRepoString.fromRaw(color),
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
      await _repository.deleteTaxonomy(
        TenantAdminTaxRepoString.fromRaw(
          taxonomyId,
          defaultValue: '',
          isRequired: true,
        ),
      );
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
        taxonomyId: TenantAdminTaxRepoString.fromRaw(
          taxonomyId,
          defaultValue: '',
          isRequired: true,
        ),
        slug: TenantAdminTaxRepoString.fromRaw(
          slug,
          defaultValue: '',
          isRequired: true,
        ),
        name: TenantAdminTaxRepoString.fromRaw(
          name,
          defaultValue: '',
          isRequired: true,
        ),
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
      taxonomyId: TenantAdminTaxRepoString.fromRaw(
        taxonomyId,
        defaultValue: '',
        isRequired: true,
      ),
      termId: TenantAdminTaxRepoString.fromRaw(
        termId,
        defaultValue: '',
        isRequired: true,
      ),
      slug: slug == null ? null : TenantAdminTaxRepoString.fromRaw(slug),
      name: name == null ? null : TenantAdminTaxRepoString.fromRaw(name),
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
        taxonomyId: TenantAdminTaxRepoString.fromRaw(
          taxonomyId,
          defaultValue: '',
          isRequired: true,
        ),
        termId: TenantAdminTaxRepoString.fromRaw(
          termId,
          defaultValue: '',
          isRequired: true,
        ),
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
        .addValue((taxonomy?.appliesTo ?? const <String>[]).toSet());
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
    _syncPaginationMirrors();
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
    unbindTaxonomiesListScrollPagination();
    unbindTermsListScrollPagination();
    _tenantScopeSubscription?.cancel();
    _hasMoreTaxonomiesSubscription?.cancel();
    _isTaxonomiesPageLoadingSubscription?.cancel();
    _hasMoreTermsSubscription?.cancel();
    _isTermsPageLoadingSubscription?.cancel();
    slugController.dispose();
    nameController.dispose();
    iconController.dispose();
    colorController.dispose();
    termSlugController.dispose();
    termNameController.dispose();
    taxonomiesListScrollController.dispose();
    termsListScrollController.dispose();
    errorStreamValue.dispose();
    successMessageStreamValue.dispose();
    actionErrorMessageStreamValue.dispose();
    detailTermStreamValue.dispose();
    detailTermSavingStreamValue.dispose();
    hasMoreTaxonomiesStreamValue.dispose();
    isTaxonomiesPageLoadingStreamValue.dispose();
    hasMoreTermsStreamValue.dispose();
    isTermsPageLoadingStreamValue.dispose();
    taxonomyAppliesToSelectionStreamValue.dispose();
    isTaxonomySlugAutoEnabledStreamValue.dispose();
    isTermSlugAutoEnabledStreamValue.dispose();
  }

  @override
  void onDispose() {
    dispose();
  }
}
