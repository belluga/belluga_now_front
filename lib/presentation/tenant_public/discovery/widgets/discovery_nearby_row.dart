import 'package:belluga_now/domain/partners/account_profile_model.dart';
import 'package:belluga_now/presentation/shared/visuals/resolved_account_profile_visual.dart';
import 'package:belluga_now/presentation/shared/widgets/belluga_network_image.dart';
import 'package:flutter/material.dart';

class DiscoveryNearbyRow extends StatelessWidget {
  const DiscoveryNearbyRow({
    super.key,
    required this.items,
    required this.onTap,
    required this.resolvedVisualForItem,
  });

  final List<AccountProfileModel> items;
  final ValueChanged<AccountProfileModel> onTap;
  final ResolvedAccountProfileVisual Function(AccountProfileModel)
      resolvedVisualForItem;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Text(
            'Perto de você',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
        SizedBox(
          height: 156,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final item = items[index];
              final resolvedVisual = resolvedVisualForItem(item);
              final distanceLabel = _distanceLabel(item.distanceMeters);
              return SizedBox(
                width: 108,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => onTap(item),
                  child: Column(
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          SizedBox(
                            width: 72,
                            height: 72,
                            child: ClipOval(
                              child: _NearbyAvatar(
                                item: item,
                                resolvedVisual: resolvedVisual,
                              ),
                            ),
                          ),
                          if (distanceLabel != null)
                            Positioned(
                              right: -4,
                              bottom: 2,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: colorScheme.tertiary,
                                  border: Border.all(
                                    color: colorScheme.surface,
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 7,
                                    vertical: 3,
                                  ),
                                  child: Text(
                                    distanceLabel,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(
                                          color: colorScheme.onTertiary,
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        item.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
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

class _NearbyAvatar extends StatelessWidget {
  const _NearbyAvatar({
    required this.item,
    required this.resolvedVisual,
  });

  final AccountProfileModel item;
  final ResolvedAccountProfileVisual resolvedVisual;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final imageUrl = resolvedVisual.compactImageUrl;
    if (imageUrl == null || imageUrl.isEmpty) {
      final typeVisual = resolvedVisual.typeVisual;
      if (typeVisual?.isIcon == true && typeVisual?.iconData != null) {
        return Container(
          color: typeVisual?.backgroundColor ?? colorScheme.surfaceContainer,
          alignment: Alignment.center,
          child: Icon(
            typeVisual!.iconData,
            color: typeVisual.iconColor ?? colorScheme.onSurfaceVariant,
          ),
        );
      }
      return Container(
        color: colorScheme.surfaceContainerHighest,
        alignment: Alignment.center,
        child: Icon(
          Icons.storefront,
          color: colorScheme.onSurfaceVariant,
        ),
      );
    }
    return BellugaNetworkImage(
      imageUrl,
      fit: BoxFit.cover,
      errorWidget: Container(
        color: colorScheme.surfaceContainerHighest,
        alignment: Alignment.center,
        child: Icon(
          Icons.storefront,
          color: colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
