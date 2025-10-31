import 'package:belluga_now/application/configurations/belluga_constants.dart';
import 'package:flutter/material.dart';

class LandlordHomeScreen extends StatelessWidget {
  const LandlordHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('This is Landlord HOME (Belluga NOW)'),
            Text(BellugaConstants.settings.platform),
          ],
        ),
      ),
    );
  }
}
