import 'package:belluga_now/domain/repositories/tenant_admin_account_profiles_repository_contract.dart';
import 'package:belluga_now/domain/repositories/tenant_admin_accounts_repository_contract.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_account.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_account_profile.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_location.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_media_upload.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_profile_type.dart';
import 'package:get_it/get_it.dart' show Disposable, GetIt;
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

  Future<TenantAdminAccountProfile> createProfile({
    required String accountId,
    required String profileType,
    required String displayName,
    TenantAdminLocation? location,
    TenantAdminMediaUpload? avatarUpload,
    TenantAdminMediaUpload? coverUpload,
  }) async {
    final profile = await _profilesRepository.createAccountProfile(
      accountId: accountId,
      profileType: profileType,
      displayName: displayName,
      location: location,
      avatarUpload: avatarUpload,
      coverUpload: coverUpload,
    );
    await loadProfiles(accountId);
    return profile;
  }

  Future<TenantAdminAccountProfile> updateProfile({
    required String accountProfileId,
    String? profileType,
    String? displayName,
    TenantAdminLocation? location,
    TenantAdminMediaUpload? avatarUpload,
    TenantAdminMediaUpload? coverUpload,
  }) async {
    final profile = await _profilesRepository.updateAccountProfile(
      accountProfileId: accountProfileId,
      profileType: profileType,
      displayName: displayName,
      location: location,
      avatarUpload: avatarUpload,
      coverUpload: coverUpload,
    );
    await loadProfiles(profile.accountId);
    return profile;
  }

  void dispose() {
    _isDisposed = true;
    profilesStreamValue.dispose();
    profileTypesStreamValue.dispose();
    isLoadingStreamValue.dispose();
    errorStreamValue.dispose();
  }

  @override
  void onDispose() {
    dispose();
  }
}
