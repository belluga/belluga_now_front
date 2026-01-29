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
  late final TenantAdminOrganizationsController _controller;

  @override
  void initState() {
    super.initState();
    _controller = GetIt.I.get<TenantAdminOrganizationsController>();
    _controller.loadOrganizations();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamValueBuilder(
      streamValue: _controller.organizationsStreamValue,
      builder: (context, organizations) {
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
                      'Organizações',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      context.router.push(const TenantAdminOrganizationCreateRoute());
                    },
                    child: const Text('Criar'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: organizations.isEmpty
                    ? _buildEmptyState()
                    : ListView.separated(
                        itemCount: organizations.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final org = organizations[index];
                          return ListTile(
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

  Widget _buildEmptyState() {
    return const Center(
      child: Text('Nenhuma organização ainda.'),
    );
  }
}
