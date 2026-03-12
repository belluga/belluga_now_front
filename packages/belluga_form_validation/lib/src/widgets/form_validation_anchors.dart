import 'package:flutter/material.dart';

import '../state/form_validation_state.dart';

class FormValidationAnchors {
  final Map<String, GlobalKey> _keysByTargetId = <String, GlobalKey>{};

  GlobalKey keyFor(String targetId) {
    return _keysByTargetId.putIfAbsent(
      targetId,
      () => GlobalKey(debugLabel: 'form-validation-anchor:$targetId'),
    );
  }

  Future<void> scrollToTarget(
    String targetId, {
    Duration duration = const Duration(milliseconds: 250),
    Curve curve = Curves.easeInOutCubic,
    double alignment = 0.08,
  }) async {
    final targetContext = _keysByTargetId[targetId]?.currentContext;
    if (targetContext == null) {
      return;
    }
    await WidgetsBinding.instance.endOfFrame;
    if (!targetContext.mounted) {
      return;
    }
    await Scrollable.ensureVisible(
      targetContext,
      duration: duration,
      curve: curve,
      alignment: alignment,
    );
  }

  Future<void> scrollToFirstInvalidTarget(
    FormValidationState state, {
    Duration duration = const Duration(milliseconds: 250),
    Curve curve = Curves.easeInOutCubic,
    double alignment = 0.08,
  }) async {
    final targetId = state.firstInvalidTargetId;
    if (targetId == null || targetId.isEmpty) {
      return;
    }
    await scrollToTarget(
      targetId,
      duration: duration,
      curve: curve,
      alignment: alignment,
    );
  }
}
