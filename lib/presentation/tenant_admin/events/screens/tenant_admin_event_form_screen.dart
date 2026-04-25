import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/rich_text/tenant_admin_rich_text_limits.dart';
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
import 'package:belluga_now/presentation/tenant_admin/events/controllers/tenant_admin_event_occurrence_editor_draft.dart';
import 'package:belluga_now/presentation/tenant_admin/events/controllers/tenant_admin_events_controller.dart';
import 'package:belluga_now/presentation/tenant_admin/events/widgets/tenant_admin_event_occurrence_editor_sheet.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/utils/tenant_admin_image_ingestion_service.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/widgets/tenant_admin_error_banner.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/widgets/tenant_admin_field_edit_sheet.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/widgets/tenant_admin_form_layout.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/widgets/tenant_admin_image_crop_sheet.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/widgets/tenant_admin_image_source_sheet.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/widgets/tenant_admin_image_upload_field.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/widgets/tenant_admin_confirmation_dialog.dart';
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
    return _TenantAdminEventFormStateScope(
      controller: _controller,
      builder: _buildFormScaffold,
    );
  }

  Widget _buildFormScaffold(
    BuildContext context,
    _TenantAdminEventFormViewModel viewModel,
  ) {
    final formState = viewModel.formState;
    final allowedTaxonomies = _allowedTaxonomyDefinitions(
      taxonomies: viewModel.taxonomies,
      eventTypes: viewModel.eventTypes,
      formState: formState,
    );

    return TenantAdminFormScaffold(
      closePolicy: buildTenantAdminCurrentRouteBackPolicy(
        context,
        consumeBackNavigationIfNeeded: _confirmDiscardChangesIfNeeded,
      ),
      title: _isEditing ? 'Editar evento' : 'Criar evento',
      showHandle: false,
      floatingActionButton: _buildAddOccurrenceFloatingActionButton(
        formState: formState,
        venues: viewModel.venues,
        isSubmitting: viewModel.isSubmitting,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      child: Form(
        key: _controller.eventFormKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (viewModel.submitError?.isNotEmpty ?? false)
                TenantAdminErrorBanner(
                  rawError: viewModel.submitError ?? '',
                  fallbackMessage: 'Falha ao salvar evento.',
                  onRetry: _controller.clearSubmitMessages,
                ),
              if (viewModel.partyCandidatesLoading)
                const Padding(
                  padding: EdgeInsets.only(top: 8, bottom: 8),
                  child: LinearProgressIndicator(),
                ),
              if (viewModel.partyCandidatesError?.isNotEmpty ?? false)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: TenantAdminErrorBanner(
                    rawError: viewModel.partyCandidatesError ?? '',
                    fallbackMessage:
                        'Falha ao carregar hosts físicos e perfis relacionados.',
                    onRetry: () => _controller.loadFormDependencies(
                      accountSlug: widget.accountSlugForOwnCreate,
                    ),
                  ),
                ),
              _buildBasicSection(),
              const SizedBox(height: 16),
              _buildCoverSection(
                selectedCover: viewModel.selectedCover,
                isCoverBusy: viewModel.isCoverBusy,
                isCoverMarkedForRemoval: viewModel.isCoverMarkedForRemoval,
                isSubmitting: viewModel.isSubmitting,
              ),
              const SizedBox(height: 16),
              _buildTypeSection(viewModel.eventTypes, formState: formState),
              const SizedBox(height: 16),
              _buildScheduleSection(
                formState: formState,
                venues: viewModel.venues,
              ),
              const SizedBox(height: 16),
              _buildPublicationSection(formState: formState),
              const SizedBox(height: 16),
              _buildLocationSection(viewModel.venues, formState: formState),
              const SizedBox(height: 16),
              _buildRelatedAccountProfilesSection(
                viewModel.relatedAccountProfiles,
                formState: formState,
              ),
              if (formState.occurrences.length <= 1) ...[
                const SizedBox(height: 16),
                _buildPrimaryOccurrenceProgrammingSection(
                  formState: formState,
                  venues: viewModel.venues,
                ),
              ],
              ..._buildTaxonomySectionEntries(
                taxonomies: allowedTaxonomies,
                termsBySlug: viewModel.termsBySlug,
                formState: formState,
              ),
              const SizedBox(height: 24),
              TenantAdminPrimaryFormAction(
                label: _isEditing ? 'Salvar alterações' : 'Criar evento',
                onPressed: viewModel.isSubmitting
                    ? null
                    : () => _handleSubmit(
                          relatedAccountProfiles:
                              viewModel.relatedAccountProfiles,
                          venues: viewModel.venues,
                          eventTypes: viewModel.eventTypes,
                          formState: formState,
                          selectedCover: viewModel.selectedCover,
                          isCoverMarkedForRemoval:
                              viewModel.isCoverMarkedForRemoval,
                        ),
                isLoading: viewModel.isSubmitting,
              ),
            ],
          ),
        ),
      ),
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
            minHeight: 280,
            maxContentBytes: tenantAdminRichTextMaxBytes,
            warningThreshold: tenantAdminRichTextWarningThreshold,
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

  Widget _buildPrimaryOccurrenceProgrammingSection({
    required TenantAdminEventFormState formState,
    required List<TenantAdminAccountProfile> venues,
  }) {
    final primaryOccurrence =
        formState.occurrences.isEmpty ? null : formState.occurrences.first;
    final canEditProgramming =
        formState.startAt != null || primaryOccurrence != null;
    final occurrenceKey = _controller.primaryOccurrenceKey();
    final programmingItems = occurrenceKey == null
        ? const <MapEntry<String, TenantAdminEventProgrammingItem>>[]
        : _controller.programmingItemsForOccurrenceKey(occurrenceKey);

    Future<void> addProgrammingItem() async {
      if (!canEditProgramming) {
        return;
      }
      final resolvedOccurrenceKey =
          occurrenceKey ?? _controller.ensurePrimaryOccurrenceDraft();
      await showTenantAdminEventProgrammingItemEditorSheet(
        context: context,
        controller: _controller,
        occurrenceKey: resolvedOccurrenceKey,
        venues: venues,
        pickRelatedAccountProfile: _pickRelatedAccountProfile,
        closeModalSheet: _closeModalSheet,
      );
    }

    Future<void> editProgrammingItem({
      required String itemKey,
      required TenantAdminEventProgrammingItem item,
    }) async {
      final resolvedOccurrenceKey = occurrenceKey;
      if (resolvedOccurrenceKey == null) {
        return;
      }
      await showTenantAdminEventProgrammingItemEditorSheet(
        context: context,
        controller: _controller,
        occurrenceKey: resolvedOccurrenceKey,
        venues: venues,
        pickRelatedAccountProfile: _pickRelatedAccountProfile,
        closeModalSheet: _closeModalSheet,
        itemKey: itemKey,
        existing: item,
      );
    }

    void removeProgrammingItem(String itemKey) {
      final resolvedOccurrenceKey = occurrenceKey;
      if (resolvedOccurrenceKey == null) {
        return;
      }
      _controller.removeOccurrenceProgrammingItem(
        occurrenceKey: resolvedOccurrenceKey,
        itemKey: itemKey,
      );
    }

    return KeyedSubtree(
      key: const Key('tenantAdminPrimaryOccurrenceProgrammingSection'),
      child: TenantAdminFormSectionCard(
        title: 'Programação',
        description:
            'Enquanto o evento tiver só uma ocorrência, a programação dessa data fica visível aqui na raiz do formulário.',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!canEditProgramming)
              Text(
                'Defina a primeira data do evento para liberar a programação.',
                style: Theme.of(context).textTheme.bodySmall,
              )
            else if (programmingItems.isEmpty)
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
                    'tenantAdminPrimaryOccurrenceProgrammingItem_$itemIndex',
                  ),
                  contentPadding: EdgeInsets.zero,
                  onTap: () => editProgrammingItem(
                    itemKey: programmingItems[itemIndex].key,
                    item: programmingItems[itemIndex].value,
                  ),
                  leading: Text(programmingItems[itemIndex].value.time),
                  title: Text(
                    programmingItems[itemIndex].value.title ??
                        TenantAdminEventOccurrenceEditorDraft
                            .firstProgrammingProfileName(
                          programmingItems[itemIndex].value,
                        ) ??
                        'Item sem título',
                  ),
                  subtitle: _buildProgrammingItemSubtitle(
                    programmingItems[itemIndex].value,
                    venues,
                  ),
                  trailing: IconButton(
                    tooltip: 'Remover item de programação',
                    onPressed: () => removeProgrammingItem(
                      programmingItems[itemIndex].key,
                    ),
                    icon: const Icon(Icons.close),
                  ),
                ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              key:
                  const Key('tenantAdminPrimaryOccurrenceAddProgrammingButton'),
              onPressed: canEditProgramming ? addProgrammingItem : null,
              icon: const Icon(Icons.add),
              label: const Text('Adicionar item de programação'),
            ),
          ],
        ),
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
      key: Key('tenantAdminRelatedProfileChip_$profileId'),
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
    return TenantAdminFormSectionCard(
      title: 'Taxonomias',
      description: 'Termos permitidos para o tipo de evento selecionado.',
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

  List<Widget> _buildTaxonomySectionEntries({
    required List<TenantAdminTaxonomyDefinition> taxonomies,
    required Map<String, List<TenantAdminTaxonomyTermDefinition>> termsBySlug,
    required TenantAdminEventFormState formState,
  }) {
    final visibleTaxonomies = taxonomies
        .where(
          (taxonomy) => (termsBySlug[taxonomy.slug] ??
                  const <TenantAdminTaxonomyTermDefinition>[])
              .isNotEmpty,
        )
        .toList(growable: false);
    if (visibleTaxonomies.isEmpty) {
      return const <Widget>[];
    }

    return <Widget>[
      const SizedBox(height: 16),
      _buildTaxonomySection(
        taxonomies: visibleTaxonomies,
        termsBySlug: termsBySlug,
        formState: formState,
      ),
    ];
  }

  Future<void> _openOccurrenceEditor({
    required int? index,
    required List<TenantAdminAccountProfile> venues,
  }) async {
    final occurrenceKey = index == null
        ? _controller.createOccurrenceDraft()
        : _controller.occurrenceKeyAt(index);
    if (occurrenceKey == null) {
      return;
    }

    await showTenantAdminEventOccurrenceEditorSheet(
      context: context,
      controller: _controller,
      occurrenceKey: occurrenceKey,
      title: index == null ? 'Adicionar data' : 'Editar data',
      venues: venues,
      pickDateTime: _pickDateTime,
      pickRelatedAccountProfile: _pickRelatedAccountProfile,
      closeModalSheet: _closeModalSheet,
    );
  }

  Future<bool> _confirmDiscardChangesIfNeeded() async {
    if (!_controller.isEventFormDirty) {
      return false;
    }
    final discard = await showTenantAdminConfirmationDialog(
      context: context,
      title: 'Sair sem salvar?',
      message: 'As alterações neste evento ainda não foram salvas.',
      confirmLabel: 'Sair sem salvar',
      cancelLabel: 'Continuar editando',
      isDestructive: true,
    );
    return !discard;
  }

  Widget _buildProgrammingItemSubtitle(
    TenantAdminEventProgrammingItem item,
    List<TenantAdminAccountProfile> venues,
  ) {
    final locationLabel =
        TenantAdminEventOccurrenceEditorDraft.programmingLocationDisplayName(
      item,
      venues,
    );
    final lines = <String>[
      '${item.accountProfileIds.length} perfil(is) vinculado(s)',
      if (locationLabel != null) 'Local: $locationLabel',
    ];
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lines
          .map(
            (line) => Text(
              line,
              overflow: TextOverflow.ellipsis,
            ),
          )
          .toList(growable: false),
    );
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
    final allowedTaxonomySlugs = _allowedTaxonomySlugsForSelectedType(
      eventTypes: eventTypes,
      formState: formState,
    );
    formState.selectedTaxonomyTerms.forEach((taxonomySlug, termSlugs) {
      if (!allowedTaxonomySlugs.contains(taxonomySlug.trim())) {
        return;
      }
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

  Set<String> _allowedTaxonomySlugsForSelectedType({
    required List<TenantAdminEventType> eventTypes,
    required TenantAdminEventFormState formState,
  }) {
    final selectedTypeSlug = formState.selectedTypeSlug?.trim();
    if (selectedTypeSlug == null || selectedTypeSlug.isEmpty) {
      return const <String>{};
    }
    final selectedType = eventTypes.firstWhereOrNull(
      (type) => type.slug.trim() == selectedTypeSlug,
    );
    if (selectedType == null) {
      return const <String>{};
    }
    return selectedType.allowedTaxonomies.value
        .map((slug) => slug.trim())
        .where((slug) => slug.isNotEmpty)
        .toSet();
  }

  List<TenantAdminTaxonomyDefinition> _allowedTaxonomyDefinitions({
    required List<TenantAdminTaxonomyDefinition> taxonomies,
    required List<TenantAdminEventType> eventTypes,
    required TenantAdminEventFormState formState,
  }) {
    final allowed = _allowedTaxonomySlugsForSelectedType(
      eventTypes: eventTypes,
      formState: formState,
    );
    if (allowed.isEmpty) {
      return const <TenantAdminTaxonomyDefinition>[];
    }
    return taxonomies
        .where((taxonomy) => allowed.contains(taxonomy.slug.trim()))
        .toList(growable: false);
  }
}

class _TenantAdminEventFormViewModel {
  const _TenantAdminEventFormViewModel({
    required this.formState,
    required this.submitError,
    required this.isSubmitting,
    required this.venues,
    required this.partyCandidatesLoading,
    required this.partyCandidatesError,
    required this.relatedAccountProfiles,
    required this.eventTypes,
    required this.taxonomies,
    required this.termsBySlug,
    required this.selectedCover,
    required this.isCoverBusy,
    required this.isCoverMarkedForRemoval,
  });

  final TenantAdminEventFormState formState;
  final String? submitError;
  final bool isSubmitting;
  final List<TenantAdminAccountProfile> venues;
  final bool partyCandidatesLoading;
  final String? partyCandidatesError;
  final List<TenantAdminAccountProfile> relatedAccountProfiles;
  final List<TenantAdminEventType> eventTypes;
  final List<TenantAdminTaxonomyDefinition> taxonomies;
  final Map<String, List<TenantAdminTaxonomyTermDefinition>> termsBySlug;
  final XFile? selectedCover;
  final bool isCoverBusy;
  final bool isCoverMarkedForRemoval;
}

class _TenantAdminEventFormStateScope extends StatelessWidget {
  const _TenantAdminEventFormStateScope({
    required this.controller,
    required this.builder,
  });

  final TenantAdminEventsController controller;
  final Widget Function(
    BuildContext context,
    _TenantAdminEventFormViewModel viewModel,
  ) builder;

  @override
  Widget build(BuildContext context) {
    return StreamValueBuilder<TenantAdminEventFormState>(
      streamValue: controller.eventFormStateStreamValue,
      builder: (context, formState) {
        return StreamValueBuilder<String?>(
          streamValue: controller.submitErrorMessageStreamValue,
          builder: (context, submitError) {
            return StreamValueBuilder<bool>(
              streamValue: controller.submitLoadingStreamValue,
              builder: (context, isSubmitting) {
                return StreamValueBuilder<List<TenantAdminAccountProfile>>(
                  streamValue: controller.venueCandidatesStreamValue,
                  builder: (context, venues) {
                    return StreamValueBuilder<bool>(
                      streamValue:
                          controller.accountProfileCandidatesLoadingStreamValue,
                      builder: (context, partyCandidatesLoading) {
                        return StreamValueBuilder<String?>(
                          streamValue: controller
                              .accountProfileCandidatesErrorStreamValue,
                          builder: (context, partyCandidatesError) {
                            return StreamValueBuilder<
                                List<TenantAdminAccountProfile>>(
                              streamValue: controller
                                  .relatedAccountProfileCandidatesStreamValue,
                              builder: (context, relatedAccountProfiles) {
                                return StreamValueBuilder<
                                    List<TenantAdminEventType>>(
                                  streamValue:
                                      controller.eventTypeCatalogStreamValue,
                                  builder: (context, eventTypes) {
                                    return StreamValueBuilder<
                                        List<TenantAdminTaxonomyDefinition>>(
                                      streamValue:
                                          controller.taxonomiesStreamValue,
                                      builder: (context, taxonomies) {
                                        return StreamValueBuilder<
                                            Map<
                                                String,
                                                List<
                                                    TenantAdminTaxonomyTermDefinition>>>(
                                          streamValue: controller
                                              .taxonomyTermsBySlugStreamValue,
                                          builder: (context, termsBySlug) {
                                            return StreamValueBuilder<XFile?>(
                                              streamValue: controller
                                                  .eventCoverFileStreamValue,
                                              builder:
                                                  (context, selectedCover) {
                                                return StreamValueBuilder<bool>(
                                                  streamValue: controller
                                                      .eventCoverBusyStreamValue,
                                                  builder:
                                                      (context, isCoverBusy) {
                                                    return StreamValueBuilder<
                                                        bool>(
                                                      streamValue: controller
                                                          .eventCoverRemoveStreamValue,
                                                      builder: (
                                                        context,
                                                        isCoverMarkedForRemoval,
                                                      ) {
                                                        return builder(
                                                          context,
                                                          _TenantAdminEventFormViewModel(
                                                            formState:
                                                                formState,
                                                            submitError:
                                                                submitError,
                                                            isSubmitting:
                                                                isSubmitting,
                                                            venues: venues,
                                                            partyCandidatesLoading:
                                                                partyCandidatesLoading,
                                                            partyCandidatesError:
                                                                partyCandidatesError,
                                                            relatedAccountProfiles:
                                                                relatedAccountProfiles,
                                                            eventTypes:
                                                                eventTypes,
                                                            taxonomies:
                                                                taxonomies,
                                                            termsBySlug:
                                                                termsBySlug,
                                                            selectedCover:
                                                                selectedCover,
                                                            isCoverBusy:
                                                                isCoverBusy,
                                                            isCoverMarkedForRemoval:
                                                                isCoverMarkedForRemoval,
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
