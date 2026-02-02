import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/presentation/tenant_admin/organizations/controllers/tenant_admin_organizations_controller.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value_builder.dart';

class TenantAdminOrganizationsListScreen extends StatefulWidget {
  const TenantAdminOrganizationsListScreen({super.key});

  @override
  State<TenantAdminOrganizationsListScreen> createState() =>
      _TenantAdminOrganizationsListScreenState();
}

class _TenantAdminOrganizationsListScreenState
    extends State<TenantAdminOrganizationsListScreen> {
  final TenantAdminOrganizationsController _controller =
      GetIt.I.get<TenantAdminOrganizationsController>();

  @override
  void initState() {
    super.initState();
    _controller.loadOrganizations();
  }

  @override
  Widget build(BuildContext context) {
    return StreamValueBuilder(
      streamValue: _controller.organizationsStreamValue,
      builder: (context, organizations) {
        return Scaffold(
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () {
              context.router.push(const TenantAdminOrganizationCreateRoute());
            },
            icon: const Icon(Icons.add),
            label: const Text('Criar organizacao'),
          ),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Organizacoes cadastradas',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: organizations.isEmpty
                      ? _buildEmptyState(context)
                      : ListView.separated(
                          itemCount: organizations.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final org = organizations[index];
                            return Card(
                              clipBehavior: Clip.antiAlias,
                              child: ListTile(
                                title: Text(org.name),
                                subtitle: Text(org.id),
                                trailing: const Icon(Icons.chevron_right),
                                onTap: () {
                                  context.router.push(
                                    TenantAdminOrganizationDetailRoute(
                                      organizationId: org.id,
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
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Nenhuma organizacao ainda.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () {
              context.router.push(const TenantAdminOrganizationCreateRoute());
            },
            child: const Text('Criar organizacao'),
          ),
        ],
      ),
    );
  }
}
