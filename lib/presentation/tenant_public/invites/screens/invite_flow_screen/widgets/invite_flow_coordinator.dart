import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/domain/invites/invite_decision.dart';
import 'package:belluga_now/domain/invites/invite_model.dart';
import 'package:belluga_now/presentation/tenant_public/invites/screens/invite_flow_screen/controllers/invite_flow_controller.dart';
import 'package:belluga_now/presentation/tenant_public/invites/screens/invite_flow_screen/widgets/invite_hero_card.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value_builder.dart';

class InviteFlowCoordinator extends StatefulWidget {
  const InviteFlowCoordinator({
    super.key,
    required this.invites,
    required this.decisionResult,
  });

  final List<InviteModel> invites;
  final InviteDecisionResult? decisionResult;

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
    return PopScope(
      canPop: context.router.canPop(),
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _exitInviteFlow();
      },
      child: Scaffold(
        body: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    final invites = widget.invites;
    if (invites.isEmpty) {
      return const SizedBox.shrink();
    }

    return StreamValueBuilder<Set<String>>(
      streamValue: _controller.loadedImagesStreamValue,
      builder: (context, loadedImages) {
        final invite = invites.first;
        final remaining = invites.length - 1;
        final isReady = loadedImages.contains(invite.eventImageUrl);

        if (!isReady) {
          return const Center(child: CircularProgressIndicator());
        }

        return InviteHeroCard(
          invite: invite,
          onAccept: () => _controller.requestDecision(InviteDecision.accepted),
          onDecline: () => _controller.requestDecision(InviteDecision.declined),
          onViewDetails: () => _openEventDetails(invite),
          onClose: _exitInviteFlow,
          remainingCount: remaining,
        );
      },
    );
  }

  void _handlePendingInvites(List<InviteModel> invites) {
    if (invites.isNotEmpty) {
      _exitHandled = false;
      return;
    }
    if (_exitHandled) return;
    _exitHandled = true;
    _scheduleEffect(_exitInviteFlow);
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
        if (result.queued == true) {
          _showOfflineAcceptToast(result.invite);
        }
        router.push(InviteShareRoute(invite: result.invite!)).then((_) {
          _controller.removeInvite();
        });
        _controller.clearDecisionResult();
        return;
      }

      _controller.clearDecisionResult();
    });
  }

  void _openEventDetails(InviteModel invite) {
    context.router.push(ImmersiveEventDetailRoute(eventSlug: invite.eventId));
  }

  void _exitInviteFlow() {
    final router = context.router;
    if (router.canPop()) {
      router.pop();
      return;
    }
    router.replaceAll([const TenantHomeRoute()]);
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
}
