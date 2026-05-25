import 'package:belluga_now/domain/invites/inviteable_recipient.dart';
import 'package:stream_value/core/stream_value.dart';

abstract class InviteablesRepositoryContract {
  final inviteableRecipientsStreamValue =
      StreamValue<List<InviteableRecipient>?>(defaultValue: null);

  Future<List<InviteableRecipient>> fetchInviteableRecipients() async =>
      const <InviteableRecipient>[];

  Future<void> refreshInviteableRecipients() async {
    final recipients = await fetchInviteableRecipients();
    inviteableRecipientsStreamValue.addValue(recipients);
  }
}
