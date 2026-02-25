import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/domain/schedule/event_model.dart';
import 'package:flutter/material.dart';

class LocationSection extends StatelessWidget {
  const LocationSection({
    required this.event,
    super.key,
  });

  final EventModel event;

  @override
  Widget build(BuildContext context) {
    final venueSlug = event.venue?.slug;
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16).copyWith(bottom: 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Como chegar',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text(
            event.location.value,
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 16),
          // TODO: Add map widget
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text('Mapa (TODO)'),
            ),
          ),
          if (venueSlug != null && venueSlug.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  context.router.push(PartnerDetailRoute(slug: venueSlug));
                },
                icon: const Icon(Icons.storefront_outlined),
                label: const Text('Ver perfil do local'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
