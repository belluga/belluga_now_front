import 'package:belluga_now/domain/map/city_poi_model.dart';
import 'package:belluga_now/presentation/shared/widgets/belluga_network_image.dart';
import 'package:belluga_now/presentation/tenant_public/map/screens/map_screen/widgets/poi_card_secondary_action.dart';
import 'package:belluga_now/presentation/tenant_public/map/screens/map_screen/widgets/shared/poi_content_resolver.dart';
import 'package:flutter/material.dart';

abstract class PoiBaseCard extends StatelessWidget {
  const PoiBaseCard({
    super.key,
    required this.poi,
    required this.colorScheme,
    required this.onPrimaryAction,
    required this.secondaryAction,
    required this.onRoute,
    this.onClose,
    this.heroMaxHeight,
  });

  final CityPoiModel poi;
  final ColorScheme colorScheme;
  final VoidCallback onPrimaryAction;
  final PoiCardSecondaryAction? secondaryAction;
  final VoidCallback onRoute;
  final VoidCallback? onClose;
  final double? heroMaxHeight;

  @override
  Widget build(BuildContext context) {
    final isCompactLayout = heroMaxHeight != null;
    final accentColor = resolveAccentColor();
    final accentForeground = _foregroundFor(accentColor);
    final sectionsBeforeDescription = buildSectionsBeforeDescription();
    final sectionsAfterDescription = buildSectionsAfterDescription();
    final description = PoiContentResolver.sanitizedDescription(poi);
    final hasDescription = description != null;
    final badge = badgeLabel(context).trim();
    final heroPadding = isCompactLayout
        ? const EdgeInsets.fromLTRB(6, 6, 6, 0)
        : const EdgeInsets.fromLTRB(12, 12, 12, 0);
    final badgeInset = isCompactLayout ? 16.0 : 24.0;
    final closeInset = isCompactLayout ? 6.0 : 12.0;
    final bodyPadding = isCompactLayout
        ? const EdgeInsets.fromLTRB(12, 10, 12, 12)
        : const EdgeInsets.fromLTRB(20, 18, 20, 20);
    final titleStyle = (isCompactLayout
            ? Theme.of(context).textTheme.titleLarge
            : Theme.of(context).textTheme.headlineSmall)
        ?.copyWith(
      fontWeight: FontWeight.w900,
      height: 1.02,
      letterSpacing: -0.5,
    );
    final headerGap = isCompactLayout ? 4.0 : 10.0;
    final sectionGap = isCompactLayout ? 6.0 : 12.0;
    final actionsTopGap = isCompactLayout ? 8.0 : 18.0;
    final buttonHeight = isCompactLayout ? 44.0 : 54.0;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        AnimatedContainer(
          key: const ValueKey<String>('poi-detail-card-visual'),
          duration: const Duration(milliseconds: 250),
          constraints: const BoxConstraints(maxWidth: 372),
          decoration: BoxDecoration(
            color: colorScheme.surface.withValues(alpha: 0.98),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.38),
            ),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 28,
                offset: Offset(0, 14),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Padding(
                    padding: heroPadding,
                    child: _buildHero(
                      context,
                      accentColor: accentColor,
                      accentForeground: accentForeground,
                    ),
                  ),
                  if (badge.isNotEmpty)
                    Positioned(
                      top: badgeInset,
                      left: badgeInset,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: accentColor,
                          borderRadius: BorderRadius.circular(999),
                          boxShadow: [
                            BoxShadow(
                              color: accentColor.withValues(alpha: 0.28),
                              blurRadius: 14,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 7,
                          ),
                          child: Text(
                            badge.toUpperCase(),
                            style: Theme.of(context)
                                .textTheme
                                .labelMedium
                                ?.copyWith(
                                  color: accentForeground,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.0,
                                ),
                          ),
                        ),
                      ),
                    ),
                  if (onClose != null)
                    Positioned(
                      top: closeInset,
                      right: closeInset,
                      child: Material(
                        color: colorScheme.surface.withValues(alpha: 0.98),
                        shape: const CircleBorder(),
                        elevation: 8,
                        child: IconButton(
                          tooltip: 'Fechar',
                          onPressed: onClose,
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ),
                    ),
                ],
              ),
              Padding(
                padding: bodyPadding,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_shouldShowHeaderAvatar()) ...[
                          _CardAvatar(
                            poi: poi,
                            accentColor: accentColor,
                          ),
                          const SizedBox(width: 12),
                        ],
                        Expanded(
                          child: Text(
                            poi.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: titleStyle,
                          ),
                        ),
                        if (secondaryAction != null) ...[
                          const SizedBox(width: 12),
                          _CardActionIconButton(
                            tooltip: secondaryAction!.tooltip,
                            icon: secondaryAction!.icon,
                            onTap: secondaryAction!.onTap,
                          ),
                        ],
                      ],
                    ),
                    SizedBox(height: headerGap),
                    buildPrimaryMeta(context, accentColor),
                    for (final section in sectionsBeforeDescription) ...[
                      SizedBox(height: sectionGap),
                      section(context),
                    ],
                    if (hasDescription) ...[
                      SizedBox(height: sectionGap),
                      Text(
                        description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              height: 1.35,
                            ),
                      ),
                    ],
                    for (final section in sectionsAfterDescription) ...[
                      SizedBox(height: sectionGap),
                      section(context),
                    ],
                    SizedBox(height: actionsTopGap),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: onRoute,
                            icon: Icon(routeButtonIcon(context)),
                            style: FilledButton.styleFrom(
                              minimumSize: Size.fromHeight(buttonHeight),
                              backgroundColor: accentColor,
                              foregroundColor: accentForeground,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                              elevation: 0,
                            ),
                            label: Text(routeActionLabel(context)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton.tonal(
                            onPressed: onPrimaryAction,
                            style: FilledButton.styleFrom(
                              minimumSize: Size.fromHeight(buttonHeight),
                              backgroundColor:
                                  colorScheme.surfaceContainerHighest,
                              foregroundColor: colorScheme.onSurface,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                              elevation: 0,
                            ),
                            child: Text(primaryActionLabel(context)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHero(
    BuildContext context, {
    required Color accentColor,
    required Color accentForeground,
  }) {
    final imageUri = PoiContentResolver.coverImageUri(poi);
    final assetPath = PoiContentResolver.assetPath(poi);
    final heroPlaceholder =
        _HeroPlaceholder(accentColor: accentColor, poi: poi);
    final heroBackdrop = _HeroBackdrop(accentColor: accentColor);
    final hasMedia = imageUri != null && imageUri.isNotEmpty ||
        assetPath != null && assetPath.isNotEmpty;
    final heroChild = imageUri != null && imageUri.isNotEmpty
        ? BellugaNetworkImage(
            imageUri,
            fit: BoxFit.cover,
            placeholder: heroPlaceholder,
            errorWidget: heroPlaceholder,
          )
        : assetPath != null && assetPath.isNotEmpty
            ? Image.asset(
                assetPath,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => heroPlaceholder,
              )
            : heroPlaceholder;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth =
            constraints.maxWidth.isFinite ? constraints.maxWidth : 348.0;
        final targetAspectRatio = hasMedia ? 1.56 : 2.18;
        final rawHeight = maxWidth / targetAspectRatio;
        final resolvedHeight = rawHeight.clamp(
          hasMedia ? 156.0 : 128.0,
          hasMedia ? 208.0 : 170.0,
        );
        final boundedHeight = heroMaxHeight == null
            ? resolvedHeight
            : resolvedHeight.clamp(
                hasMedia ? 76.0 : 68.0,
                heroMaxHeight!,
              );

        return ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: SizedBox(
            width: double.infinity,
            height: boundedHeight,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (hasMedia)
                  heroBackdrop,
                heroChild,
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.14),
                        Colors.black.withValues(alpha: 0.32),
                      ],
                      stops: const [0.1, 0.7, 1.0],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String primaryActionLabel(BuildContext context) => 'Ver detalhes';

  IconData routeButtonIcon(BuildContext context) => Icons.near_me_rounded;

  Widget buildPrimaryMeta(BuildContext context, Color accentColor) {
    final metaStyle = Theme.of(context).textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: colorScheme.onSurfaceVariant,
        );
    final mutedStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
        );

    final distance =
        PoiContentResolver.distanceLabel(poi, includeAudienceSuffix: true);
    final locationLine = PoiContentResolver.compactAddress(poi);
    final fallbackType = PoiContentResolver.typeLabel(poi);

    return Wrap(
      spacing: 10,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (distance != null)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.near_me_rounded,
                size: 17,
                color: accentColor,
              ),
              const SizedBox(width: 4),
              Text(distance, style: metaStyle),
            ],
          ),
        if (distance != null && locationLine != null)
          Text('•', style: mutedStyle),
        if (locationLine != null)
          Text(
            locationLine,
            style: mutedStyle,
            overflow: TextOverflow.ellipsis,
          ),
        if (distance == null && locationLine == null && fallbackType.isNotEmpty)
          Text(
            fallbackType,
            style: mutedStyle,
            overflow: TextOverflow.ellipsis,
          ),
      ],
    );
  }

  String badgeLabel(BuildContext context) {
    return PoiContentResolver.badgeLabel(poi);
  }

  String routeActionLabel(BuildContext context) => 'Traçar rota';

  Color resolveAccentColor() {
    return PoiContentResolver.accentColor(poi) ?? colorScheme.primary;
  }

  Color _foregroundFor(Color background) {
    return ThemeData.estimateBrightnessForColor(background) == Brightness.dark
        ? Colors.white
        : Colors.black87;
  }

  bool _shouldShowHeaderAvatar() {
    return poi.refType.trim().toLowerCase() == 'account_profile';
  }

  Widget tagsSection(BuildContext context) {
    final tags = PoiContentResolver.tags(poi);
    if (tags.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: tags
          .map(
            (tag) => Chip(
              label: Text(tag),
              visualDensity: VisualDensity.compact,
              side: BorderSide.none,
              backgroundColor: colorScheme.surfaceContainerHigh,
            ),
          )
          .toList(growable: false),
    );
  }

  List<Widget Function(BuildContext)> buildSectionsBeforeDescription() =>
      const <Widget Function(BuildContext)>[];

  List<Widget Function(BuildContext)> buildSectionsAfterDescription() =>
      buildSections();

  List<Widget Function(BuildContext)> buildSections() =>
      const <Widget Function(BuildContext)>[];
}

class _CardAvatar extends StatelessWidget {
  const _CardAvatar({
    required this.poi,
    required this.accentColor,
  });

  final CityPoiModel poi;
  final Color accentColor;

  static const double _size = 44;

  @override
  Widget build(BuildContext context) {
    final imageUri = PoiContentResolver.thumbnailImageUri(poi);
    final assetPath = PoiContentResolver.assetPath(poi);

    Widget child;
    if (imageUri != null && imageUri.isNotEmpty) {
      child = BellugaNetworkImage(
        imageUri,
        width: _size,
        height: _size,
        fit: BoxFit.cover,
        clipBorderRadius: BorderRadius.circular(_size / 2),
      );
    } else if (assetPath != null && assetPath.isNotEmpty) {
      child = ClipOval(
        child: Image.asset(
          assetPath,
          width: _size,
          height: _size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildPlaceholder(context),
        ),
      );
    } else {
      child = _buildPlaceholder(context);
    }

    return SizedBox(
      key: const ValueKey<String>('poi-card-avatar'),
      width: _size,
      height: _size,
      child: child,
    );
  }

  Widget _buildPlaceholder(BuildContext context) {
    final iconColor = PoiContentResolver.iconColor(poi) ??
        Theme.of(context).colorScheme.onPrimaryContainer;
    final backgroundColor = PoiContentResolver.accentColor(poi) ?? accentColor;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor.withValues(alpha: 0.16),
        shape: BoxShape.circle,
        border: Border.all(
          color: backgroundColor.withValues(alpha: 0.38),
        ),
      ),
      child: Icon(
        PoiContentResolver.icon(poi),
        size: 22,
        color: iconColor,
      ),
    );
  }
}

class _HeroPlaceholder extends StatelessWidget {
  const _HeroPlaceholder({
    required this.accentColor,
    required this.poi,
  });

  final Color accentColor;
  final CityPoiModel poi;

  @override
  Widget build(BuildContext context) {
    final icon = PoiContentResolver.icon(poi);
    final iconColor = PoiContentResolver.iconColor(poi) ?? Colors.white;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accentColor.withValues(alpha: 0.92),
            accentColor.withValues(alpha: 0.62),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          icon,
          size: 64,
          color: iconColor.withValues(alpha: 0.92),
        ),
      ),
    );
  }
}

class _HeroBackdrop extends StatelessWidget {
  const _HeroBackdrop({
    required this.accentColor,
  });

  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      key: const ValueKey<String>('poi-card-hero-backdrop'),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accentColor.withValues(alpha: 0.92),
            accentColor.withValues(alpha: 0.62),
          ],
        ),
      ),
    );
  }
}

class _CardActionIconButton extends StatelessWidget {
  const _CardActionIconButton({
    required this.tooltip,
    required this.icon,
    required this.onTap,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: scheme.surfaceContainerHighest,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: 40,
            height: 40,
            child: Icon(
              icon,
              size: 20,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}
