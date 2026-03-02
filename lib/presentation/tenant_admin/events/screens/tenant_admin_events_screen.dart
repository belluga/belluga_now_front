import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_event.dart';
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
    _controller.initEventsListState();
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

  Future<void> _openCreateForm() async {
    final created = await context.router.push<TenantAdminEvent>(
      const TenantAdminEventCreateRoute(),
    );

    if (created == null || !mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Evento criado com sucesso.')),
    );
  }

  Future<void> _openEditForm(TenantAdminEvent event) async {
    final updated = await context.router.push<TenantAdminEvent>(
      TenantAdminEventEditRoute(event: event),
    );

    if (updated == null || !mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Evento atualizado com sucesso.')),
    );
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

  Future<void> _openEventTypes() async {
    await context.router.push(const TenantAdminEventTypesRoute());
    if (!mounted) {
      return;
    }
    await _controller.loadFormDependencies();
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
    final searchField = TextField(
      controller: _controller.eventsSearchController,
      decoration: const InputDecoration(
        labelText: 'Buscar eventos',
        prefixIcon: Icon(Icons.search),
      ),
      onSubmitted: (value) {
        _controller.updateSearchQuery(value);
        _controller.applyFilters();
      },
    );

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
            searchField,
            const SizedBox(height: 12),
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
              child: OutlinedButton.icon(
                onPressed: _openEventTypes,
                icon: const Icon(Icons.category_outlined),
                label: const Text('Tipos de evento'),
              ),
            ),
          ] else
            Row(
              children: [
                Expanded(child: searchField),
                const SizedBox(width: 12),
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
