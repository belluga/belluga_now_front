import 'package:belluga_now/domain/map/city_poi_category.dart';
import 'package:belluga_now/domain/map/city_poi_model.dart';
import 'package:belluga_now/presentation/tenant_public/map/screens/map_screen/widgets/shared/map_marker_icon_resolver.dart';
import 'package:flutter/material.dart';

abstract class PoiBaseCard extends StatelessWidget {
  const PoiBaseCard({
    super.key,
    required this.poi,
    required this.colorScheme,
    required this.onPrimaryAction,
    required this.onShare,
    required this.onRoute,
  });

  final CityPoiModel poi;
  final ColorScheme colorScheme;
  final VoidCallback onPrimaryAction;
  final VoidCallback onShare;
  final VoidCallback onRoute;

  @override
  Widget build(BuildContext context) {
    final accentColor = resolveAccentColor();
    final accentForeground = _foregroundFor(accentColor);
    final sections = buildSections();
    final emphasizesPrimaryAction = emphasizePrimaryAction(context);
    final filledLabel = emphasizesPrimaryAction
        ? primaryActionLabel(context)
        : routeActionLabel(context);
    final filledCallback = emphasizesPrimaryAction ? onPrimaryAction : onRoute;
    final secondaryLabel = emphasizesPrimaryAction
        ? routeActionLabel(context)
        : primaryActionLabel(context);
    final secondaryCallback = emphasizesPrimaryAction ? onRoute : onPrimaryAction;
    final trimmedDescription = poi.description.trim();
    final hasDescription = trimmedDescription.isNotEmpty;

    return AnimatedContainer(
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
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                child: _buildHero(
                  context,
                  accentColor: accentColor,
                  accentForeground: accentForeground,
                ),
              ),
              Positioned(
                top: 24,
                left: 24,
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
                      badgeLabel(context).toUpperCase(),
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: accentForeground,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.0,
                          ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        poi.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w900,
                              height: 1.02,
                              letterSpacing: -0.5,
                            ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    _CardActionIconButton(
                      tooltip: 'Compartilhar',
                      icon: Icons.share_outlined,
                      onTap: onShare,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                buildPrimaryMeta(context, accentColor),
                if (hasDescription) ...[
                  const SizedBox(height: 12),
                  Text(
                    trimmedDescription,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          height: 1.35,
                        ),
                  ),
                ],
                for (final section in sections) ...[
                  const SizedBox(height: 12),
                  section(context),
                ],
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: filledCallback,
                        icon: Icon(filledButtonIcon(context)),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(54),
                          backgroundColor: accentColor,
                          foregroundColor: accentForeground,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          elevation: 0,
                        ),
                        label: Text(filledLabel),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.tonal(
                        onPressed: secondaryCallback,
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(54),
                          backgroundColor:
                              colorScheme.surfaceContainerHighest,
                          foregroundColor: colorScheme.onSurface,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          elevation: 0,
                        ),
                        child: Text(secondaryLabel),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHero(
    BuildContext context, {
    required Color accentColor,
    required Color accentForeground,
  }) {
    final imageUri =
        poi.visual?.isImage == true ? poi.visual?.imageUri?.trim() : null;
    final assetPath = poi.assetPath?.trim();
    final hasMedia =
        imageUri != null && imageUri.isNotEmpty ||
        assetPath != null && assetPath.isNotEmpty;
    final heroChild =
        imageUri != null && imageUri.isNotEmpty
            ? Image.network(
                imageUri,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    _HeroPlaceholder(accentColor: accentColor, poi: poi),
              )
            : assetPath != null && assetPath.isNotEmpty
                ? Image.asset(
                    assetPath,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        _HeroPlaceholder(accentColor: accentColor, poi: poi),
                  )
                : _HeroPlaceholder(accentColor: accentColor, poi: poi);

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: AspectRatio(
        aspectRatio: hasMedia ? 1.56 : 2.18,
        child: Stack(
          fit: StackFit.expand,
          children: [
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
  }

  bool emphasizePrimaryAction(BuildContext context) => false;

  String primaryActionLabel(BuildContext context) => 'Ver detalhes';

  IconData filledButtonIcon(BuildContext context) =>
      emphasizePrimaryAction(context)
          ? Icons.visibility_outlined
          : Icons.near_me_rounded;

  Widget buildPrimaryMeta(BuildContext context, Color accentColor) {
    final metaStyle = Theme.of(context).textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: colorScheme.onSurfaceVariant,
        );
    final mutedStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
        );

    final distance = formatDistance();
    final locationLine = formatLocationContext();

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
      ],
    );
  }

  String badgeLabel(BuildContext context) {
    return switch (poi.category) {
      CityPoiCategory.restaurant => 'Restaurante',
      CityPoiCategory.health => 'Saúde',
      CityPoiCategory.monument => 'Monumento',
      CityPoiCategory.church => 'Igreja',
      CityPoiCategory.beach => 'Praia',
      CityPoiCategory.lodging => 'Hospedagem',
      CityPoiCategory.culture => poi.isDynamic ? 'Evento' : 'Cultura',
      CityPoiCategory.nature => 'Natureza',
      CityPoiCategory.sponsor => 'Destaque',
      CityPoiCategory.attraction => 'Lugar',
    };
  }

  String routeActionLabel(BuildContext context) => 'Traçar rota';

  String? formatDistance() {
    final distance = poi.distanceMeters;
    if (distance == null || !distance.isFinite || distance <= 0) {
      return null;
    }
    if (distance < 1000) {
      return '${distance.round()}m de você';
    }
    final inKm = distance / 1000;
    return '${inKm.toStringAsFixed(inKm >= 10 ? 0 : 1)} km de você';
  }

  String? formatLocationContext() {
    final address = poi.address.trim();
    if (address.isEmpty) {
      return null;
    }
    final compact = address
        .split(',')
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .take(2)
        .toList(growable: false);
    if (compact.isEmpty) {
      return address;
    }
    return compact.join(' • ');
  }

  Color resolveAccentColor() {
    final visual = poi.visual;
    if (visual?.isIcon == true) {
      return MapMarkerIconResolver.tryParseHexColor(visual?.colorHex) ??
          colorScheme.primary;
    }
    return switch (poi.category) {
      CityPoiCategory.beach => const Color(0xFF1478C8),
      CityPoiCategory.restaurant => const Color(0xFF8F27C7),
      CityPoiCategory.lodging => const Color(0xFF355C7D),
      CityPoiCategory.health => const Color(0xFF117E96),
      CityPoiCategory.monument => const Color(0xFF805437),
      CityPoiCategory.church => const Color(0xFF6A4FB3),
      CityPoiCategory.culture => const Color(0xFFD64D4D),
      CityPoiCategory.nature => const Color(0xFF2D8A52),
      CityPoiCategory.sponsor => const Color(0xFFB26B13),
      CityPoiCategory.attraction => colorScheme.primary,
    };
  }

  Color _foregroundFor(Color background) {
    return ThemeData.estimateBrightnessForColor(background) == Brightness.dark
        ? Colors.white
        : Colors.black87;
  }

  Widget addressSection(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.place_outlined,
          size: 18,
          color: colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            poi.address,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
          ),
        ),
      ],
    );
  }

  Widget tagsSection(BuildContext context) {
    final tags = poi.tags.take(4).toList(growable: false);
    if (tags.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: tags
          .map(
            (tag) => Chip(
              label: Text(tag.value),
              visualDensity: VisualDensity.compact,
              side: BorderSide.none,
              backgroundColor: colorScheme.surfaceContainerHigh,
            ),
          )
          .toList(growable: false),
    );
  }

  List<Widget Function(BuildContext)> buildSections();
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
    final icon = poi.visual?.isIcon == true
        ? MapMarkerIconResolver.resolve(poi.visual?.icon)
        : MapMarkerIconResolver.fallbackIcon;
    final iconColor = poi.visual?.isIcon == true
        ? (MapMarkerIconResolver.tryParseHexColor(poi.visual?.iconColorHex) ??
            Colors.white)
        : Colors.white;

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
