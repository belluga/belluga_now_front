import 'dart:async';
import 'dart:typed_data';

import 'package:belluga_now/domain/repositories/tenant_admin_account_profiles_repository_contract.dart';
import 'package:belluga_now/domain/repositories/tenant_admin_taxonomies_repository_contract.dart';
import 'package:belluga_now/domain/services/tenant_admin_tenant_scope_contract.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_media_upload.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_poi_visual.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_profile_type.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_definition.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_hex_color_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_optional_url_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_required_text_value.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/utils/tenant_admin_image_ingestion_service.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart' show Disposable, GetIt;
import 'package:image_picker/image_picker.dart' show XFile;
import 'package:stream_value/core/stream_value.dart';

class TenantAdminProfileTypesController implements Disposable {
  TenantAdminProfileTypesController({
    TenantAdminAccountProfilesRepositoryContract? repository,
    TenantAdminTaxonomiesRepositoryContract? taxonomiesRepository,
    TenantAdminTenantScopeContract? tenantScope,
    TenantAdminImageIngestionService? imageIngestionService,
  })  : _repository = repository ??
            GetIt.I.get<TenantAdminAccountProfilesRepositoryContract>(),
        _taxonomiesRepository = taxonomiesRepository ??
            (GetIt.I.isRegistered<TenantAdminTaxonomiesRepositoryContract>()
                ? GetIt.I.get<TenantAdminTaxonomiesRepositoryContract>()
                : null),
        _tenantScope = tenantScope ??
            (GetIt.I.isRegistered<TenantAdminTenantScopeContract>()
                ? GetIt.I.get<TenantAdminTenantScopeContract>()
                : null),
        _imageIngestionService =
            imageIngestionService ?? TenantAdminImageIngestionService() {
    _bindRepositoryStreams();
    _bindTenantScope();
  }

  final TenantAdminAccountProfilesRepositoryContract _repository;
  final TenantAdminTaxonomiesRepositoryContract? _taxonomiesRepository;
  final TenantAdminTenantScopeContract? _tenantScope;
  final TenantAdminImageIngestionService _imageIngestionService;
  StreamValue<List<TenantAdminProfileTypeDefinition>?> get typesStreamValue =>
      _repository.profileTypesStreamValue;
  final StreamValue<bool> hasMoreTypesStreamValue =
      StreamValue<bool>(defaultValue: true);
  final StreamValue<bool> isTypesPageLoadingStreamValue =
      StreamValue<bool>(defaultValue: false);
  final StreamValue<String?> errorStreamValue = StreamValue<String?>();
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
    isFavoritable: TenantAdminFlagValue(false),
    isPoiEnabled: TenantAdminFlagValue(false),
    hasBio: TenantAdminFlagValue(false),
    hasContent: TenantAdminFlagValue(false),
    hasTaxonomies: TenantAdminFlagValue(true),
    hasAvatar: TenantAdminFlagValue(false),
    hasCover: TenantAdminFlagValue(false),
    hasEvents: TenantAdminFlagValue(false),
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
  final StreamValue<XFile?> typeAssetFileStreamValue =
      StreamValue<XFile?>(defaultValue: null);
  final StreamValue<String> typeAssetUrlStreamValue =
      StreamValue<String>(defaultValue: '');
  final StreamValue<bool> removeTypeAssetStreamValue =
      StreamValue<bool>(defaultValue: false);
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
  StreamSubscription<TenantAdminAccountProfilesRepoBool>?
      _hasMoreTypesSubscription;
  StreamSubscription<TenantAdminAccountProfilesRepoBool>?
      _isTypesPageLoadingSubscription;
  StreamSubscription<TenantAdminAccountProfilesRepoString?>?
      _typesErrorSubscription;
  String? _lastTenantDomain;

  void _bindRepositoryStreams() {
    hasMoreTypesStreamValue
        .addValue(_repository.hasMoreProfileTypesStreamValue.value.value);
    isTypesPageLoadingStreamValue
        .addValue(_repository.isProfileTypesPageLoadingStreamValue.value.value);
    errorStreamValue
        .addValue(_repository.profileTypesErrorStreamValue.value?.value);

    _hasMoreTypesSubscription =
        _repository.hasMoreProfileTypesStreamValue.stream.listen((value) {
      if (_isDisposed) return;
      hasMoreTypesStreamValue.addValue(value.value);
    });

    _isTypesPageLoadingSubscription =
        _repository.isProfileTypesPageLoadingStreamValue.stream.listen((value) {
      if (_isDisposed) return;
      isTypesPageLoadingStreamValue.addValue(value.value);
    });

    _typesErrorSubscription =
        _repository.profileTypesErrorStreamValue.stream.listen((value) {
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
    final visual = definition?.visual;
    final existingTypeAssetUrl =
        visual?.imageSource == TenantAdminPoiVisualImageSource.typeAsset
            ? _normalizeOptionalText(visual?.imageUrl)
            : null;
    capabilitiesStreamValue.addValue(
      TenantAdminProfileTypeCapabilities(
        isFavoritable: TenantAdminFlagValue(capabilities.isFavoritable),
        isPoiEnabled: TenantAdminFlagValue(capabilities.isPoiEnabled),
        hasBio: TenantAdminFlagValue(capabilities.hasBio),
        hasContent: TenantAdminFlagValue(capabilities.hasContent),
        hasTaxonomies: TenantAdminFlagValue(true),
        hasAvatar: TenantAdminFlagValue(capabilities.hasAvatar),
        hasCover: TenantAdminFlagValue(capabilities.hasCover),
        hasEvents: TenantAdminFlagValue(capabilities.hasEvents),
      ),
    );
    typeController.text = definition?.type ?? '';
    labelController.text = definition?.label ?? '';
    setAllowedTaxonomies(definition?.allowedTaxonomies ?? const []);
    typeAssetFileStreamValue.addValue(null);
    typeAssetUrlStreamValue.addValue(existingTypeAssetUrl ?? '');
    removeTypeAssetStreamValue.addValue(false);
    if (visual == null || visual.mode == TenantAdminPoiVisualMode.icon) {
      poiVisualModeStreamValue.addValue(TenantAdminPoiVisualMode.icon);
      poiVisualIconController.text = visual?.icon ?? 'place';
      poiVisualColorController.text = visual?.color ?? '#2563EB';
      poiVisualIconColorController.text = visual?.iconColor ?? '#FFFFFF';
      poiVisualImageSourceStreamValue.addValue(
        TenantAdminPoiVisualImageSource.avatar,
      );
    } else {
      poiVisualModeStreamValue.addValue(TenantAdminPoiVisualMode.image);
      poiVisualIconController.text = 'place';
      poiVisualColorController.text = '#2563EB';
      poiVisualIconColorController.text = '#FFFFFF';
      poiVisualImageSourceStreamValue.addValue(
        visual.imageSource ?? TenantAdminPoiVisualImageSource.avatar,
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
    typeAssetFileStreamValue.addValue(null);
    typeAssetUrlStreamValue.addValue('');
    removeTypeAssetStreamValue.addValue(false);
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
    if (source != TenantAdminPoiVisualImageSource.typeAsset) {
      removeTypeAssetStreamValue.addValue(false);
    }
  }

  TenantAdminPoiVisual? buildCurrentVisual() {
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
      imageUrlValue: currentPoiVisualImageSource ==
              TenantAdminPoiVisualImageSource.typeAsset
          ? _buildOptionalUrlValue(currentTypeAssetUrl)
          : null,
    );
  }

  @Deprecated('Use buildCurrentVisual instead.')
  TenantAdminPoiVisual? buildCurrentPoiVisual() => buildCurrentVisual();

  XFile? get currentTypeAssetFile => typeAssetFileStreamValue.value;

  String? get currentTypeAssetUrl {
    if (removeTypeAssetStreamValue.value) {
      return null;
    }
    return _normalizeOptionalText(typeAssetUrlStreamValue.value);
  }

  bool get isTypeAssetMarkedForRemoval => removeTypeAssetStreamValue.value;

  Future<XFile?> pickTypeAssetImageFromDevice() {
    return _imageIngestionService.pickFromDevice(
      slot: TenantAdminImageSlot.typeVisual,
    );
  }

  Future<XFile> fetchImageFromUrlForCrop({
    required String imageUrl,
  }) {
    return _imageIngestionService.fetchFromUrlForCrop(imageUrl: imageUrl);
  }

  Future<Uint8List> readImageBytesForCrop(XFile sourceFile) {
    return _imageIngestionService.readBytesForCrop(sourceFile);
  }

  Future<XFile> prepareCroppedImage(
    Uint8List croppedData, {
    required TenantAdminImageSlot slot,
  }) {
    return _imageIngestionService.prepareBytesAsXFile(
      croppedData,
      slot: slot,
      applyAspectCrop: false,
    );
  }

  Future<TenantAdminMediaUpload?> buildTypeAssetUpload() {
    return _imageIngestionService.buildUpload(
      currentTypeAssetFile,
      slot: TenantAdminImageSlot.typeVisual,
    );
  }

  void updateTypeAssetFile(XFile? file) {
    typeAssetFileStreamValue.addValue(file);
    if (file != null) {
      removeTypeAssetStreamValue.addValue(false);
    }
  }

  void clearTypeAssetSelection() {
    if (currentTypeAssetFile != null) {
      typeAssetFileStreamValue.addValue(null);
      return;
    }

    final hasExistingTypeAsset = currentTypeAssetUrl != null;
    if (!hasExistingTypeAsset) {
      removeTypeAssetStreamValue.addValue(false);
      return;
    }

    removeTypeAssetStreamValue.addValue(!removeTypeAssetStreamValue.value);
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
        isFavoritable:
            TenantAdminFlagValue(isFavoritable ?? current.isFavoritable),
        isPoiEnabled:
            TenantAdminFlagValue(isPoiEnabled ?? current.isPoiEnabled),
        hasBio: TenantAdminFlagValue(hasBio ?? current.hasBio),
        hasContent: TenantAdminFlagValue(hasContent ?? current.hasContent),
        hasTaxonomies: TenantAdminFlagValue(true),
        hasAvatar: TenantAdminFlagValue(hasAvatar ?? current.hasAvatar),
        hasCover: TenantAdminFlagValue(hasCover ?? current.hasCover),
        hasEvents: TenantAdminFlagValue(hasEvents ?? current.hasEvents),
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
          .where((taxonomy) => taxonomy.appliesToAccountProfile())
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
    TenantAdminPoiVisual? visual,
    TenantAdminMediaUpload? typeAssetUpload,
    bool includeVisual = false,
  }) async {
    final typeValue = tenantAdminAccountProfilesRepoString(
      type,
      defaultValue: '',
      isRequired: true,
    );
    final labelValue = tenantAdminAccountProfilesRepoString(
      label,
      defaultValue: '',
      isRequired: true,
    );
    final allowedTaxonomyValues = allowedTaxonomies
        .map(
          (entry) => tenantAdminAccountProfilesRepoString(
            entry,
            defaultValue: '',
            isRequired: true,
          ),
        )
        .toList(growable: false);

    final created = includeVisual
        ? await _repository.createProfileTypeWithVisual(
            type: typeValue,
            label: labelValue,
            allowedTaxonomies: allowedTaxonomyValues,
            capabilities: capabilities,
            visual: visual,
            typeAssetUpload: typeAssetUpload,
          )
        : await _repository.createProfileType(
            type: typeValue,
            label: labelValue,
            allowedTaxonomies: allowedTaxonomyValues,
            capabilities: capabilities,
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
    TenantAdminPoiVisual? visual,
    TenantAdminMediaUpload? typeAssetUpload,
    bool? removeTypeAsset,
    bool includeVisual = false,
  }) async {
    final typeValue = tenantAdminAccountProfilesRepoString(
      type,
      defaultValue: '',
      isRequired: true,
    );
    final newTypeValue = newType == null
        ? null
        : tenantAdminAccountProfilesRepoString(
            newType,
            defaultValue: '',
            isRequired: false,
          );
    final labelValue = label == null
        ? null
        : tenantAdminAccountProfilesRepoString(
            label,
            defaultValue: '',
            isRequired: false,
          );
    final allowedTaxonomyValues = allowedTaxonomies
        ?.map(
          (entry) => tenantAdminAccountProfilesRepoString(
            entry,
            defaultValue: '',
            isRequired: true,
          ),
        )
        .toList(growable: false);

    final updated = includeVisual
        ? await _repository.updateProfileTypeWithVisual(
            type: typeValue,
            newType: newTypeValue,
            label: labelValue,
            allowedTaxonomies: allowedTaxonomyValues,
            capabilities: capabilities,
            visual: visual,
            typeAssetUpload: typeAssetUpload,
            removeTypeAsset: removeTypeAsset == null
                ? null
                : tenantAdminAccountProfilesRepoBool(
                    removeTypeAsset,
                    defaultValue: false,
                  ),
          )
        : await _repository.updateProfileType(
            type: typeValue,
            newType: newTypeValue,
            label: labelValue,
            allowedTaxonomies: allowedTaxonomyValues,
            capabilities: capabilities,
          );
    await loadTypes();
    return updated;
  }

  Future<void> deleteType(String type) async {
    await _repository.deleteProfileType(
      tenantAdminAccountProfilesRepoString(
        type,
        defaultValue: '',
        isRequired: true,
      ),
    );
    await loadTypes();
  }

  Future<int> previewDisableProjectionCount(String type) async {
    final count = await _repository.fetchProfileTypeMapPoiProjectionImpact(
      type: tenantAdminAccountProfilesRepoString(
        type,
        defaultValue: '',
        isRequired: true,
      ),
    );
    return count.value;
  }

  Future<void> submitCreateType({
    required String type,
    required String label,
    List<String> allowedTaxonomies = const [],
    required TenantAdminProfileTypeCapabilities capabilities,
    TenantAdminPoiVisual? visual,
    TenantAdminMediaUpload? typeAssetUpload,
    bool includeVisual = false,
  }) async {
    try {
      await createType(
        type: type,
        label: label,
        allowedTaxonomies: allowedTaxonomies,
        capabilities: capabilities,
        visual: visual,
        typeAssetUpload: typeAssetUpload,
        includeVisual: includeVisual,
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
    TenantAdminPoiVisual? visual,
    TenantAdminMediaUpload? typeAssetUpload,
    bool? removeTypeAsset,
    bool includeVisual = false,
  }) async {
    try {
      final updated = await updateType(
        type: type,
        newType: newType,
        label: label,
        allowedTaxonomies: allowedTaxonomies,
        capabilities: capabilities,
        visual: visual,
        typeAssetUpload: typeAssetUpload,
        removeTypeAsset: removeTypeAsset,
        includeVisual: includeVisual,
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

  String? _normalizeOptionalText(Object? raw) {
    final value = raw?.toString().trim();
    if (value == null || value.isEmpty) {
      return null;
    }
    return value;
  }

  TenantAdminOptionalUrlValue? _buildOptionalUrlValue(String? raw) {
    final normalized = _normalizeOptionalText(raw);
    if (normalized == null) {
      return null;
    }
    final value = TenantAdminOptionalUrlValue();
    value.parse(normalized);
    return value;
  }

  void _resetTenantScopedState() {
    _repository.resetProfileTypesState();
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
    _hasMoreTypesSubscription?.cancel();
    _isTypesPageLoadingSubscription?.cancel();
    _typesErrorSubscription?.cancel();
    typeController.dispose();
    labelController.dispose();
    taxonomiesController.dispose();
    poiVisualIconController.dispose();
    poiVisualColorController.dispose();
    poiVisualIconColorController.dispose();
    typesListScrollController.dispose();
    hasMoreTypesStreamValue.dispose();
    isTypesPageLoadingStreamValue.dispose();
    errorStreamValue.dispose();
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
    typeAssetFileStreamValue.dispose();
    typeAssetUrlStreamValue.dispose();
    removeTypeAssetStreamValue.dispose();
  }

  @override
  void onDispose() {
    dispose();
  }
}
