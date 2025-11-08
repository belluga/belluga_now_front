import 'package:belluga_now/domain/invites/invite_model.dart';
import 'package:belluga_now/presentation/tenant/invites/screens/invite_flow_screen/widgets/invite_card.dart';
import 'package:card_stack_swiper/card_stack_swiper.dart';
import 'package:flutter/material.dart';
import 'package:stream_value/core/stream_value.dart';
import 'package:stream_value/core/stream_value_builder.dart';

class InviteDeck extends StatelessWidget {
  const InviteDeck({
    super.key,
    required this.invites,
    required this.onSwipe,
    required this.swiperController,
    required this.topCardIndexStreamValue,
  });

  final List<InviteModel> invites;
  final CardStackSwiperOnSwipe onSwipe;
  final CardStackSwiperController swiperController;
  final StreamValue<int> topCardIndexStreamValue;

  @override
  Widget build(BuildContext context) {
    return StreamValueBuilder<int>(
      streamValue: topCardIndexStreamValue,
      builder: (_, topIndex) {
        return CardStackSwiper(
          controller: swiperController,
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
          onSwipe: onSwipe,
        );
      },
    );
  }
}
