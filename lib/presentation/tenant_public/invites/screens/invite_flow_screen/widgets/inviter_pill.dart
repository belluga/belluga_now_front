import 'package:flutter/material.dart';

class InviterPill extends StatelessWidget {
  const InviterPill({super.key, required this.inviter, required this.extraInviters});

  final String inviter;
  final int extraInviters;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final description = extraInviters > 0
        ? '$inviter e +$extraInviters amigos te convidaram.'
        : '$inviter te convidou.';
    final scheme = Theme.of(context).colorScheme;
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
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
