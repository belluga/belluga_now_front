import 'package:belluga_now/domain/schedule/event_model.dart';
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
    final baseColor = widget.event.type.color.value ?? const Color(0xFF4FA0E3);
    final start = widget.event.dateTimeStart.value;
    final end = widget.event.dateTimeEnd?.value;
    final now = DateTime.now();
    final state = _resolveTemporalState(start, end, now);

    final scale = widget.isSelected ? 1.12 : 1.0;
    final badgeColor = _badgeColorForState(state, baseColor);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final progress = _controller.value;
        final isLive = state == _EventTemporalState.live;
        final containerSize = 56.0;

        return SizedBox(
          width: containerSize * (isLive ? 1.8 : 1.2),
          height: containerSize * (isLive ? 1.8 : 1.2),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              if (isLive) ...[
                _PulseCircle(
                  progress: progress,
                  color: baseColor,
                  maxSize: containerSize * 1.9,
                ),
                _PulseCircle(
                  progress: (progress + 0.45) % 1.0,
                  color: baseColor,
                  maxSize: containerSize * 1.55,
                ),
              ],
              Transform.scale(
                scale: scale,
                child: _MarkerCore(
                  event: widget.event,
                  state: state,
                  activeColor: baseColor,
                ),
              ),
              Positioned(
                bottom: -10,
                child: _MarkerBadge(
                  color: badgeColor,
                  label: _badgeLabelForState(state, start),
                  state: state,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  _EventTemporalState _resolveTemporalState(
    DateTime? start,
    DateTime? end,
    DateTime now,
  ) {
    if (start == null) {
      return _EventTemporalState.upcoming;
    }

    if (end != null) {
      if (now.isBefore(start)) {
        return _EventTemporalState.upcoming;
      }
      if (now.isAfter(end)) {
        return _EventTemporalState.past;
      }
      return _EventTemporalState.live;
    }

    final diffMinutes = now.difference(start).inMinutes;
    if (diffMinutes >= 0 && diffMinutes <= 120) {
      return _EventTemporalState.live;
    }
    if (diffMinutes > 120) {
      return _EventTemporalState.past;
    }

    return _EventTemporalState.upcoming;
  }

  Color _badgeColorForState(_EventTemporalState state, Color baseColor) {
    switch (state) {
      case _EventTemporalState.live:
        return Colors.redAccent;
      case _EventTemporalState.past:
        return Colors.grey.shade600;
      case _EventTemporalState.upcoming:
      default:
        return baseColor;
    }
  }

  String _badgeLabelForState(_EventTemporalState state, DateTime? start) {
    if (state == _EventTemporalState.live) {
      return 'AO VIVO';
    }
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
  });

  final EventModel event;
  final _EventTemporalState state;
  final Color activeColor;

  @override
  Widget build(BuildContext context) {
    final primaryArtist = event.artists.isNotEmpty ? event.artists.first : null;
    final avatarUri = primaryArtist?.avatarUrl.value?.toString();
    final fallbackUri = event.thumb?.thumbUri.value?.toString();
    final imageUrl = avatarUri?.isNotEmpty == true
        ? avatarUri
        : (fallbackUri?.isNotEmpty == true ? fallbackUri : null);

    final decoration = BoxDecoration(
      shape: BoxShape.circle,
      border: Border.all(
        color: state == _EventTemporalState.past
            ? Colors.grey.shade500
            : activeColor,
        width: 3,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.18),
          blurRadius: 6,
          offset: const Offset(0, 3),
        ),
      ],
    );

    final core = Container(
      width: 56,
      height: 56,
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

    if (state == _EventTemporalState.past) {
      return ColorFiltered(
        colorFilter: const ColorFilter.matrix(<double>[
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0, 0, 0, 1, 0,
        ]),
        child: Opacity(
          opacity: 0.35,
          child: core,
        ),
      );
    }

    return core;
  }
}

class _MarkerBadge extends StatelessWidget {
  const _MarkerBadge({
    required this.color,
    required this.label,
    required this.state,
  });

  final Color color;
  final String label;
  final _EventTemporalState state;

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: Colors.white,
        );
    final scheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: state == _EventTemporalState.past
            ? color.withOpacity(0.85)
            : color,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: scheme.surface, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text(label, style: textStyle),
      ),
    );
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

enum _EventTemporalState { upcoming, live, past }
