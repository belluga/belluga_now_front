import 'package:belluga_now/application/icons/boora_icons.dart';
import 'package:belluga_now/presentation/tenant_public/profile/screens/profile_screen/widgets/profile_metric_pill.dart';
import 'package:flutter/material.dart';

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({
    super.key,
    this.avatarImage,
    required this.displayName,
    required this.onChangeAvatar,
    required this.invitesSent,
    required this.invitesAccepted,
    required this.hasPendingChanges,
  });

  final ImageProvider? avatarImage;
  final String displayName;
  final VoidCallback onChangeAvatar;
  final int invitesSent;
  final int invitesAccepted;
  final bool hasPendingChanges;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primary.withValues(alpha: 0.08),
            colorScheme.secondary.withValues(alpha: 0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              CircleAvatar(
                radius: 34,
                backgroundColor: colorScheme.primary.withValues(alpha: 0.15),
                backgroundImage: avatarImage,
                child: avatarImage == null
                    ? Icon(Icons.person, color: colorScheme.primary, size: 32)
                    : null,
              ),
              Positioned(
                right: -4,
                bottom: -4,
                child: Material(
                  color: colorScheme.surface,
                  shape: const CircleBorder(),
                  elevation: 2,
                  child: IconButton(
                    visualDensity: VisualDensity.compact,
                    iconSize: 18,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints.tightFor(
                      width: 32,
                      height: 32,
                    ),
                    onPressed: onChangeAvatar,
                    icon: Icon(
                      Icons.photo_camera_outlined,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        displayName.isNotEmpty ? displayName : 'Seu perfil',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (hasPendingChanges)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          'Alterado',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Convites aceitos valem mais que likes.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ProfileMetricPill(
                      value: invitesSent,
                      icon: BooraIcons.invite_outlined,
                      iconColor: colorScheme.secondary,
                      backgroundColor:
                          colorScheme.secondary.withValues(alpha: 0.14),
                    ),
                    ProfileMetricPill(
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
        ],
      ),
    );
  }
}
