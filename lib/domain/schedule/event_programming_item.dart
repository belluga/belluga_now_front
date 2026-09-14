import 'package:belluga_now/domain/partners/account_profile_summary.dart';
import 'package:belluga_now/domain/partners/value_objects/account_profile_text_value.dart';
import 'package:belluga_now/domain/schedule/value_objects/event_occurrence_values.dart';

class EventProgrammingItem {
  EventProgrammingItem({
    required this.timeValue,
    this.endTimeValue,
    this.titleValue,
    List<AccountProfileSummary> linkedAccountProfiles = const [],
    this.locationProfile,
  }) : linkedAccountProfiles = List<AccountProfileSummary>.unmodifiable(
         linkedAccountProfiles,
       );

  final EventProgrammingTimeValue timeValue;
  final EventProgrammingTimeValue? endTimeValue;
  final AccountProfileTextValue? titleValue;
  final List<AccountProfileSummary> linkedAccountProfiles;
  final AccountProfileSummary? locationProfile;

  String get time => timeValue.value;
  bool get hasTime => time.trim().isNotEmpty;
  bool get isSequential => !hasTime;
  String? get endTime => endTimeValue?.value;
  String? get title => titleValue?.value;
  String get displayTitle {
    final explicitTitle = title?.trim();
    return explicitTitle == null || explicitTitle.isEmpty ? '' : explicitTitle;
  }

  bool get hasLocationProfile => locationProfile != null;
}
