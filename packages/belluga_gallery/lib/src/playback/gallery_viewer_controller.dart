import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../gallery_item.dart';
import '../gallery_youtube_player.dart';
import 'gallery_playback_session_controller.dart';

final class GalleryViewerController extends ChangeNotifier
    with WidgetsBindingObserver {
  GalleryViewerController({
    required List<GalleryItem> items,
    int initialIndex = 0,
  }) : items = List<GalleryItem>.unmodifiable(items),
       selectedIndex = items.isEmpty
           ? 0
           : initialIndex.clamp(0, items.length - 1),
       pageController = PageController(
         initialPage: items.isEmpty
             ? 0
             : initialIndex.clamp(0, items.length - 1),
       ) {
    WidgetsBinding.instance.addObserver(this);
  }

  final List<GalleryItem> items;
  final PageController pageController;
  int selectedIndex;

  YoutubePlayerController? youtubeController;
  GalleryPlaybackSessionController? _playbackSession;
  StreamSubscription<YoutubePlayerValue>? _youtubeSubscription;
  bool isActivating = false;
  bool playbackFailed = false;
  bool _disposed = false;

  GalleryItem? get selectedItem => items.isEmpty ? null : items[selectedIndex];

  Future<void> selectIndex(int index) async {
    if (index == selectedIndex || index < 0 || index >= items.length) {
      return;
    }
    selectedIndex = index;
    notifyListeners();
    await closePlayer(reason: 'item_changed');
  }

  Future<void> playSelected() async {
    final item = selectedItem;
    if (item is! GalleryYoutubePlayer || isActivating) {
      return;
    }
    isActivating = true;
    playbackFailed = false;
    notifyListeners();
    await closePlayer(reason: 'replacement');
    if (_disposed || selectedItem != item) {
      return;
    }

    final controller = YoutubePlayerController.fromVideoId(
      videoId: item.youtubeVideoId,
      autoPlay: true,
      params: const YoutubePlayerParams(
        showControls: true,
        showFullscreenButton: true,
        enableCaption: true,
      ),
    );
    youtubeController = controller;
    _playbackSession = GalleryPlaybackSessionController(item: item);
    _youtubeSubscription = controller.listen(_onYoutubeValue);
    isActivating = false;
    notifyListeners();
  }

  Future<void> closePlayer({required String reason}) async {
    final controller = youtubeController;
    final session = _playbackSession;
    final subscription = _youtubeSubscription;
    youtubeController = null;
    _playbackSession = null;
    _youtubeSubscription = null;
    isActivating = false;
    if (!_disposed) {
      notifyListeners();
    }
    await subscription?.cancel();
    if (controller == null) {
      return;
    }
    double position = 0;
    try {
      position = await controller.currentTime;
      await controller.pauseVideo();
    } catch (_) {
      // The IFrame can already be unavailable while the viewer is closing.
    }
    await session?.finish(reason: reason, endPositionSeconds: position);
    await controller.close();
  }

  Future<void> _onYoutubeValue(YoutubePlayerValue value) async {
    if (value.hasError) {
      playbackFailed = true;
      notifyListeners();
      await closePlayer(reason: 'player_error_${value.error.code}');
      return;
    }
    switch (value.playerState) {
      case PlayerState.playing:
        await _playbackSession?.onPlaying();
      case PlayerState.paused:
      case PlayerState.buffering:
        _playbackSession?.onPaused();
      case PlayerState.ended:
        final controller = youtubeController;
        final position = controller == null
            ? 0.0
            : await controller.currentTime;
        await _playbackSession?.onEnded(endPositionSeconds: position);
      default:
        break;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      unawaited(closePlayer(reason: 'app_backgrounded'));
    }
  }

  @override
  void dispose() {
    _disposed = true;
    WidgetsBinding.instance.removeObserver(this);
    pageController.dispose();
    unawaited(closePlayer(reason: 'viewer_closed'));
    super.dispose();
  }
}
