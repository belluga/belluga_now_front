import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/sharing/static_asset_public_share_payload.dart';
import 'package:belluga_now/application/router/support/canonical_route_governance.dart';
import 'package:belluga_now/domain/static_assets/public_static_asset_model.dart';
import 'package:belluga_now/presentation/shared/sharing/public_share_launcher.dart';
import 'package:belluga_now/presentation/shared/widgets/belluga_network_image.dart';
import 'package:belluga_now/presentation/shared/widgets/directions_app_chooser/directions_app_chooser.dart';
import 'package:belluga_now/presentation/shared/widgets/directions_app_chooser/directions_app_chooser_contract.dart';
import 'package:belluga_now/presentation/shared/widgets/directions_app_chooser/directions_launch_target.dart';
import 'package:belluga_now/presentation/shared/widgets/immersive_detail_screen/immersive_common_tabs.dart';
import 'package:belluga_now/presentation/shared/widgets/immersive_detail_screen/immersive_detail_screen.dart';
import 'package:belluga_now/presentation/shared/widgets/immersive_detail_screen/models/immersive_hero_action.dart';
import 'package:belluga_now/presentation/shared/widgets/immersive_detail_screen/models/immersive_tab_item.dart';
import 'package:belluga_now/presentation/shared/widgets/immersive_detail_screen/tabs/immersive_directions_section.dart';
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
    this.shareLauncher,
    this.externalUrlLauncher,
  });

  final PublicStaticAssetModel asset;
  final StaticAssetDetailController? controller;
  final DirectionsAppChooserContract? directionsAppChooser;
  final SystemShareLauncher? shareLauncher;
  final ExternalUrlLauncher? externalUrlLauncher;

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
        backPolicy: buildCanonicalCurrentRouteBackPolicy(context),
        heroActions: _buildHeroActions(),
        tabs: tabs,
      ),
    );
  }

  List<ImmersiveHeroAction> _buildHeroActions() {
    return <ImmersiveHeroAction>[
      ImmersiveHeroAction(
        key: const Key('staticAssetShareAction'),
        label: 'Compartilhar',
        icon: BooraIcons.share,
        isPrimary: true,
        onPressed: () => unawaited(_shareStaticAsset()),
      ),
      ImmersiveHeroAction(
        key: const Key('staticAssetWhatsappAction'),
        label: 'WhatsApp',
        icon: BooraIcons.whatsapp,
        foregroundColor: const Color(0xFF25D366),
        onPressed: () => unawaited(_shareStaticAssetOnWhatsApp()),
      ),
    ];
  }

  List<ImmersiveTabItem> _buildTabs() {
    final tabs = <ImmersiveTabItem>[];
    final aboutContent = widget.asset.resolvedDescription;
    if (aboutContent != null && aboutContent.trim().isNotEmpty) {
      tabs.add(
        ImmersiveCommonTabs.about(
          content: _aboutSection(aboutContent),
        ),
      );
    }
    if (widget.asset.hasLocation) {
      tabs.add(
        ImmersiveCommonTabs.directions(
          content: _locationSection(),
        ),
      );
    }
    if (tabs.isEmpty) {
      tabs.add(
        ImmersiveCommonTabs.about(
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
    return ImmersiveDirectionsSection(
      padding: const EdgeInsets.all(16),
      mapCanvas: _buildLocationMapCanvas(),
      canOpenMap: true,
      onOpenMap: _openAssetMap,
      directionsTarget: _directionsTarget(),
      onOpenDirectDirections: _openDirectDirections,
      onOpenOtherDirections: _presentDirectionsTarget,
      primaryWazeButtonKey: const Key('staticAssetMainWazeButton'),
      primaryUberButtonKey: const Key('staticAssetMainUberButton'),
      primaryOtherButtonKey: const Key('staticAssetMainOtherDirectionsButton'),
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
    final payload = _buildStaticAssetPublicSharePayload();
    try {
      await PublicShareLauncher.launchSystemShare(
        ShareParams(
          text: payload.message,
          subject: payload.subject,
        ),
        launcher: widget.shareLauncher,
      );
    } catch (_) {
      _showStatusMessage(
          'Não foi possível compartilhar ${widget.asset.displayName}.');
    }
  }

  Future<void> _shareStaticAssetOnWhatsApp() async {
    final payload = _buildStaticAssetPublicSharePayload();
    try {
      await PublicShareLauncher.launchWhatsAppOrSystemShare(
        text: payload.message,
        subject: payload.subject,
        fallbackShareLauncher: widget.shareLauncher,
        externalUrlLauncher: widget.externalUrlLauncher,
      );
    } catch (_) {
      _showStatusMessage(
          'Não foi possível compartilhar ${widget.asset.displayName}.');
    }
  }

  ({String subject, String message}) _buildStaticAssetPublicSharePayload() {
    final publicUri = _controller.buildTenantPublicUriForAsset(widget.asset);
    return StaticAssetPublicSharePayloadBuilder.build(
      publicUri: publicUri,
      fallbackName: widget.asset.displayName,
      asset: widget.asset,
      actorDisplayName: _controller.authenticatedUserDisplayName,
    );
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

  Future<void> _openDirectDirections(
    DirectionsDirectProvider provider,
    DirectionsLaunchTarget target,
  ) async {
    final launched = await _directionsAppChooser.launchDirect(
      provider: provider,
      target: target,
    );
    if (!launched) {
      _showStatusMessage('Não foi possível abrir o aplicativo de rota.');
    }
  }

  Future<void> _presentDirectionsTarget(DirectionsLaunchTarget target) async {
    await _directionsAppChooser.present(
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
