import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:flutter/material.dart';

class TenantAdminAccountProfilesListScreen extends StatelessWidget {
  const TenantAdminAccountProfilesListScreen({
    super.key,
    required this.accountSlug,
  });

  final String accountSlug;

  @override
  Widget build(BuildContext context) {
    final sampleProfiles = const [
      'principal-profile',
      'secondary-profile',
    ];

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
            'Profiles - $accountSlug',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: () {
                context.router.push(
                  TenantAdminAccountProfileCreateRoute(accountSlug: accountSlug),
                );
              },
              child: const Text('Create'),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: sampleProfiles.isEmpty
                ? _buildEmptyState()
                : ListView.separated(
                    itemCount: sampleProfiles.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final profileId = sampleProfiles[index];
                      return ListTile(
                        title: Text(profileId),
                        subtitle: const Text('artist'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          context.router.push(
                            TenantAdminAccountProfileDetailRoute(
                              accountProfileId: profileId,
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

  Widget _buildEmptyState() {
    return const Center(
      child: Text('No profiles for this account yet.'),
    );
  }
}
