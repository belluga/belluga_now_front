import 'package:belluga_now/domain/map/value_objects/city_coordinate.dart';
import 'package:belluga_now/presentation/tenant_public/map/screens/map_screen/map_surface/belluga_map_surface_contract.dart';
import 'package:flutter/material.dart';

class BellugaMapSurface extends StatelessWidget {
  const BellugaMapSurface({
    super.key,
    required this.handle,
    required this.initialCenter,
    required this.initialZoom,
    required this.minZoom,
    required this.maxZoom,
    required this.annotations,
    this.onEmptyTap,
  });

  final BellugaMapHandleContract handle;
  final CityCoordinate initialCenter;
  final double initialZoom;
  final double minZoom;
  final double maxZoom;
  final List<BellugaMapAnnotation> annotations;
  final VoidCallback? onEmptyTap;

  @override
  Widget build(BuildContext context) {
    handle.markReady();
    return ColoredBox(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Center(
        child: Text(
          'Mapa indisponível nesta plataforma.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
  }
}
