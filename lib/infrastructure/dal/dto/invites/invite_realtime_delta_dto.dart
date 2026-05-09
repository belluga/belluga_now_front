import 'package:belluga_now/infrastructure/dal/dto/invites/invite_dto.dart';

class InviteRealtimeDeltaDto {
  const InviteRealtimeDeltaDto({
    required this.type,
    this.invite,
    this.eventId,
    this.occurrenceId,
    this.lastEventId,
  });

  final String type;
  final InviteDto? invite;
  final String? eventId;
  final String? occurrenceId;
  final String? lastEventId;

  bool get isUpsert => type == 'invite.upsert' && invite != null;

  bool get isDeleted =>
      type == 'invite.deleted' &&
      eventId != null &&
      eventId!.isNotEmpty &&
      occurrenceId != null &&
      occurrenceId!.isNotEmpty;
}
