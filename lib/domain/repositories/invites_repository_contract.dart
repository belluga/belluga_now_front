import 'package:belluga_now/domain/invites/invite_accept_result.dart';
import 'package:belluga_now/domain/invites/invite_account_profile_ids.dart';
import 'package:belluga_now/domain/invites/inviteable_recipient.dart';
import 'package:belluga_now/domain/invites/invite_contact_group.dart';
import 'package:belluga_now/domain/invites/invite_contact_match.dart';
import 'package:belluga_now/domain/invites/invite_decline_result.dart';
import 'package:belluga_now/domain/invites/invite_materialize_result.dart';
import 'package:belluga_now/domain/invites/invite_model.dart';
import 'package:belluga_now/domain/invites/invite_runtime_settings.dart';
import 'package:belluga_now/domain/invites/invite_share_session_context.dart';
import 'package:belluga_now/domain/invites/invite_share_code_result.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_contact_group_id_value.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_contact_group_name_value.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_share_code_value.dart';
import 'package:belluga_now/domain/repositories/value_objects/invites_repository_contract_values.dart';
import 'package:belluga_now/domain/schedule/event_model.dart';
import 'package:belluga_now/domain/schedule/sent_invite_status.dart';
import 'package:belluga_now/domain/schedule/sent_invite_summary.dart';
import 'package:stream_value/core/stream_value.dart';

export 'package:belluga_now/domain/repositories/value_objects/invites_repository_contract_values.dart';

typedef InvitesRepositoryContractPrimString
    = InvitesRepositoryContractTextValue;
typedef InvitesRepositoryContractPrimInt = InvitesRepositoryContractIntValue;
typedef InvitesRepositoryContractPrimBool = InvitesRepositoryContractBoolValue;

abstract class InvitesRepositoryContract {
  final pendingInvitesStreamValue =
      StreamValue<List<InviteModel>>(defaultValue: const <InviteModel>[]);
  final inviteFlowPendingInvitesStreamValue =
      StreamValue<List<InviteModel>>(defaultValue: const <InviteModel>[]);
  final inviteFlowDisplayInvitesStreamValue =
      StreamValue<List<InviteModel>>(defaultValue: const <InviteModel>[]);
  final immersiveSelectedEventStreamValue =
      StreamValue<EventModel?>(defaultValue: null);
  final immersiveReceivedInvitesStreamValue =
      StreamValue<List<InviteModel>>(defaultValue: const <InviteModel>[]);
  final shareCodePreviewInviteStreamValue =
      StreamValue<InviteModel?>(defaultValue: null);
  final shareCodeSessionContextStreamValue =
      StreamValue<InviteShareSessionContext?>(defaultValue: null);

  final sentInvitesByOccurrenceStreamValue = StreamValue<
      Map<InvitesRepositoryContractPrimString, List<SentInviteStatus>>>(
    defaultValue: const <InvitesRepositoryContractPrimString,
        List<SentInviteStatus>>{},
  );
  final sentInviteSummariesByOccurrenceStreamValue =
      StreamValue<Map<InvitesRepositoryContractPrimString, SentInviteSummary>>(
    defaultValue: const <InvitesRepositoryContractPrimString,
        SentInviteSummary>{},
  );

  final settingsStreamValue =
      StreamValue<InviteRuntimeSettings?>(defaultValue: null);
  final inviteableRecipientsStreamValue =
      StreamValue<List<InviteableRecipient>?>(defaultValue: null);
  final importedContactMatchesStreamValue =
      StreamValue<List<InviteContactMatch>?>(defaultValue: null);

  InvitesRepositoryContractPrimBool get hasPendingInvites => invitesRepoBool(
        pendingInvitesStreamValue.value.isNotEmpty,
        defaultValue: false,
        isRequired: true,
      );

  Future<void> init() async {
    await fetchSettings();
    final invites = await fetchInvites();
    pendingInvitesStreamValue.addValue(invites);
  }

  void setInviteFlowPendingInvites(List<InviteModel> invites) {
    inviteFlowPendingInvitesStreamValue.addValue(
      List<InviteModel>.unmodifiable(invites),
    );
  }

  void setInviteFlowDisplayInvites(List<InviteModel> invites) {
    inviteFlowDisplayInvitesStreamValue.addValue(
      List<InviteModel>.unmodifiable(invites),
    );
  }

  void clearInviteFlowState() {
    setInviteFlowPendingInvites(const <InviteModel>[]);
    setInviteFlowDisplayInvites(const <InviteModel>[]);
  }

  void setImmersiveSelectedEvent(EventModel? event) {
    immersiveSelectedEventStreamValue.addValue(event);
  }

  void setImmersiveReceivedInvites(List<InviteModel> invites) {
    immersiveReceivedInvitesStreamValue.addValue(
      List<InviteModel>.unmodifiable(invites),
    );
  }

  void clearImmersiveDetailState() {
    immersiveSelectedEventStreamValue.addValue(null);
    immersiveReceivedInvitesStreamValue.addValue(const <InviteModel>[]);
  }

  Future<List<InviteModel>> fetchInvites(
      {InvitesRepositoryContractPrimInt? page,
      InvitesRepositoryContractPrimInt? pageSize});

  Future<void> refreshPendingInvites({
    InvitesRepositoryContractPrimInt? page,
    InvitesRepositoryContractPrimInt? pageSize,
  }) async {
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
    final invites = await fetchInvites(
      page: resolvedPage,
      pageSize: resolvedPageSize,
    );
    if (resolvedPage.value == 1) {
      pendingInvitesStreamValue.addValue(invites);
    }
  }

  Future<InviteRuntimeSettings> fetchSettings();

  Future<InviteAcceptResult> acceptInvite(
      InvitesRepositoryContractPrimString inviteId);

  Future<InviteDeclineResult> declineInvite(
      InvitesRepositoryContractPrimString inviteId);

  Future<InviteAcceptResult> acceptInviteByCode(
      InvitesRepositoryContractPrimString code);

  Future<InviteMaterializeResult> materializeShareCode(
          InvitesRepositoryContractPrimString code) async =>
      throw UnimplementedError();

  Future<InviteModel?> previewShareCode(
          InvitesRepositoryContractPrimString code) async =>
      null;

  Future<void> loadShareCodePreview(
      InvitesRepositoryContractPrimString code) async {
    final preview = await previewShareCode(code);
    shareCodePreviewInviteStreamValue.addValue(preview);
    if (preview == null) {
      clearShareCodeSessionContext(code: code);
      return;
    }
    setShareCodeSessionContext(code: code, invite: preview);
  }

  void clearShareCodePreview() {
    shareCodePreviewInviteStreamValue.addValue(null);
    clearShareCodeSessionContext();
  }

  void setShareCodeSessionContext({
    required InvitesRepositoryContractPrimString code,
    required InviteModel invite,
  }) {
    final normalizedCode = code.value.trim();
    final normalizedOccurrenceId = invite.occurrenceId?.trim() ?? '';
    if (normalizedCode.isEmpty || normalizedOccurrenceId.isEmpty) {
      clearShareCodeSessionContext(code: code);
      return;
    }
    shareCodeSessionContextStreamValue.addValue(
      InviteShareSessionContext(
        shareCodeValue: InviteShareCodeValue(normalizedCode),
        invite: invite,
      ),
    );
  }

  void clearShareCodeSessionContext({
    InvitesRepositoryContractPrimString? code,
    InvitesRepositoryContractPrimString? occurrenceId,
  }) {
    final current = shareCodeSessionContextStreamValue.value;
    if (current == null) {
      return;
    }
    final codeFilter = code?.value.trim();
    if (codeFilter != null &&
        codeFilter.isNotEmpty &&
        current.shareCode != codeFilter) {
      return;
    }
    final occurrenceFilter = occurrenceId?.value.trim();
    if (occurrenceFilter != null &&
        occurrenceFilter.isNotEmpty &&
        (current.occurrenceId ?? '') != occurrenceFilter) {
      return;
    }
    shareCodeSessionContextStreamValue.addValue(null);
  }

  Future<List<InviteContactMatch>> importContacts(
    InviteContacts contacts,
  );

  Future<void> refreshImportedContactMatches(InviteContacts contacts) async {
    final matches = await importContacts(contacts);
    importedContactMatchesStreamValue.addValue(matches);
  }

  Future<List<InviteContactMatch>?> hydrateImportedContactMatchesFromCache(
    InviteContacts contacts,
  ) async =>
      null;

  Future<List<InviteableRecipient>> fetchInviteableRecipients() async =>
      const <InviteableRecipient>[];

  Future<void> refreshInviteableRecipients() async {
    final recipients = await fetchInviteableRecipients();
    inviteableRecipientsStreamValue.addValue(recipients);
  }

  StreamValue<List<InviteableRecipient>?>
      inviteableRecipientsStreamValueForOccurrence(
    InvitesRepositoryContractPrimString occurrenceId,
  ) =>
          throw UnimplementedError(
            'Occurrence-scoped inviteables require repository slot storage.',
          );

  void setInviteableRecipientsForOccurrence({
    required InvitesRepositoryContractPrimString occurrenceId,
    required List<InviteableRecipient> recipients,
  }) {
    inviteableRecipientsStreamValueForOccurrence(occurrenceId).addValue(
      List<InviteableRecipient>.unmodifiable(recipients),
    );
  }

  List<InviteableRecipient>? inviteableRecipientsForOccurrence(
    InvitesRepositoryContractPrimString occurrenceId,
  ) =>
      inviteableRecipientsStreamValueForOccurrence(occurrenceId).value;

  Future<List<InviteableRecipient>> fetchInviteableRecipientsForOccurrence({
    required InvitesRepositoryContractPrimString occurrenceId,
    InvitesRepositoryContractPrimString? eventId,
    InvitesRepositoryContractPrimInt? page,
    InvitesRepositoryContractPrimInt? pageSize,
  }) async =>
      fetchInviteableRecipients();

  Future<void> refreshInviteableRecipientsForOccurrence({
    required InvitesRepositoryContractPrimString occurrenceId,
    InvitesRepositoryContractPrimString? eventId,
    InvitesRepositoryContractPrimInt? page,
    InvitesRepositoryContractPrimInt? pageSize,
  }) async {
    final recipients = await fetchInviteableRecipientsForOccurrence(
      occurrenceId: occurrenceId,
      eventId: eventId,
      page: page,
      pageSize: pageSize,
    );
    setInviteableRecipientsForOccurrence(
      occurrenceId: occurrenceId,
      recipients: recipients,
    );
  }

  Future<List<InviteContactGroup>> fetchContactGroups() async =>
      const <InviteContactGroup>[];

  Future<InviteContactGroup?> createContactGroup({
    required InviteContactGroupNameValue nameValue,
    required InviteAccountProfileIds recipientAccountProfileIds,
  }) async =>
      null;

  Future<InviteContactGroup?> updateContactGroup({
    required InviteContactGroupIdValue groupIdValue,
    InviteContactGroupNameValue? nameValue,
    InviteAccountProfileIds? recipientAccountProfileIds,
  }) async =>
      null;

  Future<void> deleteContactGroup(
      InviteContactGroupIdValue groupIdValue) async {}

  Future<InviteShareCodeResult> createShareCode({
    required InvitesRepositoryContractPrimString eventId,
    required InvitesRepositoryContractPrimString occurrenceId,
    InvitesRepositoryContractPrimString? accountProfileId,
  });

  /// Sends direct invites for the occurrence.
  ///
  /// Implementations that receive created/already-invited acknowledgements must
  /// publish those statuses to [sentInvitesByOccurrenceStreamValue] before this
  /// future completes. Presentation controllers use that stream as the
  /// synchronous acknowledgement source for optimistic UI.
  Future<void> sendInvites(
    InvitesRepositoryContractPrimString eventId,
    InviteRecipients recipients, {
    required InvitesRepositoryContractPrimString occurrenceId,
    InvitesRepositoryContractPrimString? message,
  });

  Future<List<SentInviteStatus>> getSentInvitesForOccurrence(
      InvitesRepositoryContractPrimString occurrenceId);

  Future<List<SentInviteStatus>> refreshSentInvitesForOccurrence({
    required InvitesRepositoryContractPrimString occurrenceId,
    InvitesRepositoryContractPrimString? eventId,
    Iterable<InvitesRepositoryContractPrimString> recipientAccountProfileIds =
        const <InvitesRepositoryContractPrimString>[],
  }) async =>
      getSentInvitesForOccurrence(occurrenceId);

  Future<SentInviteSummary> refreshSentInviteSummaryForOccurrence({
    required InvitesRepositoryContractPrimString occurrenceId,
    InvitesRepositoryContractPrimString? eventId,
    InvitesRepositoryContractPrimInt? previewLimit,
  }) async =>
      SentInviteSummary.empty();
}
