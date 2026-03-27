import 'dart:async';

import 'package:belluga_now/domain/repositories/tenant_admin_account_profiles_repository_contract.dart';
import 'package:belluga_now/domain/repositories/tenant_admin_taxonomies_repository_contract.dart';
import 'package:belluga_now/domain/services/tenant_admin_tenant_scope_contract.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_poi_visual.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_profile_type.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_definition.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_hex_color_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_required_text_value.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/utils/tenant_admin_type_poi_visual_requests.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart' show Disposable, GetIt;
import 'package:stream_value/core/stream_value.dart';

class TenantAdminProfileTypesController implements Disposable {
  TenantAdminProfileTypesController({
    TenantAdminAccountProfilesRepositoryContract? repository,
    TenantAdminTaxonomiesRepositoryContract? taxonomiesRepository,
    TenantAdminTenantScopeContract? tenantScope,
  })  : _repository = repository ??
            GetIt.I.get<TenantAdminAccountProfilesRepositoryContract>(),
        _taxonomiesRepository = taxonomiesRepository ??
            (GetIt.I.isRegistered<TenantAdminTaxonomiesRepositoryContract>()
                ? GetIt.I.get<TenantAdminTaxonomiesRepositoryContract>()
                : null),
        _tenantScope = tenantScope ??
            (GetIt.I.isRegistered<TenantAdminTenantScopeContract>()
                ? GetIt.I.get<TenantAdminTenantScopeContract>()
                : null) {
    _bindTenantScope();
  }

  final TenantAdminAccountProfilesRepositoryContract _repository;
  final TenantAdminTaxonomiesRepositoryContract? _taxonomiesRepository;
  final TenantAdminTenantScopeContract? _tenantScope;
  StreamValue<List<TenantAdminProfileTypeDefinition>?> get typesStreamValue =>
      _repository.profileTypesStreamValue;
  StreamValue<bool> get hasMoreTypesStreamValue =>
      _repository.hasMoreProfileTypesStreamValue;
  StreamValue<bool> get isTypesPageLoadingStreamValue =>
      _repository.isProfileTypesPageLoadingStreamValue;
  StreamValue<String?> get errorStreamValue =>
      _repository.profileTypesErrorStreamValue;
  final StreamValue<List<TenantAdminTaxonomyDefinition>>
      availableTaxonomiesStreamValue =
      StreamValue<List<TenantAdminTaxonomyDefinition>>(defaultValue: const []);
  final StreamValue<List<String>> selectedAllowedTaxonomiesStreamValue =
      StreamValue<List<String>>(defaultValue: const []);
  final StreamValue<bool> isTaxonomiesLoadingStreamValue =
      StreamValue<bool>(defaultValue: false);
  final StreamValue<String?> taxonomiesErrorStreamValue =
      StreamValue<String?>();
  static final TenantAdminProfileTypeCapabilities _emptyCapabilities =
      TenantAdminProfileTypeCapabilities(
    isFavoritable: false,
    isPoiEnabled: false,
    hasBio: false,
    hasContent: false,
    hasTaxonomies: true,
    hasAvatar: false,
    hasCover: false,
    hasEvents: false,
  );
  final StreamValue<String?> successMessageStreamValue = StreamValue<String?>();
  final StreamValue<String?> actionErrorMessageStreamValue =
      StreamValue<String?>();
  final StreamValue<TenantAdminProfileTypeDefinition?> detailTypeStreamValue =
      StreamValue<TenantAdminProfileTypeDefinition?>();
  final StreamValue<bool> detailSavingStreamValue =
      StreamValue<bool>(defaultValue: false);
  final StreamValue<TenantAdminProfileTypeCapabilities>
      capabilitiesStreamValue = StreamValue<TenantAdminProfileTypeCapabilities>(
    defaultValue: _emptyCapabilities,
  );
  final StreamValue<bool> isSlugAutoEnabledStreamValue =
      StreamValue<bool>(defaultValue: true);
  final StreamValue<TenantAdminPoiVisualMode> poiVisualModeStreamValue =
      StreamValue<TenantAdminPoiVisualMode>(
    defaultValue: TenantAdminPoiVisualMode.icon,
  );
  final StreamValue<TenantAdminPoiVisualImageSource>
      poiVisualImageSourceStreamValue =
      StreamValue<TenantAdminPoiVisualImageSource>(
    defaultValue: TenantAdminPoiVisualImageSource.avatar,
  );
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController typeController = TextEditingController();
  final TextEditingController labelController = TextEditingController();
  final TextEditingController taxonomiesController = TextEditingController();
  final TextEditingController poiVisualIconController = TextEditingController();
  final TextEditingController poiVisualColorController =
      TextEditingController();
  final TextEditingController poiVisualIconColorController =
      TextEditingController();
  final ScrollController typesListScrollController = ScrollController();

  bool _isDisposed = false;
  bool _typesListScrollBound = false;
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
          unawaited(loadAvailableTaxonomies());
        }
      },
    );
  }

  TenantAdminProfileTypeCapabilities get currentCapabilities =>
      capabilitiesStreamValue.value;

  List<String> get selectedAllowedTaxonomies =>
      List<String>.unmodifiable(selectedAllowedTaxonomiesStreamValue.value);

  void initForm(TenantAdminProfileTypeDefinition? definition) {
    final capabilities = definition?.capabilities ?? _emptyCapabilities;
    final poiVisual = definition?.poiVisual;
    capabilitiesStreamValue.addValue(
      TenantAdminProfileTypeCapabilities(
        isFavoritable: capabilities.isFavoritable,
        isPoiEnabled: capabilities.isPoiEnabled,
        hasBio: capabilities.hasBio,
        hasContent: capabilities.hasContent,
        hasTaxonomies: true,
        hasAvatar: capabilities.hasAvatar,
        hasCover: capabilities.hasCover,
        hasEvents: capabilities.hasEvents,
      ),
    );
    typeController.text = definition?.type ?? '';
    labelController.text = definition?.label ?? '';
    setAllowedTaxonomies(definition?.allowedTaxonomies ?? const []);
    if (poiVisual == null || poiVisual.mode == TenantAdminPoiVisualMode.icon) {
      poiVisualModeStreamValue.addValue(TenantAdminPoiVisualMode.icon);
      poiVisualIconController.text = poiVisual?.icon ?? 'place';
      poiVisualColorController.text = poiVisual?.color ?? '#2563EB';
      poiVisualIconColorController.text = poiVisual?.iconColor ?? '#FFFFFF';
      poiVisualImageSourceStreamValue.addValue(
        TenantAdminPoiVisualImageSource.avatar,
      );
    } else {
      poiVisualModeStreamValue.addValue(TenantAdminPoiVisualMode.image);
      poiVisualIconController.text = 'place';
      poiVisualColorController.text = '#2563EB';
      poiVisualIconColorController.text = '#FFFFFF';
      poiVisualImageSourceStreamValue.addValue(
        poiVisual.imageSource ?? TenantAdminPoiVisualImageSource.avatar,
      );
    }
    isSlugAutoEnabledStreamValue.addValue(true);
  }

  void resetFormState() {
    capabilitiesStreamValue.addValue(_emptyCapabilities);
    typeController.clear();
    labelController.clear();
    taxonomiesController.clear();
    selectedAllowedTaxonomiesStreamValue.addValue(const []);
    poiVisualModeStreamValue.addValue(TenantAdminPoiVisualMode.icon);
    poiVisualImageSourceStreamValue.addValue(
      TenantAdminPoiVisualImageSource.avatar,
    );
    poiVisualIconController.text = 'place';
    poiVisualColorController.text = '#2563EB';
    poiVisualIconColorController.text = '#FFFFFF';
    isSlugAutoEnabledStreamValue.addValue(true);
  }

  bool get isSlugAutoEnabled => isSlugAutoEnabledStreamValue.value;

  void setSlugAutoEnabled(bool enabled) {
    isSlugAutoEnabledStreamValue.addValue(enabled);
  }

  TenantAdminPoiVisualMode get currentPoiVisualMode =>
      poiVisualModeStreamValue.value;

  TenantAdminPoiVisualImageSource get currentPoiVisualImageSource =>
      poiVisualImageSourceStreamValue.value;

  void updatePoiVisualMode(TenantAdminPoiVisualMode mode) {
    poiVisualModeStreamValue.addValue(mode);
  }

  void updatePoiVisualImageSource(TenantAdminPoiVisualImageSource source) {
    poiVisualImageSourceStreamValue.addValue(source);
  }

  TenantAdminPoiVisual? buildCurrentPoiVisual() {
    if (currentPoiVisualMode == TenantAdminPoiVisualMode.icon) {
      try {
        final iconValue = TenantAdminRequiredTextValue()
          ..parse(poiVisualIconController.text);
        final colorValue = TenantAdminHexColorValue()
          ..parse(poiVisualColorController.text);
        final iconColorValue = TenantAdminHexColorValue()
          ..parse(poiVisualIconColorController.text);
        final candidate = TenantAdminPoiVisual.icon(
          iconValue: iconValue,
          colorValue: colorValue,
          iconColorValue: iconColorValue,
        );
        return candidate.isValid ? candidate : null;
      } on Object {
        return null;
      }
    }

    return TenantAdminPoiVisual.image(
      imageSource: currentPoiVisualImageSource,
    );
  }

  void updateCapabilities({
    bool? isFavoritable,
    bool? isPoiEnabled,
    bool? hasBio,
    bool? hasContent,
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
        hasContent: hasContent ?? current.hasContent,
        hasTaxonomies: true,
        hasAvatar: hasAvatar ?? current.hasAvatar,
        hasCover: hasCover ?? current.hasCover,
        hasEvents: hasEvents ?? current.hasEvents,
      ),
    );
  }

  Future<void> loadTypes() async {
    await _repository.loadProfileTypes();
  }

  Future<void> loadAvailableTaxonomies() async {
    final repository = _taxonomiesRepository;
    if (repository == null) {
      availableTaxonomiesStreamValue.addValue(const []);
      taxonomiesErrorStreamValue
          .addValue('Repositório de taxonomias não registrado.');
      return;
    }
    isTaxonomiesLoadingStreamValue.addValue(true);
    try {
      await repository.loadAllTaxonomies();
      final loaded = repository.taxonomiesStreamValue.value ??
          const <TenantAdminTaxonomyDefinition>[];
      if (_isDisposed) return;
      final filtered = loaded
          .where((taxonomy) => taxonomy.appliesToTarget('account_profile'))
          .toList(growable: false)
        ..sort(
          (left, right) =>
              left.name.toLowerCase().compareTo(right.name.toLowerCase()),
        );
      availableTaxonomiesStreamValue.addValue(filtered);
      taxonomiesErrorStreamValue.addValue(null);
      _sanitizeSelectedTaxonomies();
    } catch (error) {
      if (_isDisposed) return;
      availableTaxonomiesStreamValue.addValue(const []);
      taxonomiesErrorStreamValue.addValue(error.toString());
      _setSelectedAllowedTaxonomies(const []);
    } finally {
      if (!_isDisposed) {
        isTaxonomiesLoadingStreamValue.addValue(false);
      }
    }
  }

  void toggleAllowedTaxonomy(String taxonomySlug) {
    final slug = taxonomySlug.trim();
    if (slug.isEmpty) {
      return;
    }
    final availableSlugs = availableTaxonomiesStreamValue.value
        .map((taxonomy) => taxonomy.slug)
        .toSet();
    if (!availableSlugs.contains(slug)) {
      return;
    }
    final current = selectedAllowedTaxonomiesStreamValue.value;
    final next = <String>[...current];
    if (next.contains(slug)) {
      next.remove(slug);
    } else {
      next.add(slug);
    }
    _setSelectedAllowedTaxonomies(next);
  }

  void setAllowedTaxonomies(List<String> slugs) {
    _setSelectedAllowedTaxonomies(slugs);
    _sanitizeSelectedTaxonomies();
  }

  Future<void> loadNextTypesPage() async {
    if (_isDisposed) {
      return;
    }
    await _repository.loadNextProfileTypesPage();
  }

  void bindTypesListScrollPagination() {
    if (_typesListScrollBound) {
      return;
    }
    _typesListScrollBound = true;
    typesListScrollController.addListener(_handleTypesListScroll);
  }

  void unbindTypesListScrollPagination() {
    if (!_typesListScrollBound) {
      return;
    }
    _typesListScrollBound = false;
    typesListScrollController.removeListener(_handleTypesListScroll);
  }

  void _handleTypesListScroll() {
    if (!typesListScrollController.hasClients) {
      return;
    }
    final position = typesListScrollController.position;
    const threshold = 320.0;
    if (position.pixels + threshold >= position.maxScrollExtent) {
      unawaited(loadNextTypesPage());
    }
  }

  Future<TenantAdminProfileTypeDefinition> createType({
    required String type,
    required String label,
    List<String> allowedTaxonomies = const [],
    required TenantAdminProfileTypeCapabilities capabilities,
    TenantAdminPoiVisual? poiVisual,
    bool includePoiVisual = false,
  }) async {
    final created = await tenantAdminCreateTypeWithOptionalPoiVisual<
        TenantAdminProfileTypeDefinition,
        TenantAdminProfileTypeCapabilities,
        TenantAdminPoiVisual>(
      includePoiVisual: includePoiVisual,
      type: type,
      label: label,
      allowedTaxonomies: allowedTaxonomies,
      capabilities: capabilities,
      poiVisual: poiVisual,
      createWithoutPoiVisual: _repository.createProfileType,
      createWithPoiVisual: _repository.createProfileTypeWithPoiVisual,
    );
    await loadTypes();
    return created;
  }

  Future<TenantAdminProfileTypeDefinition> updateType({
    required String type,
    String? newType,
    String? label,
    List<String>? allowedTaxonomies,
    TenantAdminProfileTypeCapabilities? capabilities,
    TenantAdminPoiVisual? poiVisual,
    bool includePoiVisual = false,
  }) async {
    final updated = await tenantAdminUpdateTypeWithOptionalPoiVisual<
        TenantAdminProfileTypeDefinition,
        TenantAdminProfileTypeCapabilities,
        TenantAdminPoiVisual>(
      includePoiVisual: includePoiVisual,
      type: type,
      newType: newType,
      label: label,
      allowedTaxonomies: allowedTaxonomies,
      capabilities: capabilities,
      poiVisual: poiVisual,
      updateWithoutPoiVisual: _repository.updateProfileType,
      updateWithPoiVisual: _repository.updateProfileTypeWithPoiVisual,
    );
    await loadTypes();
    return updated;
  }

  Future<void> deleteType(String type) async {
    await _repository.deleteProfileType(type);
    await loadTypes();
  }

  Future<int> previewDisableProjectionCount(String type) {
    return _repository.fetchProfileTypeMapPoiProjectionImpact(type: type);
  }

  Future<void> submitCreateType({
    required String type,
    required String label,
    List<String> allowedTaxonomies = const [],
    required TenantAdminProfileTypeCapabilities capabilities,
    TenantAdminPoiVisual? poiVisual,
    bool includePoiVisual = false,
  }) async {
    try {
      await createType(
        type: type,
        label: label,
        allowedTaxonomies: allowedTaxonomies,
        capabilities: capabilities,
        poiVisual: poiVisual,
        includePoiVisual: includePoiVisual,
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
    TenantAdminProfileTypeCapabilities? capabilities,
    TenantAdminPoiVisual? poiVisual,
    bool includePoiVisual = false,
  }) async {
    try {
      final updated = await updateType(
        type: type,
        newType: newType,
        label: label,
        allowedTaxonomies: allowedTaxonomies,
        capabilities: capabilities,
        poiVisual: poiVisual,
        includePoiVisual: includePoiVisual,
      );
      if (_isDisposed) return;
      final currentDetail = detailTypeStreamValue.value;
      if (currentDetail != null &&
          (currentDetail.type == type || currentDetail.type == updated.type)) {
        detailTypeStreamValue.addValue(updated);
      }
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
      if (detailTypeStreamValue.value?.type == type) {
        detailTypeStreamValue.addValue(null);
      }
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

  void initDetailType(TenantAdminProfileTypeDefinition definition) {
    detailTypeStreamValue.addValue(definition);
    detailSavingStreamValue.addValue(false);
  }

  void clearDetailType() {
    detailTypeStreamValue.addValue(null);
    detailSavingStreamValue.addValue(false);
  }

  Future<TenantAdminProfileTypeDefinition?> submitDetailTypeUpdate({
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
    _repository.resetProfileTypesState();
    typesStreamValue.addValue(null);
    successMessageStreamValue.addValue(null);
    actionErrorMessageStreamValue.addValue(null);
    availableTaxonomiesStreamValue.addValue(const []);
    taxonomiesErrorStreamValue.addValue(null);
    isTaxonomiesLoadingStreamValue.addValue(false);
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

  void _sanitizeSelectedTaxonomies() {
    final availableSlugs = availableTaxonomiesStreamValue.value
        .map((taxonomy) => taxonomy.slug)
        .toSet();
    if (availableSlugs.isEmpty) {
      _setSelectedAllowedTaxonomies(const []);
      return;
    }
    final sanitized = selectedAllowedTaxonomiesStreamValue.value
        .where(availableSlugs.contains)
        .toList(growable: false);
    _setSelectedAllowedTaxonomies(sanitized);
  }

  void _setSelectedAllowedTaxonomies(List<String> slugs) {
    final seen = <String>{};
    final normalized = <String>[];
    for (final raw in slugs) {
      final slug = raw.trim();
      if (slug.isEmpty || seen.contains(slug)) {
        continue;
      }
      seen.add(slug);
      normalized.add(slug);
    }
    selectedAllowedTaxonomiesStreamValue.addValue(normalized);
    taxonomiesController.text = normalized.join(', ');
  }

  void dispose() {
    _isDisposed = true;
    unbindTypesListScrollPagination();
    _tenantScopeSubscription?.cancel();
    typeController.dispose();
    labelController.dispose();
    taxonomiesController.dispose();
    poiVisualIconController.dispose();
    poiVisualColorController.dispose();
    poiVisualIconColorController.dispose();
    typesListScrollController.dispose();
    availableTaxonomiesStreamValue.dispose();
    selectedAllowedTaxonomiesStreamValue.dispose();
    isTaxonomiesLoadingStreamValue.dispose();
    taxonomiesErrorStreamValue.dispose();
    successMessageStreamValue.dispose();
    actionErrorMessageStreamValue.dispose();
    detailTypeStreamValue.dispose();
    detailSavingStreamValue.dispose();
    capabilitiesStreamValue.dispose();
    isSlugAutoEnabledStreamValue.dispose();
    poiVisualModeStreamValue.dispose();
    poiVisualImageSourceStreamValue.dispose();
  }

  @override
  void onDispose() {
    dispose();
  }
}
