import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/infrastructure/repositories/tenant_admin_store.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

class TenantAdminAccountsListScreen extends StatefulWidget {
  const TenantAdminAccountsListScreen({super.key});

  @override
  State<TenantAdminAccountsListScreen> createState() =>
      _TenantAdminAccountsListScreenState();
}

class _TenantAdminAccountsListScreenState
    extends State<TenantAdminAccountsListScreen> {
  OwnershipState _selected = OwnershipState.tenantOwned;
  final bool _hasError = false;
  final _store = GetIt.I.get<TenantAdminStore>();

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return _buildErrorState(context);
    }

    return AnimatedBuilder(
      animation: _store,
      builder: (context, _) {
        final filteredAccounts = _store.accounts
            .where((account) => account.ownership == _selected)
            .toList(growable: false);

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
                      'Contas',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      context.router.push(const TenantAdminAccountCreateRoute());
                    },
                    child: const Text('Criar'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SegmentedButton<OwnershipState>(
                segments: OwnershipState.values
                    .map(
                      (state) => ButtonSegment<OwnershipState>(
                        value: state,
                        label: Text(state.label),
                      ),
                    )
                    .toList(growable: false),
                selected: <OwnershipState>{_selected},
                onSelectionChanged: (selection) {
                  if (selection.isEmpty) {
                    return;
                  }
                  setState(() => _selected = selection.first);
                },
              ),
              const SizedBox(height: 12),
              Expanded(
                child: filteredAccounts.isEmpty
                    ? _buildEmptyState(context)
                    : ListView.separated(
                        itemCount: filteredAccounts.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final account = filteredAccounts[index];
                          return ListTile(
                            title: Text(account.slug),
                            subtitle: Text(account.ownership.subtitle),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {
                              context.router.push(
                                TenantAdminAccountDetailRoute(
                                  accountSlug: account.slug,
                                ),
                              );
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Nenhuma conta neste segmento ainda.'),
          const SizedBox(height: 12),
          ElevatedButton(
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
          const Text('N??o foi poss??vel carregar as contas agora.'),
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
