import 'package:belluga_now/presentation/tenant_admin/shared/models/tenant_admin_error_state.dart';
import 'package:flutter/material.dart';

class TenantAdminErrorBanner extends StatelessWidget {
  const TenantAdminErrorBanner({
    super.key,
    required this.rawError,
    required this.fallbackMessage,
    required this.onRetry,
  });

  final String rawError;
  final String fallbackMessage;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final errorState = resolveTenantAdminErrorState(
      rawError,
      fallbackMessage: fallbackMessage,
    );

    return Card(
      margin: EdgeInsets.zero,
      color: Theme.of(context).colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              errorState.userMessage,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onErrorContainer,
                  ),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar novamente'),
            ),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              childrenPadding: EdgeInsets.zero,
              title: Text(
                'Detalhes técnicos',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
              ),
              iconColor: Theme.of(context).colorScheme.onErrorContainer,
              collapsedIconColor: Theme.of(context).colorScheme.onErrorContainer,
              children: [
                SelectableText(
                  errorState.technicalDetails,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onErrorContainer,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
