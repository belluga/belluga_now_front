import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/presentation/tenant/map/screens/map_screen/controllers/map_screen_controller.dart';
import 'package:belluga_now/presentation/tenant/map/screens/map_screen/widgets/fab_menu.dart';
import 'package:belluga_now/presentation/tenant/map/screens/map_screen/widgets/map_layers.dart';
import 'package:belluga_now/presentation/tenant/map/screens/map_screen/widgets/map_status_message_listener.dart';
import 'package:belluga_now/presentation/tenant/map/screens/map_screen/widgets/poi_details_deck.dart';
import 'package:belluga_now/presentation/tenant/widgets/belluga_bottom_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value_builder.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapScreenController _controller = GetIt.I.get<MapScreenController>();

  @override
  void initState() {
    super.initState();
    unawaited(_controller.startTracking());
    _initializeController();
  }

  @override
  void dispose() {
    unawaited(_controller.stopTracking());
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

    return MapStatusMessageListener(
      child: Theme(
        data: theme,
        child: PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) {
              return;
            }
            context.router.replaceAll([const TenantHomeRoute()]);
          },
          child: Scaffold(
            body: Stack(
              children: [
                Column(
                  children: [
                    Expanded(
                      child: MapLayers(controller: _controller),
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
                        onPressed: () {
                          context.router.replaceAll([const TenantHomeRoute()]);
                        },
                        icon: const Icon(Icons.arrow_back),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 16,
                  child: SafeArea(
                    child: PoiDetailDeck(controller: _controller),
                  ),
                ),
              ],
            ),
            floatingActionButtonLocation:
                FloatingActionButtonLocation.endFloat,
            floatingActionButton: FabMenu(
              onNavigateToUser: _centerOnUser,
            ),
            bottomNavigationBar:
                const BellugaBottomNavigationBar(currentIndex: 1),
          ),
        ),
      ),
    );
  }

  Future<void> _initializeController() async {
    await _controller.init();
  }

  void _centerOnUser() {
    _controller.centerOnUser();
  }

}
