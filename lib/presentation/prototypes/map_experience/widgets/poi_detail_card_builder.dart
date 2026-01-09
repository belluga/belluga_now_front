import 'package:belluga_now/domain/map/city_poi_category.dart';
import 'package:belluga_now/domain/map/city_poi_model.dart';
import 'package:belluga_now/domain/map/event_poi_model.dart';
import 'package:belluga_now/presentation/tenant/map/screens/city_map_screen/widgets/shared/event_temporal_state.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PoiDetailCardBuilder {
  const PoiDetailCardBuilder();

  Widget build({
    required BuildContext context,
    required CityPoiModel poi,
    required ColorScheme colorScheme,
    required VoidCallback onPrimaryAction,
    required VoidCallback onShare,
    required VoidCallback onRoute,
  }) {
    if (poi is EventPoiModel) {
      return _EventPoiDetailCard(
        eventPoi: poi,
        colorScheme: colorScheme,
        onPrimaryAction: onPrimaryAction,
        onShare: onShare,
        onRoute: onRoute,
      );
    }

    switch (poi.category) {
      case CityPoiCategory.restaurant:
        return _RestaurantPoiCard(
          poi: poi,
          colorScheme: colorScheme,
          onPrimaryAction: onPrimaryAction,
          onShare: onShare,
          onRoute: onRoute,
        );
      case CityPoiCategory.beach:
        return _BeachPoiCard(
          poi: poi,
          colorScheme: colorScheme,
          onPrimaryAction: onPrimaryAction,
          onShare: onShare,
          onRoute: onRoute,
        );
      case CityPoiCategory.lodging:
        return _LodgingPoiCard(
          poi: poi,
          colorScheme: colorScheme,
          onPrimaryAction: onPrimaryAction,
          onShare: onShare,
          onRoute: onRoute,
        );
      default:
        return _DefaultPoiCard(
          poi: poi,
          colorScheme: colorScheme,
          onPrimaryAction: onPrimaryAction,
          onShare: onShare,
          onRoute: onRoute,
        );
    }
  }
}

abstract class _BasePoiCard extends StatelessWidget {
  const _BasePoiCard({
    required this.poi,
    required this.colorScheme,
    required this.onPrimaryAction,
    required this.onShare,
    required this.onRoute,
    this.primaryLabel = 'Ver detalhes',
  });

  final CityPoiModel poi;
  final ColorScheme colorScheme;
  final VoidCallback onPrimaryAction;
  final VoidCallback onShare;
  final VoidCallback onRoute;
  final String primaryLabel;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      constraints: const BoxConstraints(maxWidth: 360),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            poi.name,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          for (final section in buildSections()) ...[
            section(context),
            const SizedBox(height: 12),
          ],
          FilledButton(
            onPressed: onPrimaryAction,
            style:
                FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            child: Text(primaryLabel),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                tooltip: 'Traçar rota',
                onPressed: onRoute,
                icon: const Icon(Icons.directions_outlined),
              ),
              const SizedBox(width: 4),
              IconButton(
                tooltip: 'Compartilhar',
                onPressed: onShare,
                icon: const Icon(Icons.share_outlined),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget addressSection(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.place_outlined, size: 18),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            poi.address,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
    );
  }

  Widget tagsSection(BuildContext context) {
    final tags = poi.tags.take(6).toList(growable: false);
    if (tags.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: tags
          .map(
            (tag) => Chip(
              label: Text(tag),
              visualDensity: VisualDensity.compact,
            ),
          )
          .toList(growable: false),
    );
  }

  List<Widget Function(BuildContext)> buildSections();
}

class _DefaultPoiCard extends _BasePoiCard {
  const _DefaultPoiCard({
    required super.poi,
    required super.colorScheme,
    required super.onPrimaryAction,
    required super.onShare,
    required super.onRoute,
  });

  @override
  List<Widget Function(BuildContext)> buildSections() => [
        addressSection,
        tagsSection,
      ];
}

class _RestaurantPoiCard extends _BasePoiCard {
  const _RestaurantPoiCard({
    required super.poi,
    required super.colorScheme,
    required super.onPrimaryAction,
    required super.onShare,
    required super.onRoute,
  }) : super(primaryLabel: 'Ver cardápio');

  @override
  List<Widget Function(BuildContext)> buildSections() => [
        addressSection,
        (context) => Row(
              children: [
                const Icon(Icons.local_dining, size: 18),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Sabores indicados pela curadoria Belluga.',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(fontStyle: FontStyle.italic),
                  ),
                ),
              ],
            ),
        tagsSection,
      ];
}

class _BeachPoiCard extends _BasePoiCard {
  const _BeachPoiCard({
    required super.poi,
    required super.colorScheme,
    required super.onPrimaryAction,
    required super.onShare,
    required super.onRoute,
  }) : super(primaryLabel: 'Ver rota');

  @override
  List<Widget Function(BuildContext)> buildSections() => [
        addressSection,
        (context) => Row(
              children: const [
                Icon(Icons.sunny, size: 18),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Melhor aproveitada durante o dia de hoje.',
                  ),
                ),
              ],
            ),
        tagsSection,
      ];
}

class _LodgingPoiCard extends _BasePoiCard {
  const _LodgingPoiCard({
    required super.poi,
    required super.colorScheme,
    required super.onPrimaryAction,
    required super.onShare,
    required super.onRoute,
  }) : super(primaryLabel: 'Reservar agora');

  @override
  List<Widget Function(BuildContext)> buildSections() => [
        addressSection,
        (context) => Row(
              children: const [
                Icon(Icons.king_bed_outlined, size: 18),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Conferimos disponibilidade especial para você.',
                  ),
                ),
              ],
            ),
        tagsSection,
      ];
}

class _EventPoiDetailCard extends StatelessWidget {
  const _EventPoiDetailCard({
    required this.eventPoi,
    required this.colorScheme,
    required this.onPrimaryAction,
    required this.onShare,
    required this.onRoute,
  });

  final EventPoiModel eventPoi;
  final ColorScheme colorScheme;
  final VoidCallback onPrimaryAction;
  final VoidCallback onShare;
  final VoidCallback onRoute;

  @override
  Widget build(BuildContext context) {
    final event = eventPoi.event;
    final start = event.dateTimeStart.value;
    final formattedDate =
        start != null ? DateFormat('dd MMM, HH:mm').format(start) : '--:--';
    final badgeState =
        resolveEventTemporalState(event, reference: DateTime.now());
    final badgeLabel = switch (badgeState) {
      CityEventTemporalState.now => 'AGORA',
      CityEventTemporalState.past => 'Encerrado',
      CityEventTemporalState.upcoming =>
        start != null ? DateFormat('HH:mm').format(start) : '--:--',
    };
    final badgeColor = switch (badgeState) {
      CityEventTemporalState.now => const Color(0xFFE53935),
      CityEventTemporalState.past => Colors.grey,
      CityEventTemporalState.upcoming => event.type.color.value,
    };

    final artists =
        event.artists.map((artist) => artist.displayName).join(', ');

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      constraints: const BoxConstraints(maxWidth: 360),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Chip(
                backgroundColor: badgeColor,
                label: Text(
                  badgeLabel,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                formattedDate,
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            eventPoi.name,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.place_outlined, size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  eventPoi.address,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
          if (artists.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.music_note_outlined, size: 18),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    artists,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          FilledButton(
            onPressed: onPrimaryAction,
            style:
                FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            child: const Text('Ver detalhes'),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                tooltip: 'Tracar rota',
                onPressed: onRoute,
                icon: const Icon(Icons.directions_outlined),
              ),
              const SizedBox(width: 4),
              IconButton(
                tooltip: 'Compartilhar',
                onPressed: onShare,
                icon: const Icon(Icons.share_outlined),
              ),
            ],
          ),
        ],
      ),
    );
  }

}
