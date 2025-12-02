import 'package:belluga_now/presentation/tenant/widgets/section_header.dart';
import 'package:flutter/material.dart';
import 'package:stream_value/core/stream_value.dart';
import 'package:stream_value/core/stream_value_builder.dart';

/// Generic section that renders a title, optional "see all", and content built from a StreamValue list.
class CarouselSection<T> extends StatefulWidget {
  const CarouselSection({
    super.key,
    required this.title,
    required this.streamValue,
    this.onSeeAll,
    this.loading,
    this.empty,
    this.headerPadding,
    this.sectionPadding,
    this.contentSpacing = const EdgeInsets.only(top: 4, bottom: 16),
    required this.cardBuilder,
  });

  final String title;
  final StreamValue<List<T>> streamValue;
  final VoidCallback? onSeeAll;
  final Widget? loading;
  final Widget? empty;
  final EdgeInsetsGeometry? headerPadding;
  final EdgeInsetsGeometry? sectionPadding;
  final EdgeInsetsGeometry contentSpacing;
  final Widget Function(T) cardBuilder;

  @override
  State<CarouselSection<T>> createState() => _CarouselSectionState<T>();
}

class _CarouselSectionState<T> extends State<CarouselSection<T>> {
  double get cardWidth => MediaQuery.of(context).size.width * 0.8;
  double get cardHeight => cardWidth * 9 / 16;

  @override
  Widget build(BuildContext context) {
    return StreamValueBuilder<List<T>>(
      streamValue: widget.streamValue,
      onNullWidget: widget.loading,
      builder: (context, items) {
        final data = items;
        if (data.isEmpty) {
          return widget.empty ?? const SizedBox.shrink();
        }
        return Container(
          padding: widget.sectionPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: widget.headerPadding,
                child: SectionHeader(
                  title: widget.title,
                  onPressed: widget.onSeeAll ?? () {},
                ),
              ),
              Padding(
                padding: widget.contentSpacing,
                child: SizedBox(
                  height: cardHeight,
                  child: CarouselView(
                    itemExtent: cardWidth,
                    itemSnapping: true,
                    children:
                        items.map((item) => widget.cardBuilder(item)).toList(),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
