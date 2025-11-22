import 'package:flutter/material.dart';

class InviteFlowActionBar extends StatelessWidget {
  const InviteFlowActionBar({
    super.key,
    required this.onConfirmPresence,
    required this.onDecline,
    required this.isConfirmingPresence,
  });

  final VoidCallback onConfirmPresence;
  final VoidCallback onDecline;
  final bool isConfirmingPresence;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final buttonLabel =
        isConfirmingPresence ? 'Bora! Agora é chamar os amigos...' : 'Bora?';
    final buttonIcon = isConfirmingPresence
        ? Icons.check_circle_outline
        : Icons.rocket_launch_outlined;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onDecline,
                icon: Icon(buttonIcon),
                label: const Text('Recusar'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton.icon(
                onPressed: onConfirmPresence,
                icon: Icon(buttonIcon),
                label: Text(buttonLabel),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
