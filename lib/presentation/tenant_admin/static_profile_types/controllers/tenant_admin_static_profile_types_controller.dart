import 'package:belluga_now/domain/repositories/tenant_admin_static_assets_repository_contract.dart';
import 'package:belluga_now/domain/repositories/tenant_admin_taxonomies_repository_contract.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_static_profile_type.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart' show Disposable, GetIt;
import 'package:stream_value/core/stream_value.dart';

class TenantAdminStaticProfileTypesController implements Disposable {
  TenantAdminStaticProfileTypesController({
    TenantAdminStaticAssetsRepositoryContract? repository,
    TenantAdminTaxonomiesRepositoryContract? taxonomiesRepository,
  })  : _repository = repository ??
            GetIt.I.get<TenantAdminStaticAssetsRepositoryContract>(),
        _taxonomiesRepository = taxonomiesRepository ??
            GetIt.I.get<TenantAdminTaxonomiesRepositoryContract>();

  final TenantAdminStaticAssetsRepositoryContract _repository;
  final TenantAdminTaxonomiesRepositoryContract _taxonomiesRepository;

  final StreamValue<List<TenantAdminStaticProfileTypeDefinition>>
      typesStreamValue =
      StreamValue<List<TenantAdminStaticProfileTypeDefinition>>(
    defaultValue: const [],
  );
  final StreamValue<List<TenantAdminTaxonomy>> taxonomiesStreamValue =
      StreamValue<List<TenantAdminTaxonomy>>(defaultValue: const []);
  final StreamValue<Set<String>> selectedTaxonomiesStreamValue =
      StreamValue<Set<String>>(defaultValue: const {});
  final StreamValue<bool> isLoadingStreamValue =
      StreamValue<bool>(defaultValue: false);
  final StreamValue<String?> errorStreamValue = StreamValue<String?>();
  final StreamValue<String?> successMessageStreamValue = StreamValue<String?>();
  final StreamValue<String?> actionErrorMessageStreamValue =
      StreamValue<String?>();

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

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController typeController = TextEditingController();
  final TextEditingController labelController = TextEditingController();

  bool _isDisposed = false;

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
  }

  void resetFormState() {
    capabilitiesStreamValue.addValue(_emptyCapabilities);
    typeController.clear();
    labelController.clear();
    selectedTaxonomiesStreamValue.addValue(const {});
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
    isLoadingStreamValue.addValue(true);
    try {
      final types = await _repository.fetchStaticProfileTypes();
      if (_isDisposed) return;
      typesStreamValue.addValue(types);
      errorStreamValue.addValue(null);
    } catch (error) {
      if (_isDisposed) return;
      errorStreamValue.addValue(error.toString());
    } finally {
      if (!_isDisposed) {
        isLoadingStreamValue.addValue(false);
      }
    }
  }

  Future<void> loadTaxonomies() async {
    try {
      final taxonomies = await _taxonomiesRepository.fetchTaxonomies();
      final filtered = taxonomies
          .where((taxonomy) => taxonomy.appliesTo.contains('static_asset'))
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
    String? label,
    List<String>? allowedTaxonomies,
    TenantAdminStaticProfileTypeCapabilities? capabilities,
  }) async {
    final updated = await _repository.updateStaticProfileType(
      type: type,
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
    String? label,
    List<String>? allowedTaxonomies,
    TenantAdminStaticProfileTypeCapabilities? capabilities,
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

  void dispose() {
    _isDisposed = true;
    typeController.dispose();
    labelController.dispose();
    typesStreamValue.dispose();
    taxonomiesStreamValue.dispose();
    selectedTaxonomiesStreamValue.dispose();
    isLoadingStreamValue.dispose();
    errorStreamValue.dispose();
    successMessageStreamValue.dispose();
    actionErrorMessageStreamValue.dispose();
    capabilitiesStreamValue.dispose();
  }

  @override
  void onDispose() {
    dispose();
  }
}
