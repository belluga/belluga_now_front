// ignore_for_file: prefer_const_constructors_in_immutables

import 'dart:async';

import 'package:belluga_now/domain/map/city_poi_model.dart';
import 'package:belluga_now/domain/schedule/event_model.dart';
import 'package:belluga_now/presentation/tenant/map/screens/city_map_screen/controllers/city_map_controller.dart';
import 'package:belluga_now/presentation/tenant/map/screens/city_map_screen/widgets/poi_info_card/poi_info_card.dart';
import 'package:belluga_now/presentation/tenant/map/screens/city_map_screen/widgets/shared/event_info_card.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value_builder.dart';

class CityMapSelectedCards extends StatelessWidget {
  CityMapSelectedCards({
    super.key,
    CityMapController? controller,
    required this.onOpenEventDetails,
    required this.onShareEvent,
    required this.onRouteToEvent,
    required this.onOpenPoiDetails,
    required this.onSharePoi,
    required this.onRouteToPoi,
  }) : _controller = controller ?? GetIt.I.get<CityMapController>();

  @visibleForTesting
  CityMapSelectedCards.withController(
    this._controller, {
    super.key,
    required this.onOpenEventDetails,
    required this.onShareEvent,
    required this.onRouteToEvent,
    required this.onOpenPoiDetails,
    required this.onSharePoi,
    required this.onRouteToPoi,
  });

  final CityMapController _controller;
  final FutureOr<void> Function(EventModel event) onOpenEventDetails;
  final FutureOr<void> Function(EventModel event) onShareEvent;
  final FutureOr<void> Function(EventModel event) onRouteToEvent;
  final FutureOr<void> Function(CityPoiModel poi) onOpenPoiDetails;
  final FutureOr<void> Function(CityPoiModel poi) onSharePoi;
  final FutureOr<void> Function(CityPoiModel poi) onRouteToPoi;

  @override
  Widget build(BuildContext context) {
    return StreamValueBuilder<EventModel?>(
      streamValue: _controller.selectedEventStreamValue,
      builder: (_, selectedEvent) {
        if (selectedEvent != null) {
          return _EventCard(
            event: selectedEvent,
            controller: _controller,
            onOpenDetails: () => onOpenEventDetails(selectedEvent),
            onShare: () => onShareEvent(selectedEvent),
            onRoute: selectedEvent.coordinate == null
                ? null
                : () => onRouteToEvent(selectedEvent),
          );
        }

        return StreamValueBuilder<CityPoiModel?>(
          streamValue: _controller.selectedPoiStreamValue,
          builder: (_, selectedPoi) {
            if (selectedPoi == null) {
              return const SizedBox.shrink();
            }
            return _PoiCard(
              poi: selectedPoi,
              controller: _controller,
              onOpenDetails: () => onOpenPoiDetails(selectedPoi),
              onShare: () => onSharePoi(selectedPoi),
              onRoute: () => onRouteToPoi(selectedPoi),
            );
          },
        );
      },
    );
  }
}

class _EventCard extends StatelessWidget {
  const _EventCard({
    required this.event,
    required this.controller,
    required this.onOpenDetails,
    required this.onShare,
    required this.onRoute,
  });

  final EventModel event;
  final CityMapController controller;
  final FutureOr<void> Function() onOpenDetails;
  final FutureOr<void> Function() onShare;
  final FutureOr<void> Function()? onRoute;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
        child: SafeArea(
          child: EventInfoCard(
            event: event,
            onDismiss: () => controller.selectEvent(null),
            onDetails: onOpenDetails,
            onShare: onShare,
            onRoute: onRoute,
          ),
        ),
      ),
    );
  }
}

class _PoiCard extends StatelessWidget {
  const _PoiCard({
    required this.poi,
    required this.controller,
    required this.onOpenDetails,
    required this.onShare,
    required this.onRoute,
  });

  final CityPoiModel poi;
  final CityMapController controller;
  final FutureOr<void> Function() onOpenDetails;
  final FutureOr<void> Function() onShare;
  final FutureOr<void> Function() onRoute;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
        child: SafeArea(
          child: PoiInfoCard(
            poi: poi,
            onDismiss: () => controller.selectPoi(null),
            onDetails: onOpenDetails,
            onShare: onShare,
            onRoute: onRoute,
          ),
        ),
      ),
    );
  }
}
