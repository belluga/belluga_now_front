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
              title: 'Um minuto na praia',
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
    expect(
      find.descendant(
        of: find.byKey(const Key('bellugaGalleryViewerMetadata')),
        matching: find.text('VÍDEO'),
      ),
      findsOneWidget,
    );
    expect(find.text('Um minuto na praia'), findsOneWidget);
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

  testWidgets('viewer omits the metadata block when item text is empty', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: BellugaGalleryViewer(
          items: <GalleryItem>[GalleryPhoto(itemId: 'photo', imageUrl: '')],
        ),
      ),
    );

    expect(find.byKey(const Key('bellugaGalleryViewerMetadata')), findsNothing);
    expect(
      find.byKey(const Key('bellugaGalleryViewerDescription')),
      findsNothing,
    );
  });

  for (final scenario
      in <
        ({
          String name,
          String? title,
          String? description,
          Key presentKey,
          Key absentKey,
        })
      >[
        (
          name: 'title only',
          title: 'Um minuto na praia',
          description: null,
          presentKey: const Key('bellugaGalleryViewerItemTitle'),
          absentKey: const Key('bellugaGalleryViewerDescription'),
        ),
        (
          name: 'description only',
          title: null,
          description: 'Vídeo selecionado',
          presentKey: const Key('bellugaGalleryViewerDescription'),
          absentKey: const Key('bellugaGalleryViewerItemTitle'),
        ),
      ]) {
    testWidgets('viewer renders metadata with ${scenario.name}', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: BellugaGalleryViewer(
            items: <GalleryItem>[
              GalleryPhoto(
                itemId: 'photo',
                imageUrl: '',
                title: scenario.title,
                description: scenario.description,
              ),
            ],
          ),
        ),
      );

      expect(
        find.byKey(const Key('bellugaGalleryViewerMetadata')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('bellugaGalleryViewerItemType')),
        findsOneWidget,
      );
      expect(find.byKey(scenario.presentKey), findsOneWidget);
      expect(find.byKey(scenario.absentKey), findsNothing);
    });
  }

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

  testWidgets('vertical YouTube preview fills the available viewer height', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 820));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      const MaterialApp(
        home: BellugaGalleryViewer(
          items: <GalleryItem>[
            GalleryYoutubePlayer(
              itemId: 'video',
              youtubeVideoId: '69ePBThnsVg',
              playerAspectRatio: 113 / 200,
            ),
          ],
        ),
      ),
    );

    final previewSize = tester.getSize(
      find.byKey(const Key('bellugaGalleryViewerYoutubePreview_video')),
    );
    expect(previewSize.height, greaterThan(400));
    expect(previewSize.height, greaterThan(previewSize.width));
  });

  testWidgets('viewer surface inherits the ambient generated color scheme', (
    tester,
  ) async {
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF00695C),
      brightness: Brightness.light,
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(colorScheme: scheme),
        home: const BellugaGalleryViewer(
          items: <GalleryItem>[GalleryPhoto(itemId: 'photo', imageUrl: '')],
        ),
      ),
    );

    final viewerMaterial = tester.widget<Material>(
      find
          .descendant(
            of: find.byType(BellugaGalleryViewer),
            matching: find.byType(Material),
          )
          .first,
    );
    expect(viewerMaterial.color, scheme.surface);
  });
}
