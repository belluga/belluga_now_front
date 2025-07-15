import 'dart:async';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value.dart';
import 'package:unifast_portal/domain/courses/course_item_model.dart';
import 'package:unifast_portal/presentation/screens/lms/screens/course_screen/widgets/content_video_player/enums/video_playing_status.dart';
import 'package:video_player/video_player.dart';

class ContentVideoPlayerController extends Disposable{
  ContentVideoPlayerController({required this.selectedItemModel});

  final CourseItemModel selectedItemModel;

  bool alreadyStarted = false;

  late VideoPlayerController videoPlayerController;
  Timer? _overlayHideTimer;

  final showOverlayArea = StreamValue<bool>(defaultValue: true);
  final isInitializedStreamValue = StreamValue<bool?>();
  final positionStreamValue = StreamValue<Duration?>(
    defaultValue: Duration.zero,
  );
  final playingStatusStreamValue = StreamValue<VideoPlayingStatus>(
    defaultValue: VideoPlayingStatus.buffering,
  );
  final videoWatchPercentage = StreamValue<double?>();

  Future<void> initializePlayer() async {
    final url = selectedItemModel.content!.video!.url.value!;
    videoPlayerController = VideoPlayerController.networkUrl(url);
    await videoPlayerController.initialize();

    isInitializedStreamValue.addValue(true);
    videoPlayerController.addListener(_listenVideoController);

    if (videoPlayerController.value.isPlaying) {
      resetOverlayTimer();
    }
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

  @override
  void onDispose() {
    _overlayHideTimer?.cancel();
    videoPlayerController.removeListener(_listenVideoController);
    videoPlayerController.dispose();
    showOverlayArea.dispose();
    isInitializedStreamValue.dispose();
    positionStreamValue.dispose();
    playingStatusStreamValue.dispose();
    videoWatchPercentage.dispose();
  }
}
