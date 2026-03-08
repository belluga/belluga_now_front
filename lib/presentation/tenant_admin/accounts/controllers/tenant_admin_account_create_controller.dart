import 'dart:async';
import 'dart:typed_data';

import 'package:belluga_form_validation/belluga_form_validation.dart';
import 'package:belluga_now/domain/repositories/tenant_admin_account_profiles_repository_contract.dart';
import 'package:belluga_now/domain/repositories/tenant_admin_accounts_repository_contract.dart';
import 'package:belluga_now/domain/repositories/tenant_admin_taxonomies_repository_contract.dart';
import 'package:belluga_now/domain/tenant_admin/ownership_state.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_account_onboarding_result.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_location.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_media_upload.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_profile_type.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_definition.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_term.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_term_definition.dart';
import 'package:belluga_now/domain/services/tenant_admin_location_selection_contract.dart';
import 'package:belluga_now/presentation/tenant_admin/accounts/models/tenant_admin_account_create_validation_config.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/utils/tenant_admin_form_value_utils.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/utils/tenant_admin_image_ingestion_service.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart' show Disposable, GetIt;
import 'package:image_picker/image_picker.dart';
import 'package:stream_value/core/stream_value.dart';

class TenantAdminAccountCreateController implements Disposable {
  TenantAdminAccountCreateController({
    TenantAdminAccountsRepositoryContract? accountsRepository,
    TenantAdminAccountProfilesRepositoryContract? profilesRepository,
    TenantAdminTaxonomiesRepositoryContract? taxonomiesRepository,
    TenantAdminLocationSelectionContract? locationSelectionService,
    TenantAdminImageIngestionService? imageIngestionService,
  })  : _accountsRepository = accountsRepository ??
            GetIt.I.get<TenantAdminAccountsRepositoryContract>(),
        _profilesRepository = profilesRepository ??
            GetIt.I.get<TenantAdminAccountProfilesRepositoryContract>(),
        _taxonomiesRepository = taxonomiesRepository ??
            GetIt.I.get<TenantAdminTaxonomiesRepositoryContract>(),
        _locationSelectionService = locationSelectionService ??
            GetIt.I.get<TenantAdminLocationSelectionContract>(),
        _imageIngestionService = imageIngestionService ??
            (GetIt.I.isRegistered<TenantAdminImageIngestionService>()
                ? GetIt.I.get<TenantAdminImageIngestionService>()
                : TenantAdminImageIngestionService());

  final TenantAdminAccountsRepositoryContract _accountsRepository;
  final TenantAdminAccountProfilesRepositoryContract _profilesRepository;
  final TenantAdminTaxonomiesRepositoryContract _taxonomiesRepository;
  final TenantAdminLocationSelectionContract _locationSelectionService;
  final TenantAdminImageIngestionService _imageIngestionService;

  final StreamValue<List<TenantAdminProfileTypeDefinition>>
      profileTypesStreamValue =
      StreamValue<List<TenantAdminProfileTypeDefinition>>(
    defaultValue: const [],
  );
  final StreamValue<bool> isProfileTypesLoadingStreamValue =
      StreamValue<bool>(defaultValue: false);
  final StreamValue<String?> errorStreamValue = StreamValue<String?>();
  final StreamValue<bool> createSubmittingStreamValue =
      StreamValue<bool>(defaultValue: false);
  final StreamValue<String?> createErrorMessageStreamValue =
      StreamValue<String?>();
  final StreamValue<TenantAdminAccountOnboardingResult?>
      createSuccessAccountStreamValue =
      StreamValue<TenantAdminAccountOnboardingResult?>(defaultValue: null);
  final StreamValue<TenantAdminAccountCreateDraft> createStateStreamValue =
      StreamValue<TenantAdminAccountCreateDraft>(
    defaultValue: TenantAdminAccountCreateDraft.initial(),
  );
  final FormValidationControllerAdapter createValidationController =
      FormValidationControllerAdapter(
    config: tenantAdminAccountCreateValidationConfig,
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
  final StreamValue<bool> taxonomiesLoadingStreamValue =
      StreamValue<bool>(defaultValue: false);
  final StreamValue<String?> taxonomiesErrorStreamValue =
      StreamValue<String?>();
  final GlobalKey<FormState> createFormKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController bioController = TextEditingController();
  final TextEditingController contentController = TextEditingController();
  final TextEditingController latitudeController = TextEditingController();
  final TextEditingController longitudeController = TextEditingController();

  StreamValue<FormValidationState> get createValidationStreamValue =>
      createValidationController.stateStreamValue;

  bool _isDisposed = false;
  bool _createFieldListenersBound = false;
  StreamSubscription<TenantAdminLocation?>? _locationSelectionSubscription;

  void bindCreateFlow() {
    _bindLocationSelection();
    _bindCreateFieldListeners();
  }

  void _bindLocationSelection() {
    if (_locationSelectionSubscription != null) return;
    _locationSelectionSubscription =
        _locationSelectionService.confirmedLocationStreamValue.stream.listen(
      (location) {
        if (_isDisposed || location == null) return;
        latitudeController.text = location.latitude.toStringAsFixed(6);
        longitudeController.text = location.longitude.toStringAsFixed(6);
        _locationSelectionService.clearConfirmedLocation();
      },
    );
  }

  Future<void> loadProfileTypes() async {
    isProfileTypesLoadingStreamValue.addValue(true);
    try {
      final types = await _profilesRepository.fetchProfileTypes();
      if (_isDisposed) return;
      profileTypesStreamValue.addValue(types);
      errorStreamValue.addValue(null);
    } catch (error) {
      if (_isDisposed) return;
      errorStreamValue.addValue(error.toString());
    } finally {
      if (!_isDisposed) {
        isProfileTypesLoadingStreamValue.addValue(false);
      }
    }
  }

  Future<void> loadTaxonomies() async {
    taxonomiesLoadingStreamValue.addValue(true);
    try {
      final taxonomies = await _taxonomiesRepository.fetchTaxonomies();
      if (_isDisposed) return;
      final filtered = taxonomies
          .where((taxonomy) => taxonomy.appliesToTarget('account_profile'))
          .toList(growable: false);
      taxonomiesStreamValue.addValue(filtered);
      taxonomiesErrorStreamValue.addValue(null);
      await _refreshTaxonomyTermsForSelectedProfileType();
    } catch (error) {
      if (_isDisposed) return;
      taxonomiesErrorStreamValue.addValue(error.toString());
      taxonomyTermsStreamValue.addValue(const {});
    } finally {
      if (!_isDisposed) {
        taxonomiesLoadingStreamValue.addValue(false);
      }
    }
  }

  void updateCreateSelectedProfileType(String? profileType) {
    _updateCreateState(
      createStateStreamValue.value.copyWith(selectedProfileType: profileType),
    );
    clearCreateFieldValidation(
      TenantAdminAccountCreateValidationTargets.profileType,
    );
    clearCreateGroupValidation(
      TenantAdminAccountCreateValidationTargets.location,
    );
    clearCreateGroupValidation(
      TenantAdminAccountCreateValidationTargets.taxonomies,
    );
    clearCreateGroupValidation(
      TenantAdminAccountCreateValidationTargets.media,
    );
    clearCreateFieldValidation(TenantAdminAccountCreateValidationTargets.bio);
    clearCreateFieldValidation(
      TenantAdminAccountCreateValidationTargets.content,
    );
    unawaited(_refreshTaxonomyTermsForSelectedProfileType());
  }

  void updateCreateOwnershipState(TenantAdminOwnershipState ownershipState) {
    _updateCreateState(
      createStateStreamValue.value.copyWith(ownershipState: ownershipState),
    );
    clearCreateGroupValidation(
      TenantAdminAccountCreateValidationTargets.ownership,
    );
  }

  void updateCreateAvatarFile(XFile? file) {
    _updateCreateState(
      createStateStreamValue.value.copyWith(
        avatarFile: file,
        avatarWebUrl: null,
      ),
    );
    clearCreateGroupValidation(TenantAdminAccountCreateValidationTargets.media);
  }

  void updateCreateCoverFile(XFile? file) {
    _updateCreateState(
      createStateStreamValue.value.copyWith(
        coverFile: file,
        coverWebUrl: null,
      ),
    );
    clearCreateGroupValidation(TenantAdminAccountCreateValidationTargets.media);
  }

  void updateCreateAvatarBusy(bool isBusy) {
    _updateCreateState(
      createStateStreamValue.value.copyWith(avatarBusy: isBusy),
    );
  }

  void updateCreateCoverBusy(bool isBusy) {
    _updateCreateState(
      createStateStreamValue.value.copyWith(coverBusy: isBusy),
    );
  }

  void updateCreateAvatarWebUrl(String? url) {
    final trimmed = url?.trim();
    _updateCreateState(
      createStateStreamValue.value.copyWith(
        avatarWebUrl: trimmed == null || trimmed.isEmpty ? null : trimmed,
        avatarFile: null,
      ),
    );
    clearCreateGroupValidation(TenantAdminAccountCreateValidationTargets.media);
  }

  void updateCreateCoverWebUrl(String? url) {
    final trimmed = url?.trim();
    _updateCreateState(
      createStateStreamValue.value.copyWith(
        coverWebUrl: trimmed == null || trimmed.isEmpty ? null : trimmed,
        coverFile: null,
      ),
    );
    clearCreateGroupValidation(TenantAdminAccountCreateValidationTargets.media);
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
    clearCreateGroupValidation(
      TenantAdminAccountCreateValidationTargets.taxonomies,
    );
  }

  void resetCreateState() {
    clearCreateValidation();
    clearCreateSuccessAccount();
    _updateCreateState(TenantAdminAccountCreateDraft.initial());
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

  Future<TenantAdminMediaUpload?> buildImageUpload(
    XFile? file, {
    required TenantAdminImageSlot slot,
  }) {
    return _imageIngestionService.buildUpload(file, slot: slot);
  }

  Future<TenantAdminAccountOnboardingResult> createAccountOnboarding({
    required String name,
    required TenantAdminOwnershipState ownershipState,
    required String profileType,
    TenantAdminLocation? location,
    String? bio,
    String? content,
    List<TenantAdminTaxonomyTerm> taxonomyTerms = const [],
    TenantAdminMediaUpload? avatarUpload,
    TenantAdminMediaUpload? coverUpload,
  }) async {
    return _accountsRepository.createAccountOnboarding(
      name: name.trim(),
      ownershipState: ownershipState,
      profileType: profileType,
      location: location,
      taxonomyTerms: taxonomyTerms,
      bio: bio,
      content: content,
      avatarUpload: avatarUpload,
      coverUpload: coverUpload,
    );
  }

  Future<TenantAdminAccountOnboardingResult> createAccountFromForm({
    required TenantAdminLocation? location,
  }) async {
    final selectedProfileType =
        createStateStreamValue.value.selectedProfileType ?? '';
    final capabilities = _capabilitiesForProfileType(selectedProfileType);
    final filteredTaxonomyTerms = capabilities?.hasTaxonomies == true
        ? _buildTaxonomyTerms()
        : const <TenantAdminTaxonomyTerm>[];
    final filteredBio = capabilities?.hasBio == true
        ? _normalizeOptionalString(bioController.text)
        : null;
    final filteredContent = capabilities?.hasContent == true
        ? _normalizeOptionalString(contentController.text)
        : null;
    final avatarUpload = await buildImageUpload(
      createStateStreamValue.value.avatarFile,
      slot: TenantAdminImageSlot.avatar,
    );
    final coverUpload = await buildImageUpload(
      createStateStreamValue.value.coverFile,
      slot: TenantAdminImageSlot.cover,
    );
    return createAccountOnboarding(
      name: nameController.text.trim(),
      ownershipState: createStateStreamValue.value.ownershipState,
      profileType: selectedProfileType,
      location: location,
      bio: filteredBio,
      content: filteredContent,
      taxonomyTerms: filteredTaxonomyTerms,
      avatarUpload: avatarUpload,
      coverUpload: coverUpload,
    );
  }

  bool validateCreateBeforeSubmit({
    required TenantAdminLocation? location,
  }) {
    final fieldErrors = <String, List<String>>{};
    final groupErrors = <String, List<String>>{};
    final selectedProfileType =
        createStateStreamValue.value.selectedProfileType?.trim() ?? '';

    if (selectedProfileType.isEmpty) {
      fieldErrors[TenantAdminAccountCreateValidationTargets.profileType] =
          const <String>['Tipo de perfil e obrigatorio.'];
    }

    if (nameController.text.trim().isEmpty) {
      fieldErrors[TenantAdminAccountCreateValidationTargets.name] =
          const <String>['Nome e obrigatorio.'];
    }

    final requiresLocation =
        _capabilitiesForProfileType(selectedProfileType)?.isPoiEnabled ?? false;
    if (requiresLocation) {
      final locationMessages = <String>[];
      final latitudeText = latitudeController.text.trim();
      final longitudeText = longitudeController.text.trim();

      if (latitudeText.isEmpty && longitudeText.isEmpty) {
        locationMessages.add('Localizacao e obrigatoria para este perfil.');
      } else {
        if (latitudeText.isEmpty) {
          locationMessages.add('Latitude e obrigatoria.');
        }
        if (longitudeText.isEmpty) {
          locationMessages.add('Longitude e obrigatoria.');
        }
        if (latitudeText.isNotEmpty &&
            tenantAdminParseLatitude(latitudeText) == null) {
          locationMessages.add('Latitude invalida.');
        }
        if (longitudeText.isNotEmpty &&
            tenantAdminParseLongitude(longitudeText) == null) {
          locationMessages.add('Longitude invalida.');
        }
        if (location == null && locationMessages.isEmpty) {
          locationMessages.add('Localizacao e obrigatoria para este perfil.');
        }
      }

      if (locationMessages.isNotEmpty) {
        groupErrors[TenantAdminAccountCreateValidationTargets.location] =
            locationMessages;
      }
    }

    if (fieldErrors.isEmpty && groupErrors.isEmpty) {
      clearCreateValidation();
      return true;
    }

    createValidationController.replaceWithResolved(
      fieldErrors: fieldErrors,
      groupErrors: groupErrors,
    );
    return false;
  }

  Future<bool> submitCreateAccountFromForm({
    required TenantAdminLocation? location,
  }) async {
    createSubmittingStreamValue.addValue(true);
    clearCreateSuccessAccount();
    try {
      final onboardingResult = await createAccountFromForm(
        location: location,
      );
      if (_isDisposed) return false;
      clearCreateValidation();
      createErrorMessageStreamValue.addValue(null);
      createSuccessAccountStreamValue.addValue(onboardingResult);
      return true;
    } on FormValidationFailure catch (error) {
      if (_isDisposed) return false;
      createValidationController.applyFailure(error);
      createErrorMessageStreamValue.addValue(null);
      return false;
    } catch (error) {
      if (_isDisposed) return false;
      clearCreateValidation();
      createErrorMessageStreamValue.addValue(error.toString());
      return false;
    } finally {
      if (!_isDisposed) {
        createSubmittingStreamValue.addValue(false);
      }
    }
  }

  void clearCreateErrorMessage() {
    createErrorMessageStreamValue.addValue(null);
  }

  void clearCreateSuccessAccount() {
    createSuccessAccountStreamValue.addValue(null);
  }

  void clearCreateValidation() {
    createValidationController.clearAll();
  }

  void clearCreateFieldValidation(String fieldId) {
    createValidationController.clearField(fieldId);
  }

  void clearCreateGroupValidation(String groupId) {
    createValidationController.clearGroup(groupId);
  }

  void resetCreateForm() {
    nameController.clear();
    bioController.clear();
    contentController.clear();
    latitudeController.clear();
    longitudeController.clear();
    selectedTaxonomyTermsStreamValue.addValue(const {});
    clearCreateValidation();
  }

  void dispose() {
    _isDisposed = true;
    _locationSelectionSubscription?.cancel();
    nameController.dispose();
    bioController.dispose();
    contentController.dispose();
    latitudeController.dispose();
    longitudeController.dispose();
    profileTypesStreamValue.dispose();
    isProfileTypesLoadingStreamValue.dispose();
    errorStreamValue.dispose();
    createStateStreamValue.dispose();
    taxonomiesStreamValue.dispose();
    taxonomyTermsStreamValue.dispose();
    selectedTaxonomyTermsStreamValue.dispose();
    taxonomiesLoadingStreamValue.dispose();
    taxonomiesErrorStreamValue.dispose();
    createSubmittingStreamValue.dispose();
    createErrorMessageStreamValue.dispose();
    createSuccessAccountStreamValue.dispose();
    createValidationController.dispose();
  }

  @override
  void onDispose() {
    dispose();
  }
}

extension on TenantAdminAccountCreateController {
  void _bindCreateFieldListeners() {
    if (_createFieldListenersBound) {
      return;
    }
    _createFieldListenersBound = true;
    nameController.addListener(() {
      clearCreateFieldValidation(
        TenantAdminAccountCreateValidationTargets.name,
      );
    });
    bioController.addListener(() {
      clearCreateFieldValidation(TenantAdminAccountCreateValidationTargets.bio);
    });
    contentController.addListener(() {
      clearCreateFieldValidation(
        TenantAdminAccountCreateValidationTargets.content,
      );
    });
    latitudeController.addListener(() {
      clearCreateGroupValidation(
        TenantAdminAccountCreateValidationTargets.location,
      );
    });
    longitudeController.addListener(() {
      clearCreateGroupValidation(
        TenantAdminAccountCreateValidationTargets.location,
      );
    });
  }

  TenantAdminProfileTypeCapabilities? _capabilitiesForProfileType(
    String profileType,
  ) {
    for (final definition in profileTypesStreamValue.value) {
      if (definition.type == profileType) {
        return definition.capabilities;
      }
    }
    return null;
  }

  List<String> _allowedTaxonomiesForProfileType(String? profileType) {
    if (profileType == null || profileType.isEmpty) {
      return const [];
    }
    for (final definition in profileTypesStreamValue.value) {
      if (definition.type == profileType) {
        return definition.allowedTaxonomies;
      }
    }
    return const [];
  }

  Future<void> _refreshTaxonomyTermsForSelectedProfileType() async {
    final allowed = _allowedTaxonomiesForProfileType(
      createStateStreamValue.value.selectedProfileType,
    );
    if (allowed.isEmpty) {
      taxonomyTermsStreamValue.addValue(const {});
      selectedTaxonomyTermsStreamValue.addValue(const {});
      return;
    }
    final current = Map<String, Set<String>>.from(
      selectedTaxonomyTermsStreamValue.value,
    );
    current.removeWhere((slug, _) => !allowed.contains(slug));
    selectedTaxonomyTermsStreamValue.addValue(current);

    final registry = taxonomiesStreamValue.value;
    final map = <String, List<TenantAdminTaxonomyTermDefinition>>{};
    for (final slug in allowed) {
      final taxonomy = registry.where((item) => item.slug == slug);
      if (taxonomy.isEmpty) {
        map[slug] = const [];
        continue;
      }
      final taxonomyId = taxonomy.first.id;
      try {
        final terms = await _taxonomiesRepository.fetchTerms(
          taxonomyId: taxonomyId,
        );
        if (_isDisposed) return;
        map[slug] = terms;
      } catch (error) {
        if (!_isDisposed) {
          taxonomiesErrorStreamValue
              .addValue('Falha ao carregar termos para taxonomia "$slug".');
        }
        map[slug] = const [];
      }
    }
    if (_isDisposed) return;
    taxonomyTermsStreamValue.addValue(map);
  }

  List<TenantAdminTaxonomyTerm> _buildTaxonomyTerms() {
    final terms = <TenantAdminTaxonomyTerm>[];
    final selected = selectedTaxonomyTermsStreamValue.value;
    for (final entry in selected.entries) {
      for (final value in entry.value) {
        terms.add(TenantAdminTaxonomyTerm(type: entry.key, value: value));
      }
    }
    return terms;
  }

  String? _normalizeOptionalString(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    return trimmed;
  }

  void _updateCreateState(TenantAdminAccountCreateDraft state) {
    if (_isDisposed) return;
    createStateStreamValue.addValue(state);
  }
}

class TenantAdminAccountCreateDraft {
  static const _unset = Object();

  const TenantAdminAccountCreateDraft({
    required this.ownershipState,
    required this.selectedProfileType,
    required this.avatarFile,
    required this.coverFile,
    required this.avatarWebUrl,
    required this.coverWebUrl,
    required this.avatarBusy,
    required this.coverBusy,
  });

  factory TenantAdminAccountCreateDraft.initial() =>
      const TenantAdminAccountCreateDraft(
        ownershipState: TenantAdminOwnershipState.tenantOwned,
        selectedProfileType: null,
        avatarFile: null,
        coverFile: null,
        avatarWebUrl: null,
        coverWebUrl: null,
        avatarBusy: false,
        coverBusy: false,
      );

  final TenantAdminOwnershipState ownershipState;
  final String? selectedProfileType;
  final XFile? avatarFile;
  final XFile? coverFile;
  final String? avatarWebUrl;
  final String? coverWebUrl;
  final bool avatarBusy;
  final bool coverBusy;

  TenantAdminAccountCreateDraft copyWith({
    Object? ownershipState = _unset,
    Object? selectedProfileType = _unset,
    Object? avatarFile = _unset,
    Object? coverFile = _unset,
    Object? avatarWebUrl = _unset,
    Object? coverWebUrl = _unset,
    bool? avatarBusy,
    bool? coverBusy,
  }) {
    final nextOwnershipState = ownershipState == _unset
        ? this.ownershipState
        : ownershipState as TenantAdminOwnershipState;
    final nextSelectedProfileType = selectedProfileType == _unset
        ? this.selectedProfileType
        : selectedProfileType as String?;
    final nextAvatarFile =
        avatarFile == _unset ? this.avatarFile : avatarFile as XFile?;
    final nextCoverFile =
        coverFile == _unset ? this.coverFile : coverFile as XFile?;
    final nextAvatarWebUrl =
        avatarWebUrl == _unset ? this.avatarWebUrl : avatarWebUrl as String?;
    final nextCoverWebUrl =
        coverWebUrl == _unset ? this.coverWebUrl : coverWebUrl as String?;

    return TenantAdminAccountCreateDraft(
      ownershipState: nextOwnershipState,
      selectedProfileType: nextSelectedProfileType,
      avatarFile: nextAvatarFile,
      coverFile: nextCoverFile,
      avatarWebUrl: nextAvatarWebUrl,
      coverWebUrl: nextCoverWebUrl,
      avatarBusy: avatarBusy ?? this.avatarBusy,
      coverBusy: coverBusy ?? this.coverBusy,
    );
  }
}
