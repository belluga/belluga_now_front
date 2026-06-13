import 'package:belluga_now/presentation/shared/widgets/belluga_network_image.dart';
import 'package:flutter/material.dart';

class AppPromotionBrandIcon extends StatelessWidget {
  const AppPromotionBrandIcon({
    super.key,
    required this.colorScheme,
    required this.iconUrl,
    this.size = 96,
    this.iconSize = 56,
    this.borderRadius = 28,
  });

  final ColorScheme colorScheme;
  final String? iconUrl;
  final double size;
  final double iconSize;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final iconChild = iconUrl == null
        ? Icon(
            Icons.phone_iphone_rounded,
            size: iconSize * 0.72,
            color: colorScheme.onPrimaryContainer,
          )
        : BellugaNetworkImage(
            iconUrl!,
            width: iconSize,
            height: iconSize,
            fit: BoxFit.contain,
            errorWidget: Icon(
              Icons.phone_iphone_rounded,
              size: iconSize * 0.72,
              color: colorScheme.onPrimaryContainer,
            ),
          );
    return Container(
      key: const Key('app_promotion_brand_icon'),
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.2),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.18),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: iconChild,
    );
  }
}
