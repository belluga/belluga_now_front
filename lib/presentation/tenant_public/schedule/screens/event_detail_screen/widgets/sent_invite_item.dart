import 'package:belluga_now/domain/schedule/sent_invite_status.dart';
import 'package:belluga_now/presentation/tenant/schedule/screens/event_detail_screen/widgets/sent_invite_avatar.dart';
import 'package:flutter/material.dart';

class SentInviteItem extends StatelessWidget {
  const SentInviteItem({
    super.key,
    required this.inviteStatus,
  });

  final SentInviteStatus inviteStatus;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      children: [
        SentInviteAvatar(inviteStatus: inviteStatus),
        const SizedBox(height: 4),
        Text(
          inviteStatus.friend.displayName.split(' ').first,
          style: textTheme.labelSmall,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
