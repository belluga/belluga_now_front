import 'dart:async';

import 'package:belluga_now/application/invites/invite_from_event_factory.dart';
import 'package:belluga_now/domain/schedule/event_linked_account_profile.dart';
import 'package:belluga_now/domain/schedule/event_model.dart';
import 'package:belluga_now/domain/schedule/event_occurrence_option.dart';
import 'package:belluga_now/domain/schedule/event_profile_group.dart';
import 'package:belluga_now/application/schedule/event_related_profile_groups.dart';
import 'package:belluga_now/application/schedule/event_related_profile_group_summary.dart';
import 'package:belluga_now/domain/schedule/value_objects/event_linked_account_profile_text_value.dart';
import 'package:belluga_now/domain/schedule/value_objects/event_profile_group_order_value.dart';
import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/application/router/support/canonical_route_governance.dart';
import 'package:belluga_now/application/router/support/route_instance_scope.dart';
import 'package:belluga_now/application/router/support/route_redirect_path.dart';
import 'package:belluga_now/application/router/support/tenant_public_event_path.dart';
import 'package:belluga_now/application/telemetry/auth_wall_telemetry.dart';
import 'package:belluga_now/domain/invites/invite_next_step.dart';
import 'package:belluga_now/domain/invites/invite_model.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_id_value.dart';
import 'package:belluga_now/domain/repositories/invites_repository_contract.dart';
import 'package:belluga_now/domain/schedule/sent_invite_status.dart';
import 'package:belluga_now/domain/schedule/sent_invite_summary.dart';
import 'package:belluga_now/application/sharing/event_invite_share_payload.dart';
import 'package:belluga_now/presentation/shared/favorites/account_profile_favorite_auth_gate.dart';
import 'package:belluga_now/presentation/tenant_public/invites/widgets/invite_candidate_picker.dart';
import 'package:belluga_now/presentation/shared/promotion/screens/app_promotion_screen/widgets/app_promotion_modal.dart';
import 'package:belluga_now/presentation/shared/sharing/public_share_launcher.dart';
import 'package:belluga_now/presentation/shared/widgets/immersive_detail_screen/immersive_common_tabs.dart';
import 'package:belluga_now/presentation/shared/widgets/immersive_detail_screen/models/immersive_tab_item.dart';
import 'package:belluga_now/presentation/shared/widgets/immersive_detail_screen/models/immersive_hero_action.dart';
import 'package:belluga_now/presentation/shared/widgets/immersive_detail_screen/immersive_detail_screen.dart';
import 'package:belluga_now/presentation/shared/widgets/directions_app_chooser/directions_app_chooser.dart';
import 'package:belluga_now/presentation/shared/widgets/directions_app_chooser/directions_app_chooser_contract.dart';
import 'package:belluga_now/presentation/shared/widgets/directions_app_chooser/directions_launch_target.dart';
import 'package:belluga_now/presentation/shared/widgets/directions_app_chooser/route_start_point_resolution.dart';
import 'package:belluga_now/presentation/tenant_public/schedule/screens/immersive_event_detail/controllers/immersive_event_detail_controller.dart';
import 'package:belluga_now/application/icons/boora_icons.dart';
import 'package:belluga_now/presentation/tenant_public/schedule/screens/immersive_event_detail/widgets/dynamic_footer.dart';
import 'package:belluga_now/presentation/tenant_public/schedule/screens/immersive_event_detail/widgets/event_local_section.dart';
import 'package:belluga_now/presentation/tenant_public/schedule/screens/immersive_event_detail/widgets/event_info_section.dart';
import 'package:belluga_now/presentation/tenant_public/schedule/screens/immersive_event_detail/widgets/event_programming_section.dart';
import 'package:belluga_now/presentation/tenant_public/schedule/screens/immersive_event_detail/widgets/immersive_hero.dart';
import 'package:belluga_now/presentation/tenant_public/schedule/screens/immersive_event_detail/widgets/linked_profile_category_section.dart';
import 'package:belluga_now/presentation/tenant_public/schedule/screens/immersive_event_detail/widgets/overlapped_invite_avatars.dart';
import 'package:belluga_now/presentation/tenant_public/schedule/screens/immersive_event_detail/widgets/swipeable_invite_widget.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
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
    this.shareLauncher,
    this.externalUrlLauncher,
    this.isWebRuntime = kIsWeb,
    super.key,
  });

  final EventModel event;
  final ColorScheme? colorScheme;
  final DirectionsAppChooserContract? directionsAppChooser;
  final Future<void> Function(ShareParams params)? shareLauncher;
  final ExternalUrlLauncher? externalUrlLauncher;
  final bool isWebRuntime;

  @override
  State<ImmersiveEventDetailScreen> createState() =>
      _ImmersiveEventDetailScreenState();
}

class _ImmersiveEventDetailScreenState
    extends State<ImmersiveEventDetailScreen> {
  late final ImmersiveEventDetailController _controller;
  final GlobalKey _programmingSectionAnchorKey = GlobalKey();
  late final DirectionsAppChooserContract _directionsAppChooser =
      widget.directionsAppChooser ?? DirectionsAppChooser();

  @override
  void initState() {
    super.initState();
    _controller = RouteInstanceScope.read<ImmersiveEventDetailController>(
      context,
    );
    _controller.init(widget.event);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _checkPendingIntent();
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
            return StreamValueBuilder<bool>(
              streamValue: _controller.isConfirmationStateLoadingStreamValue,
              builder: (context, isConfirmationStateLoading) {
                return StreamValueBuilder<Set<String>>(
                  streamValue: _controller.favoriteAccountProfileIdsStreamValue,
                  builder: (context, favoriteAccountProfileIds) {
                    final colorScheme =
                        widget.colorScheme ?? Theme.of(context).colorScheme;
                    return StreamValueBuilder<List<InviteModel>>(
                      streamValue: _controller.receivedInvitesStreamValue,
                      builder: (context, receivedInvites) {
                        return StreamValueBuilder<
                          Map<
                            InvitesRepositoryContractPrimString,
                            SentInviteSummary
                          >
                        >(
                          streamValue: _controller
                              .sentInviteSummariesByOccurrenceStreamValue,
                          builder: (context, sentSummariesByOccurrence) {
                            final selectedOccurrenceId = resolvedEvent
                                .selectedOccurrenceId
                                ?.trim();
                            final sentSummary =
                                selectedOccurrenceId == null ||
                                    selectedOccurrenceId.isEmpty
                                ? null
                                : sentSummariesByOccurrence[invitesRepoString(
                                    selectedOccurrenceId,
                                    defaultValue: '',
                                    isRequired: true,
                                  )];

                            final Widget? topBanner = receivedInvites.isNotEmpty
                                ? Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      16,
                                      12,
                                      16,
                                      8,
                                    ),
                                    child: SwipeableInviteWidget(
                                      invites: receivedInvites,
                                      onAccept: _handleAcceptInvite,
                                      onDecline: _handleDeclineInvite,
                                    ),
                                  )
                                : null;

                            final tabs = <ImmersiveTabItem>[
                              if (_hasAboutContent(resolvedEvent))
                                ImmersiveCommonTabs.about(
                                  content: EventInfoSection(
                                    event: resolvedEvent,
                                  ),
                                  footer: null,
                                ),
                              if (resolvedEvent.hasAnyProgrammingItems)
                                ImmersiveTabItem(
                                  title: 'Programação',
                                  content: KeyedSubtree(
                                    key: _programmingSectionAnchorKey,
                                    child: EventProgrammingSection(
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
                                      onLocationTap:
                                          _openProgrammingLocationMap,
                                    ),
                                  ),
                                  onHorizontalSwipeEnd:
                                      ({
                                        required direction,
                                        required activateTab,
                                        required currentTabIndex,
                                      }) => _handleProgrammingSwipe(
                                        event: resolvedEvent,
                                        direction: direction,
                                        activateTab: activateTab,
                                        currentTabIndex: currentTabIndex,
                                      ),
                                  footer: null,
                                ),
                              ..._buildDynamicProfileTabs(
                                event: resolvedEvent,
                                favoriteAccountProfileIds:
                                    favoriteAccountProfileIds,
                              ),
                              if (_shouldShowLocalTab(resolvedEvent))
                                ImmersiveCommonTabs.custom(
                                  title: 'O Local',
                                  content: EventLocalSection(
                                    event: resolvedEvent,
                                    profileTypeRegistry:
                                        _controller.profileTypeRegistry,
                                    canOpenMap: _canOpenEventMap(resolvedEvent),
                                    onOpenMap: _canOpenEventMap(resolvedEvent)
                                        ? () => _openEventMap(resolvedEvent)
                                        : null,
                                    onOpenDestinationMap:
                                        _openProgrammingLocationMap,
                                    onOpenDirectDirections:
                                        _launchDirectDirections,
                                    onOpenOtherDirections:
                                        _presentDirectionsChooserForTarget,
                                  ),
                                  footer: null,
                                ),
                            ];

                            final footer =
                                isConfirmationStateLoading && !isConfirmed
                                ? DynamicFooter(
                                    buttonText: 'Confirmando presença...',
                                    buttonIcon: Icons.hourglass_top_rounded,
                                    buttonColor:
                                        colorScheme.surfaceContainerHigh,
                                    onActionPressed: null,
                                  )
                                : isConfirmed
                                ? _buildInviteFooter(
                                    context,
                                    () => _openInviteFlow(resolvedEvent),
                                    sentSummary,
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
                              data: Theme.of(
                                context,
                              ).copyWith(colorScheme: colorScheme),
                              child: ImmersiveDetailScreen(
                                heroContentBuilder: (context, activateTab) =>
                                    ImmersiveHero(
                                      event: resolvedEvent,
                                      fallbackImageUri:
                                          _controller.defaultEventImageUri,
                                      onCounterpartTap: (profile) {
                                        final targetIndex =
                                            _linkedProfileTabIndexForHeroTap(
                                              resolvedEvent,
                                              profile,
                                            );
                                        if (targetIndex != null) {
                                          activateTab(targetIndex);
                                        }
                                      },
                                    ),
                                heroViewportHeightFactor: 0.65,
                                title: resolvedEvent.title.value,
                                betweenHeroAndTabs: topBanner,
                                tabs: tabs,
                                canUseTabFooter: (_) => isConfirmed,
                                // Don't auto-navigate, let user scroll naturally
                                initialTabIndex: _resolveInitialTabIndex(
                                  tabs,
                                  context,
                                ),
                                footer: footer,
                                backPolicy:
                                    buildCanonicalCurrentRouteBackPolicy(
                                      context,
                                    ),
                                heroActions: _buildHeroActions(resolvedEvent),
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
      },
    );
  }

  bool _hasAboutContent(EventModel event) {
    final rawHtml = event.content.value ?? '';
    return InviteFromEventFactory.stripHtml(rawHtml).isNotEmpty;
  }

  bool _shouldShowLocalTab(EventModel event) {
    final venue = event.venue;
    if (venue == null) {
      return false;
    }
    return venue.displayName.trim().isNotEmpty;
  }

  List<ImmersiveHeroAction> _buildHeroActions(EventModel event) {
    return <ImmersiveHeroAction>[
      ImmersiveHeroAction(
        key: const Key('immersiveHeroInviteAction'),
        label: 'Convidar',
        icon: BooraIcons.inviteOutlined,
        isPrimary: true,
        onPressed: () => _openInviteFlow(event),
      ),
      ImmersiveHeroAction(
        key: const Key('immersiveHeroShareAction'),
        label: 'Compartilhar',
        icon: BooraIcons.share,
        onPressed: () => unawaited(_shareSelectedEvent(event)),
      ),
      ImmersiveHeroAction(
        key: const Key('immersiveHeroWhatsappAction'),
        label: 'WhatsApp',
        icon: BooraIcons.whatsapp,
        foregroundColor: const Color(0xFF25D366),
        onPressed: () => unawaited(_shareSelectedEventOnWhatsApp(event)),
      ),
    ];
  }

  Future<void> _handleConfirmAttendance() async {
    final routeRedirectPath = buildRedirectPathFromRouteMatch(
      context.routeData.route,
    );
    if (widget.isWebRuntime && !_controller.isAuthorized) {
      AuthWallTelemetry.trackTriggered(
        actionType: AuthWallActionType.confirmAttendance,
        redirectPath: routeRedirectPath,
        allowPendingActionReplay: false,
      );
      await AppPromotionModal.show(
        context,
        redirectPath: routeRedirectPath,
        title: 'Confirme presença pelo app',
        supportingText:
            'Use o app para confirmar sua presença e acompanhar esse evento.',
      );
      return;
    }

    final result = await _controller.confirmAttendance();
    if (!mounted ||
        result != AttendanceConfirmationResult.requiresAuthentication) {
      return;
    }
    final encodedRedirect = Uri.encodeQueryComponent(routeRedirectPath);
    context.router.replacePath('/auth/login?redirect=$encodedRedirect');
  }

  Future<void> _shareSelectedEvent(EventModel event) async {
    final payload = await _buildEventSharePayload(event);
    if (!mounted) {
      return;
    }
    if (payload == null) {
      _showStatusMessage('Não foi possível compartilhar ${event.title.value}.');
      return;
    }

    try {
      await PublicShareLauncher.launchSystemShare(
        ShareParams(text: payload.message, subject: payload.subject),
        launcher: widget.shareLauncher,
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      _showStatusMessage('Não foi possível compartilhar ${event.title.value}.');
    }
  }

  Future<void> _shareSelectedEventOnWhatsApp(EventModel event) async {
    final payload = await _buildEventSharePayload(event);
    if (!mounted) {
      return;
    }
    if (payload == null) {
      _showStatusMessage('Não foi possível compartilhar ${event.title.value}.');
      return;
    }

    try {
      await PublicShareLauncher.launchWhatsAppOrSystemShare(
        text: payload.message,
        subject: payload.subject,
        fallbackShareLauncher: widget.shareLauncher,
        externalUrlLauncher: widget.externalUrlLauncher,
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      _showStatusMessage('Não foi possível compartilhar ${event.title.value}.');
    }
  }

  Future<({String subject, String message})?> _buildEventSharePayload(
    EventModel event,
  ) async {
    if (!_controller.isAuthorized) {
      return _buildEventPublicSharePayload(event);
    }

    final inviteUri = await _controller.createShareUriForSelectedEvent();
    if (inviteUri == null) {
      return null;
    }

    final invite = InviteFromEventFactory.build(
      event: event,
      fallbackImageUri: _controller.defaultEventImageUri,
    );
    return EventInviteSharePayloadBuilder.buildInvitation(
      eventName: invite.eventName,
      location: invite.location,
      eventScheduleLabel: event.flyerScheduleLabel,
      inviteUri: inviteUri,
      participantGroups: _participantGroupsForEventShare(event),
    );
  }

  ({String subject, String message})? _buildEventPublicSharePayload(
    EventModel event,
  ) {
    final eventPath = _eventRedirectPath(event);
    if (eventPath == null) {
      return null;
    }
    final publicUri = _controller.buildTenantPublicUriFromPath(eventPath);
    if (publicUri == null) {
      return null;
    }

    final invite = InviteFromEventFactory.build(
      event: event,
      fallbackImageUri: _controller.defaultEventImageUri,
    );
    return EventInviteSharePayloadBuilder.buildPublicShare(
      eventName: invite.eventName,
      location: invite.location,
      eventScheduleLabel: event.flyerScheduleLabel,
      publicUri: publicUri,
      participantGroups: _participantGroupsForEventShare(event),
    );
  }

  String? _eventRedirectPath(EventModel event) {
    return buildTenantPublicEventPath(
      eventSlug: event.slug,
      occurrenceId: event.selectedOccurrenceId,
    );
  }

  List<EventInviteShareParticipantGroup> _participantGroupsForEventShare(
    EventModel event,
  ) {
    return _aggregatedRelatedProfileGroups(event)
        .map((group) => (label: group.label, names: group.profileNames))
        .toList(growable: false);
  }

  List<ImmersiveTabItem> _buildDynamicProfileTabs({
    required EventModel event,
    required Set<String> favoriteAccountProfileIds,
  }) {
    return _aggregatedRelatedProfileGroups(event)
        .map(
          (group) => ImmersiveTabItem(
            title: group.label,
            content: LinkedProfileCategorySection(
              title: group.label,
              profiles: group.profiles,
              profileTypeRegistry: _controller.profileTypeRegistry,
              favoriteAccountProfileIds: favoriteAccountProfileIds,
              isFavoritable: (profile) =>
                  _controller.isLinkedProfileFavoritable(profile.profileType),
              onProfileTap: _openLinkedProfile,
              onFavoriteTap: (profile) =>
                  _handleLinkedProfileFavoriteTap(profile),
            ),
            footer: null,
          ),
        )
        .toList(growable: false);
  }

  int? _linkedProfileTabIndex(EventModel event, String profileType) {
    final type = profileType.trim();
    if (type.isEmpty) {
      return null;
    }

    final groups = _aggregatedRelatedProfileGroups(event);
    final groupOffset = groups.indexWhere(
      (group) => group.profiles.any((profile) => profile.profileType == type),
    );
    if (groupOffset < 0) {
      return null;
    }

    return _firstDynamicTabIndex(event) + groupOffset;
  }

  int? _linkedProfileTabIndexForHeroTap(
    EventModel event,
    EventLinkedAccountProfile profile,
  ) {
    final groups = _aggregatedRelatedProfileGroups(event);
    final exactGroupOffset = groups.indexWhere(
      (group) => group.profiles.any((candidate) => candidate.id == profile.id),
    );
    if (exactGroupOffset >= 0) {
      return _firstDynamicTabIndex(event) + exactGroupOffset;
    }

    final directIndex = _linkedProfileTabIndex(event, profile.profileType);
    if (directIndex != null) {
      return directIndex;
    }

    if (groups.isEmpty || groups.first.profiles.isEmpty) {
      return null;
    }

    return _linkedProfileTabIndex(
      event,
      groups.first.profiles.first.profileType,
    );
  }

  int _firstDynamicTabIndex(EventModel event) {
    var firstDynamicTabIndex = 0;
    if (_hasAboutContent(event)) {
      firstDynamicTabIndex += 1;
    }
    if (event.hasAnyProgrammingItems) {
      firstDynamicTabIndex += 1;
    }
    return firstDynamicTabIndex;
  }

  void _openInviteFlow(EventModel event) {
    if (widget.isWebRuntime && !_controller.isAuthorized) {
      unawaited(_showInviteComposerPromotion());
      return;
    }

    final invite = _buildInviteFromEvent(event);
    context.router.push(InviteShareRoute(invite: invite));
  }

  Future<void> _showInviteComposerPromotion() {
    final redirectPath = buildRedirectPathFromRouteMatch(
      context.routeData.route,
    );
    AuthWallTelemetry.trackTriggered(
      actionType: AuthWallActionType.sendInvite,
      redirectPath: redirectPath,
      allowPendingActionReplay: false,
    );
    return AppPromotionModal.show(
      context,
      redirectPath: redirectPath,
      title: 'Convide pessoas pelo app',
      supportingText:
          'Use o app para escolher contatos, acompanhar envios e gerenciar convites.',
    );
  }

  Future<void> _handleAcceptInvite(InviteModel invite) {
    if (!_controller.isAuthorized) {
      final redirectPath = _inviteOccurrenceRedirectPath(invite);
      if (kIsWeb) {
        AuthWallTelemetry.trackTriggered(
          actionType: AuthWallActionType.acceptInvite,
          redirectPath: redirectPath,
          allowPendingActionReplay: false,
        );
        return AppPromotionModal.show(
          context,
          redirectPath: redirectPath,
          title: 'Aceite convites pelo app',
          supportingText:
              'Use o app para confirmar presença, enviar convites e acompanhar seus eventos.',
        );
      } else {
        final encodedRedirect = Uri.encodeQueryComponent(redirectPath);
        context.router.replacePath('/auth/login?redirect=$encodedRedirect');
      }
      return Future<void>.value();
    }

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
    if (!_controller.isAuthorized) {
      final redirectPath = _inviteOccurrenceRedirectPath(invite);
      if (kIsWeb) {
        AuthWallTelemetry.trackTriggered(
          actionType: AuthWallActionType.acceptInvite,
          redirectPath: redirectPath,
          allowPendingActionReplay: false,
        );
        return AppPromotionModal.show(
          context,
          redirectPath: redirectPath,
          title: 'Responda convites pelo app',
          supportingText:
              'Use o app para aceitar ou recusar convites e acompanhar seus eventos.',
        );
      }
      final encodedRedirect = Uri.encodeQueryComponent(redirectPath);
      context.router.replacePath('/auth/login?redirect=$encodedRedirect');
      return Future<void>.value();
    }

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

  String _inviteAwarePromotionRedirectPath({InviteModel? invite}) {
    final shareCode =
        (invite == null
                ? _controller.shareCodeForSelectedEvent()
                : _controller.shareCodeForInvite(invite))
            ?.trim();
    if (shareCode != null && shareCode.isNotEmpty) {
      return Uri(
        path: '/invite',
        queryParameters: <String, String>{'code': shareCode},
      ).toString();
    }
    return buildRedirectPathFromRouteMatch(context.routeData.route);
  }

  String _inviteOccurrenceRedirectPath(InviteModel invite) {
    final eventSlug = invite.eventSlug.trim();
    if (eventSlug.isEmpty) {
      return _inviteAwarePromotionRedirectPath(invite: invite);
    }
    return buildTenantPublicEventPath(
          eventSlug: eventSlug,
          occurrenceId: invite.occurrenceId,
        ) ??
        _inviteAwarePromotionRedirectPath(invite: invite);
  }

  void _openEventMap(EventModel event) {
    final venueId = event.venue?.id.trim();
    if (venueId == null || venueId.isEmpty) {
      return;
    }
    final path = Uri(
      path: '/mapa',
      queryParameters: {'poi': 'account_profile:$venueId'},
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
      queryParameters: {'poi': 'account_profile:$profileId'},
    ).toString();
    context.router.pushPath(path);
  }

  void _openOccurrence(
    EventModel event,
    EventOccurrenceOption occurrence, {
    String? tab,
  }) {
    final occurrenceId = occurrence.occurrenceId.trim();
    if (occurrence.isSelected || occurrenceId.isEmpty) {
      return;
    }
    _controller.selectOccurrence(event, occurrence);
    unawaited(
      context.router.navigate(
        ImmersiveEventDetailRoute(
          eventSlug: event.slug,
          occurrenceId: occurrenceId,
          tab: tab?.trim().isNotEmpty == true ? tab!.trim() : null,
        ),
      ),
    );
  }

  bool _handleProgrammingSwipe({
    required EventModel event,
    required ImmersiveHorizontalSwipeDirection direction,
    required ValueChanged<int> activateTab,
    required int currentTabIndex,
  }) {
    final occurrences = event.occurrences;
    if (occurrences.isEmpty) {
      _activateAdjacentTabForProgrammingBoundary(
        direction: direction,
        activateTab: activateTab,
        currentTabIndex: currentTabIndex,
      );
      return true;
    }

    final selectedIndex = _selectedOccurrenceIndex(event);
    final step = direction == ImmersiveHorizontalSwipeDirection.forward
        ? 1
        : -1;
    final targetIndex = selectedIndex + step;
    if (targetIndex >= 0 && targetIndex < occurrences.length) {
      _openOccurrence(event, occurrences[targetIndex], tab: 'programming');
      _realignActiveProgrammingTab(
        activateTab: activateTab,
        currentTabIndex: currentTabIndex,
      );
      return true;
    }

    _activateAdjacentTabForProgrammingBoundary(
      direction: direction,
      activateTab: activateTab,
      currentTabIndex: currentTabIndex,
    );
    return true;
  }

  int _selectedOccurrenceIndex(EventModel event) {
    final selectedIndex = event.occurrences.indexWhere(
      (occurrence) => occurrence.isSelected,
    );
    return selectedIndex < 0 ? 0 : selectedIndex;
  }

  void _activateAdjacentTabForProgrammingBoundary({
    required ImmersiveHorizontalSwipeDirection direction,
    required ValueChanged<int> activateTab,
    required int currentTabIndex,
  }) {
    final delta = direction == ImmersiveHorizontalSwipeDirection.forward
        ? 1
        : -1;
    activateTab(currentTabIndex + delta);
  }

  void _realignActiveProgrammingTab({
    required ValueChanged<int> activateTab,
    required int currentTabIndex,
  }) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      activateTab(currentTabIndex);
    });
  }

  int _resolveInitialTabIndex(
    List<ImmersiveTabItem> tabs,
    BuildContext context,
  ) {
    final requestedTab = context.routeData.queryParams
        .optString('tab')
        ?.trim()
        .toLowerCase();
    if (requestedTab != 'programming') {
      return 0;
    }
    final programmingIndex = tabs.indexWhere(
      (tab) => tab.title == 'Programação',
    );
    return programmingIndex < 0 ? 0 : programmingIndex;
  }

  Future<void> _presentDirectionsChooserForTarget(
    DirectionsLaunchTarget target,
  ) async {
    final resolvedTarget = await RouteStartPointResolution.resolve(
      context: context,
      target: target,
      proximityPreference: _controller.proximityPreference,
      persistRouteReferencePointPolicy:
          _controller.setRouteReferencePointPolicy,
      onStatusMessage: _showStatusMessage,
    );
    if (!mounted || resolvedTarget == null) {
      return;
    }
    return _directionsAppChooser.present(
      context,
      target: resolvedTarget,
      onStatusMessage: _showStatusMessage,
    );
  }

  Future<void> _launchDirectDirections(
    DirectionsDirectProvider provider,
    DirectionsLaunchTarget target,
  ) async {
    final resolvedTarget = await RouteStartPointResolution.resolve(
      context: context,
      target: target,
      proximityPreference: _controller.proximityPreference,
      persistRouteReferencePointPolicy:
          _controller.setRouteReferencePointPolicy,
      onStatusMessage: _showStatusMessage,
    );
    if (!mounted || resolvedTarget == null) {
      return;
    }
    final launched = await _directionsAppChooser.launchDirect(
      provider: provider,
      target: resolvedTarget,
    );
    if (!mounted || launched) {
      return;
    }
    _showStatusMessage(
      'Não foi possível abrir rotas para ${resolvedTarget.destinationName}.',
    );
  }

  bool _canOpenEventMap(EventModel event) {
    final venueId = event.venue?.id.trim();
    return venueId != null && venueId.isNotEmpty;
  }

  void _showStatusMessage(String message) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) {
      return;
    }
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  InviteModel _buildInviteFromEvent(EventModel event) {
    return InviteFromEventFactory.build(
      event: event,
      fallbackImageUri: _controller.defaultEventImageUri,
      profileGroups: _aggregatedProfileGroupsForInvite(event),
    );
  }

  List<EventRelatedProfileGroupSummary> _aggregatedRelatedProfileGroups(
    EventModel event,
  ) {
    return EventRelatedProfileGroups.fromAggregatedEvent(
      event,
      labelResolver: (profileType, fallback) => _controller
          .profileTypePluralLabelFor(profileType, fallback: fallback),
    );
  }

  List<EventProfileGroup> _aggregatedProfileGroupsForInvite(EventModel event) {
    final groups = _aggregatedRelatedProfileGroups(event);
    return [
      for (var index = 0; index < groups.length; index += 1)
        EventProfileGroup(
          idValue: EventLinkedAccountProfileTextValue(
            'event-participants-$index',
          ),
          labelValue: EventLinkedAccountProfileTextValue(groups[index].label),
          orderValue: EventProfileGroupOrderValue(index),
          profiles: groups[index].profiles,
        ),
    ];
  }

  void _checkPendingIntent() {
    if (widget.isWebRuntime) {
      return;
    }
    final redirectPath = buildRedirectPathFromRouteMatch(
      context.routeData.route,
    );
    final action = AuthWallTelemetry.consumePendingAction(redirectPath);
    if (action != null && action.actionType == AuthWallActionType.favorite) {
      final partnerId = action.payload?['partnerId'] as String?;
      if (partnerId != null && partnerId.trim().isNotEmpty) {
        _controller.toggleLinkedProfileFavorite(partnerId);
      }
    }
  }

  void _handleLinkedProfileFavoriteTap(EventLinkedAccountProfile profile) {
    final accountProfileId = profile.id;
    final redirectPath = buildRedirectPathFromRouteMatch(
      context.routeData.route,
    );
    final result = _controller.toggleLinkedProfileFavorite(accountProfileId);
    if (result != LinkedProfileFavoriteToggleOutcome.requiresAuthentication) {
      return;
    }
    unawaited(
      AccountProfileFavoriteAuthGate.handleRequiredAuthentication(
        context: context,
        accountProfileId: accountProfileId,
        redirectPath: redirectPath,
        isWebRuntime: widget.isWebRuntime,
      ),
    );
  }

  void _openLinkedProfile(EventLinkedAccountProfile profile) {
    if (!profile.canOpenPublicDetail) {
      return;
    }

    final publicDetailPath = profile.publicDetailPath?.trim();
    if (publicDetailPath != null && publicDetailPath.isNotEmpty) {
      context.router.pushPath(publicDetailPath);
    }
  }
}

Widget _buildInviteFooter(
  BuildContext context,
  VoidCallback onInviteFriends,
  SentInviteSummary? sentSummary,
) {
  final visibleSentInvites = sentSummary?.preview ?? const <SentInviteStatus>[];
  final hasInvites = sentSummary?.hasVisibleInvites ?? false;
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
                child: Icon(Icons.rocket_launch, color: primary, size: 18),
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
              OverlappedInviteAvatars(invites: visibleSentInvites),
              const SizedBox(height: 4),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 220),
                child: Text(
                  _inviteSummary(sentSummary),
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
    buttonIcon: BooraIcons.inviteSolid,
    buttonColor: primary,
    onActionPressed: onInviteFriends,
  );
}

String _inviteSummary(SentInviteSummary? summary) {
  if (summary == null || !summary.hasVisibleInvites) return '';
  return '${summary.pending} pendentes | ${summary.accepted} confirmados';
}
