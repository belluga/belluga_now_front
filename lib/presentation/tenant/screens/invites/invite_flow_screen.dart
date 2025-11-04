import 'package:auto_route/auto_route.dart';
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

  @override
  void initState() {
    super.initState();
    _controller.init();
  }

  @override
  void dispose() {
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
                  final count = remaining ?? 0;
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
                child: StreamValueBuilder<InviteModel?>(
                  streamValue: _controller.currentInviteStreamValue,
                  builder: (context, invite) {
                    if (invite == null) {
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
                              current: invite,
                              previews: _controller.peekNextInvites(limit: 3),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _ActionBar(
                          onDecline: () =>
                              _handleDecision(InviteDecision.declined),
                          onMaybe: () => _handleDecision(InviteDecision.maybe),
                          onAccept: () =>
                              _handleDecision(InviteDecision.accepted),
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

  Future<void> _handleDecision(InviteDecision decision) async {
    final acceptedInvite = _controller.respondToInvite(decision);

    if (!mounted) {
      return;
    }

    switch (decision) {
      case InviteDecision.declined:
        _showSnack('Convite marcado como nao vou desta vez.');
      case InviteDecision.maybe:
        _showSnack('Convite salvo como pensar depois.');
      case InviteDecision.accepted:
        if (acceptedInvite != null) {
          await context.router.push(
            InviteShareRoute(
              invite: acceptedInvite,
              friends: _controller.friendSuggestions,
            ),
          );
        } else {
          _showSnack('Convite confirmado!');
        }
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
    required this.current,
    required this.previews,
  });

  final InviteModel current;
  final List<InviteModel> previews;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final layers = <Widget>[];
        final limitedPreviews = previews.take(3).toList();

        for (var index = limitedPreviews.length - 1; index >= 0; index--) {
          final depth = limitedPreviews.length - index;
          final preview = limitedPreviews[index];
          final widthFactor =
              (0.94 - (depth * 0.04)).clamp(0.78, 0.94).toDouble();
          final heightFactor =
              (0.9 - (depth * 0.035)).clamp(0.75, 0.9).toDouble();
          final width = constraints.maxWidth * widthFactor;
          final height = constraints.maxHeight * heightFactor;
          final horizontalMargin = (constraints.maxWidth - width) / 2;
          final topOffset = 18.0 * depth;

          layers.add(
            Positioned(
              top: topOffset,
              left: horizontalMargin,
              right: horizontalMargin,
              child: IgnorePointer(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOut,
                  height: height,
                  child: InviteCard(
                    invite: preview,
                    isPreview: true,
                  ),
                ),
              ),
            ),
          );
        }

        layers.add(
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            transitionBuilder: (child, animation) => ScaleTransition(
              scale: CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutBack,
              ),
              child: child,
            ),
            child: SizedBox(
              key: ValueKey(current.id),
              width: constraints.maxWidth,
              height: constraints.maxHeight,
              child: InviteCard(invite: current),
            ),
          ),
        );

        return Stack(
          clipBehavior: Clip.none,
          children: layers,
        );
      },
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
