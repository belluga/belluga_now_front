import 'package:belluga_now/domain/schedule/event_linked_account_profile.dart';
import 'package:belluga_now/domain/schedule/value_objects/event_linked_account_profile_text_value.dart';
import 'package:belluga_now/domain/schedule/value_objects/event_occurrence_values.dart';

class EventProgrammingItem {
  EventProgrammingItem({
    required this.timeValue,
    this.titleValue,
    List<EventLinkedAccountProfile> linkedAccountProfiles = const [],
    this.locationProfile,
  }) : linkedAccountProfiles = List<EventLinkedAccountProfile>.unmodifiable(
          linkedAccountProfiles,
        );

  final EventProgrammingTimeValue timeValue;
  final EventLinkedAccountProfileTextValue? titleValue;
  final List<EventLinkedAccountProfile> linkedAccountProfiles;
  final EventLinkedAccountProfile? locationProfile;

  String get time => timeValue.value;
  String? get title => titleValue?.value;
  String get displayTitle {
    final explicitTitle = title?.trim();
    return explicitTitle == null || explicitTitle.isEmpty ? '' : explicitTitle;
  }

  bool get hasLocationProfile => locationProfile != null;
}
