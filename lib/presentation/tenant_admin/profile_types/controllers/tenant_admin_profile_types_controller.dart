import 'package:belluga_now/domain/repositories/tenant_admin_account_profiles_repository_contract.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_profile_type.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart' show Disposable, GetIt;
import 'package:stream_value/core/stream_value.dart';

class TenantAdminProfileTypesController implements Disposable {
  TenantAdminProfileTypesController({
    TenantAdminAccountProfilesRepositoryContract? repository,
  }) : _repository =
            repository ?? GetIt.I.get<TenantAdminAccountProfilesRepositoryContract>();

  final TenantAdminAccountProfilesRepositoryContract _repository;

  final StreamValue<List<TenantAdminProfileTypeDefinition>> typesStreamValue =
      StreamValue<List<TenantAdminProfileTypeDefinition>>(defaultValue: const []);
  final StreamValue<bool> isLoadingStreamValue =
      StreamValue<bool>(defaultValue: false);
  static const TenantAdminProfileTypeCapabilities _emptyCapabilities =
      TenantAdminProfileTypeCapabilities(
    isFavoritable: false,
    isPoiEnabled: false,
    hasBio: false,
    hasTaxonomies: false,
    hasAvatar: false,
    hasCover: false,
    hasEvents: false,
  );
  final StreamValue<String?> errorStreamValue = StreamValue<String?>();
  final StreamValue<TenantAdminProfileTypeCapabilities>
      capabilitiesStreamValue =
      StreamValue<TenantAdminProfileTypeCapabilities>(
    defaultValue: _emptyCapabilities,
  );
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController typeController = TextEditingController();
  final TextEditingController labelController = TextEditingController();
  final TextEditingController taxonomiesController = TextEditingController();

  bool _isDisposed = false;

  TenantAdminProfileTypeCapabilities get currentCapabilities =>
      capabilitiesStreamValue.value;

  void initForm(TenantAdminProfileTypeDefinition? definition) {
    final capabilities = definition?.capabilities ?? _emptyCapabilities;
    capabilitiesStreamValue.addValue(capabilities);
    typeController.text = definition?.type ?? '';
    labelController.text = definition?.label ?? '';
    taxonomiesController.text =
        (definition?.allowedTaxonomies ?? const []).join(', ');
  }

  void resetFormState() {
    capabilitiesStreamValue.addValue(_emptyCapabilities);
    typeController.clear();
    labelController.clear();
    taxonomiesController.clear();
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
        hasTaxonomies: hasTaxonomies ?? current.hasTaxonomies,
        hasAvatar: hasAvatar ?? current.hasAvatar,
        hasCover: hasCover ?? current.hasCover,
        hasEvents: hasEvents ?? current.hasEvents,
      ),
    );
  }

  Future<void> loadTypes() async {
    isLoadingStreamValue.addValue(true);
    try {
      final types = await _repository.fetchProfileTypes();
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

  void dispose() {
    _isDisposed = true;
    typeController.dispose();
    labelController.dispose();
    taxonomiesController.dispose();
    typesStreamValue.dispose();
    isLoadingStreamValue.dispose();
    errorStreamValue.dispose();
    capabilitiesStreamValue.dispose();
  }

  @override
  void onDispose() {
    dispose();
  }
}
