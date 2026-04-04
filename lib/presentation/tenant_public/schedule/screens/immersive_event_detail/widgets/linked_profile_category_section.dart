import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/domain/schedule/event_linked_account_profile.dart';
import 'package:belluga_now/presentation/shared/visuals/account_profile_visual_resolver.dart';
import 'package:belluga_now/presentation/shared/visuals/resolved_account_profile_visual.dart';
import 'package:belluga_now/presentation/shared/widgets/account_profile_identity_block.dart';
import 'package:flutter/material.dart';
import 'package:belluga_now/domain/partners/profile_type_registry.dart';

class LinkedProfileCategorySection extends StatelessWidget {
  const LinkedProfileCategorySection({
    required this.title,
    required this.profiles,
    required this.profileTypeRegistry,
    required this.favoriteAccountProfileIds,
    required this.isFavoritable,
    required this.onFavoriteTap,
    super.key,
  });

  final String title;
  final List<EventLinkedAccountProfile> profiles;
  final ProfileTypeRegistry? profileTypeRegistry;
  final Set<String> favoriteAccountProfileIds;
  final bool Function(EventLinkedAccountProfile profile) isFavoritable;
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
    required this.onFavoriteTap,
  });

  final EventLinkedAccountProfile profile;
  final ResolvedAccountProfileVisual resolvedVisual;
  final bool isFavorite;
  final bool isFavoritable;
  final VoidCallback onFavoriteTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final tags = profile.taxonomyTerms
        .map((term) => term.label.trim())
        .where((label) => label.isNotEmpty)
        .take(4)
        .toList(growable: false);

    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        child: Stack(
          children: [
            InkWell(
              key: Key('linkedProfileCardTapTarget_${profile.id}'),
              borderRadius: BorderRadius.circular(24),
              onTap: profile.hasNavigableSlug
                  ? () => context.router
                      .push(PartnerDetailRoute(slug: profile.slug!))
                  : null,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: AccountProfileIdentityBlock(
                  name: profile.displayName,
                  avatarUrl: resolvedVisual.identityAvatarUrl,
                  typeVisual: resolvedVisual.typeVisual,
                  avatarSize: 44,
                  typeAvatarSize: 22,
                  typeAvatarIconSize: 12,
                  avatarSpacing: 10,
                  supportingSpacing: 10,
                  titleStyle: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  supporting: tags.isEmpty
                      ? null
                      : Wrap(
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
                                    color: colorScheme.surface,
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(
                                      color: colorScheme.outlineVariant,
                                    ),
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
                    color: colorScheme.surface.withValues(alpha: 0.94),
                    border: Border.all(color: colorScheme.outlineVariant),
                  ),
                  child: IconButton(
                    key: Key('linkedProfileFavoriteButton_${profile.id}'),
                    onPressed: onFavoriteTap,
                    icon: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: isFavorite
                          ? colorScheme.error
                          : colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
