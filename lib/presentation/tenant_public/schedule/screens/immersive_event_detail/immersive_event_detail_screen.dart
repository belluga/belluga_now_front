import 'dart:async';

import 'package:belluga_now/domain/schedule/event_model.dart';
import 'package:belluga_now/domain/venue_event/projections/venue_event_resume.dart';
import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/application/router/support/route_redirect_path.dart';
import 'package:belluga_now/domain/invites/invite_model.dart';
import 'package:belluga_now/domain/invites/invite_next_step.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_attendance_policy_value.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_event_date_value.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_event_id_value.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_host_name_value.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_id_value.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_location_value.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_message_value.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_occurrence_id_value.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_tag_value.dart';
import 'package:belluga_now/domain/repositories/invites_repository_contract.dart';
import 'package:belluga_now/domain/repositories/value_objects/invites_repository_contract_values.dart';
import 'package:belluga_now/domain/schedule/sent_invite_status.dart';
import 'package:belluga_now/domain/schedule/invite_status.dart';
import 'package:belluga_now/domain/value_objects/thumb_uri_value.dart';
import 'package:belluga_now/domain/value_objects/title_value.dart';
import 'package:belluga_now/presentation/tenant_public/invites/widgets/invite_candidate_picker.dart';
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
import 'package:belluga_now/presentation/tenant_public/schedule/screens/immersive_event_detail/widgets/swipeable_invite_widget.dart';
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
      onNullWidget: const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      builder: (context, event) {
        final resolvedEvent = event!;
        return StreamValueBuilder<bool>(
          streamValue: _controller.isConfirmedStreamValue,
          builder: (context, isConfirmed) {
            final colorScheme =
                widget.colorScheme ?? Theme.of(context).colorScheme;
            return StreamValueBuilder<List<InviteModel>>(
              streamValue: _controller.receivedInvitesStreamValue,
              builder: (context, receivedInvites) {
                return StreamValueBuilder<
                    Map<InvitesRepositoryContractPrimString,
                        List<SentInviteStatus>>>(
                  streamValue: _controller.sentInvitesByEventStreamValue,
                  builder: (context, sentInvitesByEvent) {
                    final sentForEvent = sentInvitesByEvent[invitesRepoString(
                          resolvedEvent.id.value,
                          defaultValue: '',
                          isRequired: true,
                        )] ??
                        const [];

                    final Widget? topBanner = receivedInvites.isNotEmpty
                        ? Padding(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                            child: SwipeableInviteWidget(
                              invites: receivedInvites,
                              onAccept: _handleAcceptInvite,
                              onDecline: _handleDeclineInvite,
                            ),
                          )
                        : null;

                    final tabs = <ImmersiveTabItem>[
                      ImmersiveTabItem(
                        title: 'O Rolê',
                        content: EventInfoSection(event: resolvedEvent),
                        footer: null,
                      ),
                      ImmersiveTabItem(
                        title: 'Line-up',
                        content: LineupSection(event: resolvedEvent),
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
                        content: LocationSection(event: resolvedEvent),
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
                            context,
                            () => _openInviteFlow(resolvedEvent),
                            sentForEvent,
                          )
                        : DynamicFooter(
                            buttonText: 'Bóora! Confirmar Presença!',
                            buttonIcon: Icons.celebration,
                            buttonColor: colorScheme.primary,
                            onActionPressed: () {
                              unawaited(_handleConfirmAttendance());
                            },
                          );

                    return Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: colorScheme,
                      ),
                      child: ImmersiveDetailScreen(
                        heroContent: ImmersiveHero(
                          event: resolvedEvent,
                          fallbackImageUri: _controller.defaultEventImageUri,
                        ),
                        title: resolvedEvent.title.value,
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

  Future<void> _handleConfirmAttendance() async {
    final result = await _controller.confirmAttendance();
    if (!mounted ||
        result != AttendanceConfirmationResult.requiresAuthentication) {
      return;
    }
    final redirectPath =
        buildRedirectPathFromRouteMatch(context.routeData.route);
    final encodedRedirect = Uri.encodeQueryComponent(redirectPath);
    context.router.replacePath('/auth/login?redirect=$encodedRedirect');
  }

  void _openInviteFlow(EventModel event) {
    final invite = _buildInviteFromEvent(event);
    context.router.push(InviteShareRoute(invite: invite));
  }

  Future<void> _handleAcceptInvite(InviteModel invite) {
    final router = context.router;
    final messenger = ScaffoldMessenger.of(context);

    return showInviteCandidatePicker(
      context,
      invite: invite,
      actionLabel: 'Aceitar',
    ).then((inviteId) {
      if (inviteId == null || inviteId.isEmpty) {
        return Future<void>.value();
      }

      return _controller.acceptInvite(inviteId).then<void>((result) {
        if (result.nextStep == InviteNextStep.reservationRequired ||
            result.nextStep == InviteNextStep.commitmentChoiceRequired ||
            result.nextStep == InviteNextStep.openAppToContinue) {
          _showInviteNextStepToast(messenger, invite, result.nextStep);
          return;
        }

        router.push(
          InviteShareRoute(
            invite: invite.prioritizeInviter(InviteIdValue()..parse(inviteId)),
          ),
        );
      });
    });
  }

  Future<void> _handleDeclineInvite(InviteModel invite) {
    return showInviteCandidatePicker(
      context,
      invite: invite,
      actionLabel: 'Recusar',
    ).then((inviteId) {
      if (inviteId == null || inviteId.isEmpty) {
        return Future<void>.value();
      }
      return _controller.declineInvite(inviteId).then<void>((_) {});
    });
  }

  void _showInviteNextStepToast(
    ScaffoldMessengerState messenger,
    InviteModel invite,
    InviteNextStep nextStep,
  ) {
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          nextStep == InviteNextStep.openAppToContinue
              ? 'Convite aceito para ${invite.eventName}. Continue pelo app.'
              : 'Convite aceito para ${invite.eventName}. A proxima etapa ainda nao esta disponivel nesta versao.',
        ),
      ),
    );
  }

  InviteModel _buildInviteFromEvent(EventModel event) {
    final eventName = event.title.value;
    final eventDate = event.dateTimeStart.value ?? DateTime.now();
    final fallbackImageValue = ThumbUriValue(
      defaultValue: _controller.defaultEventImageUri,
      isRequired: true,
    )..parse(_controller.defaultEventImageUri.toString());
    final imageUrl = VenueEventResume.resolvePreferredImageUri(
      event,
      settingsDefaultImageValue: fallbackImageValue,
    ).toString();
    final locationLabel = event.location.value;
    final hostName = event.artists.isNotEmpty
        ? event.artists.first.displayName
        : 'Belluga Now';
    final description = _stripHtml(event.content.value ?? '').trim();
    final tags = event.taxonomyTags;
    final eventId = event.id.value;
    final inviteId = eventId.isNotEmpty ? eventId : eventName;
    final parsedTags = tags.isEmpty
        ? <InviteTagValue>[InviteTagValue()..parse('belluga')]
        : tags
            .map((tag) => InviteTagValue()..parse(tag.value))
            .toList(growable: false);

    return InviteModel(
      idValue: InviteIdValue()..parse(inviteId),
      eventIdValue: InviteEventIdValue()..parse(eventId),
      eventNameValue: TitleValue()..parse(eventName),
      eventDateValue: InviteEventDateValue(isRequired: true)
        ..parse(eventDate.toIso8601String()),
      eventImageValue: ThumbUriValue(
        defaultValue: Uri.parse(imageUrl),
        isRequired: true,
      )..parse(imageUrl),
      locationValue: InviteLocationValue()..parse(locationLabel),
      hostNameValue: InviteHostNameValue()..parse(hostName),
      messageValue: InviteMessageValue()
        ..parse(description.isEmpty ? 'Partiu $eventName?' : description),
      tagValues: parsedTags,
      occurrenceIdValue: InviteOccurrenceIdValue(),
      attendancePolicyValue: InviteAttendancePolicyValue(
        defaultValue: 'free_confirmation_only',
      )..parse('free_confirmation_only'),
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
