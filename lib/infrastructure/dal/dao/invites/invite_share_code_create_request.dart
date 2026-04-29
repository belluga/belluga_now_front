import 'package:belluga_now/infrastructure/dal/dao/invites/invite_target_ref_request.dart';

class InviteShareCodeCreateRequest {
  const InviteShareCodeCreateRequest({
    required this.targetRef,
    this.accountProfileId,
  });

  final InviteTargetRefRequest targetRef;
  final String? accountProfileId;

  Map<String, dynamic> toJson() {
    final normalizedAccountProfileId = accountProfileId?.trim();
    return {
      'target_ref': targetRef.toJson(),
      if (normalizedAccountProfileId != null &&
          normalizedAccountProfileId.isNotEmpty)
        'account_profile_id': normalizedAccountProfileId,
    };
  }
}
