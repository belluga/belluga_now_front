import 'dart:async';

import 'package:belluga_now/application/invites/invite_from_event_factory.dart';
import 'package:belluga_now/domain/schedule/event_linked_account_profile.dart';
import 'package:belluga_now/domain/schedule/event_model.dart';
import 'package:belluga_now/domain/schedule/event_occurrence_option.dart';
import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/application/router/support/canonical_route_governance.dart';
import 'package:belluga_now/application/router/support/route_redirect_path.dart';
import 'package:belluga_now/application/telemetry/auth_wall_telemetry.dart';
import 'package:belluga_now/domain/invites/invite_next_step.dart';
import 'package:belluga_now/domain/invites/invite_model.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_id_value.dart';
import 'package:belluga_now/domain/repositories/invites_repository_contract.dart';
import 'package:belluga_now/domain/schedule/sent_invite_status.dart';
import 'package:belluga_now/domain/schedule/invite_status.dart';
import 'package:belluga_now/presentation/tenant_public/invites/widgets/invite_candidate_picker.dart';
import 'package:belluga_now/presentation/shared/widgets/immersive_detail_screen/models/immersive_tab_item.dart';
import 'package:belluga_now/presentation/shared/widgets/immersive_detail_screen/immersive_detail_screen.dart';
import 'package:belluga_now/presentation/shared/widgets/directions_app_chooser/directions_app_chooser.dart';
import 'package:belluga_now/presentation/shared/widgets/directions_app_chooser/directions_app_chooser_contract.dart';
import 'package:belluga_now/presentation/shared/widgets/directions_app_chooser/directions_launch_target.dart';
import 'package:belluga_now/presentation/tenant_public/schedule/screens/immersive_event_detail/controllers/immersive_event_detail_controller.dart';
import 'package:belluga_now/application/icons/boora_icons.dart';
import 'package:belluga_now/presentation/tenant_public/schedule/screens/immersive_event_detail/widgets/dynamic_footer.dart';
import 'package:belluga_now/presentation/tenant_public/schedule/screens/immersive_event_detail/widgets/event_info_section.dart';
import 'package:belluga_now/presentation/tenant_public/schedule/screens/immersive_event_detail/widgets/event_programming_section.dart';
import 'package:belluga_now/presentation/tenant_public/schedule/screens/immersive_event_detail/widgets/immersive_hero.dart';
import 'package:belluga_now/presentation/tenant_public/schedule/screens/immersive_event_detail/widgets/linked_profile_category_section.dart';
import 'package:belluga_now/presentation/tenant_public/schedule/screens/immersive_event_detail/widgets/location_section.dart';
import 'package:belluga_now/presentation/tenant_public/schedule/screens/immersive_event_detail/widgets/mission_widget.dart';
import 'package:belluga_now/presentation/tenant_public/schedule/screens/immersive_event_detail/widgets/overlapped_invite_avatars.dart';
import 'package:belluga_now/presentation/tenant_public/schedule/screens/immersive_event_detail/widgets/swipeable_invite_widget.dart';
import 'package:flutter/foundation.dart';
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
    this.directionsAppChooser,
    super.key,
  });

  final EventModel event;
  final ColorScheme? colorScheme;
  final DirectionsAppChooserContract? directionsAppChooser;

  @override
  State<ImmersiveEventDetailScreen> createState() =>
      _ImmersiveEventDetailScreenState();
}

class _ImmersiveEventDetailScreenState
    extends State<ImmersiveEventDetailScreen> {
  final ImmersiveEventDetailController _controller =
      GetIt.I.get<ImmersiveEventDetailController>();
  late final DirectionsAppChooserContract _directionsAppChooser =
      widget.directionsAppChooser ?? DirectionsAppChooser();

  @override
  void initState() {
    super.initState();
    _controller.init(widget.event);
  }

  @override
  void didUpdateWidget(covariant ImmersiveEventDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_isDifferentSelectedEvent(oldWidget.event, widget.event)) {
      _controller.init(widget.event);
    }
  }

  bool _isDifferentSelectedEvent(EventModel previous, EventModel current) {
    return previous.id.value != current.id.value ||
        previous.selectedOccurrenceId != current.selectedOccurrenceId;
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
            return StreamValueBuilder<Set<String>>(
              streamValue: _controller.favoriteAccountProfileIdsStreamValue,
              builder: (context, favoriteAccountProfileIds) {
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
                        final sentForEvent =
                            sentInvitesByEvent[invitesRepoString(
                                  resolvedEvent.id.value,
                                  defaultValue: '',
                                  isRequired: true,
                                )] ??
                                const [];

                        final Widget? topBanner = receivedInvites.isNotEmpty
                            ? Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 12, 16, 8),
                                child: SwipeableInviteWidget(
                                  invites: receivedInvites,
                                  onAccept: _handleAcceptInvite,
                                  onDecline: _handleDeclineInvite,
                                ),
                              )
                            : null;

                        final tabs = <ImmersiveTabItem>[
                          if (_hasAboutContent(resolvedEvent))
                            ImmersiveTabItem(
                              title: 'Sobre',
                              content: EventInfoSection(event: resolvedEvent),
                              footer: null,
                            ),
                          if (resolvedEvent.hasAnyProgrammingItems)
                            ImmersiveTabItem(
                              title: 'Programação',
                              content: EventProgrammingSection(
                                items: resolvedEvent.programmingItems,
                                occurrences: resolvedEvent.occurrences,
                                profileTypeRegistry:
                                    _controller.profileTypeRegistry,
                                onOccurrenceTap: (occurrence) =>
                                    _openOccurrence(
                                  resolvedEvent,
                                  occurrence,
                                  tab: 'programming',
                                ),
                                onLocationTap: _openProgrammingLocationMap,
                              ),
                              footer: null,
                            ),
                          ..._buildDynamicProfileTabs(
                            event: resolvedEvent,
                            favoriteAccountProfileIds:
                                favoriteAccountProfileIds,
                          ),
                          ImmersiveTabItem(
                            title: 'Como Chegar',
                            content: LocationSection(
                              event: resolvedEvent,
                              canOpenMap: _canOpenEventMap(resolvedEvent),
                              onOpenMap: _canOpenEventMap(resolvedEvent)
                                  ? () => _openEventMap(resolvedEvent)
                                  : null,
                              onOpenDestinationMap: _openProgrammingLocationMap,
                            ),
                            footer: _canOpenDirections(resolvedEvent)
                                ? DynamicFooter(
                                    buttonText: 'Traçar rota',
                                    buttonIcon: Icons.navigation,
                                    onActionPressed: () =>
                                        _presentDirectionsChooser(
                                      resolvedEvent,
                                    ),
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
                            heroContentBuilder: (context, activateTab) =>
                                ImmersiveHero(
                              event: resolvedEvent,
                              fallbackImageUri:
                                  _controller.defaultEventImageUri,
                              onCounterpartTap: (profile) {
                                final targetIndex = _linkedProfileTabIndex(
                                  resolvedEvent,
                                  profile.profileType,
                                );
                                if (targetIndex != null) {
                                  activateTab(targetIndex);
                                }
                              },
                            ),
                            title: resolvedEvent.title.value,
                            betweenHeroAndTabs: topBanner,
                            tabs: tabs,
                            canUseTabFooter: (_) => isConfirmed,
                            // Don't auto-navigate, let user scroll naturally
                            initialTabIndex:
                                _resolveInitialTabIndex(tabs, context),
                            footer: footer,
                            backPolicy:
                                buildCanonicalCurrentRouteBackPolicy(context),
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
      },
    );
  }

  bool _hasAboutContent(EventModel event) {
    final rawHtml = event.content.value ?? '';
    return InviteFromEventFactory.stripHtml(rawHtml).isNotEmpty;
  }

  Future<void> _handleConfirmAttendance() async {
    final redirectPath =
        buildRedirectPathFromRouteMatch(context.routeData.route);
    if (kIsWeb) {
      context.router.pushPath(
        buildWebPromotionBoundaryPath(
          redirectPath: redirectPath,
        ),
      );
      return;
    }

    final result = await _controller.confirmAttendance();
    if (!mounted ||
        result != AttendanceConfirmationResult.requiresAuthentication) {
      return;
    }
    final encodedRedirect = Uri.encodeQueryComponent(redirectPath);
    context.router.replacePath('/auth/login?redirect=$encodedRedirect');
  }

  List<ImmersiveTabItem> _buildDynamicProfileTabs({
    required EventModel event,
    required Set<String> favoriteAccountProfileIds,
  }) {
    final groupedProfiles = _groupLinkedProfilesByType(event);

    return groupedProfiles.entries
        .map((entry) {
          final type = entry.key;
          final profiles = entry.value;
          if (profiles.isEmpty) {
            return null;
          }

          final title = _controller.profileTypePluralLabelFor(
            type,
            fallback: _humanizeTypeKey(type),
          );

          return ImmersiveTabItem(
            title: title,
            content: LinkedProfileCategorySection(
              title: title,
              profiles: profiles,
              profileTypeRegistry: _controller.profileTypeRegistry,
              favoriteAccountProfileIds: favoriteAccountProfileIds,
              isFavoritable: (profile) =>
                  _controller.isLinkedProfileFavoritable(profile.profileType),
              onFavoriteTap: (profile) =>
                  _handleLinkedProfileFavoriteTap(profile.id),
            ),
            footer: null,
          );
        })
        .whereType<ImmersiveTabItem>()
        .toList(growable: false);
  }

  Map<String, List<EventLinkedAccountProfile>> _groupLinkedProfilesByType(
    EventModel event,
  ) {
    final venueId = event.venue?.id;
    final groupedProfiles = <String, List<EventLinkedAccountProfile>>{};

    for (final profile in event.linkedAccountProfiles) {
      if (profile.id == venueId) {
        continue;
      }

      final type = profile.profileType.trim();
      if (type.isEmpty) {
        continue;
      }

      final bucket = groupedProfiles.putIfAbsent(
        type,
        () => <EventLinkedAccountProfile>[],
      );
      if (bucket.any((existing) => existing.id == profile.id)) {
        continue;
      }
      bucket.add(profile);
    }

    return groupedProfiles;
  }

  int? _linkedProfileTabIndex(EventModel event, String profileType) {
    final type = profileType.trim();
    if (type.isEmpty) {
      return null;
    }

    final dynamicTypes = _groupLinkedProfilesByType(event).keys.toList();
    final typeOffset = dynamicTypes.indexOf(type);
    if (typeOffset < 0) {
      return null;
    }

    var firstDynamicTabIndex = 0;
    if (_hasAboutContent(event)) {
      firstDynamicTabIndex += 1;
    }
    if (event.hasAnyProgrammingItems) {
      firstDynamicTabIndex += 1;
    }

    return firstDynamicTabIndex + typeOffset;
  }

  String _humanizeTypeKey(String raw) {
    final normalized = raw.trim().replaceAll(RegExp(r'[_-]+'), ' ');
    if (normalized.isEmpty) {
      return raw;
    }
    return normalized
        .split(' ')
        .where((part) => part.isNotEmpty)
        .map(
          (part) =>
              '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}',
        )
        .join(' ');
  }

  void _openInviteFlow(EventModel event) {
    final redirectPath =
        buildRedirectPathFromRouteMatch(context.routeData.route);
    if (kIsWeb) {
      AuthWallTelemetry.trackTriggered(
        actionType: AuthWallActionType.sendInvite,
        redirectPath: redirectPath,
      );
      context.router.pushPath(
        buildWebPromotionBoundaryPath(
          redirectPath: redirectPath,
        ),
      );
      return;
    }

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

  void _openEventMap(EventModel event) {
    final venueId = event.venue?.id.trim();
    if (venueId == null || venueId.isEmpty) {
      return;
    }
    final path = Uri(
      path: '/mapa',
      queryParameters: {
        'poi': 'account_profile:$venueId',
      },
    ).toString();
    context.router.pushPath(path);
  }

  void _openProgrammingLocationMap(EventLinkedAccountProfile profile) {
    final profileId = profile.id.trim();
    if (profileId.isEmpty) {
      return;
    }
    final path = Uri(
      path: '/mapa',
      queryParameters: {
        'poi': 'account_profile:$profileId',
      },
    ).toString();
    context.router.pushPath(path);
  }

  void _openOccurrence(EventModel event, EventOccurrenceOption occurrence,
      {String? tab}) {
    final occurrenceId = occurrence.occurrenceId.trim();
    if (occurrence.isSelected || occurrenceId.isEmpty) {
      return;
    }
    _controller.selectOccurrence(event, occurrence);
    final path = Uri(
      path: '/agenda/evento/${event.slug}',
      queryParameters: {
        'occurrence': occurrenceId,
        if (tab != null && tab.trim().isNotEmpty) 'tab': tab,
      },
    ).toString();
    unawaited(context.router.replacePath(path));
  }

  int _resolveInitialTabIndex(
    List<ImmersiveTabItem> tabs,
    BuildContext context,
  ) {
    final requestedTab =
        context.routeData.queryParams.optString('tab')?.trim().toLowerCase();
    if (requestedTab != 'programming') {
      return 0;
    }
    final programmingIndex =
        tabs.indexWhere((tab) => tab.title == 'Programação');
    return programmingIndex < 0 ? 0 : programmingIndex;
  }

  void _presentDirectionsChooser(EventModel event) {
    final target = _directionsTargetFromEvent(event);
    if (target == null) {
      return;
    }
    _directionsAppChooser.present(
      context,
      target: target,
      onStatusMessage: _showStatusMessage,
    );
  }

  bool _canOpenEventMap(EventModel event) {
    final venueId = event.venue?.id.trim();
    return venueId != null && venueId.isNotEmpty;
  }

  bool _canOpenDirections(EventModel event) {
    return _directionsTargetFromEvent(event) != null;
  }

  DirectionsLaunchTarget? _directionsTargetFromEvent(EventModel event) {
    final destinationName = event.venue?.displayName.trim().isNotEmpty == true
        ? event.venue!.displayName.trim()
        : event.title.value;
    final address = event.location.value.trim();
    final coordinate = event.coordinate;
    if (coordinate != null) {
      return DirectionsLaunchTarget(
        destinationName: destinationName,
        latitude: coordinate.latitude,
        longitude: coordinate.longitude,
        address: address.isEmpty ? null : address,
      );
    }
    if (address.isEmpty) {
      return null;
    }
    return DirectionsLaunchTarget(
      destinationName: destinationName,
      address: address,
    );
  }

  void _showStatusMessage(String message) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) {
      return;
    }
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
        ),
      );
  }

  InviteModel _buildInviteFromEvent(EventModel event) {
    return InviteFromEventFactory.build(
      event: event,
      fallbackImageUri: _controller.defaultEventImageUri,
    );
  }

  void _handleLinkedProfileFavoriteTap(String accountProfileId) {
    final redirectPath =
        buildRedirectPathFromRouteMatch(context.routeData.route);
    if (kIsWeb) {
      AuthWallTelemetry.trackTriggered(
        actionType: AuthWallActionType.favorite,
        redirectPath: redirectPath,
        payload: {'partnerId': accountProfileId},
      );
      context.router.pushPath(
        buildWebPromotionBoundaryPath(
          redirectPath: redirectPath,
        ),
      );
      return;
    }

    final result = _controller.toggleLinkedProfileFavorite(accountProfileId);
    if (result != LinkedProfileFavoriteToggleOutcome.requiresAuthentication) {
      return;
    }
    AuthWallTelemetry.trackTriggered(
      actionType: AuthWallActionType.favorite,
      redirectPath: redirectPath,
      payload: {'partnerId': accountProfileId},
    );
    final encodedRedirect = Uri.encodeQueryComponent(redirectPath);
    context.router.replacePath('/auth/login?redirect=$encodedRedirect');
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
