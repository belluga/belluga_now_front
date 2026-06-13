import 'package:flutter/widgets.dart';

class PoiCardReferencePointAction {
  const PoiCardReferencePointAction({
    required this.isActive,
    required this.onTap,
    this.onClear,
  });

  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback? onClear;
}
