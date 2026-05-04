import 'package:belluga_now/presentation/tenant_public/invites/screens/invite_share_screen/controllers/invite_external_contact_share_target.dart';
import 'package:flutter/material.dart';

class InviteExternalContactCard extends StatelessWidget {
  const InviteExternalContactCard({
    super.key,
    required this.target,
    required this.onShare,
  });

  final InviteExternalContactShareTarget target;
  final VoidCallback? onShare;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: colorScheme.secondaryContainer,
              foregroundColor: colorScheme.onSecondaryContainer,
              child: Icon(
                target.hasPhone
                    ? Icons.chat_bubble_outline
                    : Icons.ios_share_outlined,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    target.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (target.subtitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      target.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            FilledButton.tonalIcon(
              onPressed: onShare,
              icon: Icon(
                target.hasPhone
                    ? Icons.chat_bubble_outline
                    : Icons.ios_share_outlined,
                size: 18,
              ),
              label: Text(target.hasPhone ? 'WhatsApp' : 'Compartilhar'),
            ),
          ],
        ),
      ),
    );
  }
}
