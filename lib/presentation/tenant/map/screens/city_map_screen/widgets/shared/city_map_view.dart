import 'dart:async';

import 'package:belluga_now/domain/map/city_poi_model.dart';
import 'package:belluga_now/domain/schedule/event_model.dart';
import 'package:belluga_now/presentation/tenant/map/screens/city_map_screen/controllers/city_map_controller.dart';
import 'package:belluga_now/presentation/tenant/map/screens/city_map_screen/widgets/shared/event_marker.dart';
import 'package:belluga_now/presentation/tenant/map/screens/city_map_screen/widgets/shared/event_temporal_state.dart';
import 'package:belluga_now/presentation/tenant/map/screens/city_map_screen/widgets/shared/poi_marker.dart';
import 'package:belluga_now/presentation/tenant/map/screens/city_map_screen/widgets/shared/user_location_marker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter/scheduler.dart';
import 'package:get_it/get_it.dart';
import 'package:latlong2/latlong.dart';
import 'package:package_info_plus/package_info_plus.dart';

class CityMapView extends StatefulWidget {
  const CityMapView({
    super.key,
    required this.pois,
    required this.selectedPoi,
    required this.onSelectPoi,
    required this.hoveredPoiId,
    required this.onHoverChange,
    required this.events,
    required this.selectedEvent,
    required this.onSelectEvent,
    required this.userPosition,
    required this.defaultCenter,
    required this.onMapInteraction,
  }) : controller = null;

  @visibleForTesting
  const CityMapView.withController(
    this.controller, {
    super.key,
    required this.pois,
    required this.selectedPoi,
    required this.onSelectPoi,
    required this.hoveredPoiId,
    required this.onHoverChange,
    required this.events,
    required this.selectedEvent,
    required this.onSelectEvent,
    required this.userPosition,
    required this.defaultCenter,
    required this.onMapInteraction,
  });

  final List<CityPoiModel> pois;
  final CityPoiModel? selectedPoi;
  final ValueChanged<CityPoiModel?> onSelectPoi;
  final String? hoveredPoiId;
  final ValueChanged<String?> onHoverChange;
  final List<EventModel> events;
  final EventModel? selectedEvent;
  final ValueChanged<EventModel?> onSelectEvent;
  final LatLng? userPosition;
  final LatLng defaultCenter;
  final VoidCallback onMapInteraction;
  final CityMapController? controller;

  @override
  State<CityMapView> createState() => _CityMapViewState();
}

class _CityMapViewState extends State<CityMapView> {
  static const _fallbackPackageName = 'com.belluganow.app';
  static const double _minZoom = 14.5;
  static const double _maxZoom = 17.0;

  late final CityMapController _controller =
      widget.controller ?? GetIt.I.get<CityMapController>();
  String? _packageName;
  late double _currentZoom;
  StreamSubscription<MapEvent>? _mapEventSubscription;
  Timer? _zoomThrottle;
  double? _pendingZoom;

  @override
  void initState() {
    super.initState();
    _resolvePackageName();
    _currentZoom = 16;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _attachZoomListener();
    });
  }

  Future<void> _resolvePackageName() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (!mounted) {
        return;
      }
      final resolved =
          info.packageName.isNotEmpty ? info.packageName : _fallbackPackageName;
      setState(() {
        _packageName = resolved;
      });
    } catch (error, stackTrace) {
      debugPrint('CityMapView -> failed to resolve package name: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) {
        return;
      }
      setState(() {
        _packageName = _fallbackPackageName;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedEventId = widget.selectedEvent?.id.value;
    final now = DateTime.now();
    final markerEntries = <_MarkerEntry>[];

    if (widget.userPosition != null) {
      markerEntries.add(
        _MarkerEntry(
          priority: 110,
          marker: Marker(
            point: widget.userPosition!,
            width: _scaledSize(_currentZoom, minSize: 36, maxSize: 52),
            height: _scaledSize(_currentZoom, minSize: 36, maxSize: 52),
            child: const UserLocationMarker(),
          ),
        ),
      );
    }

    final sortedPois = List<CityPoiModel>.from(widget.pois)
      ..sort((a, b) => a.priority.compareTo(b.priority));
    debugPrint('CityMapView -> rendering ${sortedPois.length} POIs, '
        '${widget.events.length} events, '
        'userPosition=${widget.userPosition}, defaultCenter=${widget.defaultCenter}');
    for (final poi in sortedPois) {
      final isHovered = widget.hoveredPoiId == poi.id;
      markerEntries.add(
        _MarkerEntry(
          priority: isHovered ? poi.priority + 1000 : poi.priority,
          marker: Marker(
            point: LatLng(
              poi.coordinate.latitude,
              poi.coordinate.longitude,
            ),
            width: _scaledSize(_currentZoom, minSize: 26, maxSize: 65),
            height: _scaledSize(_currentZoom, minSize: 26, maxSize: 65),
            child: GestureDetector(
              onTap: () => widget.onSelectPoi(poi),
              child: MouseRegion(
                onEnter: (_) => widget.onHoverChange(poi.id),
                onExit: (_) => widget.onHoverChange(null),
                child: PoiMarker(
                  poi: poi,
                  isSelected: widget.selectedPoi?.id == poi.id,
                  isHovered: isHovered && kIsWeb,
                ),
              ),
            ),
          ),
        ),
      );
    }

    final eventCandidates = widget.events
        .where((event) => event.coordinate != null)
        .toList(growable: false)
      ..sort(
        (a, b) => _priorityForEvent(a, now).compareTo(
          _priorityForEvent(b, now),
        ),
      );

    for (final event in eventCandidates) {
      final eventPriority = _priorityForEvent(event, now);
      markerEntries.add(
        _MarkerEntry(
          priority: eventPriority,
          marker: Marker(
            point: LatLng(
              event.coordinate!.latitude,
              event.coordinate!.longitude,
            ),
            width: _scaledSize(_currentZoom, minSize: 70, maxSize: 100),
            height: _scaledSize(_currentZoom, minSize: 70, maxSize: 100),
            child: GestureDetector(
              onTap: () => widget.onSelectEvent(event),
              child: EventMarker(
                event: event,
                isSelected: selectedEventId == event.id.value,
              ),
            ),
          ),
        ),
      );
    }

    markerEntries.sort((a, b) => a.priority.compareTo(b.priority));
    final initialCenter = widget.userPosition ?? widget.defaultCenter;
    final markers = markerEntries.map((entry) => entry.marker).toList();
    final theme = Theme.of(context);
    final resolvedPackageName = _packageName ?? _fallbackPackageName;

    return Listener(
      behavior: HitTestBehavior.deferToChild,
      onPointerDown: (_) => widget.onMapInteraction(),
      child: Stack(
        children: [
          FlutterMap(
            mapController: _controller.mapController,
            options: MapOptions(
              initialCenter: initialCenter,
              initialZoom: 16,
              minZoom: _minZoom,
              maxZoom: _maxZoom,
              onMapEvent: (event) {
                _handleZoomEvent(event.camera.zoom);
              },
              interactionOptions: InteractionOptions(
                // Restrict gestures to avoid unintended rotation/spin.
                flags: InteractiveFlag.drag |
                    InteractiveFlag.pinchZoom |
                    InteractiveFlag.doubleTapZoom |
                    InteractiveFlag.scrollWheelZoom,
                rotationWinGestures: MultiFingerGesture.none,
                enableMultiFingerGestureRace: false,
                cursorKeyboardRotationOptions:
                    CursorKeyboardRotationOptions.disabled(),
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: resolvedPackageName,
              ),
              MarkerLayer(markers: markers),
            ],
          ),
          Positioned(
            right: 12,
            bottom: 12,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Text(
                  '© OpenStreetMap',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _mapEventSubscription?.cancel();
    super.dispose();
  }

  void _attachZoomListener() {
    // MapController camera is only valid after the first frame.
    final initialZoom = _controller.mapController.camera.zoom;
    setState(() {
      _currentZoom = initialZoom.clamp(_minZoom, _maxZoom);
    });
    _mapEventSubscription =
        _controller.mapController.mapEventStream.listen((event) {
      _clampAndUpdateZoom(event.camera.zoom);
    });
  }

  void _clampAndUpdateZoom(double desiredZoom) {
    final clampedZoom = desiredZoom.clamp(_minZoom, _maxZoom);
    _handleZoomEvent(clampedZoom);
  }

  void _handleZoomEvent(double zoom) {
    final clamped = zoom.clamp(_minZoom, _maxZoom);
    if ((clamped - _currentZoom).abs() < 0.01) {
      return;
    }

    if (kIsWeb) {
      _pendingZoom = clamped;
      if (_zoomThrottle?.isActive ?? false) {
        return;
      }
      _zoomThrottle = Timer(const Duration(milliseconds: 50), () {
        final next = _pendingZoom;
        _pendingZoom = null;
        if (next != null && mounted) {
          setState(() => _currentZoom = next);
        }
      });
      return;
    }

    setState(() => _currentZoom = clamped);
  }
}

class _MarkerEntry {
  const _MarkerEntry({required this.priority, required this.marker});

  final int priority;
  final Marker marker;
}

double _scaledSize(
  double zoom, {
  required double minSize,
  required double maxSize,
  double minZoom = _CityMapViewState._minZoom,
  double maxZoom = _CityMapViewState._maxZoom,
}) {
  final t = ((zoom - minZoom) / (maxZoom - minZoom)).clamp(0, 1);
  return minSize + (maxSize - minSize) * t;
}

int _priorityForEvent(EventModel event, DateTime now) {
  final state = resolveEventTemporalState(event, reference: now);
  switch (state) {
    case CityEventTemporalState.now:
      return 90;
    case CityEventTemporalState.upcoming:
      return 80;
    case CityEventTemporalState.past:
      return 70;
  }
}
