import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:flutter/material.dart';

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

  @override
  Widget build(BuildContext context) {
    final sampleAccounts = const [
      _AccountItem(
        slug: 'acme-events',
        ownership: OwnershipState.tenantOwned,
      ),
      _AccountItem(
        slug: 'moonlight-venue',
        ownership: OwnershipState.unmanaged,
      ),
      _AccountItem(
        slug: 'sunset-artist',
        ownership: OwnershipState.userOwned,
      ),
    ];
    final filteredAccounts = sampleAccounts
        .where((account) => account.ownership == _selected)
        .toList(growable: false);

    if (_hasError) {
      return _buildErrorState(context);
    }

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
          const Text('Não foi possível carregar as contas agora.'),
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

enum OwnershipState {
  tenantOwned('Do tenant', 'tenant_owned'),
  unmanaged('Não gerenciadas', 'unmanaged'),
  userOwned('Do usuário', 'user_owned');

  const OwnershipState(this.label, this.subtitle);

  final String label;
  final String subtitle;
}

class _AccountItem {
  const _AccountItem({
    required this.slug,
    required this.ownership,
  });

  final String slug;
  final OwnershipState ownership;
}
