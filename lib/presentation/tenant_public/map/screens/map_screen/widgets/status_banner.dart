import 'package:belluga_now/presentation/tenant_public/map/screens/map_screen/controllers/map_screen_controller.dart';
import 'package:flutter/material.dart';
import 'package:stream_value/core/stream_value_builder.dart';

class StatusBanner extends StatelessWidget {
  const StatusBanner({
    super.key,
    required this.controller,
  });

  final MapScreenController controller;

  @override
  Widget build(BuildContext context) {
    final baseStyle = Theme.of(context).textTheme.bodySmall;
    return StreamValueBuilder<String?>(
      streamValue: controller.statusMessageStreamValue,
      onNullWidget: const SizedBox.shrink(),
      builder: (_, message) {
        final messageText = message ?? '';
        if (messageText.isEmpty) {
          return const SizedBox.shrink();
        }
        return Container(
          key: const ValueKey<String>('map-status-banner'),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color:
                Theme.of(context).colorScheme.surface.withValues(alpha: 0.96),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant,
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
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.info_outline,
                size: 18,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  messageText,
                  style: baseStyle?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ) ??
                      TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                iconSize: 18,
                visualDensity: VisualDensity.compact,
                onPressed: controller.clearStatusMessage,
                icon: const Icon(Icons.close),
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                tooltip: 'Fechar status',
              ),
            ],
          ),
        );
      },
    );
  }
}
