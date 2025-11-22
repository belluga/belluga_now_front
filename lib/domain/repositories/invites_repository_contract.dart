import 'package:belluga_now/domain/invites/invite_model.dart';
import 'package:belluga_now/domain/schedule/sent_invite_status.dart';
import 'package:stream_value/core/stream_value.dart';

abstract class InvitesRepositoryContract {
  final pendingInvitesStreamValue =
      StreamValue<List<InviteModel>>(defaultValue: const []);

  final sentInvitesByEventStreamValue =
      StreamValue<Map<String, List<SentInviteStatus>>>(defaultValue: const {});

  bool get hasPendingInvites => pendingInvitesStreamValue.value.isNotEmpty;

  Future<void> init() async {
    final _invites = await fetchInvites();
    pendingInvitesStreamValue.addValue(_invites);
  }

  Future<List<InviteModel>> fetchInvites();

  /// Send invites to friends for a specific event
  Future<void> sendInvites(String eventSlug, List<String> friendIds);

  /// Get all sent invites for a specific event
  Future<List<SentInviteStatus>> getSentInvitesForEvent(String eventSlug);
}
