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
    required this.isSending,
  });

  final InviteFriendResume friend;
  final InviteStatus? status;
  final VoidCallback? onInvite;
  final bool isPlaceholder;
  final bool isSending;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtitle = friend.matchLabel.isNotEmpty
        ? friend.matchLabel
        : 'Convide para viver o rolê juntos';
    final avatarUrl = friend.avatarValue.value?.toString();

    final (label, enabled) = _cta(status, isSending: isSending);
    final disabled = !enabled || isPlaceholder || isSending;
    final backgroundColor = disabled
        ? theme.colorScheme.surfaceContainerHighest
        : theme.colorScheme.primary;
    final foregroundColor = disabled
        ? theme.colorScheme.onSurfaceVariant
        : theme.colorScheme.onPrimary;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                  ? NetworkImage(avatarUrl)
                  : null,
              child: avatarUrl == null || avatarUrl.isEmpty
                  ? Text(
                      friend.name.isNotEmpty
                          ? friend.name[0].toUpperCase()
                          : '?',
                    )
                  : null,
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
                backgroundColor: backgroundColor,
                foregroundColor: foregroundColor,
                disabledBackgroundColor:
                    theme.colorScheme.surfaceContainerHighest,
                disabledForegroundColor: theme.colorScheme.onSurfaceVariant,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: isSending
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox.square(
                          dimension: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: foregroundColor,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          label,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ],
                    )
                  : Text(
                      label,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  (String, bool) _cta(InviteStatus? status, {required bool isSending}) {
    if (isSending) {
      return ('Enviando...', false);
    }
    switch (status) {
      case InviteStatus.accepted:
        return ('Convite Aceito!', false);
      case InviteStatus.pending:
      case InviteStatus.viewed:
        return ('Convidado', false);
      case InviteStatus.declined:
        return ('Convite recusado', false);
      case InviteStatus.expired:
        return ('Convite expirado', false);
      case InviteStatus.superseded:
        return ('Convidado', false);
      case InviteStatus.suppressed:
        return ('Indisponível', false);
      case null:
        return ('Convidar', true);
    }
  }
}
