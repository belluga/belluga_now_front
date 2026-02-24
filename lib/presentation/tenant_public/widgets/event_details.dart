import 'package:belluga_now/domain/venue_event/projections/venue_event_resume.dart';
import 'package:belluga_now/presentation/tenant_public/widgets/date_badge.dart';
import 'package:belluga_now/presentation/tenant_public/widgets/event_info_row.dart';
import 'package:flutter/material.dart';

class EventDetails extends StatelessWidget {
  const EventDetails({
    super.key,
    required this.event,
    this.textColor,
  });

  final VenueEventResume event;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final baseColor = textColor ??
        DefaultTextStyle.of(context).style.color ??
        theme.colorScheme.onPrimary;

    return Container(
      key: const ValueKey('details'),
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DateBadge(
            date: event.startDateTime,
            displayTime: true,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  event.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: baseColor,
                  ),
                ),
                const SizedBox(height: 10),
                EventInfoRow(
                  icon: Icons.place_outlined,
                  label: event.location,
                  color: baseColor.withValues(alpha: 0.9),
                ),
                const SizedBox(height: 6),
                if (event.hasArtists)
                  EventInfoRow(
                    icon: Icons.music_note_outlined,
                    label: event.artistNamesLabel,
                    color: baseColor.withValues(alpha: 0.9),
                  )
                else
                  EventInfoRow(
                    icon: Icons.groups_outlined,
                    label: 'Curadoria em definição',
                    color: baseColor.withValues(alpha: 0.9),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
