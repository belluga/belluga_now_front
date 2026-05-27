import 'package:flutter/widgets.dart';

class PoiCardReferencePointAction {
  const PoiCardReferencePointAction({
    required this.isActive,
    required this.onTap,
  });

  final bool isActive;
  final VoidCallback onTap;
}
