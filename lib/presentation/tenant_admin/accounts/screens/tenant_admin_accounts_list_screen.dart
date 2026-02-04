import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/domain/tenant_admin/ownership_state.dart';
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
  final bool _hasError = false;
  final TenantAdminAccountsController _controller =
      GetIt.I.get<TenantAdminAccountsController>();

  @override
  void initState() {
    super.initState();
    _controller.init();
  }


  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return _buildErrorState(context);
    }

    return StreamValueBuilder<TenantAdminOwnershipState>(
      streamValue: _controller.selectedOwnershipStreamValue,
      builder: (context, selected) {
        return StreamValueBuilder(
          streamValue: _controller.accountsStreamValue,
          builder: (context, accounts) {
            final filteredAccounts = accounts
                .where((account) => account.ownershipState == selected)
                .toList(growable: false);

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
                          segments: TenantAdminOwnershipState.values
                              .map(
                                (state) =>
                                    ButtonSegment<TenantAdminOwnershipState>(
                                  value: state,
                                  label: Text(state.label),
                                ),
                              )
                              .toList(growable: false),
                          selected: <TenantAdminOwnershipState>{selected},
                          onSelectionChanged: (selection) {
                            if (selection.isEmpty) {
                              return;
                            }
                            _controller
                                .updateSelectedOwnership(selection.first);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: filteredAccounts.isEmpty
                          ? _buildEmptyState(context)
                          : ListView.separated(
                              itemCount: filteredAccounts.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final account = filteredAccounts[index];
                                return Card(
                                  clipBehavior: Clip.antiAlias,
                                  child: ListTile(
                                    leading: const CircleAvatar(
                                      child:
                                          Icon(Icons.account_circle_outlined),
                                    ),
                                    title: Text(account.slug),
                                    subtitle:
                                        Text(account.ownershipState.subtitle),
                                    trailing: const Icon(Icons.chevron_right),
                                    onTap: () {
                                      context.router.push(
                                        TenantAdminAccountDetailRoute(
                                          accountSlug: account.slug,
                                        ),
                                      );
                                    },
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
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Nenhuma conta neste segmento ainda.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () {
              context.router.push(const TenantAdminAccountCreateRoute());
            },
            child: const Text('Criar Conta'),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Nao foi possivel carregar as contas agora.'),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () {},
            child: const Text('Tentar novamente'),
          ),
        ],
      ),
    );
  }
}
