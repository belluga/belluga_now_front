import 'package:belluga_now/presentation/view_models/upcoming_event_data.dart';
import 'package:flutter/material.dart';

class UpcomingEventItem extends StatelessWidget {
  const UpcomingEventItem({super.key, required this.data});

  final UpcomingEventData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- Thumbnail ---
        ClipRRect(
          borderRadius: BorderRadius.circular(12), // M3 standard
          child: Container(
            height: 80, // Increased size
            width: 80, // Increased size
            color: colorScheme.surfaceContainerHigh,
            child: Icon(
              Icons.image_outlined, // Changed to outline
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              size: 40,
            ),
          ),
        ),
        const SizedBox(width: 16),
        // --- Text Content ---
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                data.title,
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              // Sub-header built from adjusted data model
              Text.rich(
                TextSpan(
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: colorScheme.onSurfaceVariant),
                  children: [
                    TextSpan(text: data.category),
                    TextSpan(text: ' • ${data.price}'),
                    TextSpan(text: ' • ${data.distance}'),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              // Rating stars
              Wrap(
                spacing: 2,
                children: List.generate(
                  5,
                  (index) => Icon(
                    index < data.rating ? Icons.star : Icons.star_border,
                    size: 16,
                    color: colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                data.description,
                style: theme.textTheme.bodySmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        // --- Favorite Icon ---
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.favorite_border),
          tooltip: 'Favoritar',
        ),
      ],
    );
  }
}