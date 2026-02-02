import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/domain/invites/invite_decision.dart';
import 'package:belluga_now/domain/invites/invite_model.dart';
import 'package:belluga_now/presentation/tenant/invites/screens/invite_flow_screen/controllers/invite_flow_controller.dart';
import 'package:belluga_now/presentation/tenant/invites/screens/invite_flow_screen/widgets/invite_hero_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value_builder.dart';

class InviteFlowScreen extends StatefulWidget {
  const InviteFlowScreen({super.key});

  @override
  State<InviteFlowScreen> createState() => _InviteFlowScreenState();
}

class _InviteFlowScreenState extends State<InviteFlowScreen> {
  final InviteFlowScreenController _controller =
      GetIt.I.get<InviteFlowScreenController>();
  int _precacheToken = 0;
  String? _lastPrecacheKey;

  @override
  void initState() {
    super.initState();
    final inviteId = context.routeData.queryParams.get('invite');
    _controller.init(prioritizeInviteId: inviteId);
  }

  @override
  void dispose() {
    _precacheToken++;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamValueBuilder<InviteDecisionResult?>(
      streamValue: _controller.decisionResultStreamValue,
      builder: (context, decisionResult) {
        _handleDecisionResult(decisionResult);
        return PopScope(
          canPop: context.router.canPop(),
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) return;
            _exitInviteFlow();
          },
          child: Scaffold(
            body: StreamValueBuilder<List<InviteModel>>(
              streamValue: _controller.pendingInvitesStreamValue,
              onNullWidget: const Center(child: CircularProgressIndicator()),
              builder: (context, invites) {
                _precacheNextInvites(invites);
                if (invites.isEmpty) {
                  // Avoid flashing empty state: leave the flow when there's no invite.
                  SchedulerBinding.instance.addPostFrameCallback((_) {
                    _exitInviteFlow();
                  });
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
                      onAccept: () =>
                          _controller.requestDecision(InviteDecision.accepted),
                      onDecline: () =>
                          _controller.requestDecision(InviteDecision.declined),
                      onViewDetails: () => _openEventDetails(invite),
                      onClose: _exitInviteFlow,
                      remainingCount: remaining,
                    );
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  void _handleDecisionResult(InviteDecisionResult? result) {
    if (result == null) return;
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
        if (token != _precacheToken) return;
        _controller.markImageLoaded(url);
      }).catchError((_) {
        if (token != _precacheToken) return;
        _controller.markImageLoaded(url); // avoid blocking on errors
      });
    }
  }
}
