import 'dart:convert';

import 'package:belluga_now/domain/contacts/contact_model.dart';
import 'package:belluga_now/domain/invites/invite_accept_result.dart';
import 'package:belluga_now/domain/invites/invite_contact_match.dart';
import 'package:belluga_now/domain/invites/invite_decline_result.dart';
import 'package:belluga_now/domain/invites/invite_materialize_result.dart';
import 'package:belluga_now/domain/invites/invite_model.dart';
import 'package:belluga_now/domain/invites/invite_runtime_settings.dart';
import 'package:belluga_now/domain/invites/invite_share_code_result.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_accepted_at_value.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_attendance_policy_value.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_cooldowns_value.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_credited_acceptance_value.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_decline_status_value.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_declined_at_value.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_event_id_value.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_has_other_pending_value.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_id_value.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_materialization_status_value.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_message_value.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_occurrence_id_value.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_rate_limits_value.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_share_code_value.dart';
import 'package:belluga_now/domain/repositories/invites_repository_contract.dart';
import 'package:belluga_now/domain/repositories/value_objects/invites_repository_contract_values.dart';
import 'package:belluga_now/domain/schedule/invite_status.dart';
import 'package:belluga_now/domain/schedule/sent_invite_status.dart';
import 'package:belluga_now/domain/tenant/value_objects/tenant_id_value.dart';
import 'package:belluga_now/infrastructure/dal/dao/invites/invites_response_decoder.dart';
import 'package:belluga_now/infrastructure/dal/dao/laravel_backend/invites_backend/laravel_invites_backend.dart';
import 'package:belluga_now/infrastructure/repositories/push/push_payload_upsert_mixin.dart';
import 'package:belluga_now/infrastructure/services/invites_backend_contract.dart';
import 'package:crypto/crypto.dart';
import 'package:belluga_now/domain/repositories/friends_repository_contract.dart';
import 'package:value_object_pattern/domain/value_objects/date_time_value.dart';

class InvitesRepository extends InvitesRepositoryContract
    with PushPayloadUpsertMixin<InviteModel>, PushInvitePayloadMixin
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
      {InvitesRepositoryContractPrimInt? page,
      InvitesRepositoryContractPrimInt? pageSize}) async {
    final resolvedPage = page ??
        invitesRepoInt(
          1,
          defaultValue: 1,
          isRequired: true,
        );
    final resolvedPageSize = pageSize ??
        invitesRepoInt(
          20,
          defaultValue: 20,
          isRequired: true,
        );
    final response = await _backend.fetchInvites(
      page: resolvedPage.value,
      pageSize: resolvedPageSize.value,
    );
    final invitesRaw = response['invites'];
    final invites = _responseDecoder
        .decodeInviteDtos(invitesRaw)
        .map((dto) => dto.toDomain())
        .toList(growable: false);

    if (resolvedPage.value == 1) {
      pendingInvitesStreamValue.addValue(invites);
    }

    return invites;
  }

  @override
  Future<InviteRuntimeSettings> fetchSettings() async {
    final response = await _backend.fetchSettings();
    final settings = InviteRuntimeSettings(
      tenantIdValue:
          _buildTenantIdValueOrNull(_stringOrNull(response['tenant_id'])),
      limitValues: InviteRateLimitsValue(_parseIntMap(response['limits'])),
      cooldownValues: InviteCooldownsValue(_parseIntMap(response['cooldowns'])),
      overQuotaMessageValue: _buildInviteMessageValueOrNull(
          _stringOrNull(response['over_quota_message'])),
    );
    settingsStreamValue.addValue(settings);
    return settings;
  }

  @override
  Future<InviteAcceptResult> acceptInvite(
      InvitesRepositoryContractPrimString inviteId) async {
    final response = await _backend.acceptInvite(inviteId.value);
    await fetchInvites();
    return _decodeAcceptResult(response);
  }

  @override
  Future<InviteAcceptResult> acceptInviteByCode(
    InvitesRepositoryContractPrimString code,
  ) async {
    final response = await _backend.acceptShareCode(code.value);
    await fetchInvites();
    return _decodeAcceptResult(response);
  }

  InviteAcceptResult _decodeAcceptResult(Object? response) =>
      _responseDecoder.decodeAcceptResult(response);

  @override
  Future<InviteDeclineResult> declineInvite(
      InvitesRepositoryContractPrimString inviteId) async {
    final response = await _backend.declineInvite(inviteId.value);
    await fetchInvites();
    return InviteDeclineResult(
      inviteIdValue: _buildInviteIdValue(_stringOrEmpty(response['invite_id'])),
      statusValue: InviteDeclineStatusValue(_stringOrEmpty(response['status'])),
      groupHasOtherPendingValue: InviteHasOtherPendingValue(
          response['group_has_other_pending'] == true),
      declinedAtValue:
          InviteDeclinedAtValue(_parseDateTime(response['declined_at'])),
    );
  }

  @override
  Future<InviteMaterializeResult> materializeShareCode(
      InvitesRepositoryContractPrimString code) async {
    final response = await _backend.materializeShareCode(code.value);
    return InviteMaterializeResult(
      inviteIdValue: _buildInviteIdValue(_stringOrEmpty(response['invite_id'])),
      statusValue: _buildMaterializationStatusValue(
        _stringOrEmpty(response['status']),
      ),
      creditedAcceptanceValue: _buildCreditedAcceptanceValue(
        response['credited_acceptance'] == true,
      ),
      attendancePolicyValue: _buildAttendancePolicyValue(
        _resolveAttendancePolicy(response['attendance_policy']),
      ),
      acceptedAtValue: _buildAcceptedAtValue(
        _parseDateTime(response['accepted_at']),
      ),
    );
  }

  @override
  Future<InviteModel?> previewShareCode(
      InvitesRepositoryContractPrimString code) async {
    final response = await _backend.fetchShareCodePreview(code.value);
    final inviteRaw = response['invite'];
    final decoded = _responseDecoder.decodeRequiredInviteDto(
      inviteRaw,
      context: 'invite share preview',
    );
    return decoded.toDomain();
  }

  @override
  Future<List<InviteContactMatch>> importContacts(
    InviteContacts contacts,
  ) async {
    final importItems = _buildContactImportItems(contacts.items);
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
    required InvitesRepositoryContractPrimString eventId,
    InvitesRepositoryContractPrimString? occurrenceId,
    InvitesRepositoryContractPrimString? accountProfileId,
  }) async {
    final normalizedOccurrenceId = occurrenceId?.value.trim();
    final normalizedAccountProfileId = accountProfileId?.value.trim();
    final response = await _backend.createShareCode({
      'target_ref': {
        'event_id': eventId.value,
        if (normalizedOccurrenceId != null && normalizedOccurrenceId.isNotEmpty)
          'occurrence_id': normalizedOccurrenceId,
      },
      if (normalizedAccountProfileId != null &&
          normalizedAccountProfileId.isNotEmpty)
        'account_profile_id': normalizedAccountProfileId,
    });

    final targetRef = _responseDecoder.decodeShareCodeTargetRef(
      response['target_ref'],
      fallbackEventId: eventId.value,
    );

    return InviteShareCodeResult(
      codeValue: InviteShareCodeValue(_stringOrEmpty(response['code'])),
      eventIdValue: _buildInviteEventIdValue(targetRef.eventId),
      occurrenceIdValue:
          _buildInviteOccurrenceIdValueOrNull(targetRef.occurrenceId),
    );
  }

  @override
  Future<void> sendInvites(
    InvitesRepositoryContractPrimString eventId,
    InviteRecipients recipients, {
    InvitesRepositoryContractPrimString? occurrenceId,
    InvitesRepositoryContractPrimString? message,
  }) async {
    if (recipients.isEmpty) {
      return;
    }

    final normalizedOccurrenceId = occurrenceId?.value.trim();
    final normalizedMessage = message?.value.trim();
    final response = await _backend.sendInvites({
      'target_ref': {
        'event_id': eventId.value,
        if (normalizedOccurrenceId != null && normalizedOccurrenceId.isNotEmpty)
          'occurrence_id': normalizedOccurrenceId,
      },
      'recipients': recipients.items
          .map((recipient) => {'receiver_user_id': recipient.id})
          .toList(growable: false),
      if (normalizedMessage != null && normalizedMessage.isNotEmpty)
        'message': normalizedMessage,
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

    for (final recipient in recipients.items) {
      if (!acknowledgedRecipientIds.contains(recipient.id)) {
        continue;
      }
      existingByRecipient[recipient.id] = SentInviteStatus(
        friend: recipient,
        status: InviteStatus.pending,
        sentAtValue: existingByRecipient[recipient.id]?.sentAtValue ??
            (DateTimeValue()..parse(now.toIso8601String())),
        respondedAtValue: existingByRecipient[recipient.id]?.respondedAtValue,
      );
    }

    sentInvitesByEventStreamValue.addValue({
      ...currentByEvent,
      eventId: existingByRecipient.values.toList(growable: false),
    });
  }

  @override
  Future<List<SentInviteStatus>> getSentInvitesForEvent(
      InvitesRepositoryContractPrimString eventId) async {
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
    List<ContactModel> contacts,
  ) {
    final seen = <String>{};
    final items = <Map<String, String>>[];

    for (final contact in contacts) {
      for (final email in contact.emails) {
        final normalized = email.value.trim().toLowerCase();
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
        final normalized = phone.value.replaceAll(RegExp(r'\D+'), '');
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

  String _resolveAttendancePolicy(Object? rawValue) {
    final value = _stringOrEmpty(rawValue);
    if (value.isEmpty) {
      return 'free_confirmation_only';
    }
    return value;
  }

  InviteIdValue _buildInviteIdValue(String value) {
    final inviteIdValue = InviteIdValue()..parse(value);
    return inviteIdValue;
  }

  InviteMaterializationStatusValue _buildMaterializationStatusValue(
    String value,
  ) {
    final statusValue = InviteMaterializationStatusValue()..parse(value);
    return statusValue;
  }

  InviteCreditedAcceptanceValue _buildCreditedAcceptanceValue(bool value) {
    final creditedValue = InviteCreditedAcceptanceValue()
      ..parse(value.toString());
    return creditedValue;
  }

  InviteAttendancePolicyValue _buildAttendancePolicyValue(String value) {
    final attendancePolicyValue = InviteAttendancePolicyValue()..parse(value);
    return attendancePolicyValue;
  }

  InviteAcceptedAtValue _buildAcceptedAtValue(DateTime? value) {
    final acceptedAtValue = InviteAcceptedAtValue()
      ..parse(value?.toIso8601String());
    return acceptedAtValue;
  }

  TenantIdValue? _buildTenantIdValueOrNull(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }
    final tenantIdValue = TenantIdValue()..parse(value);
    return tenantIdValue;
  }

  InviteMessageValue? _buildInviteMessageValueOrNull(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }
    final messageValue = InviteMessageValue()..parse(value);
    return messageValue;
  }

  InviteEventIdValue _buildInviteEventIdValue(String value) {
    final eventIdValue = InviteEventIdValue()..parse(value);
    return eventIdValue;
  }

  InviteOccurrenceIdValue? _buildInviteOccurrenceIdValueOrNull(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    final occurrenceIdValue = InviteOccurrenceIdValue()..parse(value);
    return occurrenceIdValue;
  }
}
