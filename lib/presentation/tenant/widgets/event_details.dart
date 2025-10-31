import 'package:belluga_now/presentation/tenant/widgets/date_badge.dart';
import 'package:belluga_now/presentation/tenant/widgets/event_info_row.dart';
import 'package:flutter/material.dart';
import 'package:belluga_now/presentation/view_models/event_card_data.dart';

class EventDetails extends StatelessWidget {

  final EventCardData eventCardData;

  const EventDetails({super.key, required this.eventCardData,});

  @override
  Widget build(BuildContext context) {
    return Padding(
      key: const ValueKey('details'),
      padding: const EdgeInsets.fromLTRB(4, 12, 4, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DateBadge(
            date: eventCardData.startDateTime,
            displayTime: true,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 16,
                  child: Text(
                    eventCardData.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                EventInfoRow(
                  icon: Icons.place_outlined,
                  label: eventCardData.location,
                ),
                const SizedBox(height: 6),
                EventInfoRow(
                  icon: Icons.music_note_outlined,
                  label: eventCardData.artist,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
