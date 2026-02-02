import 'package:belluga_now/domain/repositories/tenant_admin_organizations_repository_contract.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_organization.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart' show Disposable, GetIt;
import 'package:stream_value/core/stream_value.dart';

class TenantAdminOrganizationsController implements Disposable {
  TenantAdminOrganizationsController({
    TenantAdminOrganizationsRepositoryContract? organizationsRepository,
  }) : _organizationsRepository = organizationsRepository ??
            GetIt.I.get<TenantAdminOrganizationsRepositoryContract>();

  final TenantAdminOrganizationsRepositoryContract _organizationsRepository;

  final StreamValue<List<TenantAdminOrganization>> organizationsStreamValue =
      StreamValue<List<TenantAdminOrganization>>(defaultValue: const []);
  final StreamValue<bool> isLoadingStreamValue =
      StreamValue<bool>(defaultValue: false);
  final StreamValue<String?> errorStreamValue = StreamValue<String?>();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  bool _isDisposed = false;

  Future<void> loadOrganizations() async {
    isLoadingStreamValue.addValue(true);
    try {
      final orgs = await _organizationsRepository.fetchOrganizations();
      if (_isDisposed) return;
      organizationsStreamValue.addValue(orgs);
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

  Future<TenantAdminOrganization> createOrganization({
    required String name,
    String? description,
  }) async {
    final org = await _organizationsRepository.createOrganization(
      name: name,
      description: description,
    );
    await loadOrganizations();
    resetCreateForm();
    return org;
  }

  void resetCreateForm() {
    nameController.clear();
    descriptionController.clear();
  }

  void dispose() {
    _isDisposed = true;
    nameController.dispose();
    descriptionController.dispose();
    organizationsStreamValue.dispose();
    isLoadingStreamValue.dispose();
    errorStreamValue.dispose();
  }

  @override
  void onDispose() {
    dispose();
  }
}
