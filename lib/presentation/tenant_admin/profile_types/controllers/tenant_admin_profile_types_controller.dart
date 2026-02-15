import 'dart:async';

import 'package:belluga_now/domain/repositories/tenant_admin_account_profiles_repository_contract.dart';
import 'package:belluga_now/domain/services/tenant_admin_tenant_scope_contract.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_profile_type.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart' show Disposable, GetIt;
import 'package:stream_value/core/stream_value.dart';

class TenantAdminProfileTypesController implements Disposable {
  TenantAdminProfileTypesController({
    TenantAdminAccountProfilesRepositoryContract? repository,
    TenantAdminTenantScopeContract? tenantScope,
  })  : _repository = repository ??
            GetIt.I.get<TenantAdminAccountProfilesRepositoryContract>(),
        _tenantScope = tenantScope ??
            (GetIt.I.isRegistered<TenantAdminTenantScopeContract>()
                ? GetIt.I.get<TenantAdminTenantScopeContract>()
                : null) {
    _bindTenantScope();
  }

  final TenantAdminAccountProfilesRepositoryContract _repository;
  final TenantAdminTenantScopeContract? _tenantScope;
  static const int _typesPageSize = 20;

  final StreamValue<List<TenantAdminProfileTypeDefinition>?> typesStreamValue =
      StreamValue<List<TenantAdminProfileTypeDefinition>?>();
  final StreamValue<bool> hasMoreTypesStreamValue =
      StreamValue<bool>(defaultValue: true);
  final StreamValue<bool> isTypesPageLoadingStreamValue =
      StreamValue<bool>(defaultValue: false);
  final StreamValue<bool> isLoadingStreamValue =
      StreamValue<bool>(defaultValue: false);
  static const TenantAdminProfileTypeCapabilities _emptyCapabilities =
      TenantAdminProfileTypeCapabilities(
    isFavoritable: false,
    isPoiEnabled: false,
    hasBio: false,
    hasTaxonomies: true,
    hasAvatar: false,
    hasCover: false,
    hasEvents: false,
  );
  final StreamValue<String?> errorStreamValue = StreamValue<String?>();
  final StreamValue<String?> successMessageStreamValue = StreamValue<String?>();
  final StreamValue<String?> actionErrorMessageStreamValue =
      StreamValue<String?>();
  final StreamValue<TenantAdminProfileTypeCapabilities>
      capabilitiesStreamValue = StreamValue<TenantAdminProfileTypeCapabilities>(
    defaultValue: _emptyCapabilities,
  );
  final StreamValue<bool> isSlugAutoEnabledStreamValue =
      StreamValue<bool>(defaultValue: true);
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController typeController = TextEditingController();
  final TextEditingController labelController = TextEditingController();
  final TextEditingController taxonomiesController = TextEditingController();

  bool _isDisposed = false;
  bool _isFetchingTypesPage = false;
  bool _hasMoreTypes = true;
  int _currentTypesPage = 0;
  final List<TenantAdminProfileTypeDefinition> _fetchedTypes =
      <TenantAdminProfileTypeDefinition>[];
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
        }
      },
    );
  }

  TenantAdminProfileTypeCapabilities get currentCapabilities =>
      capabilitiesStreamValue.value;

  void initForm(TenantAdminProfileTypeDefinition? definition) {
    final capabilities = definition?.capabilities ?? _emptyCapabilities;
    capabilitiesStreamValue.addValue(
      TenantAdminProfileTypeCapabilities(
        isFavoritable: capabilities.isFavoritable,
        isPoiEnabled: capabilities.isPoiEnabled,
        hasBio: capabilities.hasBio,
        hasTaxonomies: true,
        hasAvatar: capabilities.hasAvatar,
        hasCover: capabilities.hasCover,
        hasEvents: capabilities.hasEvents,
      ),
    );
    typeController.text = definition?.type ?? '';
    labelController.text = definition?.label ?? '';
    taxonomiesController.text =
        (definition?.allowedTaxonomies ?? const []).join(', ');
    isSlugAutoEnabledStreamValue.addValue(true);
  }

  void resetFormState() {
    capabilitiesStreamValue.addValue(_emptyCapabilities);
    typeController.clear();
    labelController.clear();
    taxonomiesController.clear();
    isSlugAutoEnabledStreamValue.addValue(true);
  }

  bool get isSlugAutoEnabled => isSlugAutoEnabledStreamValue.value;

  void setSlugAutoEnabled(bool enabled) {
    isSlugAutoEnabledStreamValue.addValue(enabled);
  }

  void updateCapabilities({
    bool? isFavoritable,
    bool? isPoiEnabled,
    bool? hasBio,
    bool? hasTaxonomies,
    bool? hasAvatar,
    bool? hasCover,
    bool? hasEvents,
  }) {
    final current = currentCapabilities;
    capabilitiesStreamValue.addValue(
      TenantAdminProfileTypeCapabilities(
        isFavoritable: isFavoritable ?? current.isFavoritable,
        isPoiEnabled: isPoiEnabled ?? current.isPoiEnabled,
        hasBio: hasBio ?? current.hasBio,
        hasTaxonomies: true,
        hasAvatar: hasAvatar ?? current.hasAvatar,
        hasCover: hasCover ?? current.hasCover,
        hasEvents: hasEvents ?? current.hasEvents,
      ),
    );
  }

  Future<void> loadTypes() async {
    await _waitForTypesFetch();
    _resetTypesPagination();
    typesStreamValue.addValue(null);
    await _fetchTypesPage(page: 1);
  }

  Future<void> loadNextTypesPage() async {
    if (_isDisposed || _isFetchingTypesPage || !_hasMoreTypes) {
      return;
    }
    await _fetchTypesPage(page: _currentTypesPage + 1);
  }

  Future<void> _waitForTypesFetch() async {
    while (_isFetchingTypesPage && !_isDisposed) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
  }

  Future<void> _fetchTypesPage({required int page}) async {
    if (_isFetchingTypesPage) return;
    if (page > 1 && !_hasMoreTypes) return;

    _isFetchingTypesPage = true;
    if (page > 1 && !_isDisposed) {
      isTypesPageLoadingStreamValue.addValue(true);
    }
    isLoadingStreamValue.addValue(true);
    try {
      final result = await _repository.fetchProfileTypesPage(
        page: page,
        pageSize: _typesPageSize,
      );
      if (_isDisposed) return;
      if (page == 1) {
        _fetchedTypes
          ..clear()
          ..addAll(result.items);
      } else {
        _fetchedTypes.addAll(result.items);
      }
      _currentTypesPage = page;
      _hasMoreTypes = result.hasMore;
      hasMoreTypesStreamValue.addValue(_hasMoreTypes);
      typesStreamValue
          .addValue(List<TenantAdminProfileTypeDefinition>.unmodifiable(_fetchedTypes));
      errorStreamValue.addValue(null);
    } catch (error) {
      if (_isDisposed) return;
      typesStreamValue.addValue(const <TenantAdminProfileTypeDefinition>[]);
      errorStreamValue.addValue(error.toString());
    } finally {
      _isFetchingTypesPage = false;
      if (!_isDisposed) {
        isLoadingStreamValue.addValue(false);
        isTypesPageLoadingStreamValue.addValue(false);
      }
    }
  }

  Future<TenantAdminProfileTypeDefinition> createType({
    required String type,
    required String label,
    List<String> allowedTaxonomies = const [],
    required TenantAdminProfileTypeCapabilities capabilities,
  }) async {
    final created = await _repository.createProfileType(
      type: type,
      label: label,
      allowedTaxonomies: allowedTaxonomies,
      capabilities: capabilities,
    );
    await loadTypes();
    return created;
  }

  Future<TenantAdminProfileTypeDefinition> updateType({
    required String type,
    String? label,
    List<String>? allowedTaxonomies,
    TenantAdminProfileTypeCapabilities? capabilities,
  }) async {
    final updated = await _repository.updateProfileType(
      type: type,
      label: label,
      allowedTaxonomies: allowedTaxonomies,
      capabilities: capabilities,
    );
    await loadTypes();
    return updated;
  }

  Future<void> deleteType(String type) async {
    await _repository.deleteProfileType(type);
    await loadTypes();
  }

  Future<void> submitCreateType({
    required String type,
    required String label,
    List<String> allowedTaxonomies = const [],
    required TenantAdminProfileTypeCapabilities capabilities,
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
    String? label,
    List<String>? allowedTaxonomies,
    TenantAdminProfileTypeCapabilities? capabilities,
  }) async {
    try {
      await updateType(
        type: type,
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

  void _resetTenantScopedState() {
    _resetTypesPagination();
    typesStreamValue.addValue(null);
    errorStreamValue.addValue(null);
    successMessageStreamValue.addValue(null);
    actionErrorMessageStreamValue.addValue(null);
    resetFormState();
  }

  void _resetTypesPagination() {
    _fetchedTypes.clear();
    _currentTypesPage = 0;
    _hasMoreTypes = true;
    _isFetchingTypesPage = false;
    hasMoreTypesStreamValue.addValue(true);
    isTypesPageLoadingStreamValue.addValue(false);
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
    taxonomiesController.dispose();
    typesStreamValue.dispose();
    hasMoreTypesStreamValue.dispose();
    isTypesPageLoadingStreamValue.dispose();
    isLoadingStreamValue.dispose();
    errorStreamValue.dispose();
    successMessageStreamValue.dispose();
    actionErrorMessageStreamValue.dispose();
    capabilitiesStreamValue.dispose();
    isSlugAutoEnabledStreamValue.dispose();
  }

  @override
  void onDispose() {
    dispose();
  }
}
