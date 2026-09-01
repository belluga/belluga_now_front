import 'dart:ui' as ui;

import 'package:belluga_gallery/belluga_gallery.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

void main() {
  tearDown(() {
    PaintingBinding.instance.imageCache
      ..clear()
      ..clearLiveImages();
  });

  testWidgets('preview row is horizontal and never creates a player', (
    tester,
  ) async {
    var selectedIndex = -1;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BellugaGalleryPreviewRow(
            items: const <GalleryItem>[
              GalleryPhoto(itemId: 'photo', imageUrl: 'photo-url'),
              GalleryYoutubePlayer(
                itemId: 'video',
                youtubeVideoId: 'dQw4w9WgXcQ',
              ),
            ],
            onItemSelected: (index) => selectedIndex = index,
          ),
        ),
      ),
    );

    expect(find.byType(ListView), findsOneWidget);
    expect(
      tester.widget<ListView>(find.byType(ListView)).scrollDirection,
      Axis.horizontal,
    );
    expect(find.byType(YoutubePlayer), findsNothing);
    final photoWidth = tester
        .getSize(find.byKey(const Key('bellugaGalleryPreview_photo')))
        .width;
    final videoWidth = tester
        .getSize(find.byKey(const Key('bellugaGalleryPreview_video')))
        .width;
    expect(videoWidth, photoWidth * 2 + 12);

    await tester.tap(find.byKey(const Key('bellugaGalleryPreview_video')));
    expect(selectedIndex, 1);
  });

  testWidgets('preview width follows the displayed image proportions', (
    tester,
  ) async {
    const horizontalPhotoUrl = 'https://images.test/horizontal-photo.jpg';
    const verticalVideoId = 'verticalVideo';
    const verticalVideoThumbnailUrl =
        'https://i.ytimg.com/vi/$verticalVideoId/hqdefault.jpg';
    await _cacheNetworkImage(horizontalPhotoUrl, width: 200, height: 100);
    await _cacheNetworkImage(
      verticalVideoThumbnailUrl,
      width: 100,
      height: 200,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BellugaGalleryPreviewRow(
            itemWidth: 100,
            items: const <GalleryItem>[
              GalleryPhoto(
                itemId: 'horizontal-photo',
                imageUrl: horizontalPhotoUrl,
              ),
              GalleryYoutubePlayer(
                itemId: 'vertical-video-thumb',
                youtubeVideoId: verticalVideoId,
              ),
            ],
            onItemSelected: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      tester
          .getSize(
            find.byKey(const Key('bellugaGalleryPreview_horizontal-photo')),
          )
          .width,
      212,
    );
    expect(
      tester
          .getSize(
            find.byKey(const Key('bellugaGalleryPreview_vertical-video-thumb')),
          )
          .width,
      100,
    );
    expect(find.byType(YoutubePlayer), findsNothing);
  });
}

Future<void> _cacheNetworkImage(
  String url, {
  required int width,
  required int height,
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  canvas.drawColor(Colors.blue, BlendMode.src);
  final image = await recorder.endRecording().toImage(width, height);
  PaintingBinding.instance.imageCache.putIfAbsent(
    NetworkImage(url),
    () => OneFrameImageStreamCompleter(
      Future<ImageInfo>.value(ImageInfo(image: image)),
    ),
  );
}
