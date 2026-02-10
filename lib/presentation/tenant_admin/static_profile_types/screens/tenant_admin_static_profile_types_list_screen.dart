import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_static_profile_type.dart';
import 'package:belluga_now/presentation/tenant_admin/static_profile_types/controllers/tenant_admin_static_profile_types_controller.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value_builder.dart';

class TenantAdminStaticProfileTypesListScreen extends StatefulWidget {
  const TenantAdminStaticProfileTypesListScreen({super.key});

  @override
  State<TenantAdminStaticProfileTypesListScreen> createState() =>
      _TenantAdminStaticProfileTypesListScreenState();
}

class _TenantAdminStaticProfileTypesListScreenState
    extends State<TenantAdminStaticProfileTypesListScreen> {
  final TenantAdminStaticProfileTypesController _controller =
      GetIt.I.get<TenantAdminStaticProfileTypesController>();

  @override
  void initState() {
    super.initState();
    _controller.loadTypes();
    _controller.loadTaxonomies();
  }

  Future<void> _confirmDelete(String type, String label) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Remover tipo de ativo'),
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

    _controller.submitDeleteType(type);
  }

  @override
  Widget build(BuildContext context) {
    return StreamValueBuilder<String?>(
      streamValue: _controller.successMessageStreamValue,
      builder: (context, successMessage) {
        _handleSuccessMessage(successMessage);
        return StreamValueBuilder<String?>(
          streamValue: _controller.actionErrorMessageStreamValue,
          builder: (context, actionErrorMessage) {
            _handleActionErrorMessage(actionErrorMessage);
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
                            onPressed: () {
                              context.router
                                  .push(
                                    const TenantAdminStaticProfileTypeCreateRoute(),
                                  )
                                  .then((_) => _controller.loadTypes());
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
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .error,
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
                                            final subtitle = _buildSubtitle(type);
                                            return Card(
                                              clipBehavior: Clip.antiAlias,
                                              child: ListTile(
                                                title: Text(type.label),
                                                subtitle: Text(
                                                  subtitle.isEmpty
                                                      ? type.type
                                                      : subtitle,
                                                ),
                                                trailing: PopupMenuButton<String>(
                                                  onSelected: (value) async {
                                                    if (value == 'edit') {
                                                      context.router
                                                          .push(
                                                            TenantAdminStaticProfileTypeEditRoute(
                                                              profileType:
                                                                  type.type,
                                                              definition: type,
                                                            ),
                                                          )
                                                          .then((_) =>
                                                              _controller.loadTypes());
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
          },
        );
      },
    );
  }

  String _buildSubtitle(TenantAdminStaticProfileTypeDefinition type) {
    final parts = <String>[];
    if (type.capabilities.isPoiEnabled) parts.add('POI habilitado');
    if (type.capabilities.hasBio) parts.add('Bio');
    if (type.capabilities.hasTaxonomies) parts.add('Taxonomias');
    if (type.capabilities.hasAvatar) parts.add('Avatar');
    if (type.capabilities.hasCover) parts.add('Capa');
    if (type.capabilities.hasContent) parts.add('Conteudo');
    if (type.allowedTaxonomies.isNotEmpty) {
      parts.add('Taxonomias: ${type.allowedTaxonomies.join(', ')}');
    }
    return parts.join(' - ');
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
            onPressed: () {
              context.router
                  .push(const TenantAdminStaticProfileTypeCreateRoute())
                  .then((_) => _controller.loadTypes());
            },
            child: const Text('Criar tipo'),
          ),
        ],
      ),
    );
  }

  void _handleSuccessMessage(String? message) {
    if (message == null || message.isEmpty) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
      _controller.clearSuccessMessage();
    });
  }

  void _handleActionErrorMessage(String? message) {
    if (message == null || message.isEmpty) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
      _controller.clearActionErrorMessage();
    });
  }
}
