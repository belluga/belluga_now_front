import 'package:belluga_now/domain/schedule/event_model.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';

class EventInfoCard extends StatelessWidget {
  const EventInfoCard({
    super.key,
    required this.event,
    required this.onDismiss,
  });

  final EventModel event;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final date = event.dateTimeStart.value;
    final artists = event.artists.map((e) => e.name.value).join(', ');

    final formattedDate = date != null
        ? DateFormat('dd MMM, HH:mm').format(date)
        : 'Horário a confirmar';

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 8,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.title.value,
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        formattedDate,
                        style: textTheme.labelMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
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
            const SizedBox(height: 12),
            if (artists.isNotEmpty)
              Row(
                children: [
                  const Icon(Icons.music_note_outlined, size: 18),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      artists,
                      style: textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            if (artists.isNotEmpty) const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.place_outlined, size: 18),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    event.location.value,
                    style: textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
