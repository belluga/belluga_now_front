import 'package:belluga_now/domain/invites/invite_inviter.dart';
import 'package:belluga_now/domain/invites/invite_inviter_principal.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_additional_inviter_name_value.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_attendance_policy_value.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_event_date_value.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_event_id_value.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_host_name_value.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_id_value.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_inviter_avatar_value.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_inviter_name_value.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_location_value.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_message_value.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_occurrence_id_value.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_tag_value.dart';
import 'package:belluga_now/domain/value_objects/thumb_uri_value.dart';
import 'package:belluga_now/domain/value_objects/title_value.dart';
import 'package:value_object_pattern/domain/exceptions/value_exceptions.dart';

class InviteModel {
  InviteModel({
    required this.idValue,
    required this.eventIdValue,
    required this.eventNameValue,
    required this.eventDateValue,
    required this.eventImageValue,
    required this.locationValue,
    required this.hostNameValue,
    required this.messageValue,
    required List<InviteTagValue> tagValues,
    required this.occurrenceIdValue,
    required this.attendancePolicyValue,
    this.inviterNameValue,
    this.inviterAvatarValue,
    this.inviterPrincipal,
    List<InviteAdditionalInviterNameValue>? additionalInviterValues,
    this.inviters = const [],
  })  : tagValues = List.unmodifiable(tagValues),
        additionalInviterValues =
            List.unmodifiable(additionalInviterValues ?? const []);

  final InviteIdValue idValue;
  final InviteEventIdValue eventIdValue;
  final TitleValue eventNameValue;
  final InviteEventDateValue eventDateValue;
  final ThumbUriValue eventImageValue;
  final InviteLocationValue locationValue;
  final InviteHostNameValue hostNameValue;
  final InviteMessageValue messageValue;
  final List<InviteTagValue> tagValues;
  final InviteOccurrenceIdValue occurrenceIdValue;
  final InviteAttendancePolicyValue attendancePolicyValue;
  final InviteInviterNameValue? inviterNameValue;
  final InviteInviterAvatarValue? inviterAvatarValue;
  final InviteInviterPrincipal? inviterPrincipal;
  final List<InviteAdditionalInviterNameValue> additionalInviterValues;
  final List<InviteInviter> inviters;

  String get id => idValue.value;
  String get eventId => eventIdValue.value;
  String get groupKey => id;
  String get eventName => eventNameValue.value;
  DateTime get eventDateTime {
    final date = eventDateValue.value;
    if (date == null) {
      throw InvalidValueException();
    }
    return date;
  }

  Uri get eventImageUri => eventImageValue.value;
  String get eventImageUrl => eventImageUri.toString();
  String get location => locationValue.value;
  String get hostName => hostNameValue.value;
  String get message => messageValue.value;
  String? get occurrenceId => occurrenceIdValue.value;
  String get attendancePolicy => attendancePolicyValue.value;
  String? get inviterName => primaryInviter?.name ?? inviterNameValue?.value;
  Uri? get inviterAvatarUri {
    final primaryAvatarUrl = primaryInviter?.avatarUrl?.trim();
    if (primaryAvatarUrl != null && primaryAvatarUrl.isNotEmpty) {
      return Uri.tryParse(primaryAvatarUrl);
    }
    return inviterAvatarValue?.value;
  }

  String? get inviterAvatarUrl => inviterAvatarUri?.toString();
  List<InviteTagValue> get tags => List<InviteTagValue>.unmodifiable(tagValues);
  List<InviteAdditionalInviterNameValue> get additionalInviters =>
      List<InviteAdditionalInviterNameValue>.unmodifiable(
        additionalInviterValues,
      );
  InviteInviter? get primaryInviter => inviters.isEmpty ? null : inviters.first;
  List<InviteInviter> get secondaryInviters =>
      inviters.length <= 1 ? const [] : inviters.sublist(1);
  bool get hasMultipleInviters => inviters.length > 1;
  String? get primaryInviteId => primaryInviter?.inviteId.isNotEmpty == true
      ? primaryInviter!.inviteId
      : null;

  bool containsInviteId(InviteIdValue inviteIdValue) {
    return inviters.any((inviter) => inviter.inviteId == inviteIdValue.value);
  }

  InviteModel prioritizeInviter(InviteIdValue inviteIdValue) {
    if (inviters.isEmpty) {
      return this;
    }

    final index = inviters
        .indexWhere((inviter) => inviter.inviteId == inviteIdValue.value);
    if (index <= 0) {
      return this;
    }

    final nextInviters = List<InviteInviter>.from(inviters);
    final prioritized = nextInviters.removeAt(index);
    nextInviters.insert(0, prioritized);

    return InviteModel(
      idValue: idValue,
      eventIdValue: eventIdValue,
      eventNameValue: eventNameValue,
      eventDateValue: eventDateValue,
      eventImageValue: eventImageValue,
      locationValue: locationValue,
      hostNameValue: hostNameValue,
      messageValue: messageValue,
      tagValues: tagValues,
      occurrenceIdValue: occurrenceIdValue,
      attendancePolicyValue: attendancePolicyValue,
      inviterNameValue: inviterNameValue,
      inviterAvatarValue: inviterAvatarValue,
      inviterPrincipal: inviterPrincipal,
      additionalInviterValues: additionalInviterValues,
      inviters: nextInviters,
    );
  }
}
