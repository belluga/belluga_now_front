import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/domain/upcoming_ocurrence/projections/upcoming_ocurrence_resume.dart';
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

  final UpcomingOcurrenceResume event;
  final bool isConfirmed;
  final int pendingInvitesCount;
  final String? distanceLabel;

  @override
  Widget build(BuildContext context) {
    final start = event.startDateTime;
    final explicitEnd = event.endDateTime;
    final inferredEnd = explicitEnd ?? start.add(const Duration(hours: 3));
    final now = DateTime.now();
    final isLiveNow = now.isAfter(start) && now.isBefore(inferredEnd);
    final scheduleLabel = isLiveNow
        ? event.agendaScheduleLabel
        : event.detailScheduleLabel;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    const overlayForeground = Colors.white;

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardHeight = constraints.maxWidth * 9 / 16;
        final isCompactCard =
            constraints.maxWidth < 260 || cardHeight < 150;
        final titleStyle =
            (isCompactCard
                    ? theme.textTheme.titleSmall
                    : theme.textTheme.titleMedium)
                ?.copyWith(
                  color: overlayForeground,
                  fontWeight: FontWeight.w800,
                );
        final statusRow = Align(
          alignment: Alignment.topRight,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              InviteStatusIcon(
                isConfirmed: isConfirmed,
                pendingInvitesCount: pendingInvitesCount,
                size: isCompactCard ? 16 : 18,
                backgroundColor: colorScheme.secondary.withValues(
                  alpha: 0.3,
                ),
              ),
              if (isLiveNow) ...[
                const SizedBox(width: 10),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: colorScheme.error,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isCompactCard ? 8 : 10,
                      vertical: isCompactCard ? 4 : 6,
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
        );

        final titleText = Text(
          event.title,
          semanticsLabel: event.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: titleStyle,
        );
        return InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            if (event.slug.isEmpty) return;
            context.router.push(
              ImmersiveEventDetailRoute(
                eventSlug: event.slug,
                occurrenceId: event.selectedOccurrenceId,
              ),
            );
          },
          child: CarouselCard(
            imageUri: event.imageUri,
            overlayMode: CarouselCardOverlayMode.fill,
            overlayAlignment: Alignment.topLeft,
            contentOverlay: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isCompactCard ? 12 : 16,
                vertical: isCompactCard ? 8 : 10,
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Positioned(
                    top: 0,
                    right: 0,
                    child: statusRow,
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    top: isCompactCard ? 44 : 52,
                    child: titleText,
                  ),
                  if (!isCompactCard)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          EventInfoRow(
                            icon: Icons.schedule,
                            label: scheduleLabel,
                            color: overlayForeground.withValues(
                              alpha: 0.95,
                            ),
                          ),
                          const SizedBox(height: 4),
                          EventInfoRow(
                            icon: Icons.place_outlined,
                            label: distanceLabel == null
                                ? event.location
                                : '${event.location} (${distanceLabel!})',
                            color: overlayForeground.withValues(
                              alpha: 0.9,
                            ),
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
