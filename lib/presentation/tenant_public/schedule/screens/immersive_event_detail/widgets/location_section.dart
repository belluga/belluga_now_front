import 'dart:async';

import 'package:belluga_now/domain/schedule/event_model.dart';
import 'package:belluga_now/domain/schedule/event_linked_account_profile.dart';
import 'package:belluga_now/presentation/shared/widgets/directions_app_chooser/directions_app_chooser_contract.dart';
import 'package:belluga_now/presentation/shared/widgets/directions_app_chooser/directions_launch_target.dart';
import 'package:flutter/material.dart';

class LocationSection extends StatelessWidget {
  const LocationSection({
    required this.event,
    this.onOpenMap,
    this.onOpenDestinationMap,
    this.onOpenDirectDirections,
    this.onOpenOtherDirections,
    this.canOpenMap = false,
    super.key,
  });

  final EventModel event;
  final VoidCallback? onOpenMap;
  final ValueChanged<EventLinkedAccountProfile>? onOpenDestinationMap;
  final Future<void> Function(
    DirectionsDirectProvider provider,
    DirectionsLaunchTarget target,
  )? onOpenDirectDirections;
  final Future<void> Function(DirectionsLaunchTarget target)?
      onOpenOtherDirections;
  final bool canOpenMap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final address = event.location.value.trim();
    final venueName = event.venue?.displayName.trim();
    final resolvedTitle = venueName != null && venueName.isNotEmpty
        ? venueName
        : 'Local do evento';
    final mainDirectionsTarget = _directionsTargetFromEvent(
      event,
      destinationName: resolvedTitle,
    );
    final destinations = _buildDestinations(event);
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16).copyWith(bottom: 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Como Chegar',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: canOpenMap ? onOpenMap : null,
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
                  _LocationMapCanvas(event: event),
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
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Ver no mapa',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelLarge
                                      ?.copyWith(
                                        color: colorScheme.onSurface,
                                        fontWeight: FontWeight.w800,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  [
                                    resolvedTitle,
                                    if (address.isNotEmpty) address,
                                  ].join(' - '),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        color: colorScheme.onSurface,
                                        fontWeight: FontWeight.w800,
                                      ),
                                ),
                              ],
                            ),
                          ),
                          if (canOpenMap)
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
          if (mainDirectionsTarget != null) ...[
            const SizedBox(height: 12),
            _DirectionsProviderButtons(
              target: mainDirectionsTarget,
              isPrimary: true,
              onOpenDirectDirections: onOpenDirectDirections,
              onOpenOtherDirections: onOpenOtherDirections,
            ),
          ],
          if (destinations.isNotEmpty) ...[
            const SizedBox(height: 18),
            Text(
              'Outros endereços relacionados',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            ...destinations.map(
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
      return DirectionsLaunchTarget(
        destinationName: title,
        address: address,
      );
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
  )? onOpenDirectDirections;
  final Future<void> Function(DirectionsLaunchTarget target)?
      onOpenOtherDirections;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final routeTarget = destination.routeTarget;
    return Material(
      color: colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: EdgeInsets.only(bottom: routeTarget == null ? 0 : 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              key: Key('eventLocationDestination_${destination.key}'),
              onTap: onTap,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: colorScheme.outlineVariant),
              ),
              leading: Icon(
                Icons.location_on_outlined,
                color: colorScheme.primary,
              ),
              title: Text(
                destination.title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              trailing: onTap == null ? null : const Icon(Icons.map_outlined),
            ),
            if (routeTarget != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: _DirectionsProviderButtons(
                  target: routeTarget,
                  isPrimary: false,
                  onOpenDirectDirections: onOpenDirectDirections,
                  onOpenOtherDirections: onOpenOtherDirections,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DirectionsProviderButtons extends StatelessWidget {
  const _DirectionsProviderButtons({
    required this.target,
    required this.isPrimary,
    required this.onOpenDirectDirections,
    required this.onOpenOtherDirections,
  });

  final DirectionsLaunchTarget target;
  final bool isPrimary;
  final Future<void> Function(
    DirectionsDirectProvider provider,
    DirectionsLaunchTarget target,
  )? onOpenDirectDirections;
  final Future<void> Function(DirectionsLaunchTarget target)?
      onOpenOtherDirections;

  @override
  Widget build(BuildContext context) {
    if (!target.hasLaunchableDestination) {
      return const SizedBox.shrink();
    }

    final height = isPrimary ? 48.0 : 38.0;
    final textStyle = Theme.of(context).textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w800,
          fontSize: isPrimary ? 14 : 12,
        );
    return Row(
      children: [
        Expanded(
          child: _DirectionProviderButton(
            key: Key(
                isPrimary ? 'eventMainWazeButton' : 'eventSecondaryWazeButton'),
            label: 'Waze',
            icon: Icons.alt_route_outlined,
            height: height,
            textStyle: textStyle,
            onPressed: onOpenDirectDirections == null
                ? null
                : () => unawaited(
                      onOpenDirectDirections!(
                        DirectionsDirectProvider.waze,
                        target,
                      ),
                    ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _DirectionProviderButton(
            key: Key(
                isPrimary ? 'eventMainUberButton' : 'eventSecondaryUberButton'),
            label: 'Uber',
            icon: Icons.local_taxi,
            height: height,
            textStyle: textStyle,
            onPressed: onOpenDirectDirections == null || !target.hasCoordinates
                ? null
                : () => unawaited(
                      onOpenDirectDirections!(
                        DirectionsDirectProvider.uber,
                        target,
                      ),
                    ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: isPrimary ? 56 : 44,
          child: _DirectionProviderButton(
            key: Key(
              isPrimary
                  ? 'eventMainOtherDirectionsButton'
                  : 'eventSecondaryOtherDirectionsButton',
            ),
            label: '',
            icon: Icons.more_horiz,
            height: height,
            textStyle: textStyle,
            onPressed: onOpenOtherDirections == null
                ? null
                : () => unawaited(onOpenOtherDirections!(target)),
          ),
        ),
      ],
    );
  }
}

class _DirectionProviderButton extends StatelessWidget {
  const _DirectionProviderButton({
    super.key,
    required this.label,
    required this.icon,
    required this.height,
    required this.textStyle,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final double height;
  final TextStyle? textStyle;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final child = label.isEmpty
        ? Icon(icon, size: 20)
        : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textStyle,
                ),
              ),
            ],
          );

    return FilledButton.tonal(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        minimumSize: Size.fromHeight(height),
        padding: EdgeInsets.symmetric(horizontal: label.isEmpty ? 8 : 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: child,
    );
  }
}

class _LocationMapCanvas extends StatelessWidget {
  const _LocationMapCanvas({required this.event});

  final EventModel event;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasCoordinates = event.coordinate != null;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primaryContainer.withValues(alpha: 0.92),
            colorScheme.secondaryContainer.withValues(alpha: 0.88),
            colorScheme.tertiaryContainer.withValues(alpha: 0.82),
          ],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            top: -24,
            left: -12,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            right: -18,
            bottom: -28,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
            ),
          ),
          CustomPaint(
            painter: _MapGridPainter(
              lineColor: Colors.white.withValues(alpha: 0.13),
            ),
          ),
          Center(
            child: Container(
              width: hasCoordinates ? 68 : 74,
              height: hasCoordinates ? 68 : 74,
              decoration: BoxDecoration(
                color: colorScheme.primary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.primary.withValues(alpha: 0.3),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Icon(
                Icons.location_on,
                color: colorScheme.onPrimary,
                size: hasCoordinates ? 34 : 36,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MapGridPainter extends CustomPainter {
  const _MapGridPainter({required this.lineColor});

  final Color lineColor;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 1;

    for (double dx = 24; dx < size.width; dx += 36) {
      canvas.drawLine(Offset(dx, 0), Offset(dx, size.height), paint);
    }
    for (double dy = 20; dy < size.height; dy += 32) {
      canvas.drawLine(Offset(0, dy), Offset(size.width, dy), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _MapGridPainter oldDelegate) {
    return oldDelegate.lineColor != lineColor;
  }
}
