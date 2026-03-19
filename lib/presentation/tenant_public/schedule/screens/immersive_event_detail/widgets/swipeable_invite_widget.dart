import 'package:belluga_now/domain/invites/invite_model.dart';
import 'package:belluga_now/presentation/shared/widgets/swipeable_card/swipeable_card.dart';
import 'package:belluga_now/presentation/tenant_public/schedule/screens/immersive_event_detail/widgets/invite_deck_card.dart';
import 'package:flutter/material.dart';

class SwipeableInviteWidget extends StatelessWidget {
  const SwipeableInviteWidget({
    super.key,
    required this.invites,
    required this.onAccept,
    required this.onDecline,
  });

  final List<InviteModel> invites;
  final Future<void> Function(InviteModel) onAccept;
  final Future<void> Function(InviteModel) onDecline;

  @override
  Widget build(BuildContext context) {
    if (invites.isEmpty) {
      return const SizedBox.shrink();
    }

    final currentInvite = invites.first;
    final nextInvite = invites.length > 1 ? invites[1] : null;

    return SizedBox(
      height: 180,
      child: Stack(
        children: [
          if (nextInvite != null)
            Positioned.fill(
              child: Transform.scale(
                scale: 0.95,
                child: InviteDeckCard(
                  invite: nextInvite,
                  onAccept: () {},
                  onDecline: () {},
                ),
              ),
            ),
          SwipeableCard(
            key: ValueKey(currentInvite.id),
            onSwipeRight: () async {
              await onAccept(currentInvite);
            },
            onSwipeLeft: () async {
              await onDecline(currentInvite);
            },
            child: InviteDeckCard(
              invite: currentInvite,
              onAccept: () async {
                await onAccept(currentInvite);
              },
              onDecline: () async {
                await onDecline(currentInvite);
              },
            ),
          ),
        ],
      ),
    );
  }
}
