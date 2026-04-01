import 'package:flutter/material.dart';

/// Sticky header wrapper for the discovery filter chips.
class DiscoveryFilterHeaderDelegate extends SliverPersistentHeaderDelegate {
  DiscoveryFilterHeaderDelegate({
    required this.extent,
    required this.title,
    required this.filterBuilder,
    this.action,
  });

  final double extent;
  final String title;
  final Widget Function() filterBuilder;
  final Widget? action;

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
                  Expanded(
                    child: Text(
                      title,
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                    ),
                  ),
                  if (action != null) action!,
                ],
              ),
            ),
            filterBuilder(),
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
