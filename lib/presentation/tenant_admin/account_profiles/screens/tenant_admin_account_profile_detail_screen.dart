import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

class TenantAdminAccountProfileDetailScreen extends StatelessWidget {
  const TenantAdminAccountProfileDetailScreen({
    super.key,
    required this.accountProfileId,
  });

  final String accountProfileId;

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
            'Profile: $accountProfileId',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          const Text('Type: artist'),
          const SizedBox(height: 8),
          const Text('Display name: Example profile'),
          const SizedBox(height: 8),
          const Text('Capabilities: favoritable'),
        ],
      ),
    );
  }
}
