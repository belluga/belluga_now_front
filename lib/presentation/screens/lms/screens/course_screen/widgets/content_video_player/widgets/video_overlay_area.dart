import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value_builder.dart';
import 'package:belluga_now/domain/courses/course_item_model.dart';
import 'package:belluga_now/presentation/screens/lms/screens/course_screen/controllers/course_screen_controller.dart';
import 'package:belluga_now/presentation/screens/lms/screens/course_screen/widgets/content_video_player/enums/video_playing_status.dart';
import 'package:belluga_now/presentation/screens/lms/screens/course_screen/widgets/content_video_player/widgets/next_video_button.dart';
import 'package:belluga_now/presentation/screens/lms/screens/course_screen/widgets/content_video_player/widgets/play_bar.dart';
import 'package:belluga_now/presentation/screens/lms/screens/course_screen/widgets/content_video_player/widgets/play_button.dart';

class VideoOverlayArea extends StatefulWidget {
  final CourseItemModel courseItemModel;

  const VideoOverlayArea({super.key, required this.courseItemModel});

  @override
  State<VideoOverlayArea> createState() => _VideoOverlayAreaState();
}

class _VideoOverlayAreaState extends State<VideoOverlayArea> {
  final _controller = GetIt.I.get<CourseScreenController>();

  @override
  Widget build(BuildContext context) {
    return StreamValueBuilder(
      streamValue: _controller.contentVideoPlayerController.showOverlayArea,
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
                            streamValue: _controller
                                .contentVideoPlayerController
                                .videoWatchPercentage,
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
          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  image:
                      !_controller
                          .contentVideoPlayerController
                          .alreadyStarted
                      ? DecorationImage(
                          image: NetworkImage(
                            widget.courseItemModel.thumb.thumbUri
                                .toString(),
                          ),
                          fit: BoxFit.cover,
                          colorFilter: ColorFilter.mode(
                            Colors.black.withAlpha(150),
                            BlendMode.darken,
                          ),
                        )
                      : null,
                ),
              ),
              Container(
                color: _controller.contentVideoPlayerController.alreadyStarted
                    ? Colors.black54
                    : Colors.transparent,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        BackButton(
                          onPressed: _backNavigation,
                        ),
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
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 16,
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
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
                                          streamValue: _controller
                                              .contentVideoPlayerController
                                              .videoWatchPercentage,
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
            ],
          ),
        );
      },
    );
  }

  void _action() {
    final VideoPlayingStatus playingStatus =
        _controller.contentVideoPlayerController.playingStatusStreamValue.value;

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
    if (_controller.contentVideoPlayerController.showOverlayArea.value) {
      _action();
    } else {
      _controller.contentVideoPlayerController.showOverlay();
    }
  }

  void _pause() {
    _controller.contentVideoPlayerController.videoPlayerController.pause();
  }

  void _play() {
    _controller.contentVideoPlayerController.videoPlayerController.play();
  }

  void _rewindAndPlay() {
    _controller.contentVideoPlayerController.videoPlayerController.seekTo(
      Duration.zero,
    );
    _controller.contentVideoPlayerController.videoPlayerController.play();
  }

  void _backNavigation() {
    if (_controller.parentExists) {
      return _navigateToParent();
    }

    return _pop();
  }

  void _navigateToParent() => _controller.backToParent();

  void _pop() => context.router.pop();
}
