export 'package:belluga_now/presentation/tenant_public/widgets/upcoming_event_card_models.dart';

import 'package:belluga_now/application/extensions/event_data_formating.dart';
import 'package:belluga_now/domain/venue_event/projections/venue_event_resume.dart';
import 'package:belluga_now/presentation/shared/widgets/belluga_network_image.dart';
import 'package:belluga_now/presentation/tenant_public/widgets/invite_status_icon.dart';
import 'package:belluga_now/presentation/tenant_public/widgets/upcoming_event_card_models.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class UpcomingEventCard extends StatelessWidget {
  const UpcomingEventCard({
    super.key,
    required this.data,
    this.onTap,
    this.isConfirmed = false,
    this.pendingInvitesCount = 0,
    this.statusIconSize = 24,
    this.keyNamespace,
    this.cardId,
  });

  factory UpcomingEventCard.fromVenueEventResume({
    Key? key,
    required VenueEventResume event,
    VoidCallback? onTap,
    bool isConfirmed = false,
    int pendingInvitesCount = 0,
    double statusIconSize = 24,
    String? distanceLabel,
    String? keyNamespace,
    String? cardId,
  }) {
    final venueName = (event.venueTitle?.trim().isNotEmpty ?? false)
        ? event.venueTitle!.trim()
        : event.location.trim();
    final locationText = event.location.trim();
    final venueAddress =
        venueName == locationText || locationText.isEmpty ? null : locationText;

    return UpcomingEventCard(
      key: key,
      data: UpcomingEventCardData(
        imageUri: event.imageUri,
        headline: event.title,
        metaLabel: _dateLabelFor(event),
        counterparts: event.counterpartProfiles
            .map(
              (counterpart) => (
                label: counterpart.displayName,
                thumbUrl: counterpart.avatarUrl ?? counterpart.coverUrl,
                fallbackIcon: Icons.music_note,
              ),
            )
            .toList(growable: false),
        venueName: venueName.isEmpty ? null : venueName,
        venueDistanceLabel: distanceLabel,
        venueAddress: venueAddress,
      ),
      onTap: onTap,
      isConfirmed: isConfirmed,
      pendingInvitesCount: pendingInvitesCount,
      statusIconSize: statusIconSize,
      keyNamespace: keyNamespace,
      cardId: cardId ?? event.id,
    );
  }

  final UpcomingEventCardData data;
  final VoidCallback? onTap;
  final bool isConfirmed;
  final int pendingInvitesCount;
  final double statusIconSize;
  final String? keyNamespace;
  final String? cardId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final cardRadius = BorderRadius.circular(26);
    final surface = colorScheme.surfaceContainerLow;
    final confirmedTint = colorScheme.primary.withValues(alpha: 0.08);
    final pendingTint = colorScheme.secondary.withValues(alpha: 0.08);
    final cardColor = isConfirmed
        ? Color.alphaBlend(confirmedTint, surface)
        : (pendingInvitesCount > 0
            ? Color.alphaBlend(pendingTint, surface)
            : surface);
    final statusWidget = _buildStatusWidget(theme, cardColor);

    return Material(
      color: cardColor,
      borderRadius: cardRadius,
      child: InkWell(
        borderRadius: cardRadius,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: SizedBox(
                  width: 84,
                  height: 112,
                  child: _UpcomingEventImage(imageUri: data.imageUri),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                data.metaLabel,
                                key: _scopedKey('Meta'),
                                style: theme.textTheme.labelLarge?.copyWith(
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                data.headline,
                                key: _scopedKey('Headline'),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  height: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (statusWidget != null) ...[
                          const SizedBox(width: 10),
                          SizedBox(
                            width: statusIconSize,
                            child: Align(
                              alignment: Alignment.topRight,
                              child: statusWidget,
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (data.counterparts.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _buildCounterpartWrap(),
                    ],
                    if (_buildVenueLine(context) case final venueLine?) ...[
                      const SizedBox(height: 8),
                      venueLine,
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCounterpartWrap() {
    final visibleCounterparts = data.counterparts.length > 1
        ? data.counterparts.take(1).toList(growable: false)
        : data.counterparts;
    final hiddenCount = data.counterparts.length - visibleCounterparts.length;
    return Wrap(
      key: _scopedKey('Counterparts'),
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 6,
      runSpacing: 6,
      children: [
        ...visibleCounterparts.asMap().entries.map(
              (entry) => _UpcomingEventCounterpartChip(
                key: _scopedKey('Counterpart${entry.key}'),
                counterpart: entry.value,
              ),
            ),
        if (hiddenCount > 0)
          _UpcomingEventMoreCounterpartChip(
            key: _scopedKey('CounterpartMore'),
            hiddenCount: hiddenCount,
          ),
      ],
    );
  }

  Widget? _buildVenueLine(BuildContext context) {
    final venueName = data.venueName?.trim();
    if (venueName == null || venueName.isEmpty) {
      return null;
    }

    final buffer = StringBuffer(venueName);
    final distance = data.venueDistanceLabel?.trim();
    final address = data.venueAddress?.trim();
    if (distance != null && distance.isNotEmpty) {
      buffer.write(' ($distance)');
    }
    if (address != null && address.isNotEmpty) {
      buffer.write(' - $address');
    }

    return Row(
      key: _scopedKey('Venue'),
      children: [
        Icon(
          Icons.place_outlined,
          size: 16,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            buffer.toString(),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
      ],
    );
  }

  Widget? _buildStatusWidget(ThemeData theme, Color cardColor) {
    if (!isConfirmed && pendingInvitesCount == 0) {
      return null;
    }
    return InviteStatusIcon(
      isConfirmed: isConfirmed,
      pendingInvitesCount: pendingInvitesCount,
      size: statusIconSize,
      backgroundColor: (isConfirmed
              ? theme.colorScheme.primary
              : theme.colorScheme.secondary)
          .withValues(alpha: 0.18),
    );
  }

  Key? _scopedKey(String suffix) {
    final namespace = keyNamespace;
    final id = cardId;
    if (namespace == null || id == null) {
      return null;
    }
    return Key('$namespace${suffix}_$id');
  }

  static String _dateLabelFor(VenueEventResume event) {
    final weekday = DateFormat.E().format(event.startDateTime);
    final day = event.startDateTime.day.toString().padLeft(2, '0');
    final explicitEnd = event.endDateTime;
    if (explicitEnd == null) {
      return '$weekday, $day • ${event.startDateTime.timeLabel}'.toUpperCase();
    }

    final sameDay = event.startDateTime.year == explicitEnd.year &&
        event.startDateTime.month == explicitEnd.month &&
        event.startDateTime.day == explicitEnd.day;
    if (sameDay) {
      return '${weekday.toUpperCase()}, $day • ${event.startDateTime.timeLabel} às ${explicitEnd.timeLabel}';
    }

    final endWeekday = DateFormat.E().format(explicitEnd);
    final endDay = explicitEnd.day.toString().padLeft(2, '0');
    return '${weekday.toUpperCase()}, $day • ${event.startDateTime.timeLabel} às '
        '${endWeekday.toUpperCase()}, $endDay • ${explicitEnd.timeLabel}';
  }
}

class _UpcomingEventMoreCounterpartChip extends StatelessWidget {
  const _UpcomingEventMoreCounterpartChip({
    super.key,
    required this.hiddenCount,
  });

  final int hiddenCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        'e mais $hiddenCount',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w800,
            ),
      ),
    );
  }
}

class _UpcomingEventCounterpartChip extends StatelessWidget {
  const _UpcomingEventCounterpartChip({
    super.key,
    required this.counterpart,
  });

  final UpcomingEventCounterpartData counterpart;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _UpcomingEventCounterpartVisual(counterpart: counterpart),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              counterpart.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UpcomingEventCounterpartVisual extends StatelessWidget {
  const _UpcomingEventCounterpartVisual({
    required this.counterpart,
  });

  final UpcomingEventCounterpartData counterpart;

  @override
  Widget build(BuildContext context) {
    final fallback = Icon(
      counterpart.fallbackIcon,
      size: 16,
      color: Theme.of(context).colorScheme.primary,
    );
    final thumbUrl = counterpart.thumbUrl;
    if (thumbUrl == null || thumbUrl.trim().isEmpty) {
      return fallback;
    }

    return ClipOval(
      child: BellugaNetworkImage(
        thumbUrl,
        width: 18,
        height: 18,
        fit: BoxFit.cover,
        errorWidget: fallback,
      ),
    );
  }
}

class _UpcomingEventImage extends StatelessWidget {
  const _UpcomingEventImage({
    required this.imageUri,
  });

  final Uri? imageUri;

  @override
  Widget build(BuildContext context) {
    final uri = imageUri;
    final imageUrl = uri?.toString() ?? '';
    if (imageUrl.isEmpty || uri?.scheme == 'asset') {
      return Container(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        alignment: Alignment.center,
        child: Icon(
          Icons.event_outlined,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      );
    }

    return BellugaNetworkImage(
      imageUrl,
      fit: BoxFit.cover,
      errorWidget: Container(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        alignment: Alignment.center,
        child: Icon(
          Icons.image_not_supported_outlined,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          size: 32,
        ),
      ),
    );
  }
}
