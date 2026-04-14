import 'package:belluga_now/domain/tenant_admin/tenant_admin_media_upload.dart';
import 'package:belluga_now/presentation/tenant_admin/settings/controllers/tenant_admin_settings_controller.dart';
import 'package:flutter/material.dart';
import 'package:stream_value/core/stream_value_builder.dart';

class TenantAdminSettingsBrandingFaviconField extends StatelessWidget {
  const TenantAdminSettingsBrandingFaviconField({
    super.key,
    required this.controller,
    required this.isBusy,
    required this.onPick,
    required this.onClearLocalSelection,
  });

  final TenantAdminSettingsController controller;
  final bool isBusy;
  final Future<void> Function() onPick;
  final VoidCallback onClearLocalSelection;

  @override
  Widget build(BuildContext context) {
    return StreamValueBuilder<TenantAdminMediaUpload?>(
      streamValue: controller.brandingFaviconUploadStreamValue,
      builder: (context, localUpload) {
        return StreamValueBuilder<String?>(
          streamValue: controller.brandingFaviconUrlStreamValue,
          builder: (context, remoteUrl) {
            final statusText = switch ((localUpload, remoteUrl?.trim())) {
              (final upload?, _) => 'Selecionado: ${upload.fileName}',
              (_, final url?) when url.isNotEmpty =>
                'Atual: ${_displayUrl(url)}',
              _ => 'Nenhum favicon selecionado.',
            };

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Favicon (.ico)',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.language_outlined,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          statusText,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: isBusy ? null : onPick,
                      icon: const Icon(Icons.upload_file_outlined),
                      label: const Text('Selecionar .ico'),
                    ),
                    if (localUpload case final _?)
                      TextButton.icon(
                        onPressed: isBusy ? null : onClearLocalSelection,
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Limpar selecao'),
                      ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _displayUrl(String rawUrl) {
    final uri = Uri.tryParse(rawUrl);
    if (uri == null) {
      return rawUrl;
    }

    final path = uri.path.trim();
    if (path.isNotEmpty) {
      return path;
    }

    return rawUrl;
  }
}
