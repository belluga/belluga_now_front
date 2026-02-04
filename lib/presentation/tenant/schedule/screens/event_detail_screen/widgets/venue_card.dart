import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/domain/partner/partner_resume.dart';
import 'package:belluga_now/presentation/common/widgets/belluga_network_image.dart';
import 'package:flutter/material.dart';

class VenueCard extends StatelessWidget {
  const VenueCard({super.key, required this.venue});

  final PartnerResume venue;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final slug = venue.slug;
    final canOpen = slug != null && slug.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant,
        ),
      ),
      child: Row(
        children: [
          if (venue.logoImageUri != null)
            BellugaNetworkImage(
              venue.logoImageUri!.toString(),
              width: 48,
              height: 48,
              fit: BoxFit.cover,
              clipBorderRadius: BorderRadius.circular(8),
              errorWidget: Container(
                width: 48,
                height: 48,
                color: colorScheme.surfaceContainerHighest,
                child: Icon(Icons.store, color: colorScheme.onSurfaceVariant),
              ),
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Onde',
                  style: textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  venue.displayName,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (venue.tagline != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    venue.tagline!,
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          if (canOpen)
            TextButton(
              onPressed: () {
                context.router.push(PartnerDetailRoute(slug: slug));
              },
              child: const Text('Ver perfil'),
            ),
        ],
      ),
    );
  }
}
