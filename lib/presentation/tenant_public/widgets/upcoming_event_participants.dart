import 'package:belluga_now/domain/venue_event/projections/venue_event_resume.dart';
import 'package:flutter/material.dart';

class UpcomingEventParticipants extends StatelessWidget {
  const UpcomingEventParticipants({super.key, required this.event});

  final VenueEventResume event;

  @override
  Widget build(BuildContext context) {
    if (!event.hasArtists) {
      return const SizedBox.shrink();
    }

    final textTheme = Theme.of(context).textTheme;
    return Row(
      children: [
        Icon(
          Icons.music_note_outlined,
          size: 18,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            event.artistNamesLabel,
            style: textTheme.bodySmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
