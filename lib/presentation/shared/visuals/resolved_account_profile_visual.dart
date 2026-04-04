import 'package:belluga_now/presentation/shared/visuals/resolved_profile_type_visual.dart';
import 'package:flutter/material.dart';

class ResolvedAccountProfileVisual {
  const ResolvedAccountProfileVisual({
    required this.typeLabel,
    required this.typeVisual,
    required this.surfaceImageUrl,
    required this.compactImageUrl,
    required this.identityAvatarUrl,
    required this.themeSeedColor,
  });

  final String typeLabel;
  final ResolvedProfileTypeVisual? typeVisual;
  final String? surfaceImageUrl;
  final String? compactImageUrl;
  final String? identityAvatarUrl;
  final Color? themeSeedColor;

  bool get hasIdentityAvatar => identityAvatarUrl != null;
}
