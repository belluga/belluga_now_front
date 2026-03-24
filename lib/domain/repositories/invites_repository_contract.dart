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

  Future<void> refreshPendingInvites({
    int page = 1,
    int pageSize = 20,
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

  Future<InviteAcceptResult> acceptInvite(String inviteId);

  Future<InviteDeclineResult> declineInvite(String inviteId);

  Future<InviteMaterializeResult> materializeShareCode(String code) async =>
      throw UnimplementedError();

  Future<InviteModel?> previewShareCode(String code) async => null;

  Future<void> loadShareCodePreview(String code) async {
    final preview = await previewShareCode(code);
    shareCodePreviewInviteStreamValue.addValue(preview);
  }

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
