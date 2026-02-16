import 'dart:async';

import 'package:belluga_now/domain/repositories/tenant_admin_account_profiles_repository_contract.dart';
import 'package:belluga_now/domain/repositories/tenant_admin_accounts_repository_contract.dart';
import 'package:belluga_now/domain/repositories/tenant_admin_taxonomies_repository_contract.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_account.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_account_profile.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_location.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_media_upload.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_profile_type.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_definition.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_term.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_term_definition.dart';
import 'package:belluga_now/domain/services/tenant_admin_location_selection_contract.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart' show Disposable, GetIt;
import 'package:image_picker/image_picker.dart';
import 'package:stream_value/core/stream_value.dart';

class TenantAdminAccountProfilesController implements Disposable {
  TenantAdminAccountProfilesController({
    TenantAdminAccountProfilesRepositoryContract? profilesRepository,
    TenantAdminAccountsRepositoryContract? accountsRepository,
    TenantAdminTaxonomiesRepositoryContract? taxonomiesRepository,
    TenantAdminLocationSelectionContract? locationSelectionService,
  })  : _profilesRepository = profilesRepository ??
            GetIt.I.get<TenantAdminAccountProfilesRepositoryContract>(),
        _accountsRepository = accountsRepository ??
            GetIt.I.get<TenantAdminAccountsRepositoryContract>(),
        _taxonomiesRepository = taxonomiesRepository ??
            GetIt.I.get<TenantAdminTaxonomiesRepositoryContract>(),
        _locationSelectionService = locationSelectionService ??
            GetIt.I.get<TenantAdminLocationSelectionContract>();

  final TenantAdminAccountProfilesRepositoryContract _profilesRepository;
  final TenantAdminAccountsRepositoryContract _accountsRepository;
  final TenantAdminTaxonomiesRepositoryContract _taxonomiesRepository;
  final TenantAdminLocationSelectionContract _locationSelectionService;

  final StreamValue<List<TenantAdminAccountProfile>> profilesStreamValue =
      StreamValue<List<TenantAdminAccountProfile>>(defaultValue: const []);
  final StreamValue<List<TenantAdminProfileTypeDefinition>>
      profileTypesStreamValue =
      StreamValue<List<TenantAdminProfileTypeDefinition>>(
          defaultValue: const []);
  final StreamValue<List<TenantAdminTaxonomyDefinition>> taxonomiesStreamValue =
      StreamValue<List<TenantAdminTaxonomyDefinition>>(defaultValue: const []);
  final StreamValue<Map<String, List<TenantAdminTaxonomyTermDefinition>>>
      taxonomyTermsStreamValue =
      StreamValue<Map<String, List<TenantAdminTaxonomyTermDefinition>>>(
    defaultValue: const {},
  );
  final StreamValue<Map<String, Set<String>>> taxonomySelectionStreamValue =
      StreamValue<Map<String, Set<String>>>(defaultValue: const {});
  final StreamValue<bool> isLoadingStreamValue =
      StreamValue<bool>(defaultValue: false);
  final StreamValue<String?> errorStreamValue = StreamValue<String?>();
  final StreamValue<TenantAdminAccount?> accountStreamValue =
      StreamValue<TenantAdminAccount?>();
  final StreamValue<TenantAdminAccountProfile?> accountProfileStreamValue =
      StreamValue<TenantAdminAccountProfile?>();
  final StreamValue<bool> accountDetailLoadingStreamValue =
      StreamValue<bool>(defaultValue: false);
  final StreamValue<String?> accountDetailErrorStreamValue =
      StreamValue<String?>();
  final StreamValue<bool> accountUpdatingStreamValue =
      StreamValue<bool>(defaultValue: false);
  final StreamValue<TenantAdminAccountProfileEditState> editStateStreamValue =
      StreamValue<TenantAdminAccountProfileEditState>(
    defaultValue: TenantAdminAccountProfileEditState.initial(),
  );
  final StreamValue<bool> editSubmittingStreamValue =
      StreamValue<bool>(defaultValue: false);
  final StreamValue<String?> editSuccessMessageStreamValue =
      StreamValue<String?>();
  final StreamValue<String?> editErrorMessageStreamValue =
      StreamValue<String?>();
  final StreamValue<TenantAdminAccountProfileCreateState>
      createStateStreamValue =
      StreamValue<TenantAdminAccountProfileCreateState>(
    defaultValue: TenantAdminAccountProfileCreateState.initial(),
  );
  final StreamValue<bool> createSubmittingStreamValue =
      StreamValue<bool>(defaultValue: false);
  final StreamValue<String?> createSuccessMessageStreamValue =
      StreamValue<String?>();
  final StreamValue<String?> createErrorMessageStreamValue =
      StreamValue<String?>();
  final StreamValue<String?> createAccountIdStreamValue =
      StreamValue<String?>();
  final GlobalKey<FormState> createFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> editFormKey = GlobalKey<FormState>();
  final TextEditingController slugController = TextEditingController();
  final TextEditingController displayNameController = TextEditingController();
  final TextEditingController bioController = TextEditingController();
  final TextEditingController latitudeController = TextEditingController();
  final TextEditingController longitudeController = TextEditingController();

  bool _isDisposed = false;
  StreamSubscription<TenantAdminLocation?>? _locationSelectionSubscription;

  Future<TenantAdminAccount> resolveAccountBySlug(String slug) async {
    return _accountsRepository.fetchAccountBySlug(slug);
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

  void bindCreateFlow() {
    _bindLocationSelection();
  }

  void bindEditFlow() {
    _bindLocationSelection();
  }

  Future<TenantAdminAccountProfile> fetchProfile(
      String accountProfileId) async {
    return _profilesRepository.fetchAccountProfile(accountProfileId);
  }

  Future<TenantAdminAccountProfile?> fetchProfileForAccount(
    String accountId,
  ) async {
    final profiles =
        await _profilesRepository.fetchAccountProfiles(accountId: accountId);
    if (profiles.isEmpty) {
      return null;
    }
    return profiles.first;
  }

  Future<void> loadProfiles(String accountId) async {
    isLoadingStreamValue.addValue(true);
    try {
      final profiles =
          await _profilesRepository.fetchAccountProfiles(accountId: accountId);
      if (_isDisposed) return;
      profilesStreamValue.addValue(profiles);
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

  Future<void> loadProfileTypes() async {
    isLoadingStreamValue.addValue(true);
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
        isLoadingStreamValue.addValue(false);
      }
    }
  }

  Future<void> loadTaxonomies() async {
    isLoadingStreamValue.addValue(true);
    try {
      final taxonomies = await _taxonomiesRepository.fetchTaxonomies();
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

  Future<void> loadTermsForTaxonomies(List<String> taxonomySlugs) async {
    if (taxonomySlugs.isEmpty) {
      taxonomyTermsStreamValue.addValue(const {});
      return;
    }
    final registry = taxonomiesStreamValue.value;
    final map = <String, List<TenantAdminTaxonomyTermDefinition>>{};
    for (final slug in taxonomySlugs) {
      final taxonomy = registry.firstWhere(
        (entry) => entry.slug == slug,
        orElse: () => const TenantAdminTaxonomyDefinition(
          id: '',
          slug: '',
          name: '',
          appliesTo: [],
          icon: null,
          color: null,
        ),
      );
      if (taxonomy.id.isEmpty) continue;
      try {
        final terms =
            await _taxonomiesRepository.fetchTerms(taxonomyId: taxonomy.id);
        map[slug] = terms;
      } catch (error) {
        debugPrint(
          '[TenantAdmin] Failed to load taxonomy terms for "$slug": $error',
        );
        map[slug] = const [];
      }
    }
    if (_isDisposed) return;
    taxonomyTermsStreamValue.addValue(map);
  }

  Future<void> loadAccountForCreate(String slug) async {
    try {
      final account = await resolveAccountBySlug(slug);
      if (_isDisposed) return;
      createAccountIdStreamValue.addValue(account.id);
    } catch (error) {
      if (_isDisposed) return;
      createErrorMessageStreamValue.addValue(error.toString());
    }
  }

  void clearCreateAccountId() {
    createAccountIdStreamValue.addValue(null);
  }

  Future<void> loadAccountDetail(String accountSlug) async {
    accountDetailLoadingStreamValue.addValue(true);
    accountDetailErrorStreamValue.addValue(null);
    try {
      await loadProfileTypes();
      final account = await resolveAccountBySlug(accountSlug);
      final profile = await fetchProfileForAccount(account.id);
      if (_isDisposed) return;
      accountStreamValue.addValue(account);
      accountProfileStreamValue.addValue(profile);
      accountDetailErrorStreamValue.addValue(null);
    } catch (error) {
      if (_isDisposed) return;
      accountDetailErrorStreamValue.addValue(error.toString());
    } finally {
      if (!_isDisposed) {
        accountDetailLoadingStreamValue.addValue(false);
      }
    }
  }

  Future<TenantAdminAccount?> updateAccount({
    required String accountSlug,
    String? name,
    String? slug,
  }) async {
    accountUpdatingStreamValue.addValue(true);
    try {
      final updated = await _accountsRepository.updateAccount(
        accountSlug: accountSlug,
        name: name,
        slug: slug,
      );
      if (_isDisposed) {
        return null;
      }
      accountStreamValue.addValue(updated);
      accountDetailErrorStreamValue.addValue(null);
      return updated;
    } catch (error) {
      if (_isDisposed) {
        return null;
      }
      accountDetailErrorStreamValue.addValue(error.toString());
      return null;
    } finally {
      if (!_isDisposed) {
        accountUpdatingStreamValue.addValue(false);
      }
    }
  }

  Future<void> loadEditProfile(String accountProfileId) async {
    _updateEditState(
      editStateStreamValue.value.copyWith(
        isLoading: true,
        errorMessage: null,
      ),
    );
    try {
      await loadProfileTypes();
      final profile = await fetchProfile(accountProfileId);
      if (_isDisposed) return;
      _updateEditState(
        editStateStreamValue.value
            .copyWith(
              isLoading: false,
              errorMessage: null,
              profile: profile,
              selectedProfileType: profile.profileType,
            )
            .syncRemoteState(profile),
      );
    } catch (error) {
      if (_isDisposed) return;
      _updateEditState(
        editStateStreamValue.value.copyWith(
          isLoading: false,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  void updateSelectedProfileType(String? profileType) {
    _updateEditState(
      editStateStreamValue.value.copyWith(
        selectedProfileType: profileType,
      ),
    );
  }

  void updateEditLoading(bool isLoading) {
    _updateEditState(
      editStateStreamValue.value.copyWith(isLoading: isLoading),
    );
  }

  void updateEditProfile(TenantAdminAccountProfile profile) {
    _updateEditState(
      editStateStreamValue.value
          .copyWith(
            profile: profile,
          )
          .syncRemoteState(profile),
    );
  }

  void updateAvatarFile(XFile? file) {
    _updateEditState(
      editStateStreamValue.value.copyWith(
        avatarFile: file,
        avatarRemoteUrl: file == null
            ? editStateStreamValue.value.avatarRemoteUrl
            : null,
        avatarRemoteReady: false,
        avatarRemoteError: false,
        avatarPreloadUrl: null,
      ),
    );
  }

  void updateCoverFile(XFile? file) {
    _updateEditState(
      editStateStreamValue.value.copyWith(
        coverFile: file,
        coverRemoteUrl:
            file == null ? editStateStreamValue.value.coverRemoteUrl : null,
        coverRemoteReady: false,
        coverRemoteError: false,
        coverPreloadUrl: null,
      ),
    );
  }

  void updateAvatarRemoteUrl(String? url) {
    final trimmed = url?.trim();
    _updateEditState(
      editStateStreamValue.value.copyWith(
        avatarRemoteUrl:
            trimmed == null || trimmed.isEmpty ? null : trimmed,
        avatarFile: null,
        avatarRemoteReady: false,
        avatarRemoteError: false,
        avatarPreloadUrl: null,
      ),
    );
  }

  void updateCoverRemoteUrl(String? url) {
    final trimmed = url?.trim();
    _updateEditState(
      editStateStreamValue.value.copyWith(
        coverRemoteUrl: trimmed == null || trimmed.isEmpty ? null : trimmed,
        coverFile: null,
        coverRemoteReady: false,
        coverRemoteError: false,
        coverPreloadUrl: null,
      ),
    );
  }

  Future<void> submitCreateProfile({
    required String accountId,
    required String profileType,
    required String displayName,
    required TenantAdminLocation? location,
    required String? bio,
    required List<TenantAdminTaxonomyTerm> taxonomyTerms,
    required TenantAdminMediaUpload? avatarUpload,
    required TenantAdminMediaUpload? coverUpload,
    String? avatarUrl,
    String? coverUrl,
  }) async {
    createSubmittingStreamValue.addValue(true);
    try {
      await createProfile(
        accountId: accountId,
        profileType: profileType,
        displayName: displayName,
        location: location,
        bio: bio,
        taxonomyTerms: taxonomyTerms,
        avatarUpload: avatarUpload,
        coverUpload: coverUpload,
        avatarUrl: avatarUrl,
        coverUrl: coverUrl,
      );
      if (_isDisposed) return;
      createErrorMessageStreamValue.addValue(null);
      createSuccessMessageStreamValue.addValue('Perfil salvo.');
      resetFormControllers();
      resetCreateState();
    } catch (error) {
      if (_isDisposed) return;
      createErrorMessageStreamValue.addValue(error.toString());
    } finally {
      if (!_isDisposed) {
        createSubmittingStreamValue.addValue(false);
      }
    }
  }

  void clearCreateSuccessMessage() {
    createSuccessMessageStreamValue.addValue(null);
  }

  void clearCreateErrorMessage() {
    createErrorMessageStreamValue.addValue(null);
  }

  void reportCreateErrorMessage(String message) {
    createErrorMessageStreamValue.addValue(message);
  }

  void markAvatarRemoteReady(bool ready) {
    _updateEditState(
      editStateStreamValue.value.copyWith(
        avatarRemoteReady: ready,
        avatarRemoteError:
            ready ? false : editStateStreamValue.value.avatarRemoteError,
        avatarFile: ready ? null : editStateStreamValue.value.avatarFile,
      ),
    );
  }

  void markCoverRemoteReady(bool ready) {
    _updateEditState(
      editStateStreamValue.value.copyWith(
        coverRemoteReady: ready,
        coverRemoteError:
            ready ? false : editStateStreamValue.value.coverRemoteError,
        coverFile: ready ? null : editStateStreamValue.value.coverFile,
      ),
    );
  }

  void updateAvatarRemoteError(bool hasError) {
    _updateEditState(
      editStateStreamValue.value.copyWith(
        avatarRemoteError: hasError,
      ),
    );
  }

  void updateCoverRemoteError(bool hasError) {
    _updateEditState(
      editStateStreamValue.value.copyWith(
        coverRemoteError: hasError,
      ),
    );
  }

  Future<void> submitUpdateProfile({
    required String accountProfileId,
    required String profileType,
    required String displayName,
    String? slug,
    required TenantAdminLocation? location,
    required String? bio,
    required List<TenantAdminTaxonomyTerm>? taxonomyTerms,
    required TenantAdminMediaUpload? avatarUpload,
    required TenantAdminMediaUpload? coverUpload,
    String? avatarUrl,
    String? coverUrl,
  }) async {
    editSubmittingStreamValue.addValue(true);
    try {
      final updated = await updateProfile(
        accountProfileId: accountProfileId,
        profileType: profileType,
        displayName: displayName,
        slug: slug,
        location: location,
        bio: bio,
        taxonomyTerms: taxonomyTerms,
        avatarUpload: avatarUpload,
        coverUpload: coverUpload,
        avatarUrl: avatarUrl,
        coverUrl: coverUrl,
      );
      if (_isDisposed) return;
      updateEditProfile(updated);
      editErrorMessageStreamValue.addValue(null);
      editSuccessMessageStreamValue.addValue('Perfil atualizado.');
    } catch (error) {
      if (_isDisposed) return;
      editErrorMessageStreamValue.addValue(error.toString());
    } finally {
      if (!_isDisposed) {
        editSubmittingStreamValue.addValue(false);
      }
    }
  }

  Future<void> submitAutoSaveImages({
    required String accountProfileId,
    required TenantAdminMediaUpload? avatarUpload,
    required TenantAdminMediaUpload? coverUpload,
    String? avatarUrl,
    String? coverUrl,
  }) async {
    if (avatarUpload == null &&
        coverUpload == null &&
        avatarUrl == null &&
        coverUrl == null) {
      return;
    }
    updateEditLoading(true);
    try {
      final updated = await updateProfile(
        accountProfileId: accountProfileId,
        avatarUpload: avatarUpload,
        coverUpload: coverUpload,
        avatarUrl: avatarUrl,
        coverUrl: coverUrl,
      );
      if (_isDisposed) return;
      updateEditProfile(updated);
      editErrorMessageStreamValue.addValue(null);
      editSuccessMessageStreamValue.addValue('Imagem atualizada.');
    } catch (error) {
      if (_isDisposed) return;
      editErrorMessageStreamValue.addValue(
        'Falha ao salvar imagem: $error',
      );
    } finally {
      if (!_isDisposed) {
        updateEditLoading(false);
      }
    }
  }

  Future<bool> submitTaxonomySelectionUpdate({
    required String accountProfileId,
    required List<TenantAdminTaxonomyTerm> taxonomyTerms,
  }) async {
    editSubmittingStreamValue.addValue(true);
    try {
      final updated = await updateProfile(
        accountProfileId: accountProfileId,
        taxonomyTerms: taxonomyTerms,
      );
      if (_isDisposed) return false;
      updateEditProfile(updated);
      editErrorMessageStreamValue.addValue(null);
      return true;
    } catch (error) {
      if (_isDisposed) return false;
      editErrorMessageStreamValue.addValue(error.toString());
      return false;
    } finally {
      if (!_isDisposed) {
        editSubmittingStreamValue.addValue(false);
      }
    }
  }

  void clearEditSuccessMessage() {
    editSuccessMessageStreamValue.addValue(null);
  }

  void clearEditErrorMessage() {
    editErrorMessageStreamValue.addValue(null);
  }

  void reportEditErrorMessage(String message) {
    editErrorMessageStreamValue.addValue(message);
  }

  void updateAvatarPreloadUrl(String? url) {
    _updateEditState(
      editStateStreamValue.value.copyWith(avatarPreloadUrl: url),
    );
  }

  void updateCoverPreloadUrl(String? url) {
    _updateEditState(
      editStateStreamValue.value.copyWith(coverPreloadUrl: url),
    );
  }

  void resetEditState() {
    _updateEditState(TenantAdminAccountProfileEditState.initial());
  }

  void updateCreateSelectedProfileType(String? profileType) {
    _updateCreateState(
      createStateStreamValue.value.copyWith(selectedProfileType: profileType),
    );
  }

  void updateCreateAvatarFile(XFile? file) {
    _updateCreateState(
      createStateStreamValue.value.copyWith(
        avatarFile: file,
        avatarWebUrl: null,
      ),
    );
  }

  void updateCreateCoverFile(XFile? file) {
    _updateCreateState(
      createStateStreamValue.value.copyWith(
        coverFile: file,
        coverWebUrl: null,
      ),
    );
  }

  void updateCreateAvatarWebUrl(String? url) {
    final trimmed = url?.trim();
    _updateCreateState(
      createStateStreamValue.value.copyWith(
        avatarWebUrl:
            trimmed == null || trimmed.isEmpty ? null : trimmed,
        avatarFile: null,
      ),
    );
  }

  void updateCreateCoverWebUrl(String? url) {
    final trimmed = url?.trim();
    _updateCreateState(
      createStateStreamValue.value.copyWith(
        coverWebUrl:
            trimmed == null || trimmed.isEmpty ? null : trimmed,
        coverFile: null,
      ),
    );
  }

  void resetFormControllers() {
    slugController.clear();
    displayNameController.clear();
    bioController.clear();
    latitudeController.clear();
    longitudeController.clear();
    resetTaxonomySelection();
  }

  void resetTaxonomySelection() {
    taxonomySelectionStreamValue.addValue(const {});
  }

  void ensureTaxonomySelectionKeys(List<String> taxonomySlugs) {
    final current = taxonomySelectionStreamValue.value;
    final next = <String, Set<String>>{};
    for (final slug in taxonomySlugs) {
      next[slug] = current[slug] ?? <String>{};
    }
    taxonomySelectionStreamValue.addValue(next);
  }

  void setTaxonomySelectionFromTerms(List<TenantAdminTaxonomyTerm> terms) {
    final next = <String, Set<String>>{};
    for (final term in terms) {
      next.putIfAbsent(term.type, () => <String>{}).add(term.value);
    }
    taxonomySelectionStreamValue.addValue(next);
  }

  void updateTaxonomySelection({
    required String taxonomySlug,
    required String termSlug,
    required bool selected,
  }) {
    final current = taxonomySelectionStreamValue.value;
    final next = <String, Set<String>>{};
    for (final entry in current.entries) {
      next[entry.key] = Set<String>.from(entry.value);
    }
    final set = next.putIfAbsent(taxonomySlug, () => <String>{});
    if (selected) {
      set.add(termSlug);
    } else {
      set.remove(termSlug);
    }
    taxonomySelectionStreamValue.addValue(next);
  }

  void resetCreateState() {
    _updateCreateState(TenantAdminAccountProfileCreateState.initial());
  }

  void _updateEditState(TenantAdminAccountProfileEditState state) {
    if (_isDisposed) return;
    editStateStreamValue.addValue(state);
  }

  void _updateCreateState(TenantAdminAccountProfileCreateState state) {
    if (_isDisposed) return;
    createStateStreamValue.addValue(state);
  }

  void resetAccountDetail() {
    accountStreamValue.addValue(null);
    accountProfileStreamValue.addValue(null);
    accountDetailErrorStreamValue.addValue(null);
    accountDetailLoadingStreamValue.addValue(false);
  }

  Future<TenantAdminAccountProfile> createProfile({
    required String accountId,
    required String profileType,
    required String displayName,
    TenantAdminLocation? location,
    List<TenantAdminTaxonomyTerm> taxonomyTerms = const [],
    String? bio,
    String? avatarUrl,
    String? coverUrl,
    TenantAdminMediaUpload? avatarUpload,
    TenantAdminMediaUpload? coverUpload,
  }) async {
    final filtered = _filterCapabilities(
      profileType: profileType,
      location: location,
      taxonomyTerms: taxonomyTerms,
      bio: bio,
      avatarUrl: avatarUrl,
      coverUrl: coverUrl,
      avatarUpload: avatarUpload,
      coverUpload: coverUpload,
    );
    final profile = await _profilesRepository.createAccountProfile(
      accountId: accountId,
      profileType: profileType,
      displayName: displayName,
      location: filtered.location,
      taxonomyTerms: filtered.taxonomyTerms,
      bio: filtered.bio,
      avatarUrl: filtered.avatarUrl,
      coverUrl: filtered.coverUrl,
      avatarUpload: filtered.avatarUpload,
      coverUpload: filtered.coverUpload,
    );
    await loadProfiles(accountId);
    return profile;
  }

  Future<TenantAdminAccountProfile> updateProfile({
    required String accountProfileId,
    String? profileType,
    String? displayName,
    String? slug,
    TenantAdminLocation? location,
    List<TenantAdminTaxonomyTerm>? taxonomyTerms,
    String? bio,
    String? avatarUrl,
    String? coverUrl,
    TenantAdminMediaUpload? avatarUpload,
    TenantAdminMediaUpload? coverUpload,
  }) async {
    final filtered = profileType == null
        ? _CapabilityFilter(
            location: location,
            taxonomyTerms: taxonomyTerms ?? const [],
            bio: bio,
            avatarUrl: avatarUrl,
            coverUrl: coverUrl,
            avatarUpload: avatarUpload,
            coverUpload: coverUpload,
          )
        : _filterCapabilities(
            profileType: profileType,
            location: location,
            taxonomyTerms: taxonomyTerms ?? const [],
            bio: bio,
            avatarUrl: avatarUrl,
            coverUrl: coverUrl,
            avatarUpload: avatarUpload,
            coverUpload: coverUpload,
          );
    final profile = await _profilesRepository.updateAccountProfile(
      accountProfileId: accountProfileId,
      profileType: profileType,
      displayName: displayName,
      slug: slug,
      location: filtered.location,
      taxonomyTerms: taxonomyTerms == null ? null : filtered.taxonomyTerms,
      bio: filtered.bio,
      avatarUrl: filtered.avatarUrl,
      coverUrl: filtered.coverUrl,
      avatarUpload: filtered.avatarUpload,
      coverUpload: filtered.coverUpload,
    );
    await loadProfiles(profile.accountId);
    return profile;
  }

  TenantAdminProfileTypeDefinition? _resolveProfileType(
    String profileType,
  ) {
    for (final definition in profileTypesStreamValue.value) {
      if (definition.type == profileType) {
        return definition;
      }
    }
    return null;
  }

  _CapabilityFilter _filterCapabilities({
    required String profileType,
    required TenantAdminLocation? location,
    required List<TenantAdminTaxonomyTerm> taxonomyTerms,
    required String? bio,
    required String? avatarUrl,
    required String? coverUrl,
    required TenantAdminMediaUpload? avatarUpload,
    required TenantAdminMediaUpload? coverUpload,
  }) {
    final definition = _resolveProfileType(profileType);
    if (definition == null) {
      return _CapabilityFilter(
        location: location,
        taxonomyTerms: taxonomyTerms,
        bio: bio,
        avatarUrl: avatarUrl,
        coverUrl: coverUrl,
        avatarUpload: avatarUpload,
        coverUpload: coverUpload,
      );
    }
    final capabilities = definition.capabilities;
    final allowedTaxonomies = definition.allowedTaxonomies.toSet();
    final filteredTerms = capabilities.hasTaxonomies
        ? taxonomyTerms
            .where((term) => allowedTaxonomies.contains(term.type))
            .toList(growable: false)
        : const <TenantAdminTaxonomyTerm>[];
    return _CapabilityFilter(
      location: capabilities.isPoiEnabled ? location : null,
      taxonomyTerms: filteredTerms,
      bio: capabilities.hasBio ? bio : null,
      avatarUrl: capabilities.hasAvatar ? avatarUrl : null,
      coverUrl: capabilities.hasCover ? coverUrl : null,
      avatarUpload: capabilities.hasAvatar ? avatarUpload : null,
      coverUpload: capabilities.hasCover ? coverUpload : null,
    );
  }

  void dispose() {
    _isDisposed = true;
    _locationSelectionSubscription?.cancel();
    slugController.dispose();
    displayNameController.dispose();
    bioController.dispose();
    latitudeController.dispose();
    longitudeController.dispose();
    profilesStreamValue.dispose();
    profileTypesStreamValue.dispose();
    taxonomiesStreamValue.dispose();
    taxonomyTermsStreamValue.dispose();
    taxonomySelectionStreamValue.dispose();
    isLoadingStreamValue.dispose();
    errorStreamValue.dispose();
    accountStreamValue.dispose();
    accountProfileStreamValue.dispose();
    accountDetailLoadingStreamValue.dispose();
    accountDetailErrorStreamValue.dispose();
    accountUpdatingStreamValue.dispose();
    editStateStreamValue.dispose();
    createStateStreamValue.dispose();
    editSubmittingStreamValue.dispose();
    editSuccessMessageStreamValue.dispose();
    editErrorMessageStreamValue.dispose();
    createSubmittingStreamValue.dispose();
    createSuccessMessageStreamValue.dispose();
    createErrorMessageStreamValue.dispose();
    createAccountIdStreamValue.dispose();
  }

  @override
  void onDispose() {
    dispose();
  }
}

class TenantAdminAccountProfileEditState {
  static const _unset = Object();

  const TenantAdminAccountProfileEditState({
    required this.isLoading,
    required this.profile,
    required this.errorMessage,
    required this.selectedProfileType,
    required this.avatarFile,
    required this.coverFile,
    required this.avatarRemoteUrl,
    required this.coverRemoteUrl,
    required this.avatarRemoteReady,
    required this.coverRemoteReady,
    required this.avatarRemoteError,
    required this.coverRemoteError,
    required this.avatarPreloadUrl,
    required this.coverPreloadUrl,
  });

  factory TenantAdminAccountProfileEditState.initial() =>
      const TenantAdminAccountProfileEditState(
        isLoading: true,
        profile: null,
        errorMessage: null,
        selectedProfileType: null,
        avatarFile: null,
        coverFile: null,
        avatarRemoteUrl: null,
        coverRemoteUrl: null,
        avatarRemoteReady: false,
        coverRemoteReady: false,
        avatarRemoteError: false,
        coverRemoteError: false,
        avatarPreloadUrl: null,
        coverPreloadUrl: null,
      );

  final bool isLoading;
  final TenantAdminAccountProfile? profile;
  final String? errorMessage;
  final String? selectedProfileType;
  final XFile? avatarFile;
  final XFile? coverFile;
  final String? avatarRemoteUrl;
  final String? coverRemoteUrl;
  final bool avatarRemoteReady;
  final bool coverRemoteReady;
  final bool avatarRemoteError;
  final bool coverRemoteError;
  final String? avatarPreloadUrl;
  final String? coverPreloadUrl;

  TenantAdminAccountProfileEditState copyWith({
    bool? isLoading,
    Object? profile = _unset,
    Object? errorMessage = _unset,
    Object? selectedProfileType = _unset,
    Object? avatarFile = _unset,
    Object? coverFile = _unset,
    Object? avatarRemoteUrl = _unset,
    Object? coverRemoteUrl = _unset,
    bool? avatarRemoteReady,
    bool? coverRemoteReady,
    bool? avatarRemoteError,
    bool? coverRemoteError,
    Object? avatarPreloadUrl = _unset,
    Object? coverPreloadUrl = _unset,
  }) {
    final nextProfile = profile == _unset
        ? this.profile
        : profile as TenantAdminAccountProfile?;
    final nextErrorMessage =
        errorMessage == _unset ? this.errorMessage : errorMessage as String?;
    final nextSelectedProfileType = selectedProfileType == _unset
        ? this.selectedProfileType
        : selectedProfileType as String?;
    final nextAvatarFile =
        avatarFile == _unset ? this.avatarFile : avatarFile as XFile?;
    final nextCoverFile =
        coverFile == _unset ? this.coverFile : coverFile as XFile?;
    final nextAvatarRemoteUrl = avatarRemoteUrl == _unset
        ? this.avatarRemoteUrl
        : avatarRemoteUrl as String?;
    final nextCoverRemoteUrl = coverRemoteUrl == _unset
        ? this.coverRemoteUrl
        : coverRemoteUrl as String?;
    final nextAvatarPreloadUrl = avatarPreloadUrl == _unset
        ? this.avatarPreloadUrl
        : avatarPreloadUrl as String?;
    final nextCoverPreloadUrl = coverPreloadUrl == _unset
        ? this.coverPreloadUrl
        : coverPreloadUrl as String?;

    return TenantAdminAccountProfileEditState(
      isLoading: isLoading ?? this.isLoading,
      profile: nextProfile,
      errorMessage: nextErrorMessage,
      selectedProfileType: nextSelectedProfileType,
      avatarFile: nextAvatarFile,
      coverFile: nextCoverFile,
      avatarRemoteUrl: nextAvatarRemoteUrl,
      coverRemoteUrl: nextCoverRemoteUrl,
      avatarRemoteReady: avatarRemoteReady ?? this.avatarRemoteReady,
      coverRemoteReady: coverRemoteReady ?? this.coverRemoteReady,
      avatarRemoteError: avatarRemoteError ?? this.avatarRemoteError,
      coverRemoteError: coverRemoteError ?? this.coverRemoteError,
      avatarPreloadUrl: nextAvatarPreloadUrl,
      coverPreloadUrl: nextCoverPreloadUrl,
    );
  }

  TenantAdminAccountProfileEditState syncRemoteState(
    TenantAdminAccountProfile updated,
  ) {
    final avatarUrl = updated.avatarUrl;
    final coverUrl = updated.coverUrl;
    return copyWith(
      avatarRemoteUrl: avatarUrl,
      coverRemoteUrl: coverUrl,
      avatarRemoteReady: false,
      coverRemoteReady: false,
      avatarRemoteError: false,
      coverRemoteError: false,
      avatarPreloadUrl: null,
      coverPreloadUrl: null,
    );
  }
}

class TenantAdminAccountProfileCreateState {
  static const _unset = Object();

  const TenantAdminAccountProfileCreateState({
    required this.selectedProfileType,
    required this.avatarFile,
    required this.coverFile,
    required this.avatarWebUrl,
    required this.coverWebUrl,
  });

  factory TenantAdminAccountProfileCreateState.initial() =>
      const TenantAdminAccountProfileCreateState(
        selectedProfileType: null,
        avatarFile: null,
        coverFile: null,
        avatarWebUrl: null,
        coverWebUrl: null,
      );

  final String? selectedProfileType;
  final XFile? avatarFile;
  final XFile? coverFile;
  final String? avatarWebUrl;
  final String? coverWebUrl;

  TenantAdminAccountProfileCreateState copyWith({
    Object? selectedProfileType = _unset,
    Object? avatarFile = _unset,
    Object? coverFile = _unset,
    Object? avatarWebUrl = _unset,
    Object? coverWebUrl = _unset,
  }) {
    final nextSelectedProfileType = selectedProfileType == _unset
        ? this.selectedProfileType
        : selectedProfileType as String?;
    final nextAvatarFile =
        avatarFile == _unset ? this.avatarFile : avatarFile as XFile?;
    final nextCoverFile =
        coverFile == _unset ? this.coverFile : coverFile as XFile?;
    final nextAvatarWebUrl = avatarWebUrl == _unset
        ? this.avatarWebUrl
        : avatarWebUrl as String?;
    final nextCoverWebUrl =
        coverWebUrl == _unset ? this.coverWebUrl : coverWebUrl as String?;

    return TenantAdminAccountProfileCreateState(
      selectedProfileType: nextSelectedProfileType,
      avatarFile: nextAvatarFile,
      coverFile: nextCoverFile,
      avatarWebUrl: nextAvatarWebUrl,
      coverWebUrl: nextCoverWebUrl,
    );
  }
}

class _CapabilityFilter {
  const _CapabilityFilter({
    required this.location,
    required this.taxonomyTerms,
    required this.bio,
    required this.avatarUrl,
    required this.coverUrl,
    required this.avatarUpload,
    required this.coverUpload,
  });

  final TenantAdminLocation? location;
  final List<TenantAdminTaxonomyTerm> taxonomyTerms;
  final String? bio;
  final String? avatarUrl;
  final String? coverUrl;
  final TenantAdminMediaUpload? avatarUpload;
  final TenantAdminMediaUpload? coverUpload;
}
