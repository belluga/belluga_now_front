import 'package:belluga_now/domain/artist/artist_resume.dart';
import 'package:belluga_now/presentation/tenant/widgets/event_info_row.dart';
import 'package:flutter/material.dart';

class EventParticipants extends StatelessWidget {
  const EventParticipants({super.key, required this.artists});

  final List<ArtistResume> artists;

  @override
  Widget build(BuildContext context) {
    if (artists.isEmpty) {
      return EventInfoRow(
        icon: Icons.groups_outlined,
        label: 'Curadoria em definição',
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      );
    }

    final label = artists
        .map(
          (artist) => artist.isHighlight
              ? '${artist.displayName} ★'
              : artist.displayName,
        )
        .join(', ');

    return EventInfoRow(
      icon: Icons.music_note_outlined,
      label: label,
    );
  }
}
