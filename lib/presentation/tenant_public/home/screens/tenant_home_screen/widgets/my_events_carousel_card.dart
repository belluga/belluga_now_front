import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/extensions/event_data_formating.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/domain/venue_event/projections/venue_event_resume.dart';
import 'package:belluga_now/presentation/tenant_public/widgets/carousel_card.dart';
import 'package:belluga_now/presentation/tenant_public/widgets/event_info_row.dart';
import 'package:belluga_now/presentation/tenant_public/widgets/invite_status_icon.dart';
import 'package:flutter/material.dart';

class MyEventsCarouselCard extends StatelessWidget {
  const MyEventsCarouselCard({
    super.key,
    required this.event,
    required this.isConfirmed,
    required this.pendingInvitesCount,
    this.distanceLabel,
  });

  final VenueEventResume event;
  final bool isConfirmed;
  final int pendingInvitesCount;
  final String? distanceLabel;

  @override
  Widget build(BuildContext context) {
    final start = event.startDateTime;
    final end = start.add(const Duration(hours: 3));
    final now = DateTime.now();
    final isLiveNow = now.isAfter(start) && now.isBefore(end);
    final scheduleLabel = isLiveNow
        ? '${start.timeLabel} - ${end.timeLabel}'
        : '${start.dayLabel} ${start.monthLabel} • ${start.timeLabel}';
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        return InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            if (event.slug.isEmpty) return;
            context.router.push(
              ImmersiveEventDetailRoute(eventSlug: event.slug),
            );
          },
          child: CarouselCard(
            imageUri: event.imageUri,
            overlayMode: CarouselCardOverlayMode.fill,
            overlayAlignment: Alignment.topLeft,
            contentOverlay: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Align(
                    alignment: Alignment.topRight,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        InviteStatusIcon(
                          isConfirmed: isConfirmed,
                          pendingInvitesCount: pendingInvitesCount,
                          size: 18,
                          backgroundColor:
                              colorScheme.secondary.withValues(alpha: 0.3),
                        ),
                        if (isLiveNow) ...[
                          const SizedBox(width: 10),
                          DecoratedBox(
                            decoration: BoxDecoration(
                              color: colorScheme.error,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              child: Text(
                                'AGORA',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: colorScheme.onError,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.1,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomLeft,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          event.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        EventInfoRow(
                          icon: Icons.schedule,
                          label: scheduleLabel,
                        ),
                        const SizedBox(height: 4),
                        EventInfoRow(
                          icon: Icons.place_outlined,
                          label: distanceLabel == null
                              ? event.location
                              : '${event.location} (${distanceLabel!})',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
