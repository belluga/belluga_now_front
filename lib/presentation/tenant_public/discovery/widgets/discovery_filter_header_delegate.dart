import 'package:belluga_now/presentation/tenant_public/widgets/section_header.dart';
import 'package:flutter/material.dart';

/// Sticky header wrapper for the discovery filter chips.
class DiscoveryFilterHeaderDelegate extends SliverPersistentHeaderDelegate {
  DiscoveryFilterHeaderDelegate({
    required this.extent,
    required this.filterBuilder,
  });

  final double extent;
  final Widget Function() filterBuilder;

  @override
  double get minExtent => extent;

  @override
  double get maxExtent => extent;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      height: extent,
      child: SafeArea(
        top: false,
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  SectionHeader(title: "Todos", onPressed: (){}),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: filterBuilder(),
            ),
          ],
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return true;
  }
}
