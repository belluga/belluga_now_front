import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_event.dart';
import 'package:belluga_now/presentation/tenant_admin/events/controllers/tenant_admin_events_controller.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/widgets/tenant_admin_confirmation_dialog.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/widgets/tenant_admin_empty_state.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value_builder.dart';

class TenantAdminEventTypesListScreen extends StatefulWidget {
  const TenantAdminEventTypesListScreen({super.key});

  @override
  State<TenantAdminEventTypesListScreen> createState() =>
      _TenantAdminEventTypesListScreenState();
}

class _TenantAdminEventTypesListScreenState
    extends State<TenantAdminEventTypesListScreen> {
  final TenantAdminEventsController _controller =
      GetIt.I.get<TenantAdminEventsController>();

  @override
  void initState() {
    super.initState();
    _controller.loadFormDependencies();
  }

  Future<void> _confirmDelete(TenantAdminEventType type) async {
    final confirmed = await showTenantAdminConfirmationDialog(
      context: context,
      title: 'Remover tipo de evento',
      message: 'Remover "${type.name}"?',
      confirmLabel: 'Remover',
      isDestructive: true,
    );
    if (!confirmed) {
      return;
    }
    await _controller.submitDeleteEventType(type);
  }

  Future<void> _openCreateType() async {
    final created = await context.router.push<TenantAdminEventType>(
      const TenantAdminEventTypeCreateRoute(),
    );
    if (created != null) {
      await _controller.loadFormDependencies();
    }
  }

  Future<void> _openEditType(TenantAdminEventType type) async {
    final updated = await context.router.push<TenantAdminEventType>(
      TenantAdminEventTypeEditRoute(type: type),
    );
    if (updated != null) {
      await _controller.loadFormDependencies();
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamValueBuilder<List<TenantAdminEventType>>(
      streamValue: _controller.eventTypeCatalogStreamValue,
      builder: (context, types) {
        final loadedTypes = types;
        return Scaffold(
          floatingActionButton: FloatingActionButton.extended(
            onPressed: _openCreateType,
            icon: const Icon(Icons.add),
            label: const Text('Criar tipo'),
          ),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tipos de evento',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  'Use os tipos cadastrados para padronizar o formulário de eventos.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: loadedTypes.isEmpty
                      ? const TenantAdminEmptyState(
                          icon: Icons.category_outlined,
                          title: 'Nenhum tipo cadastrado',
                          description:
                              'Use "Criar tipo" para adicionar o primeiro tipo de evento.',
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.only(bottom: 112),
                          itemCount: loadedTypes.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final type = loadedTypes[index];
                            return Card(
                              child: ListTile(
                                title: Text(type.name),
                                subtitle: Text(
                                  type.description?.trim().isNotEmpty == true
                                      ? '${type.slug} • ${type.description}'
                                      : type.slug,
                                ),
                                onTap: () => _openEditType(type),
                                trailing: PopupMenuButton<String>(
                                  onSelected: (value) async {
                                    if (value == 'edit') {
                                      await _openEditType(type);
                                      return;
                                    }
                                    if (value == 'delete') {
                                      await _confirmDelete(type);
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
}
