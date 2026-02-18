import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_location.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_profile_type.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_definition.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_term.dart';
import 'package:belluga_now/presentation/tenant_admin/account_profiles/controllers/tenant_admin_account_profiles_controller.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/utils/tenant_admin_form_value_utils.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/utils/tenant_admin_image_ingestion_service.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/widgets/tenant_admin_error_banner.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/widgets/tenant_admin_field_edit_sheet.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/widgets/tenant_admin_form_layout.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/widgets/tenant_admin_image_crop_sheet.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/widgets/tenant_admin_image_source_sheet.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/widgets/tenant_admin_rich_text_editor.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/widgets/tenant_admin_xfile_preview.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
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
  final TenantAdminImageIngestionService _imageIngestionService =
      GetIt.I.get<TenantAdminImageIngestionService>();
  bool _routeParamNormalized = false;

  @override
  void initState() {
    super.initState();
    _controller.bindCreateFlow();
    _controller.resetCreateState();
    _controller.resetFormControllers();
    _controller.loadProfileTypes();
    _controller.loadTaxonomies();
    _controller.loadAccountForCreate(_currentAccountSlugForRequests());
  }

  bool _isResolvedSlug(String? value) {
    if (value == null) {
      return false;
    }
    final trimmed = value.trim();
    return trimmed.isNotEmpty && !trimmed.startsWith(':');
  }

  String _currentAccountSlugForRequests() {
    final routeSlug = widget.accountSlug;
    if (_isResolvedSlug(routeSlug)) {
      return routeSlug.trim();
    }

    final cached = _controller.accountStreamValue.value?.slug;
    if (_isResolvedSlug(cached)) {
      return cached!.trim();
    }

    return routeSlug;
  }

  bool _requiresPathNormalization() {
    return kIsWeb && context.router.currentPath.contains('/:');
  }

  void _normalizeRouteParamIfNeeded() {
    if (_routeParamNormalized || !mounted) {
      return;
    }
    final needsPathNormalization = _requiresPathNormalization();
    if (!needsPathNormalization && _isResolvedSlug(widget.accountSlug)) {
      _routeParamNormalized = true;
      return;
    }
    final resolved = _isResolvedSlug(widget.accountSlug)
        ? widget.accountSlug
        : _controller.accountStreamValue.value?.slug;
    if (!_isResolvedSlug(resolved)) {
      return;
    }
    _routeParamNormalized = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      context.router.replace(
        TenantAdminAccountProfileCreateRoute(accountSlug: resolved!.trim()),
      );
    });
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

  bool _hasContent(String? selectedType) {
    final definition = _profileTypeDefinition(selectedType);
    return definition?.capabilities.hasContent ?? false;
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
    if (!_hasContent(selectedType)) {
      _controller.contentController.clear();
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
    final slot =
        isAvatar ? TenantAdminImageSlot.avatar : TenantAdminImageSlot.cover;
    if (isAvatar && _controller.createStateStreamValue.value.avatarBusy) {
      return;
    }
    if (!isAvatar && _controller.createStateStreamValue.value.coverBusy) {
      return;
    }
    try {
      if (isAvatar) {
        _controller.updateCreateAvatarBusy(true);
      } else {
        _controller.updateCreateCoverBusy(true);
      }
      final picked = await _imageIngestionService.pickFromDevice(slot: slot);
      if (picked == null) {
        return;
      }
      if (!mounted) {
        return;
      }
      final cropped = await showTenantAdminImageCropSheet(
        context: context,
        sourceFile: picked,
        slot: slot,
        ingestionService: _imageIngestionService,
      );
      if (cropped == null) {
        return;
      }
      if (isAvatar) {
        _controller.updateCreateAvatarFile(cropped);
      } else {
        _controller.updateCreateCoverFile(cropped);
      }
    } on TenantAdminImageIngestionException catch (error) {
      _controller.reportCreateErrorMessage(error.message);
    } finally {
      if (isAvatar) {
        _controller.updateCreateAvatarBusy(false);
      } else {
        _controller.updateCreateCoverBusy(false);
      }
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
    await _pickImageFromWeb(isAvatar: isAvatar);
  }

  Future<void> _pickImageFromWeb({required bool isAvatar}) async {
    final slot =
        isAvatar ? TenantAdminImageSlot.avatar : TenantAdminImageSlot.cover;
    if (isAvatar && _controller.createStateStreamValue.value.avatarBusy) {
      return;
    }
    if (!isAvatar && _controller.createStateStreamValue.value.coverBusy) {
      return;
    }
    final url = await _promptWebImageUrl(
      title: isAvatar ? 'URL do avatar' : 'URL da capa',
    );
    if (url == null || !mounted) {
      return;
    }
    try {
      if (isAvatar) {
        _controller.updateCreateAvatarBusy(true);
      } else {
        _controller.updateCreateCoverBusy(true);
      }
      final sourceFile = await _imageIngestionService.fetchFromUrlForCrop(
        imageUrl: url,
      );
      if (!mounted) return;
      final cropped = await showTenantAdminImageCropSheet(
        context: context,
        sourceFile: sourceFile,
        slot: slot,
        ingestionService: _imageIngestionService,
      );
      if (cropped == null) return;
      if (isAvatar) {
        _controller.updateCreateAvatarFile(cropped);
      } else {
        _controller.updateCreateCoverFile(cropped);
      }
    } on TenantAdminImageIngestionException catch (error) {
      _controller.reportCreateErrorMessage(error.message);
    } finally {
      if (isAvatar) {
        _controller.updateCreateAvatarBusy(false);
      } else {
        _controller.updateCreateCoverBusy(false);
      }
    }
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
        ? await _imageIngestionService.buildUpload(
            state.avatarFile,
            slot: TenantAdminImageSlot.avatar,
          )
        : null;
    final coverUpload = _hasCover(state.selectedProfileType)
        ? await _imageIngestionService.buildUpload(
            state.coverFile,
            slot: TenantAdminImageSlot.cover,
          )
        : null;
    _controller.submitCreateProfile(
      accountId: accountId,
      profileType: selectedType,
      displayName: _controller.displayNameController.text.trim(),
      location: location,
      bio: _hasBio(state.selectedProfileType)
          ? _controller.bioController.text.trim()
          : null,
      content: _hasContent(state.selectedProfileType)
          ? _controller.contentController.text.trim()
          : null,
      taxonomyTerms: _buildTaxonomyTerms(state.selectedProfileType),
      avatarUpload: avatarUpload,
      coverUpload: coverUpload,
      avatarUrl: null,
      coverUrl: null,
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
            return StreamValueBuilder<TenantAdminAccountProfileCreateDraft>(
              streamValue: _controller.createStateStreamValue,
              builder: (context, state) {
                _normalizeRouteParamIfNeeded();
                final requiresLocation =
                    _requiresLocation(state.selectedProfileType);
                final hasMedia = _hasAvatar(state.selectedProfileType) ||
                    _hasCover(state.selectedProfileType);
                final hasContent = _hasBio(state.selectedProfileType) ||
                    _hasContent(state.selectedProfileType) ||
                    _hasTaxonomies(state.selectedProfileType);
                final accountSlugForUi = _currentAccountSlugForRequests();
                return TenantAdminFormScaffold(
                  title: 'Criar Perfil - $accountSlugForUi',
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
    TenantAdminAccountProfileCreateDraft state,
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
            controller: _controller.displayNameController,
            decoration: const InputDecoration(labelText: 'Nome de exibicao'),
            textInputAction: TextInputAction.next,
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
    TenantAdminAccountProfileCreateDraft state,
  ) {
    final hasBio = _hasBio(state.selectedProfileType);
    final hasContent = _hasContent(state.selectedProfileType);
    final allowedDefinitions = _allowedTaxonomyDefinitions(
      state.selectedProfileType,
    );
    return TenantAdminFormSectionCard(
      title: 'Conteudo do perfil',
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
            if (hasBio) const SizedBox(height: 12),
            TenantAdminRichTextEditor(
              controller: _controller.contentController,
              label: 'Conteudo',
              placeholder: 'Escreva o conteudo estendido do perfil',
              minHeight: 220,
            ),
          ],
          if (_hasTaxonomies(state.selectedProfileType)) ...[
            if (hasBio || hasContent) const SizedBox(height: 12),
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
    TenantAdminAccountProfileCreateDraft state,
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
                      if (state.avatarBusy) ...[
                        const SizedBox(height: 8),
                        const LinearProgressIndicator(),
                      ],
                      Row(
                        children: [
                          FilledButton.tonalIcon(
                            onPressed: state.avatarBusy
                                ? null
                                : () => _pickImage(isAvatar: true),
                            icon:
                                const Icon(Icons.add_photo_alternate_outlined),
                            label: const Text('Adicionar avatar'),
                          ),
                          const SizedBox(width: 8),
                          if (state.avatarFile != null ||
                              (state.avatarWebUrl != null &&
                                  state.avatarWebUrl!.isNotEmpty))
                            TextButton(
                              onPressed: state.avatarBusy
                                  ? null
                                  : () => _clearImage(isAvatar: true),
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
            if (state.coverBusy) ...[
              const LinearProgressIndicator(),
              const SizedBox(height: 8),
            ],
            Row(
              children: [
                FilledButton.tonalIcon(
                  onPressed:
                      state.coverBusy ? null : () => _pickImage(isAvatar: false),
                  icon: const Icon(Icons.add_photo_alternate_outlined),
                  label: const Text('Adicionar capa'),
                ),
                const SizedBox(width: 8),
                if (state.coverFile != null ||
                    (state.coverWebUrl != null &&
                        state.coverWebUrl!.isNotEmpty))
                  TextButton(
                    onPressed:
                        state.coverBusy ? null : () => _clearImage(isAvatar: false),
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
            onPressed: _openMapPicker,
            icon: const Icon(Icons.map_outlined),
            label: const Text('Selecionar no mapa'),
          ),
        ],
      ),
    );
  }
}
