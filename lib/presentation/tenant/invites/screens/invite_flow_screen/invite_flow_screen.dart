import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:card_stack_swiper/card_stack_swiper.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/domain/invites/invite_decision.dart';
import 'package:belluga_now/domain/invites/invite_model.dart';
import 'package:belluga_now/presentation/tenant/invites/screens/invite_flow_screen/controllers/invite_flow_controller.dart';
import 'package:belluga_now/presentation/tenant/invites/screens/invite_flow_screen/widgets/invite_card.dart';
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
                      return _EmptyInviteState(
                        onBackToHome: () => context.router.maybePop(),
                      );
                    }

                    return Column(
                      children: [
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: _InviteDeck(
                              key: ValueKey(
                                data.map((invite) => invite.id).join('|'),
                              ),
                              invites: data,
                              onSwipe: _onCardSwiped,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        StreamValueBuilder<bool>(
                          streamValue:
                              _controller.confirmingPresenceStreamValue,
                          builder: (_, isConfirmingPresence) {
                            return _ActionBar(
                              onConfirmPresence: _handleConfirmPresence,
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

    _triggerSwipe(CardStackSwiperDirection.left);
  }

  Future<bool> _onCardSwiped(
    int previousIndex,
    int? currentIndex,
    CardStackSwiperDirection direction,
  ) async {
    final decision = _mapDirection(direction);
    if (decision == null) {
      return false;
    }

    final result = await _controller.applyDecision(decision);
    final acceptedInvite = result;

    if (!mounted) {
      return true;
    }

    switch (decision) {
      case InviteDecision.declined:
        _showSnack('Convite marcado como nao vou desta vez.');
        break;
      case InviteDecision.maybe:
        _showSnack('Convite salvo como pensar depois.');
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
    }

    return true;
  }

  InviteDecision? _mapDirection(CardStackSwiperDirection direction) {
    switch (direction) {
      case CardStackSwiperDirection.left:
        return InviteDecision.accepted;
      case CardStackSwiperDirection.right:
        return InviteDecision.declined;
      case CardStackSwiperDirection.top:
        return InviteDecision.maybe;
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

class _InviteDeck extends StatelessWidget {
  const _InviteDeck({
    super.key,
    required this.invites,
    required this.onSwipe,
  });

  final List<InviteModel> invites;
  final CardStackSwiperOnSwipe onSwipe;

  FutureOr<bool> _handleSwipe(
    int previousIndex,
    int? currentIndex,
    CardStackSwiperDirection direction,
  ) {
    final result = onSwipe(previousIndex, currentIndex, direction);
    final controller = GetIt.I.get<InviteFlowScreenController>();

    if (result is Future<bool>) {
      return result.then((approved) {
        if (approved) {
          controller.updateTopCardIndex(
            previousIndex: previousIndex,
            currentIndex: currentIndex,
            invitesLength: invites.length,
          );
        }
        return approved;
      });
    }

    if (result) {
      controller.updateTopCardIndex(
        previousIndex: previousIndex,
        currentIndex: currentIndex,
        invitesLength: invites.length,
      );
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    final controller = GetIt.I.get<InviteFlowScreenController>();
    controller.syncTopCardIndex(invites.length);

    return StreamValueBuilder<int>(
      streamValue: controller.topCardIndexStreamValue,
      builder: (_, topIndex) {
        return CardStackSwiper(
          controller: controller.swiperController,
          cardsCount: invites.length,
          isLoop: false,
          allowedSwipeDirection: const AllowedSwipeDirection.only(
            left: true,
            right: true,
            up: true,
          ),
          cardBuilder: (
            context,
            index,
            horizontalOffsetPercentage,
            verticalOffsetPercentage,
          ) {
            final invite = invites[index];
            final isPreview = horizontalOffsetPercentage != 0 ||
                verticalOffsetPercentage != 0;
            final isTop = index == topIndex;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: InviteCard(
                invite: invite,
                isPreview: isPreview,
                isTopOfDeck: isTop,
              ),
            );
          },
          onSwipe: _handleSwipe,
        );
      },
    );
  }
}

class _ActionBar extends StatelessWidget {
  const _ActionBar({
    required this.onConfirmPresence,
    required this.isConfirmingPresence,
  });

  final VoidCallback onConfirmPresence;
  final bool isConfirmingPresence;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final buttonLabel =
        isConfirmingPresence ? 'Bora! Agora é chamar os amigos...' : 'Bora?';
    final buttonIcon = isConfirmingPresence
        ? Icons.check_circle_outline
        : Icons.rocket_launch_outlined;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => GetIt.I
                    .get<InviteFlowScreenController>()
                    .applyDecision(InviteDecision.declined),
                icon: Icon(buttonIcon),
                label: Text("Recusar"),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: FilledButton.icon(
                onPressed: onConfirmPresence,
                icon: Icon(buttonIcon),
                label: Text(buttonLabel),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextButton.icon(
          onPressed: () => GetIt.I
              .get<InviteFlowScreenController>()
              .applyDecision(InviteDecision.maybe),
          icon: const Icon(Icons.group_add_outlined),
          label: const Text('Quem sabe...'),
        ),
      ],
    );
  }
}

class _EmptyInviteState extends StatelessWidget {
  const _EmptyInviteState({
    required this.onBackToHome,
  });

  final VoidCallback onBackToHome;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 64,
            color: theme.colorScheme.secondary,
          ),
          const SizedBox(height: 12),
          Text(
            'Tudo em dia!',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Voce respondeu todos os convites pendentes.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: onBackToHome,
            child: const Text('Voltar para Home'),
          ),
        ],
      ),
    );
  }
}
