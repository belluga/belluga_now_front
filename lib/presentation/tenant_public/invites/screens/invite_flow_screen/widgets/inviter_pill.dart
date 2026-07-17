import 'package:flutter/material.dart';

class InviterPill extends StatelessWidget {
  const InviterPill({
    super.key,
    required this.inviter,
    required this.extraInviters,
    this.isIssuerPreview = false,
    this.onSharePreview,
  });

  final String inviter;
  final int extraInviters;
  final bool isIssuerPreview;
  final VoidCallback? onSharePreview;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = Theme.of(context).colorScheme;
    if (isIssuerPreview) {
      return Container(
        constraints: const BoxConstraints(maxWidth: 320),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: scheme.surface.withValues(alpha: 0.82),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: scheme.outlineVariant.withValues(alpha: 0.45),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.visibility_outlined, color: scheme.onSurface, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Prévia do seu convite',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 6),
            TextButton.icon(
              onPressed: onSharePreview,
              style: TextButton.styleFrom(
                foregroundColor: scheme.primary,
                visualDensity: VisualDensity.compact,
              ),
              icon: const Icon(Icons.share_outlined, size: 16),
              label: const Text('Compartilhar'),
            ),
          ],
        ),
      );
    }

    final description = extraInviters > 0
        ? '$inviter e +$extraInviters amigos te convidaram.'
        : '$inviter te convidou.';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: Colors.blueGrey.withValues(alpha: 0.2),
            child: const Icon(Icons.person, size: 16, color: Colors.white),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
