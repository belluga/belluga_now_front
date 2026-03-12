import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class SizeReportingWidget extends SingleChildRenderObjectWidget {
  const SizeReportingWidget({
    super.key,
    required this.onSizeChanged,
    required Widget child,
  }) : super(child: child);

  final ValueChanged<Size> onSizeChanged;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderSizeReporting(onSizeChanged);
  }

  @override
  void updateRenderObject(
    BuildContext context,
    covariant RenderObject renderObject,
  ) {
    (renderObject as _RenderSizeReporting).onSizeChanged = onSizeChanged;
  }
}

class _RenderSizeReporting extends RenderProxyBox {
  _RenderSizeReporting(this.onSizeChanged);

  ValueChanged<Size> onSizeChanged;
  Size? _oldSize;

  @override
  void performLayout() {
    super.performLayout();
    if (size != _oldSize) {
      _oldSize = size;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (attached) {
          onSizeChanged(size);
        }
      });
    }
  }
}
