import 'package:belluga_now/domain/invites/invite_model.dart';
import 'package:belluga_now/presentation/common/widgets/swipeable_card/swipeable_card.dart';
import 'package:belluga_now/presentation/tenant/schedule/screens/event_detail_screen/widgets/invite_deck_card.dart';
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
                child: InviteDeckCard(
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
            child: InviteDeckCard(
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
