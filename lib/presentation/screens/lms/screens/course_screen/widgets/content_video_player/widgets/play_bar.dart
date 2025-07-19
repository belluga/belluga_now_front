import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:belluga_now/presentation/screens/lms/screens/course_screen/controllers/course_screen_controller.dart';
import 'package:stream_value/core/stream_value_builder.dart';
import 'package:video_player/video_player.dart';

class PlayBar extends StatefulWidget {
  const PlayBar({super.key});

  @override
  State<PlayBar> createState() => _PlayBarState();
}

class _PlayBarState extends State<PlayBar> {
  @override
  Widget build(BuildContext context) {
    final _controller = GetIt.I.get<CourseScreenController>();

    return StreamValueBuilder(
      streamValue: _controller.contentVideoPlayerController.positionStreamValue,
      builder: (context, asyncSnapshot) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "${_controller.contentVideoPlayerController.videoPlayerController.value.position.inMinutes.remainder(60).toString().padLeft(2, '0')}:${_controller.contentVideoPlayerController.videoPlayerController.value.position.inSeconds.remainder(60).toString().padLeft(2, '0')}",
              style: TextTheme.of(context).labelSmall,
            ),
            SizedBox(width: 8),
            Expanded(
              child: VideoProgressIndicator(
                padding: EdgeInsets.symmetric(vertical: 16),
                _controller.contentVideoPlayerController.videoPlayerController,
                allowScrubbing: true,
              ),
            ),
            SizedBox(width: 8),
            Text(
              "${_controller.contentVideoPlayerController.videoPlayerController.value.duration.inMinutes.remainder(60).toString().padLeft(2, '0')}:${_controller.contentVideoPlayerController.videoPlayerController.value.duration.inSeconds.remainder(60).toString().padLeft(2, '0')}",
              style: TextTheme.of(context).labelSmall,
            ),
          ],
        );
      },
    );
  }
}
