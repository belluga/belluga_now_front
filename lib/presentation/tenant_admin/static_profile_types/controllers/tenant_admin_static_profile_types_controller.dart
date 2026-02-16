import 'dart:async';

import 'package:belluga_now/domain/repositories/tenant_admin_static_assets_repository_contract.dart';
import 'package:belluga_now/domain/repositories/tenant_admin_taxonomies_repository_contract.dart';
import 'package:belluga_now/domain/services/tenant_admin_tenant_scope_contract.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_static_profile_type.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_definition.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart' show Disposable, GetIt;
import 'package:stream_value/core/stream_value.dart';

class TenantAdminStaticProfileTypesController implements Disposable {
  TenantAdminStaticProfileTypesController({
    TenantAdminStaticAssetsRepositoryContract? repository,
    TenantAdminTaxonomiesRepositoryContract? taxonomiesRepository,
    TenantAdminTenantScopeContract? tenantScope,
  })  : _repository = repository ??
            GetIt.I.get<TenantAdminStaticAssetsRepositoryContract>(),
        _taxonomiesRepository = taxonomiesRepository ??
            GetIt.I.get<TenantAdminTaxonomiesRepositoryContract>(),
        _tenantScope = tenantScope ??
            (GetIt.I.isRegistered<TenantAdminTenantScopeContract>()
                ? GetIt.I.get<TenantAdminTenantScopeContract>()
                : null) {
    _bindTenantScope();
  }

  final TenantAdminStaticAssetsRepositoryContract _repository;
  final TenantAdminTaxonomiesRepositoryContract _taxonomiesRepository;
  final TenantAdminTenantScopeContract? _tenantScope;
  static const int _typesPageSize = 20;

  StreamValue<List<TenantAdminStaticProfileTypeDefinition>?>
      get typesStreamValue => _repository.staticProfileTypesStreamValue;
  StreamValue<bool> get hasMoreTypesStreamValue =>
      _repository.hasMoreStaticProfileTypesStreamValue;
  StreamValue<bool> get isTypesPageLoadingStreamValue =>
      _repository.isStaticProfileTypesPageLoadingStreamValue;
  StreamValue<String?> get errorStreamValue =>
      _repository.staticProfileTypesErrorStreamValue;
  final StreamValue<List<TenantAdminTaxonomyDefinition>> taxonomiesStreamValue =
      StreamValue<List<TenantAdminTaxonomyDefinition>>(defaultValue: const []);
  final StreamValue<Set<String>> selectedTaxonomiesStreamValue =
      StreamValue<Set<String>>(defaultValue: const {});
  final StreamValue<String?> successMessageStreamValue = StreamValue<String?>();
  final StreamValue<String?> actionErrorMessageStreamValue =
      StreamValue<String?>();
  final StreamValue<TenantAdminStaticProfileTypeDefinition?>
      detailTypeStreamValue =
      StreamValue<TenantAdminStaticProfileTypeDefinition?>();
  final StreamValue<bool> detailSavingStreamValue =
      StreamValue<bool>(defaultValue: false);

  static const TenantAdminStaticProfileTypeCapabilities _emptyCapabilities =
      TenantAdminStaticProfileTypeCapabilities(
    isPoiEnabled: false,
    hasBio: false,
    hasTaxonomies: false,
    hasAvatar: false,
    hasCover: false,
    hasContent: false,
  );

  final StreamValue<TenantAdminStaticProfileTypeCapabilities>
      capabilitiesStreamValue =
      StreamValue<TenantAdminStaticProfileTypeCapabilities>(
    defaultValue: _emptyCapabilities,
  );
  final StreamValue<bool> isSlugAutoEnabledStreamValue =
      StreamValue<bool>(defaultValue: true);

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController typeController = TextEditingController();
  final TextEditingController labelController = TextEditingController();

  bool _isDisposed = false;
  StreamSubscription<String?>? _tenantScopeSubscription;
  String? _lastTenantDomain;

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
        _resetTenantScopedState();
        if (normalized != null) {
          unawaited(loadTypes());
          unawaited(loadTaxonomies());
        }
      },
    );
  }

  TenantAdminStaticProfileTypeCapabilities get currentCapabilities =>
      capabilitiesStreamValue.value;

  void initForm(TenantAdminStaticProfileTypeDefinition? definition) {
    final capabilities = definition?.capabilities ?? _emptyCapabilities;
    capabilitiesStreamValue.addValue(
      TenantAdminStaticProfileTypeCapabilities(
        isPoiEnabled: capabilities.isPoiEnabled,
        hasBio: capabilities.hasBio,
        hasTaxonomies: capabilities.hasTaxonomies,
        hasAvatar: capabilities.hasAvatar,
        hasCover: capabilities.hasCover,
        hasContent: capabilities.hasContent,
      ),
    );
    typeController.text = definition?.type ?? '';
    labelController.text = definition?.label ?? '';
    selectedTaxonomiesStreamValue.addValue(
      (definition?.allowedTaxonomies ?? const []).toSet(),
    );
    isSlugAutoEnabledStreamValue.addValue(true);
  }

  void resetFormState() {
    capabilitiesStreamValue.addValue(_emptyCapabilities);
    typeController.clear();
    labelController.clear();
    selectedTaxonomiesStreamValue.addValue(const {});
    isSlugAutoEnabledStreamValue.addValue(true);
  }

  bool get isSlugAutoEnabled => isSlugAutoEnabledStreamValue.value;

  void setSlugAutoEnabled(bool enabled) {
    isSlugAutoEnabledStreamValue.addValue(enabled);
  }

  void updateCapabilities({
    bool? isPoiEnabled,
    bool? hasBio,
    bool? hasTaxonomies,
    bool? hasAvatar,
    bool? hasCover,
    bool? hasContent,
  }) {
    final current = currentCapabilities;
    capabilitiesStreamValue.addValue(
      TenantAdminStaticProfileTypeCapabilities(
        isPoiEnabled: isPoiEnabled ?? current.isPoiEnabled,
        hasBio: hasBio ?? current.hasBio,
        hasTaxonomies: hasTaxonomies ?? current.hasTaxonomies,
        hasAvatar: hasAvatar ?? current.hasAvatar,
        hasCover: hasCover ?? current.hasCover,
        hasContent: hasContent ?? current.hasContent,
      ),
    );
  }

  void toggleTaxonomySelection(String slug, bool selected) {
    final current = Set<String>.from(selectedTaxonomiesStreamValue.value);
    if (selected) {
      current.add(slug);
    } else {
      current.remove(slug);
    }
    selectedTaxonomiesStreamValue.addValue(current);
  }

  Future<void> loadTypes() async {
    await _repository.loadStaticProfileTypes(pageSize: _typesPageSize);
  }

  Future<void> loadNextTypesPage() async {
    if (_isDisposed) {
      return;
    }
    await _repository.loadNextStaticProfileTypesPage(pageSize: _typesPageSize);
  }

  Future<void> loadTaxonomies() async {
    try {
      final taxonomies = await _taxonomiesRepository.fetchTaxonomies();
      final filtered = taxonomies
          .where((taxonomy) => taxonomy.appliesToTarget('static_asset'))
          .toList(growable: false);
      if (_isDisposed) return;
      taxonomiesStreamValue.addValue(filtered);
    } catch (error) {
      if (_isDisposed) return;
      actionErrorMessageStreamValue.addValue(error.toString());
    }
  }

  Future<TenantAdminStaticProfileTypeDefinition> createType({
    required String type,
    required String label,
    List<String> allowedTaxonomies = const [],
    required TenantAdminStaticProfileTypeCapabilities capabilities,
  }) async {
    final created = await _repository.createStaticProfileType(
      type: type,
      label: label,
      allowedTaxonomies: allowedTaxonomies,
      capabilities: capabilities,
    );
    await loadTypes();
    return created;
  }

  Future<TenantAdminStaticProfileTypeDefinition> updateType({
    required String type,
    String? newType,
    String? label,
    List<String>? allowedTaxonomies,
    TenantAdminStaticProfileTypeCapabilities? capabilities,
  }) async {
    final updated = await _repository.updateStaticProfileType(
      type: type,
      newType: newType,
      label: label,
      allowedTaxonomies: allowedTaxonomies,
      capabilities: capabilities,
    );
    await loadTypes();
    return updated;
  }

  Future<void> deleteType(String type) async {
    await _repository.deleteStaticProfileType(type);
    await loadTypes();
  }

  Future<void> submitCreateType({
    required String type,
    required String label,
    List<String> allowedTaxonomies = const [],
    required TenantAdminStaticProfileTypeCapabilities capabilities,
  }) async {
    try {
      await createType(
        type: type,
        label: label,
        allowedTaxonomies: allowedTaxonomies,
        capabilities: capabilities,
      );
      if (_isDisposed) return;
      actionErrorMessageStreamValue.addValue(null);
      successMessageStreamValue.addValue('Tipo criado.');
    } catch (error) {
      if (_isDisposed) return;
      actionErrorMessageStreamValue.addValue(error.toString());
    }
  }

  Future<void> submitUpdateType({
    required String type,
    String? newType,
    String? label,
    List<String>? allowedTaxonomies,
    TenantAdminStaticProfileTypeCapabilities? capabilities,
  }) async {
    try {
      await updateType(
        type: type,
        newType: newType,
        label: label,
        allowedTaxonomies: allowedTaxonomies,
        capabilities: capabilities,
      );
      if (_isDisposed) return;
      actionErrorMessageStreamValue.addValue(null);
      successMessageStreamValue.addValue('Tipo atualizado.');
    } catch (error) {
      if (_isDisposed) return;
      actionErrorMessageStreamValue.addValue(error.toString());
    }
  }

  Future<void> submitDeleteType(String type) async {
    try {
      await deleteType(type);
      if (_isDisposed) return;
      actionErrorMessageStreamValue.addValue(null);
      successMessageStreamValue.addValue('Tipo removido.');
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

  void initDetailType(TenantAdminStaticProfileTypeDefinition definition) {
    detailTypeStreamValue.addValue(definition);
    detailSavingStreamValue.addValue(false);
  }

  void clearDetailType() {
    detailTypeStreamValue.addValue(null);
    detailSavingStreamValue.addValue(false);
  }

  Future<TenantAdminStaticProfileTypeDefinition?> submitDetailTypeUpdate({
    required String type,
    String? newType,
    String? label,
  }) async {
    if (detailSavingStreamValue.value) {
      return null;
    }
    detailSavingStreamValue.addValue(true);
    try {
      final updated = await updateType(
        type: type,
        newType: newType,
        label: label,
      );
      if (_isDisposed) return null;
      detailTypeStreamValue.addValue(updated);
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
    _repository.resetStaticProfileTypesState();
    typesStreamValue.addValue(null);
    taxonomiesStreamValue.addValue(const []);
    successMessageStreamValue.addValue(null);
    actionErrorMessageStreamValue.addValue(null);
    resetFormState();
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
    typeController.dispose();
    labelController.dispose();
    taxonomiesStreamValue.dispose();
    selectedTaxonomiesStreamValue.dispose();
    successMessageStreamValue.dispose();
    actionErrorMessageStreamValue.dispose();
    detailTypeStreamValue.dispose();
    detailSavingStreamValue.dispose();
    capabilitiesStreamValue.dispose();
    isSlugAutoEnabledStreamValue.dispose();
  }

  @override
  void onDispose() {
    dispose();
  }
}
