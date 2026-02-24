import 'package:auto_route/auto_route.dart';
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
            ],
          ),
        ),
      ),
    );
  }
}
