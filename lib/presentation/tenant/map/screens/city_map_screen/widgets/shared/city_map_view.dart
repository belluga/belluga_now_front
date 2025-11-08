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
import 'package:free_map/fm_map.dart';
import 'package:get_it/get_it.dart';
import 'package:latlong2/latlong.dart';

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
  late final CityMapController _controller =
      widget.controller ?? GetIt.I.get<CityMapController>();

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
            width: 48,
            height: 48,
            child: const UserLocationMarker(),
          ),
        ),
      );
    }

    final sortedPois = List<CityPoiModel>.from(widget.pois)
      ..sort((a, b) => a.priority.compareTo(b.priority));
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
            width: 52,
            height: 52,
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
            width: 96,
            height: 96,
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
    final markers = markerEntries.map((entry) => entry.marker).toList();
    final initialCenter = widget.userPosition ?? widget.defaultCenter;

    return Listener(
      behavior: HitTestBehavior.deferToChild,
      onPointerDown: (_) => widget.onMapInteraction(),
      child: FmMap(
        mapController: _controller.mapController,
        mapOptions: MapOptions(
          initialCenter: initialCenter,
          initialZoom: 16,
          minZoom: 14,
          maxZoom: 18,
          interactionOptions:
              const InteractionOptions(flags: InteractiveFlag.all),
        ),
        markers: markers,
        attributionAlignment: Alignment.bottomRight,
      ),
    );
  }
}

class _MarkerEntry {
  const _MarkerEntry({required this.priority, required this.marker});

  final int priority;
  final Marker marker;
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
