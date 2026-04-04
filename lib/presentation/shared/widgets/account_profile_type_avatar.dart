import 'package:belluga_now/presentation/shared/visuals/resolved_profile_type_visual.dart';
import 'package:belluga_now/presentation/shared/widgets/belluga_network_image.dart';
import 'package:flutter/material.dart';

class AccountProfileTypeAvatar extends StatelessWidget {
  const AccountProfileTypeAvatar({
    super.key,
    required this.visual,
    this.size = 28,
    this.iconSize = 16,
  });

  final ResolvedProfileTypeVisual visual;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (visual.isIcon && visual.iconData != null) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: visual.backgroundColor ?? colorScheme.primary,
        ),
        alignment: Alignment.center,
        child: Icon(
          visual.iconData,
          size: iconSize,
          color: visual.iconColor ?? Colors.white,
        ),
      );
    }

    if (visual.isImage && visual.imageUrl != null) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: colorScheme.surfaceContainerHighest,
        ),
        clipBehavior: Clip.antiAlias,
        child: BellugaNetworkImage(
          visual.imageUrl!,
          fit: BoxFit.cover,
          errorWidget: Icon(
            Icons.account_circle,
            size: iconSize,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
