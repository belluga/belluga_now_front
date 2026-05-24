import 'package:belluga_now/domain/schedule/invite_status.dart';
import 'package:belluga_now/domain/schedule/sent_invite_summary.dart';
import 'package:belluga_now/presentation/tenant_public/invites/screens/invite_share_screen/widgets/invite_share_overlapped_avatars.dart';
import 'package:flutter/material.dart';

class InviteShareSummary extends StatelessWidget {
  const InviteShareSummary({
    super.key,
    required this.summary,
  });

  final SentInviteSummary summary;

  @override
  Widget build(BuildContext context) {
    final visibleInvites = summary.preview
        .where((invite) => !invite.status.isHiddenSentStatus)
        .toList();
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InviteShareOverlappedAvatars(invites: visibleInvites),
          const SizedBox(width: 12),
          Text(
            '${summary.pending} pendentes | ${summary.accepted} aceitos',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
