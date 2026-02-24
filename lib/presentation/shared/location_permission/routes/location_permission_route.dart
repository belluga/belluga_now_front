import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/guards/location_permission_state.dart';
import 'package:belluga_now/presentation/shared/location_permission/screens/location_permission_screen/location_permission_screen.dart';
import 'package:flutter/material.dart';

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
    );
  }
}
