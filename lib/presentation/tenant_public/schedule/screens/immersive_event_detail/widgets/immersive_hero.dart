import 'package:belluga_now/domain/schedule/event_linked_account_profile.dart';
import 'package:belluga_now/domain/schedule/event_model.dart';
import 'package:belluga_now/domain/value_objects/thumb_uri_value.dart';
import 'package:belluga_now/domain/venue_event/projections/venue_event_resume.dart';
import 'package:belluga_now/presentation/shared/widgets/belluga_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ImmersiveHero extends StatelessWidget {
  const ImmersiveHero({
    required this.event,
    required this.fallbackImageUri,
    super.key,
  });

  final EventModel event;
  final Uri fallbackImageUri;

  @override
  Widget build(BuildContext context) {
    final fallbackImageValue =
        ThumbUriValue(defaultValue: fallbackImageUri, isRequired: true)
          ..parse(fallbackImageUri.toString());
    final resume =
        VenueEventResume.fromScheduleEvent(event, fallbackImageValue);
    final counterparts = _counterpartProfiles(event);

    return Stack(
      fit: StackFit.expand,
      children: [
        BellugaNetworkImage(
          resume.imageUri.toString(),
          fit: BoxFit.cover,
          errorWidget: Container(color: Colors.grey[900]),
        ),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.28),
                Colors.transparent,
                Colors.black.withValues(alpha: 0.16),
                Colors.black.withValues(alpha: 0.72),
                Colors.black.withValues(alpha: 0.9),
              ],
              stops: const [0.0, 0.26, 0.52, 0.84, 1.0],
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
                Text(
                  resume.eventTypeLabel!,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Colors.white70,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 8),
              ],
              Text(
                resume.title,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      height: 0.95,
                    ),
              ),
              if (counterparts.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: counterparts
                      .map((profile) => _CounterpartChip(profile: profile))
                      .toList(growable: false),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(
                    Icons.schedule_outlined,
                    color: Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _expandedScheduleLabel(resume),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: Colors.white,
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
                    const Icon(
                      Icons.location_on_outlined,
                      color: Colors.white,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        venueLine,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: Colors.white,
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

  String _expandedScheduleLabel(VenueEventResume resume) {
    final start = resume.startDateTime;
    final end = resume.endDateTime ?? start.add(const Duration(hours: 3));
    final startWeekday = DateFormat.E('pt_BR').format(start).toUpperCase();
    final endWeekday = DateFormat.E('pt_BR').format(end).toUpperCase();
    final startDay = start.day.toString().padLeft(2, '0');
    final endDay = end.day.toString().padLeft(2, '0');
    final startTime = DateFormat.Hm('pt_BR').format(start);
    final endTime = DateFormat.Hm('pt_BR').format(end);
    return '$startWeekday, $startDay • $startTime - $endWeekday, $endDay • $endTime';
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

class _CounterpartChip extends StatelessWidget {
  const _CounterpartChip({required this.profile});

  final EventLinkedAccountProfile profile;

  @override
  Widget build(BuildContext context) {
    final avatarUrl = profile.avatarUrl?.trim();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(999),
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
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ],
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
