import 'package:belluga_now/domain/schedule/sent_invite_status.dart';
import 'package:belluga_now/presentation/tenant/invites/screens/invite_share_screen/widgets/invite_share_plus_avatar.dart';
import 'package:belluga_now/presentation/tenant/invites/screens/invite_share_screen/widgets/invite_share_avatar.dart';
import 'package:flutter/material.dart';

class InviteShareOverlappedAvatars extends StatelessWidget {
  const InviteShareOverlappedAvatars({
    super.key,
    required this.invites,
  });

  final List<SentInviteStatus> invites;

  @override
  Widget build(BuildContext context) {
    if (invites.isEmpty) {
      return const InviteSharePlusAvatar(0, isEmptySlot: true);
    }

    final cappedCount = invites.length > 3 ? 3 : invites.length;
    final displayInvites = invites.take(cappedCount).toList();
    final remaining = invites.length - cappedCount;

    final items = <Widget>[];
    for (var i = 0; i < displayInvites.length; i++) {
      items.add(Positioned(
        left: i * 18.0,
        child: InviteShareAvatar(invite: displayInvites[i]),
      ));
    }

    items.add(Positioned(
      left: cappedCount * 18.0,
      child: remaining > 0
          ? InviteSharePlusAvatar(remaining)
          : const InviteSharePlusAvatar(0, isEmptySlot: true),
    ));

    final totalItems = cappedCount + 1;
    final width = totalItems * 18.0 + 16.0;

    return SizedBox(
      width: width,
      height: 36,
      child: Stack(
        clipBehavior: Clip.none,
        children: items,
      ),
    );
  }
}
