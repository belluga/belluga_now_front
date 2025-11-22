import 'package:belluga_now/domain/invites/invite_model.dart';
import 'package:card_stack_swiper/card_stack_swiper.dart';
import 'package:flutter/material.dart';

class SwipeableInviteWidget extends StatelessWidget {
  const SwipeableInviteWidget({
    super.key,
    required this.invites,
    required this.onAccept,
    required this.onDecline,
  });

  final List<InviteModel> invites;
  final ValueChanged<String> onAccept;
  final ValueChanged<String> onDecline;

  @override
  Widget build(BuildContext context) {
    if (invites.isEmpty) return const SizedBox.shrink();

    // If only one invite, show it directly without swiper (or with swiper but locked?)
    // The user asked for "swipable as the swipe screen", which implies the deck UI.
    // Even for one card, the deck UI looks nice.

    return SizedBox(
      height: 180, // Fixed height for the widget
      child: CardStackSwiper(
        cardsCount: invites.length,
        isLoop: false,
        allowedSwipeDirection: const AllowedSwipeDirection.only(
          left: true,
          right: true,
          up: true,
        ),
        cardBuilder: (context, index, horizontalOffset, verticalOffset) {
          final invite = invites[index];
          return _InviteDeckCard(
            invite: invite,
            onAccept: () => onAccept(invite.id),
            onDecline: () => onDecline(invite.id),
          );
        },
        onSwipe: (previousIndex, currentIndex, direction) async {
          final invite = invites[previousIndex];
          switch (direction) {
            case CardStackSwiperDirection.right:
              onAccept(invite.id);
              break;
            case CardStackSwiperDirection.left:
              onDecline(invite.id);
              break;
            default:
              break;
          }
          return true;
        },
      ),
    );
  }
}

class _InviteDeckCard extends StatelessWidget {
  const _InviteDeckCard({
    required this.invite,
    required this.onAccept,
    required this.onDecline,
  });

  final InviteModel invite;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Image.network(
              invite.eventImageUrl,
              fit: BoxFit.cover,
            ),
          ),
          // Gradient Overlay
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.4),
                    Colors.black.withValues(alpha: 0.8),
                  ],
                ),
              ),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundImage: invite.inviterAvatarUrl != null
                          ? NetworkImage(invite.inviterAvatarUrl!)
                          : null,
                      child: invite.inviterAvatarUrl == null
                          ? const Icon(Icons.person)
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            invite.additionalInviters.isNotEmpty
                                ? '${invite.inviterName} e mais ${invite.additionalInviters.length} pessoas'
                                : '${invite.inviterName} te convidou',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (invite.additionalInviters.isNotEmpty)
                            Text(
                              'te convidaram',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          Text(
                            'Bora nessa?',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: onDecline,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white),
                        ),
                        child: const Text('Agora não'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: onAccept,
                        style: FilledButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          foregroundColor: colorScheme.onPrimary,
                        ),
                        icon: const Icon(Icons.rocket_launch, size: 18),
                        label: const Text('Bora!'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
