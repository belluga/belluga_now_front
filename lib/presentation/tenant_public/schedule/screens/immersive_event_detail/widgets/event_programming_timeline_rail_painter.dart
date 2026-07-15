import 'package:flutter/material.dart';

/// Paints one rail behind the list, bounded by the first and last marker.
class EventProgrammingTimelineRailPainter extends CustomPainter {
  EventProgrammingTimelineRailPainter({
    required this.timelineKey,
    required this.markerKeys,
    required this.color,
  });

  final GlobalKey timelineKey;
  final List<GlobalKey> markerKeys;
  final Color color;

  @visibleForTesting
  ({Offset start, Offset end})? debugEndpoints() => _endpoints();

  @override
  void paint(Canvas canvas, Size size) {
    final endpoints = _endpoints();
    if (endpoints == null || endpoints.start == endpoints.end) {
      return;
    }

    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(endpoints.start, endpoints.end, linePaint);
  }

  ({Offset start, Offset end})? _endpoints() {
    final timelineRenderObject = timelineKey.currentContext?.findRenderObject();
    if (timelineRenderObject is! RenderBox) {
      return null;
    }

    final markerCenters = <Offset>[];
    for (final markerKey in markerKeys) {
      final markerRenderObject = markerKey.currentContext?.findRenderObject();
      if (markerRenderObject is! RenderBox || !markerRenderObject.hasSize) {
        return null;
      }
      markerCenters.add(
        markerRenderObject.localToGlobal(
          markerRenderObject.size.center(Offset.zero),
          ancestor: timelineRenderObject,
        ),
      );
    }

    if (markerCenters.isEmpty) {
      return null;
    }

    return (start: markerCenters.first, end: markerCenters.last);
  }

  @override
  bool shouldRepaint(
    covariant EventProgrammingTimelineRailPainter oldDelegate,
  ) {
    return oldDelegate.color != color ||
        oldDelegate.timelineKey != timelineKey ||
        !identical(oldDelegate.markerKeys, markerKeys);
  }
}
