import 'package:belluga_now/domain/partners/profile_type_registry.dart';
import 'package:belluga_now/domain/partners/account_profile_gallery_item.dart';
import 'package:belluga_now/domain/schedule/event_linked_account_profile.dart';
import 'package:belluga_now/domain/schedule/event_model.dart';
import 'package:belluga_now/application/rich_text/safe_rich_html.dart';
import 'package:belluga_now/presentation/shared/visuals/account_profile_visual_resolver.dart';
import 'package:belluga_now/presentation/shared/visuals/resolved_account_profile_visual.dart';
import 'package:belluga_now/presentation/shared/widgets/belluga_network_image.dart';
import 'package:belluga_now/presentation/shared/widgets/account_profile_overlapping_identity_card.dart';
import 'package:belluga_now/presentation/shared/widgets/directions_app_chooser/directions_app_chooser_contract.dart';
import 'package:belluga_now/presentation/shared/widgets/directions_app_chooser/directions_launch_target.dart';
import 'package:belluga_now/presentation/shared/widgets/directions_app_chooser/directions_provider_actions.dart';
import 'package:belluga_now/presentation/shared/widgets/immersive_detail_screen/tabs/immersive_directions_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart' hide Marker;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class EventLocalSection extends StatelessWidget {
  const EventLocalSection({
    required this.event,
    required this.profileTypeRegistry,
    this.onOpenMap,
    this.onOpenDestinationMap,
    this.onOpenDirectDirections,
    this.onOpenOtherDirections,
    this.canOpenMap = false,
    super.key,
  });

  final EventModel event;
  final ProfileTypeRegistry? profileTypeRegistry;
  final VoidCallback? onOpenMap;
  final ValueChanged<EventLinkedAccountProfile>? onOpenDestinationMap;
  final Future<void> Function(
    DirectionsDirectProvider provider,
    DirectionsLaunchTarget target,
  )?
  onOpenDirectDirections;
  final Future<void> Function(DirectionsLaunchTarget target)?
  onOpenOtherDirections;
  final bool canOpenMap;

  @override
  Widget build(BuildContext context) {
    final venue = event.venue;
    if (venue == null || venue.displayName.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    final resolvedVisual = AccountProfileVisualResolver.resolvePreview(
      registry: profileTypeRegistry,
      profileType: venue.normalizedProfileType,
      avatarUrl: venue.logoImageUrl,
      coverUrl: venue.heroImageUrl,
    );
    final showNavigation = venue.supportsPublicNavigation;
    final directionsTarget = _directionsTargetFromEvent(
      event,
      destinationName: venue.displayName,
    );
    final relatedDestinations = showNavigation
        ? _buildDestinations(event)
        : const <_LocationDestination>[];
    final galleryItems = [
      for (final group in venue.galleryGroups) ...group.items,
    ].take(3).toList(growable: false);
    final venueBioHtml = SafeRichHtml.canonicalize(venue.bio?.trim() ?? '');
    final hasVenueBio = !SafeRichHtml.isEffectivelyEmpty(venueBioHtml);
    final tags = venue.taxonomyLabels
        .map((label) => label.value.trim())
        .where((label) => label.isNotEmpty)
        .toList(growable: false);

    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16).copyWith(bottom: 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'O Local',
            key: const Key('eventLocalSectionTitle'),
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 16),
          _EventLocalHero(
            venueName: venue.displayName,
            coverUrl: venue.heroImageUrl,
            resolvedVisual: resolvedVisual,
            tags: tags,
          ),
          if (hasVenueBio) ...[
            const SizedBox(height: 20),
            Html(
              key: const Key('eventLocalDescription'),
              data: venueBioHtml,
              style: {
                'body': Style(
                  margin: Margins.zero,
                  padding: HtmlPaddings.zero,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: FontSize(
                    Theme.of(context).textTheme.bodyLarge?.fontSize ?? 16,
                  ),
                  lineHeight: const LineHeight(1.45),
                ),
                'p': Style(margin: Margins.only(bottom: 12)),
                'strong': Style(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w800,
                ),
                'br': Style(display: Display.block),
              },
            ),
          ],
          if (galleryItems.isNotEmpty) ...[
            const SizedBox(height: 20),
            _EventLocalGalleryStrip(items: galleryItems),
          ],
          if (showNavigation && directionsTarget != null) ...[
            const SizedBox(height: 24),
            _PrimaryDirectionsCard(
              event: event,
              target: directionsTarget,
              canOpenMap: canOpenMap,
              onOpenMap: onOpenMap,
              onOpenDirectDirections: onOpenDirectDirections,
              onOpenOtherDirections: onOpenOtherDirections,
            ),
          ],
          if (showNavigation && relatedDestinations.isNotEmpty) ...[
            const SizedBox(height: 20),
            Row(
              key: const Key('eventLocalRelatedHeading'),
              children: [
                Text(
                  'Outros endereços relacionados',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Divider(
                    color: Theme.of(context).colorScheme.outlineVariant,
                    thickness: 1,
                    height: 1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ...relatedDestinations.map(
              (destination) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _LocationDestinationTile(
                  destination: destination,
                  onTap: destination.profile == null
                      ? onOpenMap
                      : onOpenDestinationMap == null
                      ? null
                      : () => onOpenDestinationMap!(destination.profile!),
                  onOpenDirectDirections: onOpenDirectDirections,
                  onOpenOtherDirections: onOpenOtherDirections,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<_LocationDestination> _buildDestinations(EventModel event) {
    final destinations = <_LocationDestination>[];
    final seen = <String>{};

    final venueId = event.venue?.id.trim();
    if (venueId != null && venueId.isNotEmpty) {
      seen.add('account_profile:$venueId');
    }

    for (final item in event.allProgrammingItems) {
      final profile = item.locationProfile;
      if (profile == null) {
        continue;
      }
      final profileId = profile.id.trim();
      if (profileId.isEmpty) {
        continue;
      }
      final key = 'account_profile:$profileId';
      if (!seen.add(key)) {
        continue;
      }
      destinations.add(
        _LocationDestination(
          key: key,
          title: profile.displayName,
          profile: profile,
        ),
      );
    }

    return List<_LocationDestination>.unmodifiable(destinations);
  }

  DirectionsLaunchTarget? _directionsTargetFromEvent(
    EventModel event, {
    required String destinationName,
  }) {
    final address = event.location.value.trim();
    final coordinate = event.coordinate;
    if (coordinate != null) {
      return DirectionsLaunchTarget(
        destinationName: destinationName,
        latitude: coordinate.latitude,
        longitude: coordinate.longitude,
        address: address.isEmpty ? null : address,
      );
    }
    if (address.isEmpty) {
      return null;
    }
    return DirectionsLaunchTarget(
      destinationName: destinationName,
      address: address,
    );
  }
}

class _EventLocalHero extends StatelessWidget {
  const _EventLocalHero({
    required this.venueName,
    required this.coverUrl,
    required this.resolvedVisual,
    required this.tags,
  });

  final String venueName;
  final String? coverUrl;
  final ResolvedAccountProfileVisual resolvedVisual;
  final List<String> tags;

  @override
  Widget build(BuildContext context) {
    final hasCover = coverUrl != null && coverUrl!.trim().isNotEmpty;
    final identityCard = AccountProfileOverlappingIdentityCard(
      cardKey: const Key('eventLocalIdentityPlate'),
      name: venueName,
      visual: resolvedVisual,
      tags: tags,
    );

    if (hasCover) {
      return Stack(
        key: const Key('eventLocalHeroWithCover'),
        clipBehavior: Clip.none,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: SizedBox(
                  height: 184,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      BellugaNetworkImage(
                        coverUrl!,
                        fit: BoxFit.cover,
                        semanticLabel: venueName,
                      ),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.08),
                              Colors.black.withValues(alpha: 0.32),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Transform.translate(
                offset: const Offset(0, -34),
                child: identityCard,
              ),
            ],
          ),
        ],
      );
    }

    return KeyedSubtree(
      key: const Key('eventLocalHeroWithoutCover'),
      child: identityCard,
    );
  }
}

class _EventLocalGalleryStrip extends StatelessWidget {
  const _EventLocalGalleryStrip({required this.items});

  final List<AccountProfileGalleryItem> items;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: const Key('eventLocalGalleryStrip'),
      height: 88,
      child: Row(
        children: [
          for (var index = 0; index < items.length; index++) ...[
            if (index > 0) const SizedBox(width: 10),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: BellugaNetworkImage(
                  items[index].previewUrl,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PrimaryDirectionsCard extends StatelessWidget {
  const _PrimaryDirectionsCard({
    required this.event,
    required this.target,
    required this.canOpenMap,
    required this.onOpenMap,
    required this.onOpenDirectDirections,
    required this.onOpenOtherDirections,
  });

  final EventModel event;
  final DirectionsLaunchTarget target;
  final bool canOpenMap;
  final VoidCallback? onOpenMap;
  final Future<void> Function(
    DirectionsDirectProvider provider,
    DirectionsLaunchTarget target,
  )?
  onOpenDirectDirections;
  final Future<void> Function(DirectionsLaunchTarget target)?
  onOpenOtherDirections;

  @override
  Widget build(BuildContext context) {
    return ImmersiveDirectionsSection(
      padding: EdgeInsets.zero,
      showTitle: false,
      mapCanvas: _EventLocationMapCanvas(event: event),
      canOpenMap: canOpenMap,
      onOpenMap: onOpenMap,
      directionsTarget: target,
      onOpenDirectDirections: onOpenDirectDirections,
      onOpenOtherDirections: onOpenOtherDirections,
      mapTileKey: const Key('eventLocalPrimaryDirectionsMapTile'),
      primaryWazeButtonKey: const Key('eventMainWazeButton'),
      primaryUberButtonKey: const Key('eventMainUberButton'),
      primaryOtherButtonKey: const Key('eventMainOtherDirectionsButton'),
    );
  }
}

class _EventLocationMapCanvas extends StatelessWidget {
  const _EventLocationMapCanvas({required this.event});

  final EventModel event;

  @override
  Widget build(BuildContext context) {
    final coordinate = event.coordinate;
    final colorScheme = Theme.of(context).colorScheme;
    if (coordinate == null) {
      return DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.primaryContainer,
              colorScheme.secondaryContainer,
            ],
          ),
        ),
        child: Center(
          child: Icon(Icons.location_on, color: colorScheme.primary, size: 46),
        ),
      );
    }

    final point = LatLng(coordinate.latitude, coordinate.longitude);
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
                    child: Icon(Icons.storefront, color: colorScheme.onPrimary),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LocationDestination {
  const _LocationDestination({
    required this.key,
    required this.title,
    required this.profile,
  });

  final String key;
  final String title;
  final EventLinkedAccountProfile? profile;

  DirectionsLaunchTarget? get routeTarget {
    final locationProfile = profile;
    if (locationProfile == null) {
      return null;
    }

    final address = locationProfile.locationAddress?.trim();
    final latitude = locationProfile.locationLat;
    final longitude = locationProfile.locationLng;
    if (latitude != null && longitude != null) {
      return DirectionsLaunchTarget(
        destinationName: title,
        latitude: latitude,
        longitude: longitude,
        address: address == null || address.isEmpty ? null : address,
      );
    }

    if (address != null && address.isNotEmpty) {
      return DirectionsLaunchTarget(destinationName: title, address: address);
    }

    return null;
  }
}

class _LocationDestinationTile extends StatelessWidget {
  const _LocationDestinationTile({
    required this.destination,
    required this.onTap,
    required this.onOpenDirectDirections,
    required this.onOpenOtherDirections,
  });

  final _LocationDestination destination;
  final VoidCallback? onTap;
  final Future<void> Function(
    DirectionsDirectProvider provider,
    DirectionsLaunchTarget target,
  )?
  onOpenDirectDirections;
  final Future<void> Function(DirectionsLaunchTarget target)?
  onOpenOtherDirections;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final routeTarget = destination.routeTarget;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: Key('eventLocationDestination_${destination.key}'),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            14,
            12,
            14,
            routeTarget == null ? 12 : 10,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.location_on_outlined, color: colorScheme.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      destination.title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  if (onTap != null) ...[
                    const SizedBox(width: 10),
                    const Icon(Icons.map_outlined),
                  ],
                ],
              ),
              if (routeTarget != null) ...[
                const SizedBox(height: 10),
                DirectionsProviderActions(
                  target: routeTarget,
                  isPrimary: false,
                  compact: true,
                  onOpenDirectDirections: onOpenDirectDirections,
                  onOpenOtherDirections: onOpenOtherDirections,
                  wazeButtonKey: const Key('eventSecondaryWazeButton'),
                  uberButtonKey: const Key('eventSecondaryUberButton'),
                  otherButtonKey: const Key(
                    'eventSecondaryOtherDirectionsButton',
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
