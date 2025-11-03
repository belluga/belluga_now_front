import 'package:belluga_now/domain/map/city_poi_model.dart';
import 'package:belluga_now/domain/schedule/event_model.dart';
import 'package:belluga_now/presentation/tenant/screens/map/widgets/event_marker.dart';
import 'package:belluga_now/presentation/tenant/screens/map/widgets/event_temporal_state.dart';
import 'package:belluga_now/presentation/tenant/screens/map/widgets/poi_marker.dart';
import 'package:belluga_now/presentation/tenant/screens/map/widgets/user_location_marker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:free_map/fm_map.dart';
import 'package:latlong2/latlong.dart';

class CityMapView extends StatelessWidget {
  const CityMapView({
    super.key,
    required this.mapController,
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

  final MapController mapController;
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

  @override
  Widget build(BuildContext context) {
    final selectedEventId = selectedEvent?.id.value;
    final now = DateTime.now();
    final markerEntries = <_MarkerEntry>[];

    if (userPosition != null) {
      markerEntries.add(
        _MarkerEntry(
          priority: 110,
          marker: Marker(
            point: userPosition!,
            width: 48,
            height: 48,
            child: const UserLocationMarker(),
          ),
        ),
      );
    }

    final sortedPois = List<CityPoiModel>.from(pois)
      ..sort((a, b) => a.priority.compareTo(b.priority));
    for (final poi in sortedPois) {
      final isHovered = hoveredPoiId == poi.id;
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
              onTap: () => onSelectPoi(poi),
              child: MouseRegion(
                onEnter: (_) => onHoverChange(poi.id),
                onExit: (_) => onHoverChange(null),
                child: PoiMarker(
                  poi: poi,
                  isSelected: selectedPoi?.id == poi.id,
                  isHovered: isHovered && kIsWeb,
                ),
              ),
            ),
          ),
        ),
      );
    }

    final eventCandidates = events
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
              onTap: () => onSelectEvent(event),
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

    final initialCenter = userPosition ?? defaultCenter;

    return Listener(
      behavior: HitTestBehavior.deferToChild,
      onPointerDown: (_) => onMapInteraction(),
      child: FmMap(
        mapController: mapController,
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
