import 'package:belluga_now/domain/partners/partner_model.dart';
import 'package:belluga_now/presentation/tenant/discovery/widgets/discovery_partner_card.dart';
import 'package:flutter/material.dart';

class DiscoveryPartnerGrid extends StatelessWidget {
  const DiscoveryPartnerGrid({
    super.key,
    required this.partners,
    required this.favorites,
    required this.onFavoriteTap,
    required this.onPartnerTap,
  });

  final List<PartnerModel> partners;
  final Set<String> favorites;
  final ValueChanged<String> onFavoriteTap;
  final ValueChanged<PartnerModel> onPartnerTap;

  @override
  Widget build(BuildContext context) {
    return SliverGrid(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final partner = partners[index];
          return DiscoveryPartnerCard(
            partner: partner,
            isFavorite: favorites.contains(partner.id),
            onFavoriteTap: () => onFavoriteTap(partner.id),
            onTap: () => onPartnerTap(partner),
          );
        },
        childCount: partners.length,
      ),
    );
  }
}
