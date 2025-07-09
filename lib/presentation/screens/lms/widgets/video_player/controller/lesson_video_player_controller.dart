import 'package:chewie/chewie.dart';
import 'package:unifast_portal/domain/courses/course_item_model.dart';
import 'package:video_player/video_player.dart';

class LessonVideoPlayerController {
  LessonVideoPlayerController({required this.selectedItemModel});

  final CourseItemModel selectedItemModel;

  late VideoPlayerController videoPlayerController;
  late ChewieController chewieController;

  void initializePlayer() {
    final url = selectedItemModel.content!.video!.url.value!;
    videoPlayerController = VideoPlayerController.networkUrl(url);
  }

  void dispose() {
    print("dispose controller");
    chewieController.dispose();
    videoPlayerController.dispose();
  }
}
