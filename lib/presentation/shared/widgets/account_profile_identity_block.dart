import 'package:belluga_now/presentation/shared/visuals/resolved_profile_type_visual.dart';
import 'package:belluga_now/presentation/shared/widgets/account_profile_type_avatar.dart';
import 'package:belluga_now/presentation/shared/widgets/belluga_network_image.dart';
import 'package:flutter/material.dart';

class AccountProfileIdentityBlock extends StatelessWidget {
  const AccountProfileIdentityBlock({
    super.key,
    required this.name,
    this.avatarUrl,
    this.typeVisual,
    this.supporting,
    this.titleStyle,
    this.titleMaxLines = 2,
    this.avatarSize = 52,
    this.typeAvatarSize = 28,
    this.typeAvatarIconSize = 16,
    this.avatarSpacing = 12,
    this.titleSpacing = 10,
    this.supportingSpacing = 12,
    this.titleTrailing = const <Widget>[],
    this.identityAvatarKey,
    this.typeAvatarKey,
  });

  final String name;
  final String? avatarUrl;
  final ResolvedProfileTypeVisual? typeVisual;
  final Widget? supporting;
  final TextStyle? titleStyle;
  final int titleMaxLines;
  final double avatarSize;
  final double typeAvatarSize;
  final double typeAvatarIconSize;
  final double avatarSpacing;
  final double titleSpacing;
  final double supportingSpacing;
  final List<Widget> titleTrailing;
  final Key? identityAvatarKey;
  final Key? typeAvatarKey;

  @override
  Widget build(BuildContext context) {
    final hasAvatar = avatarUrl != null && avatarUrl!.trim().isNotEmpty;
    final hasLeadingVisual = hasAvatar || typeVisual != null;
    final fallbackTypeAvatarIconSize = avatarSize * 0.46;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (hasLeadingVisual) ...[
              if (hasAvatar)
                _IdentityAvatarWithBadge(
                  avatarKey: identityAvatarKey,
                  badgeKey: typeAvatarKey,
                  avatarUrl: avatarUrl!,
                  size: avatarSize,
                  badgeVisual: typeVisual,
                  badgeSize: typeAvatarSize,
                  badgeIconSize: typeAvatarIconSize,
                )
              else if (typeVisual != null)
                AccountProfileTypeAvatar(
                  key: typeAvatarKey,
                  visual: typeVisual!,
                  size: avatarSize,
                  iconSize: fallbackTypeAvatarIconSize,
                ),
              SizedBox(width: avatarSpacing),
            ],
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                  child: Text(
                    name,
                    maxLines: titleMaxLines,
                    overflow: TextOverflow.ellipsis,
                    style: titleStyle,
                  ),
                  ),
                  for (final trailing in titleTrailing) ...[
                    SizedBox(width: titleSpacing),
                    trailing,
                  ],
                ],
              ),
            ),
          ],
        ),
        if (supporting != null) ...[
          SizedBox(height: supportingSpacing),
          supporting!,
        ],
      ],
    );
  }
}

class _IdentityAvatarWithBadge extends StatelessWidget {
  const _IdentityAvatarWithBadge({
    this.avatarKey,
    this.badgeKey,
    required this.avatarUrl,
    required this.size,
    required this.badgeVisual,
    required this.badgeSize,
    required this.badgeIconSize,
  });

  final Key? avatarKey;
  final Key? badgeKey;
  final String avatarUrl;
  final double size;
  final ResolvedProfileTypeVisual? badgeVisual;
  final double badgeSize;
  final double badgeIconSize;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          _IdentityAvatar(
            key: avatarKey,
            avatarUrl: avatarUrl,
            size: size,
          ),
          if (badgeVisual != null)
            Positioned(
              right: -2,
              bottom: -2,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(context).colorScheme.surface,
                    width: 2,
                  ),
                ),
                child: AccountProfileTypeAvatar(
                  key: badgeKey,
                  visual: badgeVisual!,
                  size: badgeSize,
                  iconSize: badgeIconSize,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _IdentityAvatar extends StatelessWidget {
  const _IdentityAvatar({
    super.key,
    required this.avatarUrl,
    required this.size,
  });

  final String avatarUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colorScheme.surfaceContainerHighest,
      ),
      clipBehavior: Clip.antiAlias,
      child: BellugaNetworkImage(
        avatarUrl,
        fit: BoxFit.cover,
        errorWidget: Icon(
          Icons.account_circle,
          color: colorScheme.onSurfaceVariant,
          size: size * 0.56,
        ),
      ),
    );
  }
}
