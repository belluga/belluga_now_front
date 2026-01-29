import 'package:belluga_now/domain/invites/invite_model.dart';
import 'package:belluga_now/presentation/common/widgets/swipeable_card/swipeable_card.dart';
import 'package:belluga_now/application/icons/boora_icons.dart';
import 'package:flutter/material.dart';

class SwipeableInviteWidget extends StatefulWidget {
  const SwipeableInviteWidget({
    super.key,
    required this.invites,
    required this.onAccept,
    required this.onDecline,
  });

  final List<InviteModel> invites;
  final Future<void> Function(String) onAccept;
  final Future<void> Function(String) onDecline;

  @override
  State<SwipeableInviteWidget> createState() => _SwipeableInviteWidgetState();
}

class _SwipeableInviteWidgetState extends State<SwipeableInviteWidget> {
  int _currentIndex = 0;

  void _handleNext() {
    if (_currentIndex < widget.invites.length - 1) {
      setState(() {
        _currentIndex++;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.invites.isEmpty || _currentIndex >= widget.invites.length) {
      return const SizedBox.shrink();
    }

    final currentInvite = widget.invites[_currentIndex];
    final nextInvite = _currentIndex + 1 < widget.invites.length
        ? widget.invites[_currentIndex + 1]
        : null;

    return SizedBox(
      height: 180,
      child: Stack(
        children: [
          if (nextInvite != null)
            Positioned.fill(
              child: Transform.scale(
                scale: 0.95,
                child: _InviteDeckCard(
                  invite: nextInvite,
                  onAccept: () {}, // Background card actions disabled
                  onDecline: () {},
                ),
              ),
            ),
          SwipeableCard(
            key: ValueKey(currentInvite.id),
            onSwipeRight: () async {
              await widget.onAccept(currentInvite.id);
              _handleNext();
            },
            onSwipeLeft: () async {
              await widget.onDecline(currentInvite.id);
              _handleNext();
            },
            child: _InviteDeckCard(
              invite: currentInvite,
              onAccept: () async {
                // Manual button press
                await widget.onAccept(currentInvite.id);
                _handleNext();
              },
              onDecline: () async {
                // Manual button press
                await widget.onDecline(currentInvite.id);
                _handleNext();
              },
            ),
          ),
        ],
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
                        icon: const Icon(BooraIcons.invite_solid, size: 18),
                        label: const Text('Bóora!'),
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
