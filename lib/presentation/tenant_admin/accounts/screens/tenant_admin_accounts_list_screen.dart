import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/domain/tenant_admin/ownership_state.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_account.dart';
import 'package:belluga_now/presentation/common/widgets/belluga_network_image.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/widgets/tenant_admin_empty_state.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/widgets/tenant_admin_error_banner.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/widgets/tenant_admin_list_controls_panel.dart';
import 'package:belluga_now/presentation/tenant_admin/accounts/controllers/tenant_admin_accounts_controller.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value_builder.dart';

class TenantAdminAccountsListScreen extends StatefulWidget {
  const TenantAdminAccountsListScreen({super.key});

  @override
  State<TenantAdminAccountsListScreen> createState() =>
      _TenantAdminAccountsListScreenState();
}

class _TenantAdminAccountsListScreenState
    extends State<TenantAdminAccountsListScreen> {
  static const List<TenantAdminOwnershipState> _visibleOwnershipSegments =
      <TenantAdminOwnershipState>[
    TenantAdminOwnershipState.tenantOwned,
    TenantAdminOwnershipState.unmanaged,
  ];

  final TenantAdminAccountsController _controller =
      GetIt.I.get<TenantAdminAccountsController>();
  final ScrollController _scrollController = ScrollController();
  static const ValueKey<String> _controlsPanelKey =
      ValueKey<String>('tenant_admin_accounts_controls_panel');
  static const ValueKey<String> _searchToggleKey =
      ValueKey<String>('tenant_admin_accounts_search_toggle');
  static const ValueKey<String> _searchFieldKey =
      ValueKey<String>('tenant_admin_accounts_search_field');
  static const ValueKey<String> _manageTypesButtonKey =
      ValueKey<String>('tenant_admin_accounts_manage_types_button');
  static const ValueKey<String> _ownershipSegmentedKey =
      ValueKey<String>('tenant_admin_accounts_segmented_filter');

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
    _controller.init();
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
      _controller.loadNextAccountsPage();
    }
  }

  StackRouter _navigationRouter(BuildContext context) {
    final shellRouter =
        context.innerRouterOf<StackRouter>(TenantAdminShellRoute.name);
    return shellRouter ?? context.router;
  }

  @override
  Widget build(BuildContext context) {
    return StreamValueBuilder<String?>(
      streamValue: _controller.errorStreamValue,
      builder: (context, error) {
        return StreamValueBuilder<TenantAdminOwnershipState>(
          streamValue: _controller.selectedOwnershipStreamValue,
          builder: (context, selected) {
            final selectedOwnership =
                _visibleOwnershipSegments.contains(selected)
                    ? selected
                    : TenantAdminOwnershipState.tenantOwned;
            return StreamValueBuilder<bool>(
              streamValue: _controller.showSearchFieldStreamValue,
              builder: (context, showSearchField) {
                return StreamValueBuilder<String>(
                  streamValue: _controller.searchQueryStreamValue,
                  builder: (context, query) {
                    return StreamValueBuilder<bool>(
                      streamValue: _controller.hasMoreAccountsStreamValue,
                      builder: (context, hasMore) {
                        return StreamValueBuilder<bool>(
                          streamValue:
                              _controller.isAccountsPageLoadingStreamValue,
                          builder: (context, isPageLoading) {
                            return StreamValueBuilder<
                                List<TenantAdminAccount>?>(
                              streamValue: _controller.accountsStreamValue,
                              onNullWidget: _buildScaffold(
                                context: context,
                                selectedOwnership: selectedOwnership,
                                showSearchField: showSearchField,
                                error: error,
                                content: const Center(
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                              builder: (context, accounts) {
                                final loadedAccounts =
                                    accounts ?? const <TenantAdminAccount>[];
                                final filteredAccounts = _filterAccounts(
                                  loadedAccounts: loadedAccounts,
                                  selectedOwnership: selectedOwnership,
                                  query: query.trim(),
                                );

                                return _buildScaffold(
                                  context: context,
                                  selectedOwnership: selectedOwnership,
                                  showSearchField: showSearchField,
                                  error: error,
                                  content: filteredAccounts.isEmpty
                                      ? const TenantAdminEmptyState(
                                          icon: Icons.group_off_outlined,
                                          title: 'Nenhuma conta encontrada',
                                          description:
                                              'Crie a primeira conta deste segmento usando o botão "Criar conta".',
                                        )
                                      : _buildAccountsList(
                                          filteredAccounts: filteredAccounts,
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

  Widget _buildScaffold({
    required BuildContext context,
    required TenantAdminOwnershipState selectedOwnership,
    required bool showSearchField,
    required String? error,
    required Widget content,
  }) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final router = _navigationRouter(context);
          final messenger = ScaffoldMessenger.of(context);
          final created = await router.push<bool>(
            const TenantAdminAccountCreateRoute(),
          );
          if (!mounted || created != true) {
            return;
          }
          messenger.showSnackBar(
            const SnackBar(content: Text('Conta e perfil salvos.')),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Criar conta'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TenantAdminListControlsPanel(
              key: _controlsPanelKey,
              filterLabel: 'Segmentação de contas',
              showSearchField: showSearchField,
              onToggleSearch: _controller.toggleSearchFieldVisibility,
              onSearchChanged: _controller.updateSearchQuery,
              searchHintText: 'Nome, slug ou documento',
              manageButtonLabel: 'Tipos de perfil',
              onManagePressed: () {
                _navigationRouter(context).push(
                  const TenantAdminProfileTypesListRoute(),
                );
              },
              searchToggleKey: _searchToggleKey,
              searchFieldKey: _searchFieldKey,
              manageButtonKey: _manageTypesButtonKey,
              filterField: SizedBox(
                width: double.infinity,
                child: SegmentedButton<TenantAdminOwnershipState>(
                  key: _ownershipSegmentedKey,
                  style: const ButtonStyle(
                    tapTargetSize: MaterialTapTargetSize.padded,
                    visualDensity: VisualDensity.standard,
                  ),
                  segments: _visibleOwnershipSegments
                      .map(
                        (state) => ButtonSegment<TenantAdminOwnershipState>(
                          value: state,
                          label: Text(state.label),
                        ),
                      )
                      .toList(growable: false),
                  selected: <TenantAdminOwnershipState>{selectedOwnership},
                  onSelectionChanged: (selection) {
                    if (selection.isEmpty) {
                      return;
                    }
                    _controller.updateSelectedOwnership(selection.first);
                  },
                ),
              ),
            ),
            if (error != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: TenantAdminErrorBanner(
                  rawError: error,
                  fallbackMessage:
                      'Não foi possível carregar as contas do tenant.',
                  onRetry: _controller.loadAccounts,
                ),
              ),
            const SizedBox(height: 12),
            Expanded(child: content),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountsList({
    required List<TenantAdminAccount> filteredAccounts,
    required bool hasMore,
    required bool isPageLoading,
  }) {
    final itemCount = filteredAccounts.length + (hasMore ? 1 : 0);
    return ListView.separated(
      controller: _scrollController,
      padding: const EdgeInsets.only(bottom: 112),
      itemCount: itemCount,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        if (index >= filteredAccounts.length) {
          if (isPageLoading) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          return const SizedBox.shrink();
        }
        final account = filteredAccounts[index];
        final displayName =
            account.name.trim().isNotEmpty ? account.name : account.slug;
        return Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            key: ValueKey<String>('tenant_admin_account_card_${account.id}'),
            onTap: () {
              _navigationRouter(context).push(
                TenantAdminAccountDetailRoute(accountSlug: account.slug),
              );
            },
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildAccountAvatar(context, account),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          account.slug,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
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
                            _buildAccountMetaChip(
                              context,
                              label: account.ownershipState.label,
                            ),
                            if (account.document.number.trim().isNotEmpty)
                              _buildAccountMetaChip(
                                context,
                                label:
                                    '${account.document.type.toUpperCase()}: ${account.document.number}',
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.chevron_right,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAccountAvatar(BuildContext context, TenantAdminAccount account) {
    final avatarUrl = account.avatarUrl;
    if (avatarUrl != null && avatarUrl.trim().isNotEmpty) {
      return BellugaNetworkImage(
        avatarUrl,
        width: 40,
        height: 40,
        fit: BoxFit.cover,
        clipBorderRadius: BorderRadius.circular(20),
        errorWidget: CircleAvatar(
          backgroundColor:
              Theme.of(context).colorScheme.surfaceContainerHighest,
          child: const Icon(Icons.account_circle_outlined),
        ),
      );
    }
    return CircleAvatar(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: const Icon(Icons.account_circle_outlined),
    );
  }

  Widget _buildAccountMetaChip(
    BuildContext context, {
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium,
      ),
    );
  }

  List<TenantAdminAccount> _filterAccounts({
    required List<TenantAdminAccount> loadedAccounts,
    required TenantAdminOwnershipState selectedOwnership,
    required String query,
  }) {
    final byOwnership = loadedAccounts
        .where(
          (account) => tenantAdminAccountMatchesOwnershipSegment(
            selectedOwnership: selectedOwnership,
            accountOwnership: account.ownershipState,
          ),
        )
        .toList(growable: false);

    if (query.isEmpty) {
      return byOwnership;
    }

    final needle = query.toLowerCase();
    return byOwnership
        .where(
          (account) =>
              account.name.toLowerCase().contains(needle) ||
              account.slug.toLowerCase().contains(needle) ||
              account.document.number.toLowerCase().contains(needle),
        )
        .toList(growable: false);
  }
}

@visibleForTesting
bool tenantAdminAccountMatchesOwnershipSegment({
  required TenantAdminOwnershipState selectedOwnership,
  required TenantAdminOwnershipState accountOwnership,
}) {
  return accountOwnership == selectedOwnership;
}
