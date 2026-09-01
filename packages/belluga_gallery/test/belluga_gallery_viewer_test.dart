import 'dart:ui' as ui;

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
    expect(find.text('Galeria'), findsOneWidget);
    expect(
      find.byKey(const Key('bellugaGalleryViewerSlideRow')),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel('Selecionar item 2 de 2'), findsOneWidget);
    expect(find.text('Anterior'), findsNothing);
    expect(find.text('Próximo'), findsNothing);
    expect(find.byType(YoutubePlayer), findsNothing);
    expect(find.byIcon(Icons.play_circle_fill), findsNWidgets(2));
  });

  testWidgets('dragging the main item synchronizes the selected thumbnail', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: BellugaGalleryViewer(
          items: <GalleryItem>[
            GalleryPhoto(itemId: 'first', imageUrl: ''),
            GalleryPhoto(itemId: 'second', imageUrl: ''),
          ],
        ),
      ),
    );

    await tester.drag(find.byType(PageView), const Offset(-500, 0));
    await tester.pumpAndSettle();

    expect(find.text('2/2'), findsOneWidget);
    expect(
      tester
          .getSemantics(find.bySemanticsLabel('Selecionar item 2 de 2'))
          .flagsCollection
          .isSelected,
      ui.Tristate.isTrue,
    );
  });
}
