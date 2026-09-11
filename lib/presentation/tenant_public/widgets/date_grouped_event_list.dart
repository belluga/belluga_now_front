import 'package:belluga_now/domain/upcoming_ocurrence/projections/upcoming_ocurrence_resume.dart';
import 'package:belluga_now/presentation/tenant_public/widgets/upcoming_ocurrence_card.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DateGroupedEventList extends StatelessWidget {
  const DateGroupedEventList({
    super.key,
    required this.events,
    required this.onEventSelected,
    this.shrinkWrap = false,
    this.physics,
    this.primary,
    this.isConfirmed,
    this.pendingInvitesCount,
    this.distanceLabel,
    this.statusIconSize,
    this.highlightNowEvents = false,
    this.highlightTodayEvents = false,
    this.defaultEventDuration = const Duration(hours: 3),
    this.sortDescending = false,
    this.keyNamespace = 'dateGroupedEventCard',
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
    this.showVenueAddress = true,
    this.scaleDateHeaderToFit = false,
    this.footer,
  });

  final List<UpcomingOcurrenceResume> events;
  final ValueChanged<UpcomingOcurrenceResume> onEventSelected;
  final bool shrinkWrap;
  final ScrollPhysics? physics;
  final bool? primary;
  final bool Function(UpcomingOcurrenceResume event)? isConfirmed;
  final int Function(UpcomingOcurrenceResume event)? pendingInvitesCount;
  final String? Function(UpcomingOcurrenceResume event)? distanceLabel;
  final double? statusIconSize;
  final bool highlightNowEvents;
  final bool highlightTodayEvents;
  final Duration defaultEventDuration;
  final bool sortDescending;
  final String keyNamespace;
  final EdgeInsetsGeometry padding;
  final bool showVenueAddress;
  final bool scaleDateHeaderToFit;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final sections = _buildSections(DateTime.now());

    return ListView.builder(
      primary: primary,
      shrinkWrap: shrinkWrap,
      physics: physics,
      padding: padding,
      itemCount: sections.length + (footer != null ? 1 : 0),
      itemBuilder: (context, index) {
        if (footer != null && index == sections.length) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: footer,
          );
        }

        final section = sections[index];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(
              theme: theme,
              colorScheme: colorScheme,
              section: section,
            ),
            ...section.events.asMap().entries.map(
              (entry) => _buildEventCard(
                event: entry.value,
                sectionIndex: index,
                eventIndex: entry.key,
              ),
            ),
          ],
        );
      },
    );
  }

  /// Sliver facade for surfaces whose owning viewport is already sliver-based.
  ///
  /// The box facade in [build] remains the default used by Event Search.
  List<Widget> buildSlivers(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final sections = _buildSections(DateTime.now());
    final slivers = <Widget>[];

    for (var sectionIndex = 0; sectionIndex < sections.length; sectionIndex++) {
      final section = sections[sectionIndex];
      final header = _buildSectionHeader(
        theme: theme,
        colorScheme: colorScheme,
        section: section,
      );
      final eventList = SliverList.builder(
        itemCount: section.events.length,
        itemBuilder: (context, eventIndex) => _buildEventCard(
          event: section.events[eventIndex],
          sectionIndex: sectionIndex,
          eventIndex: eventIndex,
        ),
      );

      if (section.isNow) {
        slivers
          ..add(
            SliverPadding(
              padding: padding,
              sliver: SliverToBoxAdapter(child: header),
            ),
          )
          ..add(SliverPadding(padding: padding, sliver: eventList));
        continue;
      }

      slivers.add(
        SliverPadding(
          padding: padding,
          sliver: SliverMainAxisGroup(
            slivers: [
              PinnedHeaderSliver(
                child: ColoredBox(color: colorScheme.surface, child: header),
              ),
              eventList,
            ],
          ),
        ),
      );
    }

    if (footer case final footer?) {
      slivers.add(
        SliverPadding(
          padding: padding,
          sliver: SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: footer,
            ),
          ),
        ),
      );
    }

    return slivers;
  }

  Widget _buildSectionHeader({
    required ThemeData theme,
    required ColorScheme colorScheme,
    required _EventSection section,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: section.isNow
          ? Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(26),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.errorContainer.withValues(alpha: 0.18),
                      blurRadius: 10,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Text(
                  section.label,
                  style:
                      theme.textTheme.labelLarge?.copyWith(
                        color: colorScheme.onErrorContainer,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ) ??
                      TextStyle(
                        color: colorScheme.onErrorContainer,
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
                        color: colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Text(
                        section.tag!,
                        style:
                            theme.textTheme.labelLarge?.copyWith(
                              color: colorScheme.onSecondaryContainer,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                            ) ??
                            TextStyle(
                              color: colorScheme.onSecondaryContainer,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                _DateSectionHeader(
                  label: section.label,
                  scaleToFit: scaleDateHeaderToFit,
                ),
              ],
            ),
    );
  }

  Widget _buildEventCard({
    required UpcomingOcurrenceResume event,
    required int sectionIndex,
    required int eventIndex,
  }) {
    final cardIdentity = _cardIdentityFor(
      event: event,
      sectionIndex: sectionIndex,
      eventIndex: eventIndex,
    );
    final cardId = event.selectedOccurrenceId?.trim().isNotEmpty == true
        ? event.selectedOccurrenceId!.trim()
        : cardIdentity;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: UpcomingOcurrenceCard.fromUpcomingOcurrenceResume(
        key: ValueKey<String>('date-grouped-event-card-$cardIdentity'),
        event: event,
        onTap: () => onEventSelected(event),
        isConfirmed: isConfirmed?.call(event) ?? false,
        pendingInvitesCount: pendingInvitesCount?.call(event) ?? 0,
        distanceLabel: distanceLabel?.call(event),
        statusIconSize: statusIconSize ?? 24,
        keyNamespace: keyNamespace,
        cardId: cardId,
        showVenueAddress: showVenueAddress,
      ),
    );
  }

  List<_EventSection> _buildSections(DateTime now) {
    final nowEvents = <UpcomingOcurrenceResume>[];
    final groupedEvents = <String, List<UpcomingOcurrenceResume>>{};

    for (final event in events) {
      if (highlightNowEvents && _isHappeningNow(event, now)) {
        nowEvents.add(event);
        continue;
      }
      final dateKey = DateFormat('yyyy-MM-dd').format(event.startDateTime);
      groupedEvents.putIfAbsent(dateKey, () => []).add(event);
    }

    final sortedDates = groupedEvents.keys.toList()
      ..sort((a, b) => sortDescending ? b.compareTo(a) : a.compareTo(b));
    nowEvents.sort(_compareEvents);

    return [
      if (highlightNowEvents && nowEvents.isNotEmpty)
        _EventSection(
          label: 'AGORA',
          events: nowEvents,
          tag: null,
          isNow: true,
          date: null,
        ),
      for (final key in sortedDates)
        _dateSection(key: key, events: groupedEvents[key]!, now: now),
    ];
  }

  _EventSection _dateSection({
    required String key,
    required List<UpcomingOcurrenceResume> events,
    required DateTime now,
  }) {
    final date = DateTime.parse(key);
    final dateEvents = List<UpcomingOcurrenceResume>.from(events)
      ..sort(_compareEvents);
    return _EventSection(
      label: DateFormat.MMMMEEEEd().format(date).toUpperCase(),
      events: dateEvents,
      tag: highlightTodayEvents ? _tagForDate(date, now) : null,
      isNow: false,
      date: date,
    );
  }

  bool _isHappeningNow(UpcomingOcurrenceResume event, DateTime now) {
    final start = event.startDateTime;
    final end = event.endDateTime ?? start.add(defaultEventDuration);
    if (end.isBefore(start)) return false;
    return !start.isAfter(now) && !now.isAfter(end);
  }

  String _cardIdentityFor({
    required UpcomingOcurrenceResume event,
    required int sectionIndex,
    required int eventIndex,
  }) {
    final occurrenceId = event.selectedOccurrenceId?.trim();
    if (occurrenceId != null && occurrenceId.isNotEmpty) {
      return 'occurrence:$occurrenceId';
    }

    final eventId = event.id.trim();
    if (eventId.isNotEmpty) {
      return 'event:$eventId:$sectionIndex:$eventIndex';
    }

    return 'index:$sectionIndex:$eventIndex';
  }

  int _compareEvents(
    UpcomingOcurrenceResume left,
    UpcomingOcurrenceResume right,
  ) {
    final startComparison = left.startDateTime.compareTo(right.startDateTime);
    if (startComparison != 0) {
      return sortDescending ? -startComparison : startComparison;
    }

    for (final selector in <String Function(UpcomingOcurrenceResume)>[
      (event) => event.selectedOccurrenceId?.trim() ?? '',
      (event) => event.id.trim(),
      (event) => event.slug.trim(),
      (event) => event.title.trim(),
    ]) {
      final comparison = selector(left).compareTo(selector(right));
      if (comparison != 0) {
        return sortDescending ? -comparison : comparison;
      }
    }

    return 0;
  }
}

class _DateSectionHeader extends StatelessWidget {
  const _DateSectionHeader({required this.label, required this.scaleToFit});

  final String label;
  final bool scaleToFit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final labelStyle =
        theme.textTheme.titleSmall?.copyWith(
          color: colorScheme.primary,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.3,
        ) ??
        TextStyle(
          color: colorScheme.primary,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.3,
        );

    if (scaleToFit) {
      return Stack(
        alignment: Alignment.center,
        children: [
          Divider(
            color: colorScheme.primary.withValues(alpha: 0.3),
            thickness: 1.5,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: ColoredBox(
              color: colorScheme.surface,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.visible,
                    softWrap: false,
                    style: labelStyle,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Divider(
            color: colorScheme.primary.withValues(alpha: 0.3),
            thickness: 1.5,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(label, style: labelStyle, textAlign: TextAlign.center),
        ),
        Expanded(
          child: Divider(
            color: colorScheme.primary.withValues(alpha: 0.3),
            thickness: 1.5,
          ),
        ),
      ],
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
  final List<UpcomingOcurrenceResume> events;
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
