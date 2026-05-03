import 'package:belluga_now/application/icons/boora_icons.dart';
import 'package:flutter/material.dart';

class InviteDecisionFooter extends StatelessWidget {
  const InviteDecisionFooter({
    super.key,
    required this.onAccept,
    required this.onDecline,
    required this.onRequestAuthentication,
    required this.requiresAuthentication,
  });

  final VoidCallback onAccept;
  final VoidCallback onDecline;
  final VoidCallback onRequestAuthentication;
  final bool requiresAuthentication;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isCompact = MediaQuery.sizeOf(context).width < 360;
    final buttonPadding = EdgeInsets.symmetric(
      horizontal: isCompact ? 8 : 12,
      vertical: isCompact ? 10 : 14,
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(isCompact ? 10 : 12),
        child: requiresAuthentication
            ? SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: onRequestAuthentication,
                  style: FilledButton.styleFrom(
                    padding: buttonPadding,
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  icon: const Icon(Icons.login),
                  label: const Text(
                    'Entre para Aceitar ou Recusar',
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            : Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onDecline,
                      style: OutlinedButton.styleFrom(
                        padding: buttonPadding,
                        foregroundColor: Colors.white,
                        side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      icon: const Icon(Icons.close),
                      label: const Text('Recusar'),
                    ),
                  ),
                  Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: isCompact ? 6 : 10),
                    child: Icon(
                      Icons.swipe,
                      color: Colors.white.withValues(alpha: 0.85),
                      size: isCompact ? 18 : 20,
                    ),
                  ),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: onAccept,
                      style: FilledButton.styleFrom(
                        padding: buttonPadding,
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      icon: const Icon(BooraIcons.inviteSolid),
                      label: const Text('Aceitar'),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
