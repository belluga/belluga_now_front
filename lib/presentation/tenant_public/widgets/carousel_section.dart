import 'package:belluga_now/presentation/tenant_public/widgets/section_header.dart';
import 'package:flutter/material.dart';

/// Generic section that renders a title, optional "see all", and content built from a list.
class CarouselSection<T> extends StatelessWidget {
  const CarouselSection({
    super.key,
    required this.title,
    required this.items,
    this.onSeeAll,
    this.onTitleTap,
    this.empty,
    this.headerPadding,
    this.sectionPadding,
    this.contentSpacing = const EdgeInsets.only(top: 4, bottom: 16),
    this.maxItems,
    this.overflowTrailing,
    required this.cardBuilder,
  });

  final String title;
  final List<T> items;
  final VoidCallback? onSeeAll;
  final VoidCallback? onTitleTap;
  final Widget? empty;
  final EdgeInsetsGeometry? headerPadding;
  final EdgeInsetsGeometry? sectionPadding;
  final EdgeInsetsGeometry contentSpacing;
  final int? maxItems;
  final Widget? overflowTrailing;
  final Widget Function(T) cardBuilder;

  @override
  Widget build(BuildContext context) {
    final data = items;
    if (data.isEmpty) {
      return empty ?? const SizedBox.shrink();
    }

    final cardWidth = MediaQuery.of(context).size.width * 0.8;
    final cardHeight = cardWidth * 9 / 16;
    final hasOverflow = maxItems != null && data.length > maxItems!;
    final reserveTrailing = hasOverflow && overflowTrailing != null ? 1 : 0;
    final takeCount = maxItems != null
        ? (maxItems! - reserveTrailing).clamp(0, data.length)
        : data.length;
    final displayItems = data.take(takeCount).toList();

    return Container(
      padding: sectionPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: headerPadding,
            child: SectionHeader(
              title: title,
              onPressed: onSeeAll ?? () {},
              onTitleTap: onTitleTap,
            ),
          ),
          Padding(
            padding: contentSpacing,
            child: SizedBox(
              height: cardHeight,
              child: CarouselView(
                itemExtent: cardWidth,
                itemSnapping: true,
                enableSplash: false,
                children: [
                  ...displayItems.map((item) => cardBuilder(item)),
                  if (hasOverflow && overflowTrailing != null)
                    overflowTrailing!,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
