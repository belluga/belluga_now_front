export 'tenant_admin_account_profile_create_draft.dart';
export 'tenant_admin_account_profile_edit_draft.dart';

import 'dart:async';
import 'dart:typed_data';

import 'package:belluga_contact_channels/belluga_contact_channels.dart';
import 'package:belluga_form_validation/belluga_form_validation.dart';
import 'package:belluga_now/application/tenant_admin/tenant_admin_account_profile_candidate_discovery_page_loader.dart';
import 'package:belluga_now/application/tenant_admin/tenant_admin_account_profile_candidates_page_loader.dart';
import 'package:belluga_now/application/tenant_admin/tenant_admin_nested_group_members_page_loader.dart';
import 'package:belluga_now/domain/repositories/tenant_admin_account_profiles_repository_contract.dart';
import 'package:belluga_now/domain/repositories/tenant_admin_accounts_repository_contract.dart';
import 'package:belluga_now/domain/repositories/tenant_admin_taxonomies_repository_contract.dart';
import 'package:belluga_now/domain/partners/value_objects/account_profile_name_value.dart';
import 'package:belluga_now/domain/tenant_admin/ownership_state.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_account.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_account_profile.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_account_profile_gallery_item.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_account_profile_gallery_snapshot.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_account_profile_candidate_scope.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_account_profile_candidate_selection_summary.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_location.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_media_upload.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_nested_group_member_page.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_nested_group_member_mutation_result.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_profile_type.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_definition.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_term_definition.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_unknown_mutation_failure.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_count_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_optional_text_value.dart';
import 'package:belluga_now/domain/services/tenant_admin_location_selection_contract.dart';
import 'package:belluga_now/domain/services/tenant_admin_tenant_scope_contract.dart';
import 'package:belluga_now/presentation/tenant_admin/account_profiles/controllers/tenant_admin_account_profile_create_draft.dart';
import 'package:belluga_now/presentation/tenant_admin/account_profiles/controllers/tenant_admin_account_profile_candidate_picker_controller.dart';
import 'package:belluga_now/presentation/tenant_admin/account_profiles/controllers/tenant_admin_account_profile_edit_draft.dart';
import 'package:belluga_now/presentation/tenant_admin/account_profiles/controllers/tenant_admin_account_profile_gallery_group_draft.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/utils/tenant_admin_account_profile_gallery_operations.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/utils/tenant_admin_image_ingestion_service.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/utils/tenant_admin_nested_profile_group_operations.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/models/tenant_admin_group_label_mutation_state.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart' show Disposable, GetIt;
import 'package:image_picker/image_picker.dart';
import 'package:stream_value/core/stream_value.dart';
import 'package:value_object_pattern/domain/exceptions/value_exceptions.dart';

class TenantAdminAccountProfilesController implements Disposable {
  TenantAdminAccountProfilesController({
    TenantAdminAccountProfilesRepositoryContract? profilesRepository,
    TenantAdminAccountsRepositoryContract? accountsRepository,
    TenantAdminTaxonomiesRepositoryContract? taxonomiesRepository,
    TenantAdminLocationSelectionContract? locationSelectionService,
    TenantAdminTenantScopeContract? tenantScope,
    TenantAdminImageIngestionService? imageIngestionService,
    TenantAdminAccountProfileCandidatesPageLoader?
    nestedProfileCandidatesPageLoader,
    TenantAdminNestedGroupMembersPageLoader? nestedGroupMembersPageLoader,
  }) : _profilesRepository =
           profilesRepository ??
           GetIt.I.get<TenantAdminAccountProfilesRepositoryContract>(),
       _accountsRepository =
           accountsRepository ??
           GetIt.I.get<TenantAdminAccountsRepositoryContract>(),
       _taxonomiesRepository =
           taxonomiesRepository ??
           GetIt.I.get<TenantAdminTaxonomiesRepositoryContract>(),
       _locationSelectionService =
           locationSelectionService ??
           GetIt.I.get<TenantAdminLocationSelectionContract>(),
       _tenantScope =
           tenantScope ??
           (GetIt.I.isRegistered<TenantAdminTenantScopeContract>()
               ? GetIt.I.get<TenantAdminTenantScopeContract>()
               : null),
       _imageIngestionService =
           imageIngestionService ??
           (GetIt.I.isRegistered<TenantAdminImageIngestionService>()
               ? GetIt.I.get<TenantAdminImageIngestionService>()
               : TenantAdminImageIngestionService()) {
    _nestedProfileCandidatesPageLoader =
        nestedProfileCandidatesPageLoader ??
        TenantAdminAccountProfileCandidatesPageLoader(
          profilesRepository: _profilesRepository,
        );
    _nestedGroupMembersPageLoader =
        nestedGroupMembersPageLoader ??
        TenantAdminNestedGroupMembersPageLoader(
          profilesRepository: _profilesRepository,
        );
    _bindTenantScope();
  }

  final TenantAdminAccountProfilesRepositoryContract _profilesRepository;
  final TenantAdminAccountsRepositoryContract _accountsRepository;
  final TenantAdminTaxonomiesRepositoryContract _taxonomiesRepository;
  final TenantAdminLocationSelectionContract _locationSelectionService;
  final TenantAdminTenantScopeContract? _tenantScope;
  final TenantAdminImageIngestionService _imageIngestionService;
  late final TenantAdminAccountProfileCandidatesPageLoader
  _nestedProfileCandidatesPageLoader;
  late final TenantAdminNestedGroupMembersPageLoader
  _nestedGroupMembersPageLoader;

  String? validateDisplayName(String? value) {
    try {
      AccountProfileNameValue().validate(value);
      return null;
    } on RequiredValueException {
      return 'Nome de exibicao e obrigatorio.';
    } on TooShortValueException {
      return 'Nome de exibicao deve ter pelo menos '
          '${AccountProfileNameValue.minimumLength} caracteres.';
    } on TooLongValueException {
      return 'Nome de exibicao deve ter no maximo '
          '${AccountProfileNameValue.maximumLength} caracteres.';
    }
  }

  final StreamValue<List<TenantAdminAccountProfile>> profilesStreamValue =
      StreamValue<List<TenantAdminAccountProfile>>(defaultValue: const []);
  final StreamValue<List<TenantAdminAccountProfile>>
  nestedProfileCandidatesStreamValue =
      StreamValue<List<TenantAdminAccountProfile>>(defaultValue: const []);
  final StreamValue<List<TenantAdminAccountProfile>>
  contactSourceCandidatesStreamValue =
      StreamValue<List<TenantAdminAccountProfile>>(defaultValue: const []);
  final StreamValue<bool> contactSourceCandidatesLoadingStreamValue =
      StreamValue<bool>(defaultValue: false);
  final StreamValue<bool> contactSourceCandidatesPageLoadingStreamValue =
      StreamValue<bool>(defaultValue: false);
  final StreamValue<bool> contactSourceCandidatesHasMoreStreamValue =
      StreamValue<bool>(defaultValue: false);
  final StreamValue<String?> contactSourceCandidatesErrorStreamValue =
      StreamValue<String?>();
  final StreamValue<bool> nestedProfileSearchLoadingStreamValue =
      StreamValue<bool>(defaultValue: false);
  final StreamValue<bool> nestedProfileSearchPageLoadingStreamValue =
      StreamValue<bool>(defaultValue: false);
  final StreamValue<bool> nestedProfileSearchHasMoreStreamValue =
      StreamValue<bool>(defaultValue: false);
  final StreamValue<List<TenantAdminProfileTypeDefinition>>
  profileTypesStreamValue = StreamValue<List<TenantAdminProfileTypeDefinition>>(
    defaultValue: const [],
  );
  final StreamValue<List<TenantAdminTaxonomyDefinition>> taxonomiesStreamValue =
      StreamValue<List<TenantAdminTaxonomyDefinition>>(defaultValue: const []);
  final StreamValue<Map<String, List<TenantAdminTaxonomyTermDefinition>>>
  taxonomyTermsStreamValue =
      StreamValue<Map<String, List<TenantAdminTaxonomyTermDefinition>>>(
        defaultValue: const {},
      );
  final StreamValue<Map<String, Set<String>>> taxonomySelectionStreamValue =
      StreamValue<Map<String, Set<String>>>(defaultValue: const {});
  final StreamValue<bool> isLoadingStreamValue = StreamValue<bool>(
    defaultValue: false,
  );
  final StreamValue<String?> errorStreamValue = StreamValue<String?>();
  final StreamValue<TenantAdminAccount?> _accountDetailStreamValue =
      StreamValue<TenantAdminAccount?>();
  final StreamValue<TenantAdminAccountProfile?> accountProfileStreamValue =
      StreamValue<TenantAdminAccountProfile?>();
  final StreamValue<bool> accountDetailLoadingStreamValue = StreamValue<bool>(
    defaultValue: false,
  );
  final StreamValue<String?> accountDetailErrorStreamValue =
      StreamValue<String?>();
  final StreamValue<bool> accountUpdatingStreamValue = StreamValue<bool>(
    defaultValue: false,
  );
  final StreamValue<bool> accountDeletingStreamValue = StreamValue<bool>(
    defaultValue: false,
  );
  final StreamValue<bool> accountDeletedStreamValue = StreamValue<bool>(
    defaultValue: false,
  );
  final StreamValue<TenantAdminAccountProfileEditDraft> editStateStreamValue =
      StreamValue<TenantAdminAccountProfileEditDraft>(
        defaultValue: TenantAdminAccountProfileEditDraft.initial(),
      );
  final StreamValue<bool> editLoadingStreamValue = StreamValue<bool>(
    defaultValue: false,
  );
  final StreamValue<String?> editLoadErrorStreamValue = StreamValue<String?>();
  final StreamValue<bool> editSubmittingStreamValue = StreamValue<bool>(
    defaultValue: false,
  );
  final StreamValue<String?> editSuccessMessageStreamValue =
      StreamValue<String?>();
  final StreamValue<String?> editErrorMessageStreamValue =
      StreamValue<String?>();
  final StreamValue<bool> editGalleryMutationBusyStreamValue =
      StreamValue<bool>(defaultValue: false);
  final StreamValue<Map<String, String>> editGalleryFieldErrorsStreamValue =
      StreamValue<Map<String, String>>(defaultValue: const {});
  final StreamValue<String?> editGalleryOperationErrorStreamValue =
      StreamValue<String?>();
  final StreamValue<bool> editNestedGroupMutationBusyStreamValue =
      StreamValue<bool>(defaultValue: false);
  final StreamValue<bool> taxonomyAutosavingStreamValue = StreamValue<bool>(
    defaultValue: false,
  );
  final StreamValue<TenantAdminAccountProfileCreateDraft>
  createStateStreamValue = StreamValue<TenantAdminAccountProfileCreateDraft>(
    defaultValue: TenantAdminAccountProfileCreateDraft.initial(),
  );
  final StreamValue<bool> createSubmittingStreamValue = StreamValue<bool>(
    defaultValue: false,
  );
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
  final TextEditingController contentController = TextEditingController();
  final TextEditingController latitudeController = TextEditingController();
  final TextEditingController longitudeController = TextEditingController();

  bool _isDisposed = false;
  StreamSubscription<String?>? _tenantScopeSubscription;
  String? _lastTenantDomain;
  final Map<String, StreamValue<TenantAdminGroupLabelMutationState>>
  _nestedGroupLabelStates = {};

  String _nestedGroupLabelKey(String accountProfileId, String groupId) =>
      'account_profile::${_lastTenantDomain ?? 'unscoped'}::$accountProfileId::$groupId';

  void _bindTenantScope() {
    final tenantScope = _tenantScope;
    if (tenantScope == null) return;
    _lastTenantDomain = tenantScope.selectedTenantDomain?.trim();
    _tenantScopeSubscription = tenantScope
        .selectedTenantDomainStreamValue
        .stream
        .listen((value) {
          final normalized = value?.trim();
          if (_isDisposed || normalized == _lastTenantDomain) return;
          _lastTenantDomain = normalized;
          _clearNestedGroupLabelStates();
        });
  }

  StreamValue<TenantAdminGroupLabelMutationState> nestedGroupLabelState({
    required String accountProfileId,
    required String groupId,
    required String label,
  }) => _nestedGroupLabelStates.putIfAbsent(
    _nestedGroupLabelKey(accountProfileId, groupId),
    () => StreamValue<TenantAdminGroupLabelMutationState>(
      defaultValue: TenantAdminGroupLabelMutationState(draft: label),
    ),
  );

  void _clearNestedGroupLabelStates() {
    for (final state in _nestedGroupLabelStates.values) {
      state.dispose();
    }
    _nestedGroupLabelStates.clear();
  }

  void beginNestedGroupLabelEdit({
    required String accountProfileId,
    required String groupId,
    required String label,
  }) {
    final state = nestedGroupLabelState(
      accountProfileId: accountProfileId,
      groupId: groupId,
      label: label,
    );
    state.addValue(
      TenantAdminGroupLabelMutationState(
        draft: state.value.draft,
        isEditing: true,
      ),
    );
  }

  void changeNestedGroupLabelDraft({
    required String accountProfileId,
    required String groupId,
    required String label,
  }) {
    final state = nestedGroupLabelState(
      accountProfileId: accountProfileId,
      groupId: groupId,
      label: label,
    );
    state.addValue(
      TenantAdminGroupLabelMutationState(draft: label, isEditing: true),
    );
  }

  Future<void> saveNestedGroupLabel({
    required String accountProfileId,
    required String groupId,
    required String authoritativeLabel,
  }) async {
    final key = _nestedGroupLabelKey(accountProfileId, groupId);
    final state = nestedGroupLabelState(
      accountProfileId: accountProfileId,
      groupId: groupId,
      label: authoritativeLabel,
    );
    bool isCurrentState() => identical(_nestedGroupLabelStates[key], state);
    if (state.value.isLoading) return;
    final label = state.value.draft.trim();
    if (label == authoritativeLabel.trim()) {
      state.addValue(
        TenantAdminGroupLabelMutationState(
          draft: authoritativeLabel,
          isEditing: false,
        ),
      );
      return;
    }
    if (label.isEmpty) {
      state.addValue(
        TenantAdminGroupLabelMutationState(
          draft: state.value.draft,
          isEditing: true,
          errorText: 'Nome da aba é obrigatório.',
        ),
      );
      return;
    }
    if (label.length > TenantAdminGroupLabelMutationState.maxLabelLength) {
      state.addValue(
        TenantAdminGroupLabelMutationState(
          draft: state.value.draft,
          isEditing: true,
          errorText: 'Nome da aba deve ter no máximo 255 caracteres.',
        ),
      );
      return;
    }
    state.addValue(
      TenantAdminGroupLabelMutationState(
        draft: label,
        isEditing: true,
        isLoading: true,
      ),
    );
    try {
      final result = await _profilesRepository.patchNestedProfileGroupLabel(
        accountProfileId: tenantAdminAccountProfilesRepoString(
          accountProfileId,
          defaultValue: '',
          isRequired: true,
        ),
        groupId: tenantAdminAccountProfilesRepoString(
          groupId,
          defaultValue: '',
          isRequired: true,
        ),
        label: tenantAdminAccountProfilesRepoString(
          label,
          defaultValue: '',
          isRequired: true,
        ),
      );
      if (_isDisposed || !isCurrentState()) {
        return;
      }
      if (result.id != groupId) {
        throw const FormatException('Nested group label response id mismatch.');
      }
      final groups = editStateStreamValue.value.nestedProfileGroups
          .map(
            (entry) => entry.id == groupId
                ? entry.copyWith(
                    labelValue: TenantAdminNestedProfileGroupTextValue(
                      result.label,
                    ),
                  )
                : entry,
          )
          .toList(growable: false);
      _applyEditNestedProfileGroupHeadMutation(
        groups: groups,
        invalidateAggregateRevision: true,
      );
      state.addValue(TenantAdminGroupLabelMutationState(draft: result.label));
    } on TenantAdminUnknownMutationFailure {
      if (!_isDisposed && isCurrentState()) {
        state.addValue(
          TenantAdminGroupLabelMutationState(
            draft: label,
            isEditing: true,
            errorText:
                'Não foi possível confirmar o salvamento. Tente novamente.',
          ),
        );
      }
    } catch (error) {
      if (!_isDisposed && isCurrentState()) {
        state.addValue(
          TenantAdminGroupLabelMutationState(
            draft: label,
            isEditing: true,
            errorText: _describeGroupLabelError(
              error,
              'Não foi possível salvar o grupo.',
            ),
          ),
        );
      }
    }
  }

  Timer? _nestedProfileSearchDebounce;
  Timer? _contactSourceSearchDebounce;
  StreamSubscription<TenantAdminLocation?>? _locationSelectionSubscription;
  StreamSubscription<TenantAdminAccount?>? _accountWatchSubscription;
  TenantAdminLoadedAccountWatch? _accountWatch;
  TenantAdminAccountProfile? _loadedEditProfileSnapshot;
  String? _watchedAccountId;
  String? _watchedAccountSlug;
  bool _removeAvatarOnSubmit = false;
  bool _removeCoverOnSubmit = false;
  static const Duration _nestedProfileSearchDebounceDuration = Duration(
    milliseconds: 250,
  );
  final List<TenantAdminAccountProfile> _nestedProfileCandidateWindow =
      <TenantAdminAccountProfile>[];
  final List<TenantAdminAccountProfile> _contactSourceCandidateWindow =
      <TenantAdminAccountProfile>[];
  final Map<String, TenantAdminAccountProfile> _selectedNestedProfileCache =
      <String, TenantAdminAccountProfile>{};
  final Map<String, TenantAdminAccountProfile> _selectedContactSourceCache =
      <String, TenantAdminAccountProfile>{};
  final Map<String, Future<TenantAdminAccountProfile?>>
  _selectedContactSourceHydrationInFlight =
      <String, Future<TenantAdminAccountProfile?>>{};
  final Map<String, Future<void>> _editNestedGroupBaselineHydrationsInFlight =
      <String, Future<void>>{};
  int _nestedProfileCandidatesCurrentPage = 0;
  int _nestedProfileCandidatesRequestToken = 0;
  String _nestedProfileCandidatesQuery = '';
  String? _nestedProfileCandidatesProfileType;
  String? _nestedProfileCandidatesExcludeProfileId;
  int _contactSourceCandidatesCurrentPage = 0;
  int _contactSourceCandidatesRequestToken = 0;
  String _contactSourceCandidatesQuery = '';
  String? _contactSourceCandidatesProfileType;
  String? _contactSourceCandidatesExcludeProfileId;
  bool _isFetchingContactSourceCandidates = false;
  bool _contactSourceCandidatesReloadQueued = false;

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

  void _bindLocationSelection() {
    if (_locationSelectionSubscription != null) return;
    _locationSelectionSubscription = _locationSelectionService
        .confirmedLocationStreamValue
        .stream
        .listen((location) {
          if (_isDisposed || location == null) return;
          latitudeController.text = location.latitude.toStringAsFixed(6);
          longitudeController.text = location.longitude.toStringAsFixed(6);
          _locationSelectionService.clearConfirmedLocation();
        });
  }

  void bindCreateFlow() {
    _bindLocationSelection();
  }

  void bindEditFlow() {
    _bindLocationSelection();
  }

  Future<XFile?> pickImageFromDevice({required TenantAdminImageSlot slot}) {
    return _imageIngestionService.pickFromDevice(slot: slot);
  }

  Future<XFile> fetchImageFromUrlForCrop({required String imageUrl}) {
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

  Future<TenantAdminAccountProfile> fetchProfile(
    String accountProfileId,
  ) async {
    return _profilesRepository.fetchAccountProfile(
      tenantAdminAccountProfilesRepoString(
        accountProfileId,
        defaultValue: '',
        isRequired: true,
      ),
    );
  }

  Future<List<TenantAdminAccountProfileSelectionSummary>>
  loadEditNestedGroupMemberBaseline({
    required String accountProfileId,
    required String groupId,
  }) async {
    final page = await _profilesRepository.fetchAllNestedGroupMembers(
      accountProfileId: tenantAdminAccountProfilesRepoString(
        accountProfileId,
        defaultValue: '',
        isRequired: true,
      ),
      groupId: tenantAdminAccountProfilesRepoString(
        groupId,
        defaultValue: '',
        isRequired: true,
      ),
    );

    return List<TenantAdminAccountProfileSelectionSummary>.unmodifiable(
      page.items,
    );
  }

  Future<TenantAdminNestedGroupMemberPage> fetchEditNestedGroupMembersPage({
    required String accountProfileId,
    required String groupId,
    String? cursor,
  }) async {
    return _nestedGroupMembersPageLoader.loadPage(
      accountProfileId: accountProfileId,
      groupId: groupId,
      cursor: cursor,
    );
  }

  Future<TenantAdminNestedGroupMemberMutationResult> addEditNestedGroupMembers({
    required String accountProfileId,
    required String groupId,
    required List<String> addIds,
  }) async {
    final result = await _profilesRepository.patchNestedGroupMembers(
      accountProfileId: tenantAdminAccountProfilesRepoString(
        accountProfileId,
        defaultValue: '',
        isRequired: true,
      ),
      groupId: tenantAdminAccountProfilesRepoString(
        groupId,
        defaultValue: '',
        isRequired: true,
      ),
      addIds: addIds
          .map(
            (profileId) => tenantAdminAccountProfilesRepoString(
              profileId,
              defaultValue: '',
              isRequired: true,
            ),
          )
          .toList(growable: false),
    );
    _applyEditNestedGroupMemberMutation(
      groupId: groupId,
      memberCount: result.memberCount,
    );
    return result;
  }

  Future<TenantAdminNestedGroupMemberMutationResult>
  removeEditNestedGroupMembers({
    required String accountProfileId,
    required String groupId,
    required List<String> removeIds,
  }) async {
    final result = await _profilesRepository.patchNestedGroupMembers(
      accountProfileId: tenantAdminAccountProfilesRepoString(
        accountProfileId,
        defaultValue: '',
        isRequired: true,
      ),
      groupId: tenantAdminAccountProfilesRepoString(
        groupId,
        defaultValue: '',
        isRequired: true,
      ),
      removeIds: removeIds
          .map(
            (profileId) => tenantAdminAccountProfilesRepoString(
              profileId,
              defaultValue: '',
              isRequired: true,
            ),
          )
          .toList(growable: false),
    );
    _applyEditNestedGroupMemberMutation(
      groupId: groupId,
      memberCount: result.memberCount,
    );
    return result;
  }

  Future<void> createEditNestedProfileGroupHead({
    required String accountProfileId,
    required String label,
  }) async {
    if (editNestedGroupMutationBusyStreamValue.value) {
      return;
    }

    editNestedGroupMutationBusyStreamValue.addValue(true);
    try {
      final result = await _profilesRepository.createNestedProfileGroup(
        accountProfileId: tenantAdminAccountProfilesRepoString(
          accountProfileId,
          defaultValue: '',
          isRequired: true,
        ),
        label: tenantAdminAccountProfilesRepoString(
          label,
          defaultValue: '',
          isRequired: true,
        ),
      );
      _applyEditNestedProfileGroupHeadMutation(groups: result.groups);
      editErrorMessageStreamValue.addValue(null);
    } catch (error) {
      if (_isDisposed) {
        return;
      }
      reportEditErrorMessage(
        _describeControllerError(error, 'Não foi possível criar o grupo.'),
      );
    } finally {
      if (!_isDisposed) {
        editNestedGroupMutationBusyStreamValue.addValue(false);
      }
    }
  }

  Future<void> deleteEditNestedProfileGroupHead({
    required String accountProfileId,
    required String groupId,
  }) async {
    if (editNestedGroupMutationBusyStreamValue.value) {
      return;
    }

    editNestedGroupMutationBusyStreamValue.addValue(true);
    try {
      final result = await _profilesRepository.deleteNestedProfileGroup(
        accountProfileId: tenantAdminAccountProfilesRepoString(
          accountProfileId,
          defaultValue: '',
          isRequired: true,
        ),
        groupId: tenantAdminAccountProfilesRepoString(
          groupId,
          defaultValue: '',
          isRequired: true,
        ),
      );
      _applyEditNestedProfileGroupHeadMutation(groups: result.groups);
      editErrorMessageStreamValue.addValue(null);
    } catch (error) {
      if (_isDisposed) {
        return;
      }
      reportEditErrorMessage(
        _describeControllerError(error, 'Não foi possível remover o grupo.'),
      );
    } finally {
      if (!_isDisposed) {
        editNestedGroupMutationBusyStreamValue.addValue(false);
      }
    }
  }

  Future<void> ensureEditNestedGroupBaselineHydrated({
    required String accountProfileId,
    required String groupId,
  }) async {
    final normalizedAccountProfileId = accountProfileId.trim();
    final normalizedGroupId = groupId.trim();
    if (normalizedAccountProfileId.isEmpty || normalizedGroupId.isEmpty) {
      return;
    }

    final currentGroup = _editNestedGroupById(normalizedGroupId);
    if (currentGroup == null) {
      return;
    }
    if (!_shouldHydrateEditNestedGroupBaseline(currentGroup)) {
      await _hydrateMissingSelectedNestedProfiles();
      _publishNestedProfileCandidates();
      return;
    }

    final hydrationKey = '$normalizedAccountProfileId::$normalizedGroupId';
    final inFlight = _editNestedGroupBaselineHydrationsInFlight[hydrationKey];
    if (inFlight != null) {
      await inFlight;
      return;
    }

    final hydrationFuture = _hydrateEditNestedGroupBaseline(
      accountProfileId: normalizedAccountProfileId,
      groupId: normalizedGroupId,
      hydrationKey: hydrationKey,
    );
    _editNestedGroupBaselineHydrationsInFlight[hydrationKey] = hydrationFuture;
    await hydrationFuture;
  }

  Future<void> ensureAllEditNestedGroupBaselinesHydrated({
    required String accountProfileId,
  }) async {
    final groups = List<TenantAdminNestedProfileGroup>.from(
      editStateStreamValue.value.nestedProfileGroups,
    );
    for (final group in groups) {
      if (!_shouldHydrateEditNestedGroupBaseline(group)) {
        continue;
      }
      await ensureEditNestedGroupBaselineHydrated(
        accountProfileId: accountProfileId,
        groupId: group.id,
      );
    }
  }

  Future<bool> applyEditNestedGroupSelectionDelta({
    required String accountProfileId,
    required String groupId,
    required List<TenantAdminAccountProfileSelectionSummary> previousSelections,
    required List<TenantAdminAccountProfileSelectionSummary> nextSelections,
  }) async {
    final previousIds = previousSelections.map((entry) => entry.id).toSet();
    final nextIds = nextSelections.map((entry) => entry.id).toSet();

    final addIds = nextSelections
        .where((entry) => !previousIds.contains(entry.id))
        .map(
          (entry) => tenantAdminAccountProfilesRepoString(
            entry.id,
            defaultValue: '',
            isRequired: true,
          ),
        )
        .toList(growable: false);
    final removeIds = previousSelections
        .where((entry) => !nextIds.contains(entry.id))
        .map(
          (entry) => tenantAdminAccountProfilesRepoString(
            entry.id,
            defaultValue: '',
            isRequired: true,
          ),
        )
        .toList(growable: false);

    if (addIds.isEmpty && removeIds.isEmpty) {
      return true;
    }

    updateEditLoading(true);
    try {
      await _profilesRepository.patchNestedGroupMembers(
        accountProfileId: tenantAdminAccountProfilesRepoString(
          accountProfileId,
          defaultValue: '',
          isRequired: true,
        ),
        groupId: tenantAdminAccountProfilesRepoString(
          groupId,
          defaultValue: '',
          isRequired: true,
        ),
        addIds: addIds,
        removeIds: removeIds,
      );
      final refreshed = await fetchProfile(accountProfileId);
      if (_isDisposed) {
        return false;
      }
      updateEditProfile(refreshed);
      editErrorMessageStreamValue.addValue(null);
      editSuccessMessageStreamValue.addValue('Perfis vinculados atualizados.');
      return true;
    } catch (error) {
      if (_isDisposed) {
        return false;
      }
      editErrorMessageStreamValue.addValue(error.toString());
      return false;
    } finally {
      if (!_isDisposed) {
        updateEditLoading(false);
      }
    }
  }

  TenantAdminAccountProfileCandidatePickerController
  createCandidatePickerSession({
    required TenantAdminAccountProfileCandidateScope scope,
    required int maxSelections,
    String? excludeAccountProfileId,
    List<TenantAdminAccountProfileSelectionSummary> initialSelections =
        const <TenantAdminAccountProfileSelectionSummary>[],
  }) {
    return TenantAdminAccountProfileCandidatePickerController(
      pageLoader: TenantAdminAccountProfileCandidateDiscoveryPageLoader(
        repository: _profilesRepository,
      ),
      scope: scope,
      maxSelections: maxSelections,
      excludeAccountProfileId: excludeAccountProfileId,
      initialSelections: initialSelections,
    );
  }

  void disposeCandidatePickerSession(
    TenantAdminAccountProfileCandidatePickerController session,
  ) {
    session.dispose();
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

  Future<void> loadProfiles(String accountId) async {
    isLoadingStreamValue.addValue(true);
    try {
      final profiles = await _profilesRepository.fetchAccountProfiles(
        accountId: tenantAdminAccountProfilesRepoString(
          accountId,
          defaultValue: '',
          isRequired: true,
        ),
      );
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

  Future<void> loadNestedProfileCandidates({String? excludeProfileId}) async {
    _resetNestedProfileCandidates(excludeProfileId: excludeProfileId);
    final requestToken = _nestedProfileCandidatesRequestToken + 1;
    _nestedProfileCandidatesRequestToken = requestToken;
    await _loadNestedProfileCandidatesPage(
      isInitial: true,
      requestToken: requestToken,
    );
  }

  void _resetNestedProfileCandidates({String? excludeProfileId}) {
    _nestedProfileSearchDebounce?.cancel();
    _nestedProfileCandidatesExcludeProfileId = excludeProfileId?.trim();
    _nestedProfileCandidatesQuery = '';
    _nestedProfileCandidatesProfileType = null;
    _nestedProfileCandidatesCurrentPage = 0;
    _nestedProfileCandidateWindow.clear();
    _selectedNestedProfileCache.clear();
    nestedProfileCandidatesStreamValue.addValue(const []);
    nestedProfileSearchHasMoreStreamValue.addValue(false);
    nestedProfileSearchLoadingStreamValue.addValue(false);
    nestedProfileSearchPageLoadingStreamValue.addValue(false);
  }

  Future<void> loadContactSourceCandidates({String? excludeProfileId}) async {
    _resetContactSourceCandidates(excludeProfileId: excludeProfileId);
    await _loadContactSourceCandidatesPage(
      isInitial: true,
      requestToken: _contactSourceCandidatesRequestToken,
    );
  }

  void _resetContactSourceCandidates({String? excludeProfileId}) {
    _contactSourceSearchDebounce?.cancel();
    _contactSourceCandidatesExcludeProfileId = excludeProfileId?.trim();
    _contactSourceCandidatesQuery = '';
    _contactSourceCandidatesProfileType = null;
    _contactSourceCandidatesCurrentPage = 0;
    final requestToken = _contactSourceCandidatesRequestToken + 1;
    _contactSourceCandidatesRequestToken = requestToken;
    contactSourceCandidatesStreamValue.addValue(const []);
    contactSourceCandidatesHasMoreStreamValue.addValue(false);
    contactSourceCandidatesErrorStreamValue.addValue(null);
    contactSourceCandidatesLoadingStreamValue.addValue(false);
    contactSourceCandidatesPageLoadingStreamValue.addValue(false);
    _contactSourceCandidatesReloadQueued = false;
  }

  void _syncContactSourceCandidatesForMode(
    BellugaContactSourceMode mode, {
    String? excludeProfileId,
  }) {
    if (mode == BellugaContactSourceMode.mirroredAccountProfile) {
      unawaited(
        loadContactSourceCandidates(excludeProfileId: excludeProfileId),
      );
      return;
    }
    _resetContactSourceCandidates(excludeProfileId: excludeProfileId);
  }

  Future<void> loadNextContactSourceCandidatesPage() async {
    if (_isFetchingContactSourceCandidates ||
        !contactSourceCandidatesHasMoreStreamValue.value) {
      return;
    }
    await _loadContactSourceCandidatesPage(
      isInitial: false,
      requestToken: _contactSourceCandidatesRequestToken,
    );
  }

  Future<void> _loadContactSourceCandidatesPage({
    required bool isInitial,
    required int requestToken,
  }) async {
    if (_isFetchingContactSourceCandidates) {
      if (isInitial) {
        _contactSourceCandidatesReloadQueued = true;
      }
      return;
    }
    _isFetchingContactSourceCandidates = true;
    if (isInitial) {
      contactSourceCandidatesLoadingStreamValue.addValue(true);
    } else {
      contactSourceCandidatesPageLoadingStreamValue.addValue(true);
    }
    try {
      final requestedPage = isInitial
          ? 1
          : _contactSourceCandidatesCurrentPage + 1;
      final page = await _nestedProfileCandidatesPageLoader.loadPage(
        pageNumber: requestedPage,
        search: _contactSourceCandidatesQuery,
        profileType: _contactSourceCandidatesProfileType,
        contactMode: BellugaContactSourceMode.own.rawValue,
        contactChannelsEnabledOnly: true,
        excludeAccountProfileId: _contactSourceCandidatesExcludeProfileId,
      );
      if (_isDisposed || requestToken != _contactSourceCandidatesRequestToken) {
        return;
      }
      if (isInitial) {
        _contactSourceCandidateWindow
          ..clear()
          ..addAll(page.items);
      } else {
        final existingWindow = List<TenantAdminAccountProfile>.from(
          _contactSourceCandidateWindow,
        );
        _contactSourceCandidateWindow
          ..clear()
          ..addAll(_mergeAccountProfiles(existingWindow, page.items));
      }
      _contactSourceCandidatesCurrentPage =
          page.pagination?.currentPage ?? requestedPage;
      contactSourceCandidatesHasMoreStreamValue.addValue(page.hasMore);
      await _hydrateMissingSelectedContactSources();
      _publishContactSourceCandidates();
      contactSourceCandidatesErrorStreamValue.addValue(null);
    } catch (error) {
      if (_isDisposed || requestToken != _contactSourceCandidatesRequestToken) {
        return;
      }
      // A later-page failure must not erase an already useful, server-owned
      // candidate set. The picker can still render and select the first page;
      // a subsequent initial load retries from the canonical endpoint.
      if (isInitial) {
        _contactSourceCandidateWindow.clear();
      }
      contactSourceCandidatesHasMoreStreamValue.addValue(false);
      await _hydrateMissingSelectedContactSources();
      _publishContactSourceCandidates();
      contactSourceCandidatesErrorStreamValue.addValue(error.toString());
    } finally {
      _isFetchingContactSourceCandidates = false;
      if (!_isDisposed &&
          requestToken == _contactSourceCandidatesRequestToken) {
        if (isInitial) {
          contactSourceCandidatesLoadingStreamValue.addValue(false);
        } else {
          contactSourceCandidatesPageLoadingStreamValue.addValue(false);
        }
      }
      if (_contactSourceCandidatesReloadQueued && !_isDisposed) {
        _contactSourceCandidatesReloadQueued = false;
        unawaited(
          _loadContactSourceCandidatesPage(
            isInitial: true,
            requestToken: _contactSourceCandidatesRequestToken,
          ),
        );
      }
    }
  }

  void searchNestedProfileCandidates(String query) {
    _nestedProfileCandidatesQuery = query.trim();
    final requestToken = _nestedProfileCandidatesRequestToken + 1;
    _nestedProfileCandidatesRequestToken = requestToken;
    _nestedProfileSearchDebounce?.cancel();
    _nestedProfileSearchDebounce = Timer(
      _nestedProfileSearchDebounceDuration,
      () {
        unawaited(
          _loadNestedProfileCandidatesPage(
            isInitial: true,
            requestToken: requestToken,
          ),
        );
      },
    );
  }

  void filterNestedProfileCandidatesByProfileType(String? profileType) {
    _nestedProfileCandidatesProfileType = profileType?.trim().isEmpty ?? true
        ? null
        : profileType!.trim();
    final requestToken = _nestedProfileCandidatesRequestToken + 1;
    _nestedProfileCandidatesRequestToken = requestToken;
    _nestedProfileSearchDebounce?.cancel();
    unawaited(
      _loadNestedProfileCandidatesPage(
        isInitial: true,
        requestToken: requestToken,
      ),
    );
  }

  void searchContactSourceCandidates(String query) {
    _contactSourceCandidatesQuery = query.trim();
    final requestToken = _contactSourceCandidatesRequestToken + 1;
    _contactSourceCandidatesRequestToken = requestToken;
    _contactSourceSearchDebounce?.cancel();
    _contactSourceSearchDebounce = Timer(
      _nestedProfileSearchDebounceDuration,
      () {
        unawaited(
          _loadContactSourceCandidatesPage(
            isInitial: true,
            requestToken: requestToken,
          ),
        );
      },
    );
  }

  void filterContactSourceCandidatesByProfileType(String? profileType) {
    _contactSourceCandidatesProfileType = profileType?.trim().isEmpty ?? true
        ? null
        : profileType!.trim();
    final requestToken = _contactSourceCandidatesRequestToken + 1;
    _contactSourceCandidatesRequestToken = requestToken;
    _contactSourceSearchDebounce?.cancel();
    unawaited(
      _loadContactSourceCandidatesPage(
        isInitial: true,
        requestToken: requestToken,
      ),
    );
  }

  Future<void> loadNextNestedProfileCandidatesPage() async {
    if (nestedProfileSearchLoadingStreamValue.value ||
        nestedProfileSearchPageLoadingStreamValue.value ||
        !nestedProfileSearchHasMoreStreamValue.value) {
      return;
    }
    await _loadNestedProfileCandidatesPage(
      isInitial: false,
      requestToken: _nestedProfileCandidatesRequestToken,
    );
  }

  Future<void> loadProfileTypes() async {
    isLoadingStreamValue.addValue(true);
    try {
      await _profilesRepository.loadAllProfileTypes();
      final types =
          _profilesRepository.profileTypesStreamValue.value ??
          const <TenantAdminProfileTypeDefinition>[];
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
      await _taxonomiesRepository.loadAllTaxonomies();
      final taxonomies =
          _taxonomiesRepository.taxonomiesStreamValue.value ??
          const <TenantAdminTaxonomyDefinition>[];
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
        orElse: () => tenantAdminTaxonomyDefinitionFromRaw(
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
        await _taxonomiesRepository.loadAllTerms(
          taxonomyId: TenantAdminTaxRepoString.fromRaw(
            taxonomy.id,
            defaultValue: '',
            isRequired: true,
          ),
        );
        final terms =
            _taxonomiesRepository.termsStreamValue.value ??
            const <TenantAdminTaxonomyTermDefinition>[];
        map[slug] = terms;
      } on Object {
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
      _bindAccountWatch(accountId: account.id, accountSlug: account.slug);
      createAccountIdStreamValue.addValue(account.id);
    } catch (error) {
      if (_isDisposed) return;
      createErrorMessageStreamValue.addValue(error.toString());
    }
  }

  Future<void> loadAccountForEdit(String accountSlug) async {
    try {
      final account = await resolveAccountBySlug(accountSlug);
      if (_isDisposed) return;
      _bindAccountWatch(accountId: account.id, accountSlug: account.slug);
      accountDetailErrorStreamValue.addValue(null);
    } catch (error) {
      if (_isDisposed) return;
      accountDetailErrorStreamValue.addValue(error.toString());
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
      _bindAccountWatch(accountId: account.id, accountSlug: account.slug);
      final profile = await fetchProfileForAccount(account.id);
      if (_isDisposed) return;
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
    TenantAdminOwnershipState? ownershipState,
    TenantAdminAccountPublication? publication,
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
        publication: publication,
      );
      if (_isDisposed) {
        return null;
      }
      _bindAccountWatch(accountId: updated.id, accountSlug: updated.slug);
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

  Future<bool> deleteAccount({required String accountSlug}) async {
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

  Future<void> loadEditProfile(
    String accountProfileId, {
    TenantAdminAccountProfile? prefetchedProfile,
  }) async {
    editLoadingStreamValue.addValue(true);
    editLoadErrorStreamValue.addValue(null);
    _loadedEditProfileSnapshot = null;
    _editGalleryInputValues.clear();
    editGalleryFieldErrorsStreamValue.addValue(const {});
    editGalleryOperationErrorStreamValue.addValue(null);
    _clearNestedGroupLabelStates();
    try {
      await loadProfileTypes();
      final normalizedAccountProfileId = accountProfileId.trim();
      final TenantAdminAccountProfile profile;
      if (prefetchedProfile != null &&
          prefetchedProfile.id.trim() == normalizedAccountProfileId) {
        profile = prefetchedProfile;
      } else {
        profile = await fetchProfile(normalizedAccountProfileId);
      }
      if (_isDisposed) return;
      _loadedEditProfileSnapshot = profile;
      accountProfileStreamValue.addValue(profile);
      _updateEditState(
        editStateStreamValue.value
            .copyWith(
              selectedProfileType: profile.profileType,
              nestedProfileGroups: profile.nestedProfileGroups,
            )
            .syncRemoteState(profile),
      );
      _resetNestedProfileCandidates(excludeProfileId: profile.id);
      _syncContactSourceCandidatesForMode(
        profile.contactMode,
        excludeProfileId: profile.id,
      );
      _removeAvatarOnSubmit = false;
      _removeCoverOnSubmit = false;
    } catch (error) {
      if (_isDisposed) return;
      editLoadErrorStreamValue.addValue(error.toString());
    } finally {
      if (!_isDisposed) {
        editLoadingStreamValue.addValue(false);
      }
    }
  }

  void updateSelectedProfileType(String? profileType) {
    _updateEditState(
      editStateStreamValue.value.copyWith(selectedProfileType: profileType),
    );
  }

  void updateEditContactMode(BellugaContactSourceMode mode) {
    final state = editStateStreamValue.value;
    _updateEditState(
      state.copyWith(
        contactMode: mode,
        contactBubbleSelection: _normalizeBubbleSelectionForMode(
          mode: mode,
          selection: state.contactBubbleSelection,
        ),
      ),
    );
    _syncContactSourceCandidatesForMode(
      mode,
      excludeProfileId: accountProfileStreamValue.value?.id,
    );
  }

  void updateEditContactSourceAccountProfileId(String? profileId) {
    final normalized = profileId?.trim();
    _updateEditState(
      editStateStreamValue.value.copyWith(
        contactSourceAccountProfileId: normalized == null || normalized.isEmpty
            ? null
            : normalized,
      ),
    );
    _syncSelectedContactSourceCache(_selectedContactSourceIdsAcrossDrafts());
    _publishContactSourceCandidates();
    unawaited(_hydrateAndPublishSelectedContactSources());
  }

  void updateEditContactBubbleChannelId(String? channelId) {
    final normalized = channelId?.trim();
    _updateEditState(
      editStateStreamValue.value.copyWith(
        contactBubbleSelection: normalized == null || normalized.isEmpty
            ? const BellugaContactBubbleSelectionMutation.clear()
            : BellugaContactBubbleSelectionMutation.setPersisted(normalized),
      ),
    );
  }

  void addEditContactChannel(BellugaContactChannelType type) {
    final drafts = editStateStreamValue.value.contactChannelDrafts;
    if (drafts.length >= BellugaContactChannelDraftValidator.maxChannels) {
      reportEditErrorMessage('Limite de canais de contato atingido.');
      return;
    }
    _updateEditState(
      editStateStreamValue.value.copyWith(
        contactChannelDrafts: <BellugaContactChannelDraft>[
          ...drafts,
          BellugaContactChannelDraft(
            draftKey: _newContactDraftKey(type),
            type: type,
            value: '',
          ),
        ],
      ),
    );
  }

  void updateEditContactChannel(BellugaContactChannelDraft draft) {
    _updateEditState(
      editStateStreamValue.value.copyWith(
        contactChannelDrafts: _replaceContactDraft(
          editStateStreamValue.value.contactChannelDrafts,
          draft,
        ),
      ),
    );
  }

  void removeEditContactChannel(String draftKey) {
    final state = editStateStreamValue.value;
    final removedDraft = _findContactDraft(
      state.contactChannelDrafts,
      draftKey,
    );
    final next = state.contactChannelDrafts
        .where((draft) => draft.draftKey != draftKey)
        .toList(growable: false);
    _updateEditState(
      state.copyWith(
        contactChannelDrafts: next,
        expandedContactCtaDraftKey: state.expandedContactCtaDraftKey == draftKey
            ? null
            : state.expandedContactCtaDraftKey,
        contactBubbleSelection: _bubbleSelectionAfterRemoval(
          state.contactBubbleSelection,
          removedDraft,
        ),
      ),
    );
  }

  void selectEditContactBubble(
    BellugaContactChannelDraft draft,
    bool selected,
  ) {
    _updateEditState(
      editStateStreamValue.value.copyWith(
        contactBubbleSelection: selected
            ? _bubbleSelectionForDraft(draft)
            : const BellugaContactBubbleSelectionMutation.clear(),
      ),
    );
  }

  void toggleEditContactCtaEditor(String draftKey) {
    final state = editStateStreamValue.value;
    final draft = _findContactDraft(state.contactChannelDrafts, draftKey);
    if (draft == null || !draft.definition.capabilities.messagePresets) return;
    _updateEditState(
      state.copyWith(
        expandedContactCtaDraftKey: state.expandedContactCtaDraftKey == draftKey
            ? null
            : draftKey,
      ),
    );
  }

  void addEditContactInitialMessage(String draftKey) {
    final draft = _requireEditContactDraft(draftKey);
    if (!_canAddContactInitialMessage(draft)) {
      reportEditErrorMessage('Limite de CTAs do WhatsApp atingido.');
      return;
    }
    updateEditContactChannel(
      draft.copyWith(
        initialMessages: <BellugaContactInitialMessage>[
          ...draft.initialMessages,
          _newContactInitialMessage(),
        ],
      ),
    );
  }

  void updateEditContactInitialMessage(
    String draftKey,
    BellugaContactInitialMessage message,
  ) {
    final draft = _requireEditContactDraft(draftKey);
    updateEditContactChannel(
      draft.copyWith(
        initialMessages: draft.initialMessages
            .map((entry) => entry.id == message.id ? message : entry)
            .toList(growable: false),
      ),
    );
  }

  void removeEditContactInitialMessageFromChannel(
    String draftKey,
    String messageId,
  ) {
    final draft = _requireEditContactDraft(draftKey);
    updateEditContactChannel(
      draft.copyWith(
        initialMessages: draft.initialMessages
            .where((entry) => entry.id != messageId)
            .toList(growable: false),
      ),
    );
  }

  void updateEditLoading(bool isLoading) {
    editLoadingStreamValue.addValue(isLoading);
  }

  void updateEditProfile(
    TenantAdminAccountProfile profile, {
    bool preserveGalleryState = false,
  }) {
    if (!preserveGalleryState) _editGalleryInputValues.clear();
    final currentGalleryGroups = editStateStreamValue.value.galleryGroups;
    final currentGalleryCapabilities =
        editStateStreamValue.value.galleryCapabilities;
    _loadedEditProfileSnapshot = profile;
    accountProfileStreamValue.addValue(profile);
    final syncedState = editStateStreamValue.value.copyWith().syncRemoteState(
      profile,
    );
    _updateEditState(
      preserveGalleryState
          ? syncedState.copyWith(
              galleryGroups: currentGalleryGroups,
              galleryCapabilities: currentGalleryCapabilities,
            )
          : syncedState,
    );
    _syncContactSourceCandidatesForMode(
      profile.contactMode,
      excludeProfileId: profile.id,
    );
    _removeAvatarOnSubmit = false;
    _removeCoverOnSubmit = false;
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
    if (file != null) {
      _removeAvatarOnSubmit = false;
    }
  }

  void updateCoverFile(XFile? file) {
    _updateEditState(
      editStateStreamValue.value.copyWith(
        coverFile: file,
        coverRemoteUrl: file == null
            ? editStateStreamValue.value.coverRemoteUrl
            : null,
        coverRemoteReady: false,
        coverRemoteError: false,
        coverPreloadUrl: null,
      ),
    );
    if (file != null) {
      _removeCoverOnSubmit = false;
    }
  }

  void updateEditAvatarBusy(bool isBusy) {
    _updateEditState(editStateStreamValue.value.copyWith(avatarBusy: isBusy));
  }

  void updateEditCoverBusy(bool isBusy) {
    _updateEditState(editStateStreamValue.value.copyWith(coverBusy: isBusy));
  }

  void updateAvatarRemoteUrl(String? url) {
    final trimmed = url?.trim();
    final normalized = trimmed == null || trimmed.isEmpty ? null : trimmed;
    _updateEditState(
      editStateStreamValue.value.copyWith(
        avatarRemoteUrl: normalized,
        avatarFile: null,
        avatarRemoteReady: false,
        avatarRemoteError: false,
        avatarPreloadUrl: null,
      ),
    );
    if (normalized != null) {
      _removeAvatarOnSubmit = false;
    }
  }

  void updateCoverRemoteUrl(String? url) {
    final trimmed = url?.trim();
    final normalized = trimmed == null || trimmed.isEmpty ? null : trimmed;
    _updateEditState(
      editStateStreamValue.value.copyWith(
        coverRemoteUrl: normalized,
        coverFile: null,
        coverRemoteReady: false,
        coverRemoteError: false,
        coverPreloadUrl: null,
      ),
    );
    if (normalized != null) {
      _removeCoverOnSubmit = false;
    }
  }

  void clearAvatarSelection({bool markForRemoval = false}) {
    updateAvatarFile(null);
    updateAvatarRemoteUrl(null);
    if (!markForRemoval) {
      _removeAvatarOnSubmit = false;
      return;
    }
    final hasPersistedAvatar =
        accountProfileStreamValue.value?.avatarUrl?.trim().isNotEmpty ?? false;
    _removeAvatarOnSubmit = hasPersistedAvatar;
  }

  void clearCoverSelection({bool markForRemoval = false}) {
    updateCoverFile(null);
    updateCoverRemoteUrl(null);
    if (!markForRemoval) {
      _removeCoverOnSubmit = false;
      return;
    }
    final hasPersistedCover =
        accountProfileStreamValue.value?.coverUrl?.trim().isNotEmpty ?? false;
    _removeCoverOnSubmit = hasPersistedCover;
  }

  Future<void> submitCreateProfile({
    required String accountId,
    required String profileType,
    required String displayName,
    required TenantAdminLocation? location,
    required String? bio,
    required String? content,
    required TenantAdminTaxonomyTerms taxonomyTerms,
    required TenantAdminMediaUpload? avatarUpload,
    required TenantAdminMediaUpload? coverUpload,
    String? avatarUrl,
    String? coverUrl,
    List<TenantAdminNestedProfileGroup> nestedProfileGroups =
        const <TenantAdminNestedProfileGroup>[],
    required BellugaContactSourceMode contactMode,
    String? contactSourceAccountProfileId,
    List<BellugaContactChannelDraft>? contactChannelDrafts,
    BellugaContactBubbleSelectionMutation bubbleSelection =
        const BellugaContactBubbleSelectionMutation.omit(),
  }) async {
    if (createSubmittingStreamValue.value) return;
    createSubmittingStreamValue.addValue(true);
    try {
      await createProfile(
        accountId: accountId,
        profileType: profileType,
        displayName: displayName,
        location: location,
        bio: bio,
        content: content,
        taxonomyTerms: taxonomyTerms,
        avatarUpload: avatarUpload,
        coverUpload: coverUpload,
        avatarUrl: avatarUrl,
        coverUrl: coverUrl,
        nestedProfileGroups: nestedProfileGroups,
        contactMode: contactMode,
        contactSourceAccountProfileId: contactSourceAccountProfileId,
        contactChannelDrafts: contactChannelDrafts,
        bubbleSelection: bubbleSelection,
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
        avatarRemoteError: ready
            ? false
            : editStateStreamValue.value.avatarRemoteError,
        avatarFile: ready ? null : editStateStreamValue.value.avatarFile,
      ),
    );
  }

  void markCoverRemoteReady(bool ready) {
    _updateEditState(
      editStateStreamValue.value.copyWith(
        coverRemoteReady: ready,
        coverRemoteError: ready
            ? false
            : editStateStreamValue.value.coverRemoteError,
        coverFile: ready ? null : editStateStreamValue.value.coverFile,
      ),
    );
  }

  void updateAvatarRemoteError(bool hasError) {
    _updateEditState(
      editStateStreamValue.value.copyWith(avatarRemoteError: hasError),
    );
  }

  void updateCoverRemoteError(bool hasError) {
    _updateEditState(
      editStateStreamValue.value.copyWith(coverRemoteError: hasError),
    );
  }

  Future<void> submitUpdateProfile({
    required String accountProfileId,
    required String profileType,
    required String displayName,
    String? slug,
    required TenantAdminLocation? location,
    required String? bio,
    required String? content,
    required TenantAdminTaxonomyTerms? taxonomyTerms,
    required TenantAdminMediaUpload? avatarUpload,
    required TenantAdminMediaUpload? coverUpload,
    String? avatarUrl,
    String? coverUrl,
    bool? removeAvatar,
    bool? removeCover,
    List<TenantAdminNestedProfileGroup>? nestedProfileGroups,
    BellugaContactSourceMode? contactMode,
    String? contactSourceAccountProfileId,
    List<BellugaContactChannelDraft>? contactChannelDrafts,
    BellugaContactBubbleSelectionMutation bubbleSelection =
        const BellugaContactBubbleSelectionMutation.omit(),
  }) async {
    if (editSubmittingStreamValue.value) return;
    editSubmittingStreamValue.addValue(true);
    try {
      final updated = await updateProfile(
        accountProfileId: accountProfileId,
        profileType: profileType,
        displayName: displayName,
        slug: slug,
        location: location,
        bio: bio,
        content: content,
        taxonomyTerms: taxonomyTerms,
        avatarUpload: avatarUpload,
        coverUpload: coverUpload,
        avatarUrl: avatarUrl,
        coverUrl: coverUrl,
        removeAvatar: removeAvatar ?? _removeAvatarOnSubmit,
        removeCover: removeCover ?? _removeCoverOnSubmit,
        nestedProfileGroups: nestedProfileGroups,
        contactMode: contactMode,
        contactSourceAccountProfileId: contactSourceAccountProfileId,
        contactChannelDrafts: contactChannelDrafts,
        bubbleSelection: bubbleSelection,
      );
      if (_isDisposed) return;
      updateEditProfile(updated, preserveGalleryState: true);
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
    bool? removeAvatar,
    bool? removeCover,
  }) async {
    if (avatarUpload == null &&
        coverUpload == null &&
        avatarUrl == null &&
        coverUrl == null &&
        removeAvatar != true &&
        removeCover != true) {
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
        removeAvatar: removeAvatar,
        removeCover: removeCover,
      );
      if (_isDisposed) return;
      updateEditProfile(updated, preserveGalleryState: true);
      editErrorMessageStreamValue.addValue(null);
      editSuccessMessageStreamValue.addValue('Imagem atualizada.');
    } catch (error) {
      if (_isDisposed) return;
      editErrorMessageStreamValue.addValue('Falha ao salvar imagem: $error');
    } finally {
      if (!_isDisposed) {
        updateEditLoading(false);
      }
    }
  }

  Future<bool> submitTaxonomySelectionUpdate({
    required String accountProfileId,
    required String? profileType,
    required TenantAdminTaxonomyTerms taxonomyTerms,
    String? bio,
    String? content,
  }) async {
    taxonomyAutosavingStreamValue.addValue(true);
    editSubmittingStreamValue.addValue(true);
    try {
      final currentProfile = accountProfileStreamValue.value;
      final resolvedProfileType = (profileType ?? currentProfile?.profileType)
          ?.trim();
      if (resolvedProfileType == null || resolvedProfileType.isEmpty) {
        editErrorMessageStreamValue.addValue(
          'Nao foi possivel identificar o tipo do perfil para salvar taxonomias.',
        );
        return false;
      }
      final capabilities = _resolveProfileType(
        resolvedProfileType,
      )?.capabilities;
      final resolvedBio = capabilities?.hasBio == true
          ? (bio ?? currentProfile?.bio ?? '')
          : null;
      final resolvedContent = capabilities?.hasContent == true
          ? (content ?? currentProfile?.content ?? '')
          : null;
      final updated = await updateProfile(
        accountProfileId: accountProfileId,
        profileType: resolvedProfileType,
        taxonomyTerms: taxonomyTerms,
        bio: resolvedBio,
        content: resolvedContent,
      );
      if (_isDisposed) return false;
      updateEditProfile(updated, preserveGalleryState: true);
      editErrorMessageStreamValue.addValue(null);
      return true;
    } catch (error) {
      if (_isDisposed) return false;
      editErrorMessageStreamValue.addValue(error.toString());
      return false;
    } finally {
      if (!_isDisposed) {
        editSubmittingStreamValue.addValue(false);
        taxonomyAutosavingStreamValue.addValue(false);
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

  void _applyEditNestedProfileGroupHeadMutation({
    required List<TenantAdminNestedProfileGroup> groups,
    bool invalidateAggregateRevision = false,
  }) {
    final mergedGroups = _mergeNestedProfileGroupMetadata(
      currentGroups: editStateStreamValue.value.nestedProfileGroups,
      metadataGroups: groups,
    );
    final currentProfile = accountProfileStreamValue.value;
    if (currentProfile != null) {
      accountProfileStreamValue.addValue(
        _copyAccountProfileWithNestedProfileGroups(
          currentProfile,
          nestedProfileGroups: mergedGroups,
          invalidateAggregateRevision: invalidateAggregateRevision,
        ),
      );
    }
    _syncSelectedNestedProfileCache(
      _selectedNestedProfileIdsAcrossDrafts(editGroups: mergedGroups),
    );
    _updateEditState(
      editStateStreamValue.value.copyWith(nestedProfileGroups: mergedGroups),
    );
    _publishNestedProfileCandidates();
  }

  List<TenantAdminNestedProfileGroup> _mergeNestedProfileGroupMetadata({
    required List<TenantAdminNestedProfileGroup> currentGroups,
    required List<TenantAdminNestedProfileGroup> metadataGroups,
  }) {
    final currentById = <String, TenantAdminNestedProfileGroup>{
      for (final group in currentGroups) group.id: group,
    };
    return List<TenantAdminNestedProfileGroup>.unmodifiable([
      for (final metadataGroup in metadataGroups)
        metadataGroup.copyWith(
          accountProfileIdValues:
              currentById[metadataGroup.id]?.accountProfileIdValues ?? const [],
        ),
    ]);
  }

  TenantAdminAccountProfile _copyAccountProfileWithNestedProfileGroups(
    TenantAdminAccountProfile profile, {
    required List<TenantAdminNestedProfileGroup> nestedProfileGroups,
    bool invalidateAggregateRevision = false,
  }) {
    return TenantAdminAccountProfile(
      idValue: profile.idValue,
      accountIdValue: profile.accountIdValue,
      profileTypeValue: profile.profileTypeValue,
      displayNameValue: profile.displayNameValue,
      aggregateRevisionValue: invalidateAggregateRevision
          ? null
          : profile.aggregateRevisionValue,
      slugValue: profile.slugValue,
      avatarUrlValue: profile.avatarUrlValue,
      coverUrlValue: profile.coverUrlValue,
      bioValue: profile.bioValue,
      contentValue: profile.contentValue,
      location: profile.location,
      taxonomyTerms: profile.taxonomyTerms,
      galleryGroups: profile.galleryGroups,
      nestedProfileGroups: nestedProfileGroups,
      ownershipState: profile.ownershipState,
      contactModeValue: profile.contactModeValue,
      contactSourceAccountProfileId: profile.contactSourceAccountProfileIdValue,
      contactChannels: profile.contactChannelsValue,
      contactBubbleChannelId: profile.contactBubbleChannelIdValue,
      effectiveContactChannels: profile.effectiveContactChannelsValue,
      contactSourceProfile: profile.contactSourceProfile,
      effectiveContactSourceProfile: profile.effectiveContactSourceProfile,
    );
  }

  String _describeControllerError(Object error, String fallback) {
    final rawMessage = error.toString().trim();
    if (rawMessage.isEmpty) {
      return fallback;
    }
    final withoutTypePrefix = rawMessage.replaceFirst(
      RegExp(
        r'^(Exception|Bad state|FormatException|Invalid argument\(s\)):\s*',
      ),
      '',
    );
    final trailingMessageMatch = RegExp(
      r'\):\s*(.+)$',
    ).firstMatch(withoutTypePrefix);
    final message =
        trailingMessageMatch?.group(1)?.trim() ?? withoutTypePrefix.trim();
    if (message.isEmpty) {
      return fallback;
    }
    return message;
  }

  String _describeGroupLabelError(Object error, String fallback) {
    if (error is! FormValidationFailure) {
      return fallback;
    }

    final messages = <String>[...?error.fieldErrors['label'], error.message];
    for (final message in messages) {
      final normalized = message.trim();
      if (_isSafeGroupLabelValidationMessage(normalized)) {
        return normalized;
      }
    }
    return fallback;
  }

  bool _isSafeGroupLabelValidationMessage(String value) =>
      value.isNotEmpty &&
      value.length <= TenantAdminGroupLabelMutationState.maxLabelLength &&
      !RegExp(
        r'https?://|<[^>]*>|[\r\n]',
        caseSensitive: false,
      ).hasMatch(value);

  void updateAvatarPreloadUrl(String? url) {
    _updateEditState(
      editStateStreamValue.value.copyWith(avatarPreloadUrl: url),
    );
  }

  void updateCoverPreloadUrl(String? url) {
    _updateEditState(editStateStreamValue.value.copyWith(coverPreloadUrl: url));
  }

  void resetEditState() {
    if (_isDisposed) {
      return;
    }
    _loadedEditProfileSnapshot = null;
    _resetNestedProfileCandidates();
    _updateEditState(TenantAdminAccountProfileEditDraft.initial());
    editLoadingStreamValue.addValue(false);
    editLoadErrorStreamValue.addValue(null);
    editNestedGroupMutationBusyStreamValue.addValue(false);
    taxonomyAutosavingStreamValue.addValue(false);
    _removeAvatarOnSubmit = false;
    _removeCoverOnSubmit = false;
  }

  void updateCreateSelectedProfileType(String? profileType) {
    _updateCreateState(
      createStateStreamValue.value.copyWith(selectedProfileType: profileType),
    );
  }

  void updateCreateContactMode(BellugaContactSourceMode mode) {
    final state = createStateStreamValue.value;
    _updateCreateState(
      state.copyWith(
        contactMode: mode,
        contactBubbleSelection: _normalizeBubbleSelectionForMode(
          mode: mode,
          selection: state.contactBubbleSelection,
        ),
      ),
    );
    _syncContactSourceCandidatesForMode(mode);
  }

  void updateCreateContactSourceAccountProfileId(String? profileId) {
    final normalized = profileId?.trim();
    _updateCreateState(
      createStateStreamValue.value.copyWith(
        contactSourceAccountProfileId: normalized == null || normalized.isEmpty
            ? null
            : normalized,
      ),
    );
    _syncSelectedContactSourceCache(_selectedContactSourceIdsAcrossDrafts());
    _publishContactSourceCandidates();
    unawaited(_hydrateAndPublishSelectedContactSources());
  }

  void updateCreateContactBubbleChannelId(String? channelId) {
    final normalized = channelId?.trim();
    _updateCreateState(
      createStateStreamValue.value.copyWith(
        contactBubbleSelection: normalized == null || normalized.isEmpty
            ? const BellugaContactBubbleSelectionMutation.clear()
            : BellugaContactBubbleSelectionMutation.setPersisted(normalized),
      ),
    );
  }

  void addCreateContactChannel(BellugaContactChannelType type) {
    final drafts = createStateStreamValue.value.contactChannelDrafts;
    if (drafts.length >= BellugaContactChannelDraftValidator.maxChannels) {
      reportCreateErrorMessage('Limite de canais de contato atingido.');
      return;
    }
    _updateCreateState(
      createStateStreamValue.value.copyWith(
        contactChannelDrafts: <BellugaContactChannelDraft>[
          ...drafts,
          BellugaContactChannelDraft(
            draftKey: _newContactDraftKey(type),
            type: type,
            value: '',
          ),
        ],
      ),
    );
  }

  void updateCreateContactChannel(BellugaContactChannelDraft draft) {
    _updateCreateState(
      createStateStreamValue.value.copyWith(
        contactChannelDrafts: _replaceContactDraft(
          createStateStreamValue.value.contactChannelDrafts,
          draft,
        ),
      ),
    );
  }

  void removeCreateContactChannel(String draftKey) {
    final state = createStateStreamValue.value;
    final removedDraft = _findContactDraft(
      state.contactChannelDrafts,
      draftKey,
    );
    final next = state.contactChannelDrafts
        .where((draft) => draft.draftKey != draftKey)
        .toList(growable: false);
    _updateCreateState(
      state.copyWith(
        contactChannelDrafts: next,
        expandedContactCtaDraftKey: state.expandedContactCtaDraftKey == draftKey
            ? null
            : state.expandedContactCtaDraftKey,
        contactBubbleSelection: _bubbleSelectionAfterRemoval(
          state.contactBubbleSelection,
          removedDraft,
        ),
      ),
    );
  }

  void selectCreateContactBubble(
    BellugaContactChannelDraft draft,
    bool selected,
  ) {
    _updateCreateState(
      createStateStreamValue.value.copyWith(
        contactBubbleSelection: selected
            ? _bubbleSelectionForDraft(draft)
            : const BellugaContactBubbleSelectionMutation.clear(),
      ),
    );
  }

  void toggleCreateContactCtaEditor(String draftKey) {
    final state = createStateStreamValue.value;
    final draft = _findContactDraft(state.contactChannelDrafts, draftKey);
    if (draft == null || !draft.definition.capabilities.messagePresets) return;
    _updateCreateState(
      state.copyWith(
        expandedContactCtaDraftKey: state.expandedContactCtaDraftKey == draftKey
            ? null
            : draftKey,
      ),
    );
  }

  void addCreateContactInitialMessage(String draftKey) {
    final draft = _requireCreateContactDraft(draftKey);
    if (!_canAddContactInitialMessage(draft)) {
      reportCreateErrorMessage('Limite de CTAs do WhatsApp atingido.');
      return;
    }
    updateCreateContactChannel(
      draft.copyWith(
        initialMessages: <BellugaContactInitialMessage>[
          ...draft.initialMessages,
          _newContactInitialMessage(),
        ],
      ),
    );
  }

  void updateCreateContactInitialMessage(
    String draftKey,
    BellugaContactInitialMessage message,
  ) {
    final draft = _requireCreateContactDraft(draftKey);
    updateCreateContactChannel(
      draft.copyWith(
        initialMessages: draft.initialMessages
            .map((entry) => entry.id == message.id ? message : entry)
            .toList(growable: false),
      ),
    );
  }

  void removeCreateContactInitialMessageFromChannel(
    String draftKey,
    String messageId,
  ) {
    final draft = _requireCreateContactDraft(draftKey);
    updateCreateContactChannel(
      draft.copyWith(
        initialMessages: draft.initialMessages
            .where((entry) => entry.id != messageId)
            .toList(growable: false),
      ),
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
      createStateStreamValue.value.copyWith(coverFile: file, coverWebUrl: null),
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

  void addCreateNestedProfileGroup() {
    final groups = createStateStreamValue.value.nestedProfileGroups;
    if (groups.length >= 12) {
      reportCreateErrorMessage('Limite de grupos atingido.');
      return;
    }
    _updateCreateState(
      createStateStreamValue.value.copyWith(
        nestedProfileGroups: TenantAdminNestedProfileGroupOperations.append(
          groups,
        ),
      ),
    );
  }

  void addEditNestedProfileGroup() {
    final groups = editStateStreamValue.value.nestedProfileGroups;
    if (groups.length >= 12) {
      reportEditErrorMessage('Limite de grupos atingido.');
      return;
    }
    _updateEditState(
      editStateStreamValue.value.copyWith(
        nestedProfileGroups: TenantAdminNestedProfileGroupOperations.append(
          groups,
        ),
      ),
    );
  }

  Future<void> addEditGalleryGroup(String subtitle) => _runGalleryMutation(
    () => _profilesRepository.createGalleryGroup(
      accountProfileId: _editGalleryProfileId(),
      subtitle: tenantAdminAccountProfilesRepoString(
        subtitle,
        defaultValue: '',
        isRequired: true,
      ),
    ),
    fieldErrorScope: 'group.create',
  );

  Future<void> renameEditGalleryGroup(String groupId, String subtitle) =>
      _runGalleryMutation(
        () => _profilesRepository.renameGalleryGroup(
          accountProfileId: _editGalleryProfileId(),
          groupId: _galleryText(groupId),
          subtitle: _galleryText(subtitle),
        ),
        fieldErrorScope: 'group.$groupId',
      );

  Future<void> moveEditGalleryGroup(String groupId, int delta) async {
    final previous = editStateStreamValue.value.galleryGroups;
    final reordered = TenantAdminAccountProfileGalleryOperations.moveGroup(
      previous,
      groupId: groupId,
      delta: delta,
    );
    _updateEditState(
      editStateStreamValue.value.copyWith(galleryGroups: reordered),
    );
    await _runGalleryMutation(
      () => _profilesRepository.reorderGalleryGroups(
        accountProfileId: _editGalleryProfileId(),
        groupIds: reordered
            .map((group) => _galleryText(group.groupId))
            .toList(),
      ),
      restoreGroupsOnError: previous,
      fieldErrorScope: 'group.$groupId',
    );
  }

  Future<void> removeEditGalleryGroup(String groupId) => _runGalleryMutation(
    () => _profilesRepository.deleteGalleryGroup(
      accountProfileId: _editGalleryProfileId(),
      groupId: _galleryText(groupId),
    ),
    fieldErrorScope: 'group.$groupId',
  );

  Future<void> addEditGalleryPhoto({
    required String groupId,
    required XFile uploadFile,
  }) async {
    final upload = await buildImageUpload(
      uploadFile,
      slot: TenantAdminImageSlot.accountProfileGallery,
    );
    if (upload == null) return;
    await _runGalleryMutation(
      () => _profilesRepository.createGalleryItem(
        accountProfileId: _editGalleryProfileId(),
        groupId: _galleryText(groupId),
        type: TenantAdminAccountProfileGalleryItemType.photo,
        image: upload,
      ),
      fieldErrorScope: 'group.$groupId.item.create',
    );
  }

  Future<void> addEditGalleryYoutube({
    required String groupId,
    required String youtubeUrl,
  }) => _runGalleryMutation(
    () => _profilesRepository.createGalleryItem(
      accountProfileId: _editGalleryProfileId(),
      groupId: _galleryText(groupId),
      type: TenantAdminAccountProfileGalleryItemType.youtube,
      youtubeUrl: _galleryText(youtubeUrl),
    ),
    fieldErrorScope: 'group.$groupId.item.create',
  );

  Future<void> replaceEditGalleryItemUpload({
    required String groupId,
    required String itemId,
    required XFile uploadFile,
  }) async {
    final upload = await buildImageUpload(
      uploadFile,
      slot: TenantAdminImageSlot.accountProfileGallery,
    );
    if (upload == null) return;
    await _runGalleryMutation(
      () => _profilesRepository.updateGalleryItem(
        accountProfileId: _editGalleryProfileId(),
        groupId: _galleryText(groupId),
        itemId: _galleryText(itemId),
        image: upload,
      ),
      fieldErrorScope: 'group.$groupId.item.$itemId',
    );
  }

  Future<void> replaceEditGalleryYoutube({
    required String groupId,
    required String itemId,
    required String youtubeUrl,
  }) => _runGalleryMutation(
    () => _profilesRepository.updateGalleryItem(
      accountProfileId: _editGalleryProfileId(),
      groupId: _galleryText(groupId),
      itemId: _galleryText(itemId),
      youtubeUrl: _galleryText(youtubeUrl),
    ),
    fieldErrorScope: 'group.$groupId.item.$itemId',
  );

  Future<void> updateEditGalleryItemDescription({
    required String groupId,
    required String itemId,
    required String description,
  }) => _runGalleryMutation(
    () => _profilesRepository.updateGalleryItem(
      accountProfileId: _editGalleryProfileId(),
      groupId: _galleryText(groupId),
      itemId: _galleryText(itemId),
      description: TenantAdminOptionalTextValue(defaultValue: description),
    ),
    fieldErrorScope: 'group.$groupId.item.$itemId',
  );

  Future<void> updateEditGalleryItemTitle({
    required String groupId,
    required String itemId,
    required String title,
  }) => _runGalleryMutation(
    () => _profilesRepository.updateGalleryItem(
      accountProfileId: _editGalleryProfileId(),
      groupId: _galleryText(groupId),
      itemId: _galleryText(itemId),
      title: TenantAdminOptionalTextValue(defaultValue: title),
    ),
    fieldErrorScope: 'group.$groupId.item.$itemId',
  );

  Future<void> moveEditGalleryItem({
    required String groupId,
    required String itemId,
    required int delta,
  }) async {
    final previous = editStateStreamValue.value.galleryGroups;
    final reordered = TenantAdminAccountProfileGalleryOperations.moveItem(
      previous,
      groupId: groupId,
      itemId: itemId,
      delta: delta,
    );
    _updateEditState(
      editStateStreamValue.value.copyWith(galleryGroups: reordered),
    );
    final group = reordered.firstWhere((entry) => entry.groupId == groupId);
    await _runGalleryMutation(
      () => _profilesRepository.reorderGalleryItems(
        accountProfileId: _editGalleryProfileId(),
        groupId: _galleryText(groupId),
        itemIds: group.items.map((item) => _galleryText(item.itemId)).toList(),
      ),
      restoreGroupsOnError: previous,
      fieldErrorScope: 'group.$groupId',
    );
  }

  Future<void> removeEditGalleryItem({
    required String groupId,
    required String itemId,
  }) => _runGalleryMutation(
    () => _profilesRepository.deleteGalleryItem(
      accountProfileId: _editGalleryProfileId(),
      groupId: _galleryText(groupId),
      itemId: _galleryText(itemId),
    ),
    fieldErrorScope: 'group.$groupId.item.$itemId',
  );

  TenantAdminAccountProfilesRepoString _editGalleryProfileId() =>
      _galleryText(_loadedEditProfileSnapshot?.id ?? '');

  final Map<String, String> _editGalleryInputValues = <String, String>{};

  String editGalleryInputValue(String fieldPath, String authoritativeValue) =>
      _editGalleryInputValues[fieldPath] ?? authoritativeValue;

  void updateEditGalleryInputValue(String fieldPath, String value) {
    _editGalleryInputValues[fieldPath] = value;
  }

  TenantAdminAccountProfilesRepoString _galleryText(String value) =>
      tenantAdminAccountProfilesRepoString(
        value,
        defaultValue: '',
        isRequired: true,
      );

  Future<void> _runGalleryMutation(
    Future<TenantAdminAccountProfileGallerySnapshot> Function() mutation, {
    List<TenantAdminAccountProfileGalleryGroupDraft>? restoreGroupsOnError,
    String? fieldErrorScope,
  }) async {
    editGalleryMutationBusyStreamValue.addValue(true);
    editGalleryFieldErrorsStreamValue.addValue(const {});
    editGalleryOperationErrorStreamValue.addValue(null);
    try {
      final snapshot = await mutation();
      if (_isDisposed) return;
      _applyGallerySnapshot(snapshot);
    } on FormValidationFailure catch (error) {
      if (_isDisposed) return;
      if (restoreGroupsOnError != null) {
        _updateEditState(
          editStateStreamValue.value.copyWith(
            galleryGroups: restoreGroupsOnError,
          ),
        );
      }
      final scopedFieldErrors = {
        for (final entry in error.fieldErrors.entries)
          if (entry.value.isNotEmpty &&
              _isGalleryRenderableFieldError(entry.key, fieldErrorScope))
            _galleryFieldErrorKey(entry.key, fieldErrorScope):
                entry.value.first,
      };
      editGalleryFieldErrorsStreamValue.addValue(scopedFieldErrors);
      final hasOperationFieldError = error.fieldErrors.entries.any(
        (entry) =>
            entry.value.isNotEmpty &&
            !_isGalleryRenderableFieldError(entry.key, fieldErrorScope),
      );
      if (scopedFieldErrors.isEmpty || hasOperationFieldError) {
        editGalleryOperationErrorStreamValue.addValue(error.message);
      }
      if (_isGalleryCapacityFailure(error)) {
        try {
          final refreshed = await fetchProfile(
            _loadedEditProfileSnapshot?.id ?? '',
          );
          if (!_isDisposed) {
            _applyGallerySnapshot(
              TenantAdminAccountProfileGallerySnapshot(
                groups: refreshed.galleryGroups,
                capabilities: refreshed.galleryCapabilities,
              ),
            );
          }
        } catch (_) {
          // Keep the original capacity error visible; the user may retry.
        }
      }
    } catch (error) {
      if (_isDisposed) return;
      if (restoreGroupsOnError != null) {
        _updateEditState(
          editStateStreamValue.value.copyWith(
            galleryGroups: restoreGroupsOnError,
          ),
        );
      }
      editGalleryOperationErrorStreamValue.addValue(error.toString());
    } finally {
      if (!_isDisposed) editGalleryMutationBusyStreamValue.addValue(false);
    }
  }

  bool _isGalleryCapacityFailure(FormValidationFailure error) =>
      error.statusCode == 422 &&
      error.fieldErrors.keys.any(
        (key) =>
            key.contains('gallery_capabilities') ||
            key.contains('max_galleries') ||
            key.contains('max_items_per_gallery'),
      );

  bool _isGalleryRenderableFieldError(String key, String? scope) {
    if (key.contains('gallery_capabilities') ||
        key.contains('max_galleries') ||
        key.contains('max_items_per_gallery')) {
      return true;
    }
    final parts = scope?.split('.') ?? const <String>[];
    if (parts.length == 2 && parts.first == 'group') {
      return key == 'subtitle';
    }
    if (parts.length == 4 && parts[0] == 'group' && parts[2] == 'item') {
      if (parts.last == 'create') {
        return key == 'image' || key == 'youtube_url';
      }
      return const {
        'title',
        'description',
        'image',
        'youtube_url',
      }.contains(key);
    }
    return false;
  }

  String _galleryFieldErrorKey(String key, String? scope) {
    if (scope == null || key.contains('gallery_capabilities')) return key;
    return '$scope.$key';
  }

  void _applyGallerySnapshot(
    TenantAdminAccountProfileGallerySnapshot snapshot,
  ) {
    _editGalleryInputValues.clear();
    _updateEditState(
      editStateStreamValue.value.copyWith(
        galleryGroups: snapshot.groups
            .map(TenantAdminAccountProfileGalleryGroupDraft.fromRead)
            .toList(growable: false),
        galleryCapabilities: snapshot.capabilities,
      ),
    );
  }

  void renameCreateNestedProfileGroup(String groupId, String label) {
    _updateCreateState(
      createStateStreamValue.value.copyWith(
        nestedProfileGroups: TenantAdminNestedProfileGroupOperations.rename(
          createStateStreamValue.value.nestedProfileGroups,
          groupId: groupId,
          label: label,
        ),
      ),
    );
  }

  void renameEditNestedProfileGroup(String groupId, String label) {
    _updateEditState(
      editStateStreamValue.value.copyWith(
        nestedProfileGroups: TenantAdminNestedProfileGroupOperations.rename(
          editStateStreamValue.value.nestedProfileGroups,
          groupId: groupId,
          label: label,
        ),
      ),
    );
  }

  void removeCreateNestedProfileGroup(String groupId) {
    final nextGroups = TenantAdminNestedProfileGroupOperations.remove(
      createStateStreamValue.value.nestedProfileGroups,
      groupId: groupId,
    );
    _syncSelectedNestedProfileCache(
      _selectedNestedProfileIdsAcrossDrafts(createGroups: nextGroups),
    );
    _updateCreateState(
      createStateStreamValue.value.copyWith(nestedProfileGroups: nextGroups),
    );
    _publishNestedProfileCandidates();
  }

  void removeEditNestedProfileGroup(String groupId) {
    final nextGroups = TenantAdminNestedProfileGroupOperations.remove(
      editStateStreamValue.value.nestedProfileGroups,
      groupId: groupId,
    );
    _syncSelectedNestedProfileCache(
      _selectedNestedProfileIdsAcrossDrafts(editGroups: nextGroups),
    );
    _updateEditState(
      editStateStreamValue.value.copyWith(nestedProfileGroups: nextGroups),
    );
    _publishNestedProfileCandidates();
  }

  void moveCreateNestedProfileGroup(String groupId, int delta) {
    _updateCreateState(
      createStateStreamValue.value.copyWith(
        nestedProfileGroups: TenantAdminNestedProfileGroupOperations.move(
          createStateStreamValue.value.nestedProfileGroups,
          groupId: groupId,
          delta: delta,
        ),
      ),
    );
  }

  void moveEditNestedProfileGroup(String groupId, int delta) {
    _updateEditState(
      editStateStreamValue.value.copyWith(
        nestedProfileGroups: TenantAdminNestedProfileGroupOperations.move(
          editStateStreamValue.value.nestedProfileGroups,
          groupId: groupId,
          delta: delta,
        ),
      ),
    );
  }

  void toggleCreateNestedProfileGroupMember({
    required String groupId,
    required String profileId,
    required bool selected,
  }) {
    final profile = _findNestedProfileCandidateById(profileId);
    if (selected && profile != null) {
      _selectedNestedProfileCache[profileId] = profile;
    }
    final next = TenantAdminNestedProfileGroupOperations.toggleMember(
      createStateStreamValue.value.nestedProfileGroups,
      groupId: groupId,
      profileId: profileId,
      selected: selected,
    );
    _updateCreateState(
      createStateStreamValue.value.copyWith(nestedProfileGroups: next),
    );
    _syncSelectedNestedProfileCache(
      _selectedNestedProfileIdsAcrossDrafts(createGroups: next),
    );
    _publishNestedProfileCandidates();
  }

  void toggleEditNestedProfileGroupMember({
    required String groupId,
    required String profileId,
    required bool selected,
  }) {
    final profile = _findNestedProfileCandidateById(profileId);
    if (selected && profile != null) {
      _selectedNestedProfileCache[profileId] = profile;
    }
    final next = TenantAdminNestedProfileGroupOperations.toggleMember(
      editStateStreamValue.value.nestedProfileGroups,
      groupId: groupId,
      profileId: profileId,
      selected: selected,
    );
    _updateEditState(
      editStateStreamValue.value.copyWith(nestedProfileGroups: next),
    );
    _syncSelectedNestedProfileCache(
      _selectedNestedProfileIdsAcrossDrafts(editGroups: next),
    );
    _publishNestedProfileCandidates();
  }

  Future<void> _loadNestedProfileCandidatesPage({
    required bool isInitial,
    required int requestToken,
  }) async {
    if (!isInitial &&
        (nestedProfileSearchLoadingStreamValue.value ||
            nestedProfileSearchPageLoadingStreamValue.value ||
            !nestedProfileSearchHasMoreStreamValue.value)) {
      return;
    }

    if (isInitial) {
      nestedProfileSearchLoadingStreamValue.addValue(true);
      nestedProfileSearchPageLoadingStreamValue.addValue(false);
    } else {
      nestedProfileSearchPageLoadingStreamValue.addValue(true);
    }

    try {
      final requestedPage = isInitial
          ? 1
          : _nestedProfileCandidatesCurrentPage + 1;
      final normalizedExclude = _nestedProfileCandidatesExcludeProfileId;
      final result = await _nestedProfileCandidatesPageLoader.loadPage(
        pageNumber: requestedPage,
        search: _nestedProfileCandidatesQuery,
        profileType: _nestedProfileCandidatesProfileType,
        queryableOnly: true,
        excludeAccountProfileId: normalizedExclude,
      );
      if (_isDisposed || requestToken != _nestedProfileCandidatesRequestToken) {
        return;
      }
      if (isInitial) {
        _nestedProfileCandidateWindow
          ..clear()
          ..addAll(result.items);
      } else {
        final existingWindow = List<TenantAdminAccountProfile>.from(
          _nestedProfileCandidateWindow,
        );
        _nestedProfileCandidateWindow
          ..clear()
          ..addAll(_mergeAccountProfiles(existingWindow, result.items));
      }
      _nestedProfileCandidatesCurrentPage =
          result.pagination?.currentPage ?? requestedPage;
      nestedProfileSearchHasMoreStreamValue.addValue(result.hasMore);
      await _hydrateMissingSelectedNestedProfiles();
      _publishNestedProfileCandidates();
    } catch (_) {
      if (_isDisposed || requestToken != _nestedProfileCandidatesRequestToken) {
        return;
      }
      if (isInitial) {
        _nestedProfileCandidateWindow.clear();
      }
      _syncSelectedNestedProfileCache(_selectedNestedProfileIdsAcrossDrafts());
      nestedProfileSearchHasMoreStreamValue.addValue(false);
      _publishNestedProfileCandidates();
    } finally {
      if (!_isDisposed &&
          requestToken == _nestedProfileCandidatesRequestToken) {
        nestedProfileSearchLoadingStreamValue.addValue(false);
        nestedProfileSearchPageLoadingStreamValue.addValue(false);
      }
    }
  }

  Future<void> _hydrateMissingSelectedNestedProfiles() async {
    final selectedIds = _selectedNestedProfileIdsAcrossDrafts();
    _syncSelectedNestedProfileCache(selectedIds);
    for (final profileId in selectedIds) {
      if (_selectedNestedProfileCache.containsKey(profileId) ||
          _nestedProfileCandidateWindow.any(
            (profile) => profile.id == profileId,
          )) {
        continue;
      }
      try {
        final profile = await _profilesRepository.fetchAccountProfile(
          tenantAdminAccountProfilesRepoString(
            profileId,
            defaultValue: '',
            isRequired: true,
          ),
        );
        if (_isDisposed) {
          return;
        }
        _selectedNestedProfileCache[profileId] = profile;
      } catch (_) {
        if (_isDisposed) {
          return;
        }
      }
    }
  }

  Future<void> _hydrateEditNestedGroupBaseline({
    required String accountProfileId,
    required String groupId,
    required String hydrationKey,
  }) async {
    try {
      final baseline = await loadEditNestedGroupMemberBaseline(
        accountProfileId: accountProfileId,
        groupId: groupId,
      );
      if (_isDisposed) {
        return;
      }
      final nextGroups = TenantAdminNestedProfileGroupOperations.replaceMembers(
        editStateStreamValue.value.nestedProfileGroups,
        groupId: groupId,
        profileIds: baseline.map((entry) => entry.id),
        memberCount: baseline.length,
      );
      _updateEditState(
        editStateStreamValue.value.copyWith(nestedProfileGroups: nextGroups),
      );
      await _hydrateMissingSelectedNestedProfiles();
      _publishNestedProfileCandidates();
    } finally {
      _editNestedGroupBaselineHydrationsInFlight.remove(hydrationKey);
    }
  }

  TenantAdminNestedProfileGroup? _editNestedGroupById(String groupId) {
    for (final group in editStateStreamValue.value.nestedProfileGroups) {
      if (group.id == groupId) {
        return group;
      }
    }
    return null;
  }

  bool _shouldHydrateEditNestedGroupBaseline(
    TenantAdminNestedProfileGroup group,
  ) {
    final currentIds = <String>{};
    for (final entry in group.accountProfileIdValues) {
      final normalized = entry.value.trim();
      if (normalized.isEmpty) {
        continue;
      }
      currentIds.add(normalized);
    }
    return group.memberCount > 0 && currentIds.length < group.memberCount;
  }

  void _applyEditNestedGroupMemberMutation({
    required String groupId,
    required int memberCount,
  }) {
    final nextGroups = editStateStreamValue.value.nestedProfileGroups
        .map(
          (group) => group.id == groupId
              ? group.copyWith(
                  memberCountValue: TenantAdminCountValue(memberCount),
                )
              : group,
        )
        .toList(growable: false);
    final currentProfile = accountProfileStreamValue.value;
    if (currentProfile != null) {
      accountProfileStreamValue.addValue(
        _copyAccountProfileWithNestedProfileGroups(
          currentProfile,
          nestedProfileGroups: nextGroups,
        ),
      );
    }
    _updateEditState(
      editStateStreamValue.value.copyWith(nestedProfileGroups: nextGroups),
    );
  }

  Set<String> _selectedNestedProfileIds(
    List<TenantAdminNestedProfileGroup> groups,
  ) {
    final selectedIds = <String>{};
    for (final group in groups) {
      for (final profileId in group.accountProfileIdValues) {
        selectedIds.add(profileId.value);
      }
    }
    return selectedIds;
  }

  Set<String> _selectedNestedProfileIdsAcrossDrafts({
    List<TenantAdminNestedProfileGroup>? createGroups,
    List<TenantAdminNestedProfileGroup>? editGroups,
  }) {
    final selectedIds = <String>{};
    selectedIds.addAll(
      _selectedNestedProfileIds(
        createGroups ?? createStateStreamValue.value.nestedProfileGroups,
      ),
    );
    selectedIds.addAll(
      _selectedNestedProfileIds(
        editGroups ?? editStateStreamValue.value.nestedProfileGroups,
      ),
    );
    return selectedIds;
  }

  void _syncSelectedNestedProfileCache(Set<String> selectedIds) {
    _selectedNestedProfileCache.removeWhere(
      (profileId, _) => !selectedIds.contains(profileId),
    );
  }

  void _publishNestedProfileCandidates() {
    final merged = _mergeAccountProfiles(
      _nestedProfileCandidateWindow,
      _selectedNestedProfileCache.values.toList(growable: false),
    );
    nestedProfileCandidatesStreamValue.addValue(merged);
  }

  Set<String> _selectedContactSourceIdsAcrossDrafts() {
    final selectedIds = <String>{};
    final createSelectedId = createStateStreamValue
        .value
        .contactSourceAccountProfileId
        ?.trim();
    if (createSelectedId != null && createSelectedId.isNotEmpty) {
      selectedIds.add(createSelectedId);
    }
    final editSelectedId = editStateStreamValue
        .value
        .contactSourceAccountProfileId
        ?.trim();
    if (editSelectedId != null && editSelectedId.isNotEmpty) {
      selectedIds.add(editSelectedId);
    }
    return selectedIds;
  }

  void _syncSelectedContactSourceCache(Set<String> selectedIds) {
    _selectedContactSourceCache.removeWhere(
      (profileId, _) => !selectedIds.contains(profileId),
    );
  }

  Future<void> _hydrateMissingSelectedContactSources() async {
    final selectedIds = _selectedContactSourceIdsAcrossDrafts();
    _syncSelectedContactSourceCache(selectedIds);
    for (final profileId in selectedIds) {
      if (_selectedContactSourceCache.containsKey(profileId)) {
        continue;
      }
      final profile = await _hydrateSelectedContactSourceProfile(profileId);
      if (_isDisposed) {
        return;
      }
      if (profile == null) {
        continue;
      }
      final refreshedSelectedIds = _selectedContactSourceIdsAcrossDrafts();
      if (!refreshedSelectedIds.contains(profileId)) {
        continue;
      }
      _selectedContactSourceCache[profileId] = profile;
    }
  }

  Future<TenantAdminAccountProfile?> _hydrateSelectedContactSourceProfile(
    String profileId,
  ) async {
    final inFlight = _selectedContactSourceHydrationInFlight[profileId];
    if (inFlight != null) {
      return inFlight;
    }
    final future = _fetchSelectedContactSourceProfile(profileId);
    _selectedContactSourceHydrationInFlight[profileId] = future;
    try {
      return await future;
    } finally {
      if (identical(
        _selectedContactSourceHydrationInFlight[profileId],
        future,
      )) {
        _selectedContactSourceHydrationInFlight.remove(profileId);
      }
    }
  }

  Future<TenantAdminAccountProfile?> _fetchSelectedContactSourceProfile(
    String profileId,
  ) async {
    try {
      return await _profilesRepository.fetchAccountProfile(
        tenantAdminAccountProfilesRepoString(
          profileId,
          defaultValue: '',
          isRequired: true,
        ),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _hydrateAndPublishSelectedContactSources() async {
    await _hydrateMissingSelectedContactSources();
    if (_isDisposed) {
      return;
    }
    _publishContactSourceCandidates();
  }

  void _publishContactSourceCandidates() {
    final merged = _mergeAccountProfiles(
      _selectedContactSourceCache.values.toList(growable: false),
      _contactSourceCandidateWindow,
    );
    contactSourceCandidatesStreamValue.addValue(merged);
  }

  TenantAdminAccountProfile? _findNestedProfileCandidateById(String profileId) {
    for (final profile in nestedProfileCandidatesStreamValue.value) {
      if (profile.id == profileId) {
        return profile;
      }
    }
    return null;
  }

  List<TenantAdminAccountProfile> _mergeAccountProfiles(
    List<TenantAdminAccountProfile> current,
    List<TenantAdminAccountProfile> incoming,
  ) {
    final merged = <TenantAdminAccountProfile>[];
    final seenIds = <String>{};
    for (final profile in [...current, ...incoming]) {
      if (seenIds.add(profile.id)) {
        merged.add(profile);
      }
    }
    return List<TenantAdminAccountProfile>.unmodifiable(merged);
  }

  void resetFormControllers() {
    if (_isDisposed) {
      return;
    }
    slugController.clear();
    displayNameController.clear();
    bioController.clear();
    contentController.clear();
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

  void setTaxonomySelectionFromTerms(TenantAdminTaxonomyTerms terms) {
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
    if (_isDisposed) {
      return;
    }
    _resetNestedProfileCandidates();
    _updateCreateState(TenantAdminAccountProfileCreateDraft.initial());
  }

  void _updateEditState(TenantAdminAccountProfileEditDraft state) {
    if (_isDisposed) return;
    editStateStreamValue.addValue(state);
  }

  void _updateCreateState(TenantAdminAccountProfileCreateDraft state) {
    if (_isDisposed) return;
    createStateStreamValue.addValue(state);
  }

  void resetAccountDetail() {
    if (_isDisposed) {
      return;
    }
    _clearAccountWatch();
    _watchedAccountId = null;
    _watchedAccountSlug = null;
    _accountDetailStreamValue.addValue(null);
    accountProfileStreamValue.addValue(null);
    _loadedEditProfileSnapshot = null;
    accountDetailErrorStreamValue.addValue(null);
    accountDetailLoadingStreamValue.addValue(false);
    accountDeletingStreamValue.addValue(false);
    accountDeletedStreamValue.addValue(false);
  }

  void clearAccountDeletedFlag() {
    if (_isDisposed) {
      return;
    }
    accountDeletedStreamValue.addValue(false);
  }

  void _bindAccountWatch({
    required String? accountId,
    required String? accountSlug,
  }) {
    final normalizedId = accountId?.trim();
    final normalizedSlug = accountSlug?.trim();
    final isSameBinding =
        _accountWatch != null &&
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

  Future<TenantAdminAccountProfile> createProfile({
    required String accountId,
    required String profileType,
    required String displayName,
    TenantAdminLocation? location,
    TenantAdminTaxonomyTerms taxonomyTerms =
        const TenantAdminTaxonomyTerms.empty(),
    String? bio,
    String? content,
    String? avatarUrl,
    String? coverUrl,
    TenantAdminMediaUpload? avatarUpload,
    TenantAdminMediaUpload? coverUpload,
    List<TenantAdminNestedProfileGroup> nestedProfileGroups =
        const <TenantAdminNestedProfileGroup>[],
    BellugaContactSourceMode contactMode = BellugaContactSourceMode.own,
    String? contactSourceAccountProfileId,
    List<BellugaContactChannelDraft>? contactChannelDrafts,
    BellugaContactBubbleSelectionMutation bubbleSelection =
        const BellugaContactBubbleSelectionMutation.omit(),
  }) async {
    final filtered = _filterCapabilities(
      profileType: profileType,
      location: location,
      taxonomyTerms: taxonomyTerms,
      bio: bio,
      content: content,
      avatarUrl: avatarUrl,
      coverUrl: coverUrl,
      avatarUpload: avatarUpload,
      coverUpload: coverUpload,
    );
    final accountIdValue = tenantAdminAccountProfilesRepoString(
      accountId,
      defaultValue: '',
      isRequired: true,
    );
    final profileTypeValue = tenantAdminAccountProfilesRepoString(
      profileType,
      defaultValue: '',
      isRequired: true,
    );
    final displayNameValue = tenantAdminAccountProfilesRepoString(
      displayName,
      defaultValue: '',
      isRequired: true,
    );
    final contactSourceValue =
        contactSourceAccountProfileId == null ||
            contactSourceAccountProfileId.trim().isEmpty
        ? null
        : tenantAdminAccountProfilesRepoString(contactSourceAccountProfileId);
    var profile = await _profilesRepository.createAccountProfile(
      accountId: accountIdValue,
      profileType: profileTypeValue,
      displayName: displayNameValue,
      location: filtered.location,
      taxonomyTerms: filtered.taxonomyTerms,
      bio: filtered.bio == null
          ? null
          : tenantAdminAccountProfilesRepoString(filtered.bio),
      content: filtered.content == null
          ? null
          : tenantAdminAccountProfilesRepoString(filtered.content),
      avatarUrl: filtered.avatarUrl == null
          ? null
          : tenantAdminAccountProfilesRepoString(filtered.avatarUrl),
      coverUrl: filtered.coverUrl == null
          ? null
          : tenantAdminAccountProfilesRepoString(filtered.coverUrl),
      avatarUpload: filtered.avatarUpload,
      coverUpload: filtered.coverUpload,
      contactMode: contactMode,
      contactSourceAccountProfileId: contactSourceValue,
      contactChannelDrafts:
          contactChannelDrafts ?? const <BellugaContactChannelDraft>[],
      bubbleSelection: bubbleSelection,
    );
    if (!_isDisposed) {
      accountProfileStreamValue.addValue(profile);
    }
    await loadProfiles(accountId);
    return profile;
  }

  Future<TenantAdminAccountProfile> updateProfile({
    required String accountProfileId,
    String? profileType,
    String? displayName,
    String? slug,
    TenantAdminLocation? location,
    TenantAdminTaxonomyTerms? taxonomyTerms,
    String? bio,
    String? content,
    String? avatarUrl,
    String? coverUrl,
    bool? removeAvatar,
    bool? removeCover,
    TenantAdminMediaUpload? avatarUpload,
    TenantAdminMediaUpload? coverUpload,
    List<TenantAdminNestedProfileGroup>? nestedProfileGroups,
    BellugaContactSourceMode? contactMode,
    String? contactSourceAccountProfileId,
    List<BellugaContactChannelDraft>? contactChannelDrafts,
    BellugaContactBubbleSelectionMutation bubbleSelection =
        const BellugaContactBubbleSelectionMutation.omit(),
  }) async {
    final filtered = profileType == null
        ? _CapabilityFilter(
            location: location,
            taxonomyTerms:
                taxonomyTerms ?? const TenantAdminTaxonomyTerms.empty(),
            bio: bio,
            content: content,
            avatarUrl: avatarUrl,
            coverUrl: coverUrl,
            avatarUpload: avatarUpload,
            coverUpload: coverUpload,
          )
        : _filterCapabilities(
            profileType: profileType,
            location: location,
            taxonomyTerms:
                taxonomyTerms ?? const TenantAdminTaxonomyTerms.empty(),
            bio: bio,
            content: content,
            avatarUrl: avatarUrl,
            coverUrl: coverUrl,
            avatarUpload: avatarUpload,
            coverUpload: coverUpload,
          );
    final accountProfileIdValue = tenantAdminAccountProfilesRepoString(
      accountProfileId,
      defaultValue: '',
      isRequired: true,
    );
    final contactSourceValue =
        contactSourceAccountProfileId == null ||
            contactSourceAccountProfileId.trim().isEmpty
        ? null
        : tenantAdminAccountProfilesRepoString(contactSourceAccountProfileId);
    final profile = await _profilesRepository.updateAccountProfile(
      accountProfileId: accountProfileIdValue,
      profileType: profileType == null
          ? null
          : tenantAdminAccountProfilesRepoString(profileType),
      displayName: displayName == null
          ? null
          : tenantAdminAccountProfilesRepoString(displayName),
      slug: slug == null ? null : tenantAdminAccountProfilesRepoString(slug),
      location: filtered.location,
      taxonomyTerms: taxonomyTerms == null ? null : filtered.taxonomyTerms,
      bio: filtered.bio == null
          ? null
          : tenantAdminAccountProfilesRepoString(filtered.bio),
      content: filtered.content == null
          ? null
          : tenantAdminAccountProfilesRepoString(filtered.content),
      avatarUrl: filtered.avatarUrl == null
          ? null
          : tenantAdminAccountProfilesRepoString(filtered.avatarUrl),
      coverUrl: filtered.coverUrl == null
          ? null
          : tenantAdminAccountProfilesRepoString(filtered.coverUrl),
      removeAvatar: removeAvatar == null
          ? null
          : tenantAdminAccountProfilesRepoBool(removeAvatar),
      removeCover: removeCover == null
          ? null
          : tenantAdminAccountProfilesRepoBool(removeCover),
      avatarUpload: filtered.avatarUpload,
      coverUpload: filtered.coverUpload,
      contactMode: contactMode,
      contactSourceAccountProfileId: contactSourceValue,
      contactChannelDrafts: contactChannelDrafts,
      bubbleSelection: bubbleSelection,
    );
    await loadProfiles(profile.accountId);
    return profile;
  }

  TenantAdminProfileTypeDefinition? _resolveProfileType(String profileType) {
    for (final definition in profileTypesStreamValue.value) {
      if (definition.type == profileType) {
        return definition;
      }
    }
    return null;
  }

  List<BellugaContactChannelDraft> buildCreateContactChannelDrafts({
    required bool capabilityEnabled,
  }) =>
      !capabilityEnabled ||
          createStateStreamValue.value.contactMode !=
              BellugaContactSourceMode.own
      ? const <BellugaContactChannelDraft>[]
      : createStateStreamValue.value.contactChannelDrafts;

  List<BellugaContactChannelDraft> buildEditContactChannelDrafts({
    required bool capabilityEnabled,
  }) =>
      !capabilityEnabled ||
          editStateStreamValue.value.contactMode != BellugaContactSourceMode.own
      ? const <BellugaContactChannelDraft>[]
      : editStateStreamValue.value.contactChannelDrafts;

  BellugaContactBubbleSelectionMutation createBubbleSelection({
    required bool capabilityEnabled,
  }) => !capabilityEnabled
      ? const BellugaContactBubbleSelectionMutation.omit()
      : createStateStreamValue.value.contactBubbleSelection;

  BellugaContactBubbleSelectionMutation editBubbleSelection({
    required bool capabilityEnabled,
  }) => !capabilityEnabled
      ? const BellugaContactBubbleSelectionMutation.omit()
      : editStateStreamValue.value.contactBubbleSelection;

  String? validateCreateContactDraft({required bool capabilityEnabled}) {
    final draftValidation = _validateContactDraftCollection(
      capabilityEnabled: capabilityEnabled,
      mode: createStateStreamValue.value.contactMode,
      drafts: buildCreateContactChannelDrafts(
        capabilityEnabled: capabilityEnabled,
      ),
    );
    if (draftValidation != null) return draftValidation;
    return _validateContactSource(
      capabilityEnabled: capabilityEnabled,
      mode: createStateStreamValue.value.contactMode,
      sourceAccountProfileId:
          createStateStreamValue.value.contactSourceAccountProfileId,
    );
  }

  String? validateEditContactDraft({required bool capabilityEnabled}) {
    final draftValidation = _validateContactDraftCollection(
      capabilityEnabled: capabilityEnabled,
      mode: editStateStreamValue.value.contactMode,
      drafts: buildEditContactChannelDrafts(
        capabilityEnabled: capabilityEnabled,
      ),
    );
    if (draftValidation != null) return draftValidation;
    return _validateContactSource(
      capabilityEnabled: capabilityEnabled,
      mode: editStateStreamValue.value.contactMode,
      sourceAccountProfileId:
          editStateStreamValue.value.contactSourceAccountProfileId,
    );
  }

  BellugaContactResolution? resolveDraftContactChannel({
    required BellugaContactChannelType type,
    required String rawValue,
    String? prefilledMessage,
  }) {
    return BellugaContactChannelResolver.resolveRaw(
      type: type,
      rawValue: rawValue,
      prefilledMessage: prefilledMessage,
    );
  }

  String? _validateContactDraftCollection({
    required bool capabilityEnabled,
    required BellugaContactSourceMode mode,
    required List<BellugaContactChannelDraft> drafts,
  }) {
    if (!capabilityEnabled || mode != BellugaContactSourceMode.own) return null;
    final errors = BellugaContactChannelDraftValidator.validate(drafts);
    if (errors.isNotEmpty) return errors.first;
    for (final draft in drafts) {
      if (!draft.definition.capabilities.messagePresets) continue;
      for (final message in draft.initialMessages) {
        final hasCta = message.cta.trim().isNotEmpty;
        final hasMessage = message.message.trim().isNotEmpty;
        if (hasCta != hasMessage) {
          return 'Preencha CTA e mensagem do WhatsApp.';
        }
      }
    }
    return null;
  }

  String? _validateContactSource({
    required bool capabilityEnabled,
    required BellugaContactSourceMode mode,
    required String? sourceAccountProfileId,
  }) {
    if (!capabilityEnabled) {
      return null;
    }
    if (mode == BellugaContactSourceMode.mirroredAccountProfile) {
      final normalizedSource = sourceAccountProfileId?.trim();
      if (normalizedSource == null || normalizedSource.isEmpty) {
        return 'Selecione o perfil de origem do contato.';
      }
      return null;
    }
    return null;
  }

  String _newContactDraftKey(BellugaContactChannelType type) =>
      '${type.rawValue}-${DateTime.now().microsecondsSinceEpoch}';

  BellugaContactInitialMessage _newContactInitialMessage() =>
      BellugaContactInitialMessage(
        id: 'wa-cta-${DateTime.now().microsecondsSinceEpoch}',
        cta: '',
        message: '',
      );

  bool _canAddContactInitialMessage(BellugaContactChannelDraft draft) {
    final capabilities = draft.definition.capabilities;
    return capabilities.messagePresets &&
        draft.initialMessages.length < capabilities.maxInitialMessages;
  }

  List<BellugaContactChannelDraft> _replaceContactDraft(
    List<BellugaContactChannelDraft> drafts,
    BellugaContactChannelDraft replacement,
  ) => drafts
      .map(
        (draft) => draft.draftKey == replacement.draftKey ? replacement : draft,
      )
      .toList(growable: false);

  BellugaContactChannelDraft _requireEditContactDraft(String draftKey) =>
      _requireContactDraft(
        editStateStreamValue.value.contactChannelDrafts,
        draftKey,
      );

  BellugaContactChannelDraft _requireCreateContactDraft(String draftKey) =>
      _requireContactDraft(
        createStateStreamValue.value.contactChannelDrafts,
        draftKey,
      );

  BellugaContactChannelDraft _requireContactDraft(
    List<BellugaContactChannelDraft> drafts,
    String draftKey,
  ) {
    for (final draft in drafts) {
      if (draft.draftKey == draftKey) return draft;
    }
    throw StateError(
      'Contact channel draft was removed before it could be edited.',
    );
  }

  BellugaContactBubbleSelectionMutation _bubbleSelectionForDraft(
    BellugaContactChannelDraft draft,
  ) => draft.isPersisted
      ? BellugaContactBubbleSelectionMutation.setPersisted(draft.id!)
      : BellugaContactBubbleSelectionMutation.setDraft(draft.draftKey);

  BellugaContactBubbleSelectionMutation _bubbleSelectionAfterRemoval(
    BellugaContactBubbleSelectionMutation selection,
    BellugaContactChannelDraft? removedDraft,
  ) {
    if (selection is BellugaContactBubbleSelectionDraft &&
        selection.draftKey == removedDraft?.draftKey) {
      return const BellugaContactBubbleSelectionMutation.clear();
    }
    if (selection is BellugaContactBubbleSelectionPersisted &&
        selection.channelId == removedDraft?.id) {
      return const BellugaContactBubbleSelectionMutation.clear();
    }
    return selection;
  }

  BellugaContactBubbleSelectionMutation _normalizeBubbleSelectionForMode({
    required BellugaContactSourceMode mode,
    required BellugaContactBubbleSelectionMutation selection,
  }) {
    if (mode == BellugaContactSourceMode.own) {
      return selection;
    }
    if (selection is BellugaContactBubbleSelectionDraft) {
      return const BellugaContactBubbleSelectionMutation.clear();
    }
    return selection;
  }

  BellugaContactChannelDraft? _findContactDraft(
    List<BellugaContactChannelDraft> drafts,
    String draftKey,
  ) {
    for (final draft in drafts) {
      if (draft.draftKey == draftKey) return draft;
    }
    return null;
  }

  _CapabilityFilter _filterCapabilities({
    required String profileType,
    required TenantAdminLocation? location,
    required TenantAdminTaxonomyTerms taxonomyTerms,
    required String? bio,
    required String? content,
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
        content: content,
        avatarUrl: avatarUrl,
        coverUrl: coverUrl,
        avatarUpload: avatarUpload,
        coverUpload: coverUpload,
      );
    }
    final capabilities = definition.capabilities;
    final allowedTaxonomies = definition.allowedTaxonomies.toSet();
    final filteredTerms = capabilities.hasTaxonomies
        ? (() {
            final terms = TenantAdminTaxonomyTerms();
            for (final taxonomyTerm in taxonomyTerms) {
              if (allowedTaxonomies.contains(taxonomyTerm.type)) {
                terms.add(taxonomyTerm);
              }
            }
            return terms;
          })()
        : const TenantAdminTaxonomyTerms.empty();
    return _CapabilityFilter(
      location: capabilities.isPoiEnabled ? location : null,
      taxonomyTerms: filteredTerms,
      bio: capabilities.hasBio ? bio : null,
      content: capabilities.hasContent ? content : null,
      avatarUrl: capabilities.hasAvatar ? avatarUrl : null,
      coverUrl: capabilities.hasCover ? coverUrl : null,
      avatarUpload: capabilities.hasAvatar ? avatarUpload : null,
      coverUpload: capabilities.hasCover ? coverUpload : null,
    );
  }

  void dispose() {
    _isDisposed = true;
    unawaited(_tenantScopeSubscription?.cancel());
    _nestedProfileSearchDebounce?.cancel();
    _contactSourceSearchDebounce?.cancel();
    _locationSelectionSubscription?.cancel();
    _clearAccountWatch();
    slugController.dispose();
    displayNameController.dispose();
    bioController.dispose();
    contentController.dispose();
    latitudeController.dispose();
    longitudeController.dispose();
    profilesStreamValue.dispose();
    nestedProfileCandidatesStreamValue.dispose();
    contactSourceCandidatesStreamValue.dispose();
    contactSourceCandidatesLoadingStreamValue.dispose();
    contactSourceCandidatesPageLoadingStreamValue.dispose();
    contactSourceCandidatesHasMoreStreamValue.dispose();
    contactSourceCandidatesErrorStreamValue.dispose();
    nestedProfileSearchLoadingStreamValue.dispose();
    nestedProfileSearchPageLoadingStreamValue.dispose();
    nestedProfileSearchHasMoreStreamValue.dispose();
    profileTypesStreamValue.dispose();
    taxonomiesStreamValue.dispose();
    taxonomyTermsStreamValue.dispose();
    taxonomySelectionStreamValue.dispose();
    isLoadingStreamValue.dispose();
    errorStreamValue.dispose();
    _accountDetailStreamValue.dispose();
    accountProfileStreamValue.dispose();
    accountDetailLoadingStreamValue.dispose();
    accountDetailErrorStreamValue.dispose();
    accountUpdatingStreamValue.dispose();
    accountDeletingStreamValue.dispose();
    accountDeletedStreamValue.dispose();
    editStateStreamValue.dispose();
    editLoadingStreamValue.dispose();
    editLoadErrorStreamValue.dispose();
    createStateStreamValue.dispose();
    editSubmittingStreamValue.dispose();
    editSuccessMessageStreamValue.dispose();
    editErrorMessageStreamValue.dispose();
    editGalleryMutationBusyStreamValue.dispose();
    editGalleryFieldErrorsStreamValue.dispose();
    editGalleryOperationErrorStreamValue.dispose();
    editNestedGroupMutationBusyStreamValue.dispose();
    _clearNestedGroupLabelStates();
    taxonomyAutosavingStreamValue.dispose();
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

class _CapabilityFilter {
  const _CapabilityFilter({
    required this.location,
    required this.taxonomyTerms,
    required this.bio,
    required this.content,
    required this.avatarUrl,
    required this.coverUrl,
    required this.avatarUpload,
    required this.coverUpload,
  });

  final TenantAdminLocation? location;
  final TenantAdminTaxonomyTerms taxonomyTerms;
  final String? bio;
  final String? content;
  final String? avatarUrl;
  final String? coverUrl;
  final TenantAdminMediaUpload? avatarUpload;
  final TenantAdminMediaUpload? coverUpload;
}
