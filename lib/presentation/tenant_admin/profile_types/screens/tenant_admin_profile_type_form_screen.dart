import 'package:belluga_now/application/router/support/tenant_admin_safe_back.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_poi_visual.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_profile_type.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_definition.dart';
import 'package:belluga_now/presentation/shared/widgets/belluga_network_image.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/utils/tenant_admin_form_value_utils.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/utils/tenant_admin_image_ingestion_service.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/utils/tenant_admin_poi_disable_confirmation.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/utils/tenant_admin_slug_utils.dart';
import 'package:belluga_now/presentation/tenant_admin/profile_types/controllers/tenant_admin_profile_types_controller.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/widgets/tenant_admin_canonical_image_upload_field.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/widgets/tenant_admin_color_picker_field.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/widgets/tenant_admin_error_banner.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/widgets/tenant_admin_form_layout.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/widgets/tenant_admin_image_upload_field.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/widgets/tenant_admin_map_marker_icon_picker_field.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/widgets/tenant_admin_xfile_preview.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:image_picker/image_picker.dart' show XFile;
import 'package:stream_value/core/stream_value_builder.dart';

class TenantAdminProfileTypeFormScreen extends StatefulWidget {
  const TenantAdminProfileTypeFormScreen({super.key, this.definition});

  final TenantAdminProfileTypeDefinition? definition;

  @override
  State<TenantAdminProfileTypeFormScreen> createState() =>
      _TenantAdminProfileTypeFormScreenState();
}

class _TenantAdminProfileTypeFormScreenState
    extends State<TenantAdminProfileTypeFormScreen> {
  final TenantAdminProfileTypesController _controller = GetIt.I
      .get<TenantAdminProfileTypesController>();

  bool get _isEdit => widget.definition != null;

  @override
  void initState() {
    super.initState();
    _controller.initForm(widget.definition);
    _controller.loadAvailableTaxonomies();
    if (!_isEdit) {
      _controller.labelController.addListener(_syncSlugFromLabel);
      _syncSlugFromLabel();
    }
  }

  @override
  void dispose() {
    if (!_isEdit) {
      _controller.labelController.removeListener(_syncSlugFromLabel);
    }
    _controller.resetFormState();
    super.dispose();
  }

  void _syncSlugFromLabel() {
    if (!_controller.isSlugAutoEnabled || _isEdit) {
      return;
    }
    final generated = tenantAdminSlugify(_controller.labelController.text);
    if (_controller.typeController.text == generated) {
      return;
    }
    _controller.typeController.value = _controller.typeController.value
        .copyWith(
          text: generated,
          selection: TextSelection.collapsed(offset: generated.length),
          composing: TextRange.empty,
        );
  }

  Future<void> _save() async {
    final messenger = ScaffoldMessenger.of(context);
    final form = _controller.formKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }

    final capabilities = _controller.currentCapabilities;
    final allowedTaxonomies = _controller.selectedAllowedTaxonomies;
    final visual = _controller.buildCurrentVisual();
    if (visual == null) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Configuração visual do tipo inválida. Revise modo, ícone/cor ou fonte de imagem.',
          ),
        ),
      );
      return;
    }

    final requiresTypeAsset =
        visual.mode == TenantAdminPoiVisualMode.image &&
        visual.imageSource == TenantAdminPoiVisualImageSource.typeAsset;
    final typeAssetUpload = requiresTypeAsset
        ? await _controller.buildTypeAssetUpload()
        : null;
    if (requiresTypeAsset &&
        typeAssetUpload == null &&
        _controller.currentTypeAssetUrl == null) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Envie uma imagem canônica do tipo ou escolha Avatar/Capa como fonte.',
          ),
        ),
      );
      return;
    }

    if (_isEdit) {
      final confirmed = await _confirmDisablePoiIfNeeded(
        nextPoiEnabled: capabilities.isPoiEnabled,
      );
      if (!confirmed) {
        return;
      }
      _controller.submitUpdateType(
        type: widget.definition!.type,
        newType: _controller.typeController.text.trim(),
        label: _controller.labelController.text.trim(),
        allowedTaxonomies: allowedTaxonomies,
        capabilities: capabilities,
        visual: visual,
        typeAssetUpload: typeAssetUpload,
        removeTypeAsset: _controller.isTypeAssetMarkedForRemoval,
        includeVisual: true,
      );
      return;
    }

    _controller.submitCreateType(
      type: _controller.typeController.text.trim(),
      label: _controller.labelController.text.trim(),
      allowedTaxonomies: allowedTaxonomies,
      capabilities: capabilities,
      visual: visual,
      typeAssetUpload: typeAssetUpload,
      includeVisual: true,
    );
  }

  Future<bool> _confirmDisablePoiIfNeeded({
    required bool nextPoiEnabled,
  }) async {
    if (!_isEdit) {
      return true;
    }
    final currentDefinition = widget.definition!;
    final wasPoiEnabled = currentDefinition.capabilities.isPoiEnabled;
    if (!wasPoiEnabled || nextPoiEnabled) {
      return true;
    }

    final typeLabel = currentDefinition.label.trim().isNotEmpty
        ? currentDefinition.label.trim()
        : currentDefinition.type;
    final typeValue = currentDefinition.type;
    return tenantAdminConfirmDisablePoiProjection(
      context: context,
      shouldConfirm: true,
      typeLabel: typeLabel,
      loadProjectionCount: () {
        return _controller.previewDisableProjectionCount(typeValue);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamValueBuilder<String?>(
      streamValue: _controller.successMessageStreamValue,
      builder: (context, successMessage) {
        _handleSuccessMessage(successMessage);
        return StreamValueBuilder<String?>(
          streamValue: _controller.actionErrorMessageStreamValue,
          builder: (context, errorMessage) {
            _handleErrorMessage(errorMessage);
            return TenantAdminFormScaffold(
              closePolicy: buildTenantAdminCurrentRouteBackPolicy(context),
              title: _isEdit ? 'Editar Tipo' : 'Criar Tipo',
              child: SingleChildScrollView(
                child: Form(
                  key: _controller.formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TenantAdminFormSectionCard(
                        title: 'Informacoes do tipo',
                        description:
                            'Defina nome exibido, identificador e taxonomias associadas.',
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _controller.labelController,
                              decoration: const InputDecoration(
                                labelText: 'Label',
                              ),
                              keyboardType: TextInputType.name,
                              textCapitalization: TextCapitalization.words,
                              onChanged: (_) => _syncSlugFromLabel(),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Label e obrigatorio.';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _controller.typeController,
                              decoration: const InputDecoration(
                                labelText: 'Tipo (slug)',
                              ),
                              keyboardType: TextInputType.visiblePassword,
                              textCapitalization: TextCapitalization.none,
                              autocorrect: false,
                              enableSuggestions: false,
                              inputFormatters: tenantAdminSlugInputFormatters,
                              onChanged: (value) {
                                if (_isEdit) {
                                  return;
                                }
                                final generated = tenantAdminSlugify(
                                  _controller.labelController.text,
                                );
                                if (_controller.isSlugAutoEnabled &&
                                    value != generated) {
                                  _controller.setSlugAutoEnabled(false);
                                }
                              },
                              validator: (value) {
                                return tenantAdminValidateRequiredSlug(
                                  value,
                                  requiredMessage: 'Tipo e obrigatorio.',
                                  invalidMessage:
                                      'Tipo invalido. Use letras minusculas, numeros, - ou _.',
                                );
                              },
                            ),
                            const SizedBox(height: 12),
                            _buildTaxonomySelection(),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      TenantAdminFormSectionCard(
                        title: 'Capacidades',
                        description:
                            'Ative os recursos que o perfil deve disponibilizar.',
                        child: StreamValueBuilder<TenantAdminProfileTypeCapabilities>(
                          streamValue: _controller.capabilitiesStreamValue,
                          builder: (context, capabilities) {
                            return Column(
                              children: [
                                SwitchListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: const Text('Favoritavel'),
                                  value: capabilities.isFavoritable,
                                  onChanged: (value) => _controller
                                      .updateCapabilities(isFavoritable: value),
                                ),
                                SwitchListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: const Text('POI habilitado'),
                                  subtitle: const Text(
                                    'Requer localizacao no perfil',
                                  ),
                                  value: capabilities.isPoiEnabled,
                                  onChanged: (value) => _controller
                                      .updateCapabilities(isPoiEnabled: value),
                                ),
                                SwitchListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: const Text(
                                    'Referencia fixa habilitada',
                                  ),
                                  subtitle: Text(
                                    capabilities.isPoiEnabled
                                        ? 'Permite usar perfis deste tipo como referencia fixa do usuario.'
                                        : 'Requer POI habilitado.',
                                  ),
                                  value:
                                      capabilities.isReferenceLocationEnabled,
                                  onChanged: capabilities.isPoiEnabled
                                      ? (value) =>
                                            _controller.updateCapabilities(
                                              isReferenceLocationEnabled: value,
                                            )
                                      : null,
                                ),
                                const SizedBox(height: 12),
                                _buildPoiVisualEditor(context),
                                const SizedBox(height: 8),
                                SwitchListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: const Text('Bio habilitada'),
                                  subtitle: const Text(
                                    'Exibe campo de descricao no perfil',
                                  ),
                                  value: capabilities.hasBio,
                                  onChanged: (value) => _controller
                                      .updateCapabilities(hasBio: value),
                                ),
                                SwitchListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: const Text('Conteudo habilitado'),
                                  subtitle: const Text(
                                    'Exibe campo de conteudo estendido no perfil',
                                  ),
                                  value: capabilities.hasContent,
                                  onChanged: (value) => _controller
                                      .updateCapabilities(hasContent: value),
                                ),
                                SwitchListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: const Text('Avatar habilitado'),
                                  value: capabilities.hasAvatar,
                                  onChanged: (value) => _controller
                                      .updateCapabilities(hasAvatar: value),
                                ),
                                SwitchListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: const Text('Capa habilitada'),
                                  value: capabilities.hasCover,
                                  onChanged: (value) => _controller
                                      .updateCapabilities(hasCover: value),
                                ),
                                SwitchListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: const Text('Agenda habilitada'),
                                  subtitle: const Text(
                                    'Mostra "Proximos Eventos"',
                                  ),
                                  value: capabilities.hasEvents,
                                  onChanged: (value) => _controller
                                      .updateCapabilities(hasEvents: value),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 24),
                      TenantAdminPrimaryFormAction(
                        label: _isEdit ? 'Salvar alteracoes' : 'Criar tipo',
                        icon: _isEdit ? Icons.save_outlined : Icons.add,
                        onPressed: _save,
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

  Widget _buildPoiVisualEditor(BuildContext context) {
    return StreamValueBuilder<TenantAdminPoiVisualMode>(
      streamValue: _controller.poiVisualModeStreamValue,
      builder: (context, mode) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Visual do tipo',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<TenantAdminPoiVisualMode>(
              initialValue: mode,
              decoration: const InputDecoration(labelText: 'Modo visual'),
              items: TenantAdminPoiVisualMode.values
                  .map(
                    (item) =>
                        DropdownMenuItem(value: item, child: Text(item.label)),
                  )
                  .toList(growable: false),
              onChanged: (value) {
                if (value == null) {
                  return;
                }
                _controller.updatePoiVisualMode(value);
              },
            ),
            if (mode == TenantAdminPoiVisualMode.icon) ...[
              const SizedBox(height: 12),
              TenantAdminMapMarkerIconPickerField(
                controller: _controller.poiVisualIconController,
                labelText: 'Ícone',
              ),
              const SizedBox(height: 12),
              TenantAdminColorPickerField(
                controller: _controller.poiVisualColorController,
                labelText: 'Cor do marcador',
              ),
              const SizedBox(height: 12),
              TenantAdminColorPickerField(
                controller: _controller.poiVisualIconColorController,
                labelText: 'Cor do ícone',
              ),
            ] else ...[
              const SizedBox(height: 12),
              StreamValueBuilder<TenantAdminPoiVisualImageSource>(
                streamValue: _controller.poiVisualImageSourceStreamValue,
                builder: (context, imageSource) {
                  return Column(
                    children: [
                      DropdownButtonFormField<TenantAdminPoiVisualImageSource>(
                        initialValue: imageSource,
                        decoration: const InputDecoration(
                          labelText: 'Fonte da imagem',
                        ),
                        items: TenantAdminPoiVisualImageSource.values
                            .map(
                              (item) => DropdownMenuItem(
                                value: item,
                                child: Text(item.label),
                              ),
                            )
                            .toList(growable: false),
                        onChanged: (value) {
                          if (value == null) {
                            return;
                          }
                          _controller.updatePoiVisualImageSource(value);
                        },
                      ),
                      if (imageSource ==
                          TenantAdminPoiVisualImageSource.typeAsset) ...[
                        const SizedBox(height: 12),
                        _buildTypeAssetUploadField(context),
                      ],
                    ],
                  );
                },
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildTaxonomySelection() {
    return StreamValueBuilder<bool>(
      streamValue: _controller.isTaxonomiesLoadingStreamValue,
      builder: (context, isLoading) {
        return StreamValueBuilder<String?>(
          streamValue: _controller.taxonomiesErrorStreamValue,
          builder: (context, error) {
            return StreamValueBuilder<List<TenantAdminTaxonomyDefinition>>(
              streamValue: _controller.availableTaxonomiesStreamValue,
              builder: (context, availableTaxonomies) {
                return StreamValueBuilder<List<String>>(
                  streamValue: _controller.selectedAllowedTaxonomiesStreamValue,
                  builder: (context, selectedTaxonomies) {
                    final selectedSet = selectedTaxonomies.toSet();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (isLoading) const LinearProgressIndicator(),
                        if (error?.isNotEmpty ?? false)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: TenantAdminErrorBanner(
                              rawError: error ?? '',
                              fallbackMessage:
                                  'Nao foi possivel carregar taxonomias.',
                              onRetry: _controller.loadAvailableTaxonomies,
                            ),
                          ),
                        const SizedBox(height: 8),
                        Text(
                          'Taxonomias permitidas',
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                        const SizedBox(height: 8),
                        if (availableTaxonomies.isEmpty && !isLoading)
                          Text(
                            'Nenhuma taxonomia aplicavel a perfis encontrada.',
                            style: Theme.of(context).textTheme.bodySmall,
                          )
                        else
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: availableTaxonomies
                                .map(
                                  (taxonomy) => FilterChip(
                                    label: Text(
                                      '${taxonomy.name} (${taxonomy.slug})',
                                    ),
                                    selected: selectedSet.contains(
                                      taxonomy.slug,
                                    ),
                                    onSelected: (_) => _controller
                                        .toggleAllowedTaxonomy(taxonomy.slug),
                                  ),
                                )
                                .toList(growable: false),
                          ),
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

  Widget _buildTypeAssetUploadField(BuildContext context) {
    return StreamValueBuilder<XFile?>(
      streamValue: _controller.typeAssetFileStreamValue,
      builder: (context, _) {
        return StreamValueBuilder<String>(
          streamValue: _controller.typeAssetUrlStreamValue,
          builder: (context, currentUrl) {
            return StreamValueBuilder<bool>(
              streamValue: _controller.removeTypeAssetStreamValue,
              builder: (context, isMarkedForRemoval) {
                final selectedFile = _controller.currentTypeAssetFile;
                final trimmedUrl = currentUrl.trim();
                final hasExistingUrl =
                    !isMarkedForRemoval && trimmedUrl.isNotEmpty;
                final normalizedUrl = hasExistingUrl ? trimmedUrl : null;
                final canRemove =
                    selectedFile != null ||
                    hasExistingUrl ||
                    isMarkedForRemoval;
                final selectedLabel =
                    selectedFile?.name ??
                    (isMarkedForRemoval
                        ? 'Imagem canônica será removida ao salvar.'
                        : normalizedUrl ?? 'Nenhuma imagem selecionada');

                return TenantAdminCanonicalImageUploadField(
                  variant: TenantAdminImageUploadVariant.cover,
                  preview: _buildTypeAssetPreview(
                    context,
                    selectedFile: selectedFile,
                    existingUrl: normalizedUrl,
                    isMarkedForRemoval: isMarkedForRemoval,
                  ),
                  selectedLabel: selectedLabel,
                  addLabel: 'Enviar imagem canônica',
                  sourceSheetTitle: 'Adicionar imagem canônica do tipo',
                  urlPromptTitle: 'URL da imagem canônica do tipo',
                  removeLabel: isMarkedForRemoval
                      ? 'Desfazer remoção'
                      : 'Remover',
                  busy: false,
                  canRemove: canRemove,
                  onRemove: _controller.clearTypeAssetSelection,
                  initialWebUrl: normalizedUrl,
                  slot: TenantAdminImageSlot.typeVisual,
                  pickFromDevice: _controller.pickTypeAssetImageFromDevice,
                  fetchImageFromUrlForCrop:
                      _controller.fetchImageFromUrlForCrop,
                  readBytesForCrop: _controller.readImageBytesForCrop,
                  prepareCroppedFile: _controller.prepareCroppedImage,
                  onImageSelected: (cropped) async {
                    _controller.updateTypeAssetFile(cropped);
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildTypeAssetPreview(
    BuildContext context, {
    required XFile? selectedFile,
    required String? existingUrl,
    required bool isMarkedForRemoval,
  }) {
    if (selectedFile != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: TenantAdminXFilePreview(
          file: selectedFile,
          width: 120,
          height: 120,
          fit: BoxFit.cover,
        ),
      );
    }

    if (isMarkedForRemoval) {
      return _buildTypeAssetPlaceholder(context, icon: Icons.delete_outline);
    }

    if (existingUrl != null && existingUrl.isNotEmpty) {
      return BellugaNetworkImage(
        existingUrl,
        width: 120,
        height: 120,
        fit: BoxFit.cover,
        clipBorderRadius: BorderRadius.circular(16),
      );
    }

    return _buildTypeAssetPlaceholder(context, icon: Icons.photo_outlined);
  }

  Widget _buildTypeAssetPlaceholder(
    BuildContext context, {
    required IconData icon,
  }) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(child: Icon(icon)),
    );
  }

  void _handleSuccessMessage(String? message) {
    if (message == null || message.isEmpty) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
      _controller.clearSuccessMessage();
      performTenantAdminCurrentRouteBack(context);
    });
  }

  void _handleErrorMessage(String? message) {
    if (message == null || message.isEmpty) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
      _controller.clearActionErrorMessage();
    });
  }
}
