import 'dart:math' as math;

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
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(seconds: 2))
        ..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.event.type.color.value ?? const Color(0xFF4FA0E3);
    final baseSize = widget.isSelected ? 58.0 : 48.0;
    final avatarSize = widget.isSelected ? 40.0 : 34.0;

    return SizedBox(
      width: baseSize,
      height: baseSize,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final value = _controller.value;
          final secondValue = (value + 0.5) % 1.0;

          return Stack(
            alignment: Alignment.center,
            children: [
              _PulseCircle(
                progress: value,
                color: color,
                maxSize: baseSize * 1.8,
              ),
              _PulseCircle(
                progress: secondValue,
                color: color,
                maxSize: baseSize * 1.5,
              ),
              _AvatarCircle(
                event: widget.event,
                size: avatarSize,
                borderColor: color,
              ),
            ],
          );
        },
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
    final opacity = (1 - progress).clamp(0.0, 1.0);
    final size = (math.max(progress, 0.1)) * maxSize;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(0.12 * opacity),
      ),
    );
  }
}

class _AvatarCircle extends StatelessWidget {
  const _AvatarCircle({
    required this.event,
    required this.size,
    required this.borderColor,
  });

  final EventModel event;
  final double size;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    final primaryArtist =
        event.artists.isNotEmpty ? event.artists.first : null;
    final avatarUri = primaryArtist?.avatarUrl.value?.toString();
    final fallbackUri = event.thumb?.thumbUri.value?.toString();
    final imageUrl = avatarUri?.isNotEmpty == true
        ? avatarUri
        : (fallbackUri?.isNotEmpty == true ? fallbackUri : null);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: borderColor, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: imageUrl != null
          ? Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => _fallbackIcon(),
            )
          : _fallbackIcon(),
    );
  }

  Widget _fallbackIcon() => Container(
        color: borderColor.withOpacity(0.1),
        alignment: Alignment.center,
        child: Icon(
          Icons.event,
          color: borderColor,
        ),
      );
}
