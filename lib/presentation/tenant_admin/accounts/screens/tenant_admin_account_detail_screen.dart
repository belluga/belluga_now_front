import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

class TenantAdminAccountDetailScreen extends StatelessWidget {
  const TenantAdminAccountDetailScreen({
    super.key,
    required this.accountSlug,
  });

  final String accountSlug;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextButton.icon(
            onPressed: () => context.router.pop(),
            icon: const Icon(Icons.arrow_back),
            label: const Text('Back'),
          ),
          const SizedBox(height: 8),
          Text(
            'Account: $accountSlug',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          const Text('Status: Tenant owned'),
          const SizedBox(height: 8),
          const Text('Document: pending'),
          const SizedBox(height: 8),
          const Text('Organization: none'),
        ],
      ),
    );
  }
}
