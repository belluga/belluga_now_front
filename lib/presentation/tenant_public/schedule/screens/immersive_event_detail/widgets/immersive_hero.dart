import 'package:belluga_now/domain/schedule/event_model.dart';
import 'package:belluga_now/domain/venue_event/projections/venue_event_resume.dart';
import 'package:belluga_now/presentation/common/widgets/belluga_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ImmersiveHero extends StatelessWidget {
  const ImmersiveHero({
    required this.event,
    super.key,
  });

  final EventModel event;

  @override
  Widget build(BuildContext context) {
    final resume = VenueEventResume.fromScheduleEvent(
        event, Uri()); // Fallback URI handled in projection if needed

    return Stack(
      fit: StackFit.expand,
      children: [
        // 1. Background Image
        BellugaNetworkImage(
          resume.imageUri.toString(),
          fit: BoxFit.cover,
          errorWidget: Container(color: Colors.grey[900]),
        ),

        // 2. Gradient Overlay for readability
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.3), // Top dim for back button
                Colors.transparent,
                Colors.transparent,
                Colors.black.withValues(alpha: 0.7), // Bottom fade for text
                Colors.black.withValues(alpha: 0.9), // Stronger bottom gradient
              ],
              stops: const [0.0, 0.3, 0.5, 0.85, 1.0],
            ),
          ),
        ),

        // 3. Content
        Positioned(
          bottom:
              20, // Leave space for tabs if they overlap, or just bottom padding
          left: 16,
          right: 16,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Text(
                resume.title,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),

              // Date & Time
              Row(
                children: [
                  const Icon(Icons.calendar_today,
                      color: Colors.white70, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    DateFormat("d 'de' MMMM • HH:mm'h'", 'pt_BR')
                        .format(resume.startDateTime),
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 4),

              // Location
              Row(
                children: [
                  const Icon(Icons.location_on,
                      color: Colors.white70, size: 16),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      resume.location,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Artist Links
              if (resume.hasArtists)
                Wrap(
                  spacing: 8,
                  children: resume.artists.map((artist) {
                    return GestureDetector(
                      onTap: () {
                        // TODO: Navigate to artist profile
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (artist.isHighlight)
                              const Padding(
                                padding: EdgeInsets.only(right: 4),
                                child: Icon(Icons.star,
                                    color: Colors.amber, size: 12),
                              ),
                            Text(
                              artist.displayName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
