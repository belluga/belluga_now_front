import 'dart:async';

import 'package:belluga_now/domain/repositories/tenant_admin_account_profiles_repository_contract.dart';
import 'package:belluga_now/domain/repositories/tenant_admin_accounts_repository_contract.dart';
import 'package:belluga_now/domain/repositories/tenant_admin_taxonomies_repository_contract.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_account.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_profile_type.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_location.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_media_upload.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_definition.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_term.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_term_definition.dart';
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
    TenantAdminTaxonomiesRepositoryContract? taxonomiesRepository,
    TenantAdminLocationSelectionContract? locationSelectionService,
    TenantAdminTenantScopeContract? tenantScope,
  })  : _accountsRepository = accountsRepository ??
            GetIt.I.get<TenantAdminAccountsRepositoryContract>(),
        _profilesRepository = profilesRepository ??
            GetIt.I.get<TenantAdminAccountProfilesRepositoryContract>(),
        _taxonomiesRepository = taxonomiesRepository ??
            GetIt.I.get<TenantAdminTaxonomiesRepositoryContract>(),
        _locationSelectionService = locationSelectionService ??
            GetIt.I.get<TenantAdminLocationSelectionContract>(),
        _tenantScope = tenantScope ??
            (GetIt.I.isRegistered<TenantAdminTenantScopeContract>()
                ? GetIt.I.get<TenantAdminTenantScopeContract>()
                : null);

  final TenantAdminAccountsRepositoryContract _accountsRepository;
  final TenantAdminAccountProfilesRepositoryContract _profilesRepository;
  final TenantAdminTaxonomiesRepositoryContract _taxonomiesRepository;
  final TenantAdminLocationSelectionContract _locationSelectionService;
  final TenantAdminTenantScopeContract? _tenantScope;

  static const int _accountsPageSize = 20;

  StreamValue<List<TenantAdminAccount>?> get accountsStreamValue =>
      _accountsRepository.accountsStreamValue;
  StreamValue<bool> get hasMoreAccountsStreamValue =>
      _accountsRepository.hasMoreAccountsStreamValue;
  StreamValue<bool> get isAccountsPageLoadingStreamValue =>
      _accountsRepository.isAccountsPageLoadingStreamValue;
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
  final StreamValue<bool> showSearchFieldStreamValue =
      StreamValue<bool>(defaultValue: false);
  final StreamValue<bool> createSubmittingStreamValue =
      StreamValue<bool>(defaultValue: false);
  final StreamValue<String?> createErrorMessageStreamValue =
      StreamValue<String?>();
  final StreamValue<TenantAdminAccountCreateDraft> createStateStreamValue =
      StreamValue<TenantAdminAccountCreateDraft>(
    defaultValue: TenantAdminAccountCreateDraft.initial(),
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

  bool _isDisposed = false;
  bool _initialized = false;
  String? _initializedTenantDomain;
  StreamSubscription<TenantAdminLocation?>? _locationSelectionSubscription;
  StreamSubscription<String?>? _tenantScopeSubscription;
  StreamSubscription<String?>? _accountsRepositoryErrorSubscription;

  Future<void> init() async {
    _bindAccountsRepositoryError();
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
      loadAccounts(ownershipState: selectedOwnershipStreamValue.value),
      loadProfileTypes(),
      loadTaxonomies(),
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
      loadAccounts(ownershipState: selectedOwnershipStreamValue.value),
      loadProfileTypes(),
      loadTaxonomies(),
    ]);
  }

  Future<void> loadAccounts({
    TenantAdminOwnershipState? ownershipState,
  }) async {
    _bindAccountsRepositoryError();
    if (_isDisposed) {
      return;
    }
    await _accountsRepository.loadAccounts(
      pageSize: _accountsPageSize,
      ownershipState: ownershipState ?? selectedOwnershipStreamValue.value,
    );
  }

  Future<void> loadNextAccountsPage({
    TenantAdminOwnershipState? ownershipState,
  }) async {
    _bindAccountsRepositoryError();
    if (_isDisposed) {
      return;
    }
    await _accountsRepository.loadNextAccountsPage(
      pageSize: _accountsPageSize,
      ownershipState: ownershipState ?? selectedOwnershipStreamValue.value,
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

  void updateSelectedOwnership(TenantAdminOwnershipState ownershipState) {
    if (selectedOwnershipStreamValue.value == ownershipState) {
      return;
    }
    selectedOwnershipStreamValue.addValue(ownershipState);
    unawaited(loadAccounts(ownershipState: ownershipState));
  }

  void updateSearchQuery(String query) {
    searchQueryStreamValue.addValue(query);
  }

  void toggleSearchFieldVisibility() {
    final next = !showSearchFieldStreamValue.value;
    showSearchFieldStreamValue.addValue(next);
    if (!next) {
      updateSearchQuery('');
    }
  }

  void updateCreateSelectedProfileType(String? profileType) {
    _updateCreateState(
      createStateStreamValue.value.copyWith(selectedProfileType: profileType),
    );
    unawaited(_refreshTaxonomyTermsForSelectedProfileType());
  }

  void updateCreateOwnershipState(TenantAdminOwnershipState ownershipState) {
    _updateCreateState(
      createStateStreamValue.value.copyWith(ownershipState: ownershipState),
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
  }

  void updateCreateCoverWebUrl(String? url) {
    final trimmed = url?.trim();
    _updateCreateState(
      createStateStreamValue.value.copyWith(
        coverWebUrl: trimmed == null || trimmed.isEmpty ? null : trimmed,
        coverFile: null,
      ),
    );
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
  }

  void resetCreateState() {
    _updateCreateState(TenantAdminAccountCreateDraft.initial());
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
    String? bio,
    String? content,
    List<TenantAdminTaxonomyTerm> taxonomyTerms = const [],
    String? avatarUrl,
    String? coverUrl,
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
      taxonomyTerms: taxonomyTerms,
      bio: bio,
      content: content,
      avatarUrl: avatarUrl,
      coverUrl: coverUrl,
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
    return createAccountWithProfile(
      name: nameController.text.trim(),
      ownershipState: createStateStreamValue.value.ownershipState,
      profileType: selectedProfileType,
      location: location,
      bio: filteredBio,
      content: filteredContent,
      taxonomyTerms: filteredTaxonomyTerms,
      avatarUrl: null,
      coverUrl: null,
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
    bioController.clear();
    contentController.clear();
    latitudeController.clear();
    longitudeController.clear();
    selectedTaxonomyTermsStreamValue.addValue(const {});
  }

  void _bindAccountsRepositoryError() {
    if (_accountsRepositoryErrorSubscription != null) {
      return;
    }
    _accountsRepositoryErrorSubscription =
        _accountsRepository.accountsErrorStreamValue.stream.listen(
      (error) {
        if (_isDisposed) {
          return;
        }
        errorStreamValue.addValue(error);
      },
    );
  }

  void _resetTenantScopedState() {
    _accountsRepository.resetAccountsState();
    profileTypesStreamValue.addValue(const []);
    errorStreamValue.addValue(null);
    taxonomiesStreamValue.addValue(const []);
    taxonomyTermsStreamValue.addValue(const {});
    selectedTaxonomyTermsStreamValue.addValue(const {});
    taxonomiesErrorStreamValue.addValue(null);
    createErrorMessageStreamValue.addValue(null);
    resetCreateForm();
    resetCreateState();
    showSearchFieldStreamValue.addValue(false);
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
    _accountsRepositoryErrorSubscription?.cancel();
    nameController.dispose();
    bioController.dispose();
    contentController.dispose();
    latitudeController.dispose();
    longitudeController.dispose();
    profileTypesStreamValue.dispose();
    isProfileTypesLoadingStreamValue.dispose();
    errorStreamValue.dispose();
    selectedOwnershipStreamValue.dispose();
    searchQueryStreamValue.dispose();
    showSearchFieldStreamValue.dispose();
    createStateStreamValue.dispose();
    taxonomiesStreamValue.dispose();
    taxonomyTermsStreamValue.dispose();
    selectedTaxonomyTermsStreamValue.dispose();
    taxonomiesLoadingStreamValue.dispose();
    taxonomiesErrorStreamValue.dispose();
    createSubmittingStreamValue.dispose();
    createErrorMessageStreamValue.dispose();
  }

  @override
  void onDispose() {
    dispose();
  }
}

extension on TenantAdminAccountsController {
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

extension on TenantAdminAccountsController {
  void _updateCreateState(TenantAdminAccountCreateDraft state) {
    if (_isDisposed) return;
    createStateStreamValue.addValue(state);
  }
}
