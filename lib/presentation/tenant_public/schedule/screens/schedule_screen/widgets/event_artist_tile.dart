import 'package:belluga_now/domain/artist/artist_resume.dart';
import 'package:flutter/material.dart';

class EventArtistTile extends StatelessWidget {
  const EventArtistTile({
    super.key,
    required this.artist,
  });

  final ArtistResume artist;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final imageUri = artist.avatarUri?.toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: artist.isHighlight
            ? theme.colorScheme.primaryContainer
            : theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: imageUri != null ? NetworkImage(imageUri) : null,
          backgroundColor: theme.colorScheme.surfaceContainerHighest,
          child: imageUri == null
              ? Icon(
                  Icons.person,
                  color: theme.colorScheme.onSurfaceVariant,
                )
              : null,
        ),
        title: Text(
          artist.displayName,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: artist.isHighlight ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        subtitle: artist.isHighlight
            ? Text(
                'Destaque confirmado',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              )
            : null,
      ),
    );
  }
}
