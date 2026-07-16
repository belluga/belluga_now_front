import 'package:belluga_now/presentation/shared/visuals/resolved_account_profile_visual.dart';
import 'package:belluga_now/presentation/shared/visuals/resolved_profile_type_visual.dart';
import 'package:belluga_now/presentation/shared/widgets/account_profile_type_avatar.dart';
import 'package:belluga_now/presentation/shared/widgets/belluga_network_image.dart';
import 'package:flutter/material.dart';

class AccountProfileOverlappingIdentityCard extends StatelessWidget {
  const AccountProfileOverlappingIdentityCard({
    required this.name,
    required this.visual,
    this.tags = const <String>[],
    this.onTap,
    this.cardKey,
    this.tapKey,
    this.titleStyle,
    this.titleMaxLines = 3,
    this.avatarSize = 106,
    this.avatarLeft = 18,
    this.avatarTop = 8,
    this.cardLeft = 92,
    this.cardRight = 0,
    this.contentLeadingInset = 58,
    this.contentTrailingInset = 20,
    this.minimumCardHeight = 122,
    super.key,
  });

  final String name;
  final ResolvedAccountProfileVisual visual;
  final List<String> tags;
  final VoidCallback? onTap;
  final Key? cardKey;
  final Key? tapKey;
  final TextStyle? titleStyle;
  final int titleMaxLines;
  final double avatarSize;
  final double avatarLeft;
  final double avatarTop;
  final double cardLeft;
  final double cardRight;
  final double contentLeadingInset;
  final double contentTrailingInset;
  final double minimumCardHeight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final hasAvatar = visual.identityAvatarUrl != null;
    final hasLeadingVisual = hasAvatar || visual.typeVisual != null;
    final effectiveCardLeft = hasLeadingVisual ? cardLeft : 0.0;
    final effectiveLeadingInset = hasLeadingVisual ? contentLeadingInset : 20.0;
    final effectiveMinimumHeight = hasLeadingVisual ? minimumCardHeight : 0.0;
    final effectiveTitleStyle =
        titleStyle ??
        theme.textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w800,
          height: 1.05,
          color: colorScheme.primary,
        );
    final content = ConstrainedBox(
      constraints: BoxConstraints(minHeight: effectiveMinimumHeight),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          effectiveLeadingInset,
          20,
          contentTrailingInset,
          20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: tags.isEmpty
              ? MainAxisAlignment.center
              : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              maxLines: titleMaxLines,
              overflow: TextOverflow.ellipsis,
              style: effectiveTitleStyle,
            ),
            if (tags.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: tags
                    .map(
                      (tag) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          tag,
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    )
                    .toList(growable: false),
              ),
            ],
          ],
        ),
      ),
    );

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Padding(
          padding: EdgeInsets.only(left: effectiveCardLeft, right: cardRight),
          child: SizedBox(
            width: double.infinity,
            child: Card(
              key: cardKey,
              clipBehavior: Clip.antiAlias,
              child: onTap == null
                  ? content
                  : InkWell(key: tapKey, onTap: onTap, child: content),
            ),
          ),
        ),
        if (hasLeadingVisual)
          Positioned(
            left: avatarLeft,
            top: avatarTop,
            child: _AccountProfileOverlappingAvatar(
              avatarUrl: visual.identityAvatarUrl,
              typeVisual: visual.typeVisual,
              size: avatarSize,
            ),
          ),
      ],
    );
  }
}

class _AccountProfileOverlappingAvatar extends StatelessWidget {
  const _AccountProfileOverlappingAvatar({
    required this.avatarUrl,
    required this.typeVisual,
    required this.size,
  });

  final String? avatarUrl;
  final ResolvedProfileTypeVisual? typeVisual;
  final double size;

  @override
  Widget build(BuildContext context) {
    final normalizedAvatarUrl = avatarUrl?.trim();
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipOval(
        child: normalizedAvatarUrl != null && normalizedAvatarUrl.isNotEmpty
            ? BellugaNetworkImage(normalizedAvatarUrl, fit: BoxFit.cover)
            : AccountProfileTypeAvatar(
                visual: typeVisual!,
                size: size - 8,
                iconSize: size * 0.4,
              ),
      ),
    );
  }
}
