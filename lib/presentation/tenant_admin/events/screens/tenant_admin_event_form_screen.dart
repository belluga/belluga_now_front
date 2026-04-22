import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/application/router/support/tenant_admin_safe_back.dart';
import 'package:belluga_now/application/time/timezone_converter.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_account_profile.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_event.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_event_account_profile_candidate_type.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_definition.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_term.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_terms.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_term_definition.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_account_profile_id_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_value_parsers.dart';
import 'package:belluga_now/presentation/shared/widgets/belluga_network_image.dart';
import 'package:belluga_now/presentation/tenant_admin/events/controllers/tenant_admin_events_controller.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/utils/tenant_admin_image_ingestion_service.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/widgets/tenant_admin_error_banner.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/widgets/tenant_admin_field_edit_sheet.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/widgets/tenant_admin_form_layout.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/widgets/tenant_admin_image_crop_sheet.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/widgets/tenant_admin_image_source_sheet.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/widgets/tenant_admin_image_upload_field.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/widgets/tenant_admin_rich_text_editor.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/widgets/tenant_admin_xfile_preview.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:image_picker/image_picker.dart';
import 'package:stream_value/core/stream_value_builder.dart';

class TenantAdminEventFormScreen extends StatefulWidget {
  const TenantAdminEventFormScreen({
    super.key,
    this.existingEvent,
    this.accountSlugForOwnCreate,
  });

  final TenantAdminEvent? existingEvent;
  final String? accountSlugForOwnCreate;

  @override
  State<TenantAdminEventFormScreen> createState() =>
      _TenantAdminEventFormScreenState();
}

class _TenantAdminEventFormScreenState
    extends State<TenantAdminEventFormScreen> {
  final TenantAdminEventsController _controller =
      GetIt.I.get<TenantAdminEventsController>();
  bool _submitInFlight = false;

  bool get _isEditing => widget.existingEvent != null;

  @override
  void initState() {
    super.initState();
    _controller.initEventForm(existingEvent: widget.existingEvent);

    _controller.clearSubmitMessages();
    _controller.loadFormDependencies(
      accountSlug: widget.accountSlugForOwnCreate,
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamValueBuilder<TenantAdminEventFormState>(
      streamValue: _controller.eventFormStateStreamValue,
      builder: (context, formState) {
        return StreamValueBuilder<String?>(
          streamValue: _controller.submitErrorMessageStreamValue,
          builder: (context, submitError) {
            return StreamValueBuilder<bool>(
              streamValue: _controller.submitLoadingStreamValue,
              builder: (context, isSubmitting) {
                return StreamValueBuilder<List<TenantAdminAccountProfile>>(
                  streamValue: _controller.venueCandidatesStreamValue,
                  builder: (context, venues) {
                    _controller.hydrateDefaultEventVenue(venues);
                    return StreamValueBuilder<bool>(
                      streamValue: _controller
                          .accountProfileCandidatesLoadingStreamValue,
                      builder: (context, partyCandidatesLoading) {
                        return StreamValueBuilder<String?>(
                          streamValue: _controller
                              .accountProfileCandidatesErrorStreamValue,
                          builder: (context, partyCandidatesError) {
                            return StreamValueBuilder<
                                List<TenantAdminAccountProfile>>(
                              streamValue: _controller
                                  .relatedAccountProfileCandidatesStreamValue,
                              builder: (context, relatedAccountProfiles) {
                                return StreamValueBuilder<
                                    List<TenantAdminEventType>>(
                                  streamValue:
                                      _controller.eventTypeCatalogStreamValue,
                                  builder: (context, eventTypes) {
                                    _controller.hydrateDefaultEventType(
                                      eventTypes,
                                    );
                                    return StreamValueBuilder<
                                        List<TenantAdminTaxonomyDefinition>>(
                                      streamValue:
                                          _controller.taxonomiesStreamValue,
                                      builder: (context, taxonomies) {
                                        return StreamValueBuilder<
                                            Map<
                                                String,
                                                List<
                                                    TenantAdminTaxonomyTermDefinition>>>(
                                          streamValue: _controller
                                              .taxonomyTermsBySlugStreamValue,
                                          builder: (context, termsBySlug) {
                                            return StreamValueBuilder<XFile?>(
                                              streamValue: _controller
                                                  .eventCoverFileStreamValue,
                                              builder:
                                                  (context, selectedCover) {
                                                return StreamValueBuilder<bool>(
                                                  streamValue: _controller
                                                      .eventCoverBusyStreamValue,
                                                  builder:
                                                      (context, isCoverBusy) {
                                                    return StreamValueBuilder<
                                                        bool>(
                                                      streamValue: _controller
                                                          .eventCoverRemoveStreamValue,
                                                      builder: (
                                                        context,
                                                        isCoverMarkedForRemoval,
                                                      ) {
                                                        return TenantAdminFormScaffold(
                                                          closePolicy:
                                                              buildTenantAdminCurrentRouteBackPolicy(
                                                            context,
                                                          ),
                                                          title: _isEditing
                                                              ? 'Editar evento'
                                                              : 'Criar evento',
                                                          showHandle: false,
                                                          floatingActionButton:
                                                              _buildAddOccurrenceFloatingActionButton(
                                                            formState:
                                                                formState,
                                                            venues: venues,
                                                            isSubmitting:
                                                                isSubmitting,
                                                          ),
                                                          floatingActionButtonLocation:
                                                              FloatingActionButtonLocation
                                                                  .endFloat,
                                                          child: Form(
                                                            key: _controller
                                                                .eventFormKey,
                                                            child:
                                                                SingleChildScrollView(
                                                              child: Column(
                                                                crossAxisAlignment:
                                                                    CrossAxisAlignment
                                                                        .start,
                                                                children: [
                                                                  if (submitError
                                                                          ?.isNotEmpty ??
                                                                      false)
                                                                    TenantAdminErrorBanner(
                                                                      rawError:
                                                                          submitError ??
                                                                              '',
                                                                      fallbackMessage:
                                                                          'Falha ao salvar evento.',
                                                                      onRetry:
                                                                          _controller
                                                                              .clearSubmitMessages,
                                                                    ),
                                                                  if (partyCandidatesLoading)
                                                                    const Padding(
                                                                      padding:
                                                                          EdgeInsets
                                                                              .only(
                                                                        top: 8,
                                                                        bottom:
                                                                            8,
                                                                      ),
                                                                      child:
                                                                          LinearProgressIndicator(),
                                                                    ),
                                                                  if (partyCandidatesError
                                                                          ?.isNotEmpty ??
                                                                      false)
                                                                    Padding(
                                                                      padding:
                                                                          const EdgeInsets
                                                                              .only(
                                                                        bottom:
                                                                            8,
                                                                      ),
                                                                      child:
                                                                          TenantAdminErrorBanner(
                                                                        rawError:
                                                                            partyCandidatesError ??
                                                                                '',
                                                                        fallbackMessage:
                                                                            'Falha ao carregar hosts físicos e perfis relacionados.',
                                                                        onRetry:
                                                                            () =>
                                                                                _controller.loadFormDependencies(
                                                                          accountSlug:
                                                                              widget.accountSlugForOwnCreate,
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  _buildBasicSection(),
                                                                  const SizedBox(
                                                                    height: 16,
                                                                  ),
                                                                  _buildCoverSection(
                                                                    selectedCover:
                                                                        selectedCover,
                                                                    isCoverBusy:
                                                                        isCoverBusy,
                                                                    isCoverMarkedForRemoval:
                                                                        isCoverMarkedForRemoval,
                                                                    isSubmitting:
                                                                        isSubmitting,
                                                                  ),
                                                                  const SizedBox(
                                                                    height: 16,
                                                                  ),
                                                                  _buildTypeSection(
                                                                    eventTypes,
                                                                    formState:
                                                                        formState,
                                                                  ),
                                                                  const SizedBox(
                                                                    height: 16,
                                                                  ),
                                                                  _buildScheduleSection(
                                                                    formState:
                                                                        formState,
                                                                    venues:
                                                                        venues,
                                                                  ),
                                                                  const SizedBox(
                                                                    height: 16,
                                                                  ),
                                                                  _buildPublicationSection(
                                                                    formState:
                                                                        formState,
                                                                  ),
                                                                  const SizedBox(
                                                                    height: 16,
                                                                  ),
                                                                  _buildLocationSection(
                                                                    venues,
                                                                    formState:
                                                                        formState,
                                                                  ),
                                                                  const SizedBox(
                                                                    height: 16,
                                                                  ),
                                                                  _buildRelatedAccountProfilesSection(
                                                                    relatedAccountProfiles,
                                                                    formState:
                                                                        formState,
                                                                  ),
                                                                  const SizedBox(
                                                                    height: 16,
                                                                  ),
                                                                  _buildTaxonomySection(
                                                                    taxonomies:
                                                                        taxonomies,
                                                                    termsBySlug:
                                                                        termsBySlug,
                                                                    formState:
                                                                        formState,
                                                                  ),
                                                                  const SizedBox(
                                                                    height: 24,
                                                                  ),
                                                                  TenantAdminPrimaryFormAction(
                                                                    label: _isEditing
                                                                        ? 'Salvar alterações'
                                                                        : 'Criar evento',
                                                                    onPressed: isSubmitting
                                                                        ? null
                                                                        : () => _handleSubmit(
                                                                              relatedAccountProfiles: relatedAccountProfiles,
                                                                              venues: venues,
                                                                              eventTypes: eventTypes,
                                                                              formState: formState,
                                                                              selectedCover: selectedCover,
                                                                              isCoverMarkedForRemoval: isCoverMarkedForRemoval,
                                                                            ),
                                                                    isLoading:
                                                                        isSubmitting,
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
                                          },
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

  Widget _buildBasicSection() {
    return TenantAdminFormSectionCard(
      title: 'Identificação',
      child: Column(
        children: [
          TextFormField(
            controller: _controller.eventTitleController,
            decoration: const InputDecoration(
              labelText: 'Título',
              hintText: 'Ex: Feira de Inverno',
            ),
            validator: (value) {
              final trimmed = value?.trim() ?? '';
              if (trimmed.isEmpty) {
                return 'Título é obrigatório.';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          TenantAdminRichTextEditor(
            controller: _controller.eventContentController,
            label: 'Descrição (opcional)',
            placeholder: 'Escreva a descrição do evento',
            minHeight: 180,
          ),
        ],
      ),
    );
  }

  Widget _buildCoverSection({
    required XFile? selectedCover,
    required bool isCoverBusy,
    required bool isCoverMarkedForRemoval,
    required bool isSubmitting,
  }) {
    final existingCoverUrl = widget.existingEvent?.thumbUrl?.trim();
    final hasExistingCover =
        existingCoverUrl != null && existingCoverUrl.isNotEmpty;
    final canRemove = selectedCover != null ||
        (hasExistingCover && !isCoverMarkedForRemoval) ||
        isCoverMarkedForRemoval;

    final selectedLabel = selectedCover?.name ??
        (isCoverMarkedForRemoval
            ? 'Capa será removida ao salvar.'
            : hasExistingCover
                ? existingCoverUrl
                : 'Nenhuma imagem selecionada');

    return TenantAdminFormSectionCard(
      title: 'Capa do evento',
      description:
          'Opcional. Se não houver capa, a experiência pública pode usar fallback dos perfis relacionados.',
      child: TenantAdminImageUploadField(
        variant: TenantAdminImageUploadVariant.cover,
        preview: _buildCoverPreview(
          selectedCover: selectedCover,
          existingCoverUrl: existingCoverUrl,
          isCoverMarkedForRemoval: isCoverMarkedForRemoval,
        ),
        selectedLabel: selectedLabel,
        addLabel: 'Adicionar capa',
        removeLabel: isCoverMarkedForRemoval ? 'Desfazer remoção' : 'Remover',
        onAdd: (isSubmitting || isCoverBusy) ? null : _pickCoverImage,
        busy: isCoverBusy,
        canRemove: canRemove,
        onRemove: (isSubmitting || isCoverBusy)
            ? null
            : () => _clearCoverSelection(
                  hasExistingCover: hasExistingCover,
                  hasSelectedCover: selectedCover != null,
                  isCoverMarkedForRemoval: isCoverMarkedForRemoval,
                ),
      ),
    );
  }

  Widget _buildCoverPreview({
    required XFile? selectedCover,
    required String? existingCoverUrl,
    required bool isCoverMarkedForRemoval,
  }) {
    if (selectedCover != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: TenantAdminXFilePreview(
          file: selectedCover,
          width: double.infinity,
          height: 140,
          fit: BoxFit.cover,
        ),
      );
    }

    if (isCoverMarkedForRemoval) {
      return Container(
        width: double.infinity,
        height: 140,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(child: Icon(Icons.delete_outline)),
      );
    }

    final normalizedCoverUrl = existingCoverUrl?.trim();
    if (normalizedCoverUrl != null && normalizedCoverUrl.isNotEmpty) {
      return BellugaNetworkImage(
        normalizedCoverUrl,
        width: double.infinity,
        height: 140,
        fit: BoxFit.cover,
        clipBorderRadius: BorderRadius.circular(12),
      );
    }

    return Container(
      width: double.infinity,
      height: 140,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(child: Icon(Icons.image_outlined)),
    );
  }

  Widget _buildTypeSection(
    List<TenantAdminEventType> eventTypes, {
    required TenantAdminEventFormState formState,
  }) {
    final selectedType = eventTypes.firstWhereOrNull(
      (type) => type.slug.trim() == (formState.selectedTypeSlug ?? '').trim(),
    );

    return TenantAdminFormSectionCard(
      title: 'Tipo de evento',
      description:
          'Selecione um tipo existente. O gerenciamento de tipos é feito em uma tela dedicada.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownButtonFormField<String>(
            key: ValueKey<String?>('event-type-${formState.selectedTypeSlug}'),
            initialValue: selectedType?.slug,
            decoration: const InputDecoration(labelText: 'Tipo'),
            items: eventTypes
                .map(
                  (type) => DropdownMenuItem<String>(
                    value: type.slug,
                    child: Text(type.name),
                  ),
                )
                .toList(growable: false),
            onChanged: (value) {
              _controller.updateEventTypeSelection(value);
            },
            validator: (value) {
              final trimmed = value?.trim() ?? '';
              if (trimmed.isEmpty) {
                return 'Tipo de evento é obrigatório.';
              }
              return null;
            },
          ),
          if (selectedType?.description?.trim().isNotEmpty == true) ...[
            const SizedBox(height: 8),
            Text(
              selectedType!.description!.trim(),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _openEventTypeManagement,
            icon: const Icon(Icons.category_outlined),
            label: const Text('Gerenciar tipos de evento'),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleSection({
    required TenantAdminEventFormState formState,
    required List<TenantAdminAccountProfile> venues,
  }) {
    final occurrences = formState.occurrences;
    if (occurrences.length > 1) {
      return TenantAdminFormSectionCard(
        title: 'Datas',
        description:
            'Gerencie as ocorrências deste evento. Campos compartilhados ficam nas seções acima.',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var index = 0; index < occurrences.length; index++)
              _buildOccurrenceCard(
                occurrence: occurrences[index],
                index: index,
                totalCount: occurrences.length,
                venues: venues,
              ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: _buildAddOccurrenceInlineButton(
                formState: formState,
                venues: venues,
              ),
            ),
          ],
        ),
      );
    }

    return TenantAdminFormSectionCard(
      title: 'Ocorrência',
      description:
          'Selecione data e horário da primeira ocorrência. Depois disso, adicione outras datas quando o evento tiver múltiplas ocorrências.',
      child: Column(
        children: [
          _buildDateTimeField(
            controller: _controller.eventStartController,
            label: 'Início',
            onTap: _pickStartDateTime,
            validator: (_) {
              final startAt = formState.startAt ??
                  _toLocalDateTime(
                    _parseDateTimeFromField(
                      _controller.eventStartController.text,
                    ),
                  );
              if (startAt == null) {
                return 'Início é obrigatório.';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          _buildDateTimeField(
            controller: _controller.eventEndController,
            label: 'Fim (opcional)',
            onTap: _pickEndDateTime,
            onClear:
                formState.endAt == null ? null : _controller.clearEventEndAt,
            validator: (_) {
              final startAt = formState.startAt ??
                  _toLocalDateTime(
                    _parseDateTimeFromField(
                      _controller.eventStartController.text,
                    ),
                  );
              final endAt = formState.endAt ??
                  _toLocalDateTime(
                    _parseDateTimeFromField(
                      _controller.eventEndController.text,
                    ),
                  );
              if (endAt == null) {
                return null;
              }
              if (startAt != null && endAt.isBefore(startAt)) {
                return 'Fim deve ser posterior ao início.';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: _buildAddOccurrenceInlineButton(
              formState: formState,
              venues: venues,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddOccurrenceFloatingActionButton({
    required TenantAdminEventFormState formState,
    required List<TenantAdminAccountProfile> venues,
    required bool isSubmitting,
  }) {
    return FloatingActionButton.extended(
      key: const Key('tenantAdminEventAddOccurrenceButton'),
      heroTag: 'tenantAdminEventAddOccurrenceButton',
      onPressed: isSubmitting
          ? null
          : () => _openOccurrenceEditor(
                formState: formState,
                index: null,
                venues: venues,
              ),
      icon: const Icon(Icons.add),
      label: const Text('Adicionar data'),
    );
  }

  Widget _buildAddOccurrenceInlineButton({
    required TenantAdminEventFormState formState,
    required List<TenantAdminAccountProfile> venues,
  }) {
    return OutlinedButton.icon(
      key: const Key('tenantAdminEventAddOccurrenceInlineButton'),
      onPressed: () => _openOccurrenceEditor(
        formState: formState,
        index: null,
        venues: venues,
      ),
      icon: const Icon(Icons.add),
      label: const Text('Adicionar data'),
    );
  }

  Future<bool> _closeModalSheet<T>(BuildContext context, [T? result]) {
    final navigator = ModalRoute.of(context)?.navigator;
    if (navigator != null) {
      return navigator.maybePop<T>(result);
    }
    return context.router.maybePop<T>(result);
  }

  Widget _buildOccurrenceCard({
    required TenantAdminEventOccurrence occurrence,
    required int index,
    required int totalCount,
    required List<TenantAdminAccountProfile> venues,
  }) {
    final theme = Theme.of(context);
    final end = occurrence.dateTimeEnd;
    final relatedCount = occurrence.relatedAccountProfileIds.length;
    final programmingCount = occurrence.programmingCount;
    return Card(
      key: Key('tenantAdminEventOccurrenceCard_$index'),
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _openOccurrenceEditor(
          formState: _controller.eventFormStateStreamValue.value,
          index: index,
          venues: venues,
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.event_available_outlined),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formatOccurrenceDateTime(occurrence.dateTimeStart),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (end != null)
                      Text(
                        'Fim: ${_formatOccurrenceDateTime(end)}',
                        style: theme.textTheme.bodySmall,
                      ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (occurrence.hasLocationOverride)
                          const _OccurrenceSummaryChip(
                            label: 'Local sobrescrito',
                            icon: Icons.place_outlined,
                          ),
                        if (relatedCount > 0)
                          _OccurrenceSummaryChip(
                            label: relatedCount == 1
                                ? '1 perfil próprio'
                                : '$relatedCount perfis próprios',
                            icon: Icons.group_outlined,
                          ),
                        if (programmingCount > 0)
                          _OccurrenceSummaryChip(
                            label: programmingCount == 1
                                ? '1 item de programação'
                                : '$programmingCount itens de programação',
                            icon: Icons.schedule,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Remover data',
                onPressed: totalCount <= 1
                    ? null
                    : () => _controller.removeOccurrenceAt(index),
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPublicationSection({
    required TenantAdminEventFormState formState,
  }) {
    return TenantAdminFormSectionCard(
      title: 'Publicação',
      child: Column(
        children: [
          DropdownButtonFormField<String>(
            initialValue: formState.publicationStatus,
            decoration: const InputDecoration(labelText: 'Status'),
            items: const [
              DropdownMenuItem(value: 'draft', child: Text('Draft')),
              DropdownMenuItem(value: 'published', child: Text('Published')),
              DropdownMenuItem(
                value: 'publish_scheduled',
                child: Text('Publish scheduled'),
              ),
              DropdownMenuItem(value: 'ended', child: Text('Ended')),
            ],
            onChanged: (value) {
              if (value == null) {
                return;
              }
              _controller.updateEventPublicationStatus(value);
            },
          ),
          if (formState.publicationStatus == 'publish_scheduled') ...[
            const SizedBox(height: 12),
            _buildDateTimeField(
              controller: _controller.eventPublishAtController,
              label: 'Publish at',
              onTap: _pickPublishAtDateTime,
              onClear: formState.publishAt == null
                  ? null
                  : _controller.clearEventPublishAt,
              validator: (_) {
                if (formState.publicationStatus != 'publish_scheduled') {
                  return null;
                }
                final publishAt = formState.publishAt ??
                    _toLocalDateTime(
                      _parseDateTimeFromField(
                        _controller.eventPublishAtController.text,
                      ),
                    );
                if (publishAt == null) {
                  return 'Publish at é obrigatório para publish_scheduled.';
                }
                return null;
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLocationSection(
    List<TenantAdminAccountProfile> venues, {
    required TenantAdminEventFormState formState,
  }) {
    return TenantAdminFormSectionCard(
      title: 'Localização',
      description:
          'Para physical/hybrid, a localização do evento pode ser derivada do perfil anfitrião selecionado.',
      child: Column(
        children: [
          DropdownButtonFormField<String>(
            initialValue: formState.locationMode,
            decoration: const InputDecoration(labelText: 'Modo'),
            items: const [
              DropdownMenuItem(value: 'physical', child: Text('Physical')),
              DropdownMenuItem(value: 'online', child: Text('Online')),
              DropdownMenuItem(value: 'hybrid', child: Text('Hybrid')),
            ],
            onChanged: (value) {
              if (value == null) {
                return;
              }
              _controller.updateEventLocationMode(value);
            },
          ),
          if (formState.locationMode == 'physical' ||
              formState.locationMode == 'hybrid') ...[
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: formState.selectedVenueId,
              decoration: const InputDecoration(
                labelText: 'Host físico (perfil)',
              ),
              items: venues
                  .map(
                    (venue) => DropdownMenuItem<String>(
                      value: venue.id,
                      child: Text(venue.displayName),
                    ),
                  )
                  .toList(growable: false),
              onChanged:
                  venues.isEmpty ? null : _controller.updateEventVenueSelection,
              validator: (value) {
                if (formState.locationMode == 'physical' ||
                    formState.locationMode == 'hybrid') {
                  if (value == null || value.trim().isEmpty) {
                    return 'Host físico é obrigatório para ${formState.locationMode}.';
                  }
                }
                return null;
              },
            ),
            if (venues.isEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Nenhum perfil elegível para host físico.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
          if (formState.locationMode == 'online' ||
              formState.locationMode == 'hybrid') ...[
            const SizedBox(height: 12),
            TextFormField(
              controller: _controller.eventOnlineUrlController,
              decoration: const InputDecoration(labelText: 'URL online'),
              validator: (value) {
                if (!(formState.locationMode == 'online' ||
                    formState.locationMode == 'hybrid')) {
                  return null;
                }
                final trimmed = value?.trim() ?? '';
                if (trimmed.isEmpty) {
                  return 'URL online é obrigatória.';
                }
                final uri = Uri.tryParse(trimmed);
                final valid = uri != null &&
                    (uri.scheme == 'http' || uri.scheme == 'https') &&
                    uri.host.isNotEmpty;
                if (!valid) {
                  return 'URL online inválida.';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _controller.eventOnlinePlatformController,
              decoration: const InputDecoration(
                labelText: 'Plataforma online (opcional)',
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRelatedAccountProfilesSection(
    List<TenantAdminAccountProfile> relatedAccountProfiles, {
    required TenantAdminEventFormState formState,
  }) {
    final profilesById = <String, TenantAdminAccountProfile>{
      for (final profile in relatedAccountProfiles) profile.id: profile,
      for (final profile in widget.existingEvent?.relatedAccountProfiles ?? [])
        profile.id: profile,
    };
    final selectedEntries = formState.selectedRelatedAccountProfileIds
        .map(
          (profileId) => MapEntry<String, TenantAdminAccountProfile?>(
            profileId,
            profilesById[profileId],
          ),
        )
        .toList(growable: false);

    return TenantAdminFormSectionCard(
      title: 'Perfis relacionados',
      description:
          'Selecione os perfis relacionados ao evento. A ordem aqui define o fallback da imagem pública do evento.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (selectedEntries.isEmpty)
            Text(
              'Nenhum perfil relacionado selecionado.',
              style: Theme.of(context).textTheme.bodySmall,
            )
          else ...[
            for (var index = 0; index < selectedEntries.length; index++)
              _buildRelatedAccountProfileCard(
                profileId: selectedEntries[index].key,
                profile: selectedEntries[index].value,
                index: index,
                totalCount: selectedEntries.length,
              ),
          ],
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () =>
                _openRelatedAccountProfilePickerSheet(formState: formState),
            icon: const Icon(Icons.add),
            label: const Text('Adicionar perfil'),
          ),
          if (relatedAccountProfiles.isEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Use a busca para localizar perfis relacionados além da primeira página carregada.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRelatedAccountProfileCard({
    required String profileId,
    required TenantAdminAccountProfile? profile,
    required int index,
    required int totalCount,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Icon(Icons.person_outline),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile?.displayName ?? 'Perfil relacionado $profileId',
                      ),
                      const SizedBox(height: 4),
                      Text(
                        profile == null
                            ? 'Perfil não disponível na lista atual'
                            : (profile.slug ?? profile.id),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  tooltip: 'Mover para cima',
                  onPressed: index <= 0
                      ? null
                      : () => _controller.reorderRelatedAccountProfile(
                            profileId: profileId,
                            newIndex: index - 1,
                          ),
                  icon: const Icon(Icons.arrow_upward),
                ),
                IconButton(
                  tooltip: 'Mover para baixo',
                  onPressed: index >= totalCount - 1
                      ? null
                      : () => _controller.reorderRelatedAccountProfile(
                            profileId: profileId,
                            newIndex: index + 1,
                          ),
                  icon: const Icon(Icons.arrow_downward),
                ),
                IconButton(
                  tooltip: 'Remover perfil relacionado',
                  onPressed: () =>
                      _controller.removeRelatedAccountProfile(profileId),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaxonomySection({
    required List<TenantAdminTaxonomyDefinition> taxonomies,
    required Map<String, List<TenantAdminTaxonomyTermDefinition>> termsBySlug,
    required TenantAdminEventFormState formState,
  }) {
    if (taxonomies.isEmpty) {
      return const SizedBox.shrink();
    }

    return TenantAdminFormSectionCard(
      title: 'Taxonomias',
      description: 'Termos com applies_to=event.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: taxonomies.map((taxonomy) {
          final terms = termsBySlug[taxonomy.slug] ??
              const <TenantAdminTaxonomyTermDefinition>[];
          final selected = formState.selectedTaxonomyTerms[taxonomy.slug] ??
              const <String>{};
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                taxonomy.name,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: terms
                    .map(
                      (term) => FilterChip(
                        label: Text(term.name),
                        selected: selected.contains(term.slug),
                        onSelected: (isSelected) =>
                            _controller.toggleEventTaxonomyTerm(
                          taxonomySlug: taxonomy.slug,
                          termSlug: term.slug,
                          isSelected: isSelected,
                        ),
                      ),
                    )
                    .toList(growable: false),
              ),
              const SizedBox(height: 12),
            ],
          );
        }).toList(growable: false),
      ),
    );
  }

  Future<void> _openOccurrenceEditor({
    required TenantAdminEventFormState formState,
    required int? index,
    required List<TenantAdminAccountProfile> venues,
  }) async {
    final existing =
        index == null || index < 0 || index >= formState.occurrences.length
            ? null
            : formState.occurrences[index];
    final fallbackStart = formState.occurrences.isNotEmpty
        ? formState.occurrences.last.dateTimeStart.add(const Duration(days: 1))
        : formState.startAt ?? DateTime.now();
    var startAt = existing?.dateTimeStart ?? fallbackStart;
    var endAt = existing?.dateTimeEnd ??
        (formState.endAt == null || formState.startAt == null
            ? null
            : fallbackStart.add(
                formState.endAt!.difference(formState.startAt!),
              ));
    final relatedProfileIds =
        existing?.relatedAccountProfileIds.toList(growable: true) ??
            <TenantAdminAccountProfileIdValue>[];
    final relatedProfiles =
        existing?.relatedAccountProfiles.toList(growable: true) ??
            <TenantAdminAccountProfile>[];
    final programmingItems =
        existing?.programmingItems.toList(growable: true) ??
            <TenantAdminEventProgrammingItem>[];
    var locationOverrideEnabled = existing?.locationOverride != null;
    var locationMode =
        existing?.locationOverride?.mode ?? formState.locationMode;
    var selectedVenueId = existing?.placeRef?.id;
    var onlineUrl = existing?.locationOverride?.online?.url ?? '';
    var onlinePlatform = existing?.locationOverride?.online?.platform ?? '';
    String? errorMessage;

    final result = await showModalBottomSheet<TenantAdminEventOccurrence>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            Future<void> pickStart() async {
              final picked = await _pickDateTime(
                initialDateTime: startAt,
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              if (picked == null) {
                return;
              }
              setSheetState(() {
                startAt = picked;
                if (endAt != null && endAt!.isBefore(startAt)) {
                  endAt = startAt;
                }
                errorMessage = null;
              });
            }

            Future<void> pickEnd() async {
              final picked = await _pickDateTime(
                initialDateTime: endAt ?? startAt,
                firstDate: startAt,
                lastDate: DateTime(2100),
              );
              if (picked == null) {
                return;
              }
              setSheetState(() {
                endAt = picked;
                errorMessage = null;
              });
            }

            Future<void> addRelatedProfile() async {
              final selected = await _pickRelatedAccountProfile(
                excludedProfileIds: relatedProfileIds
                    .map((profileId) => profileId.value)
                    .toSet(),
              );
              if (selected == null) {
                return;
              }
              setSheetState(() {
                relatedProfileIds.add(
                  TenantAdminAccountProfileIdValue(selected.id),
                );
                relatedProfiles.removeWhere(
                  (profile) => profile.id == selected.id,
                );
                relatedProfiles.add(selected);
                errorMessage = null;
              });
            }

            Future<void> addProgrammingItem() async {
              final item = await _openProgrammingItemEditor();
              if (item == null) {
                return;
              }
              setSheetState(() {
                programmingItems.add(item);
                programmingItems.sort((a, b) => a.time.compareTo(b.time));
                errorMessage = null;
              });
            }

            final includesPhysical =
                locationMode == 'physical' || locationMode == 'hybrid';
            final includesOnline =
                locationMode == 'online' || locationMode == 'hybrid';

            return Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                16 + MediaQuery.viewInsetsOf(context).bottom,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      index == null ? 'Adicionar data' : 'Editar data',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      key: const Key('tenantAdminOccurrenceStartField'),
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.event_outlined),
                      title: const Text('Início'),
                      subtitle: Text(_formatOccurrenceDateTime(startAt)),
                      trailing: const Icon(Icons.edit_calendar_outlined),
                      onTap: pickStart,
                    ),
                    ListTile(
                      key: const Key('tenantAdminOccurrenceEndField'),
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.event_busy_outlined),
                      title: const Text('Fim'),
                      subtitle: Text(
                        endAt == null
                            ? 'Sem fim definido'
                            : _formatOccurrenceDateTime(endAt!),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (endAt != null)
                            IconButton(
                              tooltip: 'Limpar fim',
                              onPressed: () {
                                setSheetState(() {
                                  endAt = null;
                                  errorMessage = null;
                                });
                              },
                              icon: const Icon(Icons.clear),
                            ),
                          const Icon(Icons.edit_calendar_outlined),
                        ],
                      ),
                      onTap: pickEnd,
                    ),
                    const Divider(height: 28),
                    Text(
                      'Perfis próprios da ocorrência',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    if (relatedProfileIds.isEmpty)
                      Text(
                        'Nenhum perfil próprio nesta data.',
                        style: Theme.of(context).textTheme.bodySmall,
                      )
                    else
                      for (final profileId in relatedProfileIds)
                        ListTile(
                          key: Key(
                            'tenantAdminOccurrenceProfile_${profileId.value}',
                          ),
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.person_outline),
                          title: Text(
                            _profileDisplayName(
                              profileId.value,
                              relatedProfiles,
                            ),
                          ),
                          trailing: IconButton(
                            tooltip: 'Remover perfil da ocorrência',
                            onPressed: () {
                              setSheetState(() {
                                relatedProfileIds.removeWhere(
                                  (item) => item.value == profileId.value,
                                );
                                errorMessage = null;
                              });
                            },
                            icon: const Icon(Icons.close),
                          ),
                        ),
                    OutlinedButton.icon(
                      key: const Key('tenantAdminOccurrenceAddProfileButton'),
                      onPressed: addRelatedProfile,
                      icon: const Icon(Icons.add),
                      label: const Text('Adicionar perfil próprio'),
                    ),
                    const Divider(height: 28),
                    SwitchListTile(
                      key: const Key(
                        'tenantAdminOccurrenceLocationOverrideSwitch',
                      ),
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Sobrescrever localização'),
                      subtitle: const Text(
                        'Use apenas quando esta data ocorrer em outro local.',
                      ),
                      value: locationOverrideEnabled,
                      onChanged: (value) {
                        setSheetState(() {
                          locationOverrideEnabled = value;
                          if (value &&
                              selectedVenueId == null &&
                              venues.isNotEmpty) {
                            selectedVenueId = venues.first.id;
                          }
                          errorMessage = null;
                        });
                      },
                    ),
                    if (locationOverrideEnabled) ...[
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        key: const Key('tenantAdminOccurrenceLocationMode'),
                        initialValue: locationMode,
                        decoration: const InputDecoration(labelText: 'Modo'),
                        items: const [
                          DropdownMenuItem(
                            value: 'physical',
                            child: Text('Physical'),
                          ),
                          DropdownMenuItem(
                            value: 'online',
                            child: Text('Online'),
                          ),
                          DropdownMenuItem(
                            value: 'hybrid',
                            child: Text('Hybrid'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value == null) {
                            return;
                          }
                          setSheetState(() {
                            locationMode = value;
                            if ((value == 'physical' || value == 'hybrid') &&
                                selectedVenueId == null &&
                                venues.isNotEmpty) {
                              selectedVenueId = venues.first.id;
                            }
                            errorMessage = null;
                          });
                        },
                      ),
                      if (includesPhysical) ...[
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          key: const Key('tenantAdminOccurrenceVenueDropdown'),
                          initialValue: selectedVenueId,
                          decoration: const InputDecoration(
                            labelText: 'Host físico da ocorrência',
                          ),
                          items: venues
                              .map(
                                (venue) => DropdownMenuItem<String>(
                                  value: venue.id,
                                  child: Text(venue.displayName),
                                ),
                              )
                              .toList(growable: false),
                          onChanged: venues.isEmpty
                              ? null
                              : (value) {
                                  setSheetState(() {
                                    selectedVenueId = value;
                                    errorMessage = null;
                                  });
                                },
                        ),
                      ],
                      if (includesOnline) ...[
                        const SizedBox(height: 12),
                        TextFormField(
                          key: const Key('tenantAdminOccurrenceOnlineUrl'),
                          initialValue: onlineUrl,
                          decoration: const InputDecoration(
                            labelText: 'URL online',
                          ),
                          keyboardType: TextInputType.url,
                          onChanged: (value) {
                            onlineUrl = value;
                            errorMessage = null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          key: const Key('tenantAdminOccurrenceOnlinePlatform'),
                          initialValue: onlinePlatform,
                          decoration: const InputDecoration(
                            labelText: 'Plataforma online (opcional)',
                          ),
                          onChanged: (value) {
                            onlinePlatform = value;
                            errorMessage = null;
                          },
                        ),
                      ],
                    ],
                    const Divider(height: 28),
                    Text(
                      'Programação',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    if (programmingItems.isEmpty)
                      Text(
                        'Nenhum item de programação nesta data.',
                        style: Theme.of(context).textTheme.bodySmall,
                      )
                    else
                      for (var itemIndex = 0;
                          itemIndex < programmingItems.length;
                          itemIndex++)
                        ListTile(
                          key: Key(
                            'tenantAdminOccurrenceProgrammingItem_$itemIndex',
                          ),
                          contentPadding: EdgeInsets.zero,
                          leading: Text(programmingItems[itemIndex].time),
                          title: Text(
                            programmingItems[itemIndex].title ??
                                _firstProgrammingProfileName(
                                  programmingItems[itemIndex],
                                ) ??
                                'Item sem título',
                          ),
                          subtitle: Text(
                            '${programmingItems[itemIndex].accountProfileIds.length} perfil(is) vinculado(s)',
                          ),
                          trailing: IconButton(
                            tooltip: 'Remover item de programação',
                            onPressed: () {
                              setSheetState(() {
                                programmingItems.removeAt(itemIndex);
                                errorMessage = null;
                              });
                            },
                            icon: const Icon(Icons.close),
                          ),
                        ),
                    OutlinedButton.icon(
                      key: const Key(
                        'tenantAdminOccurrenceAddProgrammingButton',
                      ),
                      onPressed: addProgrammingItem,
                      icon: const Icon(Icons.add),
                      label: const Text('Adicionar item de programação'),
                    ),
                    if (errorMessage != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        errorMessage!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () =>
                                unawaited(_closeModalSheet<Object?>(context)),
                            child: const Text('Cancelar'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            key: const Key('tenantAdminOccurrenceSaveButton'),
                            onPressed: () {
                              final selectedVenue = venues.firstWhereOrNull(
                                (venue) => venue.id == selectedVenueId,
                              );
                              final validationError = _validateOccurrenceEditor(
                                startAt: startAt,
                                endAt: endAt,
                                locationOverrideEnabled:
                                    locationOverrideEnabled,
                                locationMode: locationMode,
                                includesPhysical: includesPhysical,
                                includesOnline: includesOnline,
                                selectedVenue: selectedVenue,
                                onlineUrl: onlineUrl,
                              );
                              if (validationError != null) {
                                setSheetState(() {
                                  errorMessage = validationError;
                                });
                                return;
                              }

                              unawaited(
                                _closeModalSheet<TenantAdminEventOccurrence>(
                                  context,
                                  TenantAdminEventOccurrence(
                                    occurrenceIdValue: tenantAdminOptionalText(
                                      existing?.occurrenceId,
                                    ),
                                    occurrenceSlugValue:
                                        tenantAdminOptionalText(
                                      existing?.occurrenceSlug,
                                    ),
                                    dateTimeStartValue: tenantAdminDateTime(
                                      startAt,
                                    ),
                                    dateTimeEndValue:
                                        tenantAdminOptionalDateTime(endAt),
                                    relatedAccountProfileIdValues: List<
                                            TenantAdminAccountProfileIdValue>.unmodifiable(
                                        relatedProfileIds),
                                    relatedAccountProfiles: List<
                                            TenantAdminAccountProfile>.unmodifiable(
                                        relatedProfiles),
                                    locationOverride: locationOverrideEnabled
                                        ? _buildOccurrenceLocationOverride(
                                            mode: locationMode,
                                            selectedVenue: selectedVenue,
                                            onlineUrl: onlineUrl,
                                            onlinePlatform: onlinePlatform,
                                          )
                                        : null,
                                    placeRef: locationOverrideEnabled &&
                                            includesPhysical
                                        ? TenantAdminEventPlaceRef(
                                            typeValue: tenantAdminRequiredText(
                                              'account_profile',
                                            ),
                                            idValue: tenantAdminRequiredText(
                                              selectedVenue!.id,
                                            ),
                                          )
                                        : null,
                                    programmingItems: List<
                                            TenantAdminEventProgrammingItem>.unmodifiable(
                                        programmingItems),
                                  ),
                                ),
                              );
                            },
                            child: const Text('Salvar data'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (result == null || !mounted) {
      return;
    }
    _controller.upsertOccurrence(index: index, occurrence: result);
  }

  String? _validateOccurrenceEditor({
    required DateTime startAt,
    required DateTime? endAt,
    required bool locationOverrideEnabled,
    required String locationMode,
    required bool includesPhysical,
    required bool includesOnline,
    required TenantAdminAccountProfile? selectedVenue,
    required String onlineUrl,
  }) {
    if (endAt != null && endAt.isBefore(startAt)) {
      return 'Fim deve ser posterior ao início.';
    }
    if (!locationOverrideEnabled) {
      return null;
    }
    if (includesPhysical && selectedVenue == null) {
      return 'Host físico é obrigatório para $locationMode.';
    }
    if (includesOnline) {
      final uri = Uri.tryParse(onlineUrl.trim());
      final valid = uri != null &&
          (uri.scheme == 'http' || uri.scheme == 'https') &&
          uri.host.isNotEmpty;
      if (!valid) {
        return 'URL online da ocorrência é obrigatória e deve ser válida.';
      }
    }
    return null;
  }

  TenantAdminEventLocation _buildOccurrenceLocationOverride({
    required String mode,
    required TenantAdminAccountProfile? selectedVenue,
    required String onlineUrl,
    required String onlinePlatform,
  }) {
    final includesPhysical = mode == 'physical' || mode == 'hybrid';
    final includesOnline = mode == 'online' || mode == 'hybrid';
    final latitude =
        includesPhysical ? selectedVenue?.location?.latitude : null;
    final longitude =
        includesPhysical ? selectedVenue?.location?.longitude : null;
    return TenantAdminEventLocation(
      modeValue: tenantAdminRequiredText(mode),
      latitudeValue: tenantAdminOptionalDouble(latitude),
      longitudeValue: tenantAdminOptionalDouble(longitude),
      online: includesOnline
          ? TenantAdminEventOnlineLocation(
              urlValue: tenantAdminRequiredText(onlineUrl.trim()),
              platformValue: tenantAdminOptionalText(
                onlinePlatform.trim().isEmpty ? null : onlinePlatform.trim(),
              ),
            )
          : null,
    );
  }

  Future<TenantAdminEventProgrammingItem?> _openProgrammingItemEditor() async {
    var time = '';
    var title = '';
    final linkedProfileIds = <TenantAdminAccountProfileIdValue>[];
    final linkedProfiles = <TenantAdminAccountProfile>[];
    String? errorMessage;

    final result = await showModalBottomSheet<TenantAdminEventProgrammingItem>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            Future<void> addProfile() async {
              final selected = await _pickRelatedAccountProfile(
                excludedProfileIds: linkedProfileIds
                    .map((profileId) => profileId.value)
                    .toSet(),
              );
              if (selected == null) {
                return;
              }
              setSheetState(() {
                linkedProfileIds.add(
                  TenantAdminAccountProfileIdValue(selected.id),
                );
                linkedProfiles.removeWhere(
                  (profile) => profile.id == selected.id,
                );
                linkedProfiles.add(selected);
                errorMessage = null;
              });
            }

            return Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                16 + MediaQuery.viewInsetsOf(context).bottom,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Adicionar item de programação',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      key: const Key('tenantAdminProgrammingTimeField'),
                      initialValue: time,
                      decoration: const InputDecoration(
                        labelText: 'Horário',
                        hintText: '13:00',
                      ),
                      keyboardType: TextInputType.datetime,
                      onChanged: (value) {
                        time = value;
                        errorMessage = null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      key: const Key('tenantAdminProgrammingTitleField'),
                      initialValue: title,
                      decoration: const InputDecoration(
                        labelText: 'Título (opcional)',
                      ),
                      onChanged: (value) {
                        title = value;
                        errorMessage = null;
                      },
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Perfis vinculados',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    if (linkedProfileIds.isEmpty)
                      Text(
                        'Nenhum perfil vinculado.',
                        style: Theme.of(context).textTheme.bodySmall,
                      )
                    else
                      for (final profileId in linkedProfileIds)
                        ListTile(
                          key: Key(
                            'tenantAdminProgrammingProfile_${profileId.value}',
                          ),
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.person_outline),
                          title: Text(
                            _profileDisplayName(
                              profileId.value,
                              linkedProfiles,
                            ),
                          ),
                          trailing: IconButton(
                            tooltip: 'Remover perfil vinculado',
                            onPressed: () {
                              setSheetState(() {
                                linkedProfileIds.removeWhere(
                                  (item) => item.value == profileId.value,
                                );
                                errorMessage = null;
                              });
                            },
                            icon: const Icon(Icons.close),
                          ),
                        ),
                    OutlinedButton.icon(
                      key: const Key('tenantAdminProgrammingAddProfileButton'),
                      onPressed: addProfile,
                      icon: const Icon(Icons.add),
                      label: const Text('Vincular perfil'),
                    ),
                    if (errorMessage != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        errorMessage!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () =>
                                unawaited(_closeModalSheet<Object?>(context)),
                            child: const Text('Cancelar'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            key: const Key('tenantAdminProgrammingSaveButton'),
                            onPressed: () {
                              final normalizedTime = time.trim();
                              final normalizedTitle = title.trim();
                              final validationError = _validateProgrammingItem(
                                time: normalizedTime,
                                title: normalizedTitle,
                                linkedProfileCount: linkedProfileIds.length,
                              );
                              if (validationError != null) {
                                setSheetState(() {
                                  errorMessage = validationError;
                                });
                                return;
                              }
                              unawaited(
                                _closeModalSheet<
                                    TenantAdminEventProgrammingItem>(
                                  context,
                                  TenantAdminEventProgrammingItem(
                                    timeValue: tenantAdminRequiredText(
                                      normalizedTime,
                                    ),
                                    titleValue: tenantAdminOptionalText(
                                      normalizedTitle.isEmpty
                                          ? null
                                          : normalizedTitle,
                                    ),
                                    accountProfileIdValues: List<
                                            TenantAdminAccountProfileIdValue>.unmodifiable(
                                        linkedProfileIds),
                                    linkedAccountProfiles: List<
                                            TenantAdminAccountProfile>.unmodifiable(
                                        linkedProfiles),
                                  ),
                                ),
                              );
                            },
                            child: const Text('Salvar item'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    return result;
  }

  String? _validateProgrammingItem({
    required String time,
    required String title,
    required int linkedProfileCount,
  }) {
    if (!_isValidProgrammingTime(time)) {
      return 'Horário deve estar no formato HH:mm.';
    }
    if (title.trim().isEmpty && linkedProfileCount == 0) {
      return 'Informe um título ou vincule um perfil.';
    }
    if (title.trim().isEmpty && linkedProfileCount > 1) {
      return 'Informe um título quando houver mais de um perfil vinculado.';
    }
    return null;
  }

  bool _isValidProgrammingTime(String value) {
    final match = RegExp(r'^([01]\d|2[0-3]):([0-5]\d)$').firstMatch(value);
    return match != null;
  }

  String _profileDisplayName(
    String profileId,
    List<TenantAdminAccountProfile> profiles,
  ) {
    final profile = profiles.firstWhereOrNull((item) => item.id == profileId);
    return profile?.displayName ?? 'Perfil relacionado $profileId';
  }

  String? _firstProgrammingProfileName(TenantAdminEventProgrammingItem item) {
    if (item.linkedAccountProfiles.isEmpty) {
      return null;
    }
    return item.linkedAccountProfiles.first.displayName;
  }

  List<TenantAdminEventOccurrence> _buildOccurrencesForSubmit({
    required TenantAdminEventFormState formState,
    required DateTime startAt,
    required DateTime? endAt,
  }) {
    final source = formState.occurrences.isEmpty
        ? <TenantAdminEventOccurrence>[
            TenantAdminEventOccurrence(
              dateTimeStartValue: tenantAdminDateTime(startAt),
              dateTimeEndValue: tenantAdminOptionalDateTime(endAt),
            ),
          ]
        : formState.occurrences;

    return source
        .map(
          (occurrence) => TenantAdminEventOccurrence(
            occurrenceIdValue: tenantAdminOptionalText(occurrence.occurrenceId),
            occurrenceSlugValue: tenantAdminOptionalText(
              occurrence.occurrenceSlug,
            ),
            dateTimeStartValue: tenantAdminDateTime(
              TimezoneConverter.localToUtc(occurrence.dateTimeStart),
            ),
            dateTimeEndValue: tenantAdminOptionalDateTime(
              occurrence.dateTimeEnd == null
                  ? null
                  : TimezoneConverter.localToUtc(occurrence.dateTimeEnd!),
            ),
            relatedAccountProfileIdValues: occurrence.relatedAccountProfileIds,
            relatedAccountProfiles: occurrence.relatedAccountProfiles,
            locationOverride: occurrence.locationOverride,
            placeRef: occurrence.placeRef,
            programmingItems: occurrence.programmingItems,
          ),
        )
        .toList(growable: false);
  }

  String _formatOccurrenceDateTime(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$day/$month/${value.year} $hour:$minute';
  }

  Widget _buildDateTimeField({
    required TextEditingController controller,
    required String label,
    required Future<void> Function() onTap,
    String? Function(String?)? validator,
    VoidCallback? onClear,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (onClear != null)
              IconButton(
                tooltip: 'Limpar',
                onPressed: onClear,
                icon: const Icon(Icons.clear),
              ),
            IconButton(
              tooltip: 'Selecionar data e hora',
              onPressed: onTap,
              icon: const Icon(Icons.calendar_today_outlined),
            ),
          ],
        ),
      ),
      validator: validator,
      onTap: onTap,
    );
  }

  void _openEventTypeManagement() {
    context.router.push(const TenantAdminEventTypesRoute()).then((_) {
      if (!mounted) {
        return;
      }
      _controller.loadFormDependencies(
        accountSlug: widget.accountSlugForOwnCreate,
      );
    });
  }

  Future<void> _openRelatedAccountProfilePickerSheet({
    required TenantAdminEventFormState formState,
  }) async {
    final selectedAccountProfile = await _pickRelatedAccountProfile(
      excludedProfileIds: formState.selectedRelatedAccountProfileIds.toSet(),
    );

    if (selectedAccountProfile == null || !mounted) {
      return;
    }

    _controller.addRelatedAccountProfile(
      selectedAccountProfile.id,
      profile: selectedAccountProfile,
    );
  }

  Future<TenantAdminAccountProfile?> _pickRelatedAccountProfile({
    required Set<String> excludedProfileIds,
  }) async {
    unawaited(
      _controller.prepareAccountProfilePicker(
        candidateType:
            TenantAdminEventAccountProfileCandidateType.relatedAccountProfile,
        accountSlug: widget.accountSlugForOwnCreate,
      ),
    );

    final selectedAccountProfile =
        await showModalBottomSheet<TenantAdminAccountProfile>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            16 + MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.72,
            child: Column(
              children: [
                TextField(
                  controller: _controller.accountProfilePickerSearchController,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Buscar perfil relacionado',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: _controller.updateAccountProfilePickerSearchQuery,
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: StreamValueBuilder<String>(
                    streamValue:
                        _controller.accountProfilePickerErrorStreamValue,
                    builder: (context, searchError) {
                      return StreamValueBuilder<bool>(
                        streamValue:
                            _controller.accountProfilePickerLoadingStreamValue,
                        builder: (context, isSearchLoading) {
                          return StreamValueBuilder<bool>(
                            streamValue: _controller
                                .accountProfilePickerPageLoadingStreamValue,
                            builder: (context, isSearchPageLoading) {
                              return StreamValueBuilder<
                                  List<TenantAdminAccountProfile>>(
                                streamValue: _controller
                                    .accountProfilePickerResultsStreamValue,
                                builder: (context, searchResults) {
                                  if (isSearchLoading &&
                                      searchResults.isEmpty) {
                                    return const Center(
                                      child: CircularProgressIndicator(),
                                    );
                                  }

                                  if (searchError.isNotEmpty &&
                                      searchResults.isEmpty) {
                                    return Center(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            searchError,
                                            textAlign: TextAlign.center,
                                          ),
                                          const SizedBox(height: 12),
                                          FilledButton(
                                            onPressed: _controller
                                                .retryAccountProfilePickerSearch,
                                            child: const Text(
                                              'Tentar novamente',
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }

                                  if (searchResults.isEmpty) {
                                    return const Center(
                                      child: Text(
                                        'Nenhum perfil relacionado elegível encontrado.',
                                      ),
                                    );
                                  }

                                  final itemCount = searchResults.length +
                                      (isSearchPageLoading ? 1 : 0);

                                  return ListView.separated(
                                    key: const ValueKey<String>(
                                      'tenant-admin-related-account-profile-picker-list',
                                    ),
                                    controller: _controller
                                        .accountProfilePickerScrollController,
                                    itemCount: itemCount,
                                    separatorBuilder: (_, __) =>
                                        const SizedBox(height: 8),
                                    itemBuilder: (context, index) {
                                      if (index >= searchResults.length) {
                                        return const Padding(
                                          padding: EdgeInsets.symmetric(
                                            vertical: 12,
                                          ),
                                          child: Center(
                                            child: CircularProgressIndicator(),
                                          ),
                                        );
                                      }

                                      final profile = searchResults[index];
                                      final isAlreadySelected =
                                          excludedProfileIds.contains(
                                        profile.id,
                                      );

                                      return Card(
                                        child: ListTile(
                                          enabled: !isAlreadySelected,
                                          leading: const Icon(
                                            Icons.person_outline,
                                          ),
                                          title: Text(profile.displayName),
                                          subtitle: Text(
                                            profile.slug ?? profile.id,
                                          ),
                                          trailing: Icon(
                                            isAlreadySelected
                                                ? Icons.check_circle_outline
                                                : Icons.add_circle_outline,
                                          ),
                                          onTap: isAlreadySelected
                                              ? null
                                              : () => unawaited(
                                                    _closeModalSheet<
                                                            TenantAdminAccountProfile>(
                                                        context, profile),
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
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    return selectedAccountProfile;
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
          return 'URL obrigatória.';
        }
        final uri = Uri.tryParse(trimmed);
        final hasScheme = uri != null &&
            (uri.scheme == 'http' || uri.scheme == 'https') &&
            uri.host.isNotEmpty;
        if (!hasScheme) {
          return 'URL inválida.';
        }
        return null;
      },
    );
    return result?.value.trim();
  }

  Future<void> _pickCoverImage() async {
    final source = await showTenantAdminImageSourceSheet(
      context: context,
      title: 'Adicionar capa',
    );
    if (source == null) {
      return;
    }
    if (source == TenantAdminImageSourceOption.device) {
      await _pickCoverFromDevice();
      return;
    }
    await _pickCoverFromWeb();
  }

  Future<void> _pickCoverFromDevice() async {
    if (_controller.eventCoverBusyStreamValue.value == true) {
      return;
    }
    try {
      _controller.setEventCoverBusy(true);
      final picked = await _controller.pickImageFromDevice(
        slot: TenantAdminImageSlot.cover,
      );
      if (picked == null || !mounted) {
        return;
      }
      final cropped = await showTenantAdminImageCropSheet(
        context: context,
        sourceFile: picked,
        slot: TenantAdminImageSlot.cover,
        readBytesForCrop: _controller.readImageBytesForCrop,
        prepareCroppedFile: (croppedData, cropSlot) =>
            _controller.prepareCroppedImage(croppedData, slot: cropSlot),
      );
      if (cropped == null) {
        return;
      }
      _controller.updateEventCoverFile(cropped);
      _controller.restoreEventCover();
    } on TenantAdminImageIngestionException catch (error) {
      _controller.submitErrorMessageStreamValue.addValue(error.message);
    } finally {
      _controller.setEventCoverBusy(false);
    }
  }

  Future<void> _pickCoverFromWeb() async {
    if (_controller.eventCoverBusyStreamValue.value == true) {
      return;
    }

    final url = await _promptWebImageUrl(title: 'URL da capa');
    if (url == null || !mounted) {
      return;
    }

    try {
      _controller.setEventCoverBusy(true);
      final sourceFile = await _controller.fetchImageFromUrlForCrop(
        imageUrl: url,
      );
      if (!mounted) {
        return;
      }
      final cropped = await showTenantAdminImageCropSheet(
        context: context,
        sourceFile: sourceFile,
        slot: TenantAdminImageSlot.cover,
        readBytesForCrop: _controller.readImageBytesForCrop,
        prepareCroppedFile: (croppedData, cropSlot) =>
            _controller.prepareCroppedImage(croppedData, slot: cropSlot),
      );
      if (cropped == null) {
        return;
      }
      _controller.updateEventCoverFile(cropped);
      _controller.restoreEventCover();
    } on TenantAdminImageIngestionException catch (error) {
      _controller.submitErrorMessageStreamValue.addValue(error.message);
    } finally {
      _controller.setEventCoverBusy(false);
    }
  }

  void _clearCoverSelection({
    required bool hasExistingCover,
    required bool hasSelectedCover,
    required bool isCoverMarkedForRemoval,
  }) {
    if (isCoverMarkedForRemoval) {
      _controller.restoreEventCover();
      return;
    }
    if (hasSelectedCover) {
      _controller.updateEventCoverFile(null);
      return;
    }
    if (hasExistingCover) {
      _controller.removeEventCover();
    }
  }

  Future<void> _pickStartDateTime() async {
    final formState = _controller.eventFormStateStreamValue.value;
    final picked = await _pickDateTime(
      initialDateTime: formState.startAt ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null) {
      return;
    }
    _controller.applyEventStartAt(picked);
  }

  Future<void> _pickEndDateTime() async {
    final formState = _controller.eventFormStateStreamValue.value;
    final picked = await _pickDateTime(
      initialDateTime: formState.endAt ?? formState.startAt ?? DateTime.now(),
      firstDate: formState.startAt ?? DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null) {
      return;
    }
    _controller.applyEventEndAt(picked);
  }

  Future<void> _pickPublishAtDateTime() async {
    final formState = _controller.eventFormStateStreamValue.value;
    final picked = await _pickDateTime(
      initialDateTime: formState.publishAt ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null) {
      return;
    }
    _controller.applyEventPublishAt(picked);
  }

  Future<DateTime?> _pickDateTime({
    required DateTime initialDateTime,
    required DateTime firstDate,
    required DateTime lastDate,
  }) async {
    final firstDateOnly = DateTime(
      firstDate.year,
      firstDate.month,
      firstDate.day,
    );
    final lastDateOnly = DateTime(lastDate.year, lastDate.month, lastDate.day);
    final normalizedInitial = initialDateTime.isBefore(firstDateOnly)
        ? firstDateOnly
        : initialDateTime.isAfter(lastDateOnly)
            ? lastDateOnly
            : initialDateTime;

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime(
        normalizedInitial.year,
        normalizedInitial.month,
        normalizedInitial.day,
      ),
      firstDate: firstDateOnly,
      lastDate: lastDateOnly,
    );

    if (pickedDate == null) {
      return null;
    }

    if (!mounted) {
      return null;
    }

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(normalizedInitial),
    );

    if (pickedTime == null) {
      return null;
    }

    return DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );
  }

  Future<void> _handleSubmit({
    required List<TenantAdminAccountProfile> relatedAccountProfiles,
    required List<TenantAdminAccountProfile> venues,
    required List<TenantAdminEventType> eventTypes,
    required TenantAdminEventFormState formState,
    required XFile? selectedCover,
    required bool isCoverMarkedForRemoval,
  }) async {
    if (_submitInFlight) {
      return;
    }
    final form = _controller.eventFormKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }

    final startAt = formState.startAt ??
        _toLocalDateTime(
          _parseDateTimeFromField(_controller.eventStartController.text),
        );

    if (startAt == null) {
      return;
    }

    final endAt = formState.endAt ??
        _toLocalDateTime(
          _parseDateTimeFromField(_controller.eventEndController.text),
        );
    if (endAt != null && endAt.isBefore(startAt)) {
      return;
    }

    final publishAt = formState.publishAt ??
        _toLocalDateTime(
          _parseDateTimeFromField(_controller.eventPublishAtController.text),
        );

    final selectedType = eventTypes.firstWhereOrNull(
      (type) => type.slug.trim() == (formState.selectedTypeSlug ?? '').trim(),
    );

    if (selectedType == null) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione um tipo de evento válido.')),
      );
      return;
    }

    final selectedTypeId = selectedType.id?.trim();
    if (selectedTypeId == null || selectedTypeId.isEmpty) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Tipo de evento inválido. Selecione um tipo cadastrado no tenant.',
          ),
        ),
      );
      return;
    }

    final selectedVenue = venues.firstWhereOrNull(
      (venue) => venue.id == formState.selectedVenueId,
    );
    final knownRelatedAccountProfilesById = <String, TenantAdminAccountProfile>{
      for (final profile
          in widget.existingEvent?.relatedAccountProfiles ?? const [])
        profile.id: profile,
      for (final profile in relatedAccountProfiles) profile.id: profile,
    };
    final selectedRelatedAccountProfiles = formState
        .selectedRelatedAccountProfileIds
        .map((profileId) => knownRelatedAccountProfilesById[profileId])
        .whereType<TenantAdminAccountProfile>()
        .toList(growable: false);

    final taxonomyTerms = <TenantAdminTaxonomyTerm>[];
    formState.selectedTaxonomyTerms.forEach((taxonomySlug, termSlugs) {
      for (final termSlug in termSlugs) {
        taxonomyTerms.add(
          tenantAdminTaxonomyTermFromRaw(type: taxonomySlug, value: termSlug),
        );
      }
    });

    final location = _buildLocationFromSelection(
      selectedVenue,
      formState: formState,
    );
    _submitInFlight = true;
    var submitSucceeded = false;
    try {
      final coverUpload = await _controller.buildImageUpload(
        selectedCover,
        slot: TenantAdminImageSlot.cover,
      );
      final removeCover =
          _isEditing && selectedCover == null && isCoverMarkedForRemoval;
      final placeRef = (formState.locationMode == 'physical' ||
                  formState.locationMode == 'hybrid') &&
              selectedVenue != null
          ? TenantAdminEventPlaceRef(
              typeValue: tenantAdminRequiredText('account_profile'),
              idValue: tenantAdminRequiredText(selectedVenue.id),
            )
          : null;

      final draft = TenantAdminEventDraft(
        titleValue: tenantAdminRequiredText(
          _controller.eventTitleController.text.trim(),
        ),
        contentValue: tenantAdminOptionalText(
          _controller.eventContentController.text.trim(),
        ),
        type: TenantAdminEventType(
          idValue: tenantAdminOptionalText(selectedTypeId),
          nameValue: tenantAdminRequiredText(selectedType.name),
          slugValue: tenantAdminRequiredText(selectedType.slug),
          descriptionValue: tenantAdminOptionalText(selectedType.description),
          iconValue: tenantAdminOptionalText(selectedType.icon),
          colorValue: tenantAdminOptionalText(selectedType.color),
        ),
        occurrences: _buildOccurrencesForSubmit(
          formState: formState,
          startAt: startAt,
          endAt: endAt,
        ),
        publication: TenantAdminEventPublication(
          statusValue: tenantAdminRequiredText(formState.publicationStatus),
          publishAtValue: tenantAdminOptionalDateTime(
            formState.publicationStatus == 'publish_scheduled'
                ? publishAt == null
                    ? null
                    : TimezoneConverter.localToUtc(publishAt)
                : null,
          ),
        ),
        location: location,
        placeRef: placeRef,
        coverUpload: coverUpload,
        removeCoverValue: tenantAdminFlag(removeCover),
        relatedAccountProfileIdValues: formState
            .selectedRelatedAccountProfileIds
            .map(TenantAdminAccountProfileIdValue.new)
            .toList(growable: false),
        relatedAccountProfiles: selectedRelatedAccountProfiles,
        taxonomyTerms: (() {
          final terms = TenantAdminTaxonomyTerms();
          for (final taxonomyTerm in taxonomyTerms) {
            terms.add(taxonomyTerm);
          }
          return terms;
        })(),
      );

      final result = await (_isEditing
          ? _controller.submitUpdate(
              eventId: widget.existingEvent!.eventId,
              draft: draft,
            )
          : _controller.submitCreate(
              draft,
              accountSlug: widget.accountSlugForOwnCreate,
            ));

      if (result == null || !mounted) {
        return;
      }
      submitSucceeded = true;
      _completeSubmit(result);
    } finally {
      if (!submitSucceeded) {
        _submitInFlight = false;
      }
    }
  }

  void _completeSubmit(TenantAdminEvent result) {
    context.router.maybePop<TenantAdminEvent>(result);
  }

  TenantAdminEventLocation _buildLocationFromSelection(
    TenantAdminAccountProfile? selectedVenue, {
    required TenantAdminEventFormState formState,
  }) {
    final onlineUrl = _controller.eventOnlineUrlController.text.trim();
    final onlinePlatform =
        _controller.eventOnlinePlatformController.text.trim();

    final online = (formState.locationMode == 'online' ||
            formState.locationMode == 'hybrid')
        ? TenantAdminEventOnlineLocation(
            urlValue: tenantAdminRequiredText(onlineUrl),
            platformValue: tenantAdminOptionalText(
              onlinePlatform.isEmpty ? null : onlinePlatform,
            ),
          )
        : null;

    final includesPhysicalVenue = formState.locationMode == 'physical' ||
        formState.locationMode == 'hybrid';
    final latitude =
        includesPhysicalVenue ? selectedVenue?.location?.latitude : null;
    final longitude =
        includesPhysicalVenue ? selectedVenue?.location?.longitude : null;

    return TenantAdminEventLocation(
      modeValue: tenantAdminRequiredText(formState.locationMode),
      latitudeValue: tenantAdminOptionalDouble(latitude),
      longitudeValue: tenantAdminOptionalDouble(longitude),
      online: online,
    );
  }

  DateTime? _parseDateTimeFromField(String rawValue) {
    final trimmed = rawValue.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    final normalized =
        trimmed.contains('T') ? trimmed : trimmed.replaceFirst(' ', 'T');
    return DateTime.tryParse(normalized);
  }

  DateTime? _toLocalDateTime(DateTime? value) {
    if (value == null) {
      return null;
    }
    return TimezoneConverter.utcToLocal(value);
  }
}

class _OccurrenceSummaryChip extends StatelessWidget {
  const _OccurrenceSummaryChip({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [Icon(icon, size: 14), const SizedBox(width: 6), Text(label)],
      ),
    );
  }
}

extension _IterableFirstWhereOrNull<E> on Iterable<E> {
  E? firstWhereOrNull(bool Function(E element) matcher) {
    for (final element in this) {
      if (matcher(element)) {
        return element;
      }
    }
    return null;
  }
}
