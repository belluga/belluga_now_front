import 'package:flutter/material.dart';

class FloatingActionButtonCustom extends StatelessWidget {
  const FloatingActionButtonCustom({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.large(
      onPressed: () {},
      backgroundColor: Theme.of(context).colorScheme.secondary,
      child: Icon(Icons.location_pin, color: Theme.of(context).colorScheme.onSecondary),
    );
  }
}
