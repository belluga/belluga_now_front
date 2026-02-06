import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_static_asset.dart';
import 'package:belluga_now/presentation/tenant_admin/static_assets/controllers/tenant_admin_static_assets_controller.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value_builder.dart';

class TenantAdminStaticAssetsListScreen extends StatefulWidget {
  const TenantAdminStaticAssetsListScreen({super.key});

  @override
  State<TenantAdminStaticAssetsListScreen> createState() =>
      _TenantAdminStaticAssetsListScreenState();
}

class _TenantAdminStaticAssetsListScreenState
    extends State<TenantAdminStaticAssetsListScreen> {
  final TenantAdminStaticAssetsController _controller =
      GetIt.I.get<TenantAdminStaticAssetsController>();

  @override
  void initState() {
    super.initState();
    _controller.loadAssets();
  }

  Future<void> _confirmDelete(TenantAdminStaticAsset asset) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Remover ativo'),
          content: Text('Remover "${asset.displayName}"?'),
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

    if (confirmed != true) return;
    await _controller.deleteAsset(asset.id);
  }

  @override
  Widget build(BuildContext context) {
    return StreamValueBuilder<String?>(
      streamValue: _controller.errorStreamValue,
      builder: (context, error) {
        return StreamValueBuilder<bool>(
          streamValue: _controller.isLoadingStreamValue,
          builder: (context, isLoading) {
            return StreamValueBuilder<List<TenantAdminStaticAsset>>(
              streamValue: _controller.assetsStreamValue,
              builder: (context, assets) {
                return StreamValueBuilder<String>(
                  streamValue: _controller.searchQueryStreamValue,
                  builder: (context, query) {
                    final filteredAssets =
                        _filterAssets(assets, query.trim());
                    return Scaffold(
                      floatingActionButton: FloatingActionButton.extended(
                        onPressed: () {
                          context.router.push(
                            const TenantAdminStaticAssetCreateRoute(),
                          );
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Criar ativo'),
                      ),
                      body: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Ativos estaticos',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              onChanged: _controller.updateSearchQuery,
                              decoration: const InputDecoration(
                                prefixIcon: Icon(Icons.search),
                                labelText: 'Buscar por nome ou slug',
                              ),
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
                                          onPressed: _controller.loadAssets,
                                          child: const Text('Tentar novamente'),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            const SizedBox(height: 8),
                            Expanded(
                              child: filteredAssets.isEmpty
                                  ? _buildEmptyState(context)
                                  : ListView.separated(
                                      itemCount: filteredAssets.length,
                                      separatorBuilder: (_, __) =>
                                          const SizedBox(height: 12),
                                      itemBuilder: (context, index) {
                                        final asset = filteredAssets[index];
                                        final subtitle = [
                                          asset.slug,
                                          asset.profileType,
                                        ].join(' • ');
                                        return Card(
                                          clipBehavior: Clip.antiAlias,
                                          child: ListTile(
                                            title: Text(asset.displayName),
                                            subtitle: Text(subtitle),
                                            onTap: () {
                                              context.router.push(
                                                TenantAdminStaticAssetEditRoute(
                                                  assetId: asset.id,
                                                ),
                                              );
                                            },
                                            trailing: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                _buildStatusChip(
                                                  context,
                                                  asset.isActive,
                                                ),
                                                const SizedBox(width: 8),
                                                PopupMenuButton<String>(
                                                  onSelected: (value) {
                                                    if (value == 'edit') {
                                                      context.router.push(
                                                        TenantAdminStaticAssetEditRoute(
                                                          assetId: asset.id,
                                                        ),
                                                      );
                                                    }
                                                    if (value == 'delete') {
                                                      _confirmDelete(asset);
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
  }

  List<TenantAdminStaticAsset> _filterAssets(
    List<TenantAdminStaticAsset> assets,
    String query,
  ) {
    if (query.isEmpty) return assets;
    final needle = query.toLowerCase();
    return assets
        .where(
          (asset) =>
              asset.displayName.toLowerCase().contains(needle) ||
              asset.slug.toLowerCase().contains(needle) ||
              asset.profileType.toLowerCase().contains(needle),
        )
        .toList(growable: false);
  }

  Widget _buildStatusChip(BuildContext context, bool isActive) {
    final scheme = Theme.of(context).colorScheme;
    return Chip(
      label: Text(isActive ? 'Ativo' : 'Inativo'),
      backgroundColor:
          isActive ? scheme.primaryContainer : scheme.surfaceContainerHighest,
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Nenhum ativo cadastrado ainda.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () {
              context.router.push(
                const TenantAdminStaticAssetCreateRoute(),
              );
            },
            child: const Text('Criar ativo'),
          ),
        ],
      ),
    );
  }
}
