import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/application/router/support/route_back_reentrancy_key.dart';
import 'package:belluga_now/application/router/support/tenant_public_safe_back.dart';
import 'package:belluga_now/domain/map/city_poi_model.dart';
import 'package:belluga_now/presentation/tenant_public/map/screens/map_screen/controllers/map_screen_controller.dart';
import 'package:belluga_now/presentation/tenant_public/map/screens/map_screen/widgets/map_adaptive_tray.dart';
import 'package:belluga_now/presentation/tenant_public/map/screens/map_screen/widgets/map_layers.dart';
import 'package:belluga_now/presentation/tenant_public/map/screens/map_screen/widgets/map_location_utility_button.dart';
import 'package:belluga_now/presentation/tenant_public/map/screens/map_screen/widgets/map_soft_location_notice_banner.dart';
import 'package:belluga_now/presentation/tenant_public/map/screens/map_screen/widgets/poi_cluster_picker_dock.dart';
import 'package:belluga_now/presentation/tenant_public/map/screens/map_screen/widgets/poi_details_deck.dart';
import 'package:belluga_now/presentation/tenant_public/map/screens/map_screen/widgets/status_banner.dart';
import 'package:belluga_now/presentation/tenant_public/widgets/belluga_bottom_navigation_bar.dart';
import 'package:belluga_now/presentation/shared/widgets/route_back_scope.dart';
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

    return Theme(
      data: theme,
      child: _buildScaffold(),
    );
  }

  Widget _buildScaffold() {
    final backPolicy = buildTenantPublicSafeBackPolicy(
      context.router,
      fallbackRoute: widget.backFallbackRoute,
      reentrancyKey: resolveRouteBackReentrancyKey(
        context,
        fallbackRouteName: widget.initialPoiQuery?.trim().isNotEmpty ?? false
            ? PoiDetailsRoute.name
            : CityMapRoute.name,
      ),
    );
    return RouteBackScope(
      backPolicy: backPolicy,
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
                    Row(
                      children: [
                        IconButton.filled(
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.black54,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: backPolicy.handleBack,
                          icon: const Icon(Icons.arrow_back),
                        ),
                        const Spacer(),
                        MapLocationUtilityButton(controller: _controller),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            _buildFeedbackOverlay(),
            _buildClusterPickerOverlay(),
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
        return StreamValueBuilder<bool>(
          streamValue: _controller.hasSelectedPoiLoadingStreamValue,
          builder: (_, hasSelectedPoiLoading) {
            if (hasSelectedPoi || hasSelectedPoiLoading) {
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
                    key: const ValueKey<String>(
                      'map-bottom-controls-opacity',
                    ),
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOutCubic,
                    opacity: 1,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        MapAdaptiveTray(controller: _controller),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFeedbackOverlay() {
    return StreamValueBuilder<bool>(
      streamValue: _controller.hasSelectedPoiStreamValue,
      builder: (_, hasSelectedPoi) {
        return StreamValueBuilder<int>(
          streamValue: _controller.poiDeckHeightRevisionStreamValue,
          builder: (_, __) {
            final selectedPoi = _controller.selectedPoiStreamValue.value;
            final selectedDeckHeight = selectedPoi == null
                ? 0.0
                : _selectedDeckHeight(context, selectedPoi);
            final double bottomOffset = !hasSelectedPoi
                ? 16.0 + 88.0
                : 24.0 + selectedDeckHeight + 20.0;
            return Positioned(
              key: const ValueKey<String>('map-feedback-overlay'),
              left: 16,
              right: 16,
              bottom: bottomOffset,
              child: SafeArea(
                top: false,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        MapSoftLocationNoticeBanner(controller: _controller),
                        StreamValueBuilder<String>(
                          streamValue:
                              _controller.softLocationNoticeStreamValue,
                          builder: (_, message) => message.trim().isEmpty
                              ? const SizedBox.shrink()
                              : const SizedBox(height: 8),
                        ),
                        StatusBanner(controller: _controller),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  double _selectedDeckHeight(BuildContext context, CityPoiModel selectedPoi) {
    final deckPois = _controller.deckPoisForSelectedPoi(selectedPoi);
    if (deckPois.length <= 1) {
      return _clampPoiDeckHeight(
        context,
        _controller.getPoiDeckHeight(selectedPoi.id) ?? 356,
      );
    }

    final deckIndex =
        _controller.deckIndexForSelectedPoi(selectedPoi, deckPois);
    final safeFallbackHeight = _safePoiDeckHeight(context);
    return _clampPoiDeckHeight(
      context,
      _controller.resolvePoiDeckHeightForDeck(
        deckPois,
        currentIndex: deckIndex,
        defaultHeight: 356,
        safeFallbackHeight: safeFallbackHeight,
      ),
    );
  }

  double _safePoiDeckHeight(BuildContext context) {
    final viewportHeight = MediaQuery.of(context).size.height;
    return (viewportHeight * 0.68).clamp(380.0, 520.0).toDouble();
  }

  double _clampPoiDeckHeight(BuildContext context, double raw) {
    return raw.clamp(280.0, _safePoiDeckHeight(context)).toDouble();
  }

  Widget _buildClusterPickerOverlay() {
    return StreamValueBuilder<bool>(
      streamValue: _controller.hasSelectedPoiStreamValue,
      builder: (_, hasSelectedPoi) {
        return StreamValueBuilder<bool>(
          streamValue: _controller.hasSelectedPoiLoadingStreamValue,
          builder: (_, hasSelectedPoiLoading) {
            if (hasSelectedPoi || hasSelectedPoiLoading) {
              return const SizedBox.shrink();
            }
            return StreamValueBuilder<bool>(
              streamValue: _controller.hasClusterPickerStreamValue,
              builder: (_, hasClusterPicker) {
                if (!hasClusterPicker) {
                  return const SizedBox.shrink();
                }
                return _buildAnchoredClusterPicker();
              },
            );
          },
        );
      },
    );
  }

  Widget _buildAnchoredClusterPicker() {
    final pois = _controller.clusterPickerPoisStreamValue.value ??
        const <CityPoiModel>[];
    if (pois.isEmpty) {
      return const SizedBox.shrink();
    }
    final anchorCoordinate =
        _controller.clusterPickerAnchorCoordinateStreamValue.value;
    if (anchorCoordinate == null) {
      return const SizedBox.shrink();
    }
    final anchorOffset = _controller.mapHandle.projectToViewport(
      anchorCoordinate,
    );
    if (anchorOffset == null) {
      return const SizedBox.shrink();
    }
    return Positioned.fill(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return CustomSingleChildLayout(
            delegate: _ClusterPickerPopoverLayoutDelegate(
              anchorOffset: anchorOffset,
              screenSize: Size(
                constraints.maxWidth,
                constraints.maxHeight,
              ),
            ),
            child: PoiClusterPickerPopover(
              controller: _controller,
              pois: pois,
            ),
          );
        },
      ),
    );
  }

  Widget _buildSelectedCardOverlay() {
    return StreamValueBuilder<bool>(
      streamValue: _controller.hasSelectedPoiStreamValue,
      builder: (_, hasSelectedPoi) {
        return StreamValueBuilder<bool>(
          streamValue: _controller.hasSelectedPoiLoadingStreamValue,
          builder: (_, hasSelectedPoiLoading) {
            if (!hasSelectedPoi || hasSelectedPoiLoading) {
              return const SizedBox.shrink();
            }
            return Positioned(
              left: 0,
              right: 0,
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
      },
    );
  }

  Future<void> _initializeController() async {
    await _controller.init(
      initialPoiQuery: widget.initialPoiQuery,
      initialPoiStackQuery: widget.initialPoiStackQuery,
    );
  }
}

class _ClusterPickerPopoverLayoutDelegate extends SingleChildLayoutDelegate {
  const _ClusterPickerPopoverLayoutDelegate({
    required this.anchorOffset,
    required this.screenSize,
  });

  static const double _sidePadding = 16;
  static const double _topPadding = 88;
  static const double _bottomPadding = 128;
  static const double _anchorGap = 18;

  final Offset anchorOffset;
  final Size screenSize;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    final maxWidth =
        (screenSize.width - (_sidePadding * 2)).clamp(220.0, 320.0).toDouble();
    final maxHeight = (screenSize.height - _topPadding - _bottomPadding)
        .clamp(120.0, 320.0)
        .toDouble();
    return BoxConstraints(
      minWidth: 220,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
    );
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final maxLeft = size.width - childSize.width - _sidePadding;
    final maxTop = size.height - childSize.height - _bottomPadding;

    final centeredLeft = anchorOffset.dx - (childSize.width / 2);
    final clampedLeft = centeredLeft.clamp(_sidePadding, maxLeft);

    final preferredTop = anchorOffset.dy - childSize.height - _anchorGap;
    double resolvedTop = preferredTop;
    if (resolvedTop < _topPadding) {
      resolvedTop = anchorOffset.dy + _anchorGap;
    }
    resolvedTop = resolvedTop.clamp(_topPadding, maxTop);

    return Offset(clampedLeft.toDouble(), resolvedTop.toDouble());
  }

  @override
  bool shouldRelayout(
      covariant _ClusterPickerPopoverLayoutDelegate oldDelegate) {
    return oldDelegate.anchorOffset != anchorOffset ||
        oldDelegate.screenSize != screenSize;
  }
}
