import 'package:belluga_now/domain/app_data/location_origin_settings.dart';
import 'package:belluga_now/domain/map/value_objects/city_coordinate.dart';
import 'package:belluga_now/domain/repositories/location_resolution_phase.dart';

enum MapLocationFeedbackKind {
  loading,
  live,
  fixedManual,
  outsideRange,
  permissionDenied,
  unavailable,
}

class MapLocationFeedbackState {
  const MapLocationFeedbackState({
    required this.kind,
    required this.resolutionPhase,
    required this.settings,
    required this.targetCoordinate,
  });

  const MapLocationFeedbackState.loading({
    required LocationResolutionPhase resolutionPhase,
  }) : this(
          kind: MapLocationFeedbackKind.loading,
          resolutionPhase: resolutionPhase,
          settings: null,
          targetCoordinate: null,
        );

  final MapLocationFeedbackKind kind;
  final LocationResolutionPhase resolutionPhase;
  final LocationOriginSettings? settings;
  final CityCoordinate? targetCoordinate;

  bool get isActionEnabled => kind != MapLocationFeedbackKind.loading;
  bool get isErrorLike =>
      kind == MapLocationFeedbackKind.permissionDenied ||
      kind == MapLocationFeedbackKind.unavailable;
  bool get isAlertLike => kind == MapLocationFeedbackKind.outsideRange;
  bool get isTerminal => kind != MapLocationFeedbackKind.loading;
}
