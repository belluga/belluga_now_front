import 'dart:math' as math;
import 'dart:ui';

import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/domain/partners/partner_model.dart';
import 'package:belluga_now/presentation/tenant/discovery/widgets/discovery_partner_card.dart';
import 'package:flutter/material.dart';

/// Carousel for discovery cards with focus/scale animation and hidden details
/// on non-focused items. Targets ~65-75% viewport for the active card.
class DiscoveryCarousel extends StatefulWidget {
  const DiscoveryCarousel({
    super.key,
    required this.partners,
    required this.favorites,
    required this.onFavoriteToggle,
  });

  final List<PartnerModel> partners;
  final Set<String> favorites;
  final void Function(String id) onFavoriteToggle;

  @override
  State<DiscoveryCarousel> createState() => _DiscoveryCarouselState();
}

class _DiscoveryCarouselState extends State<DiscoveryCarousel> {
  late final PageController _controller;
  double _page = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController(viewportFraction: 0.78);
    _controller.addListener(_onScroll);
  }

  void _onScroll() {
    setState(() {
      _page = _controller.page ?? _controller.initialPage.toDouble();
    });
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = screenWidth * 0.78;
    final height = cardWidth * 9 / 16; // similar to "Seus Eventos"

    return SizedBox(
      height: height.clamp(160, 240),
      child: PageView.builder(
        controller: _controller,
        padEnds: false,
        itemCount: widget.partners.length,
        itemBuilder: (context, index) {
          final partner = widget.partners[index];
          final delta = (index - _page).abs();
          final scale =
              lerpDouble(0.95, 1.0, math.max(0, 1 - delta.clamp(0, 1)))!;
          final showDetails = delta < 0.35;

          return Transform.scale(
            scale: scale,
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: DiscoveryPartnerCard(
                partner: partner,
                isFavorite: widget.favorites.contains(partner.id),
                showDetails: showDetails,
                onFavoriteTap: () {
                  widget.onFavoriteToggle(partner.id);
                },
                onTap: () {
                  AutoRouter.of(context)
                      .push(PartnerDetailRoute(slug: partner.slug));
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
