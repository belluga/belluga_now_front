import 'package:belluga_now/application/router/support/back_surface_kind.dart';

abstract interface class RouteBackPolicy {
  BackSurfaceKind get surfaceKind;

  void handleBack();
}
