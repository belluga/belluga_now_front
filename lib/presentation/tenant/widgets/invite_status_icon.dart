import 'package:belluga_now/application/icons/boora_icons.dart';
import 'package:flutter/material.dart';

class InviteStatusIcon extends StatelessWidget {
  const InviteStatusIcon({
    super.key,
    required this.isConfirmed,
    required this.pendingInvitesCount,
    this.size = 24,
    this.backgroundColor,
  });

  final bool isConfirmed;
  final int pendingInvitesCount;
  final double size;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    if (!isConfirmed && pendingInvitesCount == 0) {
      return const SizedBox.shrink();
    }

    final colorScheme = Theme.of(context).colorScheme;
    final bgColor = isConfirmed ? colorScheme.primary : colorScheme.onSecondary;
    final iconColor =
        isConfirmed ? colorScheme.onPrimary : colorScheme.secondary;
    final badgeTextColor = colorScheme.onPrimary;

    final iconSize = size;
    final badgeSize = iconSize * 0.9;

    return SizedBox(
      width: iconSize + badgeSize,
      height: iconSize + badgeSize,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomRight,
        children: [
          Positioned(
            left: 0,
            top: 0,
            child: CircleAvatar(
              backgroundColor: bgColor,
              radius: (size + 14) / 2,
              child: Transform.translate(
                offset: const Offset(-2.0, 0.6),
                child: Icon(
                  BooraIcons.invite_solid,
                  color: iconColor,
                  size: size * 0.9,
                ),
              ),
            ),
          ),
          if (pendingInvitesCount > 0)
            Container(
              width: badgeSize,
              height: badgeSize,
              decoration: BoxDecoration(
                color: iconColor,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                pendingInvitesCount > 10
                    ? '10+'
                    : pendingInvitesCount.toString(),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: badgeTextColor,
                          fontWeight: FontWeight.w800,
                        ) ??
                    TextStyle(
                      color: badgeTextColor,
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ),
        ],
      ),
    );
  }
}
