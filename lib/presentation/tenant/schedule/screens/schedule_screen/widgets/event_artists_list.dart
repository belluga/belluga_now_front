import 'package:belluga_now/domain/artist/artist_resume.dart';
import 'package:belluga_now/presentation/tenant/schedule/screens/schedule_screen/widgets/event_artist_tile.dart';
import 'package:belluga_now/presentation/tenant/widgets/event_info_row.dart';
import 'package:flutter/material.dart';

class EventArtistsList extends StatelessWidget {
  const EventArtistsList({
    super.key,
    required this.artists,
  });

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

    return Column(
      children: artists
          .map(
            (artist) => EventArtistTile(artist: artist),
          )
          .toList(),
    );
  }
}
