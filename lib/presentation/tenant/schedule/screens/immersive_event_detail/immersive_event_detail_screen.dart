import 'package:belluga_now/domain/schedule/event_model.dart';
import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/domain/invites/invite_model.dart';
import 'package:belluga_now/domain/schedule/sent_invite_status.dart';
import 'package:belluga_now/domain/schedule/invite_status.dart';
import 'package:belluga_now/presentation/common/widgets/immersive_detail_screen/models/immersive_tab_item.dart';
import 'package:belluga_now/presentation/common/widgets/immersive_detail_screen/immersive_detail_screen.dart';
import 'package:belluga_now/presentation/tenant/schedule/screens/immersive_event_detail/controllers/immersive_event_detail_controller.dart';
import 'package:belluga_now/presentation/tenant/schedule/screens/immersive_event_detail/widgets/dynamic_footer.dart';
import 'package:belluga_now/presentation/tenant/schedule/screens/immersive_event_detail/widgets/event_info_section.dart';
import 'package:belluga_now/presentation/tenant/schedule/screens/immersive_event_detail/widgets/immersive_hero.dart';
import 'package:belluga_now/presentation/tenant/schedule/screens/immersive_event_detail/widgets/lineup_section.dart';
import 'package:belluga_now/presentation/tenant/schedule/screens/immersive_event_detail/widgets/location_section.dart';
import 'package:belluga_now/presentation/tenant/schedule/screens/immersive_event_detail/widgets/mission_widget.dart';
import 'package:belluga_now/presentation/tenant/schedule/screens/event_detail_screen/widgets/swipeable_invite_widget.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value_builder.dart';

/// Event-specific immersive detail screen.
///
/// This screen builds the generic ImmersiveDetailScreen with event-specific
/// content and configuration. When the event is confirmed, "Sua Galera" tab
/// is shown first and auto-selected to incentivize inviting friends.
class ImmersiveEventDetailScreen extends StatefulWidget {
  const ImmersiveEventDetailScreen({
    required this.event,
    super.key,
  });

  final EventModel event;

  @override
  State<ImmersiveEventDetailScreen> createState() =>
      _ImmersiveEventDetailScreenState();
}

class _ImmersiveEventDetailScreenState
    extends State<ImmersiveEventDetailScreen> {
  final _controller = GetIt.I.get<ImmersiveEventDetailController>();

  @override
  void initState() {
    super.initState();
    _controller.init(widget.event);
  }

  @override
  Widget build(BuildContext context) {
    return StreamValueBuilder<EventModel?>(
      streamValue: _controller.eventStreamValue,
      builder: (context, event) {
        if (event == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return StreamValueBuilder<bool>(
          streamValue: _controller.isConfirmedStreamValue,
          builder: (context, isConfirmed) {
            final colorScheme = Theme.of(context).colorScheme;
            return StreamValueBuilder<List<InviteModel>>(
              streamValue: _controller.receivedInvitesStreamValue,
              builder: (context, receivedInvites) {
                return StreamValueBuilder<Map<String, List<SentInviteStatus>>>(
                  streamValue: _controller.sentInvitesByEventStreamValue,
                  builder: (context, sentInvitesByEvent) {
                    final sentForEvent =
                        sentInvitesByEvent[event.id.value] ?? const [];

                    final Widget? topBanner = receivedInvites.isNotEmpty
                        ? Padding(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                            child: SwipeableInviteWidget(
                              invites: receivedInvites,
                              onAccept: _controller.acceptInvite,
                              onDecline: _controller.declineInvite,
                            ),
                          )
                        : null;

                    final tabs = <ImmersiveTabItem>[
                      ImmersiveTabItem(
                        title: 'O Rolê',
                        content: EventInfoSection(event: event),
                        footer: null,
                      ),
                      ImmersiveTabItem(
                        title: 'Line-up',
                        content: LineupSection(event: event),
                        footer: isConfirmed
                            ? DynamicFooter(
                                buttonText: 'Seguir todos os artistas',
                                buttonIcon: Icons.star,
                                buttonColor: colorScheme.secondary,
                                onActionPressed: () {
                                  // TODO: follow all artists
                                },
                              )
                            : null,
                      ),
                      ImmersiveTabItem(
                        title: 'O Local',
                        content: LocationSection(event: event),
                        footer: isConfirmed
                            ? DynamicFooter(
                                buttonText: 'Traçar Rota agora',
                                buttonIcon: Icons.navigation,
                                buttonColor: colorScheme.secondary,
                                onActionPressed: () {
                                  // TODO: open maps
                                },
                              )
                            : null,
                      ),
                      if (isConfirmed)
                        ImmersiveTabItem(
                          title: 'Ganhe Brindes',
                          content: Align(
                            alignment: Alignment.topCenter,
                            child: UnconstrainedBox(
                              alignment: Alignment.topCenter,
                              constrainedAxis: Axis.horizontal,
                              child: StreamValueBuilder(
                                streamValue: _controller.missionStreamValue,
                                onNullWidget: const SizedBox.shrink(),
                                builder: (context, mission) {
                                  return MissionWidget(mission: mission);
                                },
                              ),
                            ),
                          ),
                          footer: null,
                        ),
                    ];

                    final footer = isConfirmed
                        ? _buildInviteFooter(
                            context, () => _openInviteFlow(event), sentForEvent)
                        : DynamicFooter(
                            buttonText: 'Bóora! Confirmar Presença!',
                            buttonIcon: Icons.celebration,
                            buttonColor: colorScheme.primary,
                            onActionPressed: _controller.confirmAttendance,
                          );

                    return ImmersiveDetailScreen(
                      heroContent: ImmersiveHero(event: event),
                      title: event.title.value,
                      betweenHeroAndTabs: topBanner,
                      tabs: tabs,
                      // Don't auto-navigate, let user scroll naturally
                      // initialTabIndex defaults to 0
                      footer: footer,
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  void _openInviteFlow(EventModel event) {
    final invite = _buildInviteFromEvent(event);
    context.router.push(InviteShareRoute(invite: invite));
  }

  InviteModel _buildInviteFromEvent(EventModel event) {
    final eventName = event.title.value;
    final eventDate = event.dateTimeStart.value ?? DateTime.now();
    // Prefer event thumb; then first artist avatar; then hardcoded fallback.
    final inviteCoverUri = event.thumb?.thumbUri.value ??
        event.artists
            .map((a) => a.avatarUri)
            .firstWhere((uri) => uri != null, orElse: () => null);
    const fallbackImage =
        'https://images.unsplash.com/photo-1489515217757-5fd1be406fef?w=1200';
    final imageUrl = inviteCoverUri?.toString() ?? fallbackImage;
    final locationLabel = event.location.value;
    final hostName = event.artists.isNotEmpty
        ? event.artists.first.displayName
        : 'Belluga Now';
    final description = _stripHtml(event.content.value ?? '').trim();
    final tags = event.taxonomyTags;
    final eventId = event.id.value;
    final inviteId = eventId.isNotEmpty ? eventId : eventName;
    return InviteModel.fromPrimitives(
      id: inviteId,
      eventId: eventId,
      eventName: eventName,
      eventDateTime: eventDate,
      eventImageUrl: imageUrl,
      location: locationLabel,
      hostName: hostName,
      message: description.isEmpty ? 'Partiu $eventName?' : description,
      tags: tags.isEmpty ? const ['belluga'] : tags,
    );
  }

  String _stripHtml(String value) {
    return value.replaceAll(RegExp(r'<[^>]*>'), '').trim();
  }
}

Widget _buildInviteFooter(
  BuildContext context,
  VoidCallback onInviteFriends,
  List<SentInviteStatus> sentInvites,
) {
  final hasInvites = sentInvites.isNotEmpty;
  final theme = Theme.of(context);
  final colorScheme = theme.colorScheme;
  final subtleOnSurface = colorScheme.onSurface.withValues(alpha: 0.12);
  final textColorMuted = colorScheme.onSurface.withValues(alpha: 0.8);
  final primary = colorScheme.primary;

  return DynamicFooter(
    leftWidget: !hasInvites
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: subtleOnSurface,
                child: Icon(
                  Icons.rocket_launch,
                  color: primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  'Convide sua galera para ir com você.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _OverlappedAvatars(invites: sentInvites),
              const SizedBox(height: 4),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 220),
                child: Text(
                  _inviteSummary(sentInvites),
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: textColorMuted,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
    buttonText: 'BORA? Agitar a galera!',
    buttonIcon: Icons.rocket_launch,
    buttonColor: primary,
    onActionPressed: onInviteFriends,
  );
}

String _inviteSummary(List<SentInviteStatus> shown) {
  if (shown.isEmpty) return '';
  final pending =
      shown.where((invite) => invite.status != InviteStatus.accepted).length;
  final confirmed = shown.length - pending;
  return '$pending pendentes | $confirmed confirmados';
}

class _InviteAvatar extends StatelessWidget {
  const _InviteAvatar(this.invite);

  final SentInviteStatus invite;

  @override
  Widget build(BuildContext context) {
    final badge = invite.status == InviteStatus.accepted
        ? Icons.check_circle
        : Icons.hourglass_bottom;
    final badgeColor =
        invite.status == InviteStatus.accepted ? Colors.green : Colors.orange;

    final url = invite.friend.avatarUrl;
    final display = invite.friend.displayName;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        CircleAvatar(
          radius: 16,
          backgroundImage:
              url != null && url.isNotEmpty ? NetworkImage(url) : null,
          child: (url == null || url.isEmpty)
              ? Text(
                  display.isNotEmpty ? display[0].toUpperCase() : '?',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                )
              : null,
        ),
        Positioned(
          bottom: -2,
          right: -2,
          child: Container(
            padding: const EdgeInsets.all(2),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
            child: Icon(
              badge,
              color: badgeColor,
              size: 12,
            ),
          ),
        ),
      ],
    );
  }
}

class _OverlappedAvatars extends StatelessWidget {
  const _OverlappedAvatars({required this.invites});

  final List<SentInviteStatus> invites;

  @override
  Widget build(BuildContext context) {
    if (invites.isEmpty) return const SizedBox.shrink();

    final cappedCount = invites.length > 3 ? 3 : invites.length;
    final displayInvites = invites.take(cappedCount).toList();
    final remaining = invites.length - cappedCount;

    final items = <Widget>[];
    for (var i = 0; i < displayInvites.length; i++) {
      items.add(Positioned(
        left: i * 18.0,
        child: _InviteAvatar(displayInvites[i]),
      ));
    }

    // Final slot shows +X or empty placeholder
    items.add(Positioned(
      left: cappedCount * 18.0,
      child: remaining > 0
          ? _PlusAvatar(remaining)
          : const _PlusAvatar(0, isEmptySlot: true),
    ));

    final totalItems = cappedCount + 1;
    final width = totalItems * 18.0 + 16.0;

    return SizedBox(
      width: width,
      height: 36,
      child: Stack(
        clipBehavior: Clip.none,
        children: items,
      ),
    );
  }
}

class _PlusAvatar extends StatelessWidget {
  const _PlusAvatar(this.count, {this.isEmptySlot = false});

  final int count;
  final bool isEmptySlot;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final baseOnSurface = colorScheme.onSurface;
    final bgColor = isEmptySlot
        ? baseOnSurface.withValues(alpha: 0.08)
        : baseOnSurface.withValues(alpha: 0.16);
    final borderColor = baseOnSurface.withValues(alpha: 0.28);

    return CircleAvatar(
      radius: 16,
      backgroundColor: Colors.transparent,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: bgColor,
          border: Border.all(color: borderColor, style: BorderStyle.solid),
        ),
        child: Center(
          child: isEmptySlot
              ? Icon(Icons.person_outline,
                  size: 16, color: baseOnSurface.withValues(alpha: 0.65))
              : Text(
                  '+$count',
                  style: TextStyle(
                    color: baseOnSurface,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
        ),
      ),
    );
  }
}
