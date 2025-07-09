import 'package:chewie/chewie.dart';
import 'package:flutter_laravel_backend_boilerplate/domain/courses/course_item_model.dart';
import 'package:flutter_laravel_backend_boilerplate/presentation/common/widgets/image_with_progress_indicator.dart';
import 'package:flutter_laravel_backend_boilerplate/presentation/screens/lms/widgets/video_player/controller/lesson_video_player_controller.dart';
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
          Chewie(controller: _controller.chewieController),
          Column(
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
          ),
        ],
      ),
    );
  }

  void _initializePlayer() {
    _controller.initializePlayer();
    _controller.chewieController = ChewieController(
      overlay: SizedBox.expand(
        child: ImageWithProgressIndicator(
          thumb: widget.courseItemModel.thumb,
        ),
      ),

      videoPlayerController: _controller.videoPlayerController,
      aspectRatio: 16 / 9,
      autoInitialize: true,
    );
  }

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
  }
}
