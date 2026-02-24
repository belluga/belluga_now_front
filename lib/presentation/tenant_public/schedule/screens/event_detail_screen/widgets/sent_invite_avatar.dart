import 'package:belluga_now/domain/schedule/sent_invite_status.dart';
import 'package:flutter/material.dart';
import 'package:belluga_now/presentation/tenant_public/schedule/screens/event_detail_screen/widgets/sent_invite_status_badge.dart';

/// Avatar with status badge for sent invites
class SentInviteAvatar extends StatelessWidget {
  const SentInviteAvatar({
    super.key,
    required this.inviteStatus,
    this.size = 40,
  });

  final SentInviteStatus inviteStatus;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size + 8, // Extra space for badge
      height: size + 8,
      child: Stack(
        children: [
          Center(
            child: CircleAvatar(
              radius: size / 2,
              backgroundImage: inviteStatus.friend.avatarUrl != null
                  ? NetworkImage(inviteStatus.friend.avatarUrl!)
                  : null,
              child: inviteStatus.friend.avatarUrl == null
                  ? Text(
                      inviteStatus.friend.displayName.isNotEmpty
                          ? inviteStatus.friend.displayName[0].toUpperCase()
                          : '?',
                      style: TextStyle(fontSize: size * 0.4),
                    )
                  : null,
            ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: SentInviteStatusBadge(
              status: inviteStatus.status,
              size: size,
            ),
          ),
        ],
      ),
    );
  }
}
