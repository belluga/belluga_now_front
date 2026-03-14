import 'package:belluga_now/domain/invites/invite_inviter.dart';
import 'package:belluga_now/domain/invites/invite_inviter_principal.dart';
import 'package:belluga_now/domain/invites/invite_inviter_type.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_additional_inviter_name_value.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_event_date_value.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_event_id_value.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_host_name_value.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_id_value.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_inviter_avatar_value.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_inviter_name_value.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_location_value.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_message_value.dart';
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
    this.occurrenceId,
    this.attendancePolicy = 'free_confirmation_only',
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
  final String? occurrenceId;
  final String attendancePolicy;
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
  String? get inviterName => primaryInviter?.name ?? inviterNameValue?.value;
  Uri? get inviterAvatarUri {
    final primaryAvatarUrl = primaryInviter?.avatarUrl?.trim();
    if (primaryAvatarUrl != null && primaryAvatarUrl.isNotEmpty) {
      return Uri.tryParse(primaryAvatarUrl);
    }
    return inviterAvatarValue?.value;
  }

  String? get inviterAvatarUrl => inviterAvatarUri?.toString();
  List<String> get tags =>
      tagValues.map((tag) => tag.value).toList(growable: false);
  List<String> get additionalInviters => additionalInviterValues
      .map((additional) => additional.value)
      .toList(growable: false);
  InviteInviter? get primaryInviter => inviters.isEmpty ? null : inviters.first;
  List<InviteInviter> get secondaryInviters =>
      inviters.length <= 1 ? const [] : inviters.sublist(1);
  bool get hasMultipleInviters => inviters.length > 1;
  String? get primaryInviteId => primaryInviter?.inviteId.isNotEmpty == true
      ? primaryInviter!.inviteId
      : null;

  bool containsInviteId(String inviteId) {
    return inviters.any((inviter) => inviter.inviteId == inviteId);
  }

  InviteModel prioritizeInviter(String inviteId) {
    if (inviters.isEmpty) {
      return this;
    }

    final index =
        inviters.indexWhere((inviter) => inviter.inviteId == inviteId);
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
      occurrenceId: occurrenceId,
      attendancePolicy: attendancePolicy,
      inviterNameValue: inviterNameValue,
      inviterAvatarValue: inviterAvatarValue,
      inviterPrincipal: inviterPrincipal,
      additionalInviterValues: additionalInviterValues,
      inviters: nextInviters,
    );
  }

  factory InviteModel.fromPrimitives({
    required String id,
    required String eventId,
    required String eventName,
    required DateTime eventDateTime,
    required String eventImageUrl,
    required String location,
    required String hostName,
    required String message,
    required List<String> tags,
    String? occurrenceId,
    String attendancePolicy = 'free_confirmation_only',
    String? inviterName,
    String? inviterAvatarUrl,
    InviteInviterPrincipal? inviterPrincipal,
    List<String> additionalInviters = const [],
    List<InviteInviter> inviters = const [],
  }) {
    final eventImageUri = Uri.parse(eventImageUrl);
    final parsedTags = tags
        .where((tag) => tag.trim().isNotEmpty)
        .map((tag) => InviteTagValue()..parse(tag))
        .toList(growable: false);
    final resolvedInviterName =
        inviterName ?? (inviters.isNotEmpty ? inviters.first.name : null);
    final resolvedInviterAvatarUrl = inviterAvatarUrl ??
        (inviters.isNotEmpty ? inviters.first.avatarUrl : null);
    final resolvedInviterPrincipal = inviterPrincipal ??
        (inviters.isNotEmpty ? inviters.first.principal : null);
    final resolvedInviters = inviters.isNotEmpty
        ? inviters
        : (resolvedInviterName != null && resolvedInviterName.trim().isNotEmpty
            ? <InviteInviter>[
                InviteInviter(
                  inviteId: id,
                  type:
                      resolvedInviterPrincipal?.type ?? InviteInviterType.user,
                  name: resolvedInviterName,
                  principal: resolvedInviterPrincipal,
                  avatarUrl: resolvedInviterAvatarUrl,
                ),
              ]
            : const <InviteInviter>[]);
    final resolvedAdditionalInviters = additionalInviters.isNotEmpty
        ? additionalInviters
        : resolvedInviters
            .skip(1)
            .map((inviter) => inviter.name)
            .toList(growable: false);

    InviteInviterNameValue? inviterNameVo;
    if (resolvedInviterName != null && resolvedInviterName.trim().isNotEmpty) {
      inviterNameVo = InviteInviterNameValue()..parse(resolvedInviterName);
    }

    InviteInviterAvatarValue? inviterAvatarVo;
    if (resolvedInviterAvatarUrl != null &&
        resolvedInviterAvatarUrl.trim().isNotEmpty) {
      inviterAvatarVo = InviteInviterAvatarValue()
        ..parse(resolvedInviterAvatarUrl);
    }

    return InviteModel(
      idValue: InviteIdValue()..parse(id),
      eventIdValue: InviteEventIdValue()..parse(eventId),
      eventNameValue: TitleValue()..parse(eventName),
      eventDateValue: InviteEventDateValue(isRequired: true)
        ..parse(eventDateTime.toIso8601String()),
      eventImageValue: ThumbUriValue(
        defaultValue: eventImageUri,
        isRequired: true,
      )..parse(eventImageUrl),
      locationValue: InviteLocationValue()..parse(location),
      hostNameValue: InviteHostNameValue()..parse(hostName),
      messageValue: InviteMessageValue()..parse(message),
      tagValues: parsedTags,
      occurrenceId:
          occurrenceId?.trim().isEmpty == true ? null : occurrenceId?.trim(),
      attendancePolicy: attendancePolicy.trim().isEmpty
          ? 'free_confirmation_only'
          : attendancePolicy.trim(),
      inviterNameValue: inviterNameVo,
      inviterAvatarValue: inviterAvatarVo,
      inviterPrincipal: resolvedInviterPrincipal,
      additionalInviterValues: resolvedAdditionalInviters
          .where((inviter) => inviter.trim().isNotEmpty)
          .map((inviter) => InviteAdditionalInviterNameValue()..parse(inviter))
          .toList(growable: false),
      inviters: resolvedInviters,
    );
  }
}
