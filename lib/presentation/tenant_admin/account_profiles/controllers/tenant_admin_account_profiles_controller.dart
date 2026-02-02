import 'package:belluga_now/domain/repositories/tenant_admin_account_profiles_repository_contract.dart';
import 'package:belluga_now/domain/repositories/tenant_admin_accounts_repository_contract.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_account.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_account_profile.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_location.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_media_upload.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_profile_type.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_term.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart' show Disposable, GetIt;
import 'package:image_picker/image_picker.dart';
import 'package:stream_value/core/stream_value.dart';

class TenantAdminAccountProfilesController implements Disposable {
  TenantAdminAccountProfilesController({
    TenantAdminAccountProfilesRepositoryContract? profilesRepository,
    TenantAdminAccountsRepositoryContract? accountsRepository,
  })  : _profilesRepository = profilesRepository ??
            GetIt.I.get<TenantAdminAccountProfilesRepositoryContract>(),
        _accountsRepository =
            accountsRepository ?? GetIt.I.get<TenantAdminAccountsRepositoryContract>();

  final TenantAdminAccountProfilesRepositoryContract _profilesRepository;
  final TenantAdminAccountsRepositoryContract _accountsRepository;

  final StreamValue<List<TenantAdminAccountProfile>> profilesStreamValue =
      StreamValue<List<TenantAdminAccountProfile>>(defaultValue: const []);
  final StreamValue<List<TenantAdminProfileTypeDefinition>>
      profileTypesStreamValue =
      StreamValue<List<TenantAdminProfileTypeDefinition>>(defaultValue: const []);
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
  final StreamValue<TenantAdminAccountProfileEditState>
      editStateStreamValue = StreamValue<TenantAdminAccountProfileEditState>(
    defaultValue: TenantAdminAccountProfileEditState.initial(),
  );
  final StreamValue<TenantAdminAccountProfileCreateState>
      createStateStreamValue = StreamValue<TenantAdminAccountProfileCreateState>(
    defaultValue: TenantAdminAccountProfileCreateState.initial(),
  );
  final GlobalKey<FormState> createFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> editFormKey = GlobalKey<FormState>();
  final TextEditingController displayNameController = TextEditingController();
  final TextEditingController bioController = TextEditingController();
  final TextEditingController latitudeController = TextEditingController();
  final TextEditingController longitudeController = TextEditingController();
  final Map<String, TextEditingController> taxonomyControllers = {};

  bool _isDisposed = false;

  Future<TenantAdminAccount> resolveAccountBySlug(String slug) async {
    return _accountsRepository.fetchAccountBySlug(slug);
  }

  Future<TenantAdminAccountProfile> fetchProfile(String accountProfileId) async {
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
        editStateStreamValue.value.copyWith(
          isLoading: false,
          errorMessage: null,
          profile: profile,
          selectedProfileType: profile.profileType,
        ).syncRemoteState(profile),
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
      editStateStreamValue.value.copyWith(
        profile: profile,
      ).syncRemoteState(profile),
    );
  }

  void updateAvatarFile(XFile? file) {
    _updateEditState(
      editStateStreamValue.value.copyWith(
        avatarFile: file,
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
        coverRemoteReady: false,
        coverRemoteError: false,
        coverPreloadUrl: null,
      ),
    );
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
      createStateStreamValue.value.copyWith(avatarFile: file),
    );
  }

  void updateCreateCoverFile(XFile? file) {
    _updateCreateState(
      createStateStreamValue.value.copyWith(coverFile: file),
    );
  }

  void resetFormControllers() {
    displayNameController.clear();
    bioController.clear();
    latitudeController.clear();
    longitudeController.clear();
    for (final controller in taxonomyControllers.values) {
      controller.clear();
    }
  }

  TextEditingController getOrCreateTaxonomyController(
    String key, {
    String? initialText,
  }) {
    final controller = taxonomyControllers.putIfAbsent(
      key,
      () => TextEditingController(text: initialText ?? ''),
    );
    if (initialText != null && controller.text.isEmpty) {
      controller.text = initialText;
    }
    return controller;
  }

  void removeTaxonomyController(String key) {
    final controller = taxonomyControllers.remove(key);
    controller?.dispose();
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
    TenantAdminMediaUpload? avatarUpload,
    TenantAdminMediaUpload? coverUpload,
  }) async {
    final filtered = _filterCapabilities(
      profileType: profileType,
      location: location,
      taxonomyTerms: taxonomyTerms,
      bio: bio,
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
    TenantAdminLocation? location,
    List<TenantAdminTaxonomyTerm>? taxonomyTerms,
    String? bio,
    TenantAdminMediaUpload? avatarUpload,
    TenantAdminMediaUpload? coverUpload,
  }) async {
    final filtered = profileType == null
        ? _CapabilityFilter(
            location: location,
            taxonomyTerms: taxonomyTerms ?? const [],
            bio: bio,
            avatarUpload: avatarUpload,
            coverUpload: coverUpload,
          )
        : _filterCapabilities(
            profileType: profileType,
            location: location,
            taxonomyTerms: taxonomyTerms ?? const [],
            bio: bio,
            avatarUpload: avatarUpload,
            coverUpload: coverUpload,
          );
    final profile = await _profilesRepository.updateAccountProfile(
      accountProfileId: accountProfileId,
      profileType: profileType,
      displayName: displayName,
      location: filtered.location,
      taxonomyTerms: taxonomyTerms == null ? null : filtered.taxonomyTerms,
      bio: filtered.bio,
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
    required TenantAdminMediaUpload? avatarUpload,
    required TenantAdminMediaUpload? coverUpload,
  }) {
    final definition = _resolveProfileType(profileType);
    if (definition == null) {
      return _CapabilityFilter(
        location: location,
        taxonomyTerms: taxonomyTerms,
        bio: bio,
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
      avatarUpload: capabilities.hasAvatar ? avatarUpload : null,
      coverUpload: capabilities.hasCover ? coverUpload : null,
    );
  }

  void dispose() {
    _isDisposed = true;
    displayNameController.dispose();
    bioController.dispose();
    latitudeController.dispose();
    longitudeController.dispose();
    for (final controller in taxonomyControllers.values) {
      controller.dispose();
    }
    profilesStreamValue.dispose();
    profileTypesStreamValue.dispose();
    isLoadingStreamValue.dispose();
    errorStreamValue.dispose();
    accountStreamValue.dispose();
    accountProfileStreamValue.dispose();
    accountDetailLoadingStreamValue.dispose();
    accountDetailErrorStreamValue.dispose();
    editStateStreamValue.dispose();
    createStateStreamValue.dispose();
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
  });

  factory TenantAdminAccountProfileCreateState.initial() =>
      const TenantAdminAccountProfileCreateState(
        selectedProfileType: null,
        avatarFile: null,
        coverFile: null,
      );

  final String? selectedProfileType;
  final XFile? avatarFile;
  final XFile? coverFile;

  TenantAdminAccountProfileCreateState copyWith({
    Object? selectedProfileType = _unset,
    Object? avatarFile = _unset,
    Object? coverFile = _unset,
  }) {
    final nextSelectedProfileType = selectedProfileType == _unset
        ? this.selectedProfileType
        : selectedProfileType as String?;
    final nextAvatarFile =
        avatarFile == _unset ? this.avatarFile : avatarFile as XFile?;
    final nextCoverFile =
        coverFile == _unset ? this.coverFile : coverFile as XFile?;

    return TenantAdminAccountProfileCreateState(
      selectedProfileType: nextSelectedProfileType,
      avatarFile: nextAvatarFile,
      coverFile: nextCoverFile,
    );
  }
}

class _CapabilityFilter {
  const _CapabilityFilter({
    required this.location,
    required this.taxonomyTerms,
    required this.bio,
    required this.avatarUpload,
    required this.coverUpload,
  });

  final TenantAdminLocation? location;
  final List<TenantAdminTaxonomyTerm> taxonomyTerms;
  final String? bio;
  final TenantAdminMediaUpload? avatarUpload;
  final TenantAdminMediaUpload? coverUpload;
}
