import 'package:belluga_now/application/configurations/belluga_constants.dart';
import 'package:belluga_now/domain/repositories/admin_mode_repository_contract.dart';
import 'package:belluga_now/presentation/landlord/home/screens/landlord_home_screen/controllers/landlord_home_screen_controller.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

class LandlordHomeScreen extends StatefulWidget {
  const LandlordHomeScreen({super.key});

  @override
  State<LandlordHomeScreen> createState() => _LandlordHomeScreenState();
}

class _LandlordHomeScreenState extends State<LandlordHomeScreen> {
  late final LandlordHomeScreenController _controller =
      GetIt.I.get<LandlordHomeScreenController>();

  @override
  void initState() {
    super.initState();
    _controller.init();
  }

  @override
  Widget build(BuildContext context) {
    final adminMode = GetIt.I.get<AdminModeRepositoryContract>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin'),
        actions: const [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Chip(label: Text('Admin')),
          ),
        ],
      ),
      body: Column(
        children: [
          if (adminMode.isLandlordMode)
            MaterialBanner(
              content: const Text('Modo Admin ativo'),
              actions: [
                TextButton(
                  onPressed: () {},
                  child: const Text('Ok'),
                ),
              ],
            ),
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('This is Landlord HOME (Belluga NOW)'),
                  Text(BellugaConstants.settings.platform),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
