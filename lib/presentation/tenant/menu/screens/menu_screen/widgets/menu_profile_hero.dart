import 'package:belluga_now/application/icons/boora_icons.dart';
import 'package:belluga_now/presentation/tenant/menu/screens/menu_screen/widgets/menu_metric_pill.dart';
import 'package:flutter/material.dart';

class MenuProfileHero extends StatelessWidget {
  const MenuProfileHero({
    super.key,
    required this.onTapViewProfile,
    required this.invitesSent,
    required this.invitesAccepted,
  });

  final VoidCallback onTapViewProfile;
  final int invitesSent;
  final int invitesAccepted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primary.withValues(alpha: 0.08),
            colorScheme.secondary.withValues(alpha: 0.10),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: colorScheme.primary.withValues(alpha: 0.15),
            child: Icon(
              Icons.person,
              size: 32,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Seu Perfil',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Convites aceitos e presenças confirmadas valem mais que likes.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    MenuMetricPill(
                      value: invitesSent,
                      icon: BooraIcons.invite_outlined,
                      iconColor: colorScheme.secondary,
                      backgroundColor:
                          colorScheme.secondary.withValues(alpha: 0.14),
                    ),
                    MenuMetricPill(
                      value: invitesAccepted,
                      icon: BooraIcons.invite_solid,
                      iconColor: colorScheme.primary,
                      backgroundColor:
                          colorScheme.primary.withValues(alpha: 0.14),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: onTapViewProfile,
            icon:
                Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
