import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/domain/repositories/user_location_repository_contract.dart';
import 'package:belluga_now/presentation/prototypes/map_experience/controllers/map_screen_controller.dart';
import 'package:belluga_now/presentation/prototypes/map_experience/widgets/fab_menu.dart';
import 'package:belluga_now/presentation/prototypes/map_experience/widgets/poi_details_deck.dart';
import 'package:belluga_now/presentation/prototypes/map_experience/widgets/prototype_map_layers.dart';
import 'package:belluga_now/presentation/tenant/widgets/belluga_bottom_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

class MapExperiencePrototypeScreen extends StatefulWidget {
  const MapExperiencePrototypeScreen({super.key});

  @override
  State<MapExperiencePrototypeScreen> createState() =>
      _MapExperiencePrototypeScreenState();
}

class _MapExperiencePrototypeScreenState
    extends State<MapExperiencePrototypeScreen> {
  final _controller = GetIt.I.get<MapScreenController>();
  final _locationRepository = GetIt.I.get<UserLocationRepositoryContract>();

  @override
  void initState() {
    super.initState();
    unawaited(
      _locationRepository.startTracking(
        mode: LocationTrackingMode.mapForeground,
      ),
    );
    _initializeController();
  }

  @override
  void dispose() {
    unawaited(_locationRepository.stopTracking());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context);
    final scheme = ColorScheme.fromSeed(
      seedColor: base.colorScheme.primary,
      brightness: base.brightness,
    );
    final theme = ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      scaffoldBackgroundColor: Colors.black,
      textTheme: base.textTheme.apply(fontFamily: 'Roboto'),
    );

    return Theme(
      data: theme,
      child: Scaffold(
        body: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: PrototypeMapLayers(),
                ),
              ],
            ),
            // SafeArea(
            //   child: SizedBox(
            //     height: 120,
            //     child: Padding(
            //       padding: const EdgeInsets.symmetric(horizontal: 16),
            //       child: Column(
            //         crossAxisAlignment: CrossAxisAlignment.stretch,
            //         children: [
            //           MapHeader(onSearch: _openSearchDialog),
            //           const SizedBox(height: 8),
            //           StatusBanner(),
            //         ],
            //       ),
            //     ),
            //   ),
            // ),
            SafeArea(
              child: Align(
                alignment: Alignment.topLeft,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: IconButton.filled(
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black54,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () async {
                      final router = context.router;
                      if (router.canPop()) {
                        await router.maybePop();
                      }
                    },
                    icon: const Icon(Icons.arrow_back),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 16,
              right: 96,
              bottom: 16,
              child: SafeArea(
                child: PoiDetailDeck(),
              ),
            ),
          ],
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        floatingActionButton: FabMenu(
          onNavigateToUser: _centerOnUser,
        ),
        bottomNavigationBar:
            const BellugaBottomNavigationBar(currentIndex: 2),
      ),
    );
  }

  Future<void> _initializeController() async {
    await _controller.init();
  }

  Future<void> _centerOnUser() async {
    final message = await _controller.centerOnUser();
    if (!mounted || message == null) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
