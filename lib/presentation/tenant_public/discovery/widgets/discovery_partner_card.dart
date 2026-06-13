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
  final VoidCallback? onTap;
  final ResolvedAccountProfileVisual resolvedVisual;
  final bool showDetails;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canOpenPublicDetail = onTap != null;
    final semanticLabel = canOpenPublicDetail
        ? 'Abrir perfil ${partner.name}'
        : 'Perfil ${partner.name}';

    return Semantics(
      container: true,
      button: canOpenPublicDetail,
      label: semanticLabel,
      onTap: onTap,
      child: InkWell(
        borderRadius: BorderRadius.circular(26),
        excludeFromSemantics: true,
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
                  identityAvatarKey:
                      const Key('discoveryPartnerIdentityAvatar'),
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
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CardImageTags extends StatelessWidget {
  const _CardImageTags({required this.partner});

  final AccountProfileModel partner;

  @override
  Widget build(BuildContext context) {
    final labels = partner.tags
        .map((tag) => tag.value.trim())
        .where((label) => label.isNotEmpty)
        .toList(growable: false);
    if (labels.isEmpty) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final textStyle = Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ) ??
            const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            );
        final visibleLabels = _visibleTagLabelsForTwoRows(
          labels: labels,
          maxWidth: constraints.maxWidth,
          textStyle: textStyle,
          textDirection: Directionality.of(context),
        );
        if (visibleLabels.isEmpty) {
          return const SizedBox.shrink();
        }
        return Wrap(
          key: const ValueKey<String>('discoveryPartnerImageTagsOverlay'),
          spacing: _tagSpacing,
          runSpacing: _tagRunSpacing,
          children: visibleLabels
              .map(
                (label) => _CardImageTag(
                  label: label,
                  maxWidth: constraints.maxWidth,
                  textStyle: textStyle,
                ),
              )
              .toList(growable: false),
        );
      },
    );
  }
}

const double _tagHorizontalPadding = 20;
const double _tagSpacing = 6;
const double _tagRunSpacing = 6;
const int _maxTagRows = 2;

class _CardImageTag extends StatelessWidget {
  const _CardImageTag({
    required this.label,
    required this.maxWidth,
    required this.textStyle,
  });

  final String label;
  final double maxWidth;
  final TextStyle textStyle;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      key: ValueKey<String>('discoveryPartnerImageTag:$label'),
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.58),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.34),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: _tagHorizontalPadding / 2,
            vertical: 6,
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textStyle,
          ),
        ),
      ),
    );
  }
}

List<String> _visibleTagLabelsForTwoRows({
  required List<String> labels,
  required double maxWidth,
  required TextStyle textStyle,
  required TextDirection textDirection,
}) {
  if (maxWidth <= 0) {
    return const <String>[];
  }

  final visibleLabels = <String>[];
  var currentRow = 1;
  var currentRowWidth = 0.0;

  for (final label in labels) {
    final chipWidth = _boundedTagChipWidth(
      label: label,
      maxWidth: maxWidth,
      textStyle: textStyle,
      textDirection: textDirection,
    );
    final requiredWidth = currentRowWidth == 0
        ? chipWidth
        : currentRowWidth + _tagSpacing + chipWidth;

    if (requiredWidth <= maxWidth) {
      visibleLabels.add(label);
      currentRowWidth = requiredWidth;
      continue;
    }

    if (currentRow >= _maxTagRows) {
      break;
    }

    currentRow += 1;
    visibleLabels.add(label);
    currentRowWidth = chipWidth;
  }

  return visibleLabels;
}

double _boundedTagChipWidth({
  required String label,
  required double maxWidth,
  required TextStyle textStyle,
  required TextDirection textDirection,
}) {
  final painter = TextPainter(
    text: TextSpan(text: label, style: textStyle),
    maxLines: 1,
    textDirection: textDirection,
  )..layout(maxWidth: maxWidth);
  final naturalWidth = painter.width + _tagHorizontalPadding;
  return naturalWidth > maxWidth ? maxWidth : naturalWidth;
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
    final favoriteLabel =
        isFavorite ? 'Perfil favoritado' : 'Favoritar perfil ${partner.name}';

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
            if (partner.tags.isNotEmpty)
              Positioned(
                left: 10,
                right: 10,
                bottom: 10,
                child: _CardImageTags(partner: partner),
              ),
            if (isFavoritable)
              Positioned(
                top: 8,
                right: 8,
                child: Semantics(
                  container: true,
                  button: true,
                  label: favoriteLabel,
                  onTap: onFavoriteTap,
                  excludeSemantics: true,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withValues(alpha: 0.36),
                    ),
                    child: IconButton(
                      key: Key('discoveryFavoriteButton_${partner.id}'),
                      tooltip: favoriteLabel,
                      onPressed: onFavoriteTap,
                      icon: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: isFavorite ? colorScheme.error : Colors.white,
                      ),
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
