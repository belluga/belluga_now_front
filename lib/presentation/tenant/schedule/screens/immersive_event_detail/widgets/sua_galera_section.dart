import 'package:belluga_now/domain/gamification/mission_resume.dart';
import 'package:belluga_now/domain/schedule/friend_resume.dart';
import 'package:belluga_now/presentation/tenant/schedule/screens/immersive_event_detail/widgets/mission_widget.dart';
import 'package:belluga_now/presentation/tenant/schedule/screens/immersive_event_detail/widgets/your_crew_widget.dart';
import 'package:flutter/material.dart';
import 'package:stream_value/core/stream_value.dart';
import 'package:stream_value/core/stream_value_builder.dart';

class SuaGaleraSection extends StatelessWidget {
  const SuaGaleraSection({
    required this.isConfirmedStream,
    required this.missionStream,
    required this.friendsGoingStream,
    super.key,
  });

  final StreamValue<bool> isConfirmedStream;
  final StreamValue<MissionResume?> missionStream;
  final StreamValue<List<EventFriendResume>> friendsGoingStream;

  @override
  Widget build(BuildContext context) {
    return StreamValueBuilder<bool>(
      streamValue: isConfirmedStream,
      builder: (context, isConfirmed) {
        if (!isConfirmed) {
          // For unconfirmed users, show empty state or CTA
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: Text(
                'Confirme sua presença para ver quem mais vai!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ),
          );
        }

        // Show crew + mission for confirmed users
        return StreamValueBuilder<MissionResume>(
          streamValue: missionStream,
          onNullWidget: const SizedBox.shrink(),
          builder: (context, mission) {
            return SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 100),
              child: Column(
                children: [
                  MissionWidget(mission: mission),
                  StreamValueBuilder(
                    streamValue: friendsGoingStream,
                    builder: (context, friendsGoing) {
                      return YourCrewWidget(friendsGoing: friendsGoing);
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
