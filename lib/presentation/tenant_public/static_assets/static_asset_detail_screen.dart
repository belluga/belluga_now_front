import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/sharing/static_asset_public_share_payload.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/application/router/support/route_back_reentrancy_key.dart';
import 'package:belluga_now/application/router/support/tenant_public_safe_back.dart';
import 'package:belluga_now/domain/static_assets/public_static_asset_model.dart';
import 'package:belluga_now/presentation/shared/widgets/belluga_network_image.dart';
import 'package:belluga_now/presentation/shared/widgets/directions_app_chooser/directions_app_chooser.dart';
import 'package:belluga_now/presentation/shared/widgets/directions_app_chooser/directions_app_chooser_contract.dart';
import 'package:belluga_now/presentation/shared/widgets/directions_app_chooser/directions_launch_target.dart';
import 'package:belluga_now/presentation/shared/widgets/immersive_detail_screen/immersive_detail_screen.dart';
import 'package:belluga_now/presentation/shared/widgets/immersive_detail_screen/models/immersive_tab_item.dart';
import 'package:belluga_now/presentation/tenant_public/static_assets/controllers/static_asset_detail_controller.dart';
import 'package:belluga_now/application/icons/boora_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart' hide Marker;
import 'package:flutter_map/flutter_map.dart';
import 'package:get_it/get_it.dart';
import 'package:latlong2/latlong.dart';
import 'package:share_plus/share_plus.dart';

class StaticAssetDetailScreen extends StatefulWidget {
  const StaticAssetDetailScreen({
    super.key,
    required this.asset,
    this.controller,
    this.directionsAppChooser,
  });

  final PublicStaticAssetModel asset;
  final StaticAssetDetailController? controller;
  final DirectionsAppChooserContract? directionsAppChooser;

  @override
  State<StaticAssetDetailScreen> createState() =>
      _StaticAssetDetailScreenState();
}

class _StaticAssetDetailScreenState extends State<StaticAssetDetailScreen> {
  late final StaticAssetDetailController _controller =
      widget.controller ?? GetIt.I.get<StaticAssetDetailController>();
  late final DirectionsAppChooserContract _directionsAppChooser =
      widget.directionsAppChooser ?? DirectionsAppChooser();

  @override
  Widget build(BuildContext context) {
    final tabs = _buildTabs();
    return Scaffold(
      body: ImmersiveDetailScreen(
        heroContent: _buildHero(),
        title: widget.asset.displayName,
        collapsedToolbarHeight: 72,
        centerCollapsedTitle: false,
        backPolicy: buildTenantPublicSafeBackPolicy(
          context.router,
          fallbackRoute: const DiscoveryRoute(),
          reentrancyKey: resolveRouteBackReentrancyKey(
            context,
            fallbackRouteName: StaticAssetDetailRoute.name,
          ),
        ),
        onSharePressed: () => unawaited(_shareStaticAsset()),
        shareIcon: BooraIcons.share,
        tabs: tabs,
      ),
    );
  }

  List<ImmersiveTabItem> _buildTabs() {
    final tabs = <ImmersiveTabItem>[];
    final aboutContent = widget.asset.resolvedDescription;
    if (aboutContent != null && aboutContent.trim().isNotEmpty) {
      tabs.add(
        ImmersiveTabItem(
          title: 'Sobre',
          content: _aboutSection(aboutContent),
        ),
      );
    }
    if (widget.asset.hasLocation) {
      tabs.add(
        ImmersiveTabItem(
          title: 'Como Chegar',
          content: _locationSection(),
        ),
      );
    }
    if (tabs.isEmpty) {
      tabs.add(
        ImmersiveTabItem(
          title: 'Sobre',
          content: _fallbackAboutSection(),
        ),
      );
    }
    return tabs;
  }

  Widget _buildHero() {
    final colorScheme = Theme.of(context).colorScheme;
    final coverUrl = widget.asset.coverUrl?.trim();
    final fallback = DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primary,
            colorScheme.secondary,
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.place_outlined,
          size: 72,
          color: colorScheme.onPrimary,
        ),
      ),
    );
    return Stack(
      fit: StackFit.expand,
      children: [
        if (coverUrl != null && coverUrl.isNotEmpty)
          BellugaNetworkImage(
            coverUrl,
            fit: BoxFit.cover,
            errorWidget: fallback,
          )
        else
          fallback,
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[
                  Colors.transparent,
                  colorScheme.surface.withValues(alpha: 0.18),
                  colorScheme.surface.withValues(alpha: 0.94),
                ],
                stops: const <double>[0, 0.62, 1],
              ),
            ),
          ),
        ),
        Positioned(
          left: 16,
          right: 16,
          bottom: 24,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.asset.typeLabel.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    widget.asset.typeLabel,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
              const SizedBox(height: 12),
              Text(
                widget.asset.displayName,
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      height: 0.95,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _aboutSection(String description) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.asset.typeLabel.isNotEmpty) ...[
            Text(
              widget.asset.typeLabel,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
            const SizedBox(height: 12),
          ],
          Html(
            data: description,
            style: {
              'body': Style(
                margin: Margins.zero,
                padding: HtmlPaddings.zero,
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: FontSize(16),
                lineHeight: LineHeight.number(1.45),
              ),
              'p': Style(
                margin: Margins.only(bottom: 12),
              ),
            },
          ),
        ],
      ),
    );
  }

  Widget _fallbackAboutSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Text(
        widget.asset.typeLabel.isEmpty
            ? 'Detalhes deste lugar ainda não foram preenchidos.'
            : widget.asset.typeLabel,
        style: Theme.of(context).textTheme.bodyLarge,
      ),
    );
  }

  Widget _locationSection() {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Como Chegar',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _openAssetMap,
            child: Container(
              height: 260,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                color: colorScheme.surfaceContainerHighest,
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _buildLocationMapCanvas(),
                  Positioned(
                    left: 18,
                    right: 18,
                    bottom: 18,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colorScheme.surface.withValues(alpha: 0.95),
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: colorScheme.primaryContainer,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.near_me_outlined,
                              color: colorScheme.onPrimaryContainer,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Ver no mapa',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    color: colorScheme.onSurface,
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                          ),
                          Icon(
                            Icons.map_outlined,
                            color: colorScheme.onSurface,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _presentDirectionsChooser,
            icon: const Icon(Icons.navigation),
            label: const Text('Traçar rota'),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationMapCanvas() {
    final lat = widget.asset.locationLat;
    final lng = widget.asset.locationLng;
    if (lat == null || lng == null) {
      return _buildMapFallback();
    }

    final point = LatLng(lat, lng);
    final colorScheme = Theme.of(context).colorScheme;
    return IgnorePointer(
      child: FlutterMap(
        options: MapOptions(
          initialCenter: point,
          initialZoom: 15,
          minZoom: 15,
          maxZoom: 15,
          interactionOptions: InteractionOptions(
            flags: InteractiveFlag.none,
            rotationWinGestures: MultiFingerGesture.none,
            cursorKeyboardRotationOptions:
                CursorKeyboardRotationOptions.disabled(),
          ),
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.belluganow.app',
          ),
          MarkerLayer(
            markers: [
              Marker(
                point: point,
                width: 64,
                height: 64,
                child: Center(
                  child: Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: colorScheme.onPrimary,
                        width: 3,
                      ),
                    ),
                    child: Icon(
                      Icons.place_outlined,
                      color: colorScheme.onPrimary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMapFallback() {
    final colorScheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.surfaceContainerHighest,
            colorScheme.secondaryContainer,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: colorScheme.primary,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.place_outlined,
            color: colorScheme.onPrimary,
          ),
        ),
      ),
    );
  }

  Future<void> _shareStaticAsset() async {
    final publicUri = _controller.buildTenantPublicUriForAsset(widget.asset);
    final payload = StaticAssetPublicSharePayloadBuilder.build(
      publicUri: publicUri,
      fallbackName: widget.asset.displayName,
      asset: widget.asset,
      actorDisplayName: _controller.authenticatedUserDisplayName,
    );
    try {
      await SharePlus.instance.share(
        ShareParams(
          text: payload.message,
          subject: payload.subject,
        ),
      );
    } catch (_) {
      _showStatusMessage(
          'Não foi possível compartilhar ${widget.asset.displayName}.');
    }
  }

  void _openAssetMap() {
    final path = Uri(
      path: '/mapa',
      queryParameters: {
        'poi': 'static:${widget.asset.id}',
      },
    ).toString();
    _safeRouterPushPath(path);
  }

  void _presentDirectionsChooser() {
    final target = _directionsTarget();
    if (target == null) {
      return;
    }
    _directionsAppChooser.present(
      context,
      target: target,
      onStatusMessage: _showStatusMessage,
    );
  }

  DirectionsLaunchTarget? _directionsTarget() {
    final latitude = widget.asset.locationLat;
    final longitude = widget.asset.locationLng;
    if (latitude == null || longitude == null) {
      return null;
    }
    return DirectionsLaunchTarget(
      destinationName: widget.asset.displayName,
      latitude: latitude,
      longitude: longitude,
    );
  }

  void _safeRouterPushPath(String path) {
    try {
      context.router.pushPath(path);
    } catch (_) {
      // Tests and non-router surfaces can ignore this safely.
    }
  }

  void _showStatusMessage(String message) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) {
      return;
    }
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}
