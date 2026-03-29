import 'package:belluga_now/domain/schedule/event_model.dart';
import 'package:belluga_now/presentation/shared/widgets/belluga_network_image.dart';
import 'package:flutter/material.dart';

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

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _LiveNowHeader(),
          const SizedBox(height: 10),
          if (items.length == 1)
            _LiveNowCard(
              event: items.first,
              onTap: () => onTap(items.first),
            )
          else
            SizedBox(
              height: 188,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final event = items[index];
                  return SizedBox(
                    width: MediaQuery.of(context).size.width * 0.88,
                    child: _LiveNowCard(
                      event: event,
                      onTap: () => onTap(event),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
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

class _LiveNowCard extends StatelessWidget {
  const _LiveNowCard({
    required this.event,
    required this.onTap,
  });

  final EventModel event;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final imageUrl = _resolveImageUrl(event);
    final venueLabel = _resolveVenueLabel(event).toUpperCase();

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(28),
      child: Ink(
        height: 188,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (imageUrl != null && imageUrl.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: BellugaNetworkImage(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorWidget: const SizedBox.shrink(),
                ),
              ),
            ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.72),
                      Colors.black.withValues(alpha: 0.28),
                      Colors.black.withValues(alpha: 0.06),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 14,
              left: 16,
              child: Text(
                venueLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.92),
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.8,
                    ),
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 14,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title.value,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      FilledButton(
                        onPressed: onTap,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 12,
                          ),
                        ),
                        child: const Text('Ver detalhes'),
                      ),
                      const Spacer(),
                      _LiveNowArtistStack(event: event),
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

class _LiveNowArtistStack extends StatelessWidget {
  const _LiveNowArtistStack({required this.event});

  final EventModel event;

  @override
  Widget build(BuildContext context) {
    final artists = event.artists;
    if (artists.isEmpty) {
      return const SizedBox.shrink();
    }

    final visible = artists.take(3).toList(growable: false);
    final extraCount = artists.length - visible.length;
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: 92,
      height: 30,
      child: Stack(
        children: [
          for (var index = 0; index < visible.length; index++)
            Positioned(
              left: index * 18,
              child: _ArtistAvatar(
                imageUrl: visible[index].avatarUri?.toString(),
                fallbackLabel: visible[index].displayName,
              ),
            ),
          if (extraCount > 0)
            Positioned(
              left: visible.length * 18,
              child: CircleAvatar(
                radius: 15,
                backgroundColor: colorScheme.primaryContainer,
                child: Text(
                  '+$extraCount',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ArtistAvatar extends StatelessWidget {
  const _ArtistAvatar({
    required this.imageUrl,
    required this.fallbackLabel,
  });

  final String? imageUrl;
  final String fallbackLabel;

  @override
  Widget build(BuildContext context) {
    final trimmedLabel = fallbackLabel.trim();
    final colorScheme = Theme.of(context).colorScheme;
    final initial =
        trimmedLabel.isEmpty ? '?' : trimmedLabel.substring(0, 1).toUpperCase();

    return CircleAvatar(
      radius: 15,
      backgroundColor: colorScheme.surface,
      child: CircleAvatar(
        radius: 13,
        backgroundColor: colorScheme.surfaceContainerHighest,
        backgroundImage: (imageUrl != null && imageUrl!.trim().isNotEmpty)
            ? NetworkImage(imageUrl!)
            : null,
        child: (imageUrl == null || imageUrl!.trim().isEmpty)
            ? Text(
                initial,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
              )
            : null,
      ),
    );
  }
}

String? _resolveImageUrl(EventModel event) {
  final thumb = event.thumb?.thumbUri.value.toString();
  if (thumb != null && thumb.trim().isNotEmpty) {
    return thumb;
  }
  final hero = event.venue?.heroImageUrl;
  if (hero != null && hero.trim().isNotEmpty) {
    return hero;
  }
  final logo = event.venue?.logoImageUrl;
  if (logo != null && logo.trim().isNotEmpty) {
    return logo;
  }
  return null;
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
