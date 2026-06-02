import 'package:belluga_now/domain/schedule/event_linked_account_profile.dart';
import 'package:belluga_now/domain/schedule/value_objects/event_linked_account_profile_text_value.dart';
import 'package:belluga_now/domain/schedule/value_objects/event_profile_group_order_value.dart';

class EventProfileGroup {
  EventProfileGroup({
    required this.idValue,
    required this.labelValue,
    required this.orderValue,
    List<EventLinkedAccountProfile> profiles =
        const <EventLinkedAccountProfile>[],
  }) : profiles = List<EventLinkedAccountProfile>.unmodifiable(profiles);

  final EventLinkedAccountProfileTextValue idValue;
  final EventLinkedAccountProfileTextValue labelValue;
  final EventProfileGroupOrderValue orderValue;
  final List<EventLinkedAccountProfile> profiles;

  String get id => idValue.value;
  String get label => labelValue.value;
  int get order => orderValue.value;
}
