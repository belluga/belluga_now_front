import 'package:belluga_now/presentation/tenant_admin/settings/controllers/tenant_admin_settings_controller.dart';
import 'package:flutter/material.dart';
import 'package:stream_value/core/stream_value_builder.dart';

class TenantAdminSettingsRemoteStatusPanel extends StatelessWidget {
  const TenantAdminSettingsRemoteStatusPanel({
    super.key,
    required this.controller,
    required this.onReload,
  });

  final TenantAdminSettingsController controller;
  final Future<void> Function() onReload;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return StreamValueBuilder<String?>(
      streamValue: controller.remoteErrorStreamValue,
      builder: (context, errorMessage) {
        return StreamValueBuilder<String?>(
          streamValue: controller.remoteSuccessStreamValue,
          builder: (context, successMessage) {
            return StreamValueBuilder<bool>(
              streamValue: controller.isRemoteLoadingStreamValue,
              builder: (context, isRemoteLoading) {
                if (!isRemoteLoading &&
                    (errorMessage == null || errorMessage.isEmpty) &&
                    (successMessage == null || successMessage.isEmpty)) {
                  return const SizedBox.shrink();
                }
                final hasError =
                    errorMessage != null && errorMessage.isNotEmpty;
                final message = hasError ? errorMessage : successMessage ?? '';
                return Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: hasError
                        ? scheme.errorContainer.withValues(alpha: 0.4)
                        : scheme.secondaryContainer.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: hasError
                          ? scheme.error.withValues(alpha: 0.32)
                          : scheme.outlineVariant,
                    ),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isRemoteLoading)
                        const Padding(
                          padding: EdgeInsets.only(bottom: 8),
                          child: LinearProgressIndicator(minHeight: 2),
                        ),
                      Text(
                        message,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: hasError
                                  ? scheme.onErrorContainer
                                  : scheme.onPrimaryContainer,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: [
                          OutlinedButton(
                            onPressed: isRemoteLoading ? null : onReload,
                            child: const Text('Recarregar'),
                          ),
                          if ((hasError || successMessage != null) &&
                              !isRemoteLoading)
                            TextButton(
                              onPressed: controller.clearStatusMessages,
                              child: const Text('Fechar'),
                            ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
