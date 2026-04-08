import 'package:belluga_now/presentation/tenant_public/map/screens/map_screen/controllers/map_screen_controller.dart';
import 'package:flutter/material.dart';
import 'package:stream_value/core/stream_value_builder.dart';

class MapSoftLocationNoticeBanner extends StatelessWidget {
  const MapSoftLocationNoticeBanner({
    super.key,
    required this.controller,
  });

  final MapScreenController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return StreamValueBuilder<String>(
      streamValue: controller.softLocationNoticeStreamValue,
      builder: (context, message) {
        if (message.trim().isEmpty) {
          return const SizedBox.shrink();
        }

        return Center(
          child: Container(
            key: const ValueKey<String>('map-soft-location-notice-banner'),
            padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
            decoration: BoxDecoration(
              color: colorScheme.surface.withValues(alpha: 0.96),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: colorScheme.outlineVariant,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 14,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline,
                  size: 18,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    message,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface,
                      height: 1.3,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  iconSize: 18,
                  visualDensity: VisualDensity.compact,
                  onPressed: controller.dismissSoftLocationNotice,
                  icon: const Icon(Icons.close),
                  color: colorScheme.onSurfaceVariant,
                  tooltip: 'Fechar aviso',
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
