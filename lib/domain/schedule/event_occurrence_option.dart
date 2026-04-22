import 'package:belluga_now/domain/schedule/value_objects/event_linked_account_profile_text_value.dart';
import 'package:belluga_now/domain/schedule/value_objects/event_occurrence_values.dart';
import 'package:belluga_now/domain/value_objects/domain_optional_date_time_value.dart';
import 'package:value_object_pattern/domain/value_objects/date_time_value.dart';

class EventOccurrenceOption {
  const EventOccurrenceOption({
    required this.occurrenceIdValue,
    required this.occurrenceSlugValue,
    required this.dateTimeStartValue,
    required this.dateTimeEndValue,
    required this.isSelectedValue,
    required this.hasLocationOverrideValue,
    required this.programmingCountValue,
  });

  final EventLinkedAccountProfileTextValue occurrenceIdValue;
  final EventLinkedAccountProfileTextValue occurrenceSlugValue;
  final DateTimeValue dateTimeStartValue;
  final DomainOptionalDateTimeValue dateTimeEndValue;
  final EventOccurrenceFlagValue isSelectedValue;
  final EventOccurrenceFlagValue hasLocationOverrideValue;
  final EventProgrammingCountValue programmingCountValue;

  String get occurrenceId => occurrenceIdValue.value;
  String get occurrenceSlug => occurrenceSlugValue.value;
  DateTime? get dateTimeStart => dateTimeStartValue.value;
  DateTime? get dateTimeEnd => dateTimeEndValue.value;
  bool get isSelected => isSelectedValue.value;
  bool get hasLocationOverride => hasLocationOverrideValue.value;
  int get programmingCount => programmingCountValue.value;
}
