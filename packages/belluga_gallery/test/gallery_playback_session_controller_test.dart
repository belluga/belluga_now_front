import 'package:belluga_gallery/belluga_gallery.dart';
import 'package:event_tracker_handler/event_tracker_handler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

void main() {
  late _RecordingTracker tracker;
  late DateTime now;

  setUp(() async {
    await GetIt.I.reset();
    tracker = _RecordingTracker();
    GetIt.I.registerSingleton<EventTrackerRepositoryContract>(tracker);
    now = DateTime.utc(2026, 8, 31, 12);
  });

  tearDown(GetIt.I.reset);

  test('tracks begin once and terminal watched time once', () async {
    final controller = GalleryPlaybackSessionController(
      item: const GalleryYoutubePlayer(
        itemId: 'video-1',
        youtubeVideoId: 'dQw4w9WgXcQ',
      ),
      now: () => now,
    );

    await controller.onPlaying();
    await controller.onPlaying();
    now = now.add(const Duration(seconds: 3));
    await controller.finish(reason: 'viewer_closed', endPositionSeconds: 8);
    await controller.finish(reason: 'viewer_closed', endPositionSeconds: 8);

    expect(tracker.events.map((entry) => entry.type), <EventTrackerEvents>[
      EventTrackerEvents.videoBegin,
      EventTrackerEvents.videoWatchedTime,
    ]);
    expect(tracker.events.last.data?.customData?['watched_seconds'], 3);
    expect(tracker.events.last.data?.customData?['reason'], 'viewer_closed');
  });

  test(
    'ended emits watched time before finished and deduplicates finish',
    () async {
      final controller = GalleryPlaybackSessionController(
        item: const GalleryYoutubePlayer(
          itemId: 'video-1',
          youtubeVideoId: 'dQw4w9WgXcQ',
        ),
        now: () => now,
      );

      await controller.onPlaying();
      now = now.add(const Duration(seconds: 2));
      await controller.onEnded(endPositionSeconds: 12);
      await controller.onEnded(endPositionSeconds: 12);

      expect(tracker.events.map((entry) => entry.type), <EventTrackerEvents>[
        EventTrackerEvents.videoBegin,
        EventTrackerEvents.videoWatchedTime,
        EventTrackerEvents.videoFinished,
      ]);
    },
  );
}

final class _RecordingTracker extends EventTrackerRepositoryContract {
  final List<({EventTrackerEvents type, EventTrackerData? data})> events = [];

  @override
  EventTrackerHandler get handler => throw UnimplementedError();

  @override
  Future<EventTrackerUserData> getUserData() async =>
      EventTrackerUserData(uuid: 'test-user');

  @override
  Future<void> init() async {}

  @override
  Future<List<EventTrackerDeliveryOutcome>> logEvent({
    required EventTrackerEvents type,
    EventTrackerUserData? userDataCustom,
    EventTrackerData? data,
  }) async {
    events.add((type: type, data: data));
    return const <EventTrackerDeliveryOutcome>[];
  }
}
