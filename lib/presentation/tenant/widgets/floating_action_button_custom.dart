import 'package:belluga_now/presentation/tenant/screens/map/city_map_screen.dart';
import 'package:flutter/material.dart';

class FloatingActionButtonCustom extends StatelessWidget {
  const FloatingActionButtonCustom({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FloatingActionButton.large(
      heroTag: 'Conheça Guarapari!',
      backgroundColor: theme.colorScheme.secondary,
      onPressed: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const CityMapScreen(),
          ),
        );
      },
      child: Icon(
        Icons.location_pin,
        color: theme.colorScheme.onSecondary,
      ),
    );
  }
}
