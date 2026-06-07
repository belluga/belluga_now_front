import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/icons/boora_icons.dart';
import 'package:belluga_now/application/invites/invite_from_event_factory.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/application/sharing/account_profile_public_share_payload.dart';
import 'package:belluga_now/application/sharing/static_asset_public_share_payload.dart';
import 'package:belluga_now/application/telemetry/auth_wall_telemetry.dart';
import 'package:belluga_now/domain/map/city_poi_model.dart';
import 'package:belluga_now/domain/partners/account_profile_model.dart';
import 'package:belluga_now/domain/proximity_preferences/proximity_preference.dart';
import 'package:belluga_now/presentation/tenant_public/map/screens/map_screen/controllers/map_screen_controller.dart';
import 'package:belluga_now/presentation/tenant_public/map/screens/map_screen/widgets/filtered_deck.dart';
import 'package:belluga_now/presentation/tenant_public/map/screens/map_screen/widgets/poi_card_reference_point_action.dart';
import 'package:belluga_now/presentation/tenant_public/map/screens/map_screen/widgets/poi_card_secondary_action.dart';
import 'package:belluga_now/presentation/tenant_public/map/screens/map_screen/widgets/poi_detail_card_builder.dart';
import 'package:belluga_now/presentation/tenant_public/map/screens/map_screen/widgets/shared/poi_content_resolver.dart';
import 'package:belluga_now/presentation/tenant_public/map/screens/map_screen/widgets/single_poi_card.dart';
import 'package:belluga_now/presentation/shared/promotion/support/web_installed_app_handoff.dart';
import 'package:belluga_now/presentation/shared/widgets/account_profile_identity_block.dart';
import 'package:belluga_now/presentation/shared/widgets/directions_app_chooser/directions_app_chooser.dart';
import 'package:belluga_now/presentation/shared/widgets/directions_app_chooser/directions_app_chooser_contract.dart';
import 'package:belluga_now/presentation/shared/widgets/directions_app_chooser/directions_launch_target.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:stream_value/core/stream_value_builder.dart';

const double _kDeckMeasurementPadding = 32;

class PoiDetailDeck extends StatefulWidget {
  const PoiDetailDeck({
    super.key,
    required this.controller,
    this.directionsAppChooser,
  });

  final MapScreenController controller;
  final DirectionsAppChooserContract? directionsAppChooser;

  @override
  State<PoiDetailDeck> createState() => _PoiDetailDeckState();
}

class _PoiDetailDeckState extends State<PoiDetailDeck>
    with TickerProviderStateMixin {
  static const double _kFilteredDeckViewportFraction = 0.82;

  late final MapScreenController _controller = widget.controller;
  late final DirectionsAppChooserContract _directionsAppChooser =
      widget.directionsAppChooser ?? DirectionsAppChooser();
  final PoiDetailCardBuilder _cardBuilder = const PoiDetailCardBuilder();
  late final PageController _pageController = PageController(
    viewportFraction: _kFilteredDeckViewportFraction,
  );

  static const double _defaultCardHeight = 356;
  static const double _minCardHeight = 280;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return StreamValueBuilder<CityPoiModel?>(
      streamValue: _controller.selectedPoiStreamValue,
      onNullWidget: const SizedBox.shrink(),
      builder: (_, poi) {
        return StreamValueBuilder<int>(
          streamValue: _controller.poiDeckContentRevisionStreamValue,
          builder: (_, __) {
            return StreamValueBuilder<ProximityPreference?>(
              streamValue: _controller.proximityPreferenceStreamValue,
              builder: (_, __) {
                return StreamValueBuilder<int>(
                  streamValue: _controller.poiDeckHeightRevisionStreamValue,
                  builder: (_, __) {
                    final selectedPoi = poi!;
                    final deckPois =
                        _controller.deckPoisForSelectedPoi(selectedPoi);
                    final useFilteredDeck = deckPois.length > 1;
                    final deckIndex = _controller.deckIndexForSelectedPoi(
                      selectedPoi,
                      deckPois,
                    );
                    _syncPageController(deckIndex);
                    final resolvedDeckHeight = useFilteredDeck
                        ? _heightForDeck(
                            context,
                            deckPois,
                            deckIndex,
                          )
                        : _heightForPoi(context, selectedPoi);
                    return Align(
                      alignment: Alignment.bottomCenter,
                      child: SizedBox(
                        width: double.infinity,
                        child: useFilteredDeck
                            ? Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  FilteredDeck(
                                    pois: deckPois,
                                    controller: _controller,
                                    colorScheme: scheme,
                                    pageController: _pageController,
                                    cardBuilder: _cardBuilder,
                                    onPrimaryAction: _handlePoiAction,
                                    showPrimaryActionForPoi:
                                        _showPrimaryActionForPoi,
                                    secondaryActionForPoi:
                                        _secondaryActionForPoi,
                                    onRoute: _handleRoute,
                                    referencePointActionForPoi:
                                        _referencePointActionForPoi,
                                    onClose: _controller.clearSelectedPoi,
                                    onChanged: (index) => unawaited(
                                      _controller
                                          .handleFilteredDeckPageChanged(index),
                                    ),
                                    deckHeight: resolvedDeckHeight,
                                    onCardHeightChanged: (poiId, height) =>
                                        _handleMeasuredHeight(
                                      context,
                                      poiId,
                                      height,
                                    ),
                                    deckMeasurementPadding:
                                        _kDeckMeasurementPadding,
                                  ),
                                ],
                              )
                            : ConstrainedBox(
                                constraints:
                                    const BoxConstraints(maxWidth: 372),
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    SinglePoiCard(
                                      poi: selectedPoi,
                                      colorScheme: scheme,
                                      cardBuilder: _cardBuilder,
                                      onPrimaryAction: _handlePoiAction,
                                      showPrimaryAction:
                                          _showPrimaryActionForPoi(
                                        selectedPoi,
                                      ),
                                      secondaryAction: _secondaryActionForPoi(
                                        selectedPoi,
                                      ),
                                      onRoute: _handleRoute,
                                      referencePointAction:
                                          _referencePointActionForPoi(
                                        selectedPoi,
                                      ),
                                      onClose: _controller.clearSelectedPoi,
                                      onCardHeightChanged: (poiId, height) =>
                                          _handleMeasuredHeight(
                                        context,
                                        poiId,
                                        height,
                                      ),
                                      deckHeight: resolvedDeckHeight,
                                      deckMeasurementPadding:
                                          _kDeckMeasurementPadding,
                                    ),
                                  ],
                                ),
                              ),
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  PoiCardReferencePointAction? _referencePointActionForPoi(CityPoiModel poi) {
    if (!_controller.canUsePoiAsReferencePoint(poi)) {
      return null;
    }
    return PoiCardReferencePointAction(
      isActive: _controller.isPoiReferencePoint(poi),
      onTap: () => unawaited(_handleReferencePointTap(poi)),
      onClear: () => unawaited(_handleClearReferencePointTap()),
    );
  }

  Future<void> _handleReferencePointTap(CityPoiModel poi) async {
    if (_controller.isPoiReferencePoint(poi)) {
      return;
    }
    final confirmed = await _showReferencePointConfirmationDialog(poi);
    if (!confirmed) {
      return;
    }
    await _controller.setPoiAsReferencePoint(poi);
  }

  Future<void> _handleClearReferencePointTap() async {
    final confirmed = await _showClearReferencePointConfirmationDialog();
    if (!mounted || !confirmed) {
      return;
    }
    await _controller.clearReferencePoint();
  }

  Future<bool> _showReferencePointConfirmationDialog(CityPoiModel poi) async {
    final profile = _controller.hydratedAccountProfileForPoi(poi);
    if (profile == null) {
      return false;
    }
    final result = await showDialog<bool>(
      context: context,
      useRootNavigator: false,
      builder: (dialogContext) {
        return AlertDialog(
          key: const Key('poiReferencePointDialog'),
          contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text.rich(
                const TextSpan(
                  text: 'Todas as ',
                  children: [
                    TextSpan(
                      text: 'distâncias',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    TextSpan(text: ' serão '),
                    TextSpan(
                      text: 'calculadas',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    TextSpan(text: ' a partir desse local:'),
                  ],
                ),
                key: const Key('poiReferencePointDialogCopy'),
                style: Theme.of(dialogContext).textTheme.bodyLarge,
              ),
              const SizedBox(height: 16),
              _buildReferencePointPreviewCard(
                dialogContext,
                poi: poi,
                profile: profile,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  key: const Key('poiReferencePointConfirmButton'),
                  onPressed: () => dialogContext.router.maybePop(true),
                  icon: const Icon(Icons.location_on_outlined),
                  label: const Text('Usar como Ponto de Referência'),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  key: const Key('poiReferencePointCancelButton'),
                  onPressed: () => dialogContext.router.maybePop(false),
                  child: const Text('Cancelar'),
                ),
              ),
            ],
          ),
        );
      },
    );
    return result ?? false;
  }

  Future<bool> _showClearReferencePointConfirmationDialog() async {
    final result = await showDialog<bool>(
      context: context,
      useRootNavigator: false,
      builder: (dialogContext) {
        return AlertDialog(
          key: const Key('poiClearReferencePointDialog'),
          contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Cancelar ponto de referência?',
                style: Theme.of(dialogContext).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'As distâncias voltarão a usar sua localização atual.',
                style: Theme.of(dialogContext).textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  key: const Key('poiClearReferencePointConfirmButton'),
                  onPressed: () => dialogContext.router.maybePop(true),
                  icon: const Icon(Icons.location_off_outlined),
                  label: const Text('Cancelar ponto de referência'),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  onPressed: () => dialogContext.router.maybePop(false),
                  child: const Text('Manter'),
                ),
              ),
            ],
          ),
        );
      },
    );
    return result ?? false;
  }

  Widget _buildReferencePointPreviewCard(
    BuildContext context, {
    required CityPoiModel poi,
    required AccountProfileModel profile,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final resolvedVisual = _controller.resolvedVisualForAccountProfile(profile);
    final typeLabel = resolvedVisual.typeLabel.trim();
    final address =
        profile.locationAddress ?? PoiContentResolver.compactAddress(poi);
    final distanceLabel = PoiContentResolver.distanceLabel(
      poi,
      includeAudienceSuffix: true,
    );

    return Container(
      key: const Key('poiReferencePointPreviewCard'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: AccountProfileIdentityBlock(
        name: profile.name,
        avatarUrl: resolvedVisual.identityAvatarUrl,
        typeVisual: resolvedVisual.typeVisual,
        avatarSize: 44,
        avatarSpacing: 10,
        typeAvatarSize: 22,
        typeAvatarIconSize: 14,
        titleMaxLines: 1,
        titleStyle: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w800,
            ),
        supportingSpacing: 8,
        supporting: _buildReferencePointPreviewSupporting(
          context,
          typeLabel: typeLabel,
          address: address,
          distanceLabel: distanceLabel,
        ),
      ),
    );
  }

  Widget? _buildReferencePointPreviewSupporting(
    BuildContext context, {
    required String typeLabel,
    required String? address,
    required String? distanceLabel,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final rows = <Widget>[
      if (typeLabel.isNotEmpty)
        Text(
          typeLabel,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
        ),
      if (address != null)
        _buildReferencePointPreviewMetaRow(
          context,
          icon: Icons.place_outlined,
          label: address,
        )
      else if (distanceLabel != null)
        _buildReferencePointPreviewMetaRow(
          context,
          icon: Icons.place_outlined,
          label: distanceLabel,
        ),
    ];

    if (rows.isEmpty) {
      return null;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var index = 0; index < rows.length; index++) ...[
          if (index > 0) const SizedBox(height: 4),
          rows[index],
        ],
      ],
    );
  }

  Widget _buildReferencePointPreviewMetaRow(
    BuildContext context, {
    required IconData icon,
    required String label,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 15,
          color: colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
          ),
        ),
      ],
    );
  }

  void _syncPageController(int index) {
    if (!_pageController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        try {
          if (!_pageController.hasClients) {
            return;
          }
          if (_pageController.page?.round() == index) {
            return;
          }
          _pageController.jumpToPage(index);
        } catch (_) {
          return;
        }
      });
      return;
    }
    if (_pageController.page?.round() == index) {
      return;
    }
    _pageController.jumpToPage(index);
  }

  void _handlePoiAction(CityPoiModel poi) {
    if (_isEventPoi(poi)) {
      final eventSlug = _resolveEventSlug(poi);
      if (eventSlug.isNotEmpty) {
        final occurrenceId =
            _controller.hydratedEventForPoi(poi)?.selectedOccurrenceId;
        context.router.push(
          ImmersiveEventDetailRoute(
            eventSlug: eventSlug,
            occurrenceId: occurrenceId,
          ),
        );
        return;
      }
      _controller.statusMessageStreamValue.addValue(
        'Evento sem referência para abrir detalhes.',
      );
      return;
    }
    if (_isPartnerPoi(poi)) {
      final partnerSlug = _resolvePartnerSlug(poi);
      if (partnerSlug.isNotEmpty) {
        context.router.push(PartnerDetailRoute(slug: partnerSlug));
        return;
      }
      _controller.statusMessageStreamValue.addValue(
        'Perfil sem referência para abrir detalhes.',
      );
      return;
    }
    if (_isStaticPoi(poi)) {
      final assetRef = _resolveStaticAssetRef(poi);
      if (assetRef.isNotEmpty) {
        context.router.push(StaticAssetDetailRoute(assetRef: assetRef));
        return;
      }
      _controller.statusMessageStreamValue.addValue(
        'Ativo sem referência para abrir detalhes.',
      );
      return;
    }
    final poiQueryKey = _controller.buildPoiQueryKey(poi);
    if (poiQueryKey.isEmpty) {
      _controller.statusMessageStreamValue.addValue(
        'POI sem referência para abrir detalhes.',
      );
      return;
    }
    final stackQueryKey = poi.stackKey.trim();
    context.router.replace(
      CityMapRoute(
        poi: poiQueryKey,
        stack: stackQueryKey.isEmpty ? null : stackQueryKey,
      ),
    );
  }

  bool _showPrimaryActionForPoi(CityPoiModel poi) {
    if (_isPartnerPoi(poi)) {
      return _resolvePartnerSlug(poi).isNotEmpty;
    }
    return true;
  }

  Future<void> _handleRoute(CityPoiModel poi) async {
    _controller.logDirectionsOpened(poi);
    final target = _directionsTargetFromPoi(poi);
    if (target == null) {
      _controller.statusMessageStreamValue
          .addValue('Localização indisponível para ${poi.name}.');
      return;
    }
    await _directionsAppChooser.present(
      context,
      target: target,
      onStatusMessage: _controller.statusMessageStreamValue.addValue,
    );
  }

  DirectionsLaunchTarget? _directionsTargetFromPoi(CityPoiModel poi) {
    final address = poi.address.trim();
    return DirectionsLaunchTarget(
      destinationName: poi.name,
      latitude: poi.coordinate.latitude,
      longitude: poi.coordinate.longitude,
      address: address.isEmpty ? null : address,
    );
  }

  bool _isEventPoi(CityPoiModel poi) {
    if (poi.refType.trim().toLowerCase() == 'event') {
      return true;
    }
    return poi.isDynamic;
  }

  bool _isPartnerPoi(CityPoiModel poi) {
    final refType = poi.refType.trim().toLowerCase();
    return refType == 'account_profile' ||
        refType == 'accountprofile' ||
        refType == 'partner';
  }

  bool _isStaticPoi(CityPoiModel poi) {
    final refType = poi.refType.trim().toLowerCase();
    return refType == 'static' ||
        refType == 'static_asset' ||
        refType == 'asset';
  }

  String _resolveEventSlug(CityPoiModel poi) {
    final slug = poi.refSlug?.trim() ?? '';
    if (slug.isNotEmpty) {
      return slug;
    }
    final fromPath = _extractSlugFromPath(poi.refPath);
    if (fromPath.isNotEmpty) {
      return fromPath;
    }
    return poi.refId.trim();
  }

  String _resolvePartnerSlug(CityPoiModel poi) {
    final profile = _controller.hydratedAccountProfileForPoi(poi);
    if (profile == null || !profile.canOpenPublicDetail) {
      return '';
    }
    final publicDetailPath = profile.publicDetailPath?.trim();
    if (publicDetailPath != null && publicDetailPath.isNotEmpty) {
      final fromPublicPath = _extractSlugFromPath(publicDetailPath);
      if (fromPublicPath.isNotEmpty) {
        return fromPublicPath;
      }
    }
    return profile.slug.trim();
  }

  String _resolveStaticAssetRef(CityPoiModel poi) {
    final refSlug = poi.refSlug?.trim();
    if (refSlug != null && refSlug.isNotEmpty) {
      return refSlug;
    }
    final refId = poi.refId.trim();
    if (refId.isNotEmpty) {
      return refId;
    }
    final fromPath = _extractSlugFromPath(poi.refPath);
    if (fromPath.isNotEmpty) {
      return fromPath;
    }
    return '';
  }

  String _extractSlugFromPath(String? refPath) {
    final path = refPath?.trim() ?? '';
    if (path.isEmpty) {
      return '';
    }
    try {
      final segments = Uri.parse(path)
          .pathSegments
          .where((segment) => segment.trim().isNotEmpty)
          .toList(growable: false);
      if (segments.isEmpty) {
        return '';
      }
      return segments.last.trim();
    } catch (_) {
      return '';
    }
  }

  PoiCardSecondaryAction? _secondaryActionForPoi(CityPoiModel poi) {
    if (_isPartnerPoi(poi) && _canSharePartnerPoi(poi)) {
      return PoiCardSecondaryAction(
        icon: Icons.share_outlined,
        tooltip: 'Compartilhar',
        onTap: () => unawaited(_shareAccountProfile(poi)),
      );
    }

    if (_isEventPoi(poi)) {
      return PoiCardSecondaryAction(
        icon: BooraIcons.inviteSolid,
        tooltip: 'Convidar',
        onTap: () => unawaited(_openEventInvite(poi)),
      );
    }

    if (_isStaticPoi(poi)) {
      return PoiCardSecondaryAction(
        icon: Icons.share_outlined,
        tooltip: 'Compartilhar',
        onTap: () => unawaited(_shareStaticAsset(poi)),
      );
    }

    return null;
  }

  Future<void> _shareAccountProfile(CityPoiModel poi) async {
    final sharePath = _resolvePartnerSharePath(poi);
    final publicUri = _controller.buildTenantPublicUriFromPath(sharePath);
    if (publicUri == null) {
      _controller.statusMessageStreamValue
          .addValue('Não foi possível compartilhar ${poi.name}.');
      return;
    }

    final profile = _controller.hydratedAccountProfileForPoi(poi);
    final payload = AccountProfilePublicSharePayloadBuilder.build(
      publicUri: publicUri,
      fallbackName: poi.name,
      profile: profile,
      actorDisplayName: _controller.authenticatedUserDisplayName,
      fallbackDescription: poi.description,
    );

    try {
      await SharePlus.instance.share(
        ShareParams(
          text: payload.message,
          subject: payload.subject,
        ),
      );
    } catch (_) {
      _controller.statusMessageStreamValue
          .addValue('Não foi possível compartilhar ${poi.name}.');
    }
  }

  Future<void> _openEventInvite(CityPoiModel poi) async {
    final event = _controller.hydratedEventForPoi(poi);
    final eventPath = _resolveEventSharePath(poi, eventSlug: event?.slug);
    if (eventPath == null || eventPath.isEmpty) {
      _controller.statusMessageStreamValue
          .addValue('Evento sem referência para convidar.');
      return;
    }

    if (kIsWeb) {
      launchWebInstalledAppHandoffOrPromotion(
        context: context,
        redirectPath: eventPath,
        actionType: AuthWallActionType.sendInvite,
      );
      return;
    }

    if (event == null) {
      _controller.statusMessageStreamValue
          .addValue('Detalhes do evento ainda não estão prontos para convite.');
      return;
    }

    final invite = InviteFromEventFactory.build(
      event: event,
      fallbackImageUri: _controller.defaultEventImageUri,
    );
    context.router.push(InviteShareRoute(invite: invite));
  }

  Future<void> _shareStaticAsset(CityPoiModel poi) async {
    final publicPath = _resolveStaticAssetSharePath(poi);
    final publicUri = _controller.buildTenantPublicUriFromPath(publicPath);
    if (publicUri == null) {
      _controller.statusMessageStreamValue
          .addValue('Não foi possível compartilhar ${poi.name}.');
      return;
    }

    final asset = _controller.hydratedStaticAssetForPoi(poi);
    final payload = StaticAssetPublicSharePayloadBuilder.build(
      publicUri: publicUri,
      fallbackName: poi.name,
      asset: asset,
      actorDisplayName: _controller.authenticatedUserDisplayName,
      fallbackDescription: poi.description,
    );

    try {
      await SharePlus.instance.share(
        ShareParams(
          text: payload.message,
          subject: payload.subject,
        ),
      );
    } catch (_) {
      _controller.statusMessageStreamValue
          .addValue('Não foi possível compartilhar ${poi.name}.');
    }
  }

  String? _resolvePartnerSharePath(CityPoiModel poi) {
    final profile = _controller.hydratedAccountProfileForPoi(poi);
    if (profile == null || !profile.canOpenPublicDetail) {
      return null;
    }
    final publicDetailPath = profile.publicDetailPath?.trim();
    if (publicDetailPath != null && publicDetailPath.isNotEmpty) {
      return publicDetailPath;
    }
    final slug = profile.slug.trim();
    return slug.isEmpty ? null : '/parceiro/$slug';
  }

  bool _canSharePartnerPoi(CityPoiModel poi) =>
      (_resolvePartnerSharePath(poi)?.trim().isNotEmpty ?? false);

  String? _resolveEventSharePath(
    CityPoiModel poi, {
    String? eventSlug,
  }) {
    final normalizedEventSlug = eventSlug?.trim();
    if (normalizedEventSlug != null && normalizedEventSlug.isNotEmpty) {
      return '/agenda/evento/$normalizedEventSlug';
    }
    final slug = _resolveEventSlug(poi);
    if (slug.isNotEmpty) {
      return '/agenda/evento/$slug';
    }
    final refPath = poi.refPath?.trim();
    if (refPath != null && refPath.isNotEmpty) {
      return refPath;
    }
    return null;
  }

  String? _resolveStaticAssetSharePath(CityPoiModel poi) {
    final asset = _controller.hydratedStaticAssetForPoi(poi);
    final assetSlug = asset?.slug.trim();
    if (assetSlug != null && assetSlug.isNotEmpty) {
      return '/static/$assetSlug';
    }
    final ref = _resolveStaticAssetRef(poi);
    if (ref.isNotEmpty) {
      return '/static/$ref';
    }
    final refPath = poi.refPath?.trim();
    if (refPath != null && refPath.isNotEmpty) {
      return refPath;
    }
    return null;
  }

  void _handleMeasuredHeight(
    BuildContext context,
    String poiId,
    double height,
  ) {
    if (height.isNaN || height <= 0) {
      return;
    }
    final clamped = _clampHeight(context, height);
    final previous = _controller.getPoiDeckHeight(poiId);
    if (previous != null && (previous - clamped).abs() < 1) {
      return;
    }
    _controller.updatePoiDeckHeight(poiId, clamped);
  }

  double _heightForPoi(BuildContext context, CityPoiModel poi) {
    final raw = _controller.getPoiDeckHeight(poi.id) ?? _defaultCardHeight;
    return _clampHeight(context, raw);
  }

  double _heightForDeck(
    BuildContext context,
    List<CityPoiModel> deckPois,
    int deckIndex,
  ) {
    final safeFallbackHeight = _safeFallbackHeight(context);
    final raw = _controller.resolvePoiDeckHeightForDeck(
      deckPois,
      currentIndex: deckIndex,
      defaultHeight: _defaultCardHeight,
      safeFallbackHeight: safeFallbackHeight,
    );
    return _clampHeight(context, raw);
  }

  double _safeFallbackHeight(BuildContext context) {
    final viewportHeight = MediaQuery.of(context).size.height;
    return (viewportHeight * 0.68).clamp(380.0, 520.0).toDouble();
  }

  double _clampHeight(BuildContext context, double raw) {
    final maxHeight = _safeFallbackHeight(context);
    return raw.clamp(_minCardHeight, maxHeight);
  }
}
