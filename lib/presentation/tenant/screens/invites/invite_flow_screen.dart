import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:card_stack_swiper/card_stack_swiper.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/domain/invites/invite_decision.dart';
import 'package:belluga_now/domain/invites/invite_model.dart';
import 'package:belluga_now/presentation/tenant/screens/invites/controller/invite_flow_controller.dart';
import 'package:belluga_now/presentation/tenant/screens/invites/widgets/invite_card.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value_builder.dart';

class InviteFlowScreen extends StatefulWidget {
  const InviteFlowScreen({super.key});

  @override
  State<InviteFlowScreen> createState() => _InviteFlowScreenState();
}

class _InviteFlowScreenState extends State<InviteFlowScreen> {
  final _controller = GetIt.I.get<InviteFlowController>();

  bool _isConfirmingPresence = false;

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
                              swiperController: _controller.swiperController,
                              onSwipe: _onCardSwiped,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _ActionBar(
                          onConfirmPresence: _handleConfirmPresence,
                          onInviteFriends: _handleInviteFriendsTap,
                          isConfirmingPresence: _isConfirmingPresence,
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
    if (_isConfirmingPresence) {
      return;
    }

    final invite = _controller.currentInvite;
    if (invite == null) {
      _showSnack('Nenhum convite pendente.');
      return;
    }

    setState(() {
      _isConfirmingPresence = true;
    });
    _triggerSwipe(CardStackSwiperDirection.left);
  }

  void _handleInviteFriendsTap() {
    _handleConfirmPresence();
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

    final acceptedInvite = _controller.respondToInvite(decision);

    if (!mounted) {
      return true;
    }

    switch (decision) {
      case InviteDecision.declined:
        setState(() {
          _isConfirmingPresence = false;
        });
        _showSnack('Convite marcado como nao vou desta vez.');
        break;
      case InviteDecision.maybe:
        setState(() {
          _isConfirmingPresence = false;
        });
        _showSnack('Convite salvo como pensar depois.');
        break;
      case InviteDecision.accepted:
        if (acceptedInvite != null) {
          final inviteToShare = acceptedInvite;

          context.router.push(
            InviteShareRoute(
              invite: inviteToShare,
            ),
          );
        } else {
          setState(() {
            _isConfirmingPresence = false;
          });
          _showSnack('Convite confirmado!');
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

class _InviteDeck extends StatefulWidget {
  const _InviteDeck({
    super.key,
    required this.invites,
    required this.swiperController,
    required this.onSwipe,
  });

  final List<InviteModel> invites;
  final CardStackSwiperController swiperController;
  final CardStackSwiperOnSwipe onSwipe;

  @override
  State<_InviteDeck> createState() => _InviteDeckState();
}

class _InviteDeckState extends State<_InviteDeck> {
  int _currentTopIndex = 0;

  @override
  void didUpdateWidget(covariant _InviteDeck oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.invites.isEmpty) {
      _currentTopIndex = 0;
    } else if (_currentTopIndex >= widget.invites.length) {
      _currentTopIndex = 0;
    }
  }

  void _setTopIndex(int? currentIndex, int previousIndex) {
    if (widget.invites.isEmpty) {
      _currentTopIndex = 0;
      return;
    }
    final nextIndex = currentIndex ?? previousIndex;
    _currentTopIndex = nextIndex.clamp(0, widget.invites.length - 1);
  }

  FutureOr<bool> _handleSwipe(
    int previousIndex,
    int? currentIndex,
    CardStackSwiperDirection direction,
  ) {
    final result = widget.onSwipe(previousIndex, currentIndex, direction);

    if (result is Future<bool>) {
      return result.then((approved) {
        if (approved) {
          setState(() {
            _setTopIndex(currentIndex, previousIndex);
          });
        }
        return approved;
      });
    }

    if (result) {
      setState(() {
        _setTopIndex(currentIndex, previousIndex);
      });
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    return CardStackSwiper(
      controller: widget.swiperController,
      cardsCount: widget.invites.length,
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
        final invite = widget.invites[index];
        final isPreview =
            horizontalOffsetPercentage != 0 || verticalOffsetPercentage != 0;
        final isTop = index == _currentTopIndex;
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
  }
}

class _ActionBar extends StatelessWidget {
  _ActionBar({
    required this.onConfirmPresence,
    required this.onInviteFriends,
    required this.isConfirmingPresence,
  });

  final _controller = GetIt.I.get<InviteFlowController>();

  final VoidCallback onConfirmPresence;
  final VoidCallback onInviteFriends;
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
                onPressed: () => _controller.respondToInvite(InviteDecision.declined),
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
                onPressed: () => _controller.respondToInvite(InviteDecision.accepted),
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
          onPressed: () => _controller.respondToInvite(InviteDecision.maybe),
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
