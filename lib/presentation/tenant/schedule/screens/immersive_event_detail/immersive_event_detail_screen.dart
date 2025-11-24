import 'package:belluga_now/domain/schedule/event_model.dart';
import 'package:belluga_now/domain/invites/invite_model.dart';
import 'package:belluga_now/presentation/common/widgets/immersive_detail_screen/models/immersive_tab_item.dart';
import 'package:belluga_now/presentation/common/widgets/immersive_detail_screen/immersive_detail_screen.dart';
import 'package:belluga_now/presentation/tenant/schedule/screens/immersive_event_detail/controllers/immersive_event_detail_controller.dart';
import 'package:belluga_now/presentation/tenant/schedule/screens/immersive_event_detail/widgets/dynamic_footer.dart';
import 'package:belluga_now/presentation/tenant/schedule/screens/immersive_event_detail/widgets/event_info_section.dart';
import 'package:belluga_now/presentation/tenant/schedule/screens/immersive_event_detail/widgets/immersive_hero.dart';
import 'package:belluga_now/presentation/tenant/schedule/screens/immersive_event_detail/widgets/lineup_section.dart';
import 'package:belluga_now/presentation/tenant/schedule/screens/immersive_event_detail/widgets/location_section.dart';
import 'package:belluga_now/presentation/tenant/schedule/screens/immersive_event_detail/widgets/mission_widget.dart';
import 'package:belluga_now/presentation/tenant/schedule/screens/immersive_event_detail/widgets/sua_galera_section.dart';
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
            return StreamValueBuilder<List<InviteModel>>(
              streamValue: _controller.receivedInvitesStreamValue,
              builder: (context, receivedInvites) {
                // Build tabs dynamically; loyalty tab moves to the end
                final tabs = <ImmersiveTabItem>[
                  ImmersiveTabItem(
                    title: 'O Rolê',
                    content: EventInfoSection(event: event),
                    footer: isConfirmed
                        ? DynamicFooter(
                            buttonText: 'Ver meu QR Code de Acesso',
                            buttonIcon: Icons.qr_code,
                            buttonColor: Colors.blue,
                            onActionPressed: () {
                              // TODO: show QR code
                            },
                          )
                        : null,
                  ),
                  ImmersiveTabItem(
                    title: 'Line-up',
                    content: LineupSection(event: event),
                    footer: isConfirmed
                        ? DynamicFooter(
                            buttonText: 'Seguir todos os artistas',
                            buttonIcon: Icons.star,
                            buttonColor: const Color(0xFF6A1B9A),
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
                            buttonColor: const Color(0xFF00ACC1),
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
                      footer: DynamicFooter(
                        leftTitle: 'Tudo certo!',
                        leftSubtitle: 'Presença confirmada.',
                        leftIcon: Icons.check_circle,
                        leftIconColor: Colors.green,
                        buttonText: 'BORA? Agitar a galera!',
                        buttonIcon: Icons.rocket_launch,
                        buttonColor: const Color(0xFF9C27B0),
                        onActionPressed: () {
                          // TODO: invite friends
                        },
                      ),
                    ),
                ];

                final topBanner = (!isConfirmed && receivedInvites.isNotEmpty)
                    ? Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                        child: SwipeableInviteWidget(
                          invites: receivedInvites,
                          onAccept: _controller.acceptInvite,
                          onDecline: _controller.declineInvite,
                        ),
                      )
                    : (isConfirmed
                        ? Padding(
                            padding:
                                const EdgeInsets.fromLTRB(16, 16, 16, 12),
                            child: SuaGaleraSection(
                              friendsGoingStream:
                                  _controller.friendsGoingStreamValue,
                            ),
                          )
                        : null);

                final footer = isConfirmed
                    ? null
                    : DynamicFooter(
                        buttonText: 'Bóora! Confirmar Presença!',
                        buttonIcon: Icons.celebration,
                        buttonColor: const Color(0xFF9C27B0),
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
  }
}
