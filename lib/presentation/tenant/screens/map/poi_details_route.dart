import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/domain/map/city_poi_model.dart';
import 'package:belluga_now/presentation/tenant/screens/map/widgets/poi_category_theme.dart';
import 'package:flutter/material.dart';

@RoutePage(name: 'PoiDetailsRoute')
class PoiDetailsRoutePage extends StatelessWidget {
  const PoiDetailsRoutePage({super.key, required this.poi});

  final CityPoiModel poi;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final themeData = categoryTheme(poi.category, scheme);

    return Scaffold(
      appBar: AppBar(
        title: Text(poi.name),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: themeData.color.withOpacity(0.12),
                  child: Icon(themeData.icon, color: themeData.color, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    themeData.label,
                    style: textTheme.titleMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Sobre',
              style:
                  textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              poi.description,
              style: textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            Text(
              'Endereço',
              style:
                  textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              poi.address,
              style: textTheme.bodyLarge,
            ),
            if (poi.tags.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text(
                'Tags',
                style: textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: poi.tags
                    .map(
                      (tag) => Chip(
                        label: Text(_formatTag(tag)),
                      ),
                    )
                    .toList(growable: false),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatTag(String value) {
    if (value.length <= 1) {
      return value.toUpperCase();
    }
    return value[0].toUpperCase() + value.substring(1);
  }
}
