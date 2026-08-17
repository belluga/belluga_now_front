import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:belluga_form_validation/belluga_form_validation.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/application/router/support/tenant_admin_safe_back.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_account_onboarding_result.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_location.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_profile_type.dart';
import 'package:belluga_now/presentation/tenant_admin/accounts/controllers/tenant_admin_account_create_controller.dart';
import 'package:belluga_now/presentation/tenant_admin/accounts/models/tenant_admin_account_create_validation_config.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/utils/tenant_admin_form_value_utils.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/widgets/tenant_admin_error_banner.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/widgets/tenant_admin_form_layout.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value_builder.dart';

class TenantAdminAccountCreateScreen extends StatefulWidget {
  const TenantAdminAccountCreateScreen({super.key});

  @override
  State<TenantAdminAccountCreateScreen> createState() =>
      _TenantAdminAccountCreateScreenState();
}

class _TenantAdminAccountCreateScreenState
    extends State<TenantAdminAccountCreateScreen> {
  final TenantAdminAccountCreateController _controller = GetIt.I
      .get<TenantAdminAccountCreateController>();
  final FormValidationAnchors _validationAnchors = FormValidationAnchors();

  StreamSubscription<String?>? _createErrorSubscription;
  StreamSubscription<TenantAdminAccountOnboardingResult?>?
  _createSuccessSubscription;

  @override
  void initState() {
    super.initState();
    _controller.bindCreateFlow();
    _controller.resetCreateState();
    _controller.resetCreateForm();
    _controller.loadProfileTypes();
    _bindCreateSideEffects();
  }

  @override
  void dispose() {
    _createErrorSubscription?.cancel();
    _createSuccessSubscription?.cancel();
    super.dispose();
  }

  TenantAdminProfileTypeDefinition? _profileTypeDefinition(
    String? selectedType,
  ) {
    if (selectedType == null || selectedType.isEmpty) {
      return null;
    }
    for (final definition in _controller.profileTypesStreamValue.value) {
      if (definition.type == selectedType) {
        return definition;
      }
    }
    return null;
  }

  bool _requiresLocation(String? selectedType) {
    final definition = _profileTypeDefinition(selectedType);
    return definition?.capabilities.isPoiEnabled ?? false;
  }

  Future<void> _openMapPicker() async {
    final currentLocation = _currentLocation();
    context.router.push<TenantAdminLocation?>(
      TenantAdminLocationPickerRoute(
        initialLocation: currentLocation,
        backFallbackRoute: const TenantAdminAccountCreateRoute(),
      ),
    );
  }

  TenantAdminLocation? _currentLocation() {
    final latText = _controller.latitudeController.text.trim();
    final lngText = _controller.longitudeController.text.trim();
    if (latText.isEmpty || lngText.isEmpty) {
      return null;
    }
    final lat = tenantAdminParseLatitude(latText);
    final lng = tenantAdminParseLongitude(lngText);
    if (lat == null || lng == null) {
      return null;
    }
    return tenantAdminLocationFromRaw(latitude: lat, longitude: lng);
  }

  void _bindCreateSideEffects() {
    _createErrorSubscription ??= _controller
        .createErrorMessageStreamValue
        .stream
        .listen(_handleCreateErrorMessage);
    _createSuccessSubscription ??= _controller
        .createSuccessAccountStreamValue
        .stream
        .listen(_handleCreateSuccess);
  }

  Future<void> _submitCreate() async {
    final location = _currentLocation();
    final isLocallyValid = _controller.validateCreateBeforeSubmit(
      location: location,
    );
    if (!isLocallyValid) {
      await _scrollToFirstInvalidTarget();
      return;
    }
    final created = await _controller.submitCreateAccountFromForm(
      location: location,
    );
    if (!created && _controller.createValidationStreamValue.value.hasErrors) {
      await _scrollToFirstInvalidTarget();
    }
  }

  Future<void> _scrollToFirstInvalidTarget() {
    return _validationAnchors.scrollToFirstInvalidTarget(
      _controller.createValidationStreamValue.value,
    );
  }

  String _validationSummarySuffix(int remainingCount) {
    return '(+$remainingCount erros)';
  }

  void _handleCreateErrorMessage(String? message) {
    if (message == null || message.isEmpty || !mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
    _controller.clearCreateErrorMessage();
  }

  void _handleCreateSuccess(TenantAdminAccountOnboardingResult? result) {
    if (result == null || !mounted) {
      return;
    }
    _controller.clearCreateSuccessAccount();
    context.router.replace(
      TenantAdminAccountProfileEditRoute(
        accountSlug: result.account.slug,
        accountProfileId: result.accountProfile.id,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamValueBuilder<TenantAdminAccountCreateDraft>(
      streamValue: _controller.createStateStreamValue,
      builder: (context, draft) {
        final state = draft;
        final requiresLocation = _requiresLocation(state.selectedProfileType);
        return TenantAdminFormScaffold(
          closePolicy: buildTenantAdminCurrentRouteBackPolicy(context),
          title: 'Criar Conta',
          child: SingleChildScrollView(
            child: Form(
              key: _controller.createFormKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FormValidationAnchor(
                    anchors: _validationAnchors,
                    targetId: TenantAdminAccountCreateValidationTargets.global,
                    child: FormValidationGlobalSummary(
                      validationStreamValue:
                          _controller.createValidationStreamValue,
                      targetId:
                          TenantAdminAccountCreateValidationTargets.global,
                      summarySuffixBuilder: _validationSummarySuffix,
                      expandLabel: 'Ver todos',
                      collapseLabel: 'Ocultar',
                    ),
                  ),
                  _buildAccountSection(context, state),
                  if (requiresLocation) ...[
                    const SizedBox(height: 16),
                    _buildLocationSection(context),
                  ],
                  const SizedBox(height: 24),
                  StreamValueBuilder<bool>(
                    streamValue: _controller.createSubmittingStreamValue,
                    builder: (context, isSubmitting) {
                      return TenantAdminPrimaryFormAction(
                        buttonKey: const ValueKey(
                          'tenant_admin_account_create_save',
                        ),
                        label: 'Salvar conta',
                        loadingLabel: 'Salvando conta...',
                        icon: Icons.save_outlined,
                        isLoading: isSubmitting,
                        onPressed: _submitCreate,
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAccountSection(
    BuildContext context,
    TenantAdminAccountCreateDraft state,
  ) {
    return TenantAdminFormSectionCard(
      title: 'Dados da conta',
      description:
          'Associe o tipo de perfil e defina o nome da conta para habilitar os campos dependentes.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StreamValueBuilder<bool>(
            streamValue: _controller.isProfileTypesLoadingStreamValue,
            builder: (context, isLoading) {
              return StreamValueBuilder<String?>(
                streamValue: _controller.errorStreamValue,
                builder: (context, error) {
                  return StreamValueBuilder(
                    streamValue: _controller.profileTypesStreamValue,
                    builder: (context, types) {
                      final hasTypes = types.isNotEmpty;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (isLoading) const LinearProgressIndicator(),
                          if (error?.isNotEmpty ?? false)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: TenantAdminErrorBanner(
                                key: const ValueKey(
                                  'tenant_admin_account_create_profile_types_error',
                                ),
                                rawError: error ?? '',
                                fallbackMessage:
                                    'Falha ao carregar tipos de perfil para este tenant.',
                                onRetry: _controller.loadProfileTypes,
                              ),
                            ),
                          const SizedBox(height: 8),
                          FormValidationAnchor(
                            anchors: _validationAnchors,
                            targetId: TenantAdminAccountCreateValidationTargets
                                .profileType,
                            child: FormValidationFieldErrorBuilder(
                              validationStreamValue:
                                  _controller.createValidationStreamValue,
                              fieldId: TenantAdminAccountCreateValidationTargets
                                  .profileType,
                              builder: (context, errorText) {
                                return DropdownButtonFormField<String>(
                                  key: ValueKey(state.selectedProfileType),
                                  initialValue: state.selectedProfileType,
                                  decoration: InputDecoration(
                                    labelText: 'Tipo de perfil',
                                    errorText: errorText,
                                  ),
                                  items: types
                                      .map(
                                        (type) => DropdownMenuItem<String>(
                                          value: type.type,
                                          child: Text(type.label),
                                        ),
                                      )
                                      .toList(growable: false),
                                  onChanged: hasTypes
                                      ? (value) {
                                          _controller
                                              .updateCreateSelectedProfileType(
                                                value,
                                              );
                                          if (!_requiresLocation(value)) {
                                            _controller.latitudeController
                                                .clear();
                                            _controller.longitudeController
                                                .clear();
                                          }
                                        }
                                      : null,
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton.icon(
                              onPressed: () {
                                context.router
                                    .push(
                                      const TenantAdminProfileTypeCreateRoute(),
                                    )
                                    .then((_) {
                                      if (!mounted) {
                                        return;
                                      }
                                      _controller.loadProfileTypes();
                                    });
                              },
                              icon: const Icon(Icons.add),
                              label: const Text('Criar tipo de perfil'),
                            ),
                          ),
                          if (!isLoading &&
                              !(error?.isNotEmpty ?? false) &&
                              !hasTypes)
                            const Padding(
                              padding: EdgeInsets.only(top: 8),
                              child: Text(
                                'Nenhum tipo disponivel para este tenant.',
                              ),
                            ),
                        ],
                      );
                    },
                  );
                },
              );
            },
          ),
          const SizedBox(height: 12),
          FormValidationAnchor(
            anchors: _validationAnchors,
            targetId: TenantAdminAccountCreateValidationTargets.name,
            child: FormValidationFieldErrorBuilder(
              validationStreamValue: _controller.createValidationStreamValue,
              fieldId: TenantAdminAccountCreateValidationTargets.name,
              builder: (context, errorText) {
                return TextFormField(
                  controller: _controller.nameController,
                  decoration: InputDecoration(
                    labelText: 'Nome',
                    errorText: errorText,
                  ),
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.name],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationSection(BuildContext context) {
    return FormValidationAnchor(
      anchors: _validationAnchors,
      targetId: TenantAdminAccountCreateValidationTargets.location,
      child: TenantAdminFormSectionCard(
        title: 'Localizacao',
        description:
            'Perfis com POI habilitado precisam de coordenadas para publicação.',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _controller.latitudeController,
              decoration: const InputDecoration(labelText: 'Latitude'),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
                signed: true,
              ),
              inputFormatters: tenantAdminCoordinateInputFormatters,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _controller.longitudeController,
              decoration: const InputDecoration(labelText: 'Longitude'),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
                signed: true,
              ),
              inputFormatters: tenantAdminCoordinateInputFormatters,
              textInputAction: TextInputAction.done,
            ),
            FormValidationGroupError(
              validationStreamValue: _controller.createValidationStreamValue,
              groupId: TenantAdminAccountCreateValidationTargets.location,
              summarySuffixBuilder: _validationSummarySuffix,
              expandLabel: 'Ver todos',
              collapseLabel: 'Ocultar',
            ),
            const SizedBox(height: 8),
            FilledButton.tonalIcon(
              key: const ValueKey('tenant_admin_account_create_map_pick'),
              onPressed: _openMapPicker,
              icon: const Icon(Icons.map_outlined),
              label: const Text('Selecionar no mapa'),
            ),
          ],
        ),
      ),
    );
  }
}
