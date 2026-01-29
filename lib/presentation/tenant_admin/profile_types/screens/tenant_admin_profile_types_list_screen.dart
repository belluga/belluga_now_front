import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/presentation/tenant_admin/profile_types/controllers/tenant_admin_profile_types_controller.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value_builder.dart';

class TenantAdminProfileTypesListScreen extends StatefulWidget {
  const TenantAdminProfileTypesListScreen({super.key});

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
    _controller = GetIt.I.get<TenantAdminProfileTypesController>();
    _controller.loadTypes();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
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
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back),
                          onPressed: () => context.router.maybePop(),
                          tooltip: 'Voltar',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Tipos de Perfil',
                              style:
                                  TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () async {
                              await context.router.push(
                                const TenantAdminProfileTypeCreateRoute(),
                              );
                              if (!mounted) return;
                              await _controller.loadTypes();
                            },
                            child: const Text('Criar'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (isLoading) const LinearProgressIndicator(),
                      if (error != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            error,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: types.isEmpty
                            ? const Center(
                                child: Text('Nenhum tipo cadastrado ainda.'),
                              )
                            : ListView.separated(
                                itemCount: types.length,
                                separatorBuilder: (_, __) =>
                                    const Divider(height: 1),
                                itemBuilder: (context, index) {
                                  final type = types[index];
                                  final subtitle = [
                                    if (type.capabilities.isPoiEnabled)
                                      'POI habilitado',
                                    if (type.capabilities.isFavoritable)
                                      'Favoritável',
                                    if (type.allowedTaxonomies.isNotEmpty)
                                      'Taxonomias: ${type.allowedTaxonomies.join(', ')}',
                                  ].join(' • ');
                                  return ListTile(
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
                                          await _confirmDelete(type.type, type.label);
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
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
