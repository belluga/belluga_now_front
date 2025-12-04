import 'dart:ui';

import 'package:belluga_now/application/extensions/event_data_formating.dart';
import 'package:belluga_now/presentation/tenant/widgets/event_info_row.dart';
import 'package:belluga_now/presentation/tenant/widgets/invite_status_icon.dart';
import 'package:belluga_now/domain/venue_event/projections/venue_event_resume.dart';
import 'package:flutter/material.dart';

class EventLiveNowCard extends StatelessWidget {
  const EventLiveNowCard({
    super.key,
    required this.event,
    this.onTap,
    this.assumedDuration = const Duration(hours: 3),
    this.isConfirmed = false,
    this.pendingInvitesCount = 0,
  });

  final VenueEventResume event;
  final VoidCallback? onTap;
  final Duration assumedDuration;
  final bool isConfirmed;
  final int pendingInvitesCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final brightness = Theme.of(context).brightness;
    final start = event.startDateTime;
    final end = start.add(assumedDuration);
    final timeRange = '${start.timeLabel} - ${end.timeLabel}';
    final onOverlay = Colors.white;

    return LayoutBuilder(
      builder: (context, constraints) {
        final targetWidth = MediaQuery.of(context).size.width * 0.8;
        final isFullSize = constraints.maxWidth >= targetWidth * 0.8;
        final height = constraints.maxWidth * 9 / 16 * 0.8;

        return SizedBox(
          width: constraints.maxWidth,
          height: height,
          child: GestureDetector(
            onTap: onTap,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ImageFiltered(
                    imageFilter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                    child: Image.network(
                      event.imageUri.toString(),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
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
                      child: isFullSize
                          ? Column(
                              key: const ValueKey('liveContent'),
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    InviteStatusIcon(
                                      isConfirmed: isConfirmed,
                                      pendingInvitesCount: pendingInvitesCount,
                                      size: 18,
                                      backgroundColor: colorScheme.secondary
                                          .withValues(alpha: 0.3),
                                    ),
                                    const SizedBox(width: 10),
                                    DecoratedBox(
                                      decoration: BoxDecoration(
                                        color: colorScheme.error,
                                        borderRadius:
                                            BorderRadius.circular(999),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 6),
                                        child: Text(
                                          'AGORA',
                                          style: theme.textTheme.labelMedium
                                              ?.copyWith(
                                            color: colorScheme.onError,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 1.1,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      event.title,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style:
                                          theme.textTheme.titleMedium?.copyWith(
                                        color: onOverlay,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
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
                                  ],
                                ),
                              ],
                            )
                          : const SizedBox.shrink(key: ValueKey('liveEmpty')),
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
