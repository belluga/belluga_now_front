import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/application/router/support/canonical_route_governance.dart';
import 'package:belluga_now/application/router/support/route_back_policy.dart';
import 'package:belluga_now/application/router/support/route_redirect_path.dart';
import 'package:belluga_now/domain/invites/invite_decision.dart';
import 'package:belluga_now/domain/invites/invite_model.dart';
import 'package:belluga_now/domain/invites/invite_next_step.dart';
import 'package:belluga_now/application/telemetry/auth_wall_telemetry.dart';
import 'package:belluga_now/presentation/tenant_public/invites/screens/invite_flow_screen/controllers/invite_flow_controller.dart';
import 'package:belluga_now/presentation/tenant_public/invites/screens/invite_flow_screen/widgets/invite_hero_card.dart';
import 'package:belluga_now/presentation/tenant_public/invites/widgets/invite_candidate_picker.dart';
import 'package:belluga_now/presentation/shared/promotion/screens/app_promotion_screen/controllers/app_promotion_screen_controller.dart';
import 'package:belluga_now/presentation/shared/promotion/screens/app_promotion_screen/widgets/app_promotion_modal.dart';
import 'package:belluga_now/presentation/shared/widgets/route_back_scope.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value_builder.dart';

class InviteFlowCoordinator extends StatefulWidget {
  const InviteFlowCoordinator({
    super.key,
    required this.invites,
    required this.decisionResult,
    required this.requiresAuthentication,
    required this.isInitialized,
    this.fallbackPath,
    this.isWebRuntime = kIsWeb,
  });

  final List<InviteModel> invites;
  final InviteDecisionResult? decisionResult;
  final bool requiresAuthentication;
  final bool isInitialized;
  final String? fallbackPath;
  final bool isWebRuntime;

  @override
  State<InviteFlowCoordinator> createState() => _InviteFlowCoordinatorState();
}

class _InviteFlowCoordinatorState extends State<InviteFlowCoordinator> {
  final InviteFlowScreenController _controller =
      GetIt.I.get<InviteFlowScreenController>();
  int _precacheToken = 0;
  String? _lastPrecacheKey;
  bool _exitHandled = false;
  InviteDecisionResult? _lastDecisionResult;

  @override
  void initState() {
    super.initState();
    _handleDecisionResult(widget.decisionResult);
    _handlePendingInvites(widget.invites);
    _precacheNextInvites(widget.invites);
  }

  @override
  void didUpdateWidget(covariant InviteFlowCoordinator oldWidget) {
    super.didUpdateWidget(oldWidget);
    _handleDecisionResult(widget.decisionResult);
    _handlePendingInvites(widget.invites);
    _precacheNextInvites(widget.invites);
  }

  @override
  void dispose() {
    _precacheToken++;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final backPolicy = _buildBackPolicy(context);
    return RouteBackScope(
      backPolicy: backPolicy,
      child: Scaffold(
        body: _buildContent(backPolicy),
      ),
    );
  }

  Widget _buildContent(RouteBackPolicy backPolicy) {
    final invites = widget.invites;
    if (!widget.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    if (invites.isEmpty) {
      if (widget.isWebRuntime && !_controller.isAuthorized) {
        return _buildWebPromotionFallback();
      }
      return const SizedBox.shrink();
    }

    return StreamValueBuilder<Set<String>>(
      streamValue: _controller.loadedImagesStreamValue,
      builder: (context, loadedImages) {
        final invite = invites.first;
        final remaining = invites.length - 1;

        return InviteHeroCard(
          invite: invite,
          onAccept: () => _handleDecision(invite, InviteDecision.accepted),
          onDecline: () => _handleDecision(invite, InviteDecision.declined),
          onViewDetails: () => _openEventDetails(invite),
          onClose: backPolicy.handleBack,
          remainingCount: remaining,
          requiresAuthentication: widget.requiresAuthentication,
          onRequestAuthentication: () => _openAuthForInviteDecision(invite),
        );
      },
    );
  }

  void _handlePendingInvites(List<InviteModel> invites) {
    if (!widget.isInitialized) {
      return;
    }
    if (widget.isWebRuntime && !_controller.isAuthorized && invites.isEmpty) {
      _exitHandled = false;
      return;
    }
    if (invites.isNotEmpty) {
      _exitHandled = false;
      return;
    }
    if (_exitHandled) return;
    _exitHandled = true;
    _scheduleEffect(() {
      unawaited(_exitInviteFlowOrFallback());
    });
  }

  void _handleDecisionResult(InviteDecisionResult? result) {
    if (result == null) {
      _lastDecisionResult = null;
      return;
    }
    if (identical(result, _lastDecisionResult)) return;
    _lastDecisionResult = result;
    _scheduleEffect(() {
      final router = context.router;

      if (result.invite != null) {
        if (result.nextStep == InviteNextStep.reservationRequired ||
            result.nextStep == InviteNextStep.commitmentChoiceRequired ||
            result.nextStep == InviteNextStep.openAppToContinue) {
          _showUnsupportedNextStepToast(result.invite!, result.nextStep);
          _controller.clearDecisionResult();
          return;
        }
        if (result.queued == true) {
          _showOfflineAcceptToast(result.invite);
        }
        router.push(InviteShareRoute(invite: result.invite!));
        _controller.clearDecisionResult();
        return;
      }

      _controller.clearDecisionResult();
    });
  }

  void _openEventDetails(InviteModel invite) {
    final eventSlug = invite.eventSlug.trim();
    if (eventSlug.isEmpty) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        const SnackBar(
          content:
              Text('Os detalhes deste evento ainda não estão disponíveis.'),
        ),
      );
      return;
    }
    context.router.push(
      ImmersiveEventDetailRoute(
        eventSlug: eventSlug,
        occurrenceId: invite.occurrenceId,
      ),
    );
  }

  Future<void> _handleDecision(
    InviteModel invite,
    InviteDecision decision,
  ) async {
    if (widget.isWebRuntime && !_controller.isAuthorized) {
      await _showWebInviteDecisionPromotion(
        invite: invite,
        decision: decision,
      );
      return;
    }

    final hasSelectableCandidate = invite.inviters
        .any((candidate) => candidate.inviteId.trim().isNotEmpty);
    if (invite.hasMultipleInviters && !hasSelectableCandidate) {
      await _controller.requestDecision(decision);
      return;
    }

    final inviteId = await showInviteCandidatePicker(
      context,
      invite: invite,
      actionLabel: decision == InviteDecision.accepted ? 'Aceitar' : 'Recusar',
    );
    if (inviteId == null) {
      if (!invite.hasMultipleInviters) {
        await _controller.requestDecision(decision);
      }
      return;
    }

    if (inviteId.isEmpty) {
      await _controller.requestDecision(decision);
      return;
    }
    await _controller.requestDecisionForInvite(decision, inviteId);
  }

  void _openAuthForInviteDecision(InviteModel invite) {
    if (widget.isWebRuntime && !_controller.isAuthorized) {
      unawaited(
        AppPromotionModal.show(
          context,
          redirectPath: _inviteOccurrenceRedirectPath(invite),
          title: 'Aceite convites pelo app',
          supportingText:
              'Use o app para confirmar presença, enviar convites e acompanhar seus eventos.',
        ),
      );
      return;
    }
    final pendingPath = _controller.redirectPath?.trim();
    final normalizedPath =
        pendingPath == null || pendingPath.isEmpty ? '/invite' : pendingPath;
    final encodedRedirect = Uri.encodeQueryComponent(normalizedPath);
    context.router.pushPath('/auth/login?redirect=$encodedRedirect');
  }

  Widget _buildWebPromotionFallback() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: AppPromotionModal(
            controller: GetIt.I.get<AppPromotionScreenController>(),
            redirectPath: _promotionRedirectPath(),
            title: 'Aceite convites pelo app',
            supportingText:
                'Use o app para confirmar presença, enviar convites e acompanhar seus eventos.',
          ),
        ),
      ),
    );
  }

  Future<void> _showWebInviteDecisionPromotion({
    required InviteModel invite,
    required InviteDecision decision,
  }) async {
    final redirectPath = _inviteOccurrenceRedirectPath(invite);
    AuthWallTelemetry.trackTriggered(
      actionType: AuthWallActionType.acceptInvite,
      redirectPath: redirectPath,
      allowPendingActionReplay: false,
    );
    await AppPromotionModal.show(
      context,
      redirectPath: redirectPath,
      title: decision == InviteDecision.accepted
          ? 'Aceite convites pelo app'
          : 'Responda convites pelo app',
      supportingText: decision == InviteDecision.accepted
          ? 'Use o app para confirmar presença, enviar convites e acompanhar seus eventos.'
          : 'Use o app para aceitar ou recusar convites e acompanhar seus eventos.',
    );
  }

  RouteBackPolicy _buildBackPolicy(BuildContext context) {
    return buildCanonicalCurrentRouteBackPolicy(context);
  }

  void _exitInviteFlow() {
    _buildBackPolicy(context).handleBack();
  }

  Future<void> _exitInviteFlowOrFallback() async {
    final fallbackPath = await _resolveFallbackNavigationPath();
    if (!mounted) {
      return;
    }
    if (fallbackPath != null && fallbackPath.isNotEmpty) {
      context.router.replacePath(fallbackPath);
      return;
    }
    _exitInviteFlow();
  }

  Future<String?> _resolveFallbackNavigationPath() async {
    return _controller.resolveFallbackNavigationPath(widget.fallbackPath);
  }

  void _showOfflineAcceptToast(InviteModel? invite) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          invite == null
              ? 'Invite accepted offline. It will sync when you reconnect.'
              : 'Invite accepted for ${invite.eventName}. Syncing when online.',
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showUnsupportedNextStepToast(
    InviteModel invite,
    InviteNextStep nextStep,
  ) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          nextStep == InviteNextStep.openAppToContinue
              ? 'Convite aceito para ${invite.eventName}. Continue pelo app.'
              : 'Convite aceito para ${invite.eventName}. A proxima etapa ainda nao esta disponivel nesta versao.',
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _precacheNextInvites(List<InviteModel> invites) {
    if (invites.isEmpty) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _precacheNextInvitesNow(invites);
    });
  }

  void _precacheNextInvitesNow(List<InviteModel> invites) {
    final ctx = context;
    final toPrecache = invites.take(3); // current + next 2
    final key = toPrecache.map((invite) => invite.eventImageUrl).join('|');
    if (key.isNotEmpty && key == _lastPrecacheKey) {
      return;
    }
    _lastPrecacheKey = key;
    final token = ++_precacheToken;
    for (final invite in toPrecache) {
      final url = invite.eventImageUrl;
      if (_controller.isImageLoaded(url)) continue;
      precacheImage(NetworkImage(url), ctx).then((_) {
        if (token != _precacheToken || !mounted) return;
        _controller.markImageLoaded(url);
      }).catchError((_) {
        if (token != _precacheToken || !mounted) return;
        _controller.markImageLoaded(url); // avoid blocking on errors
      });
    }
  }

  void _scheduleEffect(VoidCallback action) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      action();
    });
  }

  String _promotionRedirectPath() {
    final explicit = _controller.redirectPath?.trim();
    if (explicit != null && explicit.isNotEmpty) {
      return explicit;
    }

    return buildRedirectPathFromRouteMatch(context.routeData.route);
  }

  String _inviteOccurrenceRedirectPath(InviteModel invite) {
    final eventSlug = invite.eventSlug.trim();
    if (eventSlug.isEmpty) {
      return _promotionRedirectPath();
    }
    final occurrenceId = invite.occurrenceId?.trim() ?? '';
    return Uri(
      path: '/agenda/evento/$eventSlug',
      queryParameters: occurrenceId.isEmpty
          ? null
          : <String, String>{'occurrence': occurrenceId},
    ).toString();
  }
}
