import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/manual_route_stubs.dart';
import 'package:flutter/material.dart';

class FloatingActionButtonCustom extends StatelessWidget {
  const FloatingActionButtonCustom({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FloatingActionButton.large(
      heroTag: 'Conheça Guarapari!',
      backgroundColor: theme.colorScheme.secondary,
      onPressed: () => context.router.push(const CityMapRoute()),
      child: Icon(
        Icons.location_pin,
        color: theme.colorScheme.onSecondary,
      ),
    );
  }
}
