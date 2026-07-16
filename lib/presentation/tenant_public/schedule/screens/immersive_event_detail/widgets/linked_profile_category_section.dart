import 'package:belluga_now/domain/schedule/event_linked_account_profile.dart';
import 'package:belluga_now/presentation/shared/visuals/account_profile_visual_resolver.dart';
import 'package:belluga_now/presentation/shared/visuals/resolved_account_profile_visual.dart';
import 'package:belluga_now/presentation/shared/widgets/account_profile_overlapping_identity_card.dart';
import 'package:flutter/material.dart';
import 'package:belluga_now/domain/partners/profile_type_registry.dart';

class LinkedProfileCategorySection extends StatelessWidget {
  const LinkedProfileCategorySection({
    required this.title,
    required this.profiles,
    required this.profileTypeRegistry,
    required this.favoriteAccountProfileIds,
    required this.isFavoritable,
    required this.onProfileTap,
    required this.onFavoriteTap,
    super.key,
  });

  final String title;
  final List<EventLinkedAccountProfile> profiles;
  final ProfileTypeRegistry? profileTypeRegistry;
  final Set<String> favoriteAccountProfileIds;
  final bool Function(EventLinkedAccountProfile profile) isFavoritable;
  final ValueChanged<EventLinkedAccountProfile> onProfileTap;
  final ValueChanged<EventLinkedAccountProfile> onFavoriteTap;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16).copyWith(bottom: 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 16),
          ...profiles.map(
            (profile) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _LinkedProfileCard(
                profile: profile,
                resolvedVisual: AccountProfileVisualResolver.resolvePreview(
                  registry: profileTypeRegistry,
                  profileType: profile.profileType,
                  avatarUrl: profile.avatarUrl,
                  coverUrl: profile.coverUrl,
                ),
                isFavorite: favoriteAccountProfileIds.contains(profile.id),
                isFavoritable: isFavoritable(profile),
                onTap: profile.canOpenPublicDetail
                    ? () => onProfileTap(profile)
                    : null,
                onFavoriteTap: () => onFavoriteTap(profile),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LinkedProfileCard extends StatelessWidget {
  const _LinkedProfileCard({
    required this.profile,
    required this.resolvedVisual,
    required this.isFavorite,
    required this.isFavoritable,
    required this.onTap,
    required this.onFavoriteTap,
  });

  final EventLinkedAccountProfile profile;
  final ResolvedAccountProfileVisual resolvedVisual;
  final bool isFavorite;
  final bool isFavoritable;
  final VoidCallback? onTap;
  final VoidCallback onFavoriteTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final favoriteLabel = isFavorite ? 'Favoritado' : 'Favoritar';
    final tags = profile.taxonomyTerms
        .map((term) => term.labelValue.value.trim())
        .where((label) => label.isNotEmpty)
        .toList(growable: false);

    return Stack(
      children: [
        AccountProfileOverlappingIdentityCard(
          name: profile.displayName,
          visual: resolvedVisual,
          tags: tags,
          onTap: onTap,
          tapKey: Key('linkedProfileCardTapTarget_${profile.id}'),
          titleStyle: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: colorScheme.primary,
          ),
          titleMaxLines: 2,
          avatarSize: 64,
          avatarLeft: 12,
          avatarTop: 8,
          cardLeft: 56,
          contentLeadingInset: 44,
          contentTrailingInset: isFavoritable ? 64 : 20,
          minimumCardHeight: 80,
        ),
        if (isFavoritable)
          Positioned(
            top: 8,
            right: 8,
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colorScheme.surface.withValues(alpha: 0.94),
              ),
              child: IconButton(
                key: Key('linkedProfileFavoriteButton_${profile.id}'),
                tooltip: favoriteLabel,
                onPressed: onFavoriteTap,
                icon: Icon(
                  isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: isFavorite ? colorScheme.error : colorScheme.onSurface,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
