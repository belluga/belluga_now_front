import 'package:belluga_now/domain/invites/projections/friend_resume.dart';
import 'package:belluga_now/domain/schedule/invite_status.dart';
import 'package:flutter/material.dart';

class InviteShareFriendCard extends StatelessWidget {
  const InviteShareFriendCard({
    super.key,
    required this.friend,
    required this.status,
    required this.onInvite,
    required this.isPlaceholder,
  });

  final InviteFriendResume friend;
  final InviteStatus? status;
  final VoidCallback? onInvite;
  final bool isPlaceholder;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtitle = friend.matchLabel.isNotEmpty
        ? friend.matchLabel
        : 'Convide para viver o rolê juntos';

    final (label, color, enabled) = _cta(status);
    final disabled = !enabled || isPlaceholder;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundImage: NetworkImage(friend.avatarUri.toString()),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    friend.name,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: disabled ? null : onInvite,
              style: ElevatedButton.styleFrom(
                backgroundColor: disabled
                    ? theme.colorScheme.surfaceContainerHighest
                    : color,
                foregroundColor:
                    disabled ? theme.colorScheme.onSurface : Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }

  (String, Color, bool) _cta(InviteStatus? status) {
    switch (status) {
      case InviteStatus.accepted:
        return ('Convite Aceito!', Colors.green, false);
      case InviteStatus.pending:
      case InviteStatus.viewed:
        return ('Convidado', Colors.orange, false);
      default:
        return ('Convidar', Colors.blue, true);
    }
  }
}
