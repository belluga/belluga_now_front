import 'package:flutter/rendering.dart';

extension ColorToHex on Color {
  /// Converts an integer channel value (0-255) to a two-character hex string.
  String _intToHex(int v) => v.toRadixString(16).padLeft(2, '0');

  /// Converts the color to a hex string (#RRGGBB).
  String toHex() {
    final r = (this.r * 255).round();
    final g = (this.g * 255).round();
    final b = (this.b * 255).round();
    return '#${_intToHex(r)}${_intToHex(g)}${_intToHex(b)}';
  }

  /// Converts the color to a hex string with alpha (#AARRGGBB).
  String toHexWithAlpha() {
    final a = (this.a * 255).round();
    final r = (this.r * 255).round();
    final g = (this.g * 255).round();
    final b = (this.b * 255).round();
    return '#${_intToHex(a)}${_intToHex(r)}${_intToHex(g)}${_intToHex(b)}';
  }
}
