import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:card_stack_swiper/card_stack_swiper.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/domain/invites/invite_decision.dart';
import 'package:belluga_now/domain/invites/invite_model.dart';
import 'package:belluga_now/presentation/tenant/invites/screens/invite_flow_screen/controllers/invite_flow_controller.dart';
import 'package:belluga_now/presentation/tenant/invites/screens/invite_flow_screen/widgets/invite_deck.dart';
import 'package:belluga_now/presentation/tenant/invites/screens/invite_flow_screen/widgets/invite_empty_state.dart';
import 'package:belluga_now/presentation/tenant/invites/screens/invite_flow_screen/widgets/invite_flow_action_bar.dart';
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
      appBar: AppBar(
        title: const Text('Convites'),
        actions: [
          IconButton(
            tooltip: 'Fechar',
            onPressed: () => context.router.maybePop(),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: StreamValueBuilder<List<InviteModel>>(
                  streamValue: _controller.pendingInvitesStreamValue,
                  onNullWidget: CircularProgressIndicator(),
                  builder: (context, invites) {
                    final data = invites;
                    if (data.isEmpty) {
                      return InviteEmptyState(
                        onBackToHome: () => context.router.maybePop(),
                      );
                    }
                    _controller.syncTopCardIndex(data.length);

                    return Column(
                      children: [
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: InviteDeck(
                              key: ValueKey(
                                data.map((invite) => invite.id).join('|'),
                              ),
                              invites: data,
                              swiperController: _controller.swiperController,
                              topCardIndexStreamValue:
                                  _controller.topCardIndexStreamValue,
                              onSwipe: (
                                previousIndex,
                                currentIndex,
                                direction,
                              ) =>
                                  _onCardSwiped(
                                previousIndex: previousIndex,
                                currentIndex: currentIndex,
                                direction: direction,
                                invitesLength: data.length,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        StreamValueBuilder<bool>(
                          streamValue:
                              _controller.confirmingPresenceStreamValue,
                          builder: (_, isConfirmingPresence) {
                            return InviteFlowActionBar(
                              onConfirmPresence: _handleConfirmPresence,
                              onDecline: () => _controller
                                  .applyDecision(InviteDecision.declined),
                              isConfirmingPresence: isConfirmingPresence,
                            );
                          },
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _triggerSwipe(CardStackSwiperDirection direction) {
    if (!_controller.hasPendingInvites) {
      _showSnack('Nenhum convite pendente.');
      return;
    }
    _controller.swiperController.swipe(direction);
  }

  void _handleConfirmPresence() {
    if (_controller.confirmingPresenceStreamValue.value) {
      return;
    }

    final started = _controller.beginConfirmPresence();
    if (!started) {
      _showSnack('Nenhum convite pendente.');
      return;
    }

    _triggerSwipe(CardStackSwiperDirection.right);
  }

  Future<bool> _onCardSwiped({
    required int previousIndex,
    required int? currentIndex,
    required CardStackSwiperDirection direction,
    required int invitesLength,
  }) async {
    final decision = _mapDirection(direction);
    if (decision == null) {
      return false;
    }

    final result = await _controller.applyDecision(decision);
    final acceptedInvite = result;
    _controller.updateTopCardIndex(
      previousIndex: previousIndex,
      currentIndex: currentIndex,
      invitesLength: invitesLength,
    );

    if (!mounted) {
      return true;
    }

    switch (decision) {
      case InviteDecision.declined:
        _showSnack('Convite marcado como nao vou desta vez.');
        break;
      case InviteDecision.accepted:
        if (acceptedInvite != null) {
          final inviteToShare = acceptedInvite;

          await context.router.push(
            InviteShareRoute(
              invite: inviteToShare,
            ),
          );
          _controller.resetConfirmPresence();
        } else {
          _showSnack('Convite confirmado!');
          _controller.resetConfirmPresence();
        }
        break;
      default:
        break;
    }

    return true;
  }

  InviteDecision? _mapDirection(CardStackSwiperDirection direction) {
    switch (direction) {
      case CardStackSwiperDirection.right:
        return InviteDecision.accepted;
      case CardStackSwiperDirection.left:
        return InviteDecision.declined;
      case CardStackSwiperDirection.top:
      case CardStackSwiperDirection.none:
      case CardStackSwiperDirection.bottom:
        return null;
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
