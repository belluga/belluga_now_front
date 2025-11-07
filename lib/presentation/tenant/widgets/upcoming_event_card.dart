import 'package:belluga_now/application/extensions/event_data_formating.dart';
import 'package:belluga_now/presentation/tenant/widgets/event_info_row.dart';
import 'package:belluga_now/presentation/view_models/event_card_data.dart';
import 'package:flutter/material.dart';

class UpcomingEventCard extends StatelessWidget {
  const UpcomingEventCard({
    super.key,
    required this.data,
    this.onTap,
  });

  final EventCardData data;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheduleLabel =
        '${data.startDateTime.dayLabel} ${data.startDateTime.monthLabel} • ${data.startDateTime.timeLabel}';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _UpcomingEventThumbnail(imageUrl: data.imageUrl),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.title,
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
                    label: data.venue,
                  ),
                  const SizedBox(height: 6),
                  _ParticipantsSection(data: data),
                ],
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () {},
              icon: const Icon(Icons.favorite_border),
              tooltip: 'Favoritar',
            ),
          ],
        ),
      ),
    );
  }
}

class _ParticipantsSection extends StatelessWidget {
  const _ParticipantsSection({required this.data});

  final EventCardData data;

  @override
  Widget build(BuildContext context) {
    if (!data.hasParticipants) {
      return EventInfoRow(
        icon: Icons.groups_outlined,
        label: 'Curadoria em definição',
      );
    }

    final label = data.participantsLabelWithHighlight;

    return EventInfoRow(
      icon: Icons.music_note_outlined,
      label: label,
    );
  }
}

class _UpcomingEventThumbnail extends StatelessWidget {
  const _UpcomingEventThumbnail({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        width: 96,
        height: 96,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              imageUrl,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  color: colorScheme.surfaceContainerHigh,
                  child: const Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) => Container(
                color: colorScheme.surfaceContainerHigh,
                child: Icon(
                  Icons.image_not_supported_outlined,
                  color: colorScheme.onSurfaceVariant,
                  size: 32,
                ),
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withValues(alpha: 0.45),
                    Colors.transparent,
                  ],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
