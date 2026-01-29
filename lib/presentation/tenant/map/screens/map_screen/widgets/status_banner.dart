import 'package:belluga_now/presentation/tenant/map/screens/map_screen/controllers/map_screen_controller.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value_builder.dart';

class StatusBanner extends StatefulWidget {
  const StatusBanner({super.key});
  @override
  State<StatusBanner> createState() => _StatusBannerState();
}

class _StatusBannerState extends State<StatusBanner> {
  final _controller = GetIt.I.get<MapScreenController>();

  @override
  Widget build(BuildContext context) {
    final baseStyle = Theme.of(context).textTheme.bodySmall;
    return StreamValueBuilder<String>(
      streamValue: _controller.statusMessageStreamValue,
      onNullWidget: SizedBox.shrink(),
      builder: (_, message) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            message,
            style: baseStyle?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ) ??
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
          ),
        );
      },
    );
  }
}
