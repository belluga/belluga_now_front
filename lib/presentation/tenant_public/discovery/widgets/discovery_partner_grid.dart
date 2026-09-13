import 'package:belluga_now/domain/partners/account_profile_complete.dart';
import 'package:belluga_now/presentation/shared/visuals/resolved_account_profile_visual.dart';
import 'package:belluga_now/presentation/tenant_public/discovery/widgets/discovery_partner_card.dart';
import 'package:flutter/material.dart';

class DiscoveryPartnerGrid extends StatelessWidget {
  const DiscoveryPartnerGrid({
    super.key,
    required this.partners,
    required this.favorites,
    required this.isFavoritable,
    required this.onFavoriteTap,
    required this.onPartnerTap,
    required this.resolvedVisualForPartner,
  });

  final List<AccountProfileComplete> partners;
  final Set<String> favorites;
  final bool Function(AccountProfileComplete) isFavoritable;
  final ValueChanged<String> onFavoriteTap;
  final ValueChanged<AccountProfileComplete> onPartnerTap;
  final ResolvedAccountProfileVisual Function(AccountProfileComplete)
  resolvedVisualForPartner;

  @override
  Widget build(BuildContext context) {
    return SliverGrid(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.6,
        crossAxisSpacing: 14,
        mainAxisSpacing: 18,
      ),
      delegate: SliverChildBuilderDelegate((context, index) {
        final partner = partners[index];
        final canOpenPublicDetail = partner.publicDetailUrl != null;
        return DiscoveryPartnerCard(
          partner: partner,
          isFavorite: favorites.contains(partner.id),
          isFavoritable: isFavoritable(partner),
          onFavoriteTap: () => onFavoriteTap(partner.id),
          onTap: canOpenPublicDetail ? () => onPartnerTap(partner) : null,
          resolvedVisual: resolvedVisualForPartner(partner),
        );
      }, childCount: partners.length),
    );
  }
}
