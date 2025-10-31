import 'package:belluga_now/presentation/tenant/widgets/date_badge.dart';
import 'package:belluga_now/presentation/tenant/widgets/event_info_row.dart';
import 'package:belluga_now/presentation/view_models/event_card_data.dart';
import 'package:flutter/material.dart';

class EventDetails extends StatelessWidget {
  const EventDetails({super.key, required this.eventCardData});

  final EventCardData eventCardData;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onPrimary = theme.colorScheme.onPrimary;

    return Container(
      key: const ValueKey('details'),
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DateBadge(
            date: eventCardData.startDateTime,
            displayTime: true,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  eventCardData.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: onPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                EventInfoRow(
                  icon: Icons.place_outlined,
                  label: eventCardData.location,
                  color: onPrimary.withOpacity(0.9),
                ),
                const SizedBox(height: 6),
                EventInfoRow(
                  icon: Icons.music_note_outlined,
                  label: eventCardData.artist,
                  color: onPrimary.withOpacity(0.9),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
