import 'package:belluga_now/domain/repositories/tenant_admin_taxonomies_repository_contract.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_term_definition.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart' show Disposable, GetIt;
import 'package:stream_value/core/stream_value.dart';

class TenantAdminTaxonomyTermsController implements Disposable {
  TenantAdminTaxonomyTermsController({
    TenantAdminTaxonomiesRepositoryContract? repository,
  }) : _repository =
            repository ?? GetIt.I.get<TenantAdminTaxonomiesRepositoryContract>();

  final TenantAdminTaxonomiesRepositoryContract _repository;

  final StreamValue<List<TenantAdminTaxonomyTermDefinition>> termsStreamValue =
      StreamValue<List<TenantAdminTaxonomyTermDefinition>>(
          defaultValue: const []);
  final StreamValue<bool> isLoadingStreamValue =
      StreamValue<bool>(defaultValue: false);
  final StreamValue<String?> errorStreamValue = StreamValue<String?>();
  final StreamValue<String?> successMessageStreamValue = StreamValue<String?>();
  final StreamValue<String?> actionErrorMessageStreamValue =
      StreamValue<String?>();

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController slugController = TextEditingController();
  final TextEditingController nameController = TextEditingController();

  bool _isDisposed = false;

  void initForm(TenantAdminTaxonomyTermDefinition? term) {
    slugController.text = term?.slug ?? '';
    nameController.text = term?.name ?? '';
  }

  void resetForm() {
    slugController.clear();
    nameController.clear();
  }

  Future<void> loadTerms(String taxonomyId) async {
    isLoadingStreamValue.addValue(true);
    try {
      final terms = await _repository.fetchTerms(taxonomyId: taxonomyId);
      if (_isDisposed) return;
      termsStreamValue.addValue(terms);
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

  Future<TenantAdminTaxonomyTermDefinition> createTerm({
    required String taxonomyId,
    required String slug,
    required String name,
  }) async {
    final created = await _repository.createTerm(
      taxonomyId: taxonomyId,
      slug: slug,
      name: name,
    );
    await loadTerms(taxonomyId);
    return created;
  }

  Future<TenantAdminTaxonomyTermDefinition> updateTerm({
    required String taxonomyId,
    required String termId,
    String? slug,
    String? name,
  }) async {
    final updated = await _repository.updateTerm(
      taxonomyId: taxonomyId,
      termId: termId,
      slug: slug,
      name: name,
    );
    await loadTerms(taxonomyId);
    return updated;
  }

  Future<void> deleteTerm({
    required String taxonomyId,
    required String termId,
  }) async {
    await _repository.deleteTerm(taxonomyId: taxonomyId, termId: termId);
    await loadTerms(taxonomyId);
  }

  Future<void> submitCreateTerm({
    required String taxonomyId,
    required String slug,
    required String name,
  }) async {
    try {
      await createTerm(
        taxonomyId: taxonomyId,
        slug: slug,
        name: name,
      );
      if (_isDisposed) return;
      actionErrorMessageStreamValue.addValue(null);
      successMessageStreamValue.addValue('Termo criado.');
    } catch (error) {
      if (_isDisposed) return;
      actionErrorMessageStreamValue.addValue(error.toString());
    }
  }

  Future<void> submitUpdateTerm({
    required String taxonomyId,
    required String termId,
    String? slug,
    String? name,
  }) async {
    try {
      await updateTerm(
        taxonomyId: taxonomyId,
        termId: termId,
        slug: slug,
        name: name,
      );
      if (_isDisposed) return;
      actionErrorMessageStreamValue.addValue(null);
      successMessageStreamValue.addValue('Termo atualizado.');
    } catch (error) {
      if (_isDisposed) return;
      actionErrorMessageStreamValue.addValue(error.toString());
    }
  }

  Future<void> submitDeleteTerm({
    required String taxonomyId,
    required String termId,
  }) async {
    try {
      await deleteTerm(taxonomyId: taxonomyId, termId: termId);
      if (_isDisposed) return;
      actionErrorMessageStreamValue.addValue(null);
      successMessageStreamValue.addValue('Termo removido.');
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
    slugController.dispose();
    nameController.dispose();
    termsStreamValue.dispose();
    isLoadingStreamValue.dispose();
    errorStreamValue.dispose();
    successMessageStreamValue.dispose();
    actionErrorMessageStreamValue.dispose();
  }

  @override
  void onDispose() {
    dispose();
  }
}
