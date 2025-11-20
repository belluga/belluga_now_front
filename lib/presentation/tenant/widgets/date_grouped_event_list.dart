import 'package:belluga_now/domain/venue_event/projections/venue_event_resume.dart';
import 'package:belluga_now/presentation/tenant/widgets/upcoming_event_card.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DateGroupedEventList extends StatelessWidget {
  const DateGroupedEventList({
    super.key,
    required this.events,
    required this.onEventSelected,
    this.shrinkWrap = false,
    this.physics,
  });

  final List<VenueEventResume> events;
  final ValueChanged<String> onEventSelected;
  final bool shrinkWrap;
  final ScrollPhysics? physics;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Group events by date
    final Map<String, List<VenueEventResume>> groupedEvents = {};
    for (var event in events) {
      final dateKey = DateFormat('yyyy-MM-dd').format(event.startDateTime);
      groupedEvents.putIfAbsent(dateKey, () => []);
      groupedEvents[dateKey]!.add(event);
    }

    // Sort dates
    final sortedDates = groupedEvents.keys.toList()
      ..sort((a, b) => a.compareTo(b));

    return ListView.builder(
      shrinkWrap: shrinkWrap,
      physics: physics,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: sortedDates.length,
      itemBuilder: (context, index) {
        final dateKey = sortedDates[index];
        final dateEvents = groupedEvents[dateKey]!;
        final date = DateTime.parse(dateKey);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date divider
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Divider(color: colorScheme.outlineVariant),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      DateFormat.MMMMEEEEd().format(date).toUpperCase(),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Divider(color: colorScheme.outlineVariant),
                  ),
                ],
              ),
            ),
            // Events for this date
            ...dateEvents.map((event) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: UpcomingEventCard(
                    event: event,
                    onTap: () => onEventSelected(event.slug),
                  ),
                )),
          ],
        );
      },
    );
  }
}
