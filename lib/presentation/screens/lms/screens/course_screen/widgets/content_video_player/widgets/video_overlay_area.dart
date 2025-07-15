import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value_builder.dart';
import 'package:unifast_portal/domain/courses/course_item_model.dart';
import 'package:unifast_portal/presentation/screens/lms/screens/course_screen/widgets/content_video_player/controller/content_video_player_controller.dart';
import 'package:unifast_portal/presentation/screens/lms/screens/course_screen/widgets/content_video_player/enums/video_playing_status.dart';
import 'package:unifast_portal/presentation/screens/lms/screens/course_screen/widgets/content_video_player/widgets/next_video_button.dart';
import 'package:unifast_portal/presentation/screens/lms/screens/course_screen/widgets/content_video_player/widgets/play_bar.dart';
import 'package:unifast_portal/presentation/screens/lms/screens/course_screen/widgets/content_video_player/widgets/play_button.dart';

class VideoOverlayArea extends StatefulWidget {
  final CourseItemModel courseItemModel;

  const VideoOverlayArea({super.key, required this.courseItemModel});

  @override
  State<VideoOverlayArea> createState() => _VideoOverlayAreaState();
}

class _VideoOverlayAreaState extends State<VideoOverlayArea> {
  final _controller = GetIt.I.get<ContentVideoPlayerController>();

  @override
  Widget build(BuildContext context) {
    return StreamValueBuilder(
      streamValue: _controller.showOverlayArea,
      builder: (context, showOverlay) {
        if (!showOverlay) {
          return GestureDetector(
            onTap: _overlayAction,
            child: SizedBox.expand(
              child: Container(
                color: Colors.transparent,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (widget.courseItemModel.next != null)
                          StreamValueBuilder<double?>(
                            streamValue: _controller.videoWatchPercentage,
                            builder: (context, percentage) {
                              return Padding(
                                padding: EdgeInsetsGeometry.only(right: 16),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    NextVideoButton(
                                      videoPercentage: percentage ?? 0.0,
                                      courseItem: widget.courseItemModel.next!,
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return GestureDetector(
          onTap: _overlayAction,
          child: Container(
            decoration: BoxDecoration(
              color: _controller.alreadyStarted
                  ? Colors.black54
                  : Colors.transparent,
              image: !_controller.alreadyStarted
                  ? DecorationImage(
                      image: NetworkImage(
                        widget.courseItemModel.thumb.thumbUri.toString(),
                      ),
                      fit: BoxFit.cover,
                      colorFilter: ColorFilter.mode(
                        Colors.black.withAlpha(150),
                        BlendMode.darken,
                      ),
                    )
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    BackButton(),
                    SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        widget.courseItemModel.title.valueFormated,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextTheme.of(context).titleMedium,
                      ),
                    ),
                    // IconButton(onPressed: () {}, icon: Icon(Icons.more_vert)),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        // IconButton(
                                        //   onPressed: _replay10Seconds,
                                        //   iconSize: 32,
                                        //   icon: Icon(Icons.replay_10),
                                        // ),
                                        // SizedBox(width: 4),
                                        PlayButton(onPressed: _action),
                                        // SizedBox(width: 4),
                                        // SizedBox.shrink()
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  if (widget.courseItemModel.next != null)
                                    StreamValueBuilder<double?>(
                                      streamValue:
                                          _controller.videoWatchPercentage,
                                      builder: (context, percentage) {
                                        return Padding(
                                          padding: EdgeInsetsGeometry.only(
                                            right: 16,
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.end,
                                            children: [
                                              NextVideoButton(
                                                videoPercentage:
                                                    percentage ?? 0.0,
                                                courseItem: widget
                                                    .courseItemModel
                                                    .next!,
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    PlayButton(size: 32, onPressed: _action),
                    Expanded(child: PlayBar()),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: () {},
                          icon: Icon(Icons.fullscreen),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _action() {
    final VideoPlayingStatus playingStatus =
        _controller.playingStatusStreamValue.value;

    switch (playingStatus) {
      case VideoPlayingStatus.playing:
        return _pause();
      case VideoPlayingStatus.paused:
      case VideoPlayingStatus.buffering:
        return _play();
      case VideoPlayingStatus.ended:
        return _rewindAndPlay();
    }
  }

  void _overlayAction() {
    if (_controller.showOverlayArea.value) {
      _action();
    } else {
      _controller.showOverlay();
    }
  }

  void _replay10Seconds() {
    _controller.videoPlayerController.seekTo(Duration(seconds: -10));
  }

  void _forward10Seconds() {
    _controller.videoPlayerController.seekTo(Duration(seconds: 10));
  }

  void _pause() {
    _controller.videoPlayerController.pause();
  }

  void _play() {
    _controller.videoPlayerController.play();
  }

  void _rewindAndPlay() {
    _controller.videoPlayerController.seekTo(Duration.zero);
    _controller.videoPlayerController.play();
  }
}
