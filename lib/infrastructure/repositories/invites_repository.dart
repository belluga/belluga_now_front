import 'dart:convert';

import 'package:belluga_now/domain/contacts/contact_model.dart';
import 'package:belluga_now/domain/invites/invite_accept_result.dart';
import 'package:belluga_now/domain/invites/invite_contact_match.dart';
import 'package:belluga_now/domain/invites/invite_decline_result.dart';
import 'package:belluga_now/domain/invites/invite_model.dart';
import 'package:belluga_now/domain/invites/invite_next_step.dart';
import 'package:belluga_now/domain/invites/invite_runtime_settings.dart';
import 'package:belluga_now/domain/invites/invite_share_code_result.dart';
import 'package:belluga_now/domain/repositories/invites_repository_contract.dart';
import 'package:belluga_now/domain/schedule/friend_resume.dart';
import 'package:belluga_now/domain/schedule/invite_status.dart';
import 'package:belluga_now/domain/schedule/sent_invite_status.dart';
import 'package:belluga_now/infrastructure/dal/dao/invites/invites_response_decoder.dart';
import 'package:belluga_now/infrastructure/dal/dao/laravel_backend/invites_backend/laravel_invites_backend.dart';
import 'package:belluga_now/infrastructure/dal/dto/mappers/invite_dto_mapper.dart';
import 'package:belluga_now/infrastructure/repositories/push/push_payload_upsert_mixin.dart';
import 'package:belluga_now/infrastructure/services/invites_backend_contract.dart';
import 'package:crypto/crypto.dart';
import 'package:belluga_now/domain/repositories/friends_repository_contract.dart';

class InvitesRepository extends InvitesRepositoryContract
    with
        InviteDtoMapper,
        PushPayloadUpsertMixin<InviteModel>,
        PushInvitePayloadMixin
    implements PushInvitePayloadAware {
  InvitesRepository({
    InvitesBackendContract? backend,
    FriendsRepositoryContract? friendsRepository,
  }) : _backend = backend ?? LaravelInvitesBackend();

  final InvitesBackendContract _backend;
  final InvitesResponseDecoder _responseDecoder =
      const InvitesResponseDecoder();

  @override
  Future<List<InviteModel>> fetchInvites(
      {int page = 1, int pageSize = 20}) async {
    final response =
        await _backend.fetchInvites(page: page, pageSize: pageSize);
    final invitesRaw = response['invites'];
    final invites = _responseDecoder
        .decodeInviteDtos(invitesRaw)
        .map(mapInviteDto)
        .toList(growable: false);

    if (page == 1) {
      pendingInvitesStreamValue.addValue(invites);
    }

    return invites;
  }

  @override
  Future<InviteRuntimeSettings> fetchSettings() async {
    final response = await _backend.fetchSettings();
    final settings = InviteRuntimeSettings(
      tenantId: _stringOrNull(response['tenant_id']),
      limits: _parseIntMap(response['limits']),
      cooldowns: _parseIntMap(response['cooldowns']),
      overQuotaMessage: _stringOrNull(response['over_quota_message']),
    );
    settingsStreamValue.addValue(settings);
    return settings;
  }

  @override
  Future<InviteAcceptResult> acceptInvite(String inviteId) async {
    final response = await _backend.acceptInvite(inviteId);
    await fetchInvites();
    return InviteAcceptResult(
      inviteId: _stringOrEmpty(response['invite_id']),
      status: _stringOrEmpty(response['status']),
      creditedAcceptance: response['credited_acceptance'] == true,
      attendancePolicy: _stringOrEmpty(response['attendance_policy']).isEmpty
          ? 'free_confirmation_only'
          : _stringOrEmpty(response['attendance_policy']),
      nextStep:
          InviteNextStepApiMapper.parse(response['next_step']?.toString()),
      supersededInviteIds: _parseStringList(
        response['superseded_invite_ids'] ??
            response['closed_duplicate_invite_ids'],
      ),
      acceptedAt: _parseDateTime(response['accepted_at']),
    );
  }

  @override
  Future<InviteDeclineResult> declineInvite(String inviteId) async {
    final response = await _backend.declineInvite(inviteId);
    await fetchInvites();
    return InviteDeclineResult(
      inviteId: _stringOrEmpty(response['invite_id']),
      status: _stringOrEmpty(response['status']),
      groupHasOtherPending: response['group_has_other_pending'] == true,
      declinedAt: _parseDateTime(response['declined_at']),
    );
  }

  @override
  Future<InviteAcceptResult> acceptShareCode(String code) async {
    final response = await _backend.acceptShareCode(code);
    await fetchInvites();
    return InviteAcceptResult(
      inviteId: _stringOrEmpty(response['invite_id']),
      status: _stringOrEmpty(response['status']),
      creditedAcceptance: response['attribution_bound'] == true,
      attendancePolicy: _stringOrEmpty(response['attendance_policy']).isEmpty
          ? 'free_confirmation_only'
          : _stringOrEmpty(response['attendance_policy']),
      nextStep:
          InviteNextStepApiMapper.parse(response['next_step']?.toString()),
      supersededInviteIds: _parseStringList(
        response['superseded_invite_ids'] ??
            response['closed_duplicate_invite_ids'],
      ),
      acceptedAt: _parseDateTime(response['accepted_at']),
    );
  }

  @override
  Future<InviteModel?> previewShareCode(String code) async {
    final response = await _backend.fetchShareCodePreview(code);
    final inviteRaw = response['invite'];
    final decoded = _responseDecoder.decodeInviteDtos([inviteRaw]);
    if (decoded.isEmpty) {
      return null;
    }
    return mapInviteDto(decoded.first);
  }

  @override
  Future<List<InviteContactMatch>> importContacts(
    List<ContactModel> contacts,
  ) async {
    final importItems = _buildContactImportItems(contacts);
    if (importItems.isEmpty) {
      return const <InviteContactMatch>[];
    }

    final response = await _backend.importContacts({
      'contacts': importItems,
    });
    final matchesRaw = response['matches'];
    return _responseDecoder.decodeContactMatches(matchesRaw);
  }

  @override
  Future<InviteShareCodeResult> createShareCode({
    required String eventId,
    String? occurrenceId,
    String? accountProfileId,
  }) async {
    final response = await _backend.createShareCode({
      'target_ref': {
        'event_id': eventId,
        if (occurrenceId != null && occurrenceId.trim().isNotEmpty)
          'occurrence_id': occurrenceId.trim(),
      },
      if (accountProfileId != null && accountProfileId.trim().isNotEmpty)
        'account_profile_id': accountProfileId.trim(),
    });

    final targetRef = _responseDecoder.decodeShareCodeTargetRef(
      response['target_ref'],
      fallbackEventId: eventId,
    );

    return InviteShareCodeResult(
      code: _stringOrEmpty(response['code']),
      eventId: targetRef.eventId,
      occurrenceId: targetRef.occurrenceId,
    );
  }

  @override
  Future<void> sendInvites(
    String eventId,
    List<EventFriendResume> recipients, {
    String? occurrenceId,
    String? message,
  }) async {
    if (recipients.isEmpty) {
      return;
    }

    final response = await _backend.sendInvites({
      'target_ref': {
        'event_id': eventId,
        if (occurrenceId != null && occurrenceId.trim().isNotEmpty)
          'occurrence_id': occurrenceId.trim(),
      },
      'recipients': recipients
          .map((recipient) => {'receiver_user_id': recipient.id})
          .toList(growable: false),
      if (message != null && message.trim().isNotEmpty)
        'message': message.trim(),
    });

    final acknowledgedRecipientIds = <String>{
      ..._parseRecipientIds(response['created']),
      ..._parseRecipientIds(response['already_invited']),
    };

    if (acknowledgedRecipientIds.isEmpty) {
      return;
    }

    final currentByEvent = sentInvitesByEventStreamValue.value;
    final existing =
        List<SentInviteStatus>.from(currentByEvent[eventId] ?? const []);
    final existingByRecipient = <String, SentInviteStatus>{
      for (final invite in existing) invite.friend.id: invite,
    };
    final now = DateTime.now();

    for (final recipient in recipients) {
      if (!acknowledgedRecipientIds.contains(recipient.id)) {
        continue;
      }
      existingByRecipient[recipient.id] = SentInviteStatus(
        friend: recipient,
        status: InviteStatus.pending,
        sentAt: existingByRecipient[recipient.id]?.sentAt ?? now,
        respondedAt: existingByRecipient[recipient.id]?.respondedAt,
      );
    }

    sentInvitesByEventStreamValue.addValue({
      ...currentByEvent,
      eventId: existingByRecipient.values.toList(growable: false),
    });
  }

  @override
  Future<List<SentInviteStatus>> getSentInvitesForEvent(String eventId) async {
    return List<SentInviteStatus>.from(
      sentInvitesByEventStreamValue.value[eventId] ??
          const <SentInviteStatus>[],
      growable: false,
    );
  }

  @override
  void applyInvitePushPayload(Object? payload) {
    final current = pendingInvitesStreamValue.value;
    final next = mergeInvitePayload(current: current, payload: payload);
    if (identical(current, next)) {
      return;
    }
    pendingInvitesStreamValue.addValue(next);
  }

  List<Map<String, String>> _buildContactImportItems(
      List<ContactModel> contacts) {
    final seen = <String>{};
    final items = <Map<String, String>>[];

    for (final contact in contacts) {
      for (final email in contact.emails) {
        final normalized = email.trim().toLowerCase();
        if (normalized.isEmpty) {
          continue;
        }
        final hash = sha256.convert(utf8.encode(normalized)).toString();
        final signature = 'email::$hash';
        if (!seen.add(signature)) {
          continue;
        }
        items.add({'type': 'email', 'hash': hash});
      }

      for (final phone in contact.phones) {
        final normalized = phone.replaceAll(RegExp(r'\D+'), '');
        if (normalized.isEmpty) {
          continue;
        }
        final hash = sha256.convert(utf8.encode(normalized)).toString();
        final signature = 'phone::$hash';
        if (!seen.add(signature)) {
          continue;
        }
        items.add({'type': 'phone', 'hash': hash});
      }
    }

    return items;
  }

  List<String> _parseRecipientIds(Object? raw) {
    return _responseDecoder.decodeRecipientIds(raw);
  }

  List<String> _parseStringList(Object? raw) {
    if (raw is! List) {
      return const <String>[];
    }
    return raw
        .map((item) => item?.toString() ?? '')
        .where((value) => value.isNotEmpty)
        .toList(growable: false);
  }

  Map<String, int> _parseIntMap(Object? raw) {
    return _responseDecoder.decodeIntMap(raw);
  }

  DateTime? _parseDateTime(Object? raw) {
    final value = raw?.toString();
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    return DateTime.tryParse(value);
  }

  String _stringOrEmpty(Object? raw) => raw?.toString() ?? '';

  String? _stringOrNull(Object? raw) {
    final value = raw?.toString().trim();
    if (value == null || value.isEmpty) {
      return null;
    }
    return value;
  }
}
