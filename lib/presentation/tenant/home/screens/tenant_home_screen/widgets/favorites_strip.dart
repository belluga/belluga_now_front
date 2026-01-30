import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/domain/favorite/projections/favorite_resume.dart';
import 'package:belluga_now/domain/partners/account_profile_model.dart';
import 'package:belluga_now/domain/repositories/account_profiles_repository_contract.dart';
import 'package:belluga_now/presentation/tenant/home/screens/tenant_home_screen/widgets/favorite_chip.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

class FavoritesStrip extends StatefulWidget {
  const FavoritesStrip({
    super.key,
    required this.items,
    this.pinned,
    this.height = 118,
    this.spacing = 12,
    this.onPinnedTap,
  });

  final List<FavoriteResume> items;
  final FavoriteResume? pinned;
  final double height;
  final double spacing;
  final VoidCallback? onPinnedTap;

  @override
  State<FavoritesStrip> createState() => _FavoritesStripState();
}

class _FavoritesStripState extends State<FavoritesStrip> {
  @override
  Widget build(BuildContext context) {
    final pinned = widget.pinned;
    final scrollItems = widget.items;

    return SizedBox(
      height: widget.height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (pinned != null)
            Padding(
              padding: EdgeInsets.only(right: widget.spacing),
              child: FavoriteChip(
                title: pinned.title,
                imageUri: pinned.imageUri,
                badge: pinned.badge,
                onTap: () => _onFavoriteTap(pinned),
                isPrimary: pinned.isPrimary,
                iconImageUrl: pinned.iconImageUrl,
                primaryColor: pinned.primaryColor,
              ),
            ),
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: scrollItems.length + 1,
              padding: EdgeInsets.only(
                left: widget.pinned != null ? 0 : widget.spacing,
                right: widget.spacing,
              ),
              separatorBuilder: (_, __) => SizedBox(width: widget.spacing),
              itemBuilder: (context, index) {
                if (index == scrollItems.length) {
                  return FavoriteChip(
                    title: 'Procurar',
                    onTap: _onSearchTap,
                  );
                }

                final item = scrollItems[index];
                return FavoriteChip(
                  title: item.title,
                  imageUri: item.imageUri,
                  badge: item.badge,
                  onTap: () => _onFavoriteTap(item),
                  isPrimary: item.isPrimary,
                  iconImageUrl: item.iconImageUrl,
                  primaryColor: item.primaryColor,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _onSearchTap() {
    context.router.push(DiscoveryRoute());
  }

  Future<void> _onFavoriteTap(FavoriteResume favorite) async {
    // If it's the primary favorite (app owner), navigate to About screen
    // Otherwise, navigate to Partner Details
    if (favorite.isPrimary) {
      widget.onPinnedTap?.call();
      return;
    }

    final slug = favorite.slug;
    if (slug != null && slug.isNotEmpty) {
      final partner = await _loadPartnerBySlug(slug);
      if (partner != null) {
        _openPartnerProfile(partner.slug);
        return;
      }
    }

    _openAgendaForFavorite(favorite);
  }

  Future<AccountProfileModel?> _loadPartnerBySlug(String slug) async {
    final getIt = GetIt.I;
    if (!getIt.isRegistered<AccountProfilesRepositoryContract>()) {
      return null;
    }
    return getIt.get<AccountProfilesRepositoryContract>().getAccountProfileBySlug(slug);
  }

  void _openPartnerProfile(String slug) {
    context.router.push(PartnerDetailRoute(slug: slug));
  }

  void _openAgendaForFavorite(FavoriteResume favorite) {
    final query = favorite.title.trim();
    context.router.replaceAll(
      [
        EventSearchRoute(
          startSearchActive: true,
          initialSearchQuery: query,
        ),
      ],
    );
  }
}
