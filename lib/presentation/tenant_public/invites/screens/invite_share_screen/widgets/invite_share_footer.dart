import 'package:belluga_now/domain/invites/invite_model.dart';
import 'package:belluga_now/application/icons/boora_icons.dart';
import 'package:belluga_now/application/time/timezone_converter.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

class InviteShareFooter extends StatelessWidget {
  const InviteShareFooter({
    super.key,
    required this.invite,
    required this.shareUri,
    required this.isGeneratingShareCode,
    required this.onRetryShareCode,
  });

  final InviteModel invite;
  final Uri? shareUri;
  final bool isGeneratingShareCode;
  final VoidCallback onRetryShareCode;

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
            color: theme.shadowColor.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: theme.colorScheme.secondaryContainer,
            foregroundColor: theme.colorScheme.onSecondaryContainer,
            child: const Icon(
              BooraIcons.inviteSolid,
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
            onPressed: isGeneratingShareCode
                ? null
                : shareUri == null
                    ? onRetryShareCode
                    : () {
                        final localEventDate =
                            TimezoneConverter.utcToLocal(invite.eventDateTime);
                        final text =
                            'Bora? ${invite.eventName} em ${invite.location} no dia $localEventDate.'
                            '\nDetalhes: $shareUri';
                        SharePlus.instance.share(
                          ShareParams(
                            text: text,
                            subject: 'Convite Belluga Now',
                          ),
                        );
                      },
            icon: isGeneratingShareCode
                ? const SizedBox.square(
                    dimension: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(shareUri == null ? Icons.refresh : Icons.share),
            label: Text(
              isGeneratingShareCode
                  ? 'Gerando...'
                  : shareUri == null
                      ? 'Tentar novamente'
                      : 'Compartilhar',
            ),
          ),
        ],
      ),
    );
  }
}
