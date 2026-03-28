import 'dart:async';

import 'package:belluga_now/domain/repositories/tenant_admin_static_assets_repository_contract.dart';
import 'package:belluga_now/domain/repositories/tenant_admin_taxonomies_repository_contract.dart';
import 'package:belluga_now/domain/services/tenant_admin_tenant_scope_contract.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_poi_visual.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_static_profile_type.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_definition.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_hex_color_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_required_text_value.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/utils/tenant_admin_type_poi_visual_requests.dart';
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
    _bindRepositoryStreams();
  }

  final TenantAdminStaticAssetsRepositoryContract _repository;
  final TenantAdminTaxonomiesRepositoryContract _taxonomiesRepository;
  final TenantAdminTenantScopeContract? _tenantScope;
  StreamValue<List<TenantAdminStaticProfileTypeDefinition>?>
      get typesStreamValue => _repository.staticProfileTypesStreamValue;
  final StreamValue<bool> hasMoreTypesStreamValue =
      StreamValue<bool>(defaultValue: true);
  final StreamValue<bool> isTypesPageLoadingStreamValue =
      StreamValue<bool>(defaultValue: false);
  final StreamValue<String?> errorStreamValue = StreamValue<String?>();
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

  static final TenantAdminStaticProfileTypeCapabilities _emptyCapabilities =
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
  final TextEditingController poiVisualIconController = TextEditingController();
  final TextEditingController poiVisualColorController =
      TextEditingController();
  final TextEditingController poiVisualIconColorController =
      TextEditingController();
  final ScrollController typesListScrollController = ScrollController();

  bool _isDisposed = false;
  bool _typesListScrollBound = false;
  StreamSubscription<String?>? _tenantScopeSubscription;
  StreamSubscription<TenantAdminStaticAssetsRepoBool>?
      _hasMoreTypesSubscription;
  StreamSubscription<TenantAdminStaticAssetsRepoBool>?
      _isTypesPageLoadingSubscription;
  StreamSubscription<TenantAdminStaticAssetsRepoString?>?
      _typesErrorSubscription;
  String? _lastTenantDomain;

  void _bindRepositoryStreams() {
    hasMoreTypesStreamValue
        .addValue(_repository.hasMoreStaticProfileTypesStreamValue.value.value);
    isTypesPageLoadingStreamValue.addValue(
      _repository.isStaticProfileTypesPageLoadingStreamValue.value.value,
    );
    errorStreamValue
        .addValue(_repository.staticProfileTypesErrorStreamValue.value?.value);

    _hasMoreTypesSubscription =
        _repository.hasMoreStaticProfileTypesStreamValue.stream.listen((value) {
      if (_isDisposed) return;
      hasMoreTypesStreamValue.addValue(value.value);
    });

    _isTypesPageLoadingSubscription = _repository
        .isStaticProfileTypesPageLoadingStreamValue.stream
        .listen((value) {
      if (_isDisposed) return;
      isTypesPageLoadingStreamValue.addValue(value.value);
    });

    _typesErrorSubscription =
        _repository.staticProfileTypesErrorStreamValue.stream.listen((value) {
      if (_isDisposed) return;
      errorStreamValue.addValue(value?.value);
    });
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
    final poiVisual = definition?.poiVisual;
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
    selectedTaxonomiesStreamValue.addValue(const {});
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
    await _repository.loadStaticProfileTypes();
    hasMoreTypesStreamValue
        .addValue(_repository.hasMoreStaticProfileTypesStreamValue.value.value);
    isTypesPageLoadingStreamValue.addValue(
      _repository.isStaticProfileTypesPageLoadingStreamValue.value.value,
    );
    errorStreamValue
        .addValue(_repository.staticProfileTypesErrorStreamValue.value?.value);
  }

  Future<void> loadNextTypesPage() async {
    if (_isDisposed) {
      return;
    }
    await _repository.loadNextStaticProfileTypesPage();
    hasMoreTypesStreamValue
        .addValue(_repository.hasMoreStaticProfileTypesStreamValue.value.value);
    isTypesPageLoadingStreamValue.addValue(
      _repository.isStaticProfileTypesPageLoadingStreamValue.value.value,
    );
    errorStreamValue
        .addValue(_repository.staticProfileTypesErrorStreamValue.value?.value);
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

  Future<void> loadTaxonomies() async {
    try {
      await _taxonomiesRepository.loadAllTaxonomies();
      final taxonomies = _taxonomiesRepository.taxonomiesStreamValue.value ??
          const <TenantAdminTaxonomyDefinition>[];
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
    TenantAdminPoiVisual? poiVisual,
    bool includePoiVisual = false,
  }) async {
    final created = await tenantAdminCreateTypeWithOptionalPoiVisual<
        TenantAdminStaticProfileTypeDefinition,
        TenantAdminStaticProfileTypeCapabilities,
        TenantAdminPoiVisual>(
      includePoiVisual: includePoiVisual,
      type: type,
      label: label,
      allowedTaxonomies: allowedTaxonomies,
      capabilities: capabilities,
      poiVisual: poiVisual,
      createWithoutPoiVisual: ({
        required String type,
        required String label,
        required List<String> allowedTaxonomies,
        required TenantAdminStaticProfileTypeCapabilities capabilities,
      }) {
        return _repository.createStaticProfileType(
          type: TenantAdminStaticAssetsRepoString.fromRaw(type),
          label: TenantAdminStaticAssetsRepoString.fromRaw(label),
          allowedTaxonomies: allowedTaxonomies
              .map(TenantAdminStaticAssetsRepoString.fromRaw)
              .toList(growable: false),
          capabilities: capabilities,
        );
      },
      createWithPoiVisual: ({
        required String type,
        required String label,
        required List<String> allowedTaxonomies,
        required TenantAdminStaticProfileTypeCapabilities capabilities,
        TenantAdminPoiVisual? poiVisual,
      }) {
        return _repository.createStaticProfileTypeWithPoiVisual(
          type: TenantAdminStaticAssetsRepoString.fromRaw(type),
          label: TenantAdminStaticAssetsRepoString.fromRaw(label),
          allowedTaxonomies: allowedTaxonomies
              .map(TenantAdminStaticAssetsRepoString.fromRaw)
              .toList(growable: false),
          capabilities: capabilities,
          poiVisual: poiVisual,
        );
      },
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
    TenantAdminPoiVisual? poiVisual,
    bool includePoiVisual = false,
  }) async {
    final updated = await tenantAdminUpdateTypeWithOptionalPoiVisual<
        TenantAdminStaticProfileTypeDefinition,
        TenantAdminStaticProfileTypeCapabilities,
        TenantAdminPoiVisual>(
      includePoiVisual: includePoiVisual,
      type: type,
      newType: newType,
      label: label,
      allowedTaxonomies: allowedTaxonomies,
      capabilities: capabilities,
      poiVisual: poiVisual,
      updateWithoutPoiVisual: ({
        required String type,
        String? newType,
        String? label,
        List<String>? allowedTaxonomies,
        TenantAdminStaticProfileTypeCapabilities? capabilities,
      }) {
        return _repository.updateStaticProfileType(
          type: TenantAdminStaticAssetsRepoString.fromRaw(type),
          newType: newType == null
              ? null
              : TenantAdminStaticAssetsRepoString.fromRaw(newType),
          label: label == null
              ? null
              : TenantAdminStaticAssetsRepoString.fromRaw(label),
          allowedTaxonomies: allowedTaxonomies
              ?.map(TenantAdminStaticAssetsRepoString.fromRaw)
              .toList(growable: false),
          capabilities: capabilities,
        );
      },
      updateWithPoiVisual: ({
        required String type,
        String? newType,
        String? label,
        List<String>? allowedTaxonomies,
        TenantAdminStaticProfileTypeCapabilities? capabilities,
        TenantAdminPoiVisual? poiVisual,
      }) {
        return _repository.updateStaticProfileTypeWithPoiVisual(
          type: TenantAdminStaticAssetsRepoString.fromRaw(type),
          newType: newType == null
              ? null
              : TenantAdminStaticAssetsRepoString.fromRaw(newType),
          label: label == null
              ? null
              : TenantAdminStaticAssetsRepoString.fromRaw(label),
          allowedTaxonomies: allowedTaxonomies
              ?.map(TenantAdminStaticAssetsRepoString.fromRaw)
              .toList(growable: false),
          capabilities: capabilities,
          poiVisual: poiVisual,
        );
      },
    );
    await loadTypes();
    return updated;
  }

  Future<void> deleteType(String type) async {
    await _repository.deleteStaticProfileType(
      TenantAdminStaticAssetsRepoString.fromRaw(type),
    );
    await loadTypes();
  }

  Future<int> previewDisableProjectionCount(String type) {
    return _repository
        .fetchStaticProfileTypeMapPoiProjectionImpact(
          type: TenantAdminStaticAssetsRepoString.fromRaw(type),
        )
        .then((value) => value.value);
  }

  Future<void> submitCreateType({
    required String type,
    required String label,
    List<String> allowedTaxonomies = const [],
    required TenantAdminStaticProfileTypeCapabilities capabilities,
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
    TenantAdminStaticProfileTypeCapabilities? capabilities,
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
    unbindTypesListScrollPagination();
    _tenantScopeSubscription?.cancel();
    _hasMoreTypesSubscription?.cancel();
    _isTypesPageLoadingSubscription?.cancel();
    _typesErrorSubscription?.cancel();
    typeController.dispose();
    labelController.dispose();
    poiVisualIconController.dispose();
    poiVisualColorController.dispose();
    poiVisualIconColorController.dispose();
    typesListScrollController.dispose();
    hasMoreTypesStreamValue.dispose();
    isTypesPageLoadingStreamValue.dispose();
    errorStreamValue.dispose();
    taxonomiesStreamValue.dispose();
    selectedTaxonomiesStreamValue.dispose();
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
