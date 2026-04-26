import 'package:belluga_now/presentation/shared/widgets/belluga_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class LandlordBrandImage extends StatelessWidget {
  const LandlordBrandImage({
    super.key,
    required this.url,
    required this.fallbackLabel,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.foregroundColor,
    this.backgroundColor,
  });

  final String? url;
  final String fallbackLabel;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Color? foregroundColor;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final resolvedUrl = url?.trim();
    final fallback = _BrandFallback(
      label: fallbackLabel,
      width: width,
      height: height,
      foregroundColor: foregroundColor,
      backgroundColor: backgroundColor,
    );

    if (resolvedUrl == null || resolvedUrl.isEmpty) {
      return fallback;
    }

    if (Uri.tryParse(resolvedUrl)?.path.toLowerCase().endsWith('.svg') ??
        false) {
      return SvgPicture.network(
        resolvedUrl,
        width: width,
        height: height,
        fit: fit,
        placeholderBuilder: (_) => fallback,
      );
    }

    return BellugaNetworkImage(
      resolvedUrl,
      width: width,
      height: height,
      fit: fit,
      placeholder: fallback,
      errorWidget: fallback,
    );
  }
}

class _BrandFallback extends StatelessWidget {
  const _BrandFallback({
    required this.label,
    this.width,
    this.height,
    this.foregroundColor,
    this.backgroundColor,
  });

  final String label;
  final double? width;
  final double? height;
  final Color? foregroundColor;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      width: width,
      height: height,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: backgroundColor ?? colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(18),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.titleMedium?.copyWith(
          color: foregroundColor ?? colorScheme.onSurface,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
