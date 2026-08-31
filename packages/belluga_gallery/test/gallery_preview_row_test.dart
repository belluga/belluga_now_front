import 'package:belluga_gallery/belluga_gallery.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

void main() {
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

    await tester.tap(find.byKey(const Key('bellugaGalleryPreview_video')));
    expect(selectedIndex, 1);
  });
}
