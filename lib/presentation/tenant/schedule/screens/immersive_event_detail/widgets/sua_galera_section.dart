import 'package:belluga_now/domain/schedule/friend_resume.dart';
import 'package:belluga_now/presentation/tenant/schedule/screens/immersive_event_detail/widgets/your_crew_widget.dart';
import 'package:flutter/material.dart';
import 'package:stream_value/core/stream_value.dart';
import 'package:stream_value/core/stream_value_builder.dart';

class SuaGaleraSection extends StatelessWidget {
  const SuaGaleraSection({
    required this.friendsGoingStream,
    super.key,
  });

  final StreamValue<List<EventFriendResume>> friendsGoingStream;

  @override
  Widget build(BuildContext context) {
    return StreamValueBuilder(
      streamValue: friendsGoingStream,
      builder: (context, friendsGoing) {
        return YourCrewWidget(friendsGoing: friendsGoing);
      },
    );
  }
}
