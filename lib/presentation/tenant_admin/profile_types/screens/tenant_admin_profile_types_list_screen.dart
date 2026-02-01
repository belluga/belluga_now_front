import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/presentation/tenant_admin/profile_types/controllers/tenant_admin_profile_types_controller.dart';
import 'package:flutter/material.dart';
import 'package:stream_value/core/stream_value_builder.dart';

class TenantAdminProfileTypesListScreen extends StatefulWidget {
  const TenantAdminProfileTypesListScreen({
    super.key,
    required this.controller,
  });

  final TenantAdminProfileTypesController controller;

  @override
  State<TenantAdminProfileTypesListScreen> createState() =>
      _TenantAdminProfileTypesListScreenState();
}

class _TenantAdminProfileTypesListScreenState
    extends State<TenantAdminProfileTypesListScreen> {
  late final TenantAdminProfileTypesController _controller;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller;
    _controller.loadTypes();
  }

  Future<void> _confirmDelete(String type, String label) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Remover tipo de perfil'),
          content: Text('Remover "$label" ($type)?'),
          actions: [
            TextButton(
              onPressed: () => context.router.pop(false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => context.router.pop(true),
              child: const Text('Remover'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    await _controller.deleteType(type);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tipo removido.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamValueBuilder<bool>(
      streamValue: _controller.isLoadingStreamValue,
      builder: (context, isLoading) {
        return StreamValueBuilder<String?>(
          streamValue: _controller.errorStreamValue,
          builder: (context, error) {
            return StreamValueBuilder(
              streamValue: _controller.typesStreamValue,
              builder: (context, types) {
                return Scaffold(
                  floatingActionButton: FloatingActionButton.extended(
                    onPressed: () async {
                      await context.router.push(
                        const TenantAdminProfileTypeCreateRoute(),
                      );
                      if (!mounted) return;
                      await _controller.loadTypes();
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Criar tipo'),
                  ),
                  body: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tipos cadastrados',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        if (isLoading) const LinearProgressIndicator(),
                        if (error != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Card(
                              margin: EdgeInsets.zero,
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        error,
                                        style: TextStyle(
                                          color:
                                              Theme.of(context).colorScheme.error,
                                        ),
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: _controller.loadTypes,
                                      child: const Text('Tentar novamente'),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: types.isEmpty
                              ? _buildEmptyState(context)
                              : ListView.separated(
                                  itemCount: types.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(height: 12),
                                  itemBuilder: (context, index) {
                                    final type = types[index];
                                    final subtitle = [
                                      if (type.capabilities.isPoiEnabled)
                                        'POI habilitado',
                                      if (type.capabilities.isFavoritable)
                                        'Favoritavel',
                                      if (type.capabilities.hasBio)
                                        'Bio',
                                      if (type.capabilities.hasTaxonomies)
                                        'Taxonomias',
                                      if (type.capabilities.hasAvatar)
                                        'Avatar',
                                      if (type.capabilities.hasCover)
                                        'Capa',
                                      if (type.capabilities.hasEvents)
                                        'Agenda',
                                      if (type.allowedTaxonomies.isNotEmpty)
                                        'Taxonomias: ${type.allowedTaxonomies.join(', ')}',
                                    ].join(' • ');
                                    return Card(
                                      clipBehavior: Clip.antiAlias,
                                      child: ListTile(
                                        title: Text(type.label),
                                        subtitle: Text(
                                          subtitle.isEmpty ? type.type : subtitle,
                                        ),
                                        trailing: PopupMenuButton<String>(
                                          onSelected: (value) async {
                                            if (value == 'edit') {
                                              await context.router.push(
                                                TenantAdminProfileTypeEditRoute(
                                                  profileType: type.type,
                                                  definition: type,
                                                ),
                                              );
                                              if (!mounted) return;
                                              await _controller.loadTypes();
                                            }
                                            if (value == 'delete') {
                                              await _confirmDelete(
                                                type.type,
                                                type.label,
                                              );
                                            }
                                          },
                                          itemBuilder: (context) => [
                                            const PopupMenuItem(
                                              value: 'edit',
                                              child: Text('Editar'),
                                            ),
                                            const PopupMenuItem(
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
          },
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Nenhum tipo cadastrado ainda.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () async {
              await context.router.push(
                const TenantAdminProfileTypeCreateRoute(),
              );
              if (!mounted) return;
              await _controller.loadTypes();
            },
            child: const Text('Criar tipo'),
          ),
        ],
      ),
    );
  }
}
