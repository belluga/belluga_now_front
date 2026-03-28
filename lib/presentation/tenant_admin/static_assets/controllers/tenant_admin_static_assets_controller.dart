import 'dart:async';
import 'dart:typed_data';

import 'package:belluga_now/domain/repositories/tenant_admin_static_assets_repository_contract.dart';
import 'package:belluga_now/domain/repositories/tenant_admin_taxonomies_repository_contract.dart';
import 'package:belluga_now/domain/services/tenant_admin_location_selection_contract.dart';
import 'package:belluga_now/domain/services/tenant_admin_tenant_scope_contract.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_location.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_media_upload.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_static_asset.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_static_profile_type.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_definition.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_term.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_term_definition.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/utils/tenant_admin_form_value_utils.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/utils/tenant_admin_image_ingestion_service.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart' show Disposable, GetIt;
import 'package:image_picker/image_picker.dart';
import 'package:stream_value/core/stream_value.dart';

class TenantAdminStaticAssetsController implements Disposable {
  TenantAdminStaticAssetsController({
    TenantAdminStaticAssetsRepositoryContract? repository,
    TenantAdminTaxonomiesRepositoryContract? taxonomiesRepository,
    TenantAdminLocationSelectionContract? locationSelection,
    TenantAdminTenantScopeContract? tenantScope,
    TenantAdminImageIngestionService? imageIngestionService,
  })  : _repository = repository ??
            GetIt.I.get<TenantAdminStaticAssetsRepositoryContract>(),
        _taxonomiesRepository = taxonomiesRepository ??
            GetIt.I.get<TenantAdminTaxonomiesRepositoryContract>(),
        _locationSelection = locationSelection ??
            GetIt.I.get<TenantAdminLocationSelectionContract>(),
        _tenantScope = tenantScope ??
            (GetIt.I.isRegistered<TenantAdminTenantScopeContract>()
                ? GetIt.I.get<TenantAdminTenantScopeContract>()
                : null),
        _imageIngestionService = imageIngestionService ??
            (GetIt.I.isRegistered<TenantAdminImageIngestionService>()
                ? GetIt.I.get<TenantAdminImageIngestionService>()
                : TenantAdminImageIngestionService()) {
    _bindTenantScope();
    _bindRepositoryStreams();
  }

  final TenantAdminStaticAssetsRepositoryContract _repository;
  final TenantAdminTaxonomiesRepositoryContract _taxonomiesRepository;
  final TenantAdminLocationSelectionContract _locationSelection;
  final TenantAdminTenantScopeContract? _tenantScope;
  final TenantAdminImageIngestionService _imageIngestionService;
  StreamValue<List<TenantAdminStaticAsset>?> get assetsStreamValue =>
      _repository.staticAssetsStreamValue;
  final StreamValue<bool> hasMoreAssetsStreamValue =
      StreamValue<bool>(defaultValue: true);
  final StreamValue<bool> isAssetsPageLoadingStreamValue =
      StreamValue<bool>(defaultValue: false);
  final StreamValue<List<TenantAdminStaticProfileTypeDefinition>>
      profileTypesStreamValue =
      StreamValue<List<TenantAdminStaticProfileTypeDefinition>>(
    defaultValue: const [],
  );
  final StreamValue<List<TenantAdminTaxonomyDefinition>> taxonomiesStreamValue =
      StreamValue<List<TenantAdminTaxonomyDefinition>>(defaultValue: const []);
  final StreamValue<Map<String, List<TenantAdminTaxonomyTermDefinition>>>
      taxonomyTermsStreamValue =
      StreamValue<Map<String, List<TenantAdminTaxonomyTermDefinition>>>(
    defaultValue: const {},
  );
  final StreamValue<Map<String, Set<String>>> selectedTaxonomyTermsStreamValue =
      StreamValue<Map<String, Set<String>>>(defaultValue: const {});
  final StreamValue<String?> selectedProfileTypeStreamValue =
      StreamValue<String?>(defaultValue: null);
  final StreamValue<TenantAdminStaticAsset?> editingAssetStreamValue =
      StreamValue<TenantAdminStaticAsset?>();
  final StreamValue<bool> isLoadingStreamValue =
      StreamValue<bool>(defaultValue: false);
  final StreamValue<String?> errorStreamValue = StreamValue<String?>();
  final StreamValue<bool> taxonomyLoadingStreamValue =
      StreamValue<bool>(defaultValue: false);
  final StreamValue<String?> taxonomyErrorStreamValue = StreamValue<String?>();
  final StreamValue<bool> submitLoadingStreamValue =
      StreamValue<bool>(defaultValue: false);
  final StreamValue<String?> submitErrorStreamValue = StreamValue<String?>();
  final StreamValue<String?> submitSuccessStreamValue = StreamValue<String?>();
  final StreamValue<String> searchQueryStreamValue =
      StreamValue<String>(defaultValue: '');
  final StreamValue<bool> showSearchFieldStreamValue =
      StreamValue<bool>(defaultValue: false);
  final StreamValue<String?> selectedTypeFilterStreamValue =
      StreamValue<String?>(defaultValue: null);
  final StreamValue<bool> taxonomyAutosavingStreamValue =
      StreamValue<bool>(defaultValue: false);
  final StreamValue<XFile?> avatarFileStreamValue = StreamValue<XFile?>();
  final StreamValue<XFile?> coverFileStreamValue = StreamValue<XFile?>();
  final StreamValue<bool> avatarBusyStreamValue =
      StreamValue<bool>(defaultValue: false);
  final StreamValue<bool> coverBusyStreamValue =
      StreamValue<bool>(defaultValue: false);

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController displayNameController = TextEditingController();
  final TextEditingController bioController = TextEditingController();
  final TextEditingController contentController = TextEditingController();
  final TextEditingController avatarUrlController = TextEditingController();
  final TextEditingController coverUrlController = TextEditingController();
  final TextEditingController latitudeController = TextEditingController();
  final TextEditingController longitudeController = TextEditingController();
  final ScrollController assetsListScrollController = ScrollController();

  bool _isDisposed = false;
  bool _assetsListScrollBound = false;
  bool _removeAvatarOnSubmit = false;
  bool _removeCoverOnSubmit = false;
  StreamSubscription<TenantAdminLocation?>? _locationSubscription;
  StreamSubscription<String?>? _tenantScopeSubscription;
  StreamSubscription<TenantAdminStaticAssetsRepoBool>?
      _hasMoreAssetsSubscription;
  StreamSubscription<TenantAdminStaticAssetsRepoBool>?
      _isAssetsPageLoadingSubscription;
  StreamSubscription<TenantAdminStaticAssetsRepoString?>?
      _staticAssetsErrorSubscription;
  String? _lastTenantDomain;

  void _bindRepositoryStreams() {
    hasMoreAssetsStreamValue
        .addValue(_repository.hasMoreStaticAssetsStreamValue.value.value);
    isAssetsPageLoadingStreamValue.addValue(
      _repository.isStaticAssetsPageLoadingStreamValue.value.value,
    );
    errorStreamValue.addValue(_repository.staticAssetsErrorStreamValue.value?.value);

    _hasMoreAssetsSubscription =
        _repository.hasMoreStaticAssetsStreamValue.stream.listen((value) {
      if (_isDisposed) {
        return;
      }
      hasMoreAssetsStreamValue.addValue(value.value);
    });

    _isAssetsPageLoadingSubscription = _repository
        .isStaticAssetsPageLoadingStreamValue.stream
        .listen((value) {
      if (_isDisposed) {
        return;
      }
      isAssetsPageLoadingStreamValue.addValue(value.value);
    });

    _staticAssetsErrorSubscription =
        _repository.staticAssetsErrorStreamValue.stream.listen((value) {
      if (_isDisposed) {
        return;
      }
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
        if (_isDisposed) {
          return;
        }
        final normalized = _normalizeTenantDomain(tenantDomain);
        if (normalized == _lastTenantDomain) {
          return;
        }
        _lastTenantDomain = normalized;
        _resetTenantScopedState();
        if (normalized != null) {
          unawaited(loadAssets());
        }
      },
    );
  }

  void _bindLocationSelection() {
    if (_locationSubscription != null) return;
    _locationSubscription =
        _locationSelection.confirmedLocationStreamValue.stream.listen(
      (location) {
        if (_isDisposed || location == null) return;
        latitudeController.text = location.latitude.toStringAsFixed(6);
        longitudeController.text = location.longitude.toStringAsFixed(6);
        _locationSelection.clearConfirmedLocation();
      },
    );
  }

  Future<void> loadAssets() async {
    await _repository.loadStaticAssets();
    errorStreamValue.addValue(_repository.staticAssetsErrorStreamValue.value?.value);
  }

  Future<void> loadNextAssetsPage() async {
    if (_isDisposed) {
      return;
    }
    await _repository.loadNextStaticAssetsPage();
    errorStreamValue.addValue(_repository.staticAssetsErrorStreamValue.value?.value);
  }

  void bindAssetsListScrollPagination() {
    if (_assetsListScrollBound) {
      return;
    }
    _assetsListScrollBound = true;
    assetsListScrollController.addListener(_handleAssetsListScroll);
  }

  void unbindAssetsListScrollPagination() {
    if (!_assetsListScrollBound) {
      return;
    }
    _assetsListScrollBound = false;
    assetsListScrollController.removeListener(_handleAssetsListScroll);
  }

  void _handleAssetsListScroll() {
    if (!assetsListScrollController.hasClients) {
      return;
    }
    final position = assetsListScrollController.position;
    const threshold = 320.0;
    if (position.pixels + threshold >= position.maxScrollExtent) {
      unawaited(loadNextAssetsPage());
    }
  }

  Future<void> loadProfileTypes() async {
    try {
      await _repository.loadAllStaticProfileTypes();
      final types = _repository.staticProfileTypesStreamValue.value ??
          const <TenantAdminStaticProfileTypeDefinition>[];
      if (_isDisposed) return;
      profileTypesStreamValue.addValue(types);
      errorStreamValue.addValue(null);
    } catch (error) {
      if (_isDisposed) return;
      errorStreamValue.addValue(error.toString());
    }
  }

  Future<void> loadTaxonomies() async {
    taxonomyLoadingStreamValue.addValue(true);
    try {
      await _taxonomiesRepository.loadAllTaxonomies();
      final taxonomies = _taxonomiesRepository.taxonomiesStreamValue.value ??
          const <TenantAdminTaxonomyDefinition>[];
      final filtered = taxonomies
          .where((taxonomy) => taxonomy.appliesToTarget('static_asset'))
          .toList(growable: false);
      if (_isDisposed) return;
      taxonomiesStreamValue.addValue(filtered);
      final entries =
          <MapEntry<String, List<TenantAdminTaxonomyTermDefinition>>>[];
      for (final taxonomy in filtered) {
        await _taxonomiesRepository.loadAllTerms(taxonomyId: taxonomy.id);
        final terms = _taxonomiesRepository.termsStreamValue.value ??
            const <TenantAdminTaxonomyTermDefinition>[];
        entries.add(MapEntry<String, List<TenantAdminTaxonomyTermDefinition>>(
          taxonomy.slug,
          terms,
        ));
      }
      if (_isDisposed) return;
      taxonomyTermsStreamValue.addValue({
        for (final entry in entries) entry.key: entry.value,
      });
      taxonomyErrorStreamValue.addValue(null);
    } catch (error) {
      if (_isDisposed) return;
      taxonomyErrorStreamValue.addValue(error.toString());
    } finally {
      if (!_isDisposed) {
        taxonomyLoadingStreamValue.addValue(false);
      }
    }
  }

  void initCreate() {
    _bindLocationSelection();
    _resetFormState();
    loadProfileTypes();
    loadTaxonomies();
  }

  Future<void> initEdit(String assetId) async {
    _bindLocationSelection();
    submitErrorStreamValue.addValue(null);
    submitSuccessStreamValue.addValue(null);
    await loadProfileTypes();
    await loadTaxonomies();
    await _loadAsset(assetId);
  }

  Future<void> _loadAsset(String assetId) async {
    isLoadingStreamValue.addValue(true);
    try {
      final asset = await _repository.fetchStaticAsset(
        TenantAdminStaticAssetsRepoString.fromRaw(assetId),
      );
      if (_isDisposed) return;
      editingAssetStreamValue.addValue(asset);
      _hydrateForm(asset);
    } catch (error) {
      if (_isDisposed) return;
      errorStreamValue.addValue(error.toString());
    } finally {
      if (!_isDisposed) {
        isLoadingStreamValue.addValue(false);
      }
    }
  }

  void _hydrateForm(TenantAdminStaticAsset asset) {
    displayNameController.text = asset.displayName;
    bioController.text = asset.bio ?? '';
    contentController.text = asset.content ?? '';
    avatarUrlController.text = asset.avatarUrl ?? '';
    coverUrlController.text = asset.coverUrl ?? '';
    avatarFileStreamValue.addValue(null);
    coverFileStreamValue.addValue(null);
    if (asset.location != null) {
      latitudeController.text = asset.location!.latitude.toStringAsFixed(6);
      longitudeController.text = asset.location!.longitude.toStringAsFixed(6);
    } else {
      latitudeController.clear();
      longitudeController.clear();
    }
    updateSelectedProfileType(asset.profileType);
    _applyTaxonomySelection(asset.taxonomyTerms);
    _removeAvatarOnSubmit = false;
    _removeCoverOnSubmit = false;
  }

  void updateAvatarFile(XFile? file) {
    avatarFileStreamValue.addValue(file);
    if (file != null) {
      avatarUrlController.clear();
      _removeAvatarOnSubmit = false;
    }
  }

  void updateCoverFile(XFile? file) {
    coverFileStreamValue.addValue(file);
    if (file != null) {
      coverUrlController.clear();
      _removeCoverOnSubmit = false;
    }
  }

  void updateAvatarBusy(bool isBusy) {
    avatarBusyStreamValue.addValue(isBusy);
  }

  void updateCoverBusy(bool isBusy) {
    coverBusyStreamValue.addValue(isBusy);
  }

  void updateAvatarWebUrl(String? url) {
    avatarUrlController.text = (url ?? '').trim();
    if (avatarUrlController.text.isNotEmpty) {
      avatarFileStreamValue.addValue(null);
      _removeAvatarOnSubmit = false;
    }
  }

  void updateCoverWebUrl(String? url) {
    coverUrlController.text = (url ?? '').trim();
    if (coverUrlController.text.isNotEmpty) {
      coverFileStreamValue.addValue(null);
      _removeCoverOnSubmit = false;
    }
  }

  void clearAvatarSelection({bool markForRemoval = false}) {
    updateAvatarFile(null);
    updateAvatarWebUrl(null);
    if (!markForRemoval) {
      _removeAvatarOnSubmit = false;
      return;
    }
    final hasPersistedAvatar =
        editingAssetStreamValue.value?.avatarUrl?.trim().isNotEmpty ?? false;
    _removeAvatarOnSubmit = hasPersistedAvatar;
  }

  void clearCoverSelection({bool markForRemoval = false}) {
    updateCoverFile(null);
    updateCoverWebUrl(null);
    if (!markForRemoval) {
      _removeCoverOnSubmit = false;
      return;
    }
    final hasPersistedCover =
        editingAssetStreamValue.value?.coverUrl?.trim().isNotEmpty ?? false;
    _removeCoverOnSubmit = hasPersistedCover;
  }

  void updateSelectedProfileType(String? profileType) {
    selectedProfileTypeStreamValue.addValue(profileType);
    _pruneTaxonomySelection();
  }

  void updateSearchQuery(String value) {
    searchQueryStreamValue.addValue(value);
  }

  void toggleSearchFieldVisibility() {
    final next = !showSearchFieldStreamValue.value;
    showSearchFieldStreamValue.addValue(next);
    if (!next) {
      updateSearchQuery('');
    }
  }

  void updateSelectedTypeFilter(String? profileType) {
    final normalized = profileType?.trim();
    if (normalized == null || normalized.isEmpty) {
      selectedTypeFilterStreamValue.addValue(null);
      return;
    }
    selectedTypeFilterStreamValue.addValue(normalized);
  }

  void updateTaxonomySelection({
    required String taxonomySlug,
    required String termSlug,
    required bool selected,
  }) {
    final current = Map<String, Set<String>>.from(
      selectedTaxonomyTermsStreamValue.value,
    );
    final terms = current[taxonomySlug] ?? <String>{};
    if (selected) {
      terms.add(termSlug);
    } else {
      terms.remove(termSlug);
    }
    if (terms.isEmpty) {
      current.remove(taxonomySlug);
    } else {
      current[taxonomySlug] = terms;
    }
    selectedTaxonomyTermsStreamValue.addValue(current);
  }

  void _applyTaxonomySelection(List<TenantAdminTaxonomyTerm> terms) {
    final map = <String, Set<String>>{};
    for (final term in terms) {
      final set = map.putIfAbsent(term.type, () => <String>{});
      set.add(term.value);
    }
    selectedTaxonomyTermsStreamValue.addValue(map);
  }

  void _pruneTaxonomySelection() {
    final allowed = _allowedTaxonomiesForSelectedType();
    if (allowed.isEmpty) {
      selectedTaxonomyTermsStreamValue.addValue(const {});
      return;
    }
    final current = Map<String, Set<String>>.from(
      selectedTaxonomyTermsStreamValue.value,
    );
    current.removeWhere((key, _) => !allowed.contains(key));
    selectedTaxonomyTermsStreamValue.addValue(current);
  }

  List<String> _allowedTaxonomiesForSelectedType() {
    final selectedType = selectedProfileTypeStreamValue.value;
    if (selectedType == null || selectedType.isEmpty) return const [];
    for (final definition in profileTypesStreamValue.value) {
      if (definition.type == selectedType) {
        return definition.allowedTaxonomies;
      }
    }
    return const [];
  }

  bool requiresLocation() {
    final selectedType = selectedProfileTypeStreamValue.value;
    if (selectedType == null || selectedType.isEmpty) return false;
    for (final definition in profileTypesStreamValue.value) {
      if (definition.type == selectedType) {
        return definition.capabilities.isPoiEnabled;
      }
    }
    return false;
  }

  Future<XFile?> pickImageFromDevice({
    required TenantAdminImageSlot slot,
  }) {
    return _imageIngestionService.pickFromDevice(slot: slot);
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

  TenantAdminLocation? _parseLocation() {
    final lat = tenantAdminParseLatitude(latitudeController.text);
    final lng = tenantAdminParseLongitude(longitudeController.text);
    if (lat == null || lng == null) return null;
    return TenantAdminLocation(latitude: lat, longitude: lng);
  }

  List<TenantAdminTaxonomyTerm> _buildTaxonomyTerms() {
    final selections = selectedTaxonomyTermsStreamValue.value;
    final terms = <TenantAdminTaxonomyTerm>[];
    selections.forEach((taxonomy, values) {
      for (final value in values) {
        terms.add(TenantAdminTaxonomyTerm(type: taxonomy, value: value));
      }
    });
    return terms;
  }

  Future<void> submitCreate() async {
    final form = formKey.currentState;
    if (form == null || !form.validate()) return;
    if (requiresLocation() && _parseLocation() == null) {
      submitErrorStreamValue.addValue('Localizacao obrigatoria.');
      return;
    }
    submitLoadingStreamValue.addValue(true);
    try {
      final avatarUpload = await _buildMediaUpload(avatarFileStreamValue.value);
      final coverUpload = await _buildMediaUpload(coverFileStreamValue.value);
      final created = await _repository.createStaticAsset(
        profileType: TenantAdminStaticAssetsRepoString.fromRaw(
          selectedProfileTypeStreamValue.value ?? '',
        ),
        displayName: TenantAdminStaticAssetsRepoString.fromRaw(
          displayNameController.text.trim(),
        ),
        location: _parseLocation(),
        taxonomyTerms: _buildTaxonomyTerms(),
        bio: bioController.text.trim().isEmpty
            ? null
            : TenantAdminStaticAssetsRepoString.fromRaw(
                bioController.text.trim(),
              ),
        content: contentController.text.trim().isEmpty
            ? null
            : TenantAdminStaticAssetsRepoString.fromRaw(
                contentController.text.trim(),
              ),
        avatarUrl: null,
        coverUrl: null,
        avatarUpload: avatarUpload,
        coverUpload: coverUpload,
      );
      if (_isDisposed) return;
      submitErrorStreamValue.addValue(null);
      submitSuccessStreamValue.addValue('Ativo criado.');
      await loadAssets();
      editingAssetStreamValue.addValue(created);
    } catch (error) {
      if (_isDisposed) return;
      submitErrorStreamValue.addValue(error.toString());
    } finally {
      if (!_isDisposed) {
        submitLoadingStreamValue.addValue(false);
      }
    }
  }

  Future<void> submitUpdate(String assetId) async {
    final form = formKey.currentState;
    if (form == null || !form.validate()) return;
    if (requiresLocation() && _parseLocation() == null) {
      submitErrorStreamValue.addValue('Localizacao obrigatoria.');
      return;
    }
    submitLoadingStreamValue.addValue(true);
    try {
      final avatarUpload = await _buildMediaUpload(avatarFileStreamValue.value);
      final coverUpload = await _buildMediaUpload(coverFileStreamValue.value);
      final updated = await _repository.updateStaticAsset(
        assetId: TenantAdminStaticAssetsRepoString.fromRaw(assetId),
        profileType: selectedProfileTypeStreamValue.value == null
            ? null
            : TenantAdminStaticAssetsRepoString.fromRaw(
                selectedProfileTypeStreamValue.value,
              ),
        displayName: TenantAdminStaticAssetsRepoString.fromRaw(
          displayNameController.text.trim(),
        ),
        location: _parseLocation(),
        taxonomyTerms: _buildTaxonomyTerms(),
        bio: bioController.text.trim().isEmpty
            ? null
            : TenantAdminStaticAssetsRepoString.fromRaw(
                bioController.text.trim(),
              ),
        content: contentController.text.trim().isEmpty
            ? null
            : TenantAdminStaticAssetsRepoString.fromRaw(
                contentController.text.trim(),
              ),
        avatarUrl: null,
        coverUrl: null,
        removeAvatar: TenantAdminStaticAssetsRepoBool.fromRaw(
          _removeAvatarOnSubmit,
        ),
        removeCover: TenantAdminStaticAssetsRepoBool.fromRaw(_removeCoverOnSubmit),
        avatarUpload: avatarUpload,
        coverUpload: coverUpload,
      );
      if (_isDisposed) return;
      submitErrorStreamValue.addValue(null);
      submitSuccessStreamValue.addValue('Ativo atualizado.');
      editingAssetStreamValue.addValue(updated);
      await loadAssets();
    } catch (error) {
      if (_isDisposed) return;
      submitErrorStreamValue.addValue(error.toString());
    } finally {
      if (!_isDisposed) {
        submitLoadingStreamValue.addValue(false);
      }
    }
  }

  Future<void> deleteAsset(String assetId) async {
    try {
      await _repository.deleteStaticAsset(
        TenantAdminStaticAssetsRepoString.fromRaw(assetId),
      );
      if (_isDisposed) return;
      await loadAssets();
    } catch (error) {
      if (_isDisposed) return;
      errorStreamValue.addValue(error.toString());
    }
  }

  Future<bool> submitSlugUpdate({
    required String assetId,
    required String slug,
  }) async {
    submitLoadingStreamValue.addValue(true);
    try {
      final updated = await _repository.updateStaticAsset(
        assetId: TenantAdminStaticAssetsRepoString.fromRaw(assetId),
        slug: TenantAdminStaticAssetsRepoString.fromRaw(slug),
      );
      if (_isDisposed) return false;
      submitErrorStreamValue.addValue(null);
      submitSuccessStreamValue.addValue('Slug do ativo atualizado.');
      editingAssetStreamValue.addValue(updated);
      await loadAssets();
      return true;
    } catch (error) {
      if (_isDisposed) return false;
      submitErrorStreamValue.addValue(error.toString());
      return false;
    } finally {
      if (!_isDisposed) {
        submitLoadingStreamValue.addValue(false);
      }
    }
  }

  Future<bool> submitTaxonomySelectionUpdate({
    required String assetId,
  }) async {
    taxonomyAutosavingStreamValue.addValue(true);
    submitLoadingStreamValue.addValue(true);
    try {
      final updated = await _repository.updateStaticAsset(
        assetId: TenantAdminStaticAssetsRepoString.fromRaw(assetId),
        taxonomyTerms: _buildTaxonomyTerms(),
      );
      if (_isDisposed) return false;
      submitErrorStreamValue.addValue(null);
      editingAssetStreamValue.addValue(updated);
      await loadAssets();
      return true;
    } catch (error) {
      if (_isDisposed) return false;
      submitErrorStreamValue.addValue(error.toString());
      return false;
    } finally {
      if (!_isDisposed) {
        submitLoadingStreamValue.addValue(false);
        taxonomyAutosavingStreamValue.addValue(false);
      }
    }
  }

  void clearSubmitMessages() {
    submitErrorStreamValue.addValue(null);
    submitSuccessStreamValue.addValue(null);
  }

  void _resetFormState() {
    editingAssetStreamValue.addValue(null);
    displayNameController.clear();
    bioController.clear();
    contentController.clear();
    avatarUrlController.clear();
    coverUrlController.clear();
    avatarFileStreamValue.addValue(null);
    coverFileStreamValue.addValue(null);
    _removeAvatarOnSubmit = false;
    _removeCoverOnSubmit = false;
    latitudeController.clear();
    longitudeController.clear();
    selectedProfileTypeStreamValue.addValue(null);
    selectedTaxonomyTermsStreamValue.addValue(const {});
    selectedTypeFilterStreamValue.addValue(null);
    showSearchFieldStreamValue.addValue(false);
    taxonomyAutosavingStreamValue.addValue(false);
    clearSubmitMessages();
  }

  void _resetTenantScopedState() {
    _repository.resetStaticAssetsState();
    assetsStreamValue.addValue(null);
    profileTypesStreamValue.addValue(const []);
    taxonomiesStreamValue.addValue(const []);
    taxonomyTermsStreamValue.addValue(const {});
    selectedTaxonomyTermsStreamValue.addValue(const {});
    selectedProfileTypeStreamValue.addValue(null);
    editingAssetStreamValue.addValue(null);
    searchQueryStreamValue.addValue('');
    errorStreamValue.addValue(null);
    taxonomyErrorStreamValue.addValue(null);
    selectedTypeFilterStreamValue.addValue(null);
    showSearchFieldStreamValue.addValue(false);
    taxonomyAutosavingStreamValue.addValue(false);
    _resetFormState();
  }

  Future<TenantAdminMediaUpload?> _buildMediaUpload(XFile? file) async {
    if (file == null) {
      return null;
    }
    final bytes = await file.readAsBytes();
    return TenantAdminMediaUpload(
      bytes: bytes,
      fileName: file.name,
    );
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

  @override
  void onDispose() {
    _isDisposed = true;
    unbindAssetsListScrollPagination();
    _locationSubscription?.cancel();
    _tenantScopeSubscription?.cancel();
    _hasMoreAssetsSubscription?.cancel();
    _isAssetsPageLoadingSubscription?.cancel();
    _staticAssetsErrorSubscription?.cancel();
    displayNameController.dispose();
    bioController.dispose();
    contentController.dispose();
    avatarUrlController.dispose();
    coverUrlController.dispose();
    latitudeController.dispose();
    longitudeController.dispose();
    assetsListScrollController.dispose();
    profileTypesStreamValue.dispose();
    taxonomiesStreamValue.dispose();
    taxonomyTermsStreamValue.dispose();
    selectedTaxonomyTermsStreamValue.dispose();
    selectedProfileTypeStreamValue.dispose();
    editingAssetStreamValue.dispose();
    hasMoreAssetsStreamValue.dispose();
    isAssetsPageLoadingStreamValue.dispose();
    isLoadingStreamValue.dispose();
    errorStreamValue.dispose();
    taxonomyLoadingStreamValue.dispose();
    taxonomyErrorStreamValue.dispose();
    submitLoadingStreamValue.dispose();
    submitErrorStreamValue.dispose();
    submitSuccessStreamValue.dispose();
    searchQueryStreamValue.dispose();
    showSearchFieldStreamValue.dispose();
    selectedTypeFilterStreamValue.dispose();
    taxonomyAutosavingStreamValue.dispose();
    avatarFileStreamValue.dispose();
    coverFileStreamValue.dispose();
    avatarBusyStreamValue.dispose();
    coverBusyStreamValue.dispose();
  }
}
