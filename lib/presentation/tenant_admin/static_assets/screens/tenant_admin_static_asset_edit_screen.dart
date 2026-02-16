import 'dart:io';

import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_location.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_static_asset.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_static_profile_type.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_definition.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_term_definition.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/utils/tenant_admin_form_value_utils.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/widgets/tenant_admin_confirmation_dialog.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/widgets/tenant_admin_error_banner.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/widgets/tenant_admin_field_edit_sheet.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/widgets/tenant_admin_form_layout.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/widgets/tenant_admin_image_source_sheet.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/widgets/tenant_admin_rich_text_editor.dart';
import 'package:belluga_now/presentation/tenant_admin/static_assets/controllers/tenant_admin_static_assets_controller.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:image_picker/image_picker.dart';
import 'package:stream_value/core/stream_value_builder.dart';

class TenantAdminStaticAssetEditScreen extends StatefulWidget {
  const TenantAdminStaticAssetEditScreen({
    super.key,
    required this.assetId,
  });

  final String assetId;

  @override
  State<TenantAdminStaticAssetEditScreen> createState() =>
      _TenantAdminStaticAssetEditScreenState();
}

class _TenantAdminStaticAssetEditScreenState
    extends State<TenantAdminStaticAssetEditScreen> {
  final TenantAdminStaticAssetsController _controller =
      GetIt.I.get<TenantAdminStaticAssetsController>();

  @override
  void initState() {
    super.initState();
    _controller.initEdit(widget.assetId);
  }

  @override
  void dispose() {
    _controller.clearSubmitMessages();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamValueBuilder<String?>(
      streamValue: _controller.submitSuccessStreamValue,
      builder: (context, submitSuccessMessage) {
        _handleSubmitSuccess(submitSuccessMessage);
        return StreamValueBuilder<String?>(
          streamValue: _controller.submitErrorStreamValue,
          builder: (context, submitErrorMessage) {
            _handleSubmitError(submitErrorMessage);
            return StreamValueBuilder<String?>(
              streamValue: _controller.errorStreamValue,
              builder: (context, error) {
                return StreamValueBuilder<String?>(
                  streamValue: _controller.selectedProfileTypeStreamValue,
                  builder: (context, selectedType) {
                    final selectedDefinition =
                        _profileTypeDefinition(selectedType);
                    final requiresLocation =
                        selectedDefinition?.capabilities.isPoiEnabled ?? false;
                    final hasBio =
                        selectedDefinition?.capabilities.hasBio ?? false;
                    final hasContent =
                        selectedDefinition?.capabilities.hasContent ?? false;
                    final hasTaxonomies =
                        selectedDefinition?.capabilities.hasTaxonomies ?? false;
                    final hasAvatar =
                        selectedDefinition?.capabilities.hasAvatar ?? false;
                    final hasCover =
                        selectedDefinition?.capabilities.hasCover ?? false;
                    return TenantAdminFormScaffold(
                      title: 'Editar ativo',
                      child: Form(
                        key: _controller.formKey,
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildBasicSection(context, error),
                              const SizedBox(height: 16),
                              if (hasAvatar || hasCover) ...[
                                const SizedBox(height: 16),
                                _buildMediaSection(
                                  hasAvatar: hasAvatar,
                                  hasCover: hasCover,
                                ),
                              ],
                              if (hasBio || hasContent) ...[
                                const SizedBox(height: 16),
                                _buildContentSection(
                                  context,
                                  hasBio: hasBio,
                                  hasContent: hasContent,
                                ),
                              ],
                              if (hasTaxonomies) ...[
                                const SizedBox(height: 16),
                                _buildTaxonomySection(context),
                              ],
                              if (requiresLocation) ...[
                                const SizedBox(height: 16),
                                _buildLocationSection(context),
                              ],
                              const SizedBox(height: 24),
                              _buildSubmitButton(),
                              const SizedBox(height: 12),
                              _buildDeleteButton(),
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
      },
    );
  }

  TenantAdminStaticProfileTypeDefinition? _profileTypeDefinition(
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

  void _clearCapabilityFields(String? selectedType) {
    final definition = _profileTypeDefinition(selectedType);
    if (!(definition?.capabilities.hasBio ?? false)) {
      _controller.bioController.clear();
    }
    if (!(definition?.capabilities.hasContent ?? false)) {
      _controller.contentController.clear();
    }
    if (!(definition?.capabilities.hasTaxonomies ?? false)) {
      _controller.selectedTaxonomyTermsStreamValue.addValue(const {});
    }
    if (!(definition?.capabilities.hasAvatar ?? false)) {
      _controller.updateAvatarFile(null);
      _controller.updateAvatarWebUrl(null);
    }
    if (!(definition?.capabilities.hasCover ?? false)) {
      _controller.updateCoverFile(null);
      _controller.updateCoverWebUrl(null);
    }
    if (!(definition?.capabilities.isPoiEnabled ?? false)) {
      _controller.latitudeController.clear();
      _controller.longitudeController.clear();
    }
  }

  Map<String, String> _taxonomyLabels(
    List<TenantAdminTaxonomyDefinition> taxonomies,
  ) {
    return {
      for (final taxonomy in taxonomies) taxonomy.slug: taxonomy.name,
    };
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

  String? _validateLatitude(String? value) {
    final trimmed = value?.trim() ?? '';
    final other = _controller.longitudeController.text.trim();
    if (_controller.requiresLocation() && trimmed.isEmpty && other.isEmpty) {
      return 'Localizacao obrigatoria.';
    }
    if (trimmed.isNotEmpty && tenantAdminParseLatitude(trimmed) == null) {
      return 'Latitude invalida.';
    }
    if (_controller.requiresLocation() && trimmed.isEmpty && other.isNotEmpty) {
      return 'Latitude obrigatoria.';
    }
    return null;
  }

  String? _validateLongitude(String? value) {
    final trimmed = value?.trim() ?? '';
    final other = _controller.latitudeController.text.trim();
    if (trimmed.isNotEmpty && tenantAdminParseLongitude(trimmed) == null) {
      return 'Longitude invalida.';
    }
    if (_controller.requiresLocation() && trimmed.isEmpty && other.isNotEmpty) {
      return 'Longitude obrigatoria.';
    }
    return null;
  }

  void _handleSubmitSuccess(String? message) {
    if (message == null || message.isEmpty) return;
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _controller.clearSubmitMessages();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    });
  }

  void _handleSubmitError(String? message) {
    if (message == null || message.isEmpty) return;
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _controller.clearSubmitMessages();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    });
  }

  Future<void> _editSlug(String currentSlug) async {
    final result = await showTenantAdminFieldEditSheet(
      context: context,
      title: 'Editar slug do ativo',
      label: 'Slug',
      initialValue: currentSlug,
      helperText: 'Deve ser unico no tenant.',
      inputFormatters: tenantAdminSlugInputFormatters,
      validator: (value) => tenantAdminValidateRequiredSlug(
        value,
        requiredMessage: 'Slug e obrigatorio.',
      ),
    );
    if (result == null || !mounted) {
      return;
    }
    final trimmed = result.value.trim();
    if (trimmed.isEmpty || trimmed == currentSlug) {
      return;
    }
    await _controller.submitSlugUpdate(
      assetId: widget.assetId,
      slug: trimmed,
    );
  }

  Map<String, Set<String>> _cloneTaxonomySelection(
    Map<String, Set<String>> source,
  ) {
    final next = <String, Set<String>>{};
    for (final entry in source.entries) {
      next[entry.key] = Set<String>.from(entry.value);
    }
    return next;
  }

  Future<void> _toggleTaxonomyWithAutoSave({
    required String taxonomySlug,
    required String termSlug,
    required bool selected,
  }) async {
    final previous = _cloneTaxonomySelection(
      _controller.selectedTaxonomyTermsStreamValue.value,
    );
    _controller.updateTaxonomySelection(
      taxonomySlug: taxonomySlug,
      termSlug: termSlug,
      selected: selected,
    );
    final saved = await _controller.submitTaxonomySelectionUpdate(
      assetId: widget.assetId,
    );
    if (!saved) {
      _controller.selectedTaxonomyTermsStreamValue.addValue(previous);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Nao foi possivel salvar a taxonomia. Alteracao desfeita.'),
        ),
      );
    }
  }

  Future<void> _pickImageFromDevice({required bool isAvatar}) async {
    final picker = ImagePicker();
    final selected = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (selected == null) {
      return;
    }
    if (isAvatar) {
      _controller.updateAvatarFile(selected);
    } else {
      _controller.updateCoverFile(selected);
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
    final url = await _promptWebImageUrl(
      title: isAvatar ? 'URL do avatar' : 'URL da capa',
    );
    if (url == null || !mounted) {
      return;
    }
    if (isAvatar) {
      _controller.updateAvatarWebUrl(url);
    } else {
      _controller.updateCoverWebUrl(url);
    }
  }

  void _clearImage({required bool isAvatar}) {
    if (isAvatar) {
      _controller.updateAvatarFile(null);
      _controller.updateAvatarWebUrl(null);
      return;
    }
    _controller.updateCoverFile(null);
    _controller.updateCoverWebUrl(null);
  }

  Widget _buildBasicSection(BuildContext context, String? error) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dados basicos',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            StreamValueBuilder<bool>(
              streamValue: _controller.isLoadingStreamValue,
              builder: (context, isLoading) {
                return StreamValueBuilder<
                    List<TenantAdminStaticProfileTypeDefinition>>(
                  streamValue: _controller.profileTypesStreamValue,
                  builder: (context, profileTypes) {
                    final hasTypes = profileTypes.isNotEmpty;
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
                                  'Não foi possível carregar os tipos de ativo.',
                              onRetry: _controller.loadProfileTypes,
                            ),
                          ),
                        const SizedBox(height: 8),
                        StreamValueBuilder<String?>(
                          streamValue:
                              _controller.selectedProfileTypeStreamValue,
                          builder: (context, selectedType) {
                            return DropdownButtonFormField<String>(
                              key: ValueKey(selectedType),
                              initialValue: selectedType,
                              decoration: const InputDecoration(
                                labelText: 'Tipo de ativo',
                              ),
                              items: profileTypes
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
                                          .updateSelectedProfileType(value);
                                      _clearCapabilityFields(value);
                                    }
                                  : null,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Tipo de ativo e obrigatorio.';
                                }
                                return null;
                              },
                            );
                          },
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            onPressed: () async {
                              await context.router.push(
                                const TenantAdminStaticProfileTypeCreateRoute(),
                              );
                              if (!mounted) {
                                return;
                              }
                              await _controller.loadProfileTypes();
                            },
                            icon: const Icon(Icons.add),
                            label: const Text('Criar tipo de ativo'),
                          ),
                        ),
                        if (!isLoading && error == null && !hasTypes)
                          const Padding(
                            padding: EdgeInsets.only(top: 8),
                            child: Text(
                              'Nenhum tipo de ativo disponivel.',
                            ),
                          ),
                      ],
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _controller.displayNameController,
              decoration: const InputDecoration(labelText: 'Nome de exibicao'),
              keyboardType: TextInputType.name,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Nome e obrigatorio.';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            StreamValueBuilder<TenantAdminStaticAsset?>(
              streamValue: _controller.editingAssetStreamValue,
              builder: (context, asset) {
                final slug = asset?.slug ?? '-';
                return Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Slug: $slug',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    IconButton(
                      onPressed:
                          asset == null ? null : () => _editSlug(asset.slug),
                      tooltip: 'Editar slug',
                      icon: const Icon(Icons.edit_outlined),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContentSection(
    BuildContext context, {
    required bool hasBio,
    required bool hasContent,
  }) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Conteudo',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (hasBio) ...[
              const SizedBox(height: 12),
              TenantAdminRichTextEditor(
                controller: _controller.bioController,
                label: 'Bio',
                placeholder: 'Edite a bio do ativo',
                minHeight: 150,
              ),
            ],
            if (hasContent) ...[
              const SizedBox(height: 12),
              TenantAdminRichTextEditor(
                controller: _controller.contentController,
                label: 'Conteudo',
                placeholder: 'Edite o conteudo detalhado do ativo',
                minHeight: 220,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMediaSection({
    required bool hasAvatar,
    required bool hasCover,
  }) {
    return StreamValueBuilder<XFile?>(
      streamValue: _controller.avatarFileStreamValue,
      builder: (context, avatarFile) {
        return StreamValueBuilder<XFile?>(
          streamValue: _controller.coverFileStreamValue,
          builder: (context, coverFile) {
            final avatarUrl = _controller.avatarUrlController.text.trim();
            final coverUrl = _controller.coverUrlController.text.trim();
            return Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Midia',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    if (hasAvatar) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          if (avatarFile != null)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(36),
                              child: Image.file(
                                File(avatarFile.path),
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
                                color: Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(36),
                              ),
                              child: Icon(
                                avatarUrl.isNotEmpty
                                    ? Icons.link_outlined
                                    : Icons.person_outline,
                              ),
                            ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  avatarFile?.name ??
                                      (avatarUrl.isNotEmpty
                                          ? avatarUrl
                                          : 'Nenhuma imagem selecionada'),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    FilledButton.tonalIcon(
                                      onPressed: () =>
                                          _pickImage(isAvatar: true),
                                      icon: const Icon(
                                        Icons.add_photo_alternate_outlined,
                                      ),
                                      label: const Text('Adicionar avatar'),
                                    ),
                                    const SizedBox(width: 8),
                                    if (avatarFile != null ||
                                        avatarUrl.isNotEmpty)
                                      TextButton(
                                        onPressed: () =>
                                            _clearImage(isAvatar: true),
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
                      if (coverFile != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            File(coverFile.path),
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
                            color: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Icon(
                              coverUrl.isNotEmpty
                                  ? Icons.link_outlined
                                  : Icons.image_outlined,
                            ),
                          ),
                        ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          FilledButton.tonalIcon(
                            onPressed: () => _pickImage(isAvatar: false),
                            icon:
                                const Icon(Icons.add_photo_alternate_outlined),
                            label: const Text('Adicionar capa'),
                          ),
                          const SizedBox(width: 8),
                          if (coverFile != null || coverUrl.isNotEmpty)
                            TextButton(
                              onPressed: () => _clearImage(isAvatar: false),
                              child: const Text('Remover'),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTaxonomySection(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: StreamValueBuilder<bool>(
          streamValue: _controller.taxonomyLoadingStreamValue,
          builder: (context, isLoading) {
            return StreamValueBuilder<String?>(
              streamValue: _controller.taxonomyErrorStreamValue,
              builder: (context, taxonomyError) {
                return StreamValueBuilder<List<TenantAdminTaxonomyDefinition>>(
                  streamValue: _controller.taxonomiesStreamValue,
                  builder: (context, taxonomies) {
                    return StreamValueBuilder<
                        Map<String, List<TenantAdminTaxonomyTermDefinition>>>(
                      streamValue: _controller.taxonomyTermsStreamValue,
                      builder: (context, termsByTaxonomy) {
                        return StreamValueBuilder<Map<String, Set<String>>>(
                          streamValue:
                              _controller.selectedTaxonomyTermsStreamValue,
                          builder: (context, selectedTerms) {
                            final labels = _taxonomyLabels(taxonomies);
                            final allowed = _controller
                                .selectedProfileTypeStreamValue.value;
                            final allowedTaxonomies =
                                _profileTypeDefinition(allowed)
                                        ?.allowedTaxonomies ??
                                    const [];
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Taxonomias',
                                  style:
                                      Theme.of(context).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 12),
                                StreamValueBuilder<bool>(
                                  streamValue:
                                      _controller.taxonomyAutosavingStreamValue,
                                  builder: (context, isTaxonomyAutosaving) {
                                    if (!isTaxonomyAutosaving) {
                                      return const SizedBox.shrink();
                                    }
                                    return const Padding(
                                      padding: EdgeInsets.only(bottom: 8),
                                      child:
                                          LinearProgressIndicator(minHeight: 2),
                                    );
                                  },
                                ),
                                if (isLoading) const LinearProgressIndicator(),
                                if (taxonomyError != null)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: Text(
                                      taxonomyError,
                                      style: TextStyle(
                                        color:
                                            Theme.of(context).colorScheme.error,
                                      ),
                                    ),
                                  ),
                                for (final taxonomy in allowedTaxonomies) ...[
                                  Text(
                                    labels[taxonomy] ?? taxonomy,
                                    style:
                                        Theme.of(context).textTheme.labelLarge,
                                  ),
                                  const SizedBox(height: 6),
                                  _buildTaxonomyChips(
                                    taxonomySlug: taxonomy,
                                    terms:
                                        termsByTaxonomy[taxonomy] ?? const [],
                                    selected:
                                        selectedTerms[taxonomy] ?? const {},
                                  ),
                                  const SizedBox(height: 12),
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
          },
        ),
      ),
    );
  }

  Widget _buildTaxonomyChips({
    required String taxonomySlug,
    required List<TenantAdminTaxonomyTermDefinition> terms,
    required Set<String> selected,
  }) {
    if (terms.isEmpty) {
      return const Text('Nenhum termo cadastrado.');
    }
    return Wrap(
      spacing: 8,
      children: terms
          .map(
            (term) => FilterChip(
              label: Text(term.name),
              selected: selected.contains(term.slug),
              onSelected: (enabled) {
                _toggleTaxonomyWithAutoSave(
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
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Localizacao',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
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
      ),
    );
  }

  Widget _buildSubmitButton() {
    return StreamValueBuilder<bool>(
      streamValue: _controller.submitLoadingStreamValue,
      builder: (context, isLoading) {
        return SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: isLoading
                ? null
                : () => _controller.submitUpdate(widget.assetId),
            child: Text(isLoading ? 'Salvando...' : 'Salvar ativo'),
          ),
        );
      },
    );
  }

  Widget _buildDeleteButton() {
    return StreamValueBuilder<TenantAdminStaticAsset?>(
      streamValue: _controller.editingAssetStreamValue,
      builder: (context, asset) {
        return SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: asset == null ? null : () => _confirmDelete(asset),
            icon: const Icon(Icons.delete_outline),
            label: const Text('Remover ativo'),
          ),
        );
      },
    );
  }

  Future<void> _confirmDelete(TenantAdminStaticAsset asset) async {
    final confirmed = await showTenantAdminConfirmationDialog(
      context: context,
      title: 'Remover ativo',
      message: 'Remover "${asset.displayName}"?',
      confirmLabel: 'Remover',
      isDestructive: true,
    );
    if (!confirmed) return;
    await _controller.deleteAsset(asset.id);
    if (!mounted) return;
    context.router.maybePop();
  }
}
