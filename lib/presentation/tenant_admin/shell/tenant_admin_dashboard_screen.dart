import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:flutter/material.dart';

class TenantAdminDashboardScreen extends StatelessWidget {
  const TenantAdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Admin Dashboard',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        ListTile(
          title: const Text('Accounts'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            context.router.push(const TenantAdminAccountsListRoute());
          },
        ),
        ListTile(
          title: const Text('Account Profiles'),
          subtitle: const Text('Select an account first'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            context.router.push(const TenantAdminAccountsListRoute());
          },
        ),
        ListTile(
          title: const Text('Organizations'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            context.router.push(const TenantAdminOrganizationsListRoute());
          },
        ),
        const Divider(),
        const ListTile(
          title: Text('Events'),
          subtitle: Text('Coming soon'),
          trailing: Icon(Icons.lock_outline),
          enabled: false,
        ),
      ],
    );
  }
}
