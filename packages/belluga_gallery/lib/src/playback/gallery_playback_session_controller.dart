import '../gallery_youtube_player.dart';
import 'gallery_playback_tracker.dart';

typedef GalleryPlaybackClock = DateTime Function();

final class GalleryPlaybackSessionController {
  GalleryPlaybackSessionController({
    required this.item,
    GalleryPlaybackClock? now,
  }) : _now = now ?? DateTime.now;

  final GalleryYoutubePlayer item;
  final GalleryPlaybackClock _now;

  DateTime? _playingSince;
  Duration _watched = Duration.zero;
  bool _began = false;
  bool _terminated = false;
  bool _finished = false;

  int get watchedSeconds => _watched.inSeconds;

  Future<void> onPlaying() async {
    if (_terminated || _playingSince != null) {
      return;
    }
    _playingSince = _now();
    if (_began) {
      return;
    }
    _began = true;
    await GalleryPlaybackTracker.begin(item);
  }

  void onPaused() => _stopClock();

  Future<void> finish({
    required String reason,
    required double endPositionSeconds,
  }) async {
    if (_terminated) {
      return;
    }
    _stopClock();
    _terminated = true;
    if (watchedSeconds < 1) {
      return;
    }
    await GalleryPlaybackTracker.watchedTime(
      item,
      watchedSeconds: watchedSeconds,
      endPositionSeconds: endPositionSeconds,
      reason: reason,
    );
  }

  Future<void> onEnded({required double endPositionSeconds}) async {
    if (_finished) {
      return;
    }
    await finish(reason: 'finished', endPositionSeconds: endPositionSeconds);
    _finished = true;
    await GalleryPlaybackTracker.finished(item, watchedSeconds: watchedSeconds);
  }

  void _stopClock() {
    final startedAt = _playingSince;
    if (startedAt == null) {
      return;
    }
    final elapsed = _now().difference(startedAt);
    if (!elapsed.isNegative) {
      _watched += elapsed;
    }
    _playingSince = null;
  }
}
