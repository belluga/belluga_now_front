import 'package:belluga_now/domain/contacts/contact_model.dart';
import 'package:belluga_now/domain/invites/invite_accept_result.dart';
import 'package:belluga_now/domain/invites/invite_contact_match.dart';
import 'package:belluga_now/domain/invites/invite_decline_result.dart';
import 'package:belluga_now/domain/invites/invite_materialize_result.dart';
import 'package:belluga_now/domain/invites/invite_model.dart';
import 'package:belluga_now/domain/invites/invite_runtime_settings.dart';
import 'package:belluga_now/domain/invites/invite_share_code_result.dart';
import 'package:belluga_now/domain/schedule/event_model.dart';
import 'package:belluga_now/domain/schedule/sent_invite_status.dart';
import 'package:belluga_now/domain/schedule/friend_resume.dart';
import 'package:stream_value/core/stream_value.dart';

typedef InvitesRepositoryContractPrimString = String;
typedef InvitesRepositoryContractPrimInt = int;
typedef InvitesRepositoryContractPrimBool = bool;
typedef InvitesRepositoryContractPrimDouble = double;
typedef InvitesRepositoryContractPrimDateTime = DateTime;
typedef InvitesRepositoryContractPrimDynamic = dynamic;

abstract class InvitesRepositoryContract {
  final pendingInvitesStreamValue =
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

  InvitesRepositoryContractPrimBool get hasPendingInvites =>
      pendingInvitesStreamValue.value.isNotEmpty;

  Future<void> init() async {
    await fetchSettings();
    final invites = await fetchInvites();
    pendingInvitesStreamValue.addValue(invites);
  }

  Future<List<InviteModel>> fetchInvites(
      {InvitesRepositoryContractPrimInt page,
      InvitesRepositoryContractPrimInt pageSize});

  Future<void> refreshPendingInvites({
    InvitesRepositoryContractPrimInt page = 1,
    InvitesRepositoryContractPrimInt pageSize = 20,
  }) async {
    final invites = await fetchInvites(
      page: page,
      pageSize: pageSize,
    );
    if (page == 1) {
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

  Future<List<InviteContactMatch>> importContacts(List<ContactModel> contacts);

  Future<InviteShareCodeResult> createShareCode({
    required InvitesRepositoryContractPrimString eventId,
    InvitesRepositoryContractPrimString? occurrenceId,
    InvitesRepositoryContractPrimString? accountProfileId,
  });

  Future<void> sendInvites(
    InvitesRepositoryContractPrimString eventId,
    List<EventFriendResume> recipients, {
    InvitesRepositoryContractPrimString? occurrenceId,
    InvitesRepositoryContractPrimString? message,
  });

  Future<List<SentInviteStatus>> getSentInvitesForEvent(
      InvitesRepositoryContractPrimString eventId);
}
