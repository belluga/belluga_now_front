import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/rich_text/tenant_admin_rich_text_limits.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/application/router/support/tenant_admin_safe_back.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_location.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_static_profile_type.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_definition.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_term_definition.dart';
import 'package:belluga_now/presentation/shared/widgets/belluga_network_image.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/utils/tenant_admin_form_value_utils.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/utils/tenant_admin_image_ingestion_service.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/widgets/tenant_admin_error_banner.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/widgets/tenant_admin_field_edit_sheet.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/widgets/tenant_admin_form_layout.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/widgets/tenant_admin_image_crop_sheet.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/widgets/tenant_admin_image_upload_field.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/widgets/tenant_admin_image_source_sheet.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/widgets/tenant_admin_rich_text_editor.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/widgets/tenant_admin_xfile_preview.dart';
import 'package:belluga_now/presentation/tenant_admin/static_assets/controllers/tenant_admin_static_assets_controller.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:image_picker/image_picker.dart' show XFile;
import 'package:stream_value/core/stream_value_builder.dart';

class TenantAdminStaticAssetCreateScreen extends StatefulWidget {
  const TenantAdminStaticAssetCreateScreen({super.key});

  @override
  State<TenantAdminStaticAssetCreateScreen> createState() =>
      _TenantAdminStaticAssetCreateScreenState();
}

class _TenantAdminStaticAssetCreateScreenState
    extends State<TenantAdminStaticAssetCreateScreen> {
  final TenantAdminStaticAssetsController _controller =
      GetIt.I.get<TenantAdminStaticAssetsController>();

  @override
  void initState() {
    super.initState();
    _controller.initCreate();
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
                      closePolicy:
                          buildTenantAdminCurrentRouteBackPolicy(context),
                      title: 'Criar ativo',
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
      _controller.clearAvatarSelection();
    }
    if (!(definition?.capabilities.hasCover ?? false)) {
      _controller.clearCoverSelection();
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
        backFallbackRoute: const TenantAdminStaticAssetCreateRoute(),
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
      performTenantAdminCurrentRouteBack(context);
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

  Future<void> _pickImageFromDevice({required bool isAvatar}) async {
    final slot =
        isAvatar ? TenantAdminImageSlot.avatar : TenantAdminImageSlot.cover;
    if (isAvatar && _controller.avatarBusyStreamValue.value) return;
    if (!isAvatar && _controller.coverBusyStreamValue.value) return;
    try {
      if (isAvatar) {
        _controller.updateAvatarBusy(true);
      } else {
        _controller.updateCoverBusy(true);
      }
      final picked = await _controller.pickImageFromDevice(slot: slot);
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
        readBytesForCrop: _controller.readImageBytesForCrop,
        prepareCroppedFile: (croppedData, cropSlot) =>
            _controller.prepareCroppedImage(
          croppedData,
          slot: cropSlot,
        ),
      );
      if (cropped == null) {
        return;
      }
      if (isAvatar) {
        _controller.updateAvatarFile(cropped);
      } else {
        _controller.updateCoverFile(cropped);
      }
    } on TenantAdminImageIngestionException catch (error) {
      _controller.submitErrorStreamValue.addValue(error.message);
    } finally {
      if (isAvatar) {
        _controller.updateAvatarBusy(false);
      } else {
        _controller.updateCoverBusy(false);
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
    if (isAvatar && _controller.avatarBusyStreamValue.value) {
      return;
    }
    if (!isAvatar && _controller.coverBusyStreamValue.value) {
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
        _controller.updateAvatarBusy(true);
      } else {
        _controller.updateCoverBusy(true);
      }
      final sourceFile = await _controller.fetchImageFromUrlForCrop(
        imageUrl: url,
      );
      if (!mounted) return;
      final cropped = await showTenantAdminImageCropSheet(
        context: context,
        sourceFile: sourceFile,
        slot: slot,
        readBytesForCrop: _controller.readImageBytesForCrop,
        prepareCroppedFile: (croppedData, cropSlot) =>
            _controller.prepareCroppedImage(
          croppedData,
          slot: cropSlot,
        ),
      );
      if (cropped == null) return;
      if (isAvatar) {
        _controller.updateAvatarFile(cropped);
      } else {
        _controller.updateCoverFile(cropped);
      }
    } on TenantAdminImageIngestionException catch (error) {
      _controller.submitErrorStreamValue.addValue(error.message);
    } finally {
      if (isAvatar) {
        _controller.updateAvatarBusy(false);
      } else {
        _controller.updateCoverBusy(false);
      }
    }
  }

  void _clearImage({required bool isAvatar}) {
    if (isAvatar) {
      _controller.clearAvatarSelection();
      return;
    }
    _controller.clearCoverSelection();
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
                            onPressed: () {
                              context.router
                                  .push(
                                const TenantAdminStaticProfileTypeCreateRoute(),
                              )
                                  .then((_) {
                                if (!mounted) {
                                  return;
                                }
                                _controller.loadProfileTypes();
                              });
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
                placeholder: 'Escreva a bio do ativo',
                minHeight: 150,
                maxContentBytes: tenantAdminRichTextMaxBytes,
                warningThreshold: tenantAdminRichTextWarningThreshold,
              ),
            ],
            if (hasContent) ...[
              const SizedBox(height: 12),
              TenantAdminRichTextEditor(
                controller: _controller.contentController,
                label: 'Conteudo',
                placeholder: 'Escreva o conteudo detalhado do ativo',
                minHeight: 220,
                maxContentBytes: tenantAdminRichTextMaxBytes,
                warningThreshold: tenantAdminRichTextWarningThreshold,
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
    return StreamValueBuilder<bool>(
      streamValue: _controller.avatarBusyStreamValue,
      builder: (context, avatarBusy) {
        return StreamValueBuilder<bool>(
          streamValue: _controller.coverBusyStreamValue,
          builder: (context, coverBusy) {
            return StreamValueBuilder<XFile?>(
              streamValue: _controller.avatarFileStreamValue,
              builder: (context, avatarFile) {
                return StreamValueBuilder<XFile?>(
                  streamValue: _controller.coverFileStreamValue,
                  builder: (context, coverFile) {
                    final avatarUrl =
                        _controller.avatarUrlController.text.trim();
                    final coverUrl = _controller.coverUrlController.text.trim();
                    final hasLocalAvatar = switch (avatarFile) {
                      final _? => true,
                      null => false,
                    };
                    final hasLocalCover = switch (coverFile) {
                      final _? => true,
                      null => false,
                    };
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
                              TenantAdminImageUploadField(
                                variant: TenantAdminImageUploadVariant.avatar,
                                preview: switch (avatarFile) {
                                  final file? => ClipRRect(
                                      borderRadius: BorderRadius.circular(36),
                                      child: TenantAdminXFilePreview(
                                        file: file,
                                        width: 72,
                                        height: 72,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  null => avatarUrl.isNotEmpty
                                      ? BellugaNetworkImage(
                                          avatarUrl,
                                          width: 72,
                                          height: 72,
                                          fit: BoxFit.cover,
                                          clipBorderRadius:
                                              BorderRadius.circular(36),
                                          placeholder: Container(
                                            width: 72,
                                            height: 72,
                                            decoration: BoxDecoration(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .surfaceContainerHighest,
                                              borderRadius:
                                                  BorderRadius.circular(36),
                                            ),
                                            child: const Icon(
                                                Icons.person_outline),
                                          ),
                                        )
                                      : Container(
                                          width: 72,
                                          height: 72,
                                          decoration: BoxDecoration(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .surfaceContainerHighest,
                                            borderRadius:
                                                BorderRadius.circular(36),
                                          ),
                                          child:
                                              const Icon(Icons.person_outline),
                                        ),
                                },
                                selectedLabel: avatarFile?.name ??
                                    (avatarUrl.isNotEmpty
                                        ? avatarUrl
                                        : 'Nenhuma imagem selecionada'),
                                addLabel: 'Adicionar avatar',
                                onAdd: () => _pickImage(isAvatar: true),
                                busy: avatarBusy,
                                canRemove:
                                    hasLocalAvatar || avatarUrl.isNotEmpty,
                                onRemove: () => _clearImage(isAvatar: true),
                              ),
                            ],
                            if (hasAvatar && hasCover)
                              const SizedBox(height: 16),
                            if (hasCover) ...[
                              TenantAdminImageUploadField(
                                variant: TenantAdminImageUploadVariant.cover,
                                preview: switch (coverFile) {
                                  final file? => ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: TenantAdminXFilePreview(
                                        file: file,
                                        width: double.infinity,
                                        height: 140,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  null => coverUrl.isNotEmpty
                                      ? BellugaNetworkImage(
                                          coverUrl,
                                          width: double.infinity,
                                          height: 140,
                                          fit: BoxFit.cover,
                                          clipBorderRadius:
                                              BorderRadius.circular(12),
                                        )
                                      : Container(
                                          width: double.infinity,
                                          height: 140,
                                          decoration: BoxDecoration(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .surfaceContainerHighest,
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: const Center(
                                            child: Icon(Icons.image_outlined),
                                          ),
                                        ),
                                },
                                selectedLabel: coverFile?.name ??
                                    (coverUrl.isNotEmpty
                                        ? coverUrl
                                        : 'Nenhuma imagem selecionada'),
                                addLabel: 'Adicionar capa',
                                onAdd: () => _pickImage(isAvatar: false),
                                busy: coverBusy,
                                canRemove: hasLocalCover || coverUrl.isNotEmpty,
                                onRemove: () => _clearImage(isAvatar: false),
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
                                if (isLoading) const LinearProgressIndicator(),
                                if (taxonomyError?.isNotEmpty ?? false)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: Text(
                                      taxonomyError ?? '',
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
            onPressed: isLoading ? null : _controller.submitCreate,
            child: Text(isLoading ? 'Salvando...' : 'Salvar ativo'),
          ),
        );
      },
    );
  }
}
