import 'package:belluga_now/domain/partners/account_profile_model.dart';
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
    required this.typeLabelForPartner,
  });

  final List<AccountProfileModel> partners;
  final Set<String> favorites;
  final bool Function(AccountProfileModel) isFavoritable;
  final ValueChanged<String> onFavoriteTap;
  final ValueChanged<AccountProfileModel> onPartnerTap;
  final String Function(AccountProfileModel) typeLabelForPartner;

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
            isFavoritable: isFavoritable(partner),
            onFavoriteTap: () => onFavoriteTap(partner.id),
            onTap: () => onPartnerTap(partner),
            typeLabel: typeLabelForPartner(partner),
          );
        },
        childCount: partners.length,
      ),
    );
  }
}
