import 'package:belluga_now/domain/invites/invite_model.dart';
import 'package:belluga_now/application/icons/boora_icons.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

class InviteShareFooter extends StatelessWidget {
  const InviteShareFooter({
    super.key,
    required this.invite,
  });

  final InviteModel invite;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.purple.withValues(alpha: 0.12),
            child: const Icon(
              BooraIcons.invite_solid,
              color: Colors.purple,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Compartilhar convite',
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(
                  'Bora? ${invite.eventName} em ${invite.location}.',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          FilledButton.icon(
            onPressed: () {
              final text =
                  'Bora? ${invite.eventName} em ${invite.location} no dia ${invite.eventDateTime.toLocal()}.'
                  '\nDetalhes: https://belluga.now/invite/${invite.id}';
              SharePlus.instance.share(
                ShareParams(
                  text: text,
                  subject: 'Convite Belluga Now',
                ),
              );
            },
            icon: const Icon(Icons.share),
            label: const Text('Compartilhar'),
          ),
        ],
      ),
    );
  }
}
