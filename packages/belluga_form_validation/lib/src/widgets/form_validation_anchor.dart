import 'package:flutter/material.dart';

export 'form_validation_anchors.dart';

import 'form_validation_anchors.dart';

class FormValidationAnchor extends StatelessWidget {
  const FormValidationAnchor({
    super.key,
    required this.anchors,
    required this.targetId,
    required this.child,
  });

  final FormValidationAnchors anchors;
  final String targetId;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
      key: anchors.keyFor(targetId),
      child: child,
    );
  }
}
