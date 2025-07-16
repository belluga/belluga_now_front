import 'dart:async';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value.dart';
import 'package:unifast_portal/domain/courses/course_item_model.dart';
import 'package:unifast_portal/presentation/screens/lms/screens/course_screen/widgets/content_video_player/controller/next_video_button_controller.dart';
import 'package:unifast_portal/presentation/screens/lms/screens/course_screen/widgets/content_video_player/enums/video_playing_status.dart';
import 'package:video_player/video_player.dart';

class ContentVideoPlayerController extends Disposable {
  bool alreadyStarted = false;

  VideoPlayerController? _videoPlayerController;
  VideoPlayerController get videoPlayerController {
    if (_videoPlayerController == null) {
      throw Exception('Video player controller is not initialized.');
    }
    return _videoPlayerController!;
  }

  bool get isInitialized => _videoPlayerController != null;

  Timer? _overlayHideTimer;

  final nextVideoController = NextVideoButtonController();

  final showOverlayArea = StreamValue<bool>(defaultValue: true);
  final currentCourseItemStreamValue = StreamValue<CourseItemModel?>();
  final isInitializedStreamValue = StreamValue<bool?>();
  final positionStreamValue = StreamValue<Duration?>(
    defaultValue: Duration.zero,
  );
  final playingStatusStreamValue = StreamValue<VideoPlayingStatus>(
    defaultValue: VideoPlayingStatus.buffering,
  );
  final videoWatchPercentage = StreamValue<double?>();

  Future<void> initializePlayer() async {
    final CourseItemModel? courseItem = currentCourseItemStreamValue.value;
    ;
    if (courseItem == null) {
      throw Exception('No course item available to initialize the player.');
    }

    final url = courseItem.content!.video!.url.value!;
    _videoPlayerController = VideoPlayerController.networkUrl(url);
    await videoPlayerController.initialize();

    isInitializedStreamValue.addValue(true);
    videoPlayerController.addListener(_listenVideoController);

    if (videoPlayerController.value.isPlaying) {
      resetOverlayTimer();
    }

    alreadyStarted = false;
  }

  void showOverlay() {
    if (!showOverlayArea.value) {
      showOverlayArea.addValue(true);
    }

    resetOverlayTimer();
  }

  void hideOverlay() {
    _overlayHideTimer?.cancel();
    showOverlayArea.addValue(false);
  }

  void resetOverlayTimer() {
    _overlayHideTimer?.cancel();
    _overlayHideTimer = Timer(const Duration(seconds: 3), () {
      if (videoPlayerController.value.isPlaying) {
        showOverlayArea.addValue(false);
      }
    });
  }

  void _listenVideoController() {
    final VideoPlayingStatus newStatus;
    if (videoPlayerController.value.isPlaying) {
      newStatus = VideoPlayingStatus.playing;
    } else if (videoPlayerController.value.isBuffering) {
      newStatus = VideoPlayingStatus.buffering;
    } else if (videoPlayerController.value.position ==
        videoPlayerController.value.duration) {
      newStatus = VideoPlayingStatus.ended;
    } else {
      newStatus = VideoPlayingStatus.paused;
    }

    if (playingStatusStreamValue.value != newStatus) {
      playingStatusStreamValue.addValue(newStatus);

      if (newStatus == VideoPlayingStatus.playing) {
        resetOverlayTimer();
      } else {
        _overlayHideTimer?.cancel();
        showOverlayArea.addValue(true);
      }
    }

    final position = videoPlayerController.value.position;
    final duration = videoPlayerController.value.duration;

    if (duration.inMilliseconds > 0) {
      final playedPercentage =
          position.inMilliseconds / duration.inMilliseconds;
      videoWatchPercentage.addValue(playedPercentage);
    }

    positionStreamValue.addValue(position);

    if (newStatus == VideoPlayingStatus.playing && !alreadyStarted) {
      alreadyStarted = true;
    }
  }

  Future<void> clearLesson() async {
    if (isInitialized) {
      videoPlayerController.removeListener(_listenVideoController);
      await videoPlayerController.dispose();
      _videoPlayerController = null;
    }
    // 1. Clean up the old controller's resources.

    _overlayHideTimer?.cancel();

    // 2. Reset all state streams to their default values.
    isInitializedStreamValue.addValue(null);
    playingStatusStreamValue.addValue(VideoPlayingStatus.buffering);
    positionStreamValue.addValue(Duration.zero);
    videoWatchPercentage.addValue(0.0);
    showOverlayArea.addValue(true);

    // 3. Clear the current course item.
    currentCourseItemStreamValue.addValue(null);
  }

  /// Changes the video to a new lesson, properly disposing of the old player.
  Future<void> changeLesson(CourseItemModel newLesson) async {
    currentCourseItemStreamValue.addValue(newLesson);
    await initializePlayer();
  }

  @override
  void onDispose() {
    _overlayHideTimer?.cancel();
    
    if (isInitialized) {
      videoPlayerController.removeListener(_listenVideoController);
      videoPlayerController.dispose();
      _videoPlayerController = null;
    }

    showOverlayArea.dispose();
    isInitializedStreamValue.dispose();
    positionStreamValue.dispose();
    playingStatusStreamValue.dispose();
    videoWatchPercentage.dispose();
  }
}
