import 'package:belluga_now/application/extensions/event_data_formating.dart';
import 'package:belluga_now/domain/venue_event/projections/venue_event_resume.dart';
import 'package:belluga_now/presentation/tenant/widgets/event_info_row.dart';
import 'package:belluga_now/presentation/tenant/widgets/upcoming_event_participants.dart';
import 'package:belluga_now/presentation/tenant/widgets/upcoming_event_thumbnail.dart';
import 'package:belluga_now/application/icons/boora_icons.dart';
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
  });

  final VenueEventResume event;
  final int pendingInvitesCount;
  final VoidCallback? onTap;
  final bool isConfirmed;
  final double statusIconSize;
  final Color? statusIconColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheduleLabel =
        '${event.startDateTime.dayLabel} ${event.startDateTime.monthLabel} • ${event.startDateTime.timeLabel}';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Builder(builder: (context) {
          final statusWidget = _buildStatusWidget(theme);
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              UpcomingEventThumbnail(imageUrl: event.imageUri.toString()),
              const SizedBox(width: 16),
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
                      label: event.location,
                    ),
                    const SizedBox(height: 6),
                    UpcomingEventParticipants(event: event),
                  ],
                ),
              ),
              if (statusWidget != null) ...[
                const SizedBox(width: 8),
                statusWidget,
              ],
            ],
          );
        }),
      ),
    );
  }

  Widget? _buildStatusWidget(ThemeData theme) {
    if (!isConfirmed && pendingInvitesCount == 0) {
      return null;
    }

    if (isConfirmed) {
      final background = statusIconColor ?? theme.colorScheme.primary;
      final iconColor = _foregroundOn(background, theme.colorScheme.onPrimary);
      return CircleAvatar(
        backgroundColor: background,
        radius: (statusIconSize + 14) / 2,
        child: Transform.translate(
          // Boora invite glyph sits slightly high/left; nudge to center visually.
          offset: const Offset(-2.0, 0.6),
          child: Icon(
            BooraIcons.invite_solid,
            color: iconColor,
            size: statusIconSize * 0.9,
          ),
        ),
      );
    }

    final badgeColor = statusIconColor ?? theme.colorScheme.tertiary;
    final textColor = _foregroundOn(badgeColor, theme.colorScheme.onTertiary);
    final displayCount =
        pendingInvitesCount > 10 ? '10+' : pendingInvitesCount.toString();

    final iconSize = statusIconSize;
    final badgeSize = iconSize * 0.6;

    return SizedBox(
      width: iconSize + badgeSize * 0.6,
      height: iconSize + badgeSize * 0.4,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            top: 0,
            child: Icon(
              BooraIcons.invite_outlined,
              color: badgeColor,
              size: iconSize,
            ),
          ),
          Positioned(
            right: 0,
            bottom: -badgeSize * 0.2,
            child: Container(
              width: badgeSize,
              height: badgeSize,
              decoration: BoxDecoration(
                color: badgeColor,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                displayCount,
                style: theme.textTheme.labelSmall?.copyWith(
                      color: textColor,
                      fontWeight: FontWeight.w800,
                    ) ??
                    TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _foregroundOn(Color background, Color themeFallback) {
    if (statusIconColor == null) {
      return themeFallback;
    }
    final brightness = ThemeData.estimateBrightnessForColor(background);
    return brightness == Brightness.dark ? Colors.white : Colors.black87;
  }
}
