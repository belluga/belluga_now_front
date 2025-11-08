import 'dart:async';

import 'package:belluga_now/domain/invites/invite_model.dart';
import 'package:belluga_now/presentation/tenant/invites/screens/invite_flow_screen/controllers/invite_flow_controller.dart';
import 'package:belluga_now/presentation/tenant/invites/screens/invite_flow_screen/widgets/invite_card.dart';
import 'package:card_stack_swiper/card_stack_swiper.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value_builder.dart';

class InviteDeck extends StatelessWidget {
  const InviteDeck({
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
    if (result is Future<bool>) {
      return result.then((approved) {
        if (approved) {
          final controller = GetIt.I.get<InviteFlowScreenController>();
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
      final controller = GetIt.I.get<InviteFlowScreenController>();
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
