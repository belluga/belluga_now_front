import 'package:belluga_now/presentation/tenant_admin/settings/controllers/tenant_admin_settings_controller.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/widgets/tenant_admin_xfile_preview.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:stream_value/core/stream_value_builder.dart';

typedef TenantAdminBrandingPickCallback = Future<void> Function({
  required TenantAdminBrandingAssetSlot slot,
});

typedef TenantAdminBrandingClearCallback = void Function(
  TenantAdminBrandingAssetSlot slot,
);

class TenantAdminSettingsBrandingImageField extends StatelessWidget {
  const TenantAdminSettingsBrandingImageField({
    super.key,
    required this.title,
    required this.slot,
    required this.controller,
    required this.isBusy,
    required this.onPick,
    required this.onClearLocalSelection,
  });

  final String title;
  final TenantAdminBrandingAssetSlot slot;
  final TenantAdminSettingsController controller;
  final bool isBusy;
  final TenantAdminBrandingPickCallback onPick;
  final TenantAdminBrandingClearCallback onClearLocalSelection;

  double get _aspectRatio => switch (slot) {
        TenantAdminBrandingAssetSlot.lightLogo => 18 / 5,
        TenantAdminBrandingAssetSlot.darkLogo => 18 / 5,
        TenantAdminBrandingAssetSlot.lightIcon => 1.0,
        TenantAdminBrandingAssetSlot.darkIcon => 1.0,
        TenantAdminBrandingAssetSlot.pwaIcon => 1.0,
      };

  @override
  Widget build(BuildContext context) {
    final previewWidth = _aspectRatio > 1 ? 252.0 : 108.0;
    final previewHeight = previewWidth / _aspectRatio;

    return StreamValueBuilder<XFile?>(
      streamValue: controller.brandingFileStream(slot),
      builder: (context, localFile) {
        return StreamValueBuilder<String?>(
          streamValue: controller.brandingUrlStream(slot),
          builder: (context, remoteUrl) {
            final hasRemote = remoteUrl != null && remoteUrl.trim().isNotEmpty;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.labelMedium,
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: previewWidth,
                    height: previewHeight,
                    color:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                    child: localFile != null
                        ? TenantAdminXFilePreview(
                            file: localFile,
                            width: previewWidth,
                            height: previewHeight,
                            fit: BoxFit.cover,
                          )
                        : hasRemote
                            ? Image.network(
                                remoteUrl,
                                width: previewWidth,
                                height: previewHeight,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Icon(
                                  Icons.broken_image_outlined,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                              )
                            : Icon(
                                Icons.image_outlined,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: isBusy ? null : () => onPick(slot: slot),
                      icon: const Icon(Icons.upload_outlined),
                      label: const Text('Selecionar'),
                    ),
                    if (localFile != null)
                      TextButton.icon(
                        onPressed:
                            isBusy ? null : () => onClearLocalSelection(slot),
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
}
