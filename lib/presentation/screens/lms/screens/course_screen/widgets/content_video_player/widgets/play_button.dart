import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value_builder.dart';
import 'package:unifast_portal/presentation/screens/lms/screens/course_screen/controllers/course_screen_controller.dart';
import 'package:unifast_portal/presentation/screens/lms/screens/course_screen/widgets/content_video_player/enums/video_playing_status.dart';

class PlayButton extends StatefulWidget {
  final double size;
  final void Function() onPressed;

  const PlayButton({
    super.key,
    this.size = 56,
    required this.onPressed,
  });

  @override
  State<PlayButton> createState() => _PlayButtonState();
}

class _PlayButtonState extends State<PlayButton> {
  final _controller = GetIt.I.get<CourseScreenController>();

  @override
  Widget build(BuildContext context) {
    return StreamValueBuilder<VideoPlayingStatus>(
      streamValue: _controller.contentVideoPlayerController.playingStatusStreamValue,
      builder: (context, playingStatus) {
        final IconData _icon = _getIconData();
        return IconButton(
          onPressed: widget.onPressed,
          iconSize: widget.size,
          icon: Icon(_icon),
        );
      },
    );
  }

  IconData _getIconData() {
    final VideoPlayingStatus playingStatus =
        _controller.contentVideoPlayerController.playingStatusStreamValue.value;

    switch (playingStatus) {
      case VideoPlayingStatus.playing:
        return Icons.pause;
      case VideoPlayingStatus.paused:
        return Icons.play_arrow;
      case VideoPlayingStatus.buffering:
        return Icons.play_arrow;
      case VideoPlayingStatus.ended:
        return Icons.replay;
    }
  }
}
