import 'package:auto_route/auto_route.dart';
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
  });

  final LocationPermissionState? initialState;

  @override
  Widget build(BuildContext context) {
    final resolvedInitialState = initialState ?? LocationPermissionState.denied;
    return ModuleScope<InitializationModule>(
      child: LocationPermissionScreen(
        initialState: resolvedInitialState,
      ),
    );
  }
}
