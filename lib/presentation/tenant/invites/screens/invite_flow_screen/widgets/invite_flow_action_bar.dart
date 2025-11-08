import 'package:belluga_now/domain/invites/invite_decision.dart';
import 'package:belluga_now/presentation/tenant/invites/screens/invite_flow_screen/controllers/invite_flow_controller.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

class InviteFlowActionBar extends StatelessWidget {
  const InviteFlowActionBar({
    super.key,
    required this.onConfirmPresence,
    required this.isConfirmingPresence,
  });

  final VoidCallback onConfirmPresence;
  final bool isConfirmingPresence;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final controller = GetIt.I.get<InviteFlowScreenController>();
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
                onPressed: () =>
                    controller.applyDecision(InviteDecision.declined),
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
        const SizedBox(height: 12),
        TextButton.icon(
          onPressed: () => controller.applyDecision(InviteDecision.maybe),
          icon: const Icon(Icons.group_add_outlined),
          label: const Text('Quem sabe...'),
        ),
      ],
    );
  }
}
