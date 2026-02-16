import 'dart:async';

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
  })  : _repository = repository ??
            GetIt.I.get<TenantAdminStaticAssetsRepositoryContract>(),
        _taxonomiesRepository = taxonomiesRepository ??
            GetIt.I.get<TenantAdminTaxonomiesRepositoryContract>(),
        _locationSelection = locationSelection ??
            GetIt.I.get<TenantAdminLocationSelectionContract>(),
        _tenantScope = tenantScope ??
            (GetIt.I.isRegistered<TenantAdminTenantScopeContract>()
                ? GetIt.I.get<TenantAdminTenantScopeContract>()
                : null) {
    _bindTenantScope();
  }

  final TenantAdminStaticAssetsRepositoryContract _repository;
  final TenantAdminTaxonomiesRepositoryContract _taxonomiesRepository;
  final TenantAdminLocationSelectionContract _locationSelection;
  final TenantAdminTenantScopeContract? _tenantScope;
  static const int _assetsPageSize = 20;

  final StreamValue<List<TenantAdminStaticAsset>?> assetsStreamValue =
      StreamValue<List<TenantAdminStaticAsset>?>();
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
  final StreamValue<XFile?> avatarFileStreamValue = StreamValue<XFile?>();
  final StreamValue<XFile?> coverFileStreamValue = StreamValue<XFile?>();

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController displayNameController = TextEditingController();
  final TextEditingController bioController = TextEditingController();
  final TextEditingController contentController = TextEditingController();
  final TextEditingController avatarUrlController = TextEditingController();
  final TextEditingController coverUrlController = TextEditingController();
  final TextEditingController latitudeController = TextEditingController();
  final TextEditingController longitudeController = TextEditingController();

  bool _isDisposed = false;
  bool _isFetchingAssetsPage = false;
  bool _hasMoreAssets = true;
  int _currentAssetsPage = 0;
  final List<TenantAdminStaticAsset> _fetchedAssets =
      <TenantAdminStaticAsset>[];
  StreamSubscription<TenantAdminLocation?>? _locationSubscription;
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
    await _waitForAssetsFetch();
    _resetAssetsPagination();
    assetsStreamValue.addValue(null);
    await _fetchAssetsPage(page: 1);
  }

  Future<void> loadNextAssetsPage() async {
    if (_isDisposed || _isFetchingAssetsPage || !_hasMoreAssets) {
      return;
    }
    await _fetchAssetsPage(page: _currentAssetsPage + 1);
  }

  Future<void> _waitForAssetsFetch() async {
    while (_isFetchingAssetsPage && !_isDisposed) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
  }

  Future<void> _fetchAssetsPage({required int page}) async {
    if (_isFetchingAssetsPage) return;
    if (page > 1 && !_hasMoreAssets) return;

    _isFetchingAssetsPage = true;
    if (page > 1 && !_isDisposed) {
      isAssetsPageLoadingStreamValue.addValue(true);
    }
    isLoadingStreamValue.addValue(true);
    try {
      final result = await _repository.fetchStaticAssetsPage(
        page: page,
        pageSize: _assetsPageSize,
      );
      if (_isDisposed) return;
      if (page == 1) {
        _fetchedAssets
          ..clear()
          ..addAll(result.items);
      } else {
        _fetchedAssets.addAll(result.items);
      }
      _currentAssetsPage = page;
      _hasMoreAssets = result.hasMore;
      hasMoreAssetsStreamValue.addValue(_hasMoreAssets);
      assetsStreamValue
          .addValue(List<TenantAdminStaticAsset>.unmodifiable(_fetchedAssets));
      errorStreamValue.addValue(null);
    } catch (error) {
      if (_isDisposed) return;
      if (page == 1) {
        assetsStreamValue.addValue(const <TenantAdminStaticAsset>[]);
      }
      errorStreamValue.addValue(error.toString());
    } finally {
      _isFetchingAssetsPage = false;
      if (!_isDisposed) {
        isLoadingStreamValue.addValue(false);
        isAssetsPageLoadingStreamValue.addValue(false);
      }
    }
  }

  Future<void> loadProfileTypes() async {
    try {
      final types = await _repository.fetchStaticProfileTypes();
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
      final taxonomies = await _taxonomiesRepository.fetchTaxonomies();
      final filtered = taxonomies
          .where((taxonomy) => taxonomy.appliesToTarget('static_asset'))
          .toList(growable: false);
      if (_isDisposed) return;
      taxonomiesStreamValue.addValue(filtered);
      final entries = await Future.wait(
        filtered.map(
          (taxonomy) async => MapEntry(
            taxonomy.slug,
            await _taxonomiesRepository.fetchTerms(taxonomyId: taxonomy.id),
          ),
        ),
      );
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
      final asset = await _repository.fetchStaticAsset(assetId);
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
  }

  void updateAvatarFile(XFile? file) {
    avatarFileStreamValue.addValue(file);
    if (file != null) {
      avatarUrlController.clear();
    }
  }

  void updateCoverFile(XFile? file) {
    coverFileStreamValue.addValue(file);
    if (file != null) {
      coverUrlController.clear();
    }
  }

  void updateAvatarWebUrl(String? url) {
    avatarUrlController.text = (url ?? '').trim();
    if (avatarUrlController.text.isNotEmpty) {
      avatarFileStreamValue.addValue(null);
    }
  }

  void updateCoverWebUrl(String? url) {
    coverUrlController.text = (url ?? '').trim();
    if (coverUrlController.text.isNotEmpty) {
      coverFileStreamValue.addValue(null);
    }
  }

  void updateSelectedProfileType(String? profileType) {
    selectedProfileTypeStreamValue.addValue(profileType);
    _pruneTaxonomySelection();
  }

  void updateSearchQuery(String value) {
    searchQueryStreamValue.addValue(value);
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
      final avatarUpload =
          await _buildMediaUpload(avatarFileStreamValue.value);
      final coverUpload =
          await _buildMediaUpload(coverFileStreamValue.value);
      final created = await _repository.createStaticAsset(
        profileType: selectedProfileTypeStreamValue.value ?? '',
        displayName: displayNameController.text.trim(),
        location: _parseLocation(),
        taxonomyTerms: _buildTaxonomyTerms(),
        bio: bioController.text.trim().isEmpty
            ? null
            : bioController.text.trim(),
        content: contentController.text.trim().isEmpty
            ? null
            : contentController.text.trim(),
        avatarUrl: avatarUrlController.text.trim().isEmpty
            ? null
            : avatarUrlController.text.trim(),
        coverUrl: coverUrlController.text.trim().isEmpty
            ? null
            : coverUrlController.text.trim(),
        avatarUpload: avatarUpload,
        coverUpload: coverUpload,
      );
      if (_isDisposed) return;
      submitErrorStreamValue.addValue(null);
      submitSuccessStreamValue.addValue('Ativo criado.');
      final nextAssets = [..._fetchedAssets, created];
      _fetchedAssets
        ..clear()
        ..addAll(nextAssets);
      assetsStreamValue.addValue(
        List<TenantAdminStaticAsset>.unmodifiable(nextAssets),
      );
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
      final avatarUpload =
          await _buildMediaUpload(avatarFileStreamValue.value);
      final coverUpload =
          await _buildMediaUpload(coverFileStreamValue.value);
      final updated = await _repository.updateStaticAsset(
        assetId: assetId,
        profileType: selectedProfileTypeStreamValue.value,
        displayName: displayNameController.text.trim(),
        location: _parseLocation(),
        taxonomyTerms: _buildTaxonomyTerms(),
        bio: bioController.text.trim().isEmpty
            ? null
            : bioController.text.trim(),
        content: contentController.text.trim().isEmpty
            ? null
            : contentController.text.trim(),
        avatarUrl: avatarUrlController.text.trim().isEmpty
            ? null
            : avatarUrlController.text.trim(),
        coverUrl: coverUrlController.text.trim().isEmpty
            ? null
            : coverUrlController.text.trim(),
        avatarUpload: avatarUpload,
        coverUpload: coverUpload,
      );
      if (_isDisposed) return;
      submitErrorStreamValue.addValue(null);
      submitSuccessStreamValue.addValue('Ativo atualizado.');
      _replaceAsset(updated);
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
      await _repository.deleteStaticAsset(assetId);
      if (_isDisposed) return;
      final nextAssets = _fetchedAssets
          .where((asset) => asset.id != assetId)
          .toList(growable: false);
      _fetchedAssets
        ..clear()
        ..addAll(nextAssets);
      assetsStreamValue.addValue(
        List<TenantAdminStaticAsset>.unmodifiable(nextAssets),
      );
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
        assetId: assetId,
        slug: slug,
      );
      if (_isDisposed) return false;
      submitErrorStreamValue.addValue(null);
      submitSuccessStreamValue.addValue('Slug do ativo atualizado.');
      _replaceAsset(updated);
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
    submitLoadingStreamValue.addValue(true);
    try {
      final updated = await _repository.updateStaticAsset(
        assetId: assetId,
        taxonomyTerms: _buildTaxonomyTerms(),
      );
      if (_isDisposed) return false;
      submitErrorStreamValue.addValue(null);
      _replaceAsset(updated);
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

  void _replaceAsset(TenantAdminStaticAsset updated) {
    final updatedList = _fetchedAssets
        .map((asset) => asset.id == updated.id ? updated : asset)
        .toList(growable: false);
    _fetchedAssets
      ..clear()
      ..addAll(updatedList);
    assetsStreamValue
        .addValue(List<TenantAdminStaticAsset>.unmodifiable(updatedList));
    editingAssetStreamValue.addValue(updated);
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
    latitudeController.clear();
    longitudeController.clear();
    selectedProfileTypeStreamValue.addValue(null);
    selectedTaxonomyTermsStreamValue.addValue(const {});
    clearSubmitMessages();
  }

  void _resetTenantScopedState() {
    _resetAssetsPagination();
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

  void _resetAssetsPagination() {
    _fetchedAssets.clear();
    _currentAssetsPage = 0;
    _hasMoreAssets = true;
    _isFetchingAssetsPage = false;
    hasMoreAssetsStreamValue.addValue(true);
    isAssetsPageLoadingStreamValue.addValue(false);
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
    _locationSubscription?.cancel();
    _tenantScopeSubscription?.cancel();
    displayNameController.dispose();
    bioController.dispose();
    contentController.dispose();
    avatarUrlController.dispose();
    coverUrlController.dispose();
    latitudeController.dispose();
    longitudeController.dispose();
    assetsStreamValue.dispose();
    hasMoreAssetsStreamValue.dispose();
    isAssetsPageLoadingStreamValue.dispose();
    profileTypesStreamValue.dispose();
    taxonomiesStreamValue.dispose();
    taxonomyTermsStreamValue.dispose();
    selectedTaxonomyTermsStreamValue.dispose();
    selectedProfileTypeStreamValue.dispose();
    editingAssetStreamValue.dispose();
    isLoadingStreamValue.dispose();
    errorStreamValue.dispose();
    taxonomyLoadingStreamValue.dispose();
    taxonomyErrorStreamValue.dispose();
    submitLoadingStreamValue.dispose();
    submitErrorStreamValue.dispose();
    submitSuccessStreamValue.dispose();
    searchQueryStreamValue.dispose();
    avatarFileStreamValue.dispose();
    coverFileStreamValue.dispose();
  }
}
