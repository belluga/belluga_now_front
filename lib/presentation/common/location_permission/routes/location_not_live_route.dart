import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/guards/location_permission_state.dart';
import 'package:belluga_now/presentation/common/location_permission/screens/location_not_live_screen/location_not_live_screen.dart';
import 'package:flutter/material.dart';

@RoutePage(name: 'LocationNotLiveRoute')
class LocationNotLiveRoutePage extends StatelessWidget {
  const LocationNotLiveRoutePage({
    super.key,
    required this.blockerState,
    this.addressLabel,
    this.capturedAt,
  });

  final LocationPermissionState blockerState;
  final String? addressLabel;
  final DateTime? capturedAt;

  @override
  Widget build(BuildContext context) {
    return LocationNotLiveScreen(
      blockerState: blockerState,
      addressLabel: addressLabel,
      capturedAt: capturedAt,
    );
  }
}

