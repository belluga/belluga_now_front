import 'package:belluga_gallery/belluga_gallery.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

void main() {
  testWidgets('viewer starts at the requested item without autoplay', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: BellugaGalleryViewer(
          initialIndex: 1,
          items: <GalleryItem>[
            GalleryPhoto(itemId: 'photo', imageUrl: ''),
            GalleryYoutubePlayer(
              itemId: 'video',
              description: 'Vídeo selecionado',
              youtubeVideoId: 'dQw4w9WgXcQ',
            ),
          ],
        ),
      ),
    );

    expect(find.text('2/2'), findsOneWidget);
    expect(find.bySemanticsLabel('Item 2 de 2'), findsOneWidget);
    expect(
      find.bySemanticsLabel('Descrição: Vídeo selecionado'),
      findsOneWidget,
    );
    expect(find.byTooltip('Fechar galeria'), findsOneWidget);
    expect(find.byType(YoutubePlayer), findsNothing);
    expect(find.byIcon(Icons.play_circle_fill), findsOneWidget);
  });
}
