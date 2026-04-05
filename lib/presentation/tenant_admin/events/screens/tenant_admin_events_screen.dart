import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_event.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_legacy_event_parties_summary.dart';
import 'package:belluga_now/presentation/tenant_admin/events/controllers/tenant_admin_events_controller.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/widgets/tenant_admin_confirmation_dialog.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/widgets/tenant_admin_empty_state.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/widgets/tenant_admin_error_banner.dart';
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
                    return Stack(
                      children: [
                        Column(
                          children: [
                            _buildFilters(
                              error: error,
                              isCompactLayout: isCompactLayout,
                            ),
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
                        ),
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

  Widget _buildFilters({
    required String? error,
    required bool isCompactLayout,
  }) {
    final statusFilter = StreamValueBuilder<String?>(
      streamValue: _controller.statusFilterStreamValue,
      builder: (context, selectedStatus) {
        return DropdownButtonFormField<String?>(
          initialValue: selectedStatus,
          decoration: const InputDecoration(labelText: 'Status'),
          items: const [
            DropdownMenuItem<String?>(
              value: null,
              child: Text('Todos'),
            ),
            DropdownMenuItem<String?>(
              value: 'draft',
              child: Text('Draft'),
            ),
            DropdownMenuItem<String?>(
              value: 'published',
              child: Text('Published'),
            ),
            DropdownMenuItem<String?>(
              value: 'publish_scheduled',
              child: Text('Scheduled'),
            ),
            DropdownMenuItem<String?>(
              value: 'ended',
              child: Text('Ended'),
            ),
          ],
          onChanged: (value) {
            _controller.updateStatusFilter(value);
            _controller.applyFilters();
          },
        );
      },
    );

    final visibilityFilter = StreamValueBuilder<bool>(
      streamValue: _controller.archivedFilterStreamValue,
      builder: (context, archivedOnly) {
        return DropdownButtonFormField<bool>(
          initialValue: archivedOnly,
          decoration: const InputDecoration(
            labelText: 'Visibilidade',
          ),
          items: const [
            DropdownMenuItem<bool>(
              value: false,
              child: Text('Ativos'),
            ),
            DropdownMenuItem<bool>(
              value: true,
              child: Text('Arquivados'),
            ),
          ],
          onChanged: (value) {
            _controller.updateArchivedFilter(value ?? false);
            _controller.applyFilters();
          },
        );
      },
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        children: [
          if (error != null && error.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: TenantAdminErrorBanner(
                rawError: error,
                fallbackMessage: 'Unable to load events.',
                onRetry: () {
                  _controller.loadEvents();
                },
              ),
            ),
          if (isCompactLayout) ...[
            Row(
              children: [
                Expanded(child: statusFilter),
                const SizedBox(width: 12),
                Expanded(child: visibilityFilter),
              ],
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  OutlinedButton.icon(
                    onPressed: _openEventTypes,
                    icon: const Icon(Icons.category_outlined),
                    label: const Text('Tipos de evento'),
                  ),
                  OutlinedButton.icon(
                    key: const ValueKey<String>(
                      'tenant-admin-events-legacy-check-button',
                    ),
                    onPressed: _openLegacyEventsDialog,
                    icon: const Icon(Icons.health_and_safety_outlined),
                    label: const Text('Verificar Eventos Legados'),
                  ),
                ],
              ),
            ),
          ] else
            Row(
              children: [
                SizedBox(
                  width: 180,
                  child: statusFilter,
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 170,
                  child: visibilityFilter,
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: _openEventTypes,
                  icon: const Icon(Icons.category_outlined),
                  label: const Text('Tipos'),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  key: const ValueKey<String>(
                    'tenant-admin-events-legacy-check-button',
                  ),
                  onPressed: _openLegacyEventsDialog,
                  icon: const Icon(Icons.health_and_safety_outlined),
                  label: const Text('Verificar Eventos Legados'),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: _openCreateForm,
                  icon: const Icon(Icons.add),
                  label: const Text('Novo evento'),
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
    final itemCount = events.length + (hasMore ? 1 : 0);

    return ListView.separated(
      controller: _controller.eventsScrollController,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 112),
      itemCount: itemCount,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        if (index >= events.length) {
          if (isPageLoading) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          return const SizedBox.shrink();
        }

        final event = events[index];

        return Card(
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 10,
            ),
            title: Text(event.title),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text('Slug: ${event.slug}'),
                Text('Tipo: ${event.type.name}'),
                Text(
                  'Início: ${event.occurrences.isNotEmpty ? event.occurrences.first.dateTimeStart.toIso8601String() : '-'}',
                ),
                Text('Status: ${event.publication.status}'),
              ],
            ),
            trailing: PopupMenuButton<String>(
              key: ValueKey<String>('tenant-admin-event-menu-${event.eventId}'),
              onSelected: (value) {
                if (value == 'edit') {
                  _openEditForm(event);
                  return;
                }
                if (value == 'delete') {
                  _confirmDelete(event);
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
            onTap: () => _openEditForm(event),
          ),
        );
      },
    );
  }
}
