import 'package:belluga_now/domain/partners/engagement_data.dart';
import 'package:belluga_now/domain/partners/account_profile_model.dart';
import 'package:belluga_now/presentation/shared/visuals/resolved_account_profile_visual.dart';
import 'package:belluga_now/presentation/shared/widgets/belluga_network_image.dart';
import 'package:belluga_now/presentation/shared/widgets/account_profile_identity_block.dart';
import 'package:flutter/material.dart';

class DiscoveryPartnerCard extends StatelessWidget {
  const DiscoveryPartnerCard({
    super.key,
    required this.partner,
    required this.isFavorite,
    required this.isFavoritable,
    required this.onFavoriteTap,
    required this.onTap,
    required this.resolvedVisual,
    this.showDetails = true,
  });

  final AccountProfileModel partner;
  final bool isFavorite;
  final bool isFavoritable;
  final VoidCallback onFavoriteTap;
  final VoidCallback onTap;
  final ResolvedAccountProfileVisual resolvedVisual;
  final bool showDetails;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      borderRadius: BorderRadius.circular(26),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardImage(
            partner: partner,
            resolvedVisual: resolvedVisual,
            isFavorite: isFavorite,
            isFavoritable: isFavoritable,
            onFavoriteTap: onFavoriteTap,
          ),
          if (showDetails)
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 12, 4, 0),
              child: AccountProfileIdentityBlock(
                name: partner.name,
                avatarUrl: resolvedVisual.identityAvatarUrl,
                typeVisual: resolvedVisual.typeVisual,
                identityAvatarKey: const Key('discoveryPartnerIdentityAvatar'),
                typeAvatarKey: const Key('discoveryPartnerTypeAvatar'),
                avatarSize: 44,
                avatarSpacing: 10,
                typeAvatarSize: 26,
                typeAvatarIconSize: 15,
                titleSpacing: 8,
                supportingSpacing: 10,
                titleStyle: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                supporting:
                    partner.tags.isEmpty ? null : _CardTags(partner: partner),
              ),
            ),
        ],
      ),
    );
  }
}

class _CardTags extends StatelessWidget {
  const _CardTags({required this.partner});

  final AccountProfileModel partner;

  @override
  Widget build(BuildContext context) {
    final tags = partner.tags.take(2).toList(growable: false);
    if (tags.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: tags
          .map(
            (tag) => Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: colorScheme.outlineVariant,
                ),
              ),
              child: Text(
                tag.value,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          )
          .toList(growable: false),
    );
  }
}

class _CardImage extends StatelessWidget {
  const _CardImage({
    required this.partner,
    required this.resolvedVisual,
    required this.isFavorite,
    required this.isFavoritable,
    required this.onFavoriteTap,
  });

  final AccountProfileModel partner;
  final ResolvedAccountProfileVisual resolvedVisual;
  final bool isFavorite;
  final bool isFavoritable;
  final VoidCallback onFavoriteTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final imageUrl = resolvedVisual.surfaceImageUrl;
    final isLiveNow = _isLiveNow(partner);

    return AspectRatio(
      aspectRatio: 0.92,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (imageUrl != null && imageUrl.isNotEmpty)
              BellugaNetworkImage(
                imageUrl,
                fit: BoxFit.cover,
                errorWidget: _fallback(colorScheme),
              )
            else
              _fallback(colorScheme),
            if (isLiveNow)
              Positioned(
                top: 8,
                left: 8,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.circle,
                          size: 7,
                          color: colorScheme.error,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'HOJE',
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: colorScheme.primary,
                                    fontWeight: FontWeight.w800,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            if (isFavoritable)
              Positioned(
                top: 8,
                right: 8,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black.withValues(alpha: 0.36),
                  ),
                  child: IconButton(
                    onPressed: onFavoriteTap,
                    icon: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: isFavorite ? colorScheme.error : Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _fallback(ColorScheme colorScheme) {
    final typeVisual = resolvedVisual.typeVisual;
    if (typeVisual?.isIcon == true && typeVisual?.iconData != null) {
      return DecoratedBox(
        decoration: BoxDecoration(
          color: typeVisual?.backgroundColor ?? colorScheme.surfaceContainer,
        ),
        child: Icon(
          typeVisual!.iconData,
          color: typeVisual.iconColor ?? colorScheme.onSurfaceVariant,
          size: 42,
        ),
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            colorScheme.surfaceContainerHighest,
            colorScheme.surfaceContainer,
          ],
        ),
      ),
      child: Icon(
        Icons.storefront,
        color: colorScheme.onSurfaceVariant,
        size: 42,
      ),
    );
  }
}

bool _isLiveNow(AccountProfileModel partner) {
  if (partner.type != 'artist') {
    return false;
  }
  final engagement = partner.engagementData;
  if (engagement is! ArtistEngagementData) {
    return false;
  }
  return engagement.status.toLowerCase().contains('agora');
}
