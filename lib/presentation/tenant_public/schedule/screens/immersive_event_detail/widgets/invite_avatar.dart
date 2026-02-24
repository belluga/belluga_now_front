import 'package:belluga_now/domain/schedule/invite_status.dart';
import 'package:belluga_now/domain/schedule/sent_invite_status.dart';
import 'package:flutter/material.dart';

class InviteAvatar extends StatelessWidget {
  const InviteAvatar({super.key, required this.invite});

  final SentInviteStatus invite;

  @override
  Widget build(BuildContext context) {
    final badge = invite.status == InviteStatus.accepted
        ? Icons.check_circle
        : Icons.hourglass_bottom;
    final badgeColor =
        invite.status == InviteStatus.accepted ? Colors.green : Colors.orange;

    final url = invite.friend.avatarUrl;
    final display = invite.friend.displayName;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        CircleAvatar(
          radius: 16,
          backgroundImage:
              url != null && url.isNotEmpty ? NetworkImage(url) : null,
          child: (url == null || url.isEmpty)
              ? Text(
                  display.isNotEmpty ? display[0].toUpperCase() : '?',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                )
              : null,
        ),
        Positioned(
          bottom: -2,
          right: -2,
          child: Container(
            padding: const EdgeInsets.all(2),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
            child: Icon(
              badge,
              color: badgeColor,
              size: 12,
            ),
          ),
        ),
      ],
    );
  }
}
