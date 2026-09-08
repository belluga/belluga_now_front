import 'package:event_tracker_handler/event_tracker_handler.dart';
import 'package:get_it/get_it.dart';

import '../gallery_youtube_player.dart';

abstract final class GalleryPlaybackTracker {
  static Future<void> begin(GalleryYoutubePlayer item) => _log(
    type: EventTrackerEvents.videoBegin,
    eventName: 'gallery_youtube_video_begin',
    data: _identity(item),
  );

  static Future<void> watchedTime(
    GalleryYoutubePlayer item, {
    required int watchedSeconds,
    required double endPositionSeconds,
    required String reason,
  }) => _log(
    type: EventTrackerEvents.videoWatchedTime,
    eventName: 'gallery_youtube_video_watched_time',
    data: <String, dynamic>{
      ..._identity(item),
      'watched_seconds': watchedSeconds,
      'end_position_seconds': endPositionSeconds,
      'reason': reason,
    },
  );

  static Future<void> finished(
    GalleryYoutubePlayer item, {
    required int watchedSeconds,
  }) => _log(
    type: EventTrackerEvents.videoFinished,
    eventName: 'gallery_youtube_video_finished',
    data: <String, dynamic>{
      ..._identity(item),
      'watched_seconds': watchedSeconds,
    },
  );

  static Map<String, dynamic> _identity(GalleryYoutubePlayer item) =>
      <String, dynamic>{
        'gallery_item_id': item.itemId,
        'youtube_video_id': item.youtubeVideoId,
      };

  static Future<void> _log({
    required EventTrackerEvents type,
    required String eventName,
    required Map<String, dynamic> data,
  }) async {
    if (!GetIt.I.isRegistered<EventTrackerRepositoryContract>()) {
      return;
    }
    try {
      await GetIt.I.get<EventTrackerRepositoryContract>().logEvent(
        type: type,
        data: EventTrackerData(eventName: eventName, customData: data),
      );
    } catch (_) {
      // Playback must remain usable when analytics delivery is unavailable.
    }
  }
}
