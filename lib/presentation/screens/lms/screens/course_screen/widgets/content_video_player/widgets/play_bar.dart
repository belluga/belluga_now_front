import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:unifast_portal/presentation/screens/lms/screens/course_screen/widgets/content_video_player/controller/content_video_player_controller.dart';
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
    final _controller = GetIt.I.get<ContentVideoPlayerController>();

    return StreamValueBuilder(
      streamValue: _controller.positionStreamValue,
      builder: (context, asyncSnapshot) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "${_controller.videoPlayerController.value.position.inMinutes.remainder(60).toString().padLeft(2, '0')}:${_controller.videoPlayerController.value.position.inSeconds.remainder(60).toString().padLeft(2, '0')}",
              style: TextTheme.of(context).labelSmall,
            ),
            SizedBox(width: 8),
            Expanded(
              child: VideoProgressIndicator(
                _controller.videoPlayerController,
                
                allowScrubbing: true,
              ),
            ),
            SizedBox(width: 8),
            Text(
              "${_controller.videoPlayerController.value.duration.inMinutes.remainder(60).toString().padLeft(2, '0')}:${_controller.videoPlayerController.value.duration.inSeconds.remainder(60).toString().padLeft(2, '0')}",
              style: TextTheme.of(context).labelSmall,
            ),
          ],
        );
      },
    );
  }
}
