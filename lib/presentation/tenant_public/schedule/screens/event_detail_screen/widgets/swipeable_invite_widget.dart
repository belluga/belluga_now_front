import 'package:belluga_now/domain/invites/invite_model.dart';
import 'package:belluga_now/presentation/shared/widgets/swipeable_card/swipeable_card.dart';
import 'package:belluga_now/presentation/tenant_public/schedule/screens/event_detail_screen/controllers/event_detail_controller.dart';
import 'package:belluga_now/presentation/tenant_public/schedule/screens/event_detail_screen/widgets/invite_deck_card.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value_builder.dart';

class SwipeableInviteWidget extends StatefulWidget {
  const SwipeableInviteWidget({
    super.key,
    this.controller,
    required this.invites,
    required this.onAccept,
    required this.onDecline,
  });

  final EventDetailController? controller;
  final List<InviteModel> invites;
  final Future<void> Function(String) onAccept;
  final Future<void> Function(String) onDecline;

  @override
  State<SwipeableInviteWidget> createState() => _SwipeableInviteWidgetState();
}

class _SwipeableInviteWidgetState extends State<SwipeableInviteWidget> {
  EventDetailController get _controller =>
      widget.controller ?? GetIt.I.get<EventDetailController>();

  @override
  Widget build(BuildContext context) {
    return StreamValueBuilder<int>(
      streamValue: _controller.inviteDeckIndexStreamValue,
      builder: (context, index) {
        if (widget.invites.isEmpty || index >= widget.invites.length) {
          return const SizedBox.shrink();
        }

        final currentInvite = widget.invites[index];
        final nextInvite =
            index + 1 < widget.invites.length ? widget.invites[index + 1] : null;

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
                  _controller.setInviteDeckIndex(index + 1);
                },
                onSwipeLeft: () async {
                  await widget.onDecline(currentInvite.id);
                  _controller.setInviteDeckIndex(index + 1);
                },
                child: InviteDeckCard(
                  invite: currentInvite,
                  onAccept: () async {
                    // Manual button press
                    await widget.onAccept(currentInvite.id);
                    _controller.setInviteDeckIndex(index + 1);
                  },
                  onDecline: () async {
                    // Manual button press
                    await widget.onDecline(currentInvite.id);
                    _controller.setInviteDeckIndex(index + 1);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
