import 'dart:ui' show SemanticsAction;

import 'package:belluga_now/presentation/shared/widgets/immersive_detail_screen/tabs/immersive_section_subtitle.dart';
import 'package:belluga_now/presentation/shared/widgets/immersive_detail_screen/tabs/immersive_section_title.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('title owns hierarchy, divider, and opaque ordered actions', (
    tester,
  ) async {
    var taps = 0;
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ImmersiveSectionTitle(
            text: 'Galeria',
            showDivider: true,
            actions: [
              TextButton(
                onPressed: () => taps++,
                child: const Text('Primeira'),
              ),
              const Icon(Icons.chevron_right, semanticLabel: 'Segunda'),
            ],
          ),
        ),
      ),
    );

    final title = tester.widget<Text>(find.text('Galeria'));
    expect(title.style?.fontWeight, FontWeight.w800);
    expect(
      title.style?.color,
      Theme.of(
        tester.element(find.text('Galeria')),
      ).textTheme.headlineSmall?.color,
    );
    expect(
      tester.getSemantics(find.text('Galeria')),
      matchesSemantics(label: 'Galeria', isHeader: true),
    );
    final divider = find.byType(Divider);
    expect(divider, findsOneWidget);
    expect(
      tester.getSize(divider).width,
      tester.getSize(find.byType(Scaffold)).width,
    );
    expect(
      tester.getTopLeft(divider).dy,
      greaterThan(tester.getBottomLeft(find.text('Galeria')).dy),
    );
    expect(
      tester.getTopLeft(find.text('Primeira')).dx,
      lessThan(tester.getTopLeft(find.bySemanticsLabel('Segunda')).dx),
    );

    await tester.tap(find.text('Primeira'));
    expect(taps, 1);
    semantics.dispose();
  });

  testWidgets(
    'subtitle keeps inline divider and opaque actions without empty space',
    (tester) async {
      final semantics = tester.ensureSemantics();
      var taps = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                ImmersiveSectionSubtitle(
                  text: 'Outros endereços relacionados',
                  showDivider: true,
                ),
                ImmersiveSectionSubtitle(
                  key: const Key('subtitleWithoutActions'),
                  text: 'Próximos Eventos',
                ),
                ImmersiveSectionSubtitle(
                  key: const Key('subtitleWithEmptyActions'),
                  text: 'Próximos Eventos',
                  actions: [],
                ),
                ImmersiveSectionSubtitle(
                  text: 'Momentos especiais',
                  actions: [
                    IconButton(
                      key: const Key('firstSubtitleAction'),
                      tooltip: 'Primeira action',
                      onPressed: () => taps++,
                      icon: const Icon(Icons.add),
                    ),
                    const Icon(
                      Icons.chevron_right,
                      key: Key('secondSubtitleAction'),
                      semanticLabel: 'Segunda action',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

      final subtitle = tester.widget<Text>(
        find.text('Outros endereços relacionados'),
      );
      expect(subtitle.style?.fontWeight, FontWeight.w800);
      expect(
        tester.getSemantics(find.text('Outros endereços relacionados')),
        matchesSemantics(
          label: 'Outros endereços relacionados',
          isHeader: true,
        ),
      );
      final divider = find.byType(Divider);
      expect(divider, findsOneWidget);
      expect(
        tester.getTopLeft(divider).dx,
        greaterThan(
          tester.getTopRight(find.text('Outros endereços relacionados')).dx,
        ),
      );
      expect(
        tester.getSize(find.byKey(const Key('subtitleWithoutActions'))),
        tester.getSize(find.byKey(const Key('subtitleWithEmptyActions'))),
      );
      expect(
        tester.getTopLeft(find.byKey(const Key('firstSubtitleAction'))).dx,
        lessThan(
          tester.getTopLeft(find.byKey(const Key('secondSubtitleAction'))).dx,
        ),
      );
      final actionSemantics = tester
          .getSemantics(find.byKey(const Key('firstSubtitleAction')))
          .getSemanticsData();
      expect(actionSemantics.tooltip, 'Primeira action');
      expect(actionSemantics.hasAction(SemanticsAction.tap), isTrue);
      expect(actionSemantics.flagsCollection.isButton, isTrue);
      await tester.tap(find.byKey(const Key('firstSubtitleAction')));
      expect(taps, 1);
      expect(find.byType(Spacer), findsNothing);
      semantics.dispose();
    },
  );

  testWidgets('headings remain overflow-free at phone width and large text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(2)),
          child: child!,
        ),
        home: Scaffold(
          body: SingleChildScrollView(
            child: Column(
              children: [
                ImmersiveSectionTitle(
                  text: 'Um título suficientemente extenso para quebrar linha',
                  actions: [
                    TextButton(onPressed: () {}, child: const Text('Ver tudo')),
                    const Icon(Icons.chevron_right),
                  ],
                ),
                ImmersiveSectionSubtitle(
                  text: 'Um subtítulo suficientemente extenso',
                  actions: [
                    IconButton(onPressed: () {}, icon: const Icon(Icons.add)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    final title = tester.widget<Text>(find.textContaining('Um título'));
    final subtitle = tester.widget<Text>(find.textContaining('Um subtítulo'));
    final context = tester.element(find.textContaining('Um subtítulo'));
    expect(
      title.style?.fontSize,
      Theme.of(context).textTheme.headlineSmall?.fontSize,
    );
    expect(
      subtitle.style?.fontSize,
      Theme.of(context).textTheme.titleLarge?.fontSize,
    );
    expect(
      subtitle.style?.color,
      Theme.of(context).textTheme.titleLarge?.color,
    );
  });

  test('blank heading text is rejected', () {
    expect(() => ImmersiveSectionTitle(text: '   '), throwsAssertionError);
    expect(() => ImmersiveSectionSubtitle(text: '\n'), throwsAssertionError);
  });
}
