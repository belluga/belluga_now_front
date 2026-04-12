import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/application/time/timezone_converter.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_account_profile.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_event.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_event_account_profile_candidate_type.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_event_temporal_bucket.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_legacy_event_parties_summary.dart';
import 'package:belluga_now/presentation/shared/widgets/belluga_network_image.dart';
import 'package:belluga_now/presentation/tenant_admin/events/controllers/tenant_admin_events_controller.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/widgets/tenant_admin_confirmation_dialog.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/widgets/tenant_admin_empty_state.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/widgets/tenant_admin_error_banner.dart';
import 'package:flutter/foundation.dart' show setEquals;
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value_builder.dart';

class TenantAdminEventsScreen extends StatefulWidget {
  const TenantAdminEventsScreen({super.key});

  @override
  State<TenantAdminEventsScreen> createState() =>
      _TenantAdminEventsScreenState();
}

class _TenantAdminEventsScreenState extends State<TenantAdminEventsScreen> {
  final TenantAdminEventsController _controller =
      GetIt.I.get<TenantAdminEventsController>();

  @override
  void initState() {
    super.initState();
    _controller.eventsScrollController.addListener(_handleScroll);
    _controller.loadEvents();
  }

  @override
  void dispose() {
    _controller.eventsScrollController.removeListener(_handleScroll);
    super.dispose();
  }

  void _handleScroll() {
    if (!_controller.eventsScrollController.hasClients) {
      return;
    }
    final position = _controller.eventsScrollController.position;
    const threshold = 320.0;
    if (position.pixels + threshold >= position.maxScrollExtent) {
      _controller.loadNextEventsPage();
    }
  }

  void _openCreateForm() {
    context.router
        .push<TenantAdminEvent>(
      const TenantAdminEventCreateRoute(),
    )
        .then((created) {
      if (created == null || !mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Evento criado com sucesso.')),
      );
    });
  }

  void _openEditForm(TenantAdminEvent event) {
    context.router
        .push<TenantAdminEvent>(
      TenantAdminEventEditRoute(event: event),
    )
        .then((updated) {
      if (updated == null || !mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Evento atualizado com sucesso.')),
      );
    });
  }

  Future<void> _confirmDelete(TenantAdminEvent event) async {
    final confirmed = await showTenantAdminConfirmationDialog(
      context: context,
      title: 'Remover evento',
      message: 'Remover "${event.title}"?',
      confirmLabel: 'Remover',
      isDestructive: true,
    );

    if (!confirmed) {
      return;
    }

    try {
      await _controller.deleteEvent(event.eventId);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Evento removido.')),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Falha ao remover evento. Tente novamente.'),
        ),
      );
    }
  }

  void _openEventTypes() {
    context.router.push(const TenantAdminEventTypesRoute()).then((_) {
      if (!mounted) {
        return;
      }
      _controller.loadFormDependencies();
    });
  }

  Future<void> _openLegacyEventsDialog() async {
    TenantAdminLegacyEventPartiesSummary? summary;
    String? errorMessage;

    try {
      summary = await _controller.inspectLegacyEventParties();
    } catch (_) {
      errorMessage = 'Falha ao verificar eventos legados.';
    }

    if (!mounted) {
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (_) {
        var currentSummary = summary;
        var currentError = errorMessage;
        var isBusy = false;

        return StatefulBuilder(
          builder: (context, setState) {
            Future<void> repairWithState() async {
              setState(() {
                isBusy = true;
                currentError = null;
              });
              try {
                currentSummary = await _controller.repairLegacyEventParties();
              } catch (_) {
                currentError = 'Falha ao corrigir eventos legados.';
              } finally {
                if (context.mounted) {
                  setState(() {
                    isBusy = false;
                  });
                }
              }
            }

            final content = currentError != null
                ? Text(currentError!)
                : currentSummary == null
                    ? const SizedBox(
                        height: 64,
                        child: Center(child: CircularProgressIndicator()),
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Escaneados: ${currentSummary!.scanned}'),
                          Text('Inválidos: ${currentSummary!.invalid}'),
                          Text('Corrigidos: ${currentSummary!.repaired}'),
                          Text('Sem mudança: ${currentSummary!.unchanged}'),
                          Text('Falhas: ${currentSummary!.failed}'),
                        ],
                      );

            return AlertDialog(
              title: const Text('Eventos legados'),
              content: content,
              actions: [
                TextButton(
                  onPressed: isBusy ? null : () => context.router.maybePop(),
                  child: const Text('Fechar'),
                ),
                if (currentError == null &&
                    currentSummary != null &&
                    currentSummary!.invalid > 0)
                  FilledButton(
                    key: const ValueKey<String>(
                      'tenant-admin-events-repair-legacy-button',
                    ),
                    onPressed: isBusy ? null : repairWithState,
                    child: Text(
                      isBusy
                          ? 'Corrigindo...'
                          : 'Corrigir ${currentSummary!.invalid}',
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _openSpecificDateFilterPicker() async {
    final now = DateTime.now();
    final selectedDate = _controller.specificDateFilterStreamValue.value;
    final picked = await showDatePicker(
      context: context,
      locale: Localizations.localeOf(context),
      initialDate: selectedDate ?? now,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
    );

    if (picked == null) {
      return;
    }

    _controller.selectSpecificDateFilter(picked);
    await _controller.applyFilters();
  }

  Future<void> _openVenueFilterPicker() async {
    final selected = await _openAccountProfileFilterPicker(
      title: 'Filtrar por local',
      emptyMessage: 'Nenhum local elegível encontrado.',
      candidateType: TenantAdminEventAccountProfileCandidateType.physicalHost,
    );

    if (selected == null) {
      return;
    }

    _controller.selectVenueFilter(selected);
    await _controller.applyFilters();
  }

  Future<void> _openRelatedAccountProfileFilterPicker() async {
    final selected = await _openAccountProfileFilterPicker(
      title: 'Filtrar por perfil relacionado',
      emptyMessage: 'Nenhum perfil relacionado elegível encontrado.',
      candidateType:
          TenantAdminEventAccountProfileCandidateType.relatedAccountProfile,
    );

    if (selected == null) {
      return;
    }

    _controller.selectRelatedAccountProfileFilter(selected);
    await _controller.applyFilters();
  }

  Future<TenantAdminAccountProfile?> _openAccountProfileFilterPicker({
    required String title,
    required String emptyMessage,
    required TenantAdminEventAccountProfileCandidateType candidateType,
  }) async {
    unawaited(
      _controller.prepareAccountProfilePicker(candidateType: candidateType),
    );

    return showModalBottomSheet<TenantAdminAccountProfile>(
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _controller.accountProfilePickerSearchController,
                  decoration: const InputDecoration(
                    labelText: 'Buscar perfil',
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
                                            child:
                                                const Text('Tentar novamente'),
                                          ),
                                        ],
                                      ),
                                    );
                                  }

                                  if (searchResults.isEmpty) {
                                    return Center(
                                      child: Text(emptyMessage),
                                    );
                                  }

                                  final itemCount = searchResults.length +
                                      (isSearchPageLoading ? 1 : 0);

                                  return ListView.separated(
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
                                      return Card(
                                        child: ListTile(
                                          leading: Icon(
                                            candidateType ==
                                                    TenantAdminEventAccountProfileCandidateType
                                                        .physicalHost
                                                ? Icons.location_on_outlined
                                                : Icons.person_outline,
                                          ),
                                          title: Text(profile.displayName),
                                          subtitle: Text(
                                            profile.slug ?? profile.profileType,
                                          ),
                                          onTap: () => context.router.maybePop(
                                            profile,
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
  }

  String _formatDateTime(BuildContext context, DateTime? value) {
    if (value == null) {
      return '-';
    }

    final local = TimezoneConverter.utcToLocal(value);
    final localizations = MaterialLocalizations.of(context);
    final date = localizations.formatShortDate(local);
    final time = localizations.formatTimeOfDay(
      TimeOfDay.fromDateTime(local),
      alwaysUse24HourFormat: true,
    );

    return '$date $time';
  }

  String _formatDateOnly(BuildContext context, DateTime value) {
    final localizations = MaterialLocalizations.of(context);
    return localizations.formatMediumDate(value);
  }

  String _buildDateKey(DateTime value) {
    final year = value.year.toString().padLeft(4, '0');
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  String _buildSectionLabel(BuildContext context, DateTime date) {
    return _formatDateOnly(context, date).toUpperCase();
  }

  String? _buildSectionTag(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final yesterday = today.subtract(const Duration(days: 1));

    if (date == today) {
      return 'HOJE';
    }
    if (date == tomorrow) {
      return 'AMANHÃ';
    }
    if (date == yesterday) {
      return 'ONTEM';
    }
    return null;
  }

  TenantAdminEventOccurrence? _resolvePrimaryOccurrence(
      TenantAdminEvent event) {
    if (event.occurrences.isEmpty) {
      return null;
    }
    return event.occurrences.first;
  }

  List<_TenantAdminEventSection> _buildSections(
    BuildContext context,
    List<TenantAdminEvent> events,
  ) {
    final sections = <_TenantAdminEventSection>[];
    final indexByKey = <String, int>{};

    for (final event in events) {
      final occurrence = _resolvePrimaryOccurrence(event);
      final baseDateTime = occurrence?.dateTimeStart ?? event.updatedAt;
      if (baseDateTime == null) {
        continue;
      }

      final localDate = DateUtils.dateOnly(
        TimezoneConverter.utcToLocal(baseDateTime),
      );
      final key = _buildDateKey(localDate);
      final sectionIndex = indexByKey[key];
      if (sectionIndex == null) {
        indexByKey[key] = sections.length;
        sections.add(
          _TenantAdminEventSection(
            key: key,
            label: _buildSectionLabel(context, localDate),
            tag: _buildSectionTag(localDate),
            items: <TenantAdminEvent>[event],
          ),
        );
        continue;
      }

      sections[sectionIndex].items.add(event);
    }

    return sections;
  }

  String _buildPublicationLabel(BuildContext context, TenantAdminEvent event) {
    final status = _humanizePublicationStatus(event.publication.status);
    final publishAt = event.publication.publishAt;
    if (publishAt == null) {
      return status;
    }

    return '$status • ${_formatDateTime(context, publishAt)}';
  }

  String _buildEventMetaLabel(
    BuildContext context,
    TenantAdminEvent event,
    TenantAdminEventOccurrence? occurrence,
  ) {
    if (occurrence == null) {
      return event.type.name.toUpperCase();
    }

    final start = TimezoneConverter.utcToLocal(occurrence.dateTimeStart);
    final localizations = MaterialLocalizations.of(context);
    final startDate = localizations.formatShortDate(start);
    final startTime = localizations.formatTimeOfDay(
      TimeOfDay.fromDateTime(start),
      alwaysUse24HourFormat: true,
    );
    final end = occurrence.dateTimeEnd == null
        ? null
        : TimezoneConverter.utcToLocal(occurrence.dateTimeEnd!);
    final rangeLabel = end == null
        ? startTime
        : '$startTime - ${localizations.formatTimeOfDay(
            TimeOfDay.fromDateTime(end),
            alwaysUse24HourFormat: true,
          )}';

    return '$startDate • $rangeLabel'.toUpperCase();
  }

  String _humanizePublicationStatus(String rawStatus) {
    return switch (rawStatus) {
      'published' => 'Publicado',
      'publish_scheduled' => 'Agendado',
      'ended' => 'Encerrado',
      'draft' => 'Rascunho',
      _ => rawStatus.trim().isEmpty ? 'Rascunho' : rawStatus,
    };
  }

  String _buildVenueLabel(TenantAdminEvent event) {
    return event.venueDisplayName ??
        event.placeRef?.id ??
        'Local não informado';
  }

  String _buildSpecificDateFilterLabel(
    BuildContext context,
    DateTime? selectedDate,
  ) {
    if (selectedDate == null) {
      return 'Filtrar data';
    }
    return _formatDateOnly(context, selectedDate);
  }

  VoidCallback? _buildClearSpecificDateFilterCallback(DateTime? selectedDate) {
    if (selectedDate == null) {
      return null;
    }

    return () {
      _controller.clearSpecificDateFilter();
      _controller.applyFilters();
    };
  }

  VoidCallback? _buildClearVenueFilterCallback(
    TenantAdminAccountProfile? selectedVenue,
  ) {
    if (selectedVenue == null) {
      return null;
    }

    return () {
      _controller.clearVenueFilter();
      _controller.applyFilters();
    };
  }

  VoidCallback? _buildClearRelatedProfileFilterCallback(
    TenantAdminAccountProfile? selectedProfile,
  ) {
    if (selectedProfile == null) {
      return null;
    }

    return () {
      _controller.clearRelatedAccountProfileFilter();
      _controller.applyFilters();
    };
  }

  Widget _buildDateDivider(
    BuildContext context,
    _TenantAdminEventSection section,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      key: ValueKey<String>('tenant-admin-events-date-section-${section.key}'),
      padding: const EdgeInsets.only(top: 8, bottom: 20),
      child: Column(
        children: [
          if (section.tag != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Text(
                  section.tag!,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: colorScheme.onSecondaryContainer,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Divider(
                  color: colorScheme.primary.withValues(alpha: 0.3),
                  thickness: 1.5,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  section.label,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.3,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                child: Divider(
                  color: colorScheme.primary.withValues(alpha: 0.3),
                  thickness: 1.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _clearAllFilters() async {
    _controller.resetEventFilters();
    await _controller.applyFilters();
  }

  Widget _buildFilterControls() {
    final specificDateFilter = StreamValueBuilder<DateTime?>(
      streamValue: _controller.specificDateFilterStreamValue,
      builder: (context, selectedDate) {
        return InputChip(
          key: const ValueKey<String>('tenant-admin-events-date-filter-button'),
          avatar: const Icon(Icons.calendar_today_outlined),
          label: Text(_buildSpecificDateFilterLabel(context, selectedDate)),
          onPressed: _openSpecificDateFilterPicker,
          onDeleted: _buildClearSpecificDateFilterCallback(selectedDate),
        );
      },
    );

    final venueFilter = StreamValueBuilder<TenantAdminAccountProfile?>(
      streamValue: _controller.venueFilterStreamValue,
      builder: (context, selectedVenue) {
        return InputChip(
          key:
              const ValueKey<String>('tenant-admin-events-venue-filter-button'),
          avatar: const Icon(Icons.location_on_outlined),
          label: Text(selectedVenue?.displayName ?? 'Filtrar local'),
          onPressed: _openVenueFilterPicker,
          onDeleted: _buildClearVenueFilterCallback(selectedVenue),
        );
      },
    );

    final relatedProfileFilter = StreamValueBuilder<TenantAdminAccountProfile?>(
      streamValue: _controller.relatedAccountProfileFilterStreamValue,
      builder: (context, selectedProfile) {
        return InputChip(
          key: const ValueKey<String>(
            'tenant-admin-events-related-filter-button',
          ),
          avatar: const Icon(Icons.person_outline),
          label: Text(
            selectedProfile?.displayName ?? 'Filtrar perfil relacionado',
          ),
          onPressed: _openRelatedAccountProfileFilterPicker,
          onDeleted: _buildClearRelatedProfileFilterCallback(selectedProfile),
        );
      },
    );

    final temporalFilter =
        StreamValueBuilder<Set<TenantAdminEventTemporalBucket>>(
      streamValue: _controller.temporalFilterStreamValue,
      builder: (context, selectedBuckets) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Temporalidade',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: TenantAdminEventTemporalBucket.values
                  .map(
                    (bucket) => FilterChip(
                      key: ValueKey<String>(
                        'tenant-admin-events-temporal-${bucket.apiValue}',
                      ),
                      label: Text(bucket.label),
                      selected: selectedBuckets.contains(bucket),
                      onSelected: (_) {
                        _controller.toggleTemporalFilter(bucket);
                        _controller.applyFilters();
                      },
                    ),
                  )
                  .toList(growable: false),
            ),
          ],
        );
      },
    );

    final filterChips = Wrap(
      spacing: 12,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        specificDateFilter,
        venueFilter,
        relatedProfileFilter,
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        filterChips,
        const SizedBox(height: 12),
        temporalFilter,
      ],
    );
  }

  Widget _buildActionButtons({required bool isCompactLayout}) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        OutlinedButton.icon(
          onPressed: _openEventTypes,
          icon: const Icon(Icons.category_outlined),
          label: Text(isCompactLayout ? 'Tipos de evento' : 'Tipos'),
        ),
        OutlinedButton.icon(
          key:
              const ValueKey<String>('tenant-admin-events-legacy-check-button'),
          onPressed: _openLegacyEventsDialog,
          icon: const Icon(Icons.health_and_safety_outlined),
          label: Text(
            isCompactLayout ? 'Verificar legados' : 'Verificar Eventos Legados',
          ),
        ),
        if (!isCompactLayout)
          FilledButton.icon(
            onPressed: _openCreateForm,
            icon: const Icon(Icons.add),
            label: const Text('Novo evento'),
          ),
      ],
    );
  }

  Widget _buildErrorBanner(String? error) {
    if (error == null || error.isEmpty) {
      return const SizedBox.shrink();
    }

    return TenantAdminErrorBanner(
      rawError: error,
      fallbackMessage: 'Unable to load events.',
      onRetry: _controller.loadEvents,
    );
  }

  int _countAppliedFilters({
    required DateTime? selectedDate,
    required TenantAdminAccountProfile? selectedVenue,
    required TenantAdminAccountProfile? selectedProfile,
    required Set<TenantAdminEventTemporalBucket> temporalBuckets,
  }) {
    var count = 0;
    if (selectedDate != null) {
      count += 1;
    }
    if (selectedVenue != null) {
      count += 1;
    }
    if (selectedProfile != null) {
      count += 1;
    }
    if (selectedDate == null &&
        !setEquals(
          temporalBuckets,
          TenantAdminEventTemporalBucket.defaultSelection,
        )) {
      count += 1;
    }
    return count;
  }

  Widget _buildAppliedFilterCountBuilder({
    required Widget Function(int appliedCount) builder,
  }) {
    return StreamValueBuilder<DateTime?>(
      streamValue: _controller.specificDateFilterStreamValue,
      builder: (context, selectedDate) {
        return StreamValueBuilder<TenantAdminAccountProfile?>(
          streamValue: _controller.venueFilterStreamValue,
          builder: (context, selectedVenue) {
            return StreamValueBuilder<TenantAdminAccountProfile?>(
              streamValue: _controller.relatedAccountProfileFilterStreamValue,
              builder: (context, selectedProfile) {
                return StreamValueBuilder<Set<TenantAdminEventTemporalBucket>>(
                  streamValue: _controller.temporalFilterStreamValue,
                  builder: (context, temporalBuckets) {
                    return builder(
                      _countAppliedFilters(
                        selectedDate: selectedDate,
                        selectedVenue: selectedVenue,
                        selectedProfile: selectedProfile,
                        temporalBuckets: temporalBuckets,
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

  Widget _buildCompactToolbarAction({
    required Key key,
    required String tooltip,
    required VoidCallback onPressed,
    required Widget icon,
    bool isHighlighted = false,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Tooltip(
      message: tooltip,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: isHighlighted
              ? colorScheme.secondaryContainer
              : colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isHighlighted
                ? colorScheme.secondary.withValues(alpha: 0.28)
                : colorScheme.outlineVariant,
          ),
        ),
        child: IconButton(
          key: key,
          onPressed: onPressed,
          icon: icon,
          color: isHighlighted
              ? colorScheme.onSecondaryContainer
              : colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildCompactFiltersButton() {
    return _buildAppliedFilterCountBuilder(
      builder: (appliedCount) {
        final tooltip = appliedCount == 0
            ? 'Filtros'
            : '$appliedCount filtro${appliedCount == 1 ? '' : 's'} ativo${appliedCount == 1 ? '' : 's'}';

        return _buildCompactToolbarAction(
          key:
              const ValueKey<String>('tenant-admin-events-open-filters-button'),
          tooltip: tooltip,
          onPressed: _openCompactFiltersSheet,
          isHighlighted: appliedCount > 0,
          icon: Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(Icons.tune),
              if (appliedCount > 0)
                Positioned(
                  right: -8,
                  top: -8,
                  child: Container(
                    key: const ValueKey<String>(
                      'tenant-admin-events-open-filters-badge',
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '$appliedCount',
                      key: const ValueKey<String>(
                        'tenant-admin-events-open-filters-badge-label',
                      ),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Theme.of(context).colorScheme.onPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openCompactFiltersSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            16 + MediaQuery.viewInsetsOf(sheetContext).bottom,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAppliedFilterCountBuilder(
                  builder: (appliedCount) {
                    return Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Filtros',
                            style: Theme.of(sheetContext).textTheme.titleMedium,
                          ),
                        ),
                        if (appliedCount > 0)
                          TextButton(
                            key: const ValueKey<String>(
                              'tenant-admin-events-clear-filters-button',
                            ),
                            onPressed: _clearAllFilters,
                            child: const Text('Limpar'),
                          ),
                        IconButton(
                          tooltip: 'Fechar',
                          onPressed: () => sheetContext.router.maybePop(),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 12),
                _buildFilterControls(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDesktopFiltersPanel({required String? error}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (error != null && error.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildErrorBanner(error),
            ),
          _buildFilterControls(),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: _buildActionButtons(isCompactLayout: false),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactToolbar({required String? error}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (error != null && error.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildErrorBanner(error),
            ),
          Row(
            children: [
              _buildCompactFiltersButton(),
              const Spacer(),
              _buildCompactToolbarAction(
                key: const ValueKey<String>('tenant-admin-events-types-button'),
                tooltip: 'Tipos de evento',
                onPressed: _openEventTypes,
                icon: const Icon(Icons.category_outlined),
              ),
              const SizedBox(width: 8),
              _buildCompactToolbarAction(
                key: const ValueKey<String>(
                    'tenant-admin-events-legacy-check-button'),
                tooltip: 'Verificar eventos legados',
                onPressed: _openLegacyEventsDialog,
                icon: const Icon(Icons.health_and_safety_outlined),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEventsList({
    required List<TenantAdminEvent> events,
    required bool hasMore,
    required bool isPageLoading,
  }) {
    final sections = _buildSections(context, events);
    final itemCount = sections.length + (hasMore ? 1 : 0);

    return ListView.builder(
      controller: _controller.eventsScrollController,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 112),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        if (index >= sections.length) {
          if (isPageLoading) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          return const SizedBox.shrink();
        }

        final section = sections[index];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDateDivider(context, section),
            ...section.items.map(
              (event) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _TenantAdminEventCard(
                  key: ValueKey<String>(
                    'tenant-admin-event-card-${event.eventId}',
                  ),
                  event: event,
                  metaLabel: _buildEventMetaLabel(
                    context,
                    event,
                    _resolvePrimaryOccurrence(event),
                  ),
                  venueLabel: _buildVenueLabel(event),
                  publicationLabel: _buildPublicationLabel(context, event),
                  updatedLabel: _formatDateTime(
                    context,
                    event.updatedAt ?? event.createdAt,
                  ),
                  onTap: () => _openEditForm(event),
                  onEdit: () => _openEditForm(event),
                  onDelete: () => _confirmDelete(event),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCompactContent({
    required String? error,
    required List<TenantAdminEvent> events,
    required bool hasMore,
    required bool isPageLoading,
  }) {
    return Column(
      children: [
        _buildCompactToolbar(error: error),
        Expanded(
          child: events.isEmpty
              ? const TenantAdminEmptyState(
                  icon: Icons.event_busy_outlined,
                  title: 'Nenhum evento cadastrado',
                  description:
                      'Use "Novo evento" para iniciar a gestão de eventos do tenant.',
                )
              : _buildEventsList(
                  events: events,
                  hasMore: hasMore,
                  isPageLoading: isPageLoading,
                ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isCompactLayout = MediaQuery.of(context).size.width < 900;
    return StreamValueBuilder<String?>(
      streamValue: _controller.eventsErrorStreamValue,
      builder: (context, error) {
        return StreamValueBuilder<bool>(
          streamValue: _controller.hasMoreEventsStreamValue,
          builder: (context, hasMore) {
            return StreamValueBuilder<bool>(
              streamValue: _controller.isEventsPageLoadingStreamValue,
              builder: (context, isPageLoading) {
                return StreamValueBuilder<List<TenantAdminEvent>?>(
                  streamValue: _controller.eventsStreamValue,
                  onNullWidget: const Center(
                    child: CircularProgressIndicator(),
                  ),
                  builder: (context, events) {
                    final loadedEvents = events ?? const <TenantAdminEvent>[];
                    final desktopContent = Column(
                      children: [
                        _buildDesktopFiltersPanel(error: error),
                        Expanded(
                          child: loadedEvents.isEmpty
                              ? const TenantAdminEmptyState(
                                  icon: Icons.event_busy_outlined,
                                  title: 'Nenhum evento cadastrado',
                                  description:
                                      'Use "Novo evento" para iniciar a gestão de eventos do tenant.',
                                )
                              : _buildEventsList(
                                  events: loadedEvents,
                                  hasMore: hasMore,
                                  isPageLoading: isPageLoading,
                                ),
                        ),
                      ],
                    );

                    return Stack(
                      children: [
                        if (isCompactLayout)
                          _buildCompactContent(
                            error: error,
                            events: loadedEvents,
                            hasMore: hasMore,
                            isPageLoading: isPageLoading,
                          )
                        else
                          desktopContent,
                        if (isCompactLayout)
                          Positioned(
                            right: 16,
                            bottom: 16,
                            child: SafeArea(
                              child: FloatingActionButton.extended(
                                key: const ValueKey<String>(
                                  'tenant-admin-events-create-fab',
                                ),
                                onPressed: _openCreateForm,
                                icon: const Icon(Icons.add),
                                label: const Text('Novo evento'),
                              ),
                            ),
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
}

class _TenantAdminEventCard extends StatelessWidget {
  const _TenantAdminEventCard({
    super.key,
    required this.event,
    required this.metaLabel,
    required this.venueLabel,
    required this.publicationLabel,
    required this.updatedLabel,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  final TenantAdminEvent event;
  final String metaLabel;
  final String venueLabel;
  final String publicationLabel;
  final String updatedLabel;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final cardRadius = BorderRadius.circular(26);

    return Material(
      color: colorScheme.surfaceContainerLow,
      borderRadius: cardRadius,
      child: InkWell(
        borderRadius: cardRadius,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Stack(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _TenantAdminEventThumb(imageUrl: event.thumbUrl),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 52),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            metaLabel,
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            event.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w900,
                              height: 1,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _TenantAdminMetaPill(label: event.type.name),
                              _TenantAdminMetaPill(label: publicationLabel),
                              if (event.deletedAt != null)
                                const _TenantAdminMetaPill(label: 'Arquivado'),
                            ],
                          ),
                          if (event.slug.trim().isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              event.slug,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                          if (event.relatedAccountProfiles.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: event.relatedAccountProfiles
                                  .map(
                                    (profile) => _TenantAdminProfileChip(
                                      profile: profile,
                                    ),
                                  )
                                  .toList(growable: false),
                            ),
                          ],
                          const SizedBox(height: 10),
                          _TenantAdminInfoRow(
                            icon: Icons.place_outlined,
                            text: venueLabel,
                          ),
                          if (updatedLabel != '-') ...[
                            const SizedBox(height: 6),
                            _TenantAdminInfoRow(
                              icon: Icons.history_outlined,
                              text: 'Atualizado $updatedLabel',
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              Positioned(
                right: 0,
                top: 0,
                child: PopupMenuButton<String>(
                  key: ValueKey<String>(
                    'tenant-admin-event-menu-${event.eventId}',
                  ),
                  onSelected: (value) {
                    if (value == 'edit') {
                      onEdit();
                      return;
                    }
                    if (value == 'delete') {
                      onDelete();
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem<String>(
                      value: 'edit',
                      child: Text('Editar'),
                    ),
                    PopupMenuItem<String>(
                      value: 'delete',
                      child: Text('Remover'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TenantAdminEventThumb extends StatelessWidget {
  const _TenantAdminEventThumb({
    required this.imageUrl,
  });

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      width: 84,
      height: 116,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      alignment: Alignment.center,
      child: const Icon(Icons.event_outlined),
    );

    final normalizedUrl = imageUrl?.trim();
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: normalizedUrl == null || normalizedUrl.isEmpty
          ? placeholder
          : BellugaNetworkImage(
              normalizedUrl,
              width: 84,
              height: 116,
              fit: BoxFit.cover,
              placeholder: placeholder,
              errorWidget: placeholder,
            ),
    );
  }
}

class _TenantAdminMetaPill extends StatelessWidget {
  const _TenantAdminMetaPill({
    required this.label,
  });

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _TenantAdminProfileChip extends StatelessWidget {
  const _TenantAdminProfileChip({
    required this.profile,
  });

  final TenantAdminAccountProfile profile;

  @override
  Widget build(BuildContext context) {
    final avatarUrl = profile.avatarUrl?.trim();
    final avatar = avatarUrl == null || avatarUrl.isEmpty
        ? CircleAvatar(
            radius: 12,
            backgroundColor:
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
            child: Icon(
              Icons.person_outline,
              size: 14,
              color: Theme.of(context).colorScheme.primary,
            ),
          )
        : ClipOval(
            child: BellugaNetworkImage(
              avatarUrl,
              width: 24,
              height: 24,
              fit: BoxFit.cover,
            ),
          );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          avatar,
          const SizedBox(width: 6),
          Text(
            profile.displayName,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

class _TenantAdminInfoRow extends StatelessWidget {
  const _TenantAdminInfoRow({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
      ],
    );
  }
}

class _TenantAdminEventSection {
  _TenantAdminEventSection({
    required this.key,
    required this.label,
    required this.tag,
    required this.items,
  });

  final String key;
  final String label;
  final String? tag;
  final List<TenantAdminEvent> items;
}
