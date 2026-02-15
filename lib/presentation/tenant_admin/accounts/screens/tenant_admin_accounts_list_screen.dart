import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/domain/tenant_admin/ownership_state.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_account.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/widgets/tenant_admin_empty_state.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/widgets/tenant_admin_error_banner.dart';
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
  final TenantAdminAccountsController _controller =
      GetIt.I.get<TenantAdminAccountsController>();
  final ScrollController _scrollController = ScrollController();

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

  @override
  Widget build(BuildContext context) {
    return StreamValueBuilder<String?>(
      streamValue: _controller.errorStreamValue,
      builder: (context, error) {
        return StreamValueBuilder<TenantAdminOwnershipState>(
          streamValue: _controller.selectedOwnershipStreamValue,
          builder: (context, selected) {
            return StreamValueBuilder<bool>(
              streamValue: _controller.hasMoreAccountsStreamValue,
              builder: (context, hasMore) {
                return StreamValueBuilder<bool>(
                  streamValue: _controller.isAccountsPageLoadingStreamValue,
                  builder: (context, isPageLoading) {
                    return StreamValueBuilder<List<TenantAdminAccount>?>(
                      streamValue: _controller.accountsStreamValue,
                      onNullWidget: _buildScaffold(
                        context: context,
                        selectedOwnership: selected,
                        error: error,
                        content: const Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      builder: (context, accounts) {
                        final loadedAccounts =
                            accounts ?? const <TenantAdminAccount>[];
                        final filteredAccounts = loadedAccounts
                            .where(
                              (account) => account.ownershipState == selected,
                            )
                            .toList(growable: false);

                        return _buildScaffold(
                          context: context,
                          selectedOwnership: selected,
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
  }

  Widget _buildScaffold({
    required BuildContext context,
    required TenantAdminOwnershipState selectedOwnership,
    required String? error,
    required Widget content,
  }) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          context.router.push(const TenantAdminAccountCreateRoute());
        },
        icon: const Icon(Icons.add),
        label: const Text('Criar conta'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Segmento',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: SegmentedButton<TenantAdminOwnershipState>(
                  style: const ButtonStyle(
                    tapTargetSize: MaterialTapTargetSize.padded,
                    visualDensity: VisualDensity.standard,
                  ),
                  segments: TenantAdminOwnershipState.values
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
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () {
                  context.router.push(const TenantAdminProfileTypesListRoute());
                },
                icon: const Icon(Icons.category_outlined),
                label: const Text('Gerenciar tipos de perfil'),
              ),
            ),
            if (error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: TenantAdminErrorBanner(
                  rawError: error,
                  fallbackMessage:
                      'Não foi possível carregar as contas do tenant.',
                  onRetry: _controller.loadAccounts,
                ),
              ),
            const SizedBox(height: 8),
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
        return Card(
          clipBehavior: Clip.antiAlias,
          child: ListTile(
            leading: const CircleAvatar(
              child: Icon(Icons.account_circle_outlined),
            ),
            title: Text(account.slug),
            subtitle: Text(account.ownershipState.subtitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              context.router.push(
                TenantAdminAccountDetailRoute(accountSlug: account.slug),
              );
            },
          ),
        );
      },
    );
  }
}
