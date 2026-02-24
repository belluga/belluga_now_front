import 'package:belluga_now/domain/map/city_poi_model.dart';
import 'package:flutter/material.dart';

abstract class PoiBaseCard extends StatelessWidget {
  const PoiBaseCard({
    super.key,
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
