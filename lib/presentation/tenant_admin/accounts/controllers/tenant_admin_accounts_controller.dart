import 'dart:async';

import 'package:belluga_now/domain/repositories/tenant_admin_account_profiles_repository_contract.dart';
import 'package:belluga_now/domain/repositories/tenant_admin_accounts_repository_contract.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_account.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_profile_type.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_location.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_media_upload.dart';
import 'package:belluga_now/domain/tenant_admin/ownership_state.dart';
import 'package:belluga_now/domain/services/tenant_admin_location_selection_contract.dart';
import 'package:belluga_now/domain/services/tenant_admin_tenant_scope_contract.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart' show Disposable, GetIt;
import 'package:image_picker/image_picker.dart';
import 'package:stream_value/core/stream_value.dart';

class TenantAdminAccountsController implements Disposable {
  TenantAdminAccountsController({
    TenantAdminAccountsRepositoryContract? accountsRepository,
    TenantAdminAccountProfilesRepositoryContract? profilesRepository,
    TenantAdminLocationSelectionContract? locationSelectionService,
    TenantAdminTenantScopeContract? tenantScope,
  })  : _accountsRepository = accountsRepository ??
            GetIt.I.get<TenantAdminAccountsRepositoryContract>(),
        _profilesRepository = profilesRepository ??
            GetIt.I.get<TenantAdminAccountProfilesRepositoryContract>(),
        _locationSelectionService = locationSelectionService ??
            GetIt.I.get<TenantAdminLocationSelectionContract>(),
        _tenantScope = tenantScope ??
            (GetIt.I.isRegistered<TenantAdminTenantScopeContract>()
                ? GetIt.I.get<TenantAdminTenantScopeContract>()
                : null);

  final TenantAdminAccountsRepositoryContract _accountsRepository;
  final TenantAdminAccountProfilesRepositoryContract _profilesRepository;
  final TenantAdminLocationSelectionContract _locationSelectionService;
  final TenantAdminTenantScopeContract? _tenantScope;

  static const int _accountsPageSize = 20;

  final StreamValue<List<TenantAdminAccount>?> accountsStreamValue =
      StreamValue<List<TenantAdminAccount>?>();
  final StreamValue<bool> hasMoreAccountsStreamValue =
      StreamValue<bool>(defaultValue: true);
  final StreamValue<bool> isAccountsPageLoadingStreamValue =
      StreamValue<bool>(defaultValue: false);
  final StreamValue<List<TenantAdminProfileTypeDefinition>>
      profileTypesStreamValue =
      StreamValue<List<TenantAdminProfileTypeDefinition>>(
          defaultValue: const []);
  final StreamValue<bool> isProfileTypesLoadingStreamValue =
      StreamValue<bool>(defaultValue: false);
  final StreamValue<String?> errorStreamValue = StreamValue<String?>();
  final StreamValue<TenantAdminOwnershipState> selectedOwnershipStreamValue =
      StreamValue<TenantAdminOwnershipState>(
    defaultValue: TenantAdminOwnershipState.tenantOwned,
  );
  final StreamValue<String> searchQueryStreamValue =
      StreamValue<String>(defaultValue: '');
  final StreamValue<bool> createSubmittingStreamValue =
      StreamValue<bool>(defaultValue: false);
  final StreamValue<String?> createErrorMessageStreamValue =
      StreamValue<String?>();
  final StreamValue<TenantAdminAccountCreateState> createStateStreamValue =
      StreamValue<TenantAdminAccountCreateState>(
    defaultValue: TenantAdminAccountCreateState.initial(),
  );
  final GlobalKey<FormState> createFormKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController latitudeController = TextEditingController();
  final TextEditingController longitudeController = TextEditingController();

  bool _isDisposed = false;
  bool _initialized = false;
  bool _isFetchingAccountsPage = false;
  bool _hasMoreAccounts = true;
  int _currentAccountsPage = 0;
  final List<TenantAdminAccount> _fetchedAccounts = <TenantAdminAccount>[];
  String? _initializedTenantDomain;
  StreamSubscription<TenantAdminLocation?>? _locationSelectionSubscription;
  StreamSubscription<String?>? _tenantScopeSubscription;

  Future<void> init() async {
    _bindTenantScope();
    final normalizedTenantDomain =
        _normalizeTenantDomain(_tenantScope?.selectedTenantDomain);
    if (_initialized && _initializedTenantDomain == normalizedTenantDomain) {
      return;
    }
    if (_initialized && _initializedTenantDomain != normalizedTenantDomain) {
      _resetTenantScopedState();
    }
    _initialized = true;
    _initializedTenantDomain = normalizedTenantDomain;
    _bindLocationSelection();
    await Future.wait([
      loadAccounts(),
      loadProfileTypes(),
    ]);
  }

  void _bindTenantScope() {
    if (_tenantScopeSubscription != null || _tenantScope == null) {
      return;
    }
    final tenantScope = _tenantScope;
    _tenantScopeSubscription =
        tenantScope.selectedTenantDomainStreamValue.stream.listen(
      (tenantDomain) {
        if (_isDisposed) return;
        final normalized = _normalizeTenantDomain(tenantDomain);
        if (normalized == _initializedTenantDomain) {
          return;
        }
        _initializedTenantDomain = normalized;
        _initialized = normalized != null;
        _resetTenantScopedState();
        if (normalized != null) {
          unawaited(_loadTenantScopedData());
        }
      },
    );
  }

  Future<void> _loadTenantScopedData() async {
    await Future.wait([
      loadAccounts(),
      loadProfileTypes(),
    ]);
  }

  Future<void> loadAccounts() async {
    await _waitForAccountsFetch();
    _resetAccountsPagination();
    if (_isDisposed) {
      return;
    }
    accountsStreamValue.addValue(null);
    await _fetchAccountsPage(page: 1);
  }

  Future<void> loadNextAccountsPage() async {
    if (_isDisposed || _isFetchingAccountsPage || !_hasMoreAccounts) {
      return;
    }
    await _fetchAccountsPage(page: _currentAccountsPage + 1);
  }

  Future<void> _waitForAccountsFetch() async {
    while (_isFetchingAccountsPage && !_isDisposed) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
  }

  Future<void> _fetchAccountsPage({required int page}) async {
    if (_isFetchingAccountsPage) return;
    if (page > 1 && !_hasMoreAccounts) return;

    _isFetchingAccountsPage = true;
    if (page > 1 && !_isDisposed) {
      isAccountsPageLoadingStreamValue.addValue(true);
    }

    try {
      final result = await _accountsRepository.fetchAccountsPage(
        page: page,
        pageSize: _accountsPageSize,
      );
      if (_isDisposed) return;
      if (page == 1) {
        _fetchedAccounts
          ..clear()
          ..addAll(result.accounts);
      } else {
        _fetchedAccounts.addAll(result.accounts);
      }
      _currentAccountsPage = page;
      _hasMoreAccounts = result.hasMore;
      hasMoreAccountsStreamValue.addValue(_hasMoreAccounts);
      accountsStreamValue
          .addValue(List<TenantAdminAccount>.unmodifiable(_fetchedAccounts));
      errorStreamValue.addValue(null);
    } catch (error) {
      if (_isDisposed) return;
      errorStreamValue.addValue(error.toString());
      if (page == 1) {
        accountsStreamValue.addValue(const <TenantAdminAccount>[]);
      }
    } finally {
      _isFetchingAccountsPage = false;
      if (!_isDisposed) {
        isAccountsPageLoadingStreamValue.addValue(false);
      }
    }
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

  void updateSelectedOwnership(TenantAdminOwnershipState ownershipState) {
    selectedOwnershipStreamValue.addValue(ownershipState);
  }

  void updateSearchQuery(String query) {
    searchQueryStreamValue.addValue(query);
  }

  void updateCreateSelectedProfileType(String? profileType) {
    _updateCreateState(
      createStateStreamValue.value.copyWith(selectedProfileType: profileType),
    );
  }

  void updateCreateOwnershipState(TenantAdminOwnershipState ownershipState) {
    _updateCreateState(
      createStateStreamValue.value.copyWith(ownershipState: ownershipState),
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

  Future<TenantAdminAccount> createAccountWithProfile({
    required String name,
    required TenantAdminOwnershipState ownershipState,
    required String profileType,
    TenantAdminLocation? location,
    TenantAdminMediaUpload? avatarUpload,
    TenantAdminMediaUpload? coverUpload,
  }) async {
    final trimmedName = name.trim();
    final account = await _accountsRepository.createAccount(
      name: trimmedName,
      ownershipState: ownershipState,
    );
    await _profilesRepository.createAccountProfile(
      accountId: account.id,
      profileType: profileType,
      displayName: trimmedName,
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
      ownershipState: createStateStreamValue.value.ownershipState,
      profileType: selectedProfileType,
      location: location,
      avatarUpload: avatarUpload,
      coverUpload: coverUpload,
    );
  }

  Future<bool> submitCreateAccountFromForm({
    required TenantAdminLocation? location,
    required TenantAdminMediaUpload? avatarUpload,
    required TenantAdminMediaUpload? coverUpload,
  }) async {
    createSubmittingStreamValue.addValue(true);
    try {
      await createAccountFromForm(
        location: location,
        avatarUpload: avatarUpload,
        coverUpload: coverUpload,
      );
      if (_isDisposed) return false;
      createErrorMessageStreamValue.addValue(null);
      return true;
    } catch (error) {
      if (_isDisposed) return false;
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

  void resetCreateForm() {
    nameController.clear();
    latitudeController.clear();
    longitudeController.clear();
  }

  void _resetAccountsPagination() {
    _fetchedAccounts.clear();
    _currentAccountsPage = 0;
    _hasMoreAccounts = true;
    _isFetchingAccountsPage = false;
    hasMoreAccountsStreamValue.addValue(true);
    isAccountsPageLoadingStreamValue.addValue(false);
  }

  void _resetTenantScopedState() {
    _resetAccountsPagination();
    accountsStreamValue.addValue(null);
    profileTypesStreamValue.addValue(const []);
    errorStreamValue.addValue(null);
    createErrorMessageStreamValue.addValue(null);
    resetCreateForm();
    resetCreateState();
  }

  String? _normalizeTenantDomain(String? raw) {
    final trimmed = raw?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    final uri =
        Uri.tryParse(trimmed.contains('://') ? trimmed : 'https://$trimmed');
    if (uri != null && uri.host.trim().isNotEmpty) {
      return uri.host.trim();
    }
    return trimmed;
  }

  void dispose() {
    _isDisposed = true;
    _locationSelectionSubscription?.cancel();
    _tenantScopeSubscription?.cancel();
    nameController.dispose();
    latitudeController.dispose();
    longitudeController.dispose();
    accountsStreamValue.dispose();
    hasMoreAccountsStreamValue.dispose();
    isAccountsPageLoadingStreamValue.dispose();
    profileTypesStreamValue.dispose();
    isProfileTypesLoadingStreamValue.dispose();
    errorStreamValue.dispose();
    selectedOwnershipStreamValue.dispose();
    searchQueryStreamValue.dispose();
    createStateStreamValue.dispose();
    createSubmittingStreamValue.dispose();
    createErrorMessageStreamValue.dispose();
  }

  @override
  void onDispose() {
    dispose();
  }
}

class TenantAdminAccountCreateState {
  static const _unset = Object();

  const TenantAdminAccountCreateState({
    required this.ownershipState,
    required this.selectedProfileType,
    required this.avatarFile,
    required this.coverFile,
  });

  factory TenantAdminAccountCreateState.initial() =>
      const TenantAdminAccountCreateState(
        ownershipState: TenantAdminOwnershipState.tenantOwned,
        selectedProfileType: null,
        avatarFile: null,
        coverFile: null,
      );

  final TenantAdminOwnershipState ownershipState;
  final String? selectedProfileType;
  final XFile? avatarFile;
  final XFile? coverFile;

  TenantAdminAccountCreateState copyWith({
    Object? ownershipState = _unset,
    Object? selectedProfileType = _unset,
    Object? avatarFile = _unset,
    Object? coverFile = _unset,
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

    return TenantAdminAccountCreateState(
      ownershipState: nextOwnershipState,
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
