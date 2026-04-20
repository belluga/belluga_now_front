import 'package:belluga_now/domain/tenant_admin/tenant_admin_media_upload.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_settings.dart';
import 'package:belluga_now/presentation/tenant_admin/settings/controllers/tenant_admin_settings_controller.dart';
import 'package:belluga_now/presentation/tenant_admin/settings/tenant_admin_settings_keys.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/widgets/tenant_admin_favicon_preview.dart';
import 'package:flutter/material.dart';
import 'package:stream_value/core/stream_value_builder.dart';

class TenantAdminSettingsBrandingFaviconField extends StatelessWidget {
  const TenantAdminSettingsBrandingFaviconField({
    super.key,
    required this.controller,
    required this.isBusy,
    required this.onPick,
    required this.onClearLocalSelection,
    this.selectSemanticsLabel = 'Selecionar favicon',
  });

  final TenantAdminSettingsController controller;
  final bool isBusy;
  final Future<void> Function() onPick;
  final VoidCallback onClearLocalSelection;
  final String selectSemanticsLabel;

  @override
  Widget build(BuildContext context) {
    return StreamValueBuilder<TenantAdminMediaUpload?>(
      streamValue: controller.brandingFaviconUploadStreamValue,
      builder: (context, localUpload) {
        return StreamValueBuilder<String?>(
          streamValue: controller.brandingFaviconUrlStreamValue,
          builder: (context, remoteUrl) {
            return StreamValueBuilder<TenantAdminBrandingSettings?>(
              streamValue: controller.brandingSettingsStreamValue,
              builder: (context, settings) {
                final colorScheme = Theme.of(context).colorScheme;
                final publicRoute = _displayPublicRoute(remoteUrl);
                final remoteStatus = _buildRemoteStatus(
                  settings,
                  publicRoute: publicRoute,
                );
                final status = switch (localUpload) {
                  final upload? => (
                      title: 'Arquivo local pronto para salvar',
                      description:
                          '${upload.fileName}. Salve o branding para publicar este .ico em $publicRoute.',
                      icon: Icons.pending_actions_outlined,
                      color: colorScheme.primary,
                    ),
                  _ => remoteStatus,
                };
                final previewDescription = _buildPreviewDescription(
                  settings,
                  localUpload: localUpload,
                  publicRoute: publicRoute,
                );

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Favicon (.ico)',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        key: TenantAdminSettingsKeys.brandingFaviconPreview,
                        width: 108,
                        height: 108,
                        color: colorScheme.surfaceContainerHighest,
                        padding: const EdgeInsets.all(14),
                        child: TenantAdminFaviconPreview(
                          bytes: localUpload?.bytes,
                          mimeType: localUpload?.mimeType,
                          remoteUrl: switch (localUpload) {
                            final _? => null,
                            null => remoteUrl,
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      previewDescription,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(status.icon, color: status.color),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  status.title,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  status.description,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'O navegador sempre consome /favicon.ico. Sem um .ico dedicado salvo, '
                      'essa rota usa fallback do icone PWA.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Semantics(
                          button: true,
                          label: selectSemanticsLabel,
                          child: OutlinedButton.icon(
                            onPressed: isBusy ? null : onPick,
                            icon: const Icon(Icons.upload_file_outlined),
                            label: const Text('Selecionar'),
                          ),
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
      },
    );
  }

  ({
    Color color,
    String description,
    IconData icon,
    String title,
  }) _buildRemoteStatus(
    TenantAdminBrandingSettings? settings, {
    required String publicRoute,
  }) {
    if (settings?.hasDedicatedFavicon == true) {
      return (
        title: '.ico dedicado salvo',
        description: 'Publicacao atual: $publicRoute',
        icon: Icons.verified_outlined,
        color: Colors.green,
      );
    }

    if (settings?.usesPwaFaviconFallback == true) {
      return (
        title: 'Fallback ativo pelo icone PWA',
        description: 'Publicacao atual: $publicRoute',
        icon: Icons.swap_horiz_outlined,
        color: Colors.orange,
      );
    }

    return (
      title: 'Estado remoto do favicon indisponivel',
      description: 'Publicacao atual: $publicRoute',
      icon: Icons.help_outline,
      color: Colors.orange,
    );
  }

  String _buildPreviewDescription(
    TenantAdminBrandingSettings? settings, {
    required TenantAdminMediaUpload? localUpload,
    required String publicRoute,
  }) {
    if (localUpload != null) {
      return 'Preview local do .ico selecionado. Ao salvar, ele sera publicado em $publicRoute.';
    }

    if (settings?.usesPwaFaviconFallback == true) {
      return 'Preview atualmente entregue por $publicRoute via fallback do icone PWA.';
    }

    if (settings?.hasDedicatedFavicon == true) {
      return 'Preview atualmente publicado em $publicRoute.';
    }

    return 'Preview esperado de $publicRoute.';
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

  String _displayPublicRoute(String? rawUrl) {
    final normalized = rawUrl?.trim();
    if (normalized == null || normalized.isEmpty) {
      return '/favicon.ico';
    }

    return _displayUrl(normalized);
  }
}
