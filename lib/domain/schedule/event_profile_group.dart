import 'package:belluga_now/domain/schedule/event_linked_account_profile.dart';
import 'package:belluga_now/domain/schedule/value_objects/event_linked_account_profile_text_value.dart';
import 'package:belluga_now/domain/schedule/value_objects/event_profile_group_member_count_value.dart';
import 'package:belluga_now/domain/schedule/value_objects/event_profile_group_members_path_value.dart';
import 'package:belluga_now/domain/schedule/value_objects/event_profile_group_order_value.dart';

export 'package:belluga_now/domain/schedule/value_objects/event_profile_group_member_count_value.dart';
export 'package:belluga_now/domain/schedule/value_objects/event_profile_group_members_path_value.dart';

class EventProfileGroup {
  EventProfileGroup({
    required this.idValue,
    required this.labelValue,
    required this.orderValue,
    EventProfileGroupMembersPathValue? membersPathValue,
    EventProfileGroupMemberCountValue? memberCountValue,
    List<EventLinkedAccountProfile> profiles =
        const <EventLinkedAccountProfile>[],
    List<EventLinkedAccountProfileTextValue> accountProfileIdValues =
        const <EventLinkedAccountProfileTextValue>[],
  }) : profiles = List<EventLinkedAccountProfile>.unmodifiable(profiles),
       accountProfileIdValues =
           List<EventLinkedAccountProfileTextValue>.unmodifiable(
             accountProfileIdValues.where((id) => id.value.isNotEmpty),
           ),
       membersPathValue =
           membersPathValue ?? EventProfileGroupMembersPathValue(),
       memberCountValue =
           memberCountValue ??
           EventProfileGroupMemberCountValue(profiles.length);

  final EventLinkedAccountProfileTextValue idValue;
  final EventLinkedAccountProfileTextValue labelValue;
  final EventProfileGroupOrderValue orderValue;
  final EventProfileGroupMembersPathValue membersPathValue;
  final EventProfileGroupMemberCountValue memberCountValue;
  final List<EventLinkedAccountProfile> profiles;
  final List<EventLinkedAccountProfileTextValue> accountProfileIdValues;

  String get id => idValue.value;
  String get label => labelValue.value;
  int get order => orderValue.value;
  String? get membersPath => membersPathValue.nullableValue;
  int get memberCount => memberCountValue.value;
  bool get isVisible =>
      label.trim().isNotEmpty &&
      (profiles.isNotEmpty ||
          accountProfileIdValues.isNotEmpty ||
          memberCount > 0 ||
          (membersPath?.trim().isNotEmpty ?? false));
}
