import 'dart:async';
import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/domain/invites/invite_decision.dart';
import 'package:belluga_now/domain/invites/invite_model.dart';
import 'package:belluga_now/presentation/tenant/invites/screens/invite_flow_screen/controllers/invite_flow_controller.dart';
import 'package:belluga_now/presentation/tenant/invites/screens/invite_flow_screen/widgets/invite_empty_state.dart';
import 'package:belluga_now/presentation/tenant/invites/screens/invite_flow_screen/widgets/invite_hero_card.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value_builder.dart';

class InviteFlowScreen extends StatefulWidget {
  const InviteFlowScreen({super.key});

  @override
  State<InviteFlowScreen> createState() => _InviteFlowScreenState();
}

class _InviteFlowScreenState extends State<InviteFlowScreen> {
  final _controller = GetIt.I.get<InviteFlowScreenController>();

  @override
  void initState() {
    super.initState();
    _controller.init();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: StreamValueBuilder<List<InviteModel>>(
          streamValue: _controller.pendingInvitesStreamValue,
          onNullWidget: const Center(child: CircularProgressIndicator()),
          builder: (context, invites) {
            if (invites.isEmpty) {
              return InviteEmptyState(
                onBackToHome: () => context.router.maybePop(),
              );
            }

            final invite = invites.first;
            final remaining = invites.length - 1;

            return InviteHeroCard(
              invite: invite,
              onAccept: () => _handleDecision(InviteDecision.accepted),
              onDecline: () => _handleDecision(InviteDecision.declined),
              onClose: () => context.router.maybePop(),
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

    if (decision == InviteDecision.declined) {
      _showSnack('Convite marcado como não vou desta vez.');
      return;
    }

    if (result != null) {
      await context.router.push(InviteShareRoute(invite: result));
    } else {
      _showSnack('Convite confirmado!');
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
