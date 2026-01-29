import 'dart:async';

import 'package:belluga_now/domain/repositories/tenant_admin_account_profiles_repository_contract.dart';
import 'package:belluga_now/domain/repositories/tenant_admin_accounts_repository_contract.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_account.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_document.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_profile_type.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_location.dart';
import 'package:get_it/get_it.dart' show Disposable, GetIt;
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

  Future<TenantAdminAccount> createAccountWithProfile({
    required String name,
    required String documentType,
    required String documentNumber,
    required String profileType,
    required String displayName,
    TenantAdminLocation? location,
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
    );
    await loadAccounts();
    return account;
  }

  void dispose() {
    _isDisposed = true;
    accountsStreamValue.dispose();
    profileTypesStreamValue.dispose();
    isLoadingStreamValue.dispose();
    errorStreamValue.dispose();
  }

  @override
  void onDispose() {
    dispose();
  }
}
