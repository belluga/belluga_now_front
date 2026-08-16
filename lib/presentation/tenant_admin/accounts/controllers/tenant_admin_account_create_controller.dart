export 'tenant_admin_account_create_draft.dart';

import 'dart:async';

import 'package:belluga_form_validation/belluga_form_validation.dart';
import 'package:belluga_now/domain/repositories/tenant_admin_account_profiles_repository_contract.dart';
import 'package:belluga_now/domain/repositories/tenant_admin_accounts_repository_contract.dart';
import 'package:belluga_now/domain/tenant_admin/ownership_state.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_account_onboarding_result.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_location.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_profile_type.dart';
import 'package:belluga_now/domain/services/tenant_admin_location_selection_contract.dart';
import 'package:belluga_now/presentation/tenant_admin/accounts/controllers/tenant_admin_account_create_draft.dart';
import 'package:belluga_now/presentation/tenant_admin/accounts/models/tenant_admin_account_create_validation_config.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/utils/tenant_admin_form_value_utils.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart' show Disposable, GetIt;
import 'package:stream_value/core/stream_value.dart';

class TenantAdminAccountCreateController implements Disposable {
  TenantAdminAccountCreateController({
    TenantAdminAccountsRepositoryContract? accountsRepository,
    TenantAdminAccountProfilesRepositoryContract? profilesRepository,
    TenantAdminLocationSelectionContract? locationSelectionService,
  }) : _accountsRepository =
           accountsRepository ??
           GetIt.I.get<TenantAdminAccountsRepositoryContract>(),
       _profilesRepository =
           profilesRepository ??
           GetIt.I.get<TenantAdminAccountProfilesRepositoryContract>(),
       _locationSelectionService =
           locationSelectionService ??
           GetIt.I.get<TenantAdminLocationSelectionContract>();

  final TenantAdminAccountsRepositoryContract _accountsRepository;
  final TenantAdminAccountProfilesRepositoryContract _profilesRepository;
  final TenantAdminLocationSelectionContract _locationSelectionService;

  final StreamValue<List<TenantAdminProfileTypeDefinition>>
  profileTypesStreamValue = StreamValue<List<TenantAdminProfileTypeDefinition>>(
    defaultValue: const [],
  );
  final StreamValue<bool> isProfileTypesLoadingStreamValue = StreamValue<bool>(
    defaultValue: false,
  );
  final StreamValue<String?> errorStreamValue = StreamValue<String?>();
  final StreamValue<bool> createSubmittingStreamValue = StreamValue<bool>(
    defaultValue: false,
  );
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
  final GlobalKey<FormState> createFormKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
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
    if (_locationSelectionSubscription != null) {
      return;
    }
    _locationSelectionSubscription = _locationSelectionService
        .confirmedLocationStreamValue
        .stream
        .listen((location) {
          if (_isDisposed || location == null) {
            return;
          }
          latitudeController.text = location.latitude.toStringAsFixed(6);
          longitudeController.text = location.longitude.toStringAsFixed(6);
          _locationSelectionService.clearConfirmedLocation();
        });
  }

  Future<void> loadProfileTypes() async {
    isProfileTypesLoadingStreamValue.addValue(true);
    try {
      await _profilesRepository.loadAllProfileTypes();
      final types =
          _profilesRepository.profileTypesStreamValue.value ??
          const <TenantAdminProfileTypeDefinition>[];
      if (_isDisposed) {
        return;
      }
      profileTypesStreamValue.addValue(types);
      errorStreamValue.addValue(null);
    } catch (error) {
      if (_isDisposed) {
        return;
      }
      errorStreamValue.addValue(error.toString());
    } finally {
      if (!_isDisposed) {
        isProfileTypesLoadingStreamValue.addValue(false);
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
  }

  void resetCreateState() {
    clearCreateValidation();
    clearCreateSuccessAccount();
    _updateCreateState(TenantAdminAccountCreateDraft.initial());
  }

  Future<TenantAdminAccountOnboardingResult> createAccountOnboarding({
    required String name,
    required TenantAdminOwnershipState ownershipState,
    required String profileType,
    TenantAdminLocation? location,
  }) async {
    return _accountsRepository.createAccountOnboarding(
      name: TenantAdminAccountsRepositoryContractPrimString.fromRaw(
        name.trim(),
        defaultValue: '',
        isRequired: true,
      ),
      ownershipState: ownershipState,
      profileType: TenantAdminAccountsRepositoryContractPrimString.fromRaw(
        profileType,
        defaultValue: '',
        isRequired: true,
      ),
      location: location,
    );
  }

  Future<TenantAdminAccountOnboardingResult> createAccountFromForm({
    required TenantAdminLocation? location,
  }) async {
    final selectedProfileType =
        createStateStreamValue.value.selectedProfileType ?? '';
    return createAccountOnboarding(
      name: nameController.text.trim(),
      ownershipState: TenantAdminOwnershipState.tenantOwned,
      profileType: selectedProfileType,
      location: location,
    );
  }

  bool validateCreateBeforeSubmit({required TenantAdminLocation? location}) {
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
      final onboardingResult = await createAccountFromForm(location: location);
      if (_isDisposed) {
        return false;
      }
      clearCreateValidation();
      createErrorMessageStreamValue.addValue(null);
      createSuccessAccountStreamValue.addValue(onboardingResult);
      return true;
    } on FormValidationFailure catch (error) {
      if (_isDisposed) {
        return false;
      }
      createValidationController.applyFailure(error);
      createErrorMessageStreamValue.addValue(null);
      return false;
    } catch (error) {
      if (_isDisposed) {
        return false;
      }
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
    latitudeController.clear();
    longitudeController.clear();
    clearCreateValidation();
  }

  void dispose() {
    _isDisposed = true;
    _locationSelectionSubscription?.cancel();
    nameController.dispose();
    latitudeController.dispose();
    longitudeController.dispose();
    profileTypesStreamValue.dispose();
    isProfileTypesLoadingStreamValue.dispose();
    errorStreamValue.dispose();
    createStateStreamValue.dispose();
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

  void _updateCreateState(TenantAdminAccountCreateDraft state) {
    if (_isDisposed) {
      return;
    }
    createStateStreamValue.addValue(state);
  }
}
