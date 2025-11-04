import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:card_stack_swiper/card_stack_swiper.dart';
import 'package:belluga_now/application/router/manual_route_stubs.dart';
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
  late final InviteFlowController _controller =
      GetIt.I.get<InviteFlowController>();
  final CardStackSwiperController _swiperController =
      CardStackSwiperController();

  @override
  void initState() {
    super.initState();
    _controller.init();
  }

  @override
  void dispose() {
    unawaited(_swiperController.dispose());
    _controller.onDispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
              StreamValueBuilder<int>(
                streamValue: _controller.remainingInvitesStreamValue,
                builder: (context, remaining) {
                  final count = remaining;

                  if(count == 0){
                    return SizedBox.shrink();
                  }

                  final label = count == 0
                      ? 'Nenhum convite pendente'
                      : count == 1
                          ? '1 convite pendente'
                          : '$count convites pendentes';
                  return Text(
                    label,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              Expanded(
                child: StreamValueBuilder<List<InviteModel>>(
                  streamValue: _controller.pendingInvitesStreamValue,
                  builder: (context, invites) {
                    final data = invites ?? const <InviteModel>[];
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
                              swiperController: _swiperController,
                              onSwipe: _onCardSwiped,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _ActionBar(
                          onDecline: () =>
                              _triggerSwipe(CardStackSwiperDirection.left),
                          onMaybe: () =>
                              _triggerSwipe(CardStackSwiperDirection.top),
                          onAccept: () =>
                              _triggerSwipe(CardStackSwiperDirection.right),
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
    if (_controller.pendingInvites.isEmpty) {
      _showSnack('Nenhum convite pendente.');
      return;
    }
    _swiperController.swipe(direction);
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
        _showSnack('Convite marcado como nao vou desta vez.');
        break;
      case InviteDecision.maybe:
        _showSnack('Convite salvo como pensar depois.');
        break;
      case InviteDecision.accepted:
        if (acceptedInvite != null) {
          Future.microtask(() {
            if (!mounted) {
              return;
            }
            context.router.push(
              InviteShareRoute(
                invite: acceptedInvite,
                friends: _controller.friendSuggestions,
              ),
            );
          });
        } else {
          _showSnack('Convite confirmado!');
        }
        break;
    }

    return true;
  }

  InviteDecision? _mapDirection(CardStackSwiperDirection direction) {
    switch (direction) {
      case CardStackSwiperDirection.left:
        return InviteDecision.declined;
      case CardStackSwiperDirection.right:
        return InviteDecision.accepted;
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
    required this.swiperController,
    required this.onSwipe,
  });

  final List<InviteModel> invites;
  final CardStackSwiperController swiperController;
  final CardStackSwiperOnSwipe onSwipe;

  @override
  Widget build(BuildContext context) {
    return CardStackSwiper(
      controller: swiperController,
      cardsCount: invites.length,
      // isLoop: false,
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
        final isPreview =
            horizontalOffsetPercentage != 0 || verticalOffsetPercentage != 0;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: InviteCard(
            invite: invite,
            isPreview: isPreview,
          ),
        );
      },
      onSwipe: onSwipe,
    );
  }
}

class _ActionBar extends StatelessWidget {
  const _ActionBar({
    required this.onDecline,
    required this.onMaybe,
    required this.onAccept,
  });

  final VoidCallback onDecline;
  final VoidCallback onMaybe;
  final VoidCallback onAccept;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onDecline,
                icon: const Icon(Icons.close),
                label: const Text('Nao rola'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onMaybe,
                icon: const Icon(Icons.hourglass_bottom),
                label: const Text('Talvez'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: onAccept,
            icon: const Icon(Icons.rocket_launch_outlined),
            label: const Text('Bora!'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              textStyle: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
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
