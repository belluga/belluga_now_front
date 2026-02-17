import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_location.dart';
import 'package:belluga_now/domain/tenant_admin/ownership_state.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_profile_type.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_definition.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_term_definition.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/utils/tenant_admin_form_value_utils.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/utils/tenant_admin_image_ingestion_service.dart';
import 'package:belluga_now/presentation/tenant_admin/accounts/controllers/tenant_admin_accounts_controller.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/widgets/tenant_admin_error_banner.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/widgets/tenant_admin_field_edit_sheet.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/widgets/tenant_admin_form_layout.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/widgets/tenant_admin_image_source_sheet.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/widgets/tenant_admin_rich_text_editor.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/widgets/tenant_admin_xfile_preview.dart';
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
  final TenantAdminAccountsController _controller =
      GetIt.I.get<TenantAdminAccountsController>();
  final TenantAdminImageIngestionService _imageIngestionService =
      TenantAdminImageIngestionService();

  @override
  void initState() {
    super.initState();
    _controller.bindCreateFlow();
    _controller.resetCreateState();
    _controller.resetCreateForm();
    _controller.loadProfileTypes();
    _controller.loadTaxonomies();
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

  Future<void> _pickImageFromDevice({required bool isAvatar}) async {
    try {
      final selected = await _imageIngestionService.pickFromDevice(
        slot:
            isAvatar ? TenantAdminImageSlot.avatar : TenantAdminImageSlot.cover,
      );
      if (selected == null) {
        return;
      }
      if (isAvatar) {
        _controller.updateCreateAvatarFile(selected);
      } else {
        _controller.updateCreateCoverFile(selected);
      }
    } on TenantAdminImageIngestionException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    }
  }

  Future<void> _pickImage({required bool isAvatar}) async {
    final source = await showTenantAdminImageSourceSheet(
      context: context,
      title: isAvatar ? 'Adicionar avatar' : 'Adicionar capa',
    );
    if (source == null) {
      return;
    }
    if (source == TenantAdminImageSourceOption.device) {
      await _pickImageFromDevice(isAvatar: isAvatar);
      return;
    }
    final url = await _promptWebImageUrl(
      title: isAvatar ? 'URL do avatar' : 'URL da capa',
    );
    if (url == null || !mounted) {
      return;
    }
    try {
      final selected = await _imageIngestionService.importFromUrl(
        imageUrl: url,
        slot:
            isAvatar ? TenantAdminImageSlot.avatar : TenantAdminImageSlot.cover,
      );
      if (isAvatar) {
        _controller.updateCreateAvatarFile(selected);
      } else {
        _controller.updateCreateCoverFile(selected);
      }
    } on TenantAdminImageIngestionException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    }
  }

  Future<String?> _promptWebImageUrl({required String title}) async {
    final result = await showTenantAdminFieldEditSheet(
      context: context,
      title: title,
      label: 'URL da imagem',
      initialValue: '',
      helperText: 'Use URL completa (http/https).',
      keyboardType: TextInputType.url,
      textCapitalization: TextCapitalization.none,
      autocorrect: false,
      enableSuggestions: false,
      validator: (value) {
        final trimmed = value?.trim() ?? '';
        if (trimmed.isEmpty) {
          return 'URL obrigatoria.';
        }
        final uri = Uri.tryParse(trimmed);
        final hasScheme = uri != null &&
            (uri.scheme == 'http' || uri.scheme == 'https') &&
            uri.host.isNotEmpty;
        if (!hasScheme) {
          return 'URL invalida.';
        }
        return null;
      },
    );
    return result?.value.trim();
  }

  void _clearImage({required bool isAvatar}) {
    if (isAvatar) {
      _controller.updateCreateAvatarFile(null);
      _controller.updateCreateAvatarWebUrl(null);
    } else {
      _controller.updateCreateCoverFile(null);
      _controller.updateCreateCoverWebUrl(null);
    }
  }

  Future<void> _clearWebUrlsFromState() async {
    _controller.updateCreateAvatarWebUrl(null);
    _controller.updateCreateCoverWebUrl(null);
  }

  Future<void> _submitCreate(
    TenantAdminAccountCreateDraft state,
    BuildContext context,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final form = _controller.createFormKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }
    final location = _currentLocation();
    final avatarUpload = await _imageIngestionService.buildUpload(
      state.avatarFile,
      slot: TenantAdminImageSlot.avatar,
    );
    final coverUpload = await _imageIngestionService.buildUpload(
      state.coverFile,
      slot: TenantAdminImageSlot.cover,
    );
    await _clearWebUrlsFromState();
    final created = await _controller.submitCreateAccountFromForm(
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
  }

  @override
  Widget build(BuildContext context) {
    return StreamValueBuilder<String?>(
      streamValue: _controller.createErrorMessageStreamValue,
      builder: (context, errorMessage) {
        _handleCreateErrorMessage(errorMessage);
        return StreamValueBuilder<TenantAdminAccountCreateDraft>(
          streamValue: _controller.createStateStreamValue,
          builder: (context, state) {
            final requiresLocation =
                _requiresLocation(state.selectedProfileType);
            final definition =
                _profileTypeDefinition(state.selectedProfileType);
            final hasBio = definition?.capabilities.hasBio ?? false;
            final hasContent = definition?.capabilities.hasContent ?? false;
            final hasTaxonomies =
                definition?.capabilities.hasTaxonomies ?? false;
            final showAvatar = definition?.capabilities.hasAvatar ?? false;
            final showCover = definition?.capabilities.hasCover ?? false;
            final showMediaSection = showAvatar || showCover;
            return TenantAdminFormScaffold(
              title: 'Criar Conta',
              child: SingleChildScrollView(
                child: Form(
                  key: _controller.createFormKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildOwnershipSection(state),
                      const SizedBox(height: 16),
                      _buildAccountSection(context, state),
                      if (showMediaSection) ...[
                        const SizedBox(height: 16),
                        _buildMediaSection(
                          context,
                          state,
                          showAvatar: showAvatar,
                          showCover: showCover,
                        ),
                      ],
                      if (hasBio || hasContent || hasTaxonomies) ...[
                        const SizedBox(height: 16),
                        _buildProfileContentSection(
                          context,
                          state,
                          hasBio: hasBio,
                          hasContent: hasContent,
                          hasTaxonomies: hasTaxonomies,
                        ),
                      ],
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
                            onPressed: () => _submitCreate(state, context),
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
                                    final definition =
                                        _profileTypeDefinition(value);
                                    _controller
                                        .updateCreateSelectedProfileType(value);
                                    if (!_requiresLocation(value)) {
                                      _controller.latitudeController.clear();
                                      _controller.longitudeController.clear();
                                    }
                                    if (!(definition?.capabilities.hasAvatar ??
                                        false)) {
                                      _controller.updateCreateAvatarFile(null);
                                    }
                                    if (!(definition?.capabilities.hasCover ??
                                        false)) {
                                      _controller.updateCreateCoverFile(null);
                                    }
                                    if (!(definition?.capabilities.hasBio ??
                                        false)) {
                                      _controller.bioController.clear();
                                    }
                                    if (!(definition?.capabilities.hasContent ??
                                        false)) {
                                      _controller.contentController.clear();
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
        ],
      ),
    );
  }

  Widget _buildOwnershipSection(TenantAdminAccountCreateDraft state) {
    return TenantAdminFormSectionCard(
      title: 'Propriedade da conta',
      description: 'Defina a vinculação da conta ao tenant.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
    TenantAdminAccountCreateDraft state, {
    required bool showAvatar,
    required bool showCover,
  }) {
    return TenantAdminFormSectionCard(
      title: 'Imagem e identidade visual',
      description:
          'Campos exibidos conforme capabilities do tipo de perfil selecionado.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showAvatar) ...[
            Row(
              children: [
                if (state.avatarFile != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(36),
                    child: TenantAdminXFilePreview(
                      file: state.avatarFile!,
                      width: 72,
                      height: 72,
                      fit: BoxFit.cover,
                    ),
                  )
                else if (state.avatarWebUrl != null &&
                    state.avatarWebUrl!.isNotEmpty)
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(36),
                    ),
                    child: const Icon(Icons.link_outlined),
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
                        state.avatarFile?.name ??
                            state.avatarWebUrl ??
                            'Nenhuma imagem selecionada',
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
                            icon:
                                const Icon(Icons.add_photo_alternate_outlined),
                            label: const Text('Adicionar avatar'),
                          ),
                          const SizedBox(width: 8),
                          if (state.avatarFile != null ||
                              (state.avatarWebUrl != null &&
                                  state.avatarWebUrl!.isNotEmpty))
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
          ],
          if (showAvatar && showCover) const SizedBox(height: 16),
          if (showCover) ...[
            if (state.coverFile != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: TenantAdminXFilePreview(
                  file: state.coverFile!,
                  width: double.infinity,
                  height: 140,
                  fit: BoxFit.cover,
                ),
              )
            else if (state.coverWebUrl != null && state.coverWebUrl!.isNotEmpty)
              Container(
                width: double.infinity,
                height: 140,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Icon(Icons.link_outlined),
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
                  icon: const Icon(Icons.add_photo_alternate_outlined),
                  label: const Text('Adicionar capa'),
                ),
                const SizedBox(width: 8),
                if (state.coverFile != null ||
                    (state.coverWebUrl != null &&
                        state.coverWebUrl!.isNotEmpty))
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
        ],
      ),
    );
  }

  Widget _buildProfileContentSection(
    BuildContext context,
    TenantAdminAccountCreateDraft state, {
    required bool hasBio,
    required bool hasContent,
    required bool hasTaxonomies,
  }) {
    final allowedTaxonomies = _allowedTaxonomyDefinitions(
      state.selectedProfileType,
    );
    return TenantAdminFormSectionCard(
      title: 'Conteudo do perfil',
      description:
          'Campos exibidos conforme capabilities do tipo de perfil selecionado.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasBio) ...[
            TenantAdminRichTextEditor(
              controller: _controller.bioController,
              label: 'Bio',
              placeholder: 'Escreva a bio do perfil',
              minHeight: 160,
            ),
          ],
          if (hasContent) ...[
            if (hasBio) const SizedBox(height: 16),
            TenantAdminRichTextEditor(
              controller: _controller.contentController,
              label: 'Conteudo',
              placeholder: 'Escreva o conteudo estendido do perfil',
              minHeight: 220,
            ),
          ],
          if (hasTaxonomies) ...[
            if (hasBio || hasContent) const SizedBox(height: 16),
            _buildTaxonomySection(allowedTaxonomies),
          ],
        ],
      ),
    );
  }

  List<TenantAdminTaxonomyDefinition> _allowedTaxonomyDefinitions(
    String? profileType,
  ) {
    final definition = _profileTypeDefinition(profileType);
    final allowed = (definition?.allowedTaxonomies ?? const []).toSet();
    return _controller.taxonomiesStreamValue.value
        .where((taxonomy) => allowed.contains(taxonomy.slug))
        .toList(growable: false);
  }

  Widget _buildTaxonomySection(
    List<TenantAdminTaxonomyDefinition> allowedTaxonomies,
  ) {
    return StreamValueBuilder<bool>(
      streamValue: _controller.taxonomiesLoadingStreamValue,
      builder: (context, isLoading) {
        return StreamValueBuilder<String?>(
          streamValue: _controller.taxonomiesErrorStreamValue,
          builder: (context, error) {
            return StreamValueBuilder<
                Map<String, List<TenantAdminTaxonomyTermDefinition>>>(
              streamValue: _controller.taxonomyTermsStreamValue,
              builder: (context, termsByTaxonomy) {
                return StreamValueBuilder<Map<String, Set<String>>>(
                  streamValue: _controller.selectedTaxonomyTermsStreamValue,
                  builder: (context, selected) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Taxonomias',
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                        const SizedBox(height: 8),
                        if (isLoading) const LinearProgressIndicator(),
                        if (error != null && error.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: TenantAdminErrorBanner(
                              rawError: error,
                              fallbackMessage:
                                  'Nao foi possivel carregar taxonomias.',
                              onRetry: _controller.loadTaxonomies,
                            ),
                          ),
                        if (allowedTaxonomies.isEmpty && !isLoading)
                          const Padding(
                            padding: EdgeInsets.only(top: 8),
                            child: Text(
                                'Nenhuma taxonomia permitida para este tipo.'),
                          ),
                        for (final taxonomy in allowedTaxonomies) ...[
                          const SizedBox(height: 12),
                          Text(taxonomy.name),
                          const SizedBox(height: 6),
                          _buildTaxonomyChips(
                            taxonomySlug: taxonomy.slug,
                            terms: termsByTaxonomy[taxonomy.slug] ?? const [],
                            selected: selected[taxonomy.slug] ?? const {},
                          ),
                        ],
                      ],
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildTaxonomyChips({
    required String taxonomySlug,
    required List<TenantAdminTaxonomyTermDefinition> terms,
    required Set<String> selected,
  }) {
    if (terms.isEmpty) {
      return const Text('Sem termos cadastrados.');
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: terms
          .map(
            (term) => FilterChip(
              label: Text(term.name),
              selected: selected.contains(term.slug),
              onSelected: (enabled) {
                _controller.updateTaxonomySelection(
                  taxonomySlug: taxonomySlug,
                  termSlug: term.slug,
                  selected: enabled,
                );
              },
            ),
          )
          .toList(growable: false),
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
