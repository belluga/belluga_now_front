import 'package:belluga_now/domain/schedule/event_linked_account_profile.dart';

class EventRelatedProfileGroupSummary {
  EventRelatedProfileGroupSummary({
    required String label,
    required List<EventLinkedAccountProfile> profiles,
  })  : label = label.trim(),
        profiles = List<EventLinkedAccountProfile>.unmodifiable(profiles);

  final String label;
  final List<EventLinkedAccountProfile> profiles;

  List<String> get profileNames => List<String>.unmodifiable(
        profiles
            .map((profile) => profile.displayName.trim())
            .where((name) => name.isNotEmpty),
      );
}
