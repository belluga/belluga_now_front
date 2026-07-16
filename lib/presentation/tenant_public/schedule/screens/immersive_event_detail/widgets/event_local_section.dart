import 'package:belluga_now/domain/partners/profile_type_registry.dart';
import 'package:belluga_now/domain/partners/account_profile_gallery_item.dart';
import 'package:belluga_now/domain/schedule/event_linked_account_profile.dart';
import 'package:belluga_now/domain/schedule/event_model.dart';
import 'package:belluga_now/application/rich_text/safe_rich_html.dart';
import 'package:belluga_now/presentation/shared/visuals/account_profile_visual_resolver.dart';
import 'package:belluga_now/presentation/shared/visuals/resolved_account_profile_visual.dart';
import 'package:belluga_now/presentation/shared/widgets/account_profile_type_avatar.dart';
import 'package:belluga_now/presentation/shared/widgets/belluga_network_image.dart';
import 'package:belluga_now/presentation/shared/widgets/directions_app_chooser/directions_app_chooser_contract.dart';
import 'package:belluga_now/presentation/shared/widgets/directions_app_chooser/directions_launch_target.dart';
import 'package:belluga_now/presentation/shared/widgets/directions_app_chooser/directions_provider_actions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';

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
        .take(3)
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
            const SizedBox(height: 24),
            Row(
              key: const Key('eventLocalRelatedHeading'),
              children: [
                Icon(
                  Icons.near_me_outlined,
                  size: 18,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
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
    final hasAvatar = resolvedVisual.identityAvatarUrl != null;

    if (hasCover) {
      final heroBadge = _HeroAvatarBadge(resolvedVisual: resolvedVisual);
      final badgeVisible =
          resolvedVisual.identityAvatarUrl != null ||
          resolvedVisual.typeVisual != null;
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
                child: Padding(
                  padding: EdgeInsets.only(
                    left: badgeVisible ? 92 : 0,
                    right: 16,
                  ),
                  child: _IdentityPlate(
                    venueName: venueName,
                    resolvedVisual: resolvedVisual,
                    tags: tags,
                    centered: false,
                    showInlineAvatar: false,
                    strongerTitle: true,
                  ),
                ),
              ),
            ],
          ),
          if (badgeVisible) Positioned(left: 18, bottom: 22, child: heroBadge),
        ],
      );
    }

    return _IdentityPlate(
      venueName: venueName,
      resolvedVisual: resolvedVisual,
      tags: tags,
      centered: !hasAvatar,
      showInlineAvatar: true,
      strongerTitle: false,
    );
  }
}

class _HeroAvatarBadge extends StatelessWidget {
  const _HeroAvatarBadge({required this.resolvedVisual});

  final ResolvedAccountProfileVisual resolvedVisual;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final avatarUrl = resolvedVisual.identityAvatarUrl;
    final typeVisual = resolvedVisual.typeVisual;
    if (avatarUrl == null && typeVisual == null) {
      return const SizedBox.shrink();
    }

    return Container(
      width: 106,
      height: 106,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipOval(
        child: avatarUrl != null
            ? BellugaNetworkImage(avatarUrl, fit: BoxFit.cover)
            : AccountProfileTypeAvatar(
                visual: typeVisual!,
                size: 98,
                iconSize: 42,
              ),
      ),
    );
  }
}

class _IdentityPlate extends StatelessWidget {
  const _IdentityPlate({
    required this.venueName,
    required this.resolvedVisual,
    required this.tags,
    required this.centered,
    required this.showInlineAvatar,
    required this.strongerTitle,
  });

  final String venueName;
  final ResolvedAccountProfileVisual resolvedVisual;
  final List<String> tags;
  final bool centered;
  final bool showInlineAvatar;
  final bool strongerTitle;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasAvatar = resolvedVisual.identityAvatarUrl != null;
    final typeVisual = resolvedVisual.typeVisual;
    final titleStyle = Theme.of(context).textTheme.headlineSmall?.copyWith(
      fontWeight: FontWeight.w800,
      height: 1.05,
      color: strongerTitle ? colorScheme.primary : null,
    );

    return Container(
      key: Key(
        centered
            ? 'eventLocalCenteredIdentityPlate'
            : 'eventLocalIdentityPlate',
      ),
      padding: EdgeInsets.fromLTRB(
        strongerTitle ? 20 : 18,
        strongerTitle ? 22 : 18,
        strongerTitle ? 20 : 18,
        strongerTitle ? 20 : 18,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.97),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: centered
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!hasAvatar && typeVisual != null) ...[
                  AccountProfileTypeAvatar(
                    visual: typeVisual,
                    size: 64,
                    iconSize: 30,
                  ),
                  const SizedBox(height: 12),
                ],
                Text(venueName, textAlign: TextAlign.center, style: titleStyle),
                if (tags.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _TagWrap(tags: tags, centered: true),
                ],
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (showInlineAvatar && hasAvatar)
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: colorScheme.surfaceContainerHighest,
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: BellugaNetworkImage(
                          resolvedVisual.identityAvatarUrl!,
                          fit: BoxFit.cover,
                        ),
                      )
                    else if (showInlineAvatar && typeVisual != null)
                      AccountProfileTypeAvatar(
                        visual: typeVisual,
                        size: 56,
                        iconSize: 26,
                      ),
                    if (showInlineAvatar && (hasAvatar || typeVisual != null))
                      const SizedBox(width: 14),
                    Expanded(child: Text(venueName, style: titleStyle)),
                  ],
                ),
                if (tags.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _TagWrap(tags: tags, centered: false),
                ],
              ],
            ),
    );
  }
}

class _TagWrap extends StatelessWidget {
  const _TagWrap({required this.tags, required this.centered});

  final List<String> tags;
  final bool centered;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Wrap(
      alignment: centered ? WrapAlignment.center : WrapAlignment.start,
      spacing: 8,
      runSpacing: 8,
      children: tags
          .map(
            (tag) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                tag,
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          )
          .toList(growable: false),
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
    final colorScheme = Theme.of(context).colorScheme;
    final address = event.location.value.trim();

    return Container(
      key: const Key('eventLocalPrimaryDirectionsCard'),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: colorScheme.tertiaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.near_me_outlined,
                  color: colorScheme.onTertiaryContainer,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ver no mapa',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (address.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        address,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                key: const Key('eventLocalPrimaryDirectionsMapAction'),
                tooltip: 'Ver no mapa',
                onPressed: canOpenMap ? onOpenMap : null,
                icon: const Icon(Icons.map_outlined),
              ),
              if (canOpenMap)
                Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
            ],
          ),
          const SizedBox(height: 12),
          DirectionsProviderActions(
            target: target,
            isPrimary: true,
            onOpenDirectDirections: onOpenDirectDirections,
            onOpenOtherDirections: onOpenOtherDirections,
            wazeButtonKey: const Key('eventMainWazeButton'),
            uberButtonKey: const Key('eventMainUberButton'),
            otherButtonKey: const Key('eventMainOtherDirectionsButton'),
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
    return Material(
      color: colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        padding: EdgeInsets.fromLTRB(14, 12, 14, routeTarget == null ? 12 : 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              key: Key('eventLocationDestination_${destination.key}'),
              onTap: onTap,
              borderRadius: BorderRadius.circular(14),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      color: colorScheme.primary,
                    ),
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
              ),
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
    );
  }
}
