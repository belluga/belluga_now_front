import 'package:belluga_now/presentation/tenant_public/invites/screens/invite_share_screen/controllers/invite_external_contact_share_target.dart';
import 'package:flutter/material.dart';

class InviteExternalContactsSheet extends StatelessWidget {
  const InviteExternalContactsSheet({
    super.key,
    required this.targets,
    required this.onShare,
  });

  final List<InviteExternalContactShareTarget> targets;
  final ValueChanged<InviteExternalContactShareTarget> onShare;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Compartilhar externamente',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.55,
              ),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: targets.length,
                separatorBuilder: (_, __) => Divider(
                  height: 1,
                  color: colorScheme.outlineVariant,
                ),
                itemBuilder: (context, index) {
                  final target = targets[index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: colorScheme.secondaryContainer,
                      foregroundColor: colorScheme.onSecondaryContainer,
                      child: const Icon(Icons.person_outline),
                    ),
                    title: Text(
                      target.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: target.subtitle.isEmpty
                        ? null
                        : Text(
                            target.subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                    trailing: FilledButton.tonal(
                      onPressed: () {
                        ModalRoute.of(context)?.navigator?.maybePop();
                        onShare(target);
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            target.hasPhone
                                ? Icons.chat_bubble_outline
                                : Icons.ios_share,
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Text(target.hasPhone ? 'WhatsApp' : 'Compartilhar'),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
