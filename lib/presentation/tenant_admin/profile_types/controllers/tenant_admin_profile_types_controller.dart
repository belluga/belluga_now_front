import 'package:belluga_now/domain/repositories/tenant_admin_account_profiles_repository_contract.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_profile_type.dart';
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
  final StreamValue<String?> errorStreamValue = StreamValue<String?>();

  bool _isDisposed = false;

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
    typesStreamValue.dispose();
    isLoadingStreamValue.dispose();
    errorStreamValue.dispose();
  }

  @override
  void onDispose() {
    dispose();
  }
}
