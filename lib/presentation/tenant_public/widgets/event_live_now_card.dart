import 'dart:ui';

import 'package:belluga_now/presentation/shared/widgets/belluga_network_image.dart';
import 'package:belluga_now/presentation/tenant_public/widgets/event_info_row.dart';
import 'package:belluga_now/presentation/tenant_public/widgets/invite_status_icon.dart';
import 'package:belluga_now/domain/venue_event/projections/venue_event_resume.dart';
import 'package:flutter/material.dart';

class EventLiveNowCard extends StatelessWidget {
  const EventLiveNowCard({
    super.key,
    required this.event,
    this.onTap,
    this.isConfirmed = false,
    this.pendingInvitesCount = 0,
    this.distanceLabel,
  });

  final VenueEventResume event;
  final VoidCallback? onTap;
  final bool isConfirmed;
  final int pendingInvitesCount;
  final String? distanceLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final brightness = Theme.of(context).brightness;
    final timeRange = event.endDateTime == null
        ? event.scheduleDisplay.withDefaultFallbackEnd().agendaLabel
        : event.agendaScheduleLabel;
    final onOverlay = Colors.white;

    return LayoutBuilder(
      builder: (context, constraints) {
        final height = constraints.maxWidth * 9 / 16 * 0.8;
        final isCompactCard =
            constraints.maxWidth < 260 || height < 110;
        final titleStyle =
            (isCompactCard
                    ? theme.textTheme.titleSmall
                    : theme.textTheme.titleMedium)
                ?.copyWith(
                  color: onOverlay,
                  fontWeight: FontWeight.w800,
                );
        final statusRow = Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            InviteStatusIcon(
              isConfirmed: isConfirmed,
              pendingInvitesCount: pendingInvitesCount,
              size: isCompactCard ? 16 : 18,
              backgroundColor: colorScheme.secondary.withValues(
                alpha: 0.3,
              ),
            ),
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
        );
        final titleText = Text(
          event.title,
          semanticsLabel: event.title,
          maxLines: isCompactCard ? 1 : 2,
          overflow: TextOverflow.ellipsis,
          style: titleStyle,
        );

        return SizedBox(
          width: constraints.maxWidth,
          height: height,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              fit: StackFit.expand,
              children: [
                ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                  child: BellugaNetworkImage(
                    event.imageUri.toString(),
                    fit: BoxFit.cover,
                    errorWidget: Container(
                      color: colorScheme.surfaceContainerHighest,
                      child: Icon(
                        Icons.broken_image,
                        size: 40,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: brightness == Brightness.dark
                          ? [
                              Colors.black.withValues(alpha: 0.78),
                              Colors.black.withValues(alpha: 0.35),
                            ]
                          : [
                              Colors.black.withValues(alpha: 0.65),
                              Colors.black.withValues(alpha: 0.3),
                            ],
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: AnimatedSwitcher(
                    duration: Duration.zero,
                    child: isCompactCard
                        ? Column(
                            key: const ValueKey('liveContentCompact'),
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              statusRow,
                              const SizedBox(height: 6),
                              titleText,
                            ],
                          )
                        : Column(
                            key: const ValueKey('liveContent'),
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              statusRow,
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  titleText,
                                  const SizedBox(height: 10),
                                  EventInfoRow(
                                    icon: Icons.schedule,
                                    label: timeRange,
                                    color: onOverlay.withValues(alpha: 0.95),
                                  ),
                                  const SizedBox(height: 6),
                                  EventInfoRow(
                                    icon: Icons.place_outlined,
                                    label: event.location,
                                    color: onOverlay.withValues(alpha: 0.9),
                                  ),
                                  if (distanceLabel != null) ...[
                                    const SizedBox(height: 6),
                                    EventInfoRow(
                                      icon: Icons.near_me_outlined,
                                      label: distanceLabel!,
                                      color: onOverlay.withValues(alpha: 0.9),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                  ),
                ),
                Positioned.fill(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: onTap,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
