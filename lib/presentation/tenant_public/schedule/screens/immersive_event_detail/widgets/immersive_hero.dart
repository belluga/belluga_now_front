import 'package:belluga_now/domain/schedule/event_linked_account_profile.dart';
import 'package:belluga_now/domain/schedule/event_model.dart';
import 'package:belluga_now/domain/value_objects/thumb_uri_value.dart';
import 'package:belluga_now/domain/venue_event/projections/venue_event_resume.dart';
import 'package:belluga_now/presentation/shared/icons/map_marker_visual_resolver.dart';
import 'package:belluga_now/presentation/shared/widgets/belluga_network_image.dart';
import 'package:flutter/material.dart';

class ImmersiveHero extends StatelessWidget {
  const ImmersiveHero({
    required this.event,
    required this.fallbackImageUri,
    this.onCounterpartTap,
    super.key,
  });

  final EventModel event;
  final Uri fallbackImageUri;
  final ValueChanged<EventLinkedAccountProfile>? onCounterpartTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final fallbackImageValue =
        ThumbUriValue(defaultValue: fallbackImageUri, isRequired: true)
          ..parse(fallbackImageUri.toString());
    final resume =
        VenueEventResume.fromScheduleEvent(event, fallbackImageValue);
    final counterparts = _counterpartProfiles(event);
    final taxonomyTags = event.taxonomyTags;

    return Stack(
      fit: StackFit.expand,
      children: [
        BellugaNetworkImage(
          resume.imageUri.toString(),
          fit: BoxFit.cover,
          errorWidget: Container(color: Colors.grey[900]),
        ),
        Container(
          key: const Key('eventHeroFadeGradient'),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.28),
                Colors.transparent,
                colorScheme.surface.withValues(alpha: 0.08),
                colorScheme.surface.withValues(alpha: 0.42),
                colorScheme.surface.withValues(alpha: 0.78),
                colorScheme.surface,
              ],
              stops: const [0.0, 0.34, 0.54, 0.72, 0.88, 1.0],
            ),
          ),
        ),
        Positioned(
          left: 16,
          right: 16,
          bottom: 18,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if ((resume.eventTypeLabel ?? '').trim().isNotEmpty) ...[
                _EventCategoryChip(
                  label: resume.eventTypeLabel!,
                  iconData: MapMarkerVisualResolver.resolveIcon(
                    event.type.icon.value,
                  ),
                  iconColor: event.type.color.value,
                ),
                const SizedBox(height: 8),
              ],
              if (taxonomyTags.isNotEmpty) ...[
                _TaxonomyTagStrip(
                  tags: taxonomyTags.map((tag) => tag.value),
                  excludedLabel: resume.eventTypeLabel,
                ),
                const SizedBox(height: 10),
              ],
              Semantics(
                label: resume.title,
                header: true,
                child: Text(
                  resume.title,
                  key: const Key('eventHeroTitle'),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w900,
                    height: 0.95,
                    shadows: [
                      Shadow(
                        color: colorScheme.surface.withValues(alpha: 0.94),
                        offset: Offset.zero,
                        blurRadius: 12,
                      ),
                      Shadow(
                        color: colorScheme.surface.withValues(alpha: 0.6),
                        offset: const Offset(0, 1),
                        blurRadius: 24,
                      ),
                    ],
                  ),
                ),
              ),
              if (counterparts.isNotEmpty) ...[
                const SizedBox(height: 10),
                _CounterpartStrip(
                  profiles: counterparts,
                  onCounterpartTap: onCounterpartTap,
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.schedule_outlined,
                    color: colorScheme.onSurfaceVariant,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      event.detailScheduleLabel,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ),
                ],
              ),
              if (_venueLine(resume) case final venueLine?) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      color: colorScheme.onSurfaceVariant,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        venueLine,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: colorScheme.onSurface,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  List<EventLinkedAccountProfile> _counterpartProfiles(EventModel event) {
    final venueId = event.venue?.id;
    final seen = <String>{};
    final linked = <EventLinkedAccountProfile>[];
    for (final profile in event.linkedAccountProfiles) {
      if (profile.id == venueId) {
        continue;
      }
      if (!seen.add(profile.id)) {
        continue;
      }
      linked.add(profile);
    }
    return linked;
  }

  String? _venueLine(VenueEventResume resume) {
    final venueTitle = resume.venueTitle?.trim();
    final address = resume.location.trim();
    if ((venueTitle == null || venueTitle.isEmpty) && address.isEmpty) {
      return null;
    }
    if (venueTitle == null || venueTitle.isEmpty) {
      return address;
    }
    if (address.isEmpty || address == venueTitle) {
      return venueTitle;
    }
    return '$venueTitle - $address';
  }
}

class _EventCategoryChip extends StatelessWidget {
  const _EventCategoryChip({
    required this.label,
    required this.iconData,
    required this.iconColor,
  });

  final String label;
  final IconData iconData;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final maxChipWidth = (MediaQuery.sizeOf(context).width - 32)
        .clamp(0.0, double.infinity)
        .toDouble();
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxChipWidth),
      child: Container(
        key: const Key('eventHeroCategoryChip'),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: colorScheme.surface.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.32),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              iconData,
              key: const Key('eventHeroCategoryChipIcon'),
              size: 16,
              color: iconColor,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TaxonomyTagStrip extends StatelessWidget {
  _TaxonomyTagStrip({
    required Iterable<String> tags,
    String? excludedLabel,
  }) : tags = tags
            .map(_clean)
            .where((tag) => tag.isNotEmpty)
            .where(
              (tag) => _normalize(tag) != _normalize(excludedLabel ?? ''),
            )
            .toSet()
            .toList(growable: false);

  final List<String> tags;

  static String _clean(String value) => value.trim();
  static String _normalize(String value) =>
      value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

  @override
  Widget build(BuildContext context) {
    if (tags.isEmpty) {
      return const SizedBox.shrink();
    }

    if (tags.length == 1) {
      return Align(
        alignment: Alignment.centerLeft,
        child: _TaxonomyTagChip(
          key: const Key('eventHeroTaxonomyTagStrip'),
          label: tags.first,
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxVisibleTags = constraints.maxWidth >= 420 ? 3 : 2;
        final visibleTags = tags.take(maxVisibleTags).toList(growable: false);
        final hiddenCount = tags.length - visibleTags.length;

        return Row(
          key: const Key('eventHeroTaxonomyTagStrip'),
          children: [
            for (var index = 0; index < visibleTags.length; index++) ...[
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: index == visibleTags.length - 1 && hiddenCount == 0
                        ? 0
                        : 8,
                  ),
                  child: _TaxonomyTagChip(label: visibleTags[index]),
                ),
              ),
            ],
            if (hiddenCount > 0)
              _TaxonomyOverflowChip(hiddenCount: hiddenCount),
          ],
        );
      },
    );
  }
}

class _TaxonomyTagChip extends StatelessWidget {
  const _TaxonomyTagChip({
    required this.label,
    super.key,
  });

  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      key: Key('eventHeroTaxonomyTagChip_$label'),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w800,
            ),
      ),
    );
  }
}

class _TaxonomyOverflowChip extends StatelessWidget {
  const _TaxonomyOverflowChip({required this.hiddenCount});

  final int hiddenCount;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      key: const Key('eventHeroTaxonomyOverflowChip'),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
      child: Text(
        '+$hiddenCount',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w800,
            ),
      ),
    );
  }
}

class _CounterpartStrip extends StatelessWidget {
  const _CounterpartStrip({
    required this.profiles,
    required this.onCounterpartTap,
  });

  static const int _compactThreshold = 1;

  final List<EventLinkedAccountProfile> profiles;
  final ValueChanged<EventLinkedAccountProfile>? onCounterpartTap;

  @override
  Widget build(BuildContext context) {
    final compact = profiles.length > _compactThreshold;
    final visibleProfiles = compact
        ? profiles.take(1).toList(growable: false)
        : profiles.toList(growable: false);
    final hiddenCount = profiles.length - visibleProfiles.length;

    return Wrap(
      key: const Key('eventHeroCounterpartStrip'),
      spacing: 8,
      runSpacing: 8,
      children: [
        ...visibleProfiles.map(
          (profile) => _CounterpartChip(
            profile: profile,
            onTap: onCounterpartTap == null
                ? null
                : () => onCounterpartTap!(profile),
          ),
        ),
        if (compact)
          _MoreCounterpartChip(
            hiddenCount: hiddenCount,
            onTap: onCounterpartTap == null
                ? null
                : () => onCounterpartTap!(profiles.first),
          ),
      ],
    );
  }
}

class _CounterpartChip extends StatelessWidget {
  const _CounterpartChip({
    required this.profile,
    required this.onTap,
  });

  final EventLinkedAccountProfile profile;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final avatarUrl = profile.avatarUrl?.trim();
    final maxChipWidth = (MediaQuery.sizeOf(context).width - 32)
        .clamp(0.0, double.infinity)
        .toDouble();
    final chip = Container(
      key: Key('eventHeroCounterpartChip_${profile.id}'),
      constraints: BoxConstraints(maxWidth: maxChipWidth),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _CounterpartAvatar(avatarUrl: avatarUrl),
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

    if (onTap == null) {
      return chip;
    }

    return Semantics(
      button: true,
      label: profile.displayName,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: chip,
      ),
    );
  }
}

class _MoreCounterpartChip extends StatelessWidget {
  const _MoreCounterpartChip({
    required this.hiddenCount,
    required this.onTap,
  });

  final int hiddenCount;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final chip = Container(
      key: const Key('eventHeroMoreProfilesChip'),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Text(
        'e mais $hiddenCount',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
      ),
    );

    if (onTap == null) {
      return chip;
    }

    return Semantics(
      button: true,
      label: 'e mais $hiddenCount',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: chip,
      ),
    );
  }
}

class _CounterpartAvatar extends StatelessWidget {
  const _CounterpartAvatar({required this.avatarUrl});

  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    final resolvedAvatarUrl = avatarUrl?.trim();
    final fallback = Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.person_outline,
        color: Colors.white,
        size: 14,
      ),
    );

    if (resolvedAvatarUrl == null || resolvedAvatarUrl.isEmpty) {
      return fallback;
    }

    return ClipOval(
      child: SizedBox(
        width: 22,
        height: 22,
        child: BellugaNetworkImage(
          resolvedAvatarUrl,
          fit: BoxFit.cover,
          errorWidget: fallback,
        ),
      ),
    );
  }
}
