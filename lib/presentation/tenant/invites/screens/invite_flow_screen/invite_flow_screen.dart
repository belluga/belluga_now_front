import 'dart:async';
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
  final _controller = GetIt.I.get<InviteFlowScreenController>();
  final Set<String> _loadedImages = <String>{};

  @override
  void initState() {
    super.initState();
    final inviteId = context.routeData.queryParams.get('invite');
    _controller.init(prioritizeInviteId: inviteId);
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
        body: StreamValueBuilder<List<InviteModel>>(
          streamValue: _controller.pendingInvitesStreamValue,
          onNullWidget: const Center(child: CircularProgressIndicator()),
          builder: (context, invites) {
            _precacheNextInvites(invites);

            if (invites.isEmpty) {
              // Avoid flashing empty state: leave the flow when there's no invite.
              SchedulerBinding.instance.addPostFrameCallback((_) {
                if (mounted) _exitInviteFlow();
              });
              return const SizedBox.shrink();
            }

            final invite = invites.first;
            final remaining = invites.length - 1;
            final isReady = _loadedImages.contains(invite.eventImageUrl);

            if (!isReady) {
              return const Center(child: CircularProgressIndicator());
            }

            return InviteHeroCard(
              invite: invite,
              onAccept: () => _handleDecision(InviteDecision.accepted),
              onDecline: () => _handleDecision(InviteDecision.declined),
              onViewDetails: () => _openEventDetails(invite),
              onClose: _exitInviteFlow,
              remainingCount: remaining,
            );
          },
        ),
      ),
    );
  }

  Future<void> _handleDecision(InviteDecision decision) async {
    final result = await _controller.applyDecision(decision);
    if (!mounted) return;

    if (decision == InviteDecision.accepted) {
      if (result?.queued == true) {
        _showOfflineAcceptToast(result?.invite);
      }
      if (result?.invite != null) {
        await context.router.push(InviteShareRoute(invite: result!.invite!));
      }
      // Remove only after returning from share to avoid flashing next card mid-navigation.
      _controller.removeInvite();
      return;
    }

    // Decline path: removal already handled in controller.
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
    if (!mounted) return;
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
    if (!mounted) return;
    final ctx = context;
    final toPrecache = invites.take(3); // current + next 2
    for (final invite in toPrecache) {
      final url = invite.eventImageUrl;
      if (_loadedImages.contains(url)) continue;
      precacheImage(NetworkImage(url), ctx).then((_) {
        if (mounted) {
          setState(() {
            _loadedImages.add(url);
          });
        }
      }).catchError((_) {
        if (mounted) {
          setState(() {
            _loadedImages.add(url); // avoid blocking on errors
          });
        }
      });
    }
  }
}
