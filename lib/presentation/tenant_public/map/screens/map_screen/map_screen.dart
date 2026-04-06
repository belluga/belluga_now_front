import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/support/tenant_public_safe_back.dart';
import 'package:belluga_now/presentation/tenant_public/map/screens/map_screen/controllers/map_screen_controller.dart';
import 'package:belluga_now/presentation/tenant_public/map/screens/map_screen/widgets/map_adaptive_tray.dart';
import 'package:belluga_now/presentation/tenant_public/map/screens/map_screen/widgets/map_layers.dart';
import 'package:belluga_now/presentation/tenant_public/map/screens/map_screen/widgets/map_local_action_row.dart';
import 'package:belluga_now/presentation/tenant_public/map/screens/map_screen/widgets/map_soft_location_notice_banner.dart';
import 'package:belluga_now/presentation/tenant_public/map/screens/map_screen/widgets/map_status_message_listener.dart';
import 'package:belluga_now/presentation/tenant_public/map/screens/map_screen/widgets/poi_details_deck.dart';
import 'package:belluga_now/presentation/tenant_public/widgets/belluga_bottom_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value_builder.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({
    super.key,
    required this.backFallbackRoute,
    this.initialPoiQuery,
    this.initialPoiStackQuery,
  });

  final PageRouteInfo<dynamic> backFallbackRoute;
  final String? initialPoiQuery;
  final String? initialPoiStackQuery;

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
        child: _buildScaffold(),
      ),
    );
  }

  Widget _buildScaffold() {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          return;
        }
        _handleBack();
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
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: Alignment.topLeft,
                      child: IconButton.filled(
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.black54,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: _handleBack,
                        icon: const Icon(Icons.arrow_back),
                      ),
                    ),
                    MapSoftLocationNoticeBanner(controller: _controller),
                  ],
                ),
              ),
            ),
            _buildBottomControlsOverlay(),
            _buildSelectedCardOverlay(),
          ],
        ),
        bottomNavigationBar: const BellugaBottomNavigationBar(currentIndex: 1),
      ),
    );
  }

  Widget _buildBottomControlsOverlay() {
    return StreamValueBuilder<bool>(
      streamValue: _controller.hasSelectedPoiStreamValue,
      builder: (_, hasSelectedPoi) {
        if (hasSelectedPoi) {
          return const SizedBox.shrink();
        }
        return Positioned(
          left: 16,
          right: 16,
          bottom: 16,
          child: SafeArea(
            top: false,
            child: AnimatedSlide(
              key: const ValueKey<String>('map-bottom-controls-slide'),
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              offset: Offset.zero,
              child: AnimatedOpacity(
                key: const ValueKey<String>('map-bottom-controls-opacity'),
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                opacity: 1,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    MapLocalActionRow(controller: _controller),
                    const SizedBox(height: 12),
                    MapAdaptiveTray(controller: _controller),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSelectedCardOverlay() {
    return StreamValueBuilder<bool>(
      streamValue: _controller.hasSelectedPoiStreamValue,
      builder: (_, hasSelectedPoi) {
        if (!hasSelectedPoi) {
          return const SizedBox.shrink();
        }
        return Positioned(
          left: 16,
          right: 16,
          bottom: 24,
          child: SafeArea(
            top: false,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: AnimatedSlide(
                key: const ValueKey<String>('map-selected-card-slide'),
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeOutCubic,
                offset: Offset.zero,
                child: AnimatedOpacity(
                  key: const ValueKey<String>('map-selected-card-opacity'),
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  opacity: 1,
                  child: PoiDetailDeck(controller: _controller),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _initializeController() async {
    await _controller.init(
      initialPoiQuery: widget.initialPoiQuery,
      initialPoiStackQuery: widget.initialPoiStackQuery,
    );
  }

  void _handleBack() {
    performTenantPublicSafeBack(
      context.router,
      fallbackRoute: widget.backFallbackRoute,
    );
  }
}
