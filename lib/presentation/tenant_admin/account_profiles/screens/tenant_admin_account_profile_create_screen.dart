import 'dart:io';

import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_location.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_media_upload.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_profile_type.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_definition.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_term.dart';
import 'package:belluga_now/presentation/tenant_admin/account_profiles/controllers/tenant_admin_account_profiles_controller.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/widgets/tenant_admin_error_banner.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/widgets/tenant_admin_form_layout.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:image_picker/image_picker.dart';
import 'package:stream_value/core/stream_value_builder.dart';

class TenantAdminAccountProfileCreateScreen extends StatefulWidget {
  const TenantAdminAccountProfileCreateScreen({
    super.key,
    required this.accountSlug,
  });

  final String accountSlug;

  @override
  State<TenantAdminAccountProfileCreateScreen> createState() =>
      _TenantAdminAccountProfileCreateScreenState();
}

class _TenantAdminAccountProfileCreateScreenState
    extends State<TenantAdminAccountProfileCreateScreen> {
  final TenantAdminAccountProfilesController _controller =
      GetIt.I.get<TenantAdminAccountProfilesController>();

  @override
  void initState() {
    super.initState();
    _controller.bindCreateFlow();
    _controller.resetCreateState();
    _controller.resetFormControllers();
    _controller.loadProfileTypes();
    _controller.loadTaxonomies();
    _controller.loadAccountForCreate(widget.accountSlug);
  }

  @override
  void dispose() {
    _controller.resetFormControllers();
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

  bool _hasBio(String? selectedType) {
    final definition = _profileTypeDefinition(selectedType);
    return definition?.capabilities.hasBio ?? false;
  }

  bool _hasTaxonomies(String? selectedType) {
    final definition = _profileTypeDefinition(selectedType);
    return definition?.capabilities.hasTaxonomies ?? false;
  }

  bool _hasAvatar(String? selectedType) {
    final definition = _profileTypeDefinition(selectedType);
    return definition?.capabilities.hasAvatar ?? false;
  }

  bool _hasCover(String? selectedType) {
    final definition = _profileTypeDefinition(selectedType);
    return definition?.capabilities.hasCover ?? false;
  }

  List<String> _allowedTaxonomies(String? selectedType) {
    final definition = _profileTypeDefinition(selectedType);
    return definition?.allowedTaxonomies ?? const [];
  }

  List<TenantAdminTaxonomyDefinition> _allowedTaxonomyDefinitions(
    String? selectedType,
  ) {
    final allowed = _allowedTaxonomies(selectedType).toSet();
    return _controller.taxonomiesStreamValue.value
        .where((taxonomy) =>
            taxonomy.appliesToTarget('account_profile') &&
            allowed.contains(taxonomy.slug))
        .toList(growable: false);
  }

  void _syncTaxonomySelection(List<TenantAdminTaxonomyDefinition> allowed) {
    final slugs = allowed.map((taxonomy) => taxonomy.slug).toList();
    _controller.ensureTaxonomySelectionKeys(slugs);
    _controller.loadTermsForTaxonomies(slugs);
  }

  void _clearCapabilityFields(String? selectedType) {
    if (!_hasBio(selectedType)) {
      _controller.bioController.clear();
    }
    if (!_hasTaxonomies(selectedType)) {
      _controller.resetTaxonomySelection();
    }
    if (!_hasAvatar(selectedType)) {
      _controller.updateCreateAvatarFile(null);
    }
    if (!_hasCover(selectedType)) {
      _controller.updateCreateCoverFile(null);
    }
    if (!_requiresLocation(selectedType)) {
      _controller.latitudeController.clear();
      _controller.longitudeController.clear();
    }
  }

  List<TenantAdminTaxonomyTerm> _buildTaxonomyTerms(String? selectedType) {
    if (!_hasTaxonomies(selectedType)) {
      return const [];
    }
    final terms = <TenantAdminTaxonomyTerm>[];
    final selections = _controller.taxonomySelectionStreamValue.value;
    for (final entry in selections.entries) {
      for (final value in entry.value) {
        terms.add(TenantAdminTaxonomyTerm(type: entry.key, value: value));
      }
    }
    return terms;
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
    if (trimmed.isNotEmpty && double.tryParse(trimmed) == null) {
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
    if (trimmed.isNotEmpty && double.tryParse(trimmed) == null) {
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
    final lat = double.tryParse(latText);
    final lng = double.tryParse(lngText);
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
    final lowerName = selected.name.toLowerCase();
    const allowed = ['.jpg', '.jpeg', '.png', '.webp'];
    if (!allowed.any(lowerName.endsWith)) {
      _controller.reportCreateErrorMessage(
        'Formato de imagem invalido. Use JPG, PNG ou WEBP.',
      );
      return;
    }
    final size = await selected.length();
    const maxBytes = 5 * 1024 * 1024;
    if (size > maxBytes) {
      _controller.reportCreateErrorMessage(
        'Imagem muito grande. Maximo 5MB.',
      );
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

  Future<void> _submit() async {
    final form = _controller.createFormKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }
    final accountId = _controller.createAccountIdStreamValue.value;
    if (accountId == null) {
      _controller.reportCreateErrorMessage('Conta inválida.');
      return;
    }
    final state = _controller.createStateStreamValue.value;
    final selectedType = state.selectedProfileType ?? '';
    final location = _requiresLocation(state.selectedProfileType)
        ? _currentLocation()
        : null;
    final avatarUpload = _hasAvatar(state.selectedProfileType)
        ? await _buildUpload(state.avatarFile)
        : null;
    final coverUpload = _hasCover(state.selectedProfileType)
        ? await _buildUpload(state.coverFile)
        : null;
    _controller.submitCreateProfile(
      accountId: accountId,
      profileType: selectedType,
      displayName: _controller.displayNameController.text.trim(),
      location: location,
      bio: _hasBio(state.selectedProfileType)
          ? _controller.bioController.text.trim()
          : null,
      taxonomyTerms: _buildTaxonomyTerms(state.selectedProfileType),
      avatarUpload: avatarUpload,
      coverUpload: coverUpload,
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamValueBuilder<String?>(
      streamValue: _controller.createSuccessMessageStreamValue,
      builder: (context, successMessage) {
        _handleCreateSuccessMessage(successMessage);
        return StreamValueBuilder<String?>(
          streamValue: _controller.createErrorMessageStreamValue,
          builder: (context, errorMessage) {
            _handleCreateErrorMessage(errorMessage);
            return StreamValueBuilder<TenantAdminAccountProfileCreateState>(
              streamValue: _controller.createStateStreamValue,
              builder: (context, state) {
                final requiresLocation =
                    _requiresLocation(state.selectedProfileType);
                final hasMedia = _hasAvatar(state.selectedProfileType) ||
                    _hasCover(state.selectedProfileType);
                final hasContent = _hasBio(state.selectedProfileType) ||
                    _hasTaxonomies(state.selectedProfileType);
                return TenantAdminFormScaffold(
                  title: 'Criar Perfil - ${widget.accountSlug}',
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => context.router.maybePop(),
                    tooltip: 'Voltar',
                  ),
                  child: SingleChildScrollView(
                    child: Form(
                      key: _controller.createFormKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildProfileSection(context, state),
                          if (hasMedia) ...[
                            const SizedBox(height: 16),
                            _buildMediaSection(context, state),
                          ],
                          if (hasContent) ...[
                            const SizedBox(height: 16),
                            _buildContentSection(context, state),
                          ],
                          if (requiresLocation) ...[
                            const SizedBox(height: 16),
                            _buildLocationSection(context),
                          ],
                          const SizedBox(height: 24),
                          TenantAdminPrimaryFormAction(
                            label: 'Salvar perfil',
                            icon: Icons.save_outlined,
                            onPressed: _submit,
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
      },
    );
  }

  void _handleCreateSuccessMessage(String? message) {
    if (message == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.clearCreateSuccessMessage();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
      context.router.maybePop();
    });
  }

  void _handleCreateErrorMessage(String? message) {
    if (message == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.clearCreateErrorMessage();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    });
  }

  Widget _buildProfileSection(
    BuildContext context,
    TenantAdminAccountProfileCreateState state,
  ) {
    return TenantAdminFormSectionCard(
      title: 'Dados do perfil',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StreamValueBuilder<bool>(
            streamValue: _controller.isLoadingStreamValue,
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
                                rawError: error,
                                fallbackMessage:
                                    'Não foi possível carregar os tipos de perfil.',
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
                                    _syncTaxonomySelection(
                                      _allowedTaxonomyDefinitions(value),
                                    );
                                    _clearCapabilityFields(value);
                                  }
                                : null,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Tipo de perfil e obrigatorio.';
                              }
                              return null;
                            },
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
            controller: _controller.displayNameController,
            decoration: const InputDecoration(labelText: 'Nome de exibicao'),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Nome de exibicao e obrigatorio.';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildContentSection(
    BuildContext context,
    TenantAdminAccountProfileCreateState state,
  ) {
    final hasBio = _hasBio(state.selectedProfileType);
    final allowedDefinitions = _allowedTaxonomyDefinitions(
      state.selectedProfileType,
    );
    return TenantAdminFormSectionCard(
      title: 'Conteudo do perfil',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasBio) ...[
            TextFormField(
              controller: _controller.bioController,
              decoration: const InputDecoration(labelText: 'Bio'),
              maxLines: 4,
              minLines: 2,
            ),
          ],
          if (_hasTaxonomies(state.selectedProfileType)) ...[
            if (hasBio) const SizedBox(height: 12),
            Text(
              'Taxonomias',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 8),
            StreamValueBuilder(
              streamValue: _controller.taxonomySelectionStreamValue,
              builder: (context, selections) {
                return StreamValueBuilder(
                  streamValue: _controller.taxonomyTermsStreamValue,
                  builder: (context, termsByTaxonomy) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final taxonomy in allowedDefinitions)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(taxonomy.name),
                                const SizedBox(height: 8),
                                if ((termsByTaxonomy[taxonomy.slug] ?? const [])
                                    .isEmpty)
                                  const Text(
                                    'Sem termos cadastrados.',
                                  )
                                else
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: (termsByTaxonomy[taxonomy.slug] ??
                                            const [])
                                        .map(
                                          (term) => FilterChip(
                                            label: Text(term.name),
                                            selected: selections[taxonomy.slug]
                                                    ?.contains(term.slug) ??
                                                false,
                                            onSelected: (selected) {
                                              _controller
                                                  .updateTaxonomySelection(
                                                taxonomySlug: taxonomy.slug,
                                                termSlug: term.slug,
                                                selected: selected,
                                              );
                                            },
                                          ),
                                        )
                                        .toList(growable: false),
                                  ),
                              ],
                            ),
                          ),
                      ],
                    );
                  },
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMediaSection(
    BuildContext context,
    TenantAdminAccountProfileCreateState state,
  ) {
    final hasAvatar = _hasAvatar(state.selectedProfileType);
    final hasCover = _hasCover(state.selectedProfileType);
    return TenantAdminFormSectionCard(
      title: 'Imagens do perfil',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasAvatar) ...[
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
                      Row(
                        children: [
                          FilledButton.tonalIcon(
                            onPressed: () => _pickImage(isAvatar: true),
                            icon: const Icon(Icons.photo_library_outlined),
                            label: const Text('Selecionar'),
                          ),
                          const SizedBox(width: 8),
                          if (state.avatarFile != null)
                            TextButton(
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
          ],
          if (hasAvatar && hasCover) const SizedBox(height: 16),
          if (hasCover) ...[
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
                  onPressed: () => _pickImage(isAvatar: false),
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('Selecionar capa'),
                ),
                const SizedBox(width: 8),
                if (state.coverFile != null)
                  TextButton(
                    onPressed: () => _clearImage(isAvatar: false),
                    child: const Text('Remover'),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLocationSection(BuildContext context) {
    return TenantAdminFormSectionCard(
      title: 'Localizacao',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _controller.latitudeController,
            decoration: const InputDecoration(labelText: 'Latitude'),
            keyboardType: TextInputType.number,
            validator: _validateLatitude,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _controller.longitudeController,
            decoration: const InputDecoration(labelText: 'Longitude'),
            keyboardType: TextInputType.number,
            validator: _validateLongitude,
          ),
          const SizedBox(height: 8),
          FilledButton.tonalIcon(
            onPressed: _openMapPicker,
            icon: const Icon(Icons.map_outlined),
            label: const Text('Selecionar no mapa'),
          ),
        ],
      ),
    );
  }
}
