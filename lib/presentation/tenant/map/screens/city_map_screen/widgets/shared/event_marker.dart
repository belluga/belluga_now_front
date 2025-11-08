import 'package:belluga_now/domain/schedule/event_model.dart';
import 'package:belluga_now/presentation/tenant/map/screens/city_map_screen/widgets/shared/event_badge_chip.dart';
import 'package:belluga_now/presentation/tenant/map/screens/city_map_screen/widgets/shared/event_temporal_state.dart';
import 'package:belluga_now/presentation/tenant/map/screens/city_map_screen/widgets/shared/marker_core.dart';
import 'package:belluga_now/presentation/tenant/map/screens/city_map_screen/widgets/shared/marker_pulse_circle.dart';
import 'package:flutter/material.dart';

class EventMarker extends StatefulWidget {
  const EventMarker({
    super.key,
    required this.event,
    required this.isSelected,
  });

  final EventModel event;
  final bool isSelected;

  @override
  State<EventMarker> createState() => _EventMarkerState();
}

class _EventMarkerState extends State<EventMarker>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseColor = widget.event.type.color.value;
    final now = DateTime.now();
    final state = resolveEventTemporalState(widget.event, reference: now);
    final scale = widget.isSelected ? 1.1 : 1.0;
    final badgeColor = _badgeColorForState(state, baseColor);
    final coreSize = state == CityEventTemporalState.now ? 56.0 : 52.0;
    final frameSize =
        state == CityEventTemporalState.now ? coreSize * 1.65 : coreSize * 1.28;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final progress = _controller.value;
        final isLive = state == CityEventTemporalState.now;

        Widget marker = SizedBox(
          width: frameSize,
          height: frameSize,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              if (isLive) ...[
                MarkerPulseCircle(
                  progress: progress,
                  color: baseColor,
                  maxSize: coreSize * 2.1,
                ),
                MarkerPulseCircle(
                  progress: (progress + 0.45) % 1.0,
                  color: baseColor,
                  maxSize: coreSize * 1.75,
                ),
              ],
              Transform.scale(
                scale: scale,
                child: MarkerCore(
                  event: widget.event,
                  state: state,
                  activeColor: baseColor,
                  size: coreSize,
                ),
              ),
              Positioned(
                bottom: 4,
                child: EventBadgeChip(
                  color: badgeColor,
                  label: _badgeLabelForState(state, widget.event),
                  dimmed: state == CityEventTemporalState.past,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                ),
              ),
            ],
          ),
        );

        if (state == CityEventTemporalState.past) {
          marker = ColorFiltered(
            colorFilter: const ColorFilter.matrix(<double>[
              0.2126,
              0.7152,
              0.0722,
              0,
              0,
              0.2126,
              0.7152,
              0.0722,
              0,
              0,
              0.2126,
              0.7152,
              0.0722,
              0,
              0,
              0,
              0,
              0,
              1,
              0,
            ]),
            child: Opacity(
              opacity: 0.1,
              child: marker,
            ),
          );
        }

        return marker;
      },
    );
  }

  Color _badgeColorForState(CityEventTemporalState state, Color baseColor) {
    switch (state) {
      case CityEventTemporalState.now:
        return const Color(0xFFE53935);
      case CityEventTemporalState.past:
        return Colors.grey.shade500;
      case CityEventTemporalState.upcoming:
        return baseColor;
    }
  }

  String _badgeLabelForState(CityEventTemporalState state, EventModel event) {
    if (state == CityEventTemporalState.now) {
      return 'AGORA';
    }
    final start = event.dateTimeStart.value;
    if (start == null) {
      return '--:--';
    }

    final hours = start.hour.toString().padLeft(2, '0');
    final minutes = start.minute.toString().padLeft(2, '0');
    return '$hours:$minutes';
  }

}
