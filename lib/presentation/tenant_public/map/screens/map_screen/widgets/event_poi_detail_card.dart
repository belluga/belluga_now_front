import 'package:belluga_now/domain/map/city_poi_model.dart';
import 'package:flutter/material.dart';

class EventPoiDetailCard extends StatelessWidget {
  const EventPoiDetailCard({
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
    final badgeLabel = poi.isHappeningNow ? 'AGORA' : 'EVENTO';
    final badgeColor = poi.isHappeningNow ? const Color(0xFFE53935) : colorScheme.primary;

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
                poi.updatedAt == null
                    ? 'Atualização indisponível'
                    : 'Atualizado recentemente',
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            poi.name,
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
                  poi.address,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            poi.description,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: onPrimaryAction,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
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
