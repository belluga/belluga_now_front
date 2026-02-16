import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_static_asset.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/widgets/tenant_admin_confirmation_dialog.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/widgets/tenant_admin_empty_state.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/widgets/tenant_admin_error_banner.dart';
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
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
    _controller.loadAssets();
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    super.dispose();
  }

  void _handleScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    const threshold = 320.0;
    if (position.pixels + threshold >= position.maxScrollExtent) {
      _controller.loadNextAssetsPage();
    }
  }

  Future<void> _confirmDelete(TenantAdminStaticAsset asset) async {
    final confirmed = await showTenantAdminConfirmationDialog(
      context: context,
      title: 'Remover ativo',
      message: 'Remover "${asset.displayName}"?',
      confirmLabel: 'Remover',
      isDestructive: true,
    );
    if (!confirmed) return;
    await _controller.deleteAsset(asset.id);
  }

  @override
  Widget build(BuildContext context) {
    return StreamValueBuilder<String?>(
      streamValue: _controller.errorStreamValue,
      builder: (context, error) {
        return StreamValueBuilder<bool>(
          streamValue: _controller.hasMoreAssetsStreamValue,
          builder: (context, hasMore) {
            return StreamValueBuilder<bool>(
              streamValue: _controller.isAssetsPageLoadingStreamValue,
              builder: (context, isPageLoading) {
                return StreamValueBuilder<List<TenantAdminStaticAsset>?>(
                  streamValue: _controller.assetsStreamValue,
                  onNullWidget: StreamValueBuilder<bool>(
                    streamValue: _controller.showSearchFieldStreamValue,
                    builder: (context, showSearchField) {
                      return StreamValueBuilder<String?>(
                        streamValue: _controller.selectedTypeFilterStreamValue,
                        builder: (context, selectedTypeFilter) {
                          return _buildScaffold(
                            context: context,
                            showSearchField: showSearchField,
                            availableTypes: const [],
                            selectedTypeFilter: selectedTypeFilter,
                            error: error,
                            body: const Center(
                                child: CircularProgressIndicator()),
                          );
                        },
                      );
                    },
                  ),
                  builder: (context, assets) {
                    return StreamValueBuilder<bool>(
                      streamValue: _controller.showSearchFieldStreamValue,
                      builder: (context, showSearchField) {
                        return StreamValueBuilder<String?>(
                          streamValue:
                              _controller.selectedTypeFilterStreamValue,
                          builder: (context, selectedTypeFilterValue) {
                            return StreamValueBuilder<String>(
                              streamValue: _controller.searchQueryStreamValue,
                              builder: (context, query) {
                                final loadedAssets =
                                    assets ?? const <TenantAdminStaticAsset>[];
                                final availableTypes = loadedAssets
                                    .map((asset) => asset.profileType)
                                    .toSet()
                                    .toList(growable: false)
                                  ..sort();
                                final selectedTypeFilter =
                                    availableTypes.contains(
                                  selectedTypeFilterValue,
                                )
                                        ? selectedTypeFilterValue
                                        : null;
                                final filteredAssets =
                                    _filterAssets(loadedAssets, query.trim());
                                final filteredByType =
                                    selectedTypeFilter == null
                                        ? filteredAssets
                                        : filteredAssets
                                            .where(
                                              (asset) =>
                                                  asset.profileType ==
                                                  selectedTypeFilter,
                                            )
                                            .toList(growable: false);
                                return _buildScaffold(
                                  context: context,
                                  showSearchField: showSearchField,
                                  availableTypes: availableTypes,
                                  selectedTypeFilter: selectedTypeFilter,
                                  error: error,
                                  body: filteredByType.isEmpty
                                      ? const TenantAdminEmptyState(
                                          icon: Icons.place_outlined,
                                          title: 'Nenhum ativo estático',
                                          description:
                                              'Use "Criar ativo" para adicionar o primeiro ativo do tenant.',
                                        )
                                      : _buildAssetsList(
                                          filteredAssets: filteredByType,
                                          hasMore: hasMore,
                                          isPageLoading: isPageLoading,
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
  }

  Widget _buildAssetsList({
    required List<TenantAdminStaticAsset> filteredAssets,
    required bool hasMore,
    required bool isPageLoading,
  }) {
    final itemCount = filteredAssets.length + (hasMore ? 1 : 0);
    return ListView.separated(
      controller: _scrollController,
      padding: const EdgeInsets.only(bottom: 112),
      itemCount: itemCount,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        if (index >= filteredAssets.length) {
          if (isPageLoading) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          return const SizedBox.shrink();
        }
        final asset = filteredAssets[index];
        final subtitle = [asset.slug, asset.profileType].join(' • ');
        return Card(
          clipBehavior: Clip.antiAlias,
          child: ListTile(
            title: Text(asset.displayName),
            subtitle: Text(subtitle),
            onTap: () {
              context.router.push(
                TenantAdminStaticAssetDetailRoute(
                  assetId: asset.id,
                  asset: asset,
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
    );
  }

  Widget _buildScaffold({
    required BuildContext context,
    required bool showSearchField,
    required List<String> availableTypes,
    required String? selectedTypeFilter,
    required String? error,
    required Widget body,
  }) {
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
            Row(
              children: [
                const Spacer(),
                IconButton(
                  tooltip: showSearchField ? 'Ocultar busca' : 'Buscar',
                  onPressed: _controller.toggleSearchFieldVisibility,
                  icon: Icon(
                    showSearchField ? Icons.close : Icons.search,
                  ),
                ),
              ],
            ),
            if (showSearchField) ...[
              TextField(
                onChanged: _controller.updateSearchQuery,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  labelText: 'Buscar por nome ou slug',
                ),
              ),
              const SizedBox(height: 12),
            ],
            DropdownButtonFormField<String?>(
              key: ValueKey(selectedTypeFilter),
              initialValue: selectedTypeFilter,
              decoration: const InputDecoration(
                labelText: 'Filtrar por tipo',
              ),
              items: <DropdownMenuItem<String?>>[
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('Todos os tipos'),
                ),
                ...availableTypes.map(
                  (profileType) => DropdownMenuItem<String?>(
                    value: profileType,
                    child: Text(profileType),
                  ),
                ),
              ],
              onChanged: (value) {
                _controller.updateSelectedTypeFilter(value);
              },
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () {
                  context.router.push(
                    const TenantAdminStaticProfileTypesListRoute(),
                  );
                },
                icon: const Icon(Icons.layers_outlined),
                label: const Text('Gerenciar tipos de ativo'),
              ),
            ),
            const SizedBox(height: 12),
            if (error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: TenantAdminErrorBanner(
                  rawError: error,
                  fallbackMessage:
                      'Não foi possível carregar os ativos estáticos.',
                  onRetry: _controller.loadAssets,
                ),
              ),
            const SizedBox(height: 8),
            Expanded(child: body),
          ],
        ),
      ),
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
}
