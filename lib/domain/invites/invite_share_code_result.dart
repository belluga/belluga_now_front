import 'package:belluga_now/domain/invites/value_objects/invite_event_id_value.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_occurrence_id_value.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_share_code_value.dart';

class InviteShareCodeResult {
  const InviteShareCodeResult({
    required this.codeValue,
    required this.eventIdValue,
    this.occurrenceIdValue,
  });

  final InviteShareCodeValue codeValue;
  final InviteEventIdValue eventIdValue;
  final InviteOccurrenceIdValue? occurrenceIdValue;

  String get code => codeValue.value;
  String get eventId => eventIdValue.value;
  String? get occurrenceId => occurrenceIdValue?.value;
}
