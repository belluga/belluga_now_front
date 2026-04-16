import 'dart:async';

import 'package:belluga_now/domain/repositories/tenant_admin_account_profiles_repository_contract.dart';
import 'package:belluga_now/domain/repositories/tenant_admin_accounts_repository_contract.dart';
import 'package:belluga_now/domain/tenant_admin/ownership_state.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_account.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_account_profile.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_profile_type.dart';
import 'package:get_it/get_it.dart' show Disposable, GetIt;
import 'package:stream_value/core/stream_value.dart';

class TenantAdminAccountDetailController implements Disposable {
  TenantAdminAccountDetailController({
    TenantAdminAccountProfilesRepositoryContract? profilesRepository,
    TenantAdminAccountsRepositoryContract? accountsRepository,
  })  : _profilesRepository = profilesRepository ??
            GetIt.I.get<TenantAdminAccountProfilesRepositoryContract>(),
        _accountsRepository = accountsRepository ??
            GetIt.I.get<TenantAdminAccountsRepositoryContract>();

  final TenantAdminAccountProfilesRepositoryContract _profilesRepository;
  final TenantAdminAccountsRepositoryContract _accountsRepository;

  final StreamValue<TenantAdminAccount?> _accountDetailStreamValue =
      StreamValue<TenantAdminAccount?>();
  final StreamValue<TenantAdminAccountProfile?> accountProfileStreamValue =
      StreamValue<TenantAdminAccountProfile?>();
  final StreamValue<List<TenantAdminProfileTypeDefinition>>
      profileTypesStreamValue =
      StreamValue<List<TenantAdminProfileTypeDefinition>>(
    defaultValue: const [],
  );
  final StreamValue<bool> accountDetailLoadingStreamValue =
      StreamValue<bool>(defaultValue: false);
  final StreamValue<String?> accountDetailErrorStreamValue =
      StreamValue<String?>();
  final StreamValue<bool> accountUpdatingStreamValue =
      StreamValue<bool>(defaultValue: false);
  final StreamValue<bool> accountDeletingStreamValue =
      StreamValue<bool>(defaultValue: false);
  final StreamValue<bool> accountDeletedStreamValue =
      StreamValue<bool>(defaultValue: false);

  bool _isDisposed = false;
  int _accountDetailLoadVersion = 0;
  StreamSubscription<TenantAdminAccount?>? _accountWatchSubscription;
  TenantAdminLoadedAccountWatch? _accountWatch;
  String? _watchedAccountId;
  String? _watchedAccountSlug;

  StreamValue<TenantAdminAccount?> get accountStreamValue =>
      _accountDetailStreamValue;

  Future<TenantAdminAccount> resolveAccountBySlug(String slug) async {
    return _accountsRepository.fetchAccountBySlug(
      TenantAdminAccountsRepositoryContractPrimString.fromRaw(
        slug,
        defaultValue: '',
        isRequired: true,
      ),
    );
  }

  Future<TenantAdminAccountProfile?> fetchProfileForAccount(
    String accountId,
  ) async {
    final profiles = await _profilesRepository.fetchAccountProfiles(
      accountId: tenantAdminAccountProfilesRepoString(
        accountId,
        defaultValue: '',
        isRequired: true,
      ),
    );
    if (profiles.isEmpty) {
      return null;
    }
    return profiles.first;
  }

  Future<void> loadProfileTypes() async {
    await _profilesRepository.loadAllProfileTypes();
    final types = _profilesRepository.profileTypesStreamValue.value ??
        const <TenantAdminProfileTypeDefinition>[];
    if (_isDisposed) {
      return;
    }
    profileTypesStreamValue.addValue(types);
  }

  Future<void> loadAccountDetail(String accountSlug) async {
    final requestVersion = ++_accountDetailLoadVersion;
    accountDetailLoadingStreamValue.addValue(true);
    accountDetailErrorStreamValue.addValue(null);
    try {
      await loadProfileTypes();
      if (!_isActiveAccountDetailLoad(requestVersion)) {
        return;
      }
      final account = await resolveAccountBySlug(accountSlug);
      if (!_isActiveAccountDetailLoad(requestVersion)) {
        return;
      }
      _bindAccountWatch(
        accountId: account.id,
        accountSlug: account.slug,
      );
      final profile = await fetchProfileForAccount(account.id);
      if (!_isActiveAccountDetailLoad(requestVersion)) {
        return;
      }
      accountProfileStreamValue.addValue(profile);
      accountDetailErrorStreamValue.addValue(null);
    } catch (error) {
      if (!_isActiveAccountDetailLoad(requestVersion)) {
        return;
      }
      accountDetailErrorStreamValue.addValue(error.toString());
    } finally {
      if (_isActiveAccountDetailLoad(requestVersion)) {
        accountDetailLoadingStreamValue.addValue(false);
      }
    }
  }

  Future<TenantAdminAccount?> updateAccount({
    required String accountSlug,
    String? name,
    String? slug,
    TenantAdminOwnershipState? ownershipState,
  }) async {
    accountUpdatingStreamValue.addValue(true);
    try {
      final updated = await _accountsRepository.updateAccount(
        accountSlug: TenantAdminAccountsRepositoryContractPrimString.fromRaw(
          accountSlug,
          defaultValue: '',
          isRequired: true,
        ),
        name: name == null
            ? null
            : TenantAdminAccountsRepositoryContractPrimString.fromRaw(
                name,
                defaultValue: '',
              ),
        slug: slug == null
            ? null
            : TenantAdminAccountsRepositoryContractPrimString.fromRaw(
                slug,
                defaultValue: '',
              ),
        ownershipState: ownershipState,
      );
      if (_isDisposed) {
        return null;
      }
      _bindAccountWatch(
        accountId: updated.id,
        accountSlug: updated.slug,
      );
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

  Future<bool> deleteAccount({
    required String accountSlug,
  }) async {
    accountDeletingStreamValue.addValue(true);
    try {
      await _accountsRepository.deleteAccount(
        TenantAdminAccountsRepositoryContractPrimString.fromRaw(
          accountSlug,
          defaultValue: '',
          isRequired: true,
        ),
      );
      if (_isDisposed) {
        return false;
      }
      _clearAccountWatch();
      _watchedAccountId = null;
      _watchedAccountSlug = null;
      _accountDetailStreamValue.addValue(null);
      accountProfileStreamValue.addValue(null);
      accountDetailErrorStreamValue.addValue(null);
      accountDeletedStreamValue.addValue(true);
      return true;
    } catch (error) {
      if (_isDisposed) {
        return false;
      }
      accountDetailErrorStreamValue.addValue(error.toString());
      return false;
    } finally {
      if (!_isDisposed) {
        accountDeletingStreamValue.addValue(false);
      }
    }
  }

  void clearAccountDeletedFlag() {
    if (_isDisposed) {
      return;
    }
    accountDeletedStreamValue.addValue(false);
  }

  void resetAccountDetail() {
    if (_isDisposed) {
      return;
    }
    _accountDetailLoadVersion += 1;
    _clearAccountWatch();
    _watchedAccountId = null;
    _watchedAccountSlug = null;
    _accountDetailStreamValue.addValue(null);
    accountProfileStreamValue.addValue(null);
    accountDetailErrorStreamValue.addValue(null);
    accountDetailLoadingStreamValue.addValue(false);
    accountUpdatingStreamValue.addValue(false);
    accountDeletingStreamValue.addValue(false);
    accountDeletedStreamValue.addValue(false);
  }

  void _bindAccountWatch({
    required String? accountId,
    required String? accountSlug,
  }) {
    final normalizedId = accountId?.trim();
    final normalizedSlug = accountSlug?.trim();
    final isSameBinding = _accountWatch != null &&
        _watchedAccountId == normalizedId &&
        _watchedAccountSlug == normalizedSlug;
    if (isSameBinding) {
      _accountDetailStreamValue.addValue(_accountWatch!.streamValue.value);
      return;
    }
    _clearAccountWatch();
    _watchedAccountId = normalizedId;
    _watchedAccountSlug = normalizedSlug;
    _accountWatch = _accountsRepository.watchLoadedAccount(
      accountId: normalizedId == null
          ? null
          : TenantAdminAccountsRepositoryContractPrimString.fromRaw(
              normalizedId,
            ),
      accountSlug: normalizedSlug == null
          ? null
          : TenantAdminAccountsRepositoryContractPrimString.fromRaw(
              normalizedSlug,
            ),
    );
    _accountDetailStreamValue.addValue(_accountWatch!.streamValue.value);
    _accountWatchSubscription = _accountWatch!.streamValue.stream.listen((
      account,
    ) {
      if (_isDisposed) {
        return;
      }
      _accountDetailStreamValue.addValue(account);
    });
  }

  void _clearAccountWatch() {
    final subscription = _accountWatchSubscription;
    if (subscription != null) {
      unawaited(subscription.cancel());
      _accountWatchSubscription = null;
    }
    _accountWatch?.dispose();
    _accountWatch = null;
  }

  bool _isActiveAccountDetailLoad(int requestVersion) {
    return !_isDisposed && _accountDetailLoadVersion == requestVersion;
  }

  @override
  void onDispose() {
    _isDisposed = true;
    _accountDetailLoadVersion += 1;
    _clearAccountWatch();
    _accountDetailStreamValue.dispose();
    accountProfileStreamValue.dispose();
    profileTypesStreamValue.dispose();
    accountDetailLoadingStreamValue.dispose();
    accountDetailErrorStreamValue.dispose();
    accountUpdatingStreamValue.dispose();
    accountDeletingStreamValue.dispose();
    accountDeletedStreamValue.dispose();
  }
}
