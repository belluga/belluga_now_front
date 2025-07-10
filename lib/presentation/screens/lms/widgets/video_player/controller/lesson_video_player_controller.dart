import 'package:chewie/chewie.dart';
import 'package:stream_value/core/stream_value.dart';
import 'package:unifast_portal/domain/courses/course_item_model.dart';
import 'package:video_player/video_player.dart';

class LessonVideoPlayerController {
  LessonVideoPlayerController({required this.selectedItemModel});

  final CourseItemModel selectedItemModel;

  late VideoPlayerController videoPlayerController;
  late ChewieController chewieController;

  Future<void> initializePlayer() async {
    final url = selectedItemModel.content!.video!.url.value!;
    videoPlayerController = VideoPlayerController.networkUrl(url);
    await videoPlayerController.initialize();
    
    chewieController = ChewieController(
      videoPlayerController: videoPlayerController,
      aspectRatio: 16 / 9,
      autoInitialize: true,
    );

    isInitializedStreamValue.addValue(true);
    videoPlayerController.addListener(_listenVideoController);
  }

  final isInitializedStreamValue = StreamValue<bool>(defaultValue: false);

  final isPlayingStreamValue = StreamValue<bool>(defaultValue: false);

  void _listenVideoController() {
    isPlayingStreamValue.addValue(videoPlayerController.value.isPlaying);
    final bool _isPlaying = videoPlayerController.value.isPlaying;
    if (_isPlaying != isPlayingStreamValue.value) {
      isPlayingStreamValue.addValue(_isPlaying);
    }
  }

  void dispose() {
    chewieController.dispose();
    videoPlayerController.dispose();
  }
}
