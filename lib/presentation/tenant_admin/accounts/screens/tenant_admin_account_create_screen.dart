import 'dart:io';

import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_location.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_media_upload.dart';
import 'package:belluga_now/domain/tenant_admin/ownership_state.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_profile_type.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/utils/tenant_admin_form_value_utils.dart';
import 'package:belluga_now/presentation/tenant_admin/accounts/controllers/tenant_admin_accounts_controller.dart';
import 'package:belluga_now/presentation/tenant_admin/accounts/screens/widgets/tenant_admin_document_type_field.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/widgets/tenant_admin_error_banner.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/widgets/tenant_admin_form_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:image_picker/image_picker.dart';
import 'package:stream_value/core/stream_value_builder.dart';

class TenantAdminAccountCreateScreen extends StatefulWidget {
  const TenantAdminAccountCreateScreen({super.key});

  @override
  State<TenantAdminAccountCreateScreen> createState() =>
      _TenantAdminAccountCreateScreenState();
}

class _TenantAdminAccountCreateScreenState
    extends State<TenantAdminAccountCreateScreen> {
  final TenantAdminAccountsController _controller =
      GetIt.I.get<TenantAdminAccountsController>();

  @override
  void initState() {
    super.initState();
    _controller.bindCreateFlow();
    _controller.resetCreateState();
    _controller.resetCreateForm();
    _controller.loadProfileTypes();
  }

  @override
  void dispose() {
    _controller.resetCreateState();
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

  String? _validateLatitude(String? value) {
    final trimmed = value?.trim() ?? '';
    final other = _controller.longitudeController.text.trim();
    final requires = _requiresLocation(
      _controller.createStateStreamValue.value.selectedProfileType,
    );
    if (requires && trimmed.isEmpty && other.isEmpty) {
      return 'Localização é obrigatória para este perfil.';
    }
    if (trimmed.isNotEmpty && tenantAdminParseLatitude(trimmed) == null) {
      return 'Latitude inválida.';
    }
    if (requires && trimmed.isEmpty && other.isNotEmpty) {
      return 'Latitude é obrigatória.';
    }
    return null;
  }

  String? _validateLongitude(String? value) {
    final trimmed = value?.trim() ?? '';
    final other = _controller.latitudeController.text.trim();
    final requires = _requiresLocation(
      _controller.createStateStreamValue.value.selectedProfileType,
    );
    if (trimmed.isNotEmpty && tenantAdminParseLongitude(trimmed) == null) {
      return 'Longitude inválida.';
    }
    if (requires && trimmed.isEmpty && other.isNotEmpty) {
      return 'Longitude é obrigatória.';
    }
    return null;
  }

  Future<void> _openMapPicker() async {
    final currentLocation = _currentLocation();
    context.router.push<TenantAdminLocation?>(
      TenantAdminLocationPickerRoute(
        initialLocation: currentLocation,
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
    return TenantAdminLocation(latitude: lat, longitude: lng);
  }

  Future<void> _pickImage({required bool isAvatar}) async {
    final picker = ImagePicker();
    final selected = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (selected == null) {
      return;
    }
    if (isAvatar) {
      _controller.updateCreateAvatarFile(selected);
    } else {
      _controller.updateCreateCoverFile(selected);
    }
  }

  void _clearImage({required bool isAvatar}) {
    if (isAvatar) {
      _controller.updateCreateAvatarFile(null);
    } else {
      _controller.updateCreateCoverFile(null);
    }
  }

  Future<TenantAdminMediaUpload?> _buildUpload(XFile? file) async {
    if (file == null) return null;
    final bytes = await file.readAsBytes();
    return TenantAdminMediaUpload(
      bytes: bytes,
      fileName: file.name,
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamValueBuilder<String?>(
      streamValue: _controller.createErrorMessageStreamValue,
      builder: (context, errorMessage) {
        _handleCreateErrorMessage(errorMessage);
        return StreamValueBuilder<TenantAdminAccountCreateState>(
          streamValue: _controller.createStateStreamValue,
          builder: (context, state) {
            final requiresLocation =
                _requiresLocation(state.selectedProfileType);
            return TenantAdminFormScaffold(
              title: 'Criar Conta',
              child: SingleChildScrollView(
                child: Form(
                  key: _controller.createFormKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildMediaSection(context, state),
                      const SizedBox(height: 16),
                      _buildAccountSection(context, state),
                      if (requiresLocation) ...[
                        const SizedBox(height: 16),
                        _buildLocationSection(context),
                      ],
                      const SizedBox(height: 24),
                      TenantAdminPrimaryFormAction(
                        buttonKey: const ValueKey(
                          'tenant_admin_account_create_save',
                        ),
                        label: 'Salvar conta',
                        icon: Icons.save_outlined,
                        onPressed: () async {
                          final messenger = ScaffoldMessenger.of(context);
                          final form = _controller.createFormKey.currentState;
                          if (form == null || !form.validate()) {
                            return;
                          }
                          final location = _currentLocation();
                          final avatarUpload =
                              await _buildUpload(state.avatarFile);
                          final coverUpload =
                              await _buildUpload(state.coverFile);
                          final created =
                              await _controller.submitCreateAccountFromForm(
                            location: location,
                            avatarUpload: avatarUpload,
                            coverUpload: coverUpload,
                          );
                          if (!context.mounted || !created) {
                            return;
                          }

                          final router = context.router;
                          final closed = await router.maybePop(true);
                          if (!closed && context.mounted) {
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text('Conta e perfil salvos.'),
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAccountSection(
    BuildContext context,
    TenantAdminAccountCreateState state,
  ) {
    return TenantAdminFormSectionCard(
      title: 'Dados da conta',
      description:
          'Preencha os dados principais da conta e associe um tipo de perfil.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _controller.nameController,
            decoration: const InputDecoration(labelText: 'Nome'),
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.name],
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Nome e obrigatorio.';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          Text(
            'Propriedade da conta',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 8),
          SegmentedButton<TenantAdminOwnershipState>(
            segments: const [
              ButtonSegment<TenantAdminOwnershipState>(
                value: TenantAdminOwnershipState.tenantOwned,
                label: Text('Do tenant'),
              ),
              ButtonSegment<TenantAdminOwnershipState>(
                value: TenantAdminOwnershipState.unmanaged,
                label: Text('Nao gerenciada'),
              ),
            ],
            selected: <TenantAdminOwnershipState>{state.ownershipState},
            onSelectionChanged: (selection) {
              if (selection.isEmpty) {
                return;
              }
              _controller.updateCreateOwnershipState(selection.first);
            },
          ),
          const SizedBox(height: 12),
          TenantAdminDocumentTypeField(
            documentTypeController: _controller.documentTypeController,
          ),
          const SizedBox(height: 12),
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
                          if (error != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: TenantAdminErrorBanner(
                                key: const ValueKey(
                                  'tenant_admin_account_create_profile_types_error',
                                ),
                                rawError: error,
                                fallbackMessage:
                                    'Falha ao carregar tipos de perfil para este tenant.',
                                onRetry: _controller.loadProfileTypes,
                              ),
                            ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            key: ValueKey(state.selectedProfileType),
                            initialValue: state.selectedProfileType,
                            decoration: const InputDecoration(
                              labelText: 'Tipo de perfil',
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
                                        .updateCreateSelectedProfileType(value);
                                    if (!_requiresLocation(value)) {
                                      _controller.latitudeController.clear();
                                      _controller.longitudeController.clear();
                                    }
                                  }
                                : null,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Tipo de perfil e obrigatorio.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton.icon(
                              onPressed: () async {
                                await context.router.push(
                                  const TenantAdminProfileTypeCreateRoute(),
                                );
                                if (!mounted) {
                                  return;
                                }
                                await _controller.loadProfileTypes();
                              },
                              icon: const Icon(Icons.add),
                              label: const Text('Criar tipo de perfil'),
                            ),
                          ),
                          if (!isLoading && error == null && !hasTypes)
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
          TextFormField(
            controller: _controller.profileDisplayNameController,
            decoration: const InputDecoration(labelText: 'Nome de exibicao'),
            textInputAction: TextInputAction.next,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Nome de exibicao e obrigatorio.';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _controller.documentNumberController,
            decoration: const InputDecoration(labelText: 'Numero do documento'),
            textInputAction: TextInputAction.next,
            keyboardType: TextInputType.text,
            autofillHints: const [AutofillHints.creditCardNumber],
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.allow(RegExp(r'[0-9A-Za-z./-]')),
            ],
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Numero do documento e obrigatorio.';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  void _handleCreateErrorMessage(String? message) {
    if (message == null || message.isEmpty) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
      _controller.clearCreateErrorMessage();
    });
  }

  Widget _buildMediaSection(
    BuildContext context,
    TenantAdminAccountCreateState state,
  ) {
    return TenantAdminFormSectionCard(
      title: 'Imagem e identidade visual',
      description:
          'Defina avatar e capa antes dos metadados para validar rapidamente a identidade da conta.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (state.avatarFile != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(36),
                  child: Image.file(
                    File(state.avatarFile!.path),
                    width: 72,
                    height: 72,
                    fit: BoxFit.cover,
                  ),
                )
              else
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(36),
                  ),
                  child: const Icon(Icons.person_outline),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      state.avatarFile?.name ?? 'Nenhuma imagem selecionada',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        FilledButton.tonalIcon(
                          key: const ValueKey(
                            'tenant_admin_account_create_avatar_pick',
                          ),
                          onPressed: () => _pickImage(isAvatar: true),
                          icon: const Icon(Icons.photo_library_outlined),
                          label: const Text('Selecionar'),
                        ),
                        const SizedBox(width: 8),
                        if (state.avatarFile != null)
                          TextButton(
                            key: const ValueKey(
                              'tenant_admin_account_create_avatar_remove',
                            ),
                            onPressed: () => _clearImage(isAvatar: true),
                            child: const Text('Remover'),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (state.coverFile != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                File(state.coverFile!.path),
                width: double.infinity,
                height: 140,
                fit: BoxFit.cover,
              ),
            )
          else
            Container(
              width: double.infinity,
              height: 140,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Icon(Icons.image_outlined),
              ),
            ),
          const SizedBox(height: 8),
          Row(
            children: [
              FilledButton.tonalIcon(
                key: const ValueKey(
                  'tenant_admin_account_create_cover_pick',
                ),
                onPressed: () => _pickImage(isAvatar: false),
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text('Selecionar capa'),
              ),
              const SizedBox(width: 8),
              if (state.coverFile != null)
                TextButton(
                  key: const ValueKey(
                    'tenant_admin_account_create_cover_remove',
                  ),
                  onPressed: () => _clearImage(isAvatar: false),
                  child: const Text('Remover'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLocationSection(BuildContext context) {
    return TenantAdminFormSectionCard(
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
                decimal: true, signed: true),
            inputFormatters: tenantAdminCoordinateInputFormatters,
            textInputAction: TextInputAction.next,
            validator: _validateLatitude,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _controller.longitudeController,
            decoration: const InputDecoration(labelText: 'Longitude'),
            keyboardType: const TextInputType.numberWithOptions(
                decimal: true, signed: true),
            inputFormatters: tenantAdminCoordinateInputFormatters,
            textInputAction: TextInputAction.done,
            validator: _validateLongitude,
          ),
          const SizedBox(height: 8),
          FilledButton.tonalIcon(
            key: const ValueKey(
              'tenant_admin_account_create_map_pick',
            ),
            onPressed: _openMapPicker,
            icon: const Icon(Icons.map_outlined),
            label: const Text('Selecionar no mapa'),
          ),
        ],
      ),
    );
  }
}
