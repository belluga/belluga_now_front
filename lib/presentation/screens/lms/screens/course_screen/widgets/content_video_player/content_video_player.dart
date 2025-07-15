import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value_builder.dart';
import 'package:unifast_portal/domain/courses/course_item_model.dart';
import 'package:unifast_portal/presentation/screens/lms/screens/course_screen/widgets/content_video_player/controller/content_video_player_controller.dart';
import 'package:flutter/material.dart';
import 'package:unifast_portal/presentation/screens/lms/screens/course_screen/widgets/content_video_player/widgets/video_overlay_area.dart';
import 'package:video_player/video_player.dart';

class ContentVideoPlayer extends StatefulWidget {
  final CourseItemModel courseItemModel;

  const ContentVideoPlayer({super.key, required this.courseItemModel});

  @override
  State<ContentVideoPlayer> createState() => _ContentVideoPlayerState();
}

class _ContentVideoPlayerState extends State<ContentVideoPlayer> {
  late ContentVideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = GetIt.I.registerSingleton(
      ContentVideoPlayerController(selectedItemModel: widget.courseItemModel),
    );
    _initializePlayer();
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Stack(
        children: [
          StreamValueBuilder<bool>(
            streamValue: _controller.isInitializedStreamValue,
            onNullWidget: Center(child: CircularProgressIndicator()),
            builder: (context, isInitialized) {
              return Stack(
                children: [
                  VideoPlayer(_controller.videoPlayerController),
                  SizedBox.expand(
                    child: VideoOverlayArea(
                      courseItemModel: widget.courseItemModel,
                    ),
                  ),
                ],
              );
              // return Chewie(controller: _controller.chewieController);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _initializePlayer() async {
    await _controller.initializePlayer();
  }

  @override
  void dispose() {
    super.dispose();
    GetIt.I.unregister<ContentVideoPlayerController>();
  }
}
