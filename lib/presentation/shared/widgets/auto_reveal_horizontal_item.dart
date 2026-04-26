import 'dart:async';

import 'package:flutter/material.dart';

class AutoRevealHorizontalItem extends StatefulWidget {
  const AutoRevealHorizontalItem({
    required this.selected,
    required this.child,
    super.key,
  });

  final bool selected;
  final Widget child;

  @override
  State<AutoRevealHorizontalItem> createState() =>
      _AutoRevealHorizontalItemState();
}

class _AutoRevealHorizontalItemState extends State<AutoRevealHorizontalItem> {
  bool _isRevealScheduled = false;

  @override
  void initState() {
    super.initState();
    _scheduleRevealIfSelected();
  }

  @override
  void didUpdateWidget(covariant AutoRevealHorizontalItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selected && !oldWidget.selected) {
      _scheduleRevealIfSelected();
    }
  }

  void _scheduleRevealIfSelected() {
    if (!widget.selected || _isRevealScheduled) {
      return;
    }
    _isRevealScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _isRevealScheduled = false;
      if (!mounted || !widget.selected) {
        return;
      }
      _revealHorizontallyIfNeeded(context);
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

void _revealHorizontallyIfNeeded(BuildContext context) {
  final scrollable = Scrollable.maybeOf(context);
  if (scrollable == null) {
    return;
  }

  final targetBox = context.findRenderObject();
  final viewportBox = scrollable.context.findRenderObject();
  if (targetBox is! RenderBox || viewportBox is! RenderBox) {
    return;
  }

  final targetOffset = targetBox.localToGlobal(
    Offset.zero,
    ancestor: viewportBox,
  );
  final targetRect = targetOffset & targetBox.size;
  final viewportWidth = viewportBox.size.width;
  const edgePadding = 8.0;

  double scrollDelta = 0;
  if (targetRect.left < edgePadding) {
    scrollDelta = targetRect.left - edgePadding;
  } else if (targetRect.right > viewportWidth - edgePadding) {
    scrollDelta = targetRect.right - viewportWidth + edgePadding;
  }

  if (scrollDelta == 0) {
    return;
  }

  final position = scrollable.position;
  final targetPixels = (position.pixels + scrollDelta)
      .clamp(position.minScrollExtent, position.maxScrollExtent)
      .toDouble();
  if ((targetPixels - position.pixels).abs() < 0.5) {
    return;
  }

  unawaited(position.animateTo(
    targetPixels,
    duration: const Duration(milliseconds: 180),
    curve: Curves.easeOutCubic,
  ));
}
