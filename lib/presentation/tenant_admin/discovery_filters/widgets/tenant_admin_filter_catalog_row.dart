import 'package:belluga_now/domain/tenant_admin/tenant_admin_settings.dart';
import 'package:belluga_now/presentation/shared/icons/map_marker_visual_resolver.dart';
import 'package:belluga_now/presentation/shared/widgets/belluga_network_image.dart';
import 'package:flutter/material.dart';

class TenantAdminFilterCatalogRow extends StatelessWidget {
  const TenantAdminFilterCatalogRow({
    super.key,
    required this.visualPreviewKey,
    required this.ruleButtonKey,
    required this.visualButtonKey,
    required this.label,
    required this.secondaryLabel,
    required this.ruleSummary,
    required this.supportsMarkerOverride,
    required this.overrideMarker,
    required this.markerOverride,
    required this.imageUri,
    required this.visualButtonLabel,
    required this.hasPrevious,
    required this.hasNext,
    required this.onEditKey,
    required this.onEditLabel,
    required this.onEditRule,
    required this.onEditVisual,
    required this.onRemove,
    required this.onMoveUp,
    required this.onMoveDown,
  });

  final Key visualPreviewKey;
  final Key? ruleButtonKey;
  final Key? visualButtonKey;
  final String label;
  final String secondaryLabel;
  final String ruleSummary;
  final bool supportsMarkerOverride;
  final bool overrideMarker;
  final TenantAdminMapFilterMarkerOverride? markerOverride;
  final String? imageUri;
  final String visualButtonLabel;
  final bool hasPrevious;
  final bool hasNext;
  final VoidCallback onEditKey;
  final VoidCallback onEditLabel;
  final VoidCallback onEditRule;
  final VoidCallback onEditVisual;
  final VoidCallback onRemove;
  final VoidCallback onMoveUp;
  final VoidCallback onMoveDown;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final visual = _TenantAdminFilterCatalogRowVisual.resolve(
      supportsMarkerOverride: supportsMarkerOverride,
      overrideMarker: overrideMarker,
      markerOverride: markerOverride,
      imageUri: imageUri,
    );
    final visualBackgroundColor = switch (visual.kind) {
      _TenantAdminFilterCatalogRowVisualKind.icon =>
        (MapMarkerVisualResolver.tryParseHexColor(visual.color) ??
                theme.colorScheme.surfaceContainerHighest)
            .withValues(alpha: 0.22),
      _ => theme.colorScheme.surfaceContainerHighest,
    };

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  key: visualPreviewKey,
                  width: 56,
                  height: 56,
                  color: visualBackgroundColor,
                  child: switch (visual.kind) {
                    _TenantAdminFilterCatalogRowVisualKind.image =>
                      BellugaNetworkImage(
                        visual.imageUri!,
                        key: ValueKey<String>(visual.imageUri!),
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                        errorWidget: Icon(
                          Icons.broken_image_outlined,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    _TenantAdminFilterCatalogRowVisualKind.icon => Icon(
                        MapMarkerVisualResolver.resolveIcon(visual.icon),
                        color: MapMarkerVisualResolver.tryParseHexColor(
                              visual.iconColor,
                            ) ??
                            theme.colorScheme.onSurfaceVariant,
                      ),
                    _TenantAdminFilterCatalogRowVisualKind.fallback => Icon(
                        Icons.filter_alt_outlined,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: theme.textTheme.titleSmall),
                    const SizedBox(height: 2),
                    Text(
                      secondaryLabel,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      ruleSummary,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: onEditKey,
                icon: const Icon(Icons.vpn_key_outlined),
                label: const Text('Chave'),
              ),
              OutlinedButton.icon(
                onPressed: onEditLabel,
                icon: const Icon(Icons.label_outline),
                label: const Text('Rótulo'),
              ),
              OutlinedButton.icon(
                key: ruleButtonKey,
                onPressed: onEditRule,
                icon: const Icon(Icons.rule_outlined),
                label: const Text('Regra'),
              ),
              OutlinedButton.icon(
                key: visualButtonKey,
                onPressed: onEditVisual,
                icon: const Icon(Icons.palette_outlined),
                label: Text(visualButtonLabel),
              ),
              OutlinedButton.icon(
                onPressed: hasPrevious ? onMoveUp : null,
                icon: const Icon(Icons.arrow_upward),
                label: const Text('Subir'),
              ),
              OutlinedButton.icon(
                onPressed: hasNext ? onMoveDown : null,
                icon: const Icon(Icons.arrow_downward),
                label: const Text('Descer'),
              ),
              TextButton.icon(
                onPressed: onRemove,
                icon: const Icon(Icons.delete_outline),
                label: const Text('Remover'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

enum _TenantAdminFilterCatalogRowVisualKind {
  icon,
  image,
  fallback,
}

class _TenantAdminFilterCatalogRowVisual {
  const _TenantAdminFilterCatalogRowVisual.icon({
    required this.icon,
    required this.color,
    required this.iconColor,
  })  : kind = _TenantAdminFilterCatalogRowVisualKind.icon,
        imageUri = null;

  const _TenantAdminFilterCatalogRowVisual.image({
    required this.imageUri,
  })  : kind = _TenantAdminFilterCatalogRowVisualKind.image,
        icon = null,
        color = null,
        iconColor = null;

  const _TenantAdminFilterCatalogRowVisual.fallback()
      : kind = _TenantAdminFilterCatalogRowVisualKind.fallback,
        icon = null,
        color = null,
        iconColor = null,
        imageUri = null;

  factory _TenantAdminFilterCatalogRowVisual.resolve({
    required bool supportsMarkerOverride,
    required bool overrideMarker,
    required TenantAdminMapFilterMarkerOverride? markerOverride,
    required String? imageUri,
  }) {
    if (supportsMarkerOverride &&
        overrideMarker &&
        markerOverride?.isValid == true) {
      if (markerOverride!.mode == TenantAdminMapFilterMarkerOverrideMode.icon) {
        return _TenantAdminFilterCatalogRowVisual.icon(
          icon: markerOverride.icon ?? '',
          color: markerOverride.color,
          iconColor: markerOverride.iconColor,
        );
      }
      final overrideImageUri = markerOverride.imageUri?.trim();
      if (overrideImageUri != null && overrideImageUri.isNotEmpty) {
        return _TenantAdminFilterCatalogRowVisual.image(
          imageUri: overrideImageUri,
        );
      }
      return const _TenantAdminFilterCatalogRowVisual.fallback();
    }

    final fallbackImageUri = imageUri?.trim();
    if (fallbackImageUri != null && fallbackImageUri.isNotEmpty) {
      return _TenantAdminFilterCatalogRowVisual.image(
        imageUri: fallbackImageUri,
      );
    }

    return const _TenantAdminFilterCatalogRowVisual.fallback();
  }

  final _TenantAdminFilterCatalogRowVisualKind kind;
  final String? icon;
  final String? color;
  final String? iconColor;
  final String? imageUri;
}
