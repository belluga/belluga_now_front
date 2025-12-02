import 'package:belluga_now/application/extensions/event_data_formating.dart';
import 'package:belluga_now/domain/venue_event/projections/venue_event_resume.dart';
import 'package:belluga_now/presentation/tenant/widgets/event_info_row.dart';
import 'package:belluga_now/presentation/tenant/widgets/upcoming_event_participants.dart';
import 'package:belluga_now/presentation/tenant/widgets/upcoming_event_thumbnail.dart';
import 'package:flutter/material.dart';

class UpcomingEventCard extends StatelessWidget {
  const UpcomingEventCard({
    super.key,
    required this.event,
    this.onTap,
    this.isConfirmed = false,
    this.hasPendingInvite = false,
  });

  final VenueEventResume event;
  final bool hasPendingInvite;
  final VoidCallback? onTap;
  final bool isConfirmed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheduleLabel =
        '${event.startDateTime.dayLabel} ${event.startDateTime.monthLabel} • ${event.startDateTime.timeLabel}';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            UpcomingEventThumbnail(imageUrl: event.imageUri.toString()),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  EventInfoRow(
                    icon: Icons.event_outlined,
                    label: scheduleLabel,
                  ),
                  const SizedBox(height: 6),
                  EventInfoRow(
                    icon: Icons.place_outlined,
                    label: event.location,
                  ),
                  const SizedBox(height: 6),
                  UpcomingEventParticipants(event: event),
                ],
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () {},
              icon: Icon(
                isConfirmed || hasPendingInvite
                    ? Icons.rocket_launch
                    : Icons.rocket_launch_outlined,
                color: isConfirmed
                    ? theme.colorScheme.primary
                    : (hasPendingInvite ? Colors.orange : null),
              ),
              tooltip: isConfirmed
                  ? 'Confirmado!'
                  : (hasPendingInvite
                      ? 'Convite pendente'
                      : 'Confirmar presença'),
            ),
          ],
        ),
      ),
    );
  }
}
