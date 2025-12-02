import 'package:belluga_now/domain/schedule/event_model.dart';
import 'package:belluga_now/presentation/tenant/map/screens/city_map_screen/widgets/shared/event_actions_row.dart';
import 'package:belluga_now/presentation/tenant/map/screens/city_map_screen/widgets/shared/event_avatar.dart';
import 'package:belluga_now/presentation/tenant/map/screens/city_map_screen/widgets/shared/event_badge_chip.dart';
import 'package:belluga_now/presentation/tenant/map/screens/city_map_screen/widgets/shared/event_temporal_state.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class EventInfoCard extends StatelessWidget {
  const EventInfoCard({
    super.key,
    required this.event,
    required this.onDismiss,
    required this.onDetails,
    required this.onShare,
    this.onRoute,
  });

  final EventModel event;
  final VoidCallback onDismiss;
  final VoidCallback onDetails;
  final VoidCallback onShare;
  final VoidCallback? onRoute;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final state = resolveEventTemporalState(event, reference: now);
    final isPast = state == CityEventTemporalState.past;
    final date = event.dateTimeStart.value;
    final artists =
        event.artists.map((artist) => artist.displayName).join(', ');
    final primaryArtist = event.artists.isNotEmpty ? event.artists.first : null;
    final avatarUri = primaryArtist?.avatarUri?.toString();
    final fallbackUri = event.thumb?.thumbUri.value.toString();
    final hasAvatar = avatarUri?.isNotEmpty ?? false;
    final imageUrl = hasAvatar
        ? avatarUri
        : ((fallbackUri?.isNotEmpty ?? false) ? fallbackUri : null);

    final formattedDate = date != null
        ? DateFormat('dd MMM, HH:mm').format(date)
        : 'Horário a confirmar';
    final timeLabel = date != null ? DateFormat('HH:mm').format(date) : '--:--';
    final badgeText = switch (state) {
      CityEventTemporalState.now => 'AGORA',
      CityEventTemporalState.past => 'Encerrado',
      CityEventTemporalState.upcoming => timeLabel,
    };
    final badgeColor = switch (state) {
      CityEventTemporalState.now => const Color(0xFFE53935),
      CityEventTemporalState.past => Colors.grey.shade500,
      CityEventTemporalState.upcoming => event.type.color.value,
    };
    final mutedTextColor =
        isPast ? scheme.onSurfaceVariant.withValues(alpha: 0.65) : null;

    return Card(
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 8,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.bottomCenter,
                    children: [
                      EventAvatar(
                        imageUrl: imageUrl,
                        fallbackColor: event.type.color.value,
                        isPast: isPast,
                      ),
                      Positioned(
                        bottom: -6,
                        child: EventBadgeChip(
                          label: badgeText,
                          color: badgeColor,
                          dimmed: isPast,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.title.value,
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color:
                                mutedTextColor ?? textTheme.titleMedium?.color,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          formattedDate,
                          style: textTheme.labelMedium?.copyWith(
                            color: mutedTextColor ?? scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Fechar',
                    onPressed: onDismiss,
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (artists.isNotEmpty)
                Row(
                  children: [
                    Icon(
                      Icons.music_note_outlined,
                      size: 18,
                      color: mutedTextColor ?? scheme.onSurface,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        artists,
                        style: textTheme.bodyMedium?.copyWith(
                          color: mutedTextColor ?? textTheme.bodyMedium?.color,
                        ),
                      ),
                    ),
                  ],
                ),
              if (artists.isNotEmpty) const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.place_outlined,
                    size: 18,
                    color: mutedTextColor ?? scheme.onSurface,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      event.location.value,
                      style: textTheme.bodySmall?.copyWith(
                        color: mutedTextColor ?? textTheme.bodySmall?.color,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              EventActionsRow(
                onDetails: onDetails,
                onShare: onShare,
                onRoute: onRoute,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

