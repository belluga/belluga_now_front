import 'dart:async';

import 'package:belluga_now/domain/repositories/tenant_admin_account_profiles_repository_contract.dart';
import 'package:belluga_now/domain/repositories/tenant_admin_accounts_repository_contract.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_account.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_document.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_profile_type.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_location.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_media_upload.dart';
import 'package:belluga_now/domain/tenant_admin/ownership_state.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart' show Disposable, GetIt;
import 'package:image_picker/image_picker.dart';
import 'package:stream_value/core/stream_value.dart';

class TenantAdminAccountsController implements Disposable {
  TenantAdminAccountsController({
    TenantAdminAccountsRepositoryContract? accountsRepository,
    TenantAdminAccountProfilesRepositoryContract? profilesRepository,
  })  : _accountsRepository =
            accountsRepository ?? GetIt.I.get<TenantAdminAccountsRepositoryContract>(),
        _profilesRepository =
            profilesRepository ?? GetIt.I.get<TenantAdminAccountProfilesRepositoryContract>();

  final TenantAdminAccountsRepositoryContract _accountsRepository;
  final TenantAdminAccountProfilesRepositoryContract _profilesRepository;

  final StreamValue<List<TenantAdminAccount>> accountsStreamValue =
      StreamValue<List<TenantAdminAccount>>(defaultValue: const []);
  final StreamValue<List<TenantAdminProfileTypeDefinition>>
      profileTypesStreamValue =
      StreamValue<List<TenantAdminProfileTypeDefinition>>(defaultValue: const []);
  final StreamValue<bool> isLoadingStreamValue =
      StreamValue<bool>(defaultValue: false);
  final StreamValue<String?> errorStreamValue = StreamValue<String?>();
  final StreamValue<TenantAdminOwnershipState> selectedOwnershipStreamValue =
      StreamValue<TenantAdminOwnershipState>(
    defaultValue: TenantAdminOwnershipState.tenantOwned,
  );
  final StreamValue<TenantAdminAccountCreateState> createStateStreamValue =
      StreamValue<TenantAdminAccountCreateState>(
    defaultValue: TenantAdminAccountCreateState.initial(),
  );
  final TextEditingController nameController = TextEditingController();
  final TextEditingController documentTypeController = TextEditingController();
  final TextEditingController documentNumberController = TextEditingController();
  final TextEditingController profileDisplayNameController =
      TextEditingController();
  final TextEditingController latitudeController = TextEditingController();
  final TextEditingController longitudeController = TextEditingController();

  bool _isDisposed = false;
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    await Future.wait([
      loadAccounts(),
      loadProfileTypes(),
    ]);
  }

  Future<void> loadAccounts() async {
    isLoadingStreamValue.addValue(true);
    try {
      final accounts = await _accountsRepository.fetchAccounts();
      if (_isDisposed) return;
      accountsStreamValue.addValue(accounts);
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

  void updateSelectedOwnership(TenantAdminOwnershipState ownershipState) {
    selectedOwnershipStreamValue.addValue(ownershipState);
  }

  void updateCreateSelectedProfileType(String? profileType) {
    _updateCreateState(
      createStateStreamValue.value.copyWith(selectedProfileType: profileType),
    );
  }

  void updateCreateAvatarFile(XFile? file) {
    _updateCreateState(createStateStreamValue.value.copyWith(avatarFile: file));
  }

  void updateCreateCoverFile(XFile? file) {
    _updateCreateState(createStateStreamValue.value.copyWith(coverFile: file));
  }

  void resetCreateState() {
    _updateCreateState(TenantAdminAccountCreateState.initial());
  }

  Future<TenantAdminAccount> createAccountWithProfile({
    required String name,
    required String documentType,
    required String documentNumber,
    required String profileType,
    required String displayName,
    TenantAdminLocation? location,
    TenantAdminMediaUpload? avatarUpload,
    TenantAdminMediaUpload? coverUpload,
  }) async {
    final account = await _accountsRepository.createAccount(
      name: name,
      document: TenantAdminDocument(
        type: documentType,
        number: documentNumber,
      ),
    );
    await _profilesRepository.createAccountProfile(
      accountId: account.id,
      profileType: profileType,
      displayName: displayName,
      location: location,
      avatarUpload: avatarUpload,
      coverUpload: coverUpload,
    );
    await loadAccounts();
    return account;
  }

  Future<TenantAdminAccount> createAccountFromForm({
    required TenantAdminLocation? location,
    required TenantAdminMediaUpload? avatarUpload,
    required TenantAdminMediaUpload? coverUpload,
  }) async {
    final selectedProfileType =
        createStateStreamValue.value.selectedProfileType ?? '';
    return createAccountWithProfile(
      name: nameController.text.trim(),
      documentType: documentTypeController.text.trim(),
      documentNumber: documentNumberController.text.trim(),
      profileType: selectedProfileType,
      displayName: profileDisplayNameController.text.trim(),
      location: location,
      avatarUpload: avatarUpload,
      coverUpload: coverUpload,
    );
  }

  void resetCreateForm() {
    nameController.clear();
    documentTypeController.clear();
    documentNumberController.clear();
    profileDisplayNameController.clear();
    latitudeController.clear();
    longitudeController.clear();
  }

  void dispose() {
    _isDisposed = true;
    nameController.dispose();
    documentTypeController.dispose();
    documentNumberController.dispose();
    profileDisplayNameController.dispose();
    latitudeController.dispose();
    longitudeController.dispose();
    accountsStreamValue.dispose();
    profileTypesStreamValue.dispose();
    isLoadingStreamValue.dispose();
    errorStreamValue.dispose();
    selectedOwnershipStreamValue.dispose();
    createStateStreamValue.dispose();
  }

  @override
  void onDispose() {
    dispose();
  }
}

class TenantAdminAccountCreateState {
  static const _unset = Object();

  const TenantAdminAccountCreateState({
    required this.selectedProfileType,
    required this.avatarFile,
    required this.coverFile,
  });

  factory TenantAdminAccountCreateState.initial() =>
      const TenantAdminAccountCreateState(
        selectedProfileType: null,
        avatarFile: null,
        coverFile: null,
      );

  final String? selectedProfileType;
  final XFile? avatarFile;
  final XFile? coverFile;

  TenantAdminAccountCreateState copyWith({
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

    return TenantAdminAccountCreateState(
      selectedProfileType: nextSelectedProfileType,
      avatarFile: nextAvatarFile,
      coverFile: nextCoverFile,
    );
  }
}

extension on TenantAdminAccountsController {
  void _updateCreateState(TenantAdminAccountCreateState state) {
    if (_isDisposed) return;
    createStateStreamValue.addValue(state);
  }
}
