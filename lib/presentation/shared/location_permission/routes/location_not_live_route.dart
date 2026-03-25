import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/guards/location_permission_state.dart';
import 'package:belluga_now/application/router/modular_app/modules/initialization_module.dart';
import 'package:belluga_now/presentation/shared/location_permission/screens/location_not_live_screen/location_not_live_screen.dart';
import 'package:flutter/material.dart';
import 'package:get_it_modular_with_auto_route/get_it_modular_with_auto_route.dart';

@RoutePage(name: 'LocationNotLiveRoute')
class LocationNotLiveRoutePage extends StatelessWidget {
  const LocationNotLiveRoutePage({
    super.key,
    this.blockerState,
    this.addressLabel,
    this.capturedAt,
  });

  final LocationPermissionState? blockerState;
  final String? addressLabel;
  final DateTime? capturedAt;

  @override
  Widget build(BuildContext context) {
    final resolvedBlockerState = blockerState ?? LocationPermissionState.denied;
    return ModuleScope<InitializationModule>(
      child: LocationNotLiveScreen(
        blockerState: resolvedBlockerState,
        addressLabel: addressLabel,
        capturedAt: capturedAt,
      ),
    );
  }
}
