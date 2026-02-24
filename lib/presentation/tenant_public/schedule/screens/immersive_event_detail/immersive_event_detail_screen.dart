import 'package:belluga_now/domain/schedule/event_model.dart';
import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/domain/invites/invite_model.dart';
import 'package:belluga_now/domain/schedule/sent_invite_status.dart';
import 'package:belluga_now/domain/schedule/invite_status.dart';
import 'package:belluga_now/presentation/shared/widgets/immersive_detail_screen/models/immersive_tab_item.dart';
import 'package:belluga_now/presentation/shared/widgets/immersive_detail_screen/immersive_detail_screen.dart';
import 'package:belluga_now/presentation/tenant_public/schedule/screens/immersive_event_detail/controllers/immersive_event_detail_controller.dart';
import 'package:belluga_now/application/icons/boora_icons.dart';
import 'package:belluga_now/presentation/tenant_public/schedule/screens/immersive_event_detail/widgets/dynamic_footer.dart';
import 'package:belluga_now/presentation/tenant_public/schedule/screens/immersive_event_detail/widgets/event_info_section.dart';
import 'package:belluga_now/presentation/tenant_public/schedule/screens/immersive_event_detail/widgets/immersive_hero.dart';
import 'package:belluga_now/presentation/tenant_public/schedule/screens/immersive_event_detail/widgets/lineup_section.dart';
import 'package:belluga_now/presentation/tenant_public/schedule/screens/immersive_event_detail/widgets/location_section.dart';
import 'package:belluga_now/presentation/tenant_public/schedule/screens/immersive_event_detail/widgets/mission_widget.dart';
import 'package:belluga_now/presentation/tenant_public/schedule/screens/immersive_event_detail/widgets/overlapped_invite_avatars.dart';
import 'package:belluga_now/presentation/tenant_public/schedule/screens/event_detail_screen/widgets/swipeable_invite_widget.dart';
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
    this.colorScheme,
    super.key,
  });

  final EventModel event;
  final ColorScheme? colorScheme;

  @override
  State<ImmersiveEventDetailScreen> createState() =>
      _ImmersiveEventDetailScreenState();
}

class _ImmersiveEventDetailScreenState
    extends State<ImmersiveEventDetailScreen> {
  final ImmersiveEventDetailController _controller =
      GetIt.I.get<ImmersiveEventDetailController>();

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
            final colorScheme =
                widget.colorScheme ?? Theme.of(context).colorScheme;
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
                            buttonText: 'Convidar amigos',
                            buttonIcon: BooraIcons.invite_solid,
                            buttonColor: colorScheme.primary,
                            onActionPressed: () => _openInviteFlow(event),
                          );

                    return Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: colorScheme,
                      ),
                      child: ImmersiveDetailScreen(
                        heroContent: ImmersiveHero(event: event),
                        title: event.title.value,
                        betweenHeroAndTabs: topBanner,
                        tabs: tabs,
                        // Don't auto-navigate, let user scroll naturally
                        // initialTabIndex defaults to 0
                        footer: footer,
                      ),
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
              OverlappedInviteAvatars(invites: sentInvites),
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
    buttonIcon: BooraIcons.invite_solid,
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
