import 'package:belluga_now/infrastructure/dal/dao/invites/invite_send_recipient_request.dart';
import 'package:belluga_now/infrastructure/dal/dao/invites/invite_target_ref_request.dart';

class InviteSendRequest {
  const InviteSendRequest({
    required this.targetRef,
    required this.recipients,
    this.message,
  });

  final InviteTargetRefRequest targetRef;
  final List<InviteSendRecipientRequest> recipients;
  final String? message;

  Map<String, dynamic> toJson() {
    final normalizedMessage = message?.trim();
    return {
      'target_ref': targetRef.toJson(),
      'recipients': recipients
          .map((recipient) => recipient.toJson())
          .toList(growable: false),
      if (normalizedMessage != null && normalizedMessage.isNotEmpty)
        'message': normalizedMessage,
    };
  }
}
