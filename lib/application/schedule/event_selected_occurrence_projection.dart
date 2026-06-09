import 'package:belluga_now/domain/schedule/event_model.dart';
import 'package:belluga_now/domain/schedule/event_occurrence_option.dart';
import 'package:belluga_now/domain/schedule/event_programming_item.dart';
import 'package:belluga_now/domain/schedule/value_objects/event_occurrence_values.dart';
import 'package:belluga_now/domain/venue_event/value_objects/venue_event_tag_value.dart';
import 'package:value_object_pattern/domain/value_objects/date_time_value.dart';

class EventSelectedOccurrenceProjection {
  const EventSelectedOccurrenceProjection._();

  static EventModel align(EventModel event) {
    final occurrenceId = event.selectedOccurrenceId?.trim();
    if (occurrenceId == null || occurrenceId.isEmpty) {
      return event;
    }

    final selectedOccurrence = event.selectedOccurrence;
    if (selectedOccurrence == null) {
      return event;
    }

    final expectedEnd = _dateTimeEndForSelectedOccurrence(selectedOccurrence);
    final hasMatchingSchedule = _dateTimeSignature(event.dateTimeStart) ==
            _dateTimeSignature(selectedOccurrence.dateTimeStartValue) &&
        _dateTimeSignature(event.dateTimeEnd) ==
            _dateTimeSignature(expectedEnd);
    final hasMatchingProgramming =
        _programmingSignature(event.programmingItems) ==
            _programmingSignature(selectedOccurrence.programmingItems);
    final hasMatchingTags =
        _tagSignature(event.tags) == _tagSignature(selectedOccurrence.tags);

    if (hasMatchingSchedule && hasMatchingProgramming && hasMatchingTags) {
      return event;
    }

    return project(
      event,
      occurrenceId,
      preserveCurrentProgrammingWhenAlreadySelectedAndTargetEmpty: true,
    );
  }

  static EventModel project(
    EventModel event,
    String occurrenceId, {
    bool preserveCurrentProgrammingWhenAlreadySelectedAndTargetEmpty = false,
  }) {
    final normalizedOccurrenceId = occurrenceId.trim();
    if (normalizedOccurrenceId.isEmpty) {
      return event;
    }

    EventOccurrenceOption? selectedOccurrence;
    for (final occurrence in event.occurrences) {
      if (occurrence.occurrenceId == normalizedOccurrenceId) {
        selectedOccurrence = occurrence;
        break;
      }
    }
    if (selectedOccurrence == null) {
      return event;
    }

    final preservesCurrentSelectedProgramming =
        preserveCurrentProgrammingWhenAlreadySelectedAndTargetEmpty &&
            (event.selectedOccurrenceId?.trim() ?? '') ==
                normalizedOccurrenceId &&
            selectedOccurrence.programmingItems.isEmpty;

    final updatedOccurrences = event.occurrences
        .map(
          (occurrence) => EventOccurrenceOption(
            occurrenceIdValue: occurrence.occurrenceIdValue,
            occurrenceSlugValue: occurrence.occurrenceSlugValue,
            dateTimeStartValue: occurrence.dateTimeStartValue,
            dateTimeEndValue: occurrence.dateTimeEndValue,
            isSelectedValue: EventOccurrenceFlagValue()
              ..parse(
                (occurrence.occurrenceId == normalizedOccurrenceId).toString(),
              ),
            hasLocationOverrideValue: occurrence.hasLocationOverrideValue,
            programmingCountValue: occurrence.programmingCountValue,
            programmingItems: occurrence.programmingItems,
            profileGroups: occurrence.profileGroups,
            tags: occurrence.tags,
          ),
        )
        .toList(growable: false);

    return EventModel(
      id: event.id,
      slugValue: event.slugValue,
      type: event.type,
      title: event.title,
      content: event.content,
      location: event.location,
      venue: event.venue,
      thumb: event.thumb,
      dateTimeStart: selectedOccurrence.dateTimeStartValue,
      dateTimeEnd: _dateTimeEndForSelectedOccurrence(selectedOccurrence),
      linkedAccountProfiles: event.linkedAccountProfiles,
      profileGroups: event.profileGroups,
      occurrences: updatedOccurrences,
      programmingItems: preservesCurrentSelectedProgramming
          ? event.programmingItems
          : selectedOccurrence.programmingItems,
      coordinate: event.coordinate,
      tags: selectedOccurrence.tags.isNotEmpty
          ? selectedOccurrence.tags
          : event.tags,
      isConfirmedValue: event.isConfirmedValue,
      confirmedAtValue: event.confirmedAtValue,
      receivedInvites: event.receivedInvites,
      sentInvites: event.sentInvites,
      friendsGoing: event.friendsGoing,
      totalConfirmedValue: event.totalConfirmedValue,
    );
  }

  static DateTimeValue? _dateTimeEndForSelectedOccurrence(
    EventOccurrenceOption selectedOccurrence,
  ) {
    final end = selectedOccurrence.dateTimeEnd;
    if (end == null) {
      return null;
    }

    return DateTimeValue()..parse(end.toIso8601String());
  }

  static String _dateTimeSignature(DateTimeValue? value) {
    return value?.value?.toIso8601String() ?? '';
  }

  static String _programmingSignature(List<EventProgrammingItem> items) {
    return items.map((item) {
      final profileIds = item.linkedAccountProfiles
          .map((profile) => profile.id.trim())
          .where((id) => id.isNotEmpty)
          .join(',');
      return [
        item.time,
        item.endTime ?? '',
        item.title ?? '',
        profileIds,
        item.locationProfile?.id.trim() ?? '',
      ].join(':');
    }).join('|');
  }

  static String _tagSignature(Iterable<dynamic> tags) {
    return tags
        .map((tag) => tag is VenueEventTagValue
            ? tag.value.trim()
            : tag.toString().trim())
        .where((tag) => tag.isNotEmpty)
        .join('|');
  }
}
