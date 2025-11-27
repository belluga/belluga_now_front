import 'package:belluga_now/presentation/tenant/widgets/section_header.dart';
import 'package:flutter/material.dart';
import 'package:stream_value/core/stream_value.dart';
import 'package:stream_value/core/stream_value_builder.dart';

/// Generic section that renders a title, optional "see all", and content built from a StreamValue list.
class StreamValueSection<T> extends StatelessWidget {
  const StreamValueSection({
    super.key,
    required this.title,
    required this.stream,
    required this.contentBuilder,
    this.onSeeAll,
    this.loading,
    this.empty,
    this.headerPadding =
        const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    this.contentSpacing = const EdgeInsets.only(top: 4, bottom: 16),
  });

  final String title;
  final StreamValue<List<T>> stream;
  final Widget Function(BuildContext context, List<T> items) contentBuilder;
  final VoidCallback? onSeeAll;
  final Widget? loading;
  final Widget? empty;
  final EdgeInsetsGeometry headerPadding;
  final EdgeInsetsGeometry contentSpacing;

  @override
  Widget build(BuildContext context) {
    return StreamValueBuilder<List<T>>(
      streamValue: stream,
      onNullWidget: loading,
      builder: (context, items) {
        final data = items;
        if (data.isEmpty) {
          return empty ?? const SizedBox.shrink();
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: headerPadding,
              child: SectionHeader(
                title: title,
                onPressed: onSeeAll ?? () {},
              ),
            ),
            Padding(
              padding: contentSpacing,
              child: contentBuilder(context, data),
            ),
          ],
        );
      },
    );
  }
}
