import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/presentation/tenant_admin/shell/widgets/tenant_admin_dashboard_card.dart';
import 'package:flutter/material.dart';

class TenantAdminDashboardScreen extends StatelessWidget {
  const TenantAdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Visão geral',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 16),
        TenantAdminDashboardCard(
          icon: Icons.event_outlined,
          title: 'Eventos',
          description: 'Acompanhe o domínio de eventos do tenant.',
          onTap: () {
            context.router.push(const TenantAdminEventsRoute());
          },
        ),
        const SizedBox(height: 12),
        TenantAdminDashboardCard(
          icon: Icons.account_box_outlined,
          title: 'Contas',
          description: 'Gerencie contas e o perfil associado.',
          onTap: () {
            context.router.push(const TenantAdminAccountsListRoute());
          },
        ),
        const SizedBox(height: 12),
        TenantAdminDashboardCard(
          icon: Icons.apartment_outlined,
          title: 'Organizações',
          description: 'Controle organizações do tenant.',
          onTap: () {
            context.router.push(const TenantAdminOrganizationsListRoute());
          },
        ),
        const SizedBox(height: 12),
        TenantAdminDashboardCard(
          icon: Icons.category_outlined,
          title: 'Tipos de Perfil',
          description: 'Defina tipos e capacidades.',
          onTap: () {
            context.router.push(const TenantAdminProfileTypesListRoute());
          },
        ),
        const SizedBox(height: 12),
        TenantAdminDashboardCard(
          icon: Icons.account_tree_outlined,
          title: 'Taxonomias',
          description: 'Configure taxonomias e termos.',
          onTap: () {
            context.router.push(const TenantAdminTaxonomiesListRoute());
          },
        ),
        const SizedBox(height: 12),
        TenantAdminDashboardCard(
          icon: Icons.layers_outlined,
          title: 'Tipos de Ativo',
          description: 'Defina tipos estáticos e capacidades.',
          onTap: () {
            context.router.push(const TenantAdminStaticProfileTypesListRoute());
          },
        ),
        const SizedBox(height: 12),
        TenantAdminDashboardCard(
          icon: Icons.place_outlined,
          title: 'Ativos estáticos',
          description: 'Gerencie ativos e POIs do tenant.',
          onTap: () {
            context.router.push(const TenantAdminStaticAssetsListRoute());
          },
        ),
        const SizedBox(height: 12),
        TenantAdminDashboardCard(
          icon: Icons.settings_outlined,
          title: 'Configurações',
          description: 'Ajuste preferências e consulte o environment ativo.',
          onTap: () {
            context.router.push(const TenantAdminSettingsRoute());
          },
        ),
      ],
    );
  }
}
