import 'package:chewie/chewie.dart';
import 'package:stream_value/core/stream_value_builder.dart';
import 'package:unifast_portal/domain/courses/course_item_model.dart';
import 'package:unifast_portal/presentation/screens/lms/widgets/video_player/controller/lesson_video_player_controller.dart';
import 'package:flutter/material.dart';

class LessonVideoPlayer extends StatefulWidget {
  final CourseItemModel courseItemModel;

  const LessonVideoPlayer({super.key, required this.courseItemModel});

  @override
  State<LessonVideoPlayer> createState() => _LessonVideoPlayerState();
}

class _LessonVideoPlayerState extends State<LessonVideoPlayer> {
  late LessonVideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = LessonVideoPlayerController(
      selectedItemModel: widget.courseItemModel,
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
            builder: (context, isInitialized) {
              print("isInitialized: $isInitialized");
              if (!isInitialized) {
                print("circular");
                return Center(child: CircularProgressIndicator());
              }
              // return Center(child: CircularProgressIndicator());

              return Chewie(controller: _controller.chewieController);
            },
          ),
          // Chewie(controller: _controller.chewieController),
          StreamValueBuilder(
            streamValue: _controller.isPlayingStreamValue,
            builder: (context, isPlaying) {
              if (isPlaying) {
                return SizedBox.shrink();
              }

              return Column(
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
                    ],
                  ),
                ],
              );
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
    _controller.dispose();
  }
}
