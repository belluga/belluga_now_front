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
    this.isConfirmed,
    this.pendingInvitesCount,
    this.statusIconSize,
    this.highlightNowEvents = false,
    this.highlightTodayEvents = false,
    this.defaultEventDuration = const Duration(hours: 3),
    this.sortDescending = false,
    this.controller,
    this.footer,
  });

  final List<VenueEventResume> events;
  final ValueChanged<String> onEventSelected;
  final bool shrinkWrap;
  final ScrollPhysics? physics;
  final ScrollController? controller;
  final bool Function(VenueEventResume event)? isConfirmed;
  final int Function(VenueEventResume event)? pendingInvitesCount;
  final double? statusIconSize;
  final bool highlightNowEvents;
  final bool highlightTodayEvents;
  final Duration defaultEventDuration;
  final bool sortDescending;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final now = DateTime.now();

    // Partition events into "now" and date groups
    final nowEvents = <VenueEventResume>[];
    final Map<String, List<VenueEventResume>> groupedEvents = {};

    bool isHappeningNow(VenueEventResume event) {
      final start = event.startDateTime;
      final end = start.add(defaultEventDuration);
      return start.isBefore(now) || start.isAtSameMomentAs(now)
          ? now.isBefore(end) || now.isAtSameMomentAs(end)
          : false;
    }

    for (var event in events) {
      if (highlightNowEvents && isHappeningNow(event)) {
        nowEvents.add(event);
        continue;
      }
      final dateKey = DateFormat('yyyy-MM-dd').format(event.startDateTime);
      groupedEvents.putIfAbsent(dateKey, () => []);
      groupedEvents[dateKey]!.add(event);
    }

    // Sort dates
    final sortedDates = groupedEvents.keys.toList()
      ..sort((a, b) => sortDescending ? b.compareTo(a) : a.compareTo(b));

    // Sort "now" events consistently
    nowEvents.sort((a, b) => sortDescending
        ? b.startDateTime.compareTo(a.startDateTime)
        : a.startDateTime.compareTo(b.startDateTime));

    final sections = <_EventSection>[];
    if (highlightNowEvents && nowEvents.isNotEmpty) {
      sections.add(
        _EventSection(
          label: 'AGORA',
          events: nowEvents,
          tag: null,
          isNow: true,
          date: null,
        ),
      );
    }

    for (final key in sortedDates) {
      final date = DateTime.parse(key);
      final dateEvents = List<VenueEventResume>.from(
        groupedEvents[key] ?? const [],
      )..sort((a, b) => sortDescending
          ? b.startDateTime.compareTo(a.startDateTime)
          : a.startDateTime.compareTo(b.startDateTime));
      final tag = highlightTodayEvents ? _tagForDate(date, now) : null;
      sections.add(
        _EventSection(
          label: DateFormat.MMMMEEEEd().format(date).toUpperCase(),
          events: dateEvents,
          tag: tag,
          isNow: false,
          date: date,
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: shrinkWrap,
      physics: physics,
      controller: controller,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: sections.length + (footer != null ? 1 : 0),
      itemBuilder: (context, index) {
        if (footer != null && index == sections.length) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: footer,
          );
        }

        final section = sections[index];
        final dateEvents = section.events;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date / tag divider
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: section.isNow
                  ? Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.primary,
                          borderRadius: BorderRadius.circular(26),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  colorScheme.primary.withValues(alpha: 0.18),
                              blurRadius: 10,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Text(
                          section.label,
                          style: theme.textTheme.labelLarge?.copyWith(
                                color: colorScheme.onPrimary,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.2,
                              ) ??
                              TextStyle(
                                color: colorScheme.onPrimary,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.2,
                              ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  : Column(
                      children: [
                        if (section.tag != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: Text(
                                section.tag!,
                                style: theme.textTheme.labelLarge?.copyWith(
                                      color: colorScheme.onPrimaryContainer,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1.2,
                                    ) ??
                                    TextStyle(
                                      color: colorScheme.onPrimaryContainer,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1.2,
                                    ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Divider(
                                color:
                                    colorScheme.primary.withValues(alpha: 0.3),
                                thickness: 1.5,
                              ),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              child: Text(
                                section.label,
                                style: theme.textTheme.titleSmall?.copyWith(
                                      color: colorScheme.primary,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1.3,
                                    ) ??
                                    TextStyle(
                                      color: colorScheme.primary,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1.3,
                                    ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            Expanded(
                              child: Divider(
                                color:
                                    colorScheme.primary.withValues(alpha: 0.3),
                                thickness: 1.5,
                              ),
                            ),
                          ],
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
                    isConfirmed: isConfirmed?.call(event) ?? false,
                    pendingInvitesCount: pendingInvitesCount?.call(event) ?? 0,
                    statusIconSize: statusIconSize ?? 24,
                  ),
                )),
          ],
        );
      },
    );
  }
}

class _EventSection {
  _EventSection({
    required this.label,
    required this.events,
    required this.tag,
    required this.isNow,
    required this.date,
  });

  final String label;
  final List<VenueEventResume> events;
  final String? tag;
  final bool isNow;
  final DateTime? date;
}

String? _tagForDate(DateTime date, DateTime today) {
  final dateOnly = DateTime(date.year, date.month, date.day);
  final todayOnly = DateTime(today.year, today.month, today.day);
  if (dateOnly == todayOnly) {
    return 'HOJE!';
  }
  final yesterday = todayOnly.subtract(const Duration(days: 1));
  if (dateOnly == yesterday) {
    return 'ONTEM';
  }
  final tomorrow = todayOnly.add(const Duration(days: 1));
  if (dateOnly == tomorrow) {
    return 'AMANHÃ';
  }
  return null;
}
