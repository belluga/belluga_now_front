import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_static_asset.dart';
import 'package:belluga_now/presentation/common/widgets/belluga_network_image.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/widgets/tenant_admin_confirmation_dialog.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/widgets/tenant_admin_empty_state.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/widgets/tenant_admin_error_banner.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/widgets/tenant_admin_list_controls_panel.dart';
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
  static const ValueKey<String> _controlsPanelKey =
      ValueKey<String>('tenant_admin_assets_controls_panel');
  static const ValueKey<String> _searchToggleKey =
      ValueKey<String>('tenant_admin_assets_search_toggle');
  static const ValueKey<String> _searchFieldKey =
      ValueKey<String>('tenant_admin_assets_search_field');
  static const ValueKey<String> _manageTypesButtonKey =
      ValueKey<String>('tenant_admin_assets_manage_types_button');

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

  StackRouter _navigationRouter(BuildContext context) {
    final shellRouter =
        context.innerRouterOf<StackRouter>(TenantAdminShellRoute.name);
    return shellRouter ?? context.router;
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
        return Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            key: ValueKey<String>('tenant_admin_static_asset_card_${asset.id}'),
            onTap: () {
              _navigationRouter(context).push(
                TenantAdminStaticAssetDetailRoute(
                  assetId: asset.id,
                ),
              );
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCoverPreview(context, asset),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildAvatarPreview(context, asset),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  asset.displayName,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  asset.slug,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                      ),
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    _buildAssetMetaChip(
                                      context,
                                      label: asset.profileType,
                                      icon: Icons.layers_outlined,
                                    ),
                                    _buildAssetMetaChip(
                                      context,
                                      label:
                                          asset.isActive ? 'Ativo' : 'Inativo',
                                      icon: asset.isActive
                                          ? Icons.check_circle_outline
                                          : Icons.pause_circle_outline,
                                      highlight: asset.isActive,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'edit') {
                                _navigationRouter(context).push(
                                  TenantAdminStaticAssetEditRoute(
                                    assetId: asset.id,
                                  ),
                                );
                              }
                              if (value == 'delete') {
                                _confirmDelete(asset);
                              }
                            },
                            icon: Icon(
                              Icons.more_horiz_rounded,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
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
                      if (asset.bio != null &&
                          asset.bio!.trim().isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Text(
                          asset.bio!.trim(),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCoverPreview(
    BuildContext context,
    TenantAdminStaticAsset asset,
  ) {
    final coverUrl = asset.coverUrl;
    if (coverUrl != null && coverUrl.isNotEmpty) {
      return BellugaNetworkImage(
        coverUrl,
        height: 120,
        width: double.infinity,
        fit: BoxFit.cover,
        errorWidget: Container(
          height: 120,
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: const Center(
            child: Icon(Icons.image_not_supported_outlined),
          ),
        ),
      );
    }
    return Container(
      height: 120,
      width: double.infinity,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: const Center(
        child: Icon(Icons.image_outlined),
      ),
    );
  }

  Widget _buildAvatarPreview(
    BuildContext context,
    TenantAdminStaticAsset asset,
  ) {
    final avatarUrl = asset.avatarUrl;
    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      return BellugaNetworkImage(
        avatarUrl,
        width: 40,
        height: 40,
        fit: BoxFit.cover,
        clipBorderRadius: BorderRadius.circular(20),
        errorWidget: CircleAvatar(
          backgroundColor:
              Theme.of(context).colorScheme.surfaceContainerHighest,
          child: const Icon(Icons.person_outline),
        ),
      );
    }
    return CircleAvatar(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: const Icon(Icons.photo_outlined),
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
          _navigationRouter(context).push(
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
            TenantAdminListControlsPanel(
              key: _controlsPanelKey,
              filterLabel: 'Filtros de ativos',
              showSearchField: showSearchField,
              onToggleSearch: _controller.toggleSearchFieldVisibility,
              onSearchChanged: _controller.updateSearchQuery,
              searchHintText: 'Nome ou slug do ativo',
              manageButtonLabel: 'Tipos de ativo',
              onManagePressed: () {
                _navigationRouter(context).push(
                  const TenantAdminStaticProfileTypesListRoute(),
                );
              },
              searchToggleKey: _searchToggleKey,
              searchFieldKey: _searchFieldKey,
              manageButtonKey: _manageTypesButtonKey,
              filterField: DropdownButtonFormField<String?>(
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
            ),
            if (error != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: TenantAdminErrorBanner(
                  rawError: error,
                  fallbackMessage:
                      'Não foi possível carregar os ativos estáticos.',
                  onRetry: _controller.loadAssets,
                ),
              ),
            const SizedBox(height: 12),
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

  Widget _buildAssetMetaChip(
    BuildContext context, {
    required String label,
    required IconData icon,
    bool highlight = false,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: highlight
            ? scheme.secondaryContainer.withValues(alpha: 0.8)
            : scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: highlight ? scheme.onSecondaryContainer : scheme.onSurface,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: highlight
                      ? scheme.onSecondaryContainer
                      : scheme.onSurface,
                ),
          ),
        ],
      ),
    );
  }
}
