import 'package:belluga_now/domain/schedule/event_model.dart';
import 'package:belluga_now/presentation/tenant/map/screens/city_map_screen/widgets/shared/event_badge_chip.dart';
import 'package:belluga_now/presentation/tenant/map/screens/city_map_screen/widgets/shared/event_temporal_state.dart';
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
                _PulseCircle(
                  progress: progress,
                  color: baseColor,
                  maxSize: coreSize * 2.1,
                ),
                _PulseCircle(
                  progress: (progress + 0.45) % 1.0,
                  color: baseColor,
                  maxSize: coreSize * 1.75,
                ),
              ],
              Transform.scale(
                scale: scale,
                child: _MarkerCore(
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

class _MarkerCore extends StatelessWidget {
  const _MarkerCore({
    required this.event,
    required this.state,
    required this.activeColor,
    required this.size,
  });

  final EventModel event;
  final CityEventTemporalState state;
  final Color activeColor;
  final double size;

  @override
  Widget build(BuildContext context) {
    final primaryArtist = event.artists.isNotEmpty ? event.artists.first : null;
    final avatarUriValue = primaryArtist?.avatarUrl.value;
    final avatarUri = avatarUriValue == null ? null : avatarUriValue.toString();
    final fallbackUriValue = event.thumb?.thumbUri.value;
    final fallbackUri =
        fallbackUriValue == null ? null : fallbackUriValue.toString();
    final imageUrl = avatarUri?.isNotEmpty == true
        ? avatarUri
        : (fallbackUri?.isNotEmpty == true ? fallbackUri : null);

    final decoration = BoxDecoration(
      shape: BoxShape.circle,
      border: Border.all(
        color: state == CityEventTemporalState.past
            ? Colors.grey.shade500
            : activeColor,
        width: 2.8,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.16),
          blurRadius: 5,
          offset: const Offset(0, 3),
        ),
      ],
    );

    final core = Container(
      width: size,
      height: size,
      decoration: decoration,
      clipBehavior: Clip.antiAlias,
      child: imageUrl != null
          ? Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _FallbackIcon(color: activeColor),
            )
          : _FallbackIcon(color: activeColor),
    );

    return core;
  }
}

class _PulseCircle extends StatelessWidget {
  const _PulseCircle({
    required this.progress,
    required this.color,
    required this.maxSize,
  });

  final double progress;
  final Color color;
  final double maxSize;

  @override
  Widget build(BuildContext context) {
    final eased = Curves.easeOut.transform(progress);
    final size = (eased.clamp(0.1, 1.0)) * maxSize;
    final opacity = (1 - eased).clamp(0.0, 1.0);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(0.16 * opacity),
      ),
    );
  }
}

class _FallbackIcon extends StatelessWidget {
  const _FallbackIcon({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: color.withOpacity(0.1),
      alignment: Alignment.center,
      child: Icon(
        Icons.music_note,
        color: color,
        size: 28,
      ),
    );
  }
}
