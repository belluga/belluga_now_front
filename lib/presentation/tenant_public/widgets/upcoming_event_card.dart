import 'package:belluga_now/application/extensions/event_data_formating.dart';
import 'package:belluga_now/domain/venue_event/projections/venue_event_resume.dart';
import 'package:belluga_now/presentation/tenant_public/widgets/event_info_row.dart';
import 'package:belluga_now/presentation/tenant_public/widgets/upcoming_event_participants.dart';
import 'package:belluga_now/presentation/tenant_public/widgets/upcoming_event_thumbnail.dart';
import 'package:belluga_now/presentation/tenant_public/widgets/invite_status_icon.dart';
import 'package:flutter/material.dart';

class UpcomingEventCard extends StatelessWidget {
  const UpcomingEventCard({
    super.key,
    required this.event,
    this.onTap,
    this.isConfirmed = false,
    this.pendingInvitesCount = 0,
    this.statusIconSize = 24,
    this.statusIconColor,
    this.distanceLabel,
  });

  final VenueEventResume event;
  final int pendingInvitesCount;
  final VoidCallback? onTap;
  final bool isConfirmed;
  final double statusIconSize;
  final Color? statusIconColor;
  final String? distanceLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheduleLabel =
        '${event.startDateTime.dayLabel} ${event.startDateTime.monthLabel} • ${event.startDateTime.timeLabel}';
    final cardRadius = BorderRadius.circular(18);
    final surface =
        theme.colorScheme.surfaceContainerHigh.withValues(alpha: 0.9);
    final confirmedTint =
        theme.colorScheme.primaryContainer.withValues(alpha: 0.18);
    final pendingTint =
        theme.colorScheme.secondaryContainer.withValues(alpha: 0.16);
    final cardColor = isConfirmed
        ? Color.alphaBlend(confirmedTint, surface)
        : (pendingInvitesCount > 0
            ? Color.alphaBlend(pendingTint, surface)
            : surface);

    return Card(
      color: cardColor,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: cardRadius),
      child: InkWell(
        borderRadius: cardRadius,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Builder(builder: (context) {
            final statusWidget = _buildStatusWidget(theme, cardColor);
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                UpcomingEventThumbnail(imageUrl: event.imageUri.toString()),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      EventInfoRow(
                        icon: Icons.event_outlined,
                        label: scheduleLabel,
                      ),
                      const SizedBox(height: 6),
                      EventInfoRow(
                        icon: Icons.place_outlined,
                        label: distanceLabel != null ? "${event.location} ($distanceLabel)"  : event.location,
                      ),
                      const SizedBox(height: 6),
                      UpcomingEventParticipants(event: event),
                    ],
                  ),
                ),
                if (statusWidget != null) ...[
                  const SizedBox(width: 10),
                  statusWidget,
                ],
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget? _buildStatusWidget(ThemeData theme, Color cardColor) {
    final statusIcon = InviteStatusIcon(
      isConfirmed: isConfirmed,
      pendingInvitesCount: pendingInvitesCount,
      size: statusIconSize,
      backgroundColor: (isConfirmed
              ? theme.colorScheme.primary
              : theme.colorScheme.secondary)
          .withValues(alpha: 0.18),
    );
    if (!isConfirmed && pendingInvitesCount == 0) return null;
    return statusIcon;
  }
}
