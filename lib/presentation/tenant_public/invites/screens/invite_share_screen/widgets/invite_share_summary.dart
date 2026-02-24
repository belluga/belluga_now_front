import 'package:belluga_now/domain/schedule/invite_status.dart';
import 'package:belluga_now/domain/schedule/sent_invite_status.dart';
import 'package:belluga_now/presentation/tenant_public/invites/screens/invite_share_screen/widgets/invite_share_overlapped_avatars.dart';
import 'package:flutter/material.dart';

class InviteShareSummary extends StatelessWidget {
  const InviteShareSummary({
    super.key,
    required this.invites,
  });

  final List<SentInviteStatus> invites;

  @override
  Widget build(BuildContext context) {
    final pending =
        invites.where((i) => i.status != InviteStatus.accepted).length;
    final confirmed = invites.length - pending;
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InviteShareOverlappedAvatars(invites: invites),
          const SizedBox(width: 12),
          Text(
            '$pending pendentes | $confirmed aceitos',
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
