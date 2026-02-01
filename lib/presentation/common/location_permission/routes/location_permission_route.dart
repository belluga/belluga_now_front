import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/guards/location_permission_state.dart';
import 'package:belluga_now/presentation/common/location_permission/controllers/location_permission_controller.dart';
import 'package:belluga_now/presentation/common/location_permission/screens/location_permission_screen/location_permission_screen.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

@RoutePage(name: 'LocationPermissionRoute')
class LocationPermissionRoutePage extends StatelessWidget {
  const LocationPermissionRoutePage({
    super.key,
    required this.initialState,
  });

  final LocationPermissionState initialState;

  @override
  Widget build(BuildContext context) {
    return LocationPermissionScreen(
      initialState: initialState,
      controller: GetIt.I.get<LocationPermissionController>(),
    );
  }
}
