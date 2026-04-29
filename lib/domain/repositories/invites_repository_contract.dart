import 'package:belluga_now/domain/invites/invite_accept_result.dart';
import 'package:belluga_now/domain/invites/invite_account_profile_ids.dart';
import 'package:belluga_now/domain/invites/inviteable_recipient.dart';
import 'package:belluga_now/domain/invites/invite_contact_group.dart';
import 'package:belluga_now/domain/invites/invite_contact_match.dart';
import 'package:belluga_now/domain/invites/invite_decline_result.dart';
import 'package:belluga_now/domain/invites/invite_materialize_result.dart';
import 'package:belluga_now/domain/invites/invite_model.dart';
import 'package:belluga_now/domain/invites/invite_runtime_settings.dart';
import 'package:belluga_now/domain/invites/invite_share_code_result.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_contact_group_id_value.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_contact_group_name_value.dart';
import 'package:belluga_now/domain/repositories/value_objects/invites_repository_contract_values.dart';
import 'package:belluga_now/domain/schedule/event_model.dart';
import 'package:belluga_now/domain/schedule/sent_invite_status.dart';
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

  final sentInvitesByEventStreamValue = StreamValue<
      Map<InvitesRepositoryContractPrimString, List<SentInviteStatus>>>(
    defaultValue: const <InvitesRepositoryContractPrimString,
        List<SentInviteStatus>>{},
  );

  final settingsStreamValue =
      StreamValue<InviteRuntimeSettings?>(defaultValue: null);

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
  }

  void clearShareCodePreview() {
    shareCodePreviewInviteStreamValue.addValue(null);
  }

  Future<List<InviteContactMatch>> importContacts(
    InviteContacts contacts,
  );

  Future<List<InviteableRecipient>> fetchInviteableRecipients() async =>
      const <InviteableRecipient>[];

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
    InvitesRepositoryContractPrimString? occurrenceId,
    InvitesRepositoryContractPrimString? accountProfileId,
  });

  Future<void> sendInvites(
    InvitesRepositoryContractPrimString eventId,
    InviteRecipients recipients, {
    InvitesRepositoryContractPrimString? occurrenceId,
    InvitesRepositoryContractPrimString? message,
  });

  Future<List<SentInviteStatus>> getSentInvitesForEvent(
      InvitesRepositoryContractPrimString eventId);
}
