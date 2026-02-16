import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_organization.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/widgets/tenant_admin_empty_state.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/widgets/tenant_admin_error_banner.dart';
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
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
    _controller.loadOrganizations();
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
      _controller.loadNextOrganizationsPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamValueBuilder<String?>(
      streamValue: _controller.errorStreamValue,
      builder: (context, error) {
        return StreamValueBuilder<bool>(
          streamValue: _controller.hasMoreOrganizationsStreamValue,
          builder: (context, hasMore) {
            return StreamValueBuilder<bool>(
              streamValue: _controller.isOrganizationsPageLoadingStreamValue,
              builder: (context, isPageLoading) {
                return StreamValueBuilder<List<TenantAdminOrganization>?>(
                  streamValue: _controller.organizationsStreamValue,
                  onNullWidget: _buildScaffold(
                    context: context,
                    error: error,
                    body: const Center(child: CircularProgressIndicator()),
                  ),
                  builder: (context, organizations) {
                    final loadedOrganizations =
                        organizations ?? const <TenantAdminOrganization>[];
                    return _buildScaffold(
                      context: context,
                      error: error,
                      body: loadedOrganizations.isEmpty
                          ? const TenantAdminEmptyState(
                              icon: Icons.apartment_outlined,
                              title: 'Nenhuma organização cadastrada',
                              description:
                                  'Crie uma organização para agrupar contas deste tenant.',
                            )
                          : _buildOrganizationsList(
                              organizations: loadedOrganizations,
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
  }

  Widget _buildOrganizationsList({
    required List<TenantAdminOrganization> organizations,
    required bool hasMore,
    required bool isPageLoading,
  }) {
    final itemCount = organizations.length + (hasMore ? 1 : 0);
    return ListView.separated(
      controller: _scrollController,
      padding: const EdgeInsets.only(bottom: 112),
      itemCount: itemCount,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        if (index >= organizations.length) {
          if (isPageLoading) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          return const SizedBox.shrink();
        }
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
    );
  }

  Widget _buildScaffold({
    required BuildContext context,
    required String? error,
    required Widget body,
  }) {
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
            if (error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: TenantAdminErrorBanner(
                  rawError: error,
                  fallbackMessage: 'Não foi possível carregar as organizações.',
                  onRetry: _controller.loadOrganizations,
                ),
              ),
            const SizedBox(height: 8),
            Expanded(child: body),
          ],
        ),
      ),
    );
  }
}
