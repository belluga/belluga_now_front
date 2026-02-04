import 'package:belluga_now/domain/repositories/tenant_admin_taxonomies_repository_contract.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_definition.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_term_definition.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart' show Disposable, GetIt;
import 'package:stream_value/core/stream_value.dart';

class TenantAdminTaxonomiesController implements Disposable {
  TenantAdminTaxonomiesController({
    TenantAdminTaxonomiesRepositoryContract? repository,
  }) : _repository =
            repository ?? GetIt.I.get<TenantAdminTaxonomiesRepositoryContract>();

  final TenantAdminTaxonomiesRepositoryContract _repository;

  final StreamValue<List<TenantAdminTaxonomyDefinition>> taxonomiesStreamValue =
      StreamValue<List<TenantAdminTaxonomyDefinition>>(defaultValue: const []);
  final StreamValue<List<TenantAdminTaxonomyTermDefinition>>
      termsStreamValue =
      StreamValue<List<TenantAdminTaxonomyTermDefinition>>(defaultValue: const []);
  final StreamValue<bool> isLoadingStreamValue =
      StreamValue<bool>(defaultValue: false);
  final StreamValue<String?> errorStreamValue = StreamValue<String?>();
  final StreamValue<String?> successMessageStreamValue =
      StreamValue<String?>();
  final StreamValue<String?> actionErrorMessageStreamValue =
      StreamValue<String?>();

  final GlobalKey<FormState> taxonomyFormKey = GlobalKey<FormState>();
  final TextEditingController slugController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController iconController = TextEditingController();
  final TextEditingController colorController = TextEditingController();

  final GlobalKey<FormState> termFormKey = GlobalKey<FormState>();
  final TextEditingController termSlugController = TextEditingController();
  final TextEditingController termNameController = TextEditingController();

  bool _isDisposed = false;

  Future<void> loadTaxonomies() async {
    isLoadingStreamValue.addValue(true);
    try {
      final taxonomies = await _repository.fetchTaxonomies();
      if (_isDisposed) return;
      taxonomiesStreamValue.addValue(taxonomies);
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

  Future<void> submitCreateTaxonomy({
    required String slug,
    required String name,
    required List<String> appliesTo,
    String? icon,
    String? color,
  }) async {
    try {
      await _repository.createTaxonomy(
        slug: slug,
        name: name,
        appliesTo: appliesTo,
        icon: icon,
        color: color,
      );
      if (_isDisposed) return;
      successMessageStreamValue.addValue('Taxonomia criada.');
      await loadTaxonomies();
    } catch (error) {
      if (_isDisposed) return;
      actionErrorMessageStreamValue.addValue(error.toString());
    }
  }

  Future<void> submitUpdateTaxonomy({
    required String taxonomyId,
    String? slug,
    String? name,
    List<String>? appliesTo,
    String? icon,
    String? color,
  }) async {
    try {
      await _repository.updateTaxonomy(
        taxonomyId: taxonomyId,
        slug: slug,
        name: name,
        appliesTo: appliesTo,
        icon: icon,
        color: color,
      );
      if (_isDisposed) return;
      successMessageStreamValue.addValue('Taxonomia atualizada.');
      await loadTaxonomies();
    } catch (error) {
      if (_isDisposed) return;
      actionErrorMessageStreamValue.addValue(error.toString());
    }
  }

  Future<void> submitDeleteTaxonomy(String taxonomyId) async {
    try {
      await _repository.deleteTaxonomy(taxonomyId);
      if (_isDisposed) return;
      successMessageStreamValue.addValue('Taxonomia removida.');
      await loadTaxonomies();
    } catch (error) {
      if (_isDisposed) return;
      actionErrorMessageStreamValue.addValue(error.toString());
    }
  }

  Future<void> submitCreateTerm({
    required String taxonomyId,
    required String slug,
    required String name,
  }) async {
    try {
      await _repository.createTerm(
        taxonomyId: taxonomyId,
        slug: slug,
        name: name,
      );
      if (_isDisposed) return;
      successMessageStreamValue.addValue('Termo criado.');
      await loadTerms(taxonomyId);
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
      await _repository.updateTerm(
        taxonomyId: taxonomyId,
        termId: termId,
        slug: slug,
        name: name,
      );
      if (_isDisposed) return;
      successMessageStreamValue.addValue('Termo atualizado.');
      await loadTerms(taxonomyId);
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
      await _repository.deleteTerm(
        taxonomyId: taxonomyId,
        termId: termId,
      );
      if (_isDisposed) return;
      successMessageStreamValue.addValue('Termo removido.');
      await loadTerms(taxonomyId);
    } catch (error) {
      if (_isDisposed) return;
      actionErrorMessageStreamValue.addValue(error.toString());
    }
  }

  void initTaxonomyForm(TenantAdminTaxonomyDefinition? taxonomy) {
    slugController.text = taxonomy?.slug ?? '';
    nameController.text = taxonomy?.name ?? '';
    iconController.text = taxonomy?.icon ?? '';
    colorController.text = taxonomy?.color ?? '';
  }

  void resetTaxonomyForm() {
    slugController.clear();
    nameController.clear();
    iconController.clear();
    colorController.clear();
  }

  void initTermForm(TenantAdminTaxonomyTermDefinition? term) {
    termSlugController.text = term?.slug ?? '';
    termNameController.text = term?.name ?? '';
  }

  void resetTermForm() {
    termSlugController.clear();
    termNameController.clear();
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
    iconController.dispose();
    colorController.dispose();
    termSlugController.dispose();
    termNameController.dispose();
    taxonomiesStreamValue.dispose();
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
