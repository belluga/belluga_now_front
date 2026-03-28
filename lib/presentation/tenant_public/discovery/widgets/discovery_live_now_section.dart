import 'package:belluga_now/domain/partners/account_profile_model.dart';
import 'package:belluga_now/presentation/shared/widgets/belluga_network_image.dart';
import 'package:flutter/material.dart';

class DiscoveryLiveNowSection extends StatelessWidget {
  const DiscoveryLiveNowSection({
    super.key,
    required this.items,
    required this.isFavorite,
    required this.isFavoritable,
    required this.onFavoriteTap,
    required this.onTap,
    required this.typeLabelForPartner,
  });

  final List<AccountProfileModel> items;
  final bool Function(AccountProfileModel) isFavorite;
  final bool Function(AccountProfileModel) isFavoritable;
  final ValueChanged<AccountProfileModel> onFavoriteTap;
  final ValueChanged<AccountProfileModel> onTap;
  final String Function(AccountProfileModel) typeLabelForPartner;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _LiveNowHeader(),
          const SizedBox(height: 10),
          if (items.length == 1)
            _LiveNowCard(
              partner: items.first,
              isFavorite: isFavorite(items.first),
              isFavoritable: isFavoritable(items.first),
              onFavoriteTap: () => onFavoriteTap(items.first),
              onTap: () => onTap(items.first),
              typeLabel: typeLabelForPartner(items.first),
            )
          else
            SizedBox(
              height: 188,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final partner = items[index];
                  return SizedBox(
                    width: MediaQuery.of(context).size.width * 0.88,
                    child: _LiveNowCard(
                      partner: partner,
                      isFavorite: isFavorite(partner),
                      isFavoritable: isFavoritable(partner),
                      onFavoriteTap: () => onFavoriteTap(partner),
                      onTap: () => onTap(partner),
                      typeLabel: typeLabelForPartner(partner),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _LiveNowHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: Text(
            'Tocando agora',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              children: [
                Icon(
                  Icons.circle,
                  size: 8,
                  color: colorScheme.error,
                ),
                const SizedBox(width: 6),
                Text(
                  'AO VIVO',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _LiveNowCard extends StatelessWidget {
  const _LiveNowCard({
    required this.partner,
    required this.isFavorite,
    required this.isFavoritable,
    required this.onFavoriteTap,
    required this.onTap,
    required this.typeLabel,
  });

  final AccountProfileModel partner;
  final bool isFavorite;
  final bool isFavoritable;
  final VoidCallback onFavoriteTap;
  final VoidCallback onTap;
  final String typeLabel;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final imageUrl = partner.coverUrl ?? partner.avatarUrl;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(28),
      child: Ink(
        height: 188,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (imageUrl != null && imageUrl.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: BellugaNetworkImage(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorWidget: const SizedBox.shrink(),
                ),
              ),
            ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.72),
                      Colors.black.withValues(alpha: 0.28),
                      Colors.black.withValues(alpha: 0.06),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 14,
              left: 16,
              child: Text(
                typeLabel.toUpperCase(),
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.92),
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.8,
                    ),
              ),
            ),
            if (isFavoritable)
              Positioned(
                top: 10,
                right: 10,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black.withValues(alpha: 0.44),
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
            Positioned(
              left: 16,
              right: 16,
              bottom: 14,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    partner.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 10),
                  FilledButton(
                    onPressed: onTap,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 12,
                      ),
                    ),
                    child: const Text('Ver detalhes'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
