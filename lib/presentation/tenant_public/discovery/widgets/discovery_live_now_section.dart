import 'package:belluga_now/domain/artist/artist_resume.dart';
import 'package:belluga_now/domain/schedule/event_model.dart';
import 'package:belluga_now/presentation/shared/widgets/belluga_network_image.dart';
import 'package:flutter/material.dart';

class _LiveArtistItem {
  final ArtistResume artist;
  final EventModel event;

  _LiveArtistItem(this.artist, this.event);
}

class DiscoveryLiveNowSection extends StatelessWidget {
  const DiscoveryLiveNowSection({
    super.key,
    required this.items,
    required this.onTap,
  });

  final List<EventModel> items;
  final ValueChanged<EventModel> onTap;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    final uniqueArtists = <String, _LiveArtistItem>{};
    for (final event in items) {
      for (final artist in event.artists) {
        if (!uniqueArtists.containsKey(artist.id)) {
          uniqueArtists[artist.id] = _LiveArtistItem(artist, event);
        }
      }
    }

    final liveArtists = uniqueArtists.values.toList();
    if (liveArtists.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: _LiveNowHeader(),
        ),
        SizedBox(
          height: 196,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: liveArtists.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final item = liveArtists[index];
              return SizedBox(
                width: MediaQuery.of(context).size.width * 0.42,
                child: _LiveArtistCard(
                  item: item,
                  onTap: () => onTap(item.event),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}

class _LiveNowHeader extends StatelessWidget {
  const _LiveNowHeader();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: Text(
            'Tocando agora',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              children: [
                Icon(
                  Icons.circle,
                  size: 8,
                  color: colorScheme.error,
                ),
                const SizedBox(width: 6),
                Text(
                  'AO VIVO',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _LiveArtistCard extends StatelessWidget {
  const _LiveArtistCard({
    required this.item,
    required this.onTap,
  });

  final _LiveArtistItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final imageUrl = item.artist.avatarUri?.toString();
    final venueLabel = _resolveVenueLabel(item.event).toUpperCase();

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Ink(
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (imageUrl != null && imageUrl.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BellugaNetworkImage(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorWidget: const SizedBox.shrink(),
                ),
              ),
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.82),
                      Colors.black.withValues(alpha: 0.28),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 14,
              right: 14,
              bottom: 14,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item.artist.displayName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          height: 1.15,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.pin_drop,
                        size: 12,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          venueLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: Colors.white.withValues(alpha: 0.95),
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _resolveVenueLabel(EventModel event) {
  final venueName = event.venue?.displayName.trim();
  if (venueName != null && venueName.isNotEmpty) {
    return venueName;
  }
  return event.type.name.value.trim().isEmpty
      ? 'Evento'
      : event.type.name.value;
}
