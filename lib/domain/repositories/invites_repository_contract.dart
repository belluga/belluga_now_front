import 'package:belluga_now/domain/contacts/contact_model.dart';
import 'package:belluga_now/domain/invites/invite_accept_result.dart';
import 'package:belluga_now/domain/invites/invite_contact_match.dart';
import 'package:belluga_now/domain/invites/invite_decline_result.dart';
import 'package:belluga_now/domain/invites/invite_model.dart';
import 'package:belluga_now/domain/invites/invite_runtime_settings.dart';
import 'package:belluga_now/domain/invites/invite_share_code_result.dart';
import 'package:belluga_now/domain/schedule/sent_invite_status.dart';
import 'package:belluga_now/domain/schedule/friend_resume.dart';
import 'package:stream_value/core/stream_value.dart';

abstract class InvitesRepositoryContract {
  final pendingInvitesStreamValue =
      StreamValue<List<InviteModel>>(defaultValue: const <InviteModel>[]);

  final sentInvitesByEventStreamValue =
      StreamValue<Map<String, List<SentInviteStatus>>>(
    defaultValue: const <String, List<SentInviteStatus>>{},
  );

  final settingsStreamValue =
      StreamValue<InviteRuntimeSettings?>(defaultValue: null);

  bool get hasPendingInvites => pendingInvitesStreamValue.value.isNotEmpty;

  Future<void> init() async {
    await fetchSettings();
    final invites = await fetchInvites();
    pendingInvitesStreamValue.addValue(invites);
  }

  Future<List<InviteModel>> fetchInvites({int page, int pageSize});

  Future<InviteRuntimeSettings> fetchSettings();

  Future<InviteAcceptResult> acceptInvite(String inviteId);

  Future<InviteDeclineResult> declineInvite(String inviteId);

  Future<InviteAcceptResult> acceptShareCode(String code);

  Future<List<InviteContactMatch>> importContacts(List<ContactModel> contacts);

  Future<InviteShareCodeResult> createShareCode({
    required String eventId,
    String? occurrenceId,
    String? accountProfileId,
  });

  Future<void> sendInvites(
    String eventId,
    List<EventFriendResume> recipients, {
    String? occurrenceId,
    String? message,
  });

  Future<List<SentInviteStatus>> getSentInvitesForEvent(String eventId);
}
