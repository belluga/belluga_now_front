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

  @override
  Future<List<InviteModel>> fetchInvites(
      {int page = 1, int pageSize = 20}) async {
    final response =
        await _backend.fetchInvites(page: page, pageSize: pageSize);
    final invitesRaw = response['invites'];
    final invites = <InviteModel>[];

    if (invitesRaw is List) {
      for (final item in invitesRaw) {
        if (item is! Map<String, dynamic>) {
          continue;
        }
        final dto = tryParseInviteDtoJson(Map<String, dynamic>.from(item));
        if (dto == null) {
          continue;
        }
        invites.add(mapInviteDto(dto));
      }
    }

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
      closedDuplicateInviteIds:
          _parseStringList(response['closed_duplicate_invite_ids']),
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
      closedDuplicateInviteIds:
          _parseStringList(response['closed_duplicate_invite_ids']),
      acceptedAt: _parseDateTime(response['accepted_at']),
    );
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
    if (matchesRaw is! List) {
      return const <InviteContactMatch>[];
    }

    final dedupedByUserId = <String, InviteContactMatch>{};
    for (final item in matchesRaw) {
      if (item is! Map<String, dynamic>) {
        continue;
      }
      final userId = _stringOrEmpty(item['user_id']);
      final displayName = _stringOrEmpty(item['display_name']);
      if (userId.isEmpty || displayName.isEmpty) {
        continue;
      }
      dedupedByUserId.putIfAbsent(
        userId,
        () => InviteContactMatch(
          contactHash: _stringOrEmpty(item['contact_hash']),
          type: _stringOrEmpty(item['type']),
          userId: userId,
          displayName: displayName,
          avatarUrl: _stringOrNull(item['avatar_url']),
        ),
      );
    }

    return dedupedByUserId.values.toList(growable: false);
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

    final targetRef = response['target_ref'];
    final targetRefMap =
        targetRef is Map<String, dynamic> ? targetRef : const {};

    return InviteShareCodeResult(
      code: _stringOrEmpty(response['code']),
      eventId: _stringOrEmpty(targetRefMap['event_id']).isEmpty
          ? eventId
          : _stringOrEmpty(targetRefMap['event_id']),
      occurrenceId: _stringOrNull(targetRefMap['occurrence_id']),
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

    final currentMap = Map<String, List<SentInviteStatus>>.from(
        sentInvitesByEventStreamValue.value);
    final existing =
        List<SentInviteStatus>.from(currentMap[eventId] ?? const []);
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

    currentMap[eventId] = existingByRecipient.values.toList(growable: false);
    sentInvitesByEventStreamValue.addValue(currentMap);
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
  void applyInvitePushPayload(Map<String, dynamic> payload) {
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

  List<String> _parseRecipientIds(dynamic raw) {
    if (raw is! List) {
      return const <String>[];
    }

    return raw
        .whereType<Map<String, dynamic>>()
        .map((item) => _stringOrEmpty(item['receiver_user_id']))
        .where((value) => value.isNotEmpty)
        .toList(growable: false);
  }

  List<String> _parseStringList(dynamic raw) {
    if (raw is! List) {
      return const <String>[];
    }
    return raw
        .map((item) => item?.toString() ?? '')
        .where((value) => value.isNotEmpty)
        .toList(growable: false);
  }

  Map<String, int> _parseIntMap(dynamic raw) {
    if (raw is! Map) {
      return const <String, int>{};
    }
    final result = <String, int>{};
    raw.forEach((key, value) {
      final normalizedKey = key?.toString();
      if (normalizedKey == null || normalizedKey.isEmpty) {
        return;
      }
      if (value is num) {
        result[normalizedKey] = value.toInt();
        return;
      }
      final parsed = int.tryParse(value?.toString() ?? '');
      if (parsed != null) {
        result[normalizedKey] = parsed;
      }
    });
    return result;
  }

  DateTime? _parseDateTime(dynamic raw) {
    final value = raw?.toString();
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    return DateTime.tryParse(value);
  }

  String _stringOrEmpty(dynamic raw) => raw?.toString() ?? '';

  String? _stringOrNull(dynamic raw) {
    final value = raw?.toString().trim();
    if (value == null || value.isEmpty) {
      return null;
    }
    return value;
  }
}
