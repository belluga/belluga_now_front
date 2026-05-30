import 'dart:async';

import 'package:belluga_now/presentation/shared/widgets/directions_app_chooser/directions_app_chooser_contract.dart';
import 'package:belluga_now/presentation/shared/widgets/directions_app_chooser/directions_launch_target.dart';
import 'package:belluga_now/presentation/shared/widgets/directions_app_chooser/directions_provider_brand_asset.dart';
import 'package:belluga_now/presentation/shared/widgets/directions_app_chooser/directions_provider_brand_catalog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class DirectionsProviderActions extends StatelessWidget {
  const DirectionsProviderActions({
    super.key,
    required this.target,
    required this.isPrimary,
    required this.onOpenDirectDirections,
    required this.onOpenOtherDirections,
    this.wazeButtonKey,
    this.uberButtonKey,
    this.otherButtonKey,
  });

  final DirectionsLaunchTarget target;
  final bool isPrimary;
  final Future<void> Function(
    DirectionsDirectProvider provider,
    DirectionsLaunchTarget target,
  )? onOpenDirectDirections;
  final Future<void> Function(DirectionsLaunchTarget target)?
      onOpenOtherDirections;
  final Key? wazeButtonKey;
  final Key? uberButtonKey;
  final Key? otherButtonKey;

  @override
  Widget build(BuildContext context) {
    if (!target.hasLaunchableDestination) {
      return const SizedBox.shrink();
    }

    final height = isPrimary ? 48.0 : 38.0;
    final textStyle = Theme.of(context).textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w800,
          fontSize: isPrimary ? 14 : 12,
        );
    return Row(
      children: [
        Expanded(
          child: _DirectionProviderButton(
            key: wazeButtonKey,
            label: DirectionsProviderBrandCatalog.waze.label,
            brand: DirectionsProviderBrandCatalog.waze,
            height: height,
            isPrimary: isPrimary,
            textStyle: textStyle,
            onPressed: onOpenDirectDirections == null
                ? null
                : () => unawaited(
                      onOpenDirectDirections!(
                        DirectionsDirectProvider.waze,
                        target,
                      ),
                    ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _DirectionProviderButton(
            key: uberButtonKey,
            label: DirectionsProviderBrandCatalog.uber.label,
            brand: DirectionsProviderBrandCatalog.uber,
            height: height,
            isPrimary: isPrimary,
            textStyle: textStyle,
            onPressed: onOpenDirectDirections == null || !target.hasCoordinates
                ? null
                : () => unawaited(
                      onOpenDirectDirections!(
                        DirectionsDirectProvider.uber,
                        target,
                      ),
                    ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: isPrimary ? 56 : 44,
          child: _DirectionProviderButton(
            key: otherButtonKey,
            label: '',
            icon: Icons.more_horiz,
            semanticLabel: 'Outros',
            height: height,
            isPrimary: isPrimary,
            textStyle: textStyle,
            onPressed: onOpenOtherDirections == null
                ? null
                : () => unawaited(onOpenOtherDirections!(target)),
          ),
        ),
      ],
    );
  }
}

class _DirectionProviderButton extends StatelessWidget {
  const _DirectionProviderButton({
    super.key,
    required this.label,
    this.brand,
    this.icon,
    this.semanticLabel,
    required this.height,
    required this.isPrimary,
    required this.textStyle,
    required this.onPressed,
  });

  final String label;
  final DirectionsProviderBrandAsset? brand;
  final IconData? icon;
  final String? semanticLabel;
  final double height;
  final bool isPrimary;
  final TextStyle? textStyle;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final child = label.isEmpty
        ? Icon(icon, size: 20, semanticLabel: semanticLabel)
        : brand == null
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textStyle,
                    ),
                  ),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Semantics(
                    label: label,
                    button: true,
                    child: ExcludeSemantics(
                      child: _DirectionProviderLogo(
                        brand: brand!,
                        isPrimary: isPrimary,
                        enabled: enabled,
                      ),
                    ),
                  ),
                ],
              );

    final theme = Theme.of(context);
    final buttonStyle = brand == null
        ? FilledButton.styleFrom(
            minimumSize: Size(0, height),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            padding: EdgeInsets.symmetric(horizontal: label.isEmpty ? 8 : 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          )
        : FilledButton.styleFrom(
            backgroundColor: brand!.backgroundColor,
            foregroundColor: brand!.foregroundColor,
            disabledBackgroundColor: theme.colorScheme.surfaceContainerHighest,
            disabledForegroundColor:
                theme.colorScheme.onSurface.withValues(alpha: 0.38),
            minimumSize: Size(0, height),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          );

    return SizedBox(
      height: height,
      child: FilledButton.tonal(
        onPressed: onPressed,
        style: buttonStyle,
        child: child,
      ),
    );
  }
}

class _DirectionProviderLogo extends StatelessWidget {
  const _DirectionProviderLogo({
    required this.brand,
    required this.isPrimary,
    required this.enabled,
  });

  final DirectionsProviderBrandAsset brand;
  final bool isPrimary;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final size = isPrimary ? brand.primaryLogoSize : brand.compactLogoSize;
    final disabledColor =
        Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38);
    final logo = switch (brand.assetType) {
      DirectionsProviderBrandAssetType.rasterImage => Image.asset(
          brand.assetPath,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) =>
              _DirectionProviderLogoFallback(label: brand.label),
        ),
      DirectionsProviderBrandAssetType.svg => SvgPicture.asset(
          brand.assetPath,
          fit: BoxFit.contain,
          colorFilter: !enabled
              ? ColorFilter.mode(disabledColor, BlendMode.srcIn)
              : brand.logoTint == null
                  ? null
                  : ColorFilter.mode(brand.logoTint!, BlendMode.srcIn),
          placeholderBuilder: (context) =>
              _DirectionProviderLogoFallback(label: brand.label),
        ),
    };

    final child =
        brand.assetType == DirectionsProviderBrandAssetType.rasterImage
            ? Opacity(
                opacity: enabled ? 1 : 0.38,
                child: logo,
              )
            : logo;

    return SizedBox(
      width: size.width,
      height: size.height,
      child: child,
    );
  }
}

class _DirectionProviderLogoFallback extends StatelessWidget {
  const _DirectionProviderLogoFallback({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
    );
  }
}
