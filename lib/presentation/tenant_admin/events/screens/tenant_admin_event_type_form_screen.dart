import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/support/tenant_admin_safe_back.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_event.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_poi_visual.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_definition.dart';
import 'package:belluga_now/presentation/shared/widgets/belluga_network_image.dart';
import 'package:belluga_now/presentation/tenant_admin/events/controllers/tenant_admin_events_controller.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/utils/tenant_admin_form_value_utils.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/utils/tenant_admin_image_ingestion_service.dart';
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

class TenantAdminEventTypeFormScreen extends StatefulWidget {
  const TenantAdminEventTypeFormScreen({
    super.key,
    this.existingType,
  });

  final TenantAdminEventType? existingType;

  @override
  State<TenantAdminEventTypeFormScreen> createState() =>
      _TenantAdminEventTypeFormScreenState();
}

class _TenantAdminEventTypeFormScreenState
    extends State<TenantAdminEventTypeFormScreen> {
  final TenantAdminEventsController _controller =
      GetIt.I.get<TenantAdminEventsController>();

  bool get _isEdit => widget.existingType != null;

  @override
  void initState() {
    super.initState();
    _controller.initEventTypeForm(existingType: widget.existingType);
    _controller.loadEventTypeFormTaxonomies();
  }

  Future<void> _save() async {
    final messenger = ScaffoldMessenger.of(context);
    final router = context.router;
    if (_controller.eventTypeFormStateStreamValue.value.isSaving) {
      return;
    }
    final form = _controller.eventTypeFormKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }

    _controller.setEventTypeFormSaving(true);
    _controller.setEventTypeFormError(null);

    final name = _controller.eventTypeNameController.text.trim();
    final slug = _controller.eventTypeSlugController.text.trim();
    final description = _controller.eventTypeDescriptionController.text.trim();
    try {
      final visual = _controller.buildCurrentEventTypeVisual();
      if (visual == null) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text(
              'Configuração visual do tipo inválida. Revise modo, ícone/cor ou fonte de imagem.',
            ),
          ),
        );
        _controller.setEventTypeFormSaving(false);
        return;
      }
      final requiresTypeAsset = visual.mode == TenantAdminPoiVisualMode.image &&
          visual.imageSource == TenantAdminPoiVisualImageSource.typeAsset;
      final typeAssetUpload = requiresTypeAsset
          ? await _controller.buildEventTypeAssetUpload()
          : null;
      if (requiresTypeAsset &&
          typeAssetUpload == null &&
          _controller.currentEventTypeTypeAssetUrl == null) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text(
              'Envie uma imagem canônica do tipo ou escolha Capa do evento como fonte.',
            ),
          ),
        );
        _controller.setEventTypeFormSaving(false);
        return;
      }

      _controller
          .saveEventType(
        name: name,
        slug: slug,
        description: description,
        allowedTaxonomies: _controller.selectedEventTypeAllowedTaxonomies,
        visual: visual,
        typeAssetUpload: typeAssetUpload,
        removeTypeAsset: _controller.isEventTypeTypeAssetMarkedForRemoval,
        includeVisual: true,
        existingType: widget.existingType,
      )
          .then((type) {
        if (!mounted) {
          return;
        }
        router.maybePop(type);
      }).catchError((error) {
        _controller.setEventTypeFormError(error.toString());
      }).whenComplete(() {
        _controller.setEventTypeFormSaving(false);
      });
    } catch (error) {
      _controller.setEventTypeFormError(error.toString());
      _controller.setEventTypeFormSaving(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamValueBuilder<TenantAdminEventTypeFormState>(
      streamValue: _controller.eventTypeFormStateStreamValue,
      builder: (context, formState) {
        final formError = formState.formError;
        return TenantAdminFormScaffold(
          closePolicy: buildTenantAdminCurrentRouteBackPolicy(context),
          title: _isEdit ? 'Editar tipo de evento' : 'Criar tipo de evento',
          showHandle: false,
          child: SingleChildScrollView(
            child: Form(
              key: _controller.eventTypeFormKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (formError != null && formError.isNotEmpty) ...[
                    TenantAdminErrorBanner(
                      rawError: formError,
                      fallbackMessage: 'Falha ao salvar tipo de evento.',
                      onRetry: () => _controller.setEventTypeFormError(null),
                    ),
                    const SizedBox(height: 16),
                  ],
                  TenantAdminFormSectionCard(
                    title: 'Dados do tipo',
                    description:
                        'Use tipos para padronizar o formulário de criação de eventos.',
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _controller.eventTypeNameController,
                          decoration: const InputDecoration(
                            labelText: 'Nome',
                            hintText: 'Ex: Workshop',
                          ),
                          textCapitalization: TextCapitalization.words,
                          validator: (value) {
                            final trimmed = value?.trim() ?? '';
                            if (trimmed.isEmpty) {
                              return 'Nome é obrigatório.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _controller.eventTypeSlugController,
                          decoration: const InputDecoration(
                            labelText: 'Slug',
                            hintText: 'Ex: workshop',
                          ),
                          inputFormatters: tenantAdminSlugInputFormatters,
                          autocorrect: false,
                          enableSuggestions: false,
                          validator: (value) {
                            return tenantAdminValidateRequiredSlug(
                              value,
                              requiredMessage: 'Slug é obrigatório.',
                              invalidMessage:
                                  'Slug inválido. Use letras minúsculas, números, - ou _.',
                            );
                          },
                          onChanged: _controller
                              .updateEventTypeSlugAutoFlagFromManualInput,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller:
                              _controller.eventTypeDescriptionController,
                          decoration: const InputDecoration(
                            labelText: 'Descrição (opcional)',
                          ),
                          minLines: 2,
                          maxLines: 4,
                        ),
                        const SizedBox(height: 16),
                        _buildPoiVisualEditor(context),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildTaxonomySelection(context),
                  const SizedBox(height: 24),
                  TenantAdminPrimaryFormAction(
                    label: _isEdit ? 'Salvar alterações' : 'Criar tipo',
                    icon: _isEdit ? Icons.save_outlined : Icons.add,
                    isLoading: formState.isSaving,
                    onPressed: formState.isSaving ? null : _save,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPoiVisualEditor(BuildContext context) {
    return StreamValueBuilder<TenantAdminPoiVisualMode>(
      streamValue: _controller.eventTypePoiVisualModeStreamValue,
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
              decoration: const InputDecoration(
                labelText: 'Modo visual',
              ),
              items: TenantAdminPoiVisualMode.values
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
                _controller.updateEventTypePoiVisualMode(value);
              },
            ),
            if (mode == TenantAdminPoiVisualMode.icon) ...[
              const SizedBox(height: 12),
              TenantAdminMapMarkerIconPickerField(
                controller: _controller.eventTypePoiVisualIconController,
                labelText: 'Ícone',
              ),
              const SizedBox(height: 12),
              TenantAdminColorPickerField(
                controller: _controller.eventTypePoiVisualColorController,
                labelText: 'Cor do marcador',
              ),
              const SizedBox(height: 12),
              TenantAdminColorPickerField(
                controller: _controller.eventTypePoiVisualIconColorController,
                labelText: 'Cor do ícone',
              ),
            ] else ...[
              const SizedBox(height: 12),
              StreamValueBuilder<TenantAdminPoiVisualImageSource>(
                streamValue:
                    _controller.eventTypePoiVisualImageSourceStreamValue,
                builder: (context, imageSource) {
                  final imageSourceItems = <TenantAdminPoiVisualImageSource>[
                    TenantAdminPoiVisualImageSource.cover,
                    TenantAdminPoiVisualImageSource.typeAsset,
                  ];
                  return Column(
                    children: [
                      DropdownButtonFormField<TenantAdminPoiVisualImageSource>(
                        initialValue: imageSource,
                        decoration: const InputDecoration(
                          labelText: 'Fonte da imagem',
                        ),
                        items: imageSourceItems
                            .map(
                              (item) => DropdownMenuItem(
                                value: item,
                                child: Text(
                                  item == TenantAdminPoiVisualImageSource.cover
                                      ? 'Capa do evento'
                                      : item.label,
                                ),
                              ),
                            )
                            .toList(growable: false),
                        onChanged: (value) {
                          if (value == null) {
                            return;
                          }
                          _controller.updateEventTypePoiVisualImageSource(
                            value,
                          );
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

  Widget _buildTaxonomySelection(BuildContext context) {
    return TenantAdminFormSectionCard(
      title: 'Taxonomias permitidas',
      description: 'Selecione quais taxonomias podem ser usadas neste tipo.',
      child: StreamValueBuilder<bool>(
        streamValue: _controller.taxonomyLoadingStreamValue,
        builder: (context, isLoading) {
          return StreamValueBuilder<String?>(
            streamValue: _controller.taxonomyErrorStreamValue,
            builder: (context, error) {
              return StreamValueBuilder<List<TenantAdminTaxonomyDefinition>>(
                streamValue: _controller.taxonomiesStreamValue,
                builder: (context, availableTaxonomies) {
                  return StreamValueBuilder<List<String>>(
                    streamValue: _controller.eventTypeAllowedTaxonomiesStreamValue,
                    builder: (context, selectedTaxonomies) {
                      final selected = selectedTaxonomies.toSet();
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
                                onRetry: _controller.loadEventTypeFormTaxonomies,
                              ),
                            ),
                          if (availableTaxonomies.isEmpty && !isLoading)
                            Text(
                              'Nenhuma taxonomia aplicavel a eventos encontrada.',
                              style: Theme.of(context).textTheme.bodySmall,
                            )
                          else
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: availableTaxonomies
                                  .map(
                                    (taxonomy) {
                                      final label =
                                          '${taxonomy.name} (${taxonomy.slug})';
                                      final isSelected =
                                          selected.contains(taxonomy.slug);
                                      return Semantics(
                                        container: true,
                                        label: label,
                                        button: true,
                                        toggled: isSelected,
                                        selected: isSelected,
                                        child: ExcludeSemantics(
                                          child: FilterChip(
                                            label: Text(label),
                                            selected: isSelected,
                                            onSelected: (_) => _controller
                                                .toggleEventTypeAllowedTaxonomy(
                                                  taxonomy.slug,
                                                ),
                                          ),
                                        ),
                                      );
                                    },
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
      ),
    );
  }

  Widget _buildTypeAssetUploadField(BuildContext context) {
    return StreamValueBuilder<XFile?>(
      streamValue: _controller.eventTypeTypeAssetFileStreamValue,
      builder: (context, _) {
        return StreamValueBuilder<String>(
          streamValue: _controller.eventTypeTypeAssetUrlStreamValue,
          builder: (context, currentUrl) {
            return StreamValueBuilder<bool>(
              streamValue: _controller.eventTypeRemoveTypeAssetStreamValue,
              builder: (context, isMarkedForRemoval) {
                final selectedFile = _controller.currentEventTypeTypeAssetFile;
                final trimmedUrl = currentUrl.trim();
                final hasExistingUrl =
                    !isMarkedForRemoval && trimmedUrl.isNotEmpty;
                final normalizedUrl = hasExistingUrl ? trimmedUrl : null;
                final canRemove = selectedFile != null ||
                    hasExistingUrl ||
                    isMarkedForRemoval;
                final selectedLabel = selectedFile?.name ??
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
                  removeLabel:
                      isMarkedForRemoval ? 'Desfazer remoção' : 'Remover',
                  busy: false,
                  canRemove: canRemove,
                  onRemove: _controller.clearEventTypeTypeAssetSelection,
                  initialWebUrl: normalizedUrl,
                  slot: TenantAdminImageSlot.typeVisual,
                  pickFromDevice: _controller.pickEventTypeAssetImageFromDevice,
                  fetchImageFromUrlForCrop:
                      _controller.fetchEventTypeImageFromUrlForCrop,
                  readBytesForCrop: _controller.readEventTypeImageBytesForCrop,
                  prepareCroppedFile: _controller.prepareEventTypeCroppedImage,
                  onImageSelected: (cropped) async {
                    _controller.updateEventTypeTypeAssetFile(cropped);
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
      return _buildTypeAssetPlaceholder(
        context,
        icon: Icons.delete_outline,
      );
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

    return _buildTypeAssetPlaceholder(
      context,
      icon: Icons.photo_outlined,
    );
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
}
