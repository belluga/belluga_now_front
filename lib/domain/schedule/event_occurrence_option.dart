import 'package:belluga_now/domain/schedule/value_objects/event_linked_account_profile_text_value.dart';
import 'package:belluga_now/domain/schedule/event_profile_group.dart';
import 'package:belluga_now/domain/schedule/event_programming_item.dart';
import 'package:belluga_now/domain/schedule/event_schedule_display.dart';
import 'package:belluga_now/domain/schedule/value_objects/event_occurrence_values.dart';
import 'package:belluga_now/domain/value_objects/domain_optional_date_time_value.dart';
import 'package:value_object_pattern/domain/value_objects/date_time_value.dart';

class EventOccurrenceOption {
  EventOccurrenceOption({
    required this.occurrenceIdValue,
    required this.occurrenceSlugValue,
    required this.dateTimeStartValue,
    required this.dateTimeEndValue,
    required this.isSelectedValue,
    required this.hasLocationOverrideValue,
    required this.programmingCountValue,
    List<EventProgrammingItem> programmingItems = const [],
    List<EventProfileGroup> profileGroups = const [],
  })  : programmingItems = List<EventProgrammingItem>.unmodifiable(
          programmingItems,
        ),
        profileGroups = List<EventProfileGroup>.unmodifiable(profileGroups);

  final EventLinkedAccountProfileTextValue occurrenceIdValue;
  final EventLinkedAccountProfileTextValue occurrenceSlugValue;
  final DateTimeValue dateTimeStartValue;
  final DomainOptionalDateTimeValue dateTimeEndValue;
  final EventOccurrenceFlagValue isSelectedValue;
  final EventOccurrenceFlagValue hasLocationOverrideValue;
  final EventProgrammingCountValue programmingCountValue;
  final List<EventProgrammingItem> programmingItems;
  final List<EventProfileGroup> profileGroups;

  String get occurrenceId => occurrenceIdValue.value;
  String get occurrenceSlug => occurrenceSlugValue.value;
  DateTime? get dateTimeStart => dateTimeStartValue.value;
  DateTime? get dateTimeEnd => dateTimeEndValue.value;
  bool get isSelected => isSelectedValue.value;
  bool get hasLocationOverride => hasLocationOverrideValue.value;
  int get programmingCount => programmingCountValue.value;
  EventScheduleDisplay get scheduleDisplay {
    final end = dateTimeEnd;
    final endValue =
        end == null ? null : (DateTimeValue()..parse(end.toIso8601String()));
    return EventScheduleDisplay(
      startValue: dateTimeStartValue,
      endValue: endValue,
    );
  }

  String get detailScheduleLabel {
    if (dateTimeStart == null) {
      throw StateError('EventOccurrenceOption.dateTimeStart must be defined');
    }
    return scheduleDisplay.detailLabel;
  }

  String get agendaScheduleLabel => scheduleDisplay.agendaLabel;
  String get flyerScheduleLabel => scheduleDisplay.flyerLabel;
}
