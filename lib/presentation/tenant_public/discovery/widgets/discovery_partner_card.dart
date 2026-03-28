import 'package:belluga_now/domain/partners/engagement_data.dart';
import 'package:belluga_now/domain/partners/account_profile_model.dart';
import 'package:belluga_now/presentation/shared/widgets/belluga_network_image.dart';
import 'package:flutter/material.dart';

class DiscoveryPartnerCard extends StatelessWidget {
  const DiscoveryPartnerCard({
    super.key,
    required this.partner,
    required this.isFavorite,
    required this.isFavoritable,
    required this.onFavoriteTap,
    required this.onTap,
    required this.typeLabel,
    this.showDetails = true,
  });

  final AccountProfileModel partner;
  final bool isFavorite;
  final bool isFavoritable;
  final VoidCallback onFavoriteTap;
  final VoidCallback onTap;
  final String typeLabel;
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
            isFavorite: isFavorite,
            isFavoritable: isFavoritable,
            onFavoriteTap: onFavoriteTap,
          ),
          if (showDetails)
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 12, 4, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    typeLabel.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.primary,
                      letterSpacing: 1.1,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    partner.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  _CardSubtitle(partner: partner),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _CardImage extends StatelessWidget {
  const _CardImage({
    required this.partner,
    required this.isFavorite,
    required this.isFavoritable,
    required this.onFavoriteTap,
  });

  final AccountProfileModel partner;
  final bool isFavorite;
  final bool isFavoritable;
  final VoidCallback onFavoriteTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final imageUrl = partner.coverUrl ?? partner.avatarUrl;
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

class _CardSubtitle extends StatelessWidget {
  const _CardSubtitle({required this.partner});

  final AccountProfileModel partner;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final distanceLabel = _distanceLabel(partner.distanceMeters);
    final secondary = partner.tags.isNotEmpty ? partner.tags.first : null;
    final text = <String>[
      if (secondary != null && secondary.isNotEmpty) secondary,
      if (distanceLabel != null) distanceLabel,
    ].join(' • ');

    if (text.isEmpty) {
      return const SizedBox.shrink();
    }

    return Row(
      children: [
        Icon(
          Icons.place,
          size: 14,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
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

String? _distanceLabel(double? distanceMeters) {
  if (distanceMeters == null) {
    return null;
  }
  if (distanceMeters >= 1000) {
    return '${(distanceMeters / 1000).toStringAsFixed(1)} km';
  }
  return '${distanceMeters.toStringAsFixed(0)} m';
}
