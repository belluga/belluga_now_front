import 'package:belluga_now/presentation/view_models/event_card_data.dart';
import 'package:flutter/material.dart';

class CarouselEventCard extends StatelessWidget {
  const CarouselEventCard({super.key ,required this.data});

  final EventCardData data;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Center(
                child: Icon(
                  Icons.confirmation_num_outlined, // Placeholder icon
                  size: 64,
                ),
              ),
            ),
            // Kept your data-driven text
            Text(
              data.title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              data.subtitle,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}