import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/guards/location_permission_gate_result.dart';
import 'package:belluga_now/application/router/guards/location_permission_state.dart';
import 'package:belluga_now/application/router/modular_app/modules/initialization_module.dart';
import 'package:belluga_now/presentation/shared/location_permission/screens/location_permission_screen/location_permission_screen.dart';
import 'package:flutter/material.dart';
import 'package:get_it_modular_with_auto_route/get_it_modular_with_auto_route.dart';

@RoutePage(name: 'LocationPermissionRoute')
class LocationPermissionRoutePage extends StatelessWidget {
  const LocationPermissionRoutePage({
    super.key,
    this.initialState,
    this.allowContinueWithoutLocation = true,
    this.onResult,
    this.popRouteAfterResult = false,
  });

  final LocationPermissionState? initialState;
  final bool allowContinueWithoutLocation;
  final ValueChanged<LocationPermissionGateResult>? onResult;
  final bool popRouteAfterResult;

  @override
  Widget build(BuildContext context) {
    return ModuleScope<InitializationModule>(
      child: LocationPermissionScreen(
        initialState: initialState,
        allowContinueWithoutLocation: allowContinueWithoutLocation,
        onResult: onResult,
        popRouteAfterResult: popRouteAfterResult,
      ),
    );
  }
}
