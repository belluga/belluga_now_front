import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

class TenantAdminOrganizationDetailScreen extends StatelessWidget {
  const TenantAdminOrganizationDetailScreen({
    super.key,
    required this.organizationId,
  });

  final String organizationId;

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
            'Organization: $organizationId',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          const Text('Name: Example Organization'),
          const SizedBox(height: 8),
          const Text('Slug: example-org'),
        ],
      ),
    );
  }
}
