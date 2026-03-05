import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:flutter/material.dart';

class AccountWorkspacePlaceholderScreen extends StatelessWidget {
  const AccountWorkspacePlaceholderScreen({
    this.accountSlug,
    super.key,
  });

  final String? accountSlug;

  @override
  Widget build(BuildContext context) {
    final title = accountSlug == null || accountSlug!.trim().isEmpty
        ? 'Account Workspace'
        : 'Account Workspace: ${accountSlug!.trim()}';

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => context.router.pop(),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Back'),
              ),
              if (accountSlug != null && accountSlug!.trim().isNotEmpty) ...[
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () {
                    context.router.push(
                      AccountWorkspaceCreateEventRoute(
                        accountSlug: accountSlug!.trim(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.event_available_outlined),
                  label: const Text('Create Own Event'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
