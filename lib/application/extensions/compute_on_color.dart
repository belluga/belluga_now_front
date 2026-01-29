import 'dart:math' as math;

import 'package:flutter/material.dart';

extension ComputeOnColor on Color {
  /// Picks the highest-contrast foreground from a set of candidates.
  /// Defaults to white/black with a 4.5:1 target contrast.
  Color computeIconColor(
    BuildContext context, {
    double minContrast = 4.5,
    List<Color>? candidates,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final options = candidates ??
        <Color>[
          scheme.onSurface,
          scheme.onPrimary,
          scheme.onSecondary,
          Colors.white,
          Colors.black,
        ];

    Color? best;
    double bestContrast = 0;
    for (final color in options) {
      final contrast = _contrastRatio(this, color);
      if (contrast > bestContrast) {
        best = color;
        bestContrast = contrast;
      }
    }

    // If none meet the target, still return the highest contrast found.
    return best ?? scheme.onSurface;
  }

  double _contrastRatio(Color bg, Color fg) {
    final l1 = bg.computeLuminance();
    final l2 = fg.computeLuminance();
    final bright = math.max(l1, l2);
    final dark = math.min(l1, l2);
    return (bright + 0.05) / (dark + 0.05);
  }
}
