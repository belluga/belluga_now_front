import 'package:belluga_now/domain/map/projections/city_poi_linked_profile.dart';
import 'package:belluga_now/presentation/shared/widgets/belluga_network_image.dart';
import 'package:belluga_now/presentation/tenant_public/map/screens/map_screen/widgets/poi_base_card.dart';
import 'package:belluga_now/presentation/tenant_public/map/screens/map_screen/widgets/shared/poi_content_resolver.dart';
import 'package:flutter/material.dart';

class EventPoiDetailCard extends PoiBaseCard {
  const EventPoiDetailCard({
    super.key,
    required super.poi,
    required super.colorScheme,
    required super.onPrimaryAction,
    required super.secondaryAction,
    required super.onRoute,
    super.onClose,
    super.heroMaxHeight,
  });

  @override
  Color resolveAccentColor() {
    if (poi.isHappeningNow) {
      return const Color(0xFFD93A56);
    }
    return super.resolveAccentColor();
  }

  @override
  List<Widget Function(BuildContext)> buildSectionsBeforeDescription() => [
        _scheduleSection,
        _linkedProfilesSection,
      ];

  @override
  List<Widget Function(BuildContext)> buildSectionsAfterDescription() => [
        tagsSection,
      ];

  Widget _scheduleSection(BuildContext context) {
    final scheduleLabel = PoiContentResolver.eventScheduleLabel(poi);
    if (scheduleLabel == null) {
      return const SizedBox.shrink();
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          poi.isHappeningNow ? Icons.bolt_rounded : Icons.schedule_rounded,
          size: 18,
          color: resolveAccentColor(),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            scheduleLabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
          ),
        ),
      ],
    );
  }

  Widget _linkedProfilesSection(BuildContext context) {
    if (poi.linkedProfiles.isEmpty) {
      return const SizedBox.shrink();
    }
    final visibleProfiles = poi.linkedProfiles.length > 1
        ? poi.linkedProfiles.take(1).toList(growable: false)
        : poi.linkedProfiles;
    final hiddenCount = poi.linkedProfiles.length - visibleProfiles.length;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ...visibleProfiles.map(
          (profile) => _LinkedProfileChip(
            profile: profile,
            colorScheme: colorScheme,
          ),
        ),
        if (hiddenCount > 0)
          _LinkedProfileOverflowChip(
            hiddenCount: hiddenCount,
            colorScheme: colorScheme,
          ),
      ],
    );
  }
}

class _LinkedProfileOverflowChip extends StatelessWidget {
  const _LinkedProfileOverflowChip({
    required this.hiddenCount,
    required this.colorScheme,
  });

  final int hiddenCount;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Text(
          'e mais $hiddenCount',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w800,
              ),
        ),
      ),
    );
  }
}

class _LinkedProfileChip extends StatelessWidget {
  const _LinkedProfileChip({
    required this.profile,
    required this.colorScheme,
  });

  final CityPoiLinkedProfile profile;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _LinkedProfileAvatar(
              imageUri: profile.avatarImageUri,
              colorScheme: colorScheme,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                profile.displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LinkedProfileAvatar extends StatelessWidget {
  const _LinkedProfileAvatar({
    required this.imageUri,
    required this.colorScheme,
  });

  final String? imageUri;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.14),
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.person_outline,
        color: colorScheme.primary,
        size: 14,
      ),
    );
    final resolvedImageUri = imageUri?.trim();
    if (resolvedImageUri == null || resolvedImageUri.isEmpty) {
      return fallback;
    }
    return ClipOval(
      child: SizedBox(
        width: 22,
        height: 22,
        child: BellugaNetworkImage(
          resolvedImageUri,
          fit: BoxFit.cover,
          errorWidget: fallback,
        ),
      ),
    );
  }
}
