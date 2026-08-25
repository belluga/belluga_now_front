import 'dart:async';

import 'package:belluga_now/presentation/shared/widgets/controllers/public_rich_text_link_controller.dart';
import 'package:belluga_now/presentation/shared/widgets/public_rich_text_html.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  for (final tapCount in <int>[5, 10, 20]) {
    test(
      'controller drops $tapCount rapid taps while one launch is active',
      () async {
        final gate = Completer<bool>();
        var calls = 0;
        final controller = PublicRichTextLinkController(
          launcher: (uri, {required mode, required webOnlyWindowName}) {
            calls++;
            return gate.future;
          },
        );

        final launches = List<Future<void>>.generate(
          tapCount,
          (_) => controller.launch('https://example.test/path?a=1&b=2'),
        );
        expect(calls, 1);
        expect(controller.isLaunching, isTrue);
        gate.complete(true);
        await Future.wait(launches);
        expect(controller.isLaunching, isFalse);
        controller.dispose();
      },
    );
  }

  test(
    'controller emits false/throw failures and suppresses effects after disposal',
    () async {
      final pending = Completer<bool>();
      var calls = 0;
      final controller = PublicRichTextLinkController(
        launcher: (uri, {required mode, required webOnlyWindowName}) {
          calls++;
          if (calls == 1) return Future<bool>.value(false);
          if (calls == 2) throw StateError('platform failure');
          return pending.future;
        },
      );
      var failures = 0;
      final subscription = controller.failureEffects.listen((_) => failures++);

      await controller.launch('https://example.test/false');
      await controller.launch('https://example.test/throw');
      expect(failures, 2);
      final pendingLaunch = controller.launch('https://example.test/pending');
      controller.dispose();
      pending.complete(false);
      await pendingLaunch;
      expect(failures, 2);
      await subscription.cancel();
    },
  );

  testWidgets(
    'uses readable local light and dark theme primary links and allows caller override',
    (tester) async {
      Future<({Style anchor, Color surface})> pumpWith({
        required ColorScheme scheme,
        Map<String, Style>? style,
      }) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(
              useMaterial3: true,
              colorScheme: scheme,
              scaffoldBackgroundColor: scheme.surface,
            ),
            home: Scaffold(
              body: PublicRichTextHtml(
                html: '<p><a href="https://example.test">Abrir</a></p>',
                style: style,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        return (
          anchor: tester.widget<Html>(find.byType(Html)).style['a']!,
          surface: Theme.of(
            tester.element(find.byType(PublicRichTextHtml)),
          ).colorScheme.surface,
        );
      }

      for (final brightness in Brightness.values) {
        final scheme = ColorScheme.fromSeed(
          seedColor: const Color(0xFF006B5F),
          brightness: brightness,
        );
        final rendered = await pumpWith(scheme: scheme);
        expect(rendered.anchor.color, scheme.primary);
        expect(rendered.anchor.textDecoration, TextDecoration.underline);
        expect(rendered.anchor.textDecorationColor, scheme.primary);
        expect(
          _contrastRatio(rendered.anchor.color!, rendered.surface),
          greaterThanOrEqualTo(4.5),
          reason: '$brightness link must meet WCAG AA against local surface',
        );
      }

      final lowContrast =
          ColorScheme.fromSeed(seedColor: const Color(0xFF777777)).copyWith(
            primary: const Color(0xFFF4F4F4),
            surface: const Color(0xFFF4F4F4),
            onSurface: const Color(0xFF111111),
          );
      final resolved = await pumpWith(scheme: lowContrast);
      expect(resolved.anchor.color, isNot(lowContrast.primary));
      expect(resolved.anchor.textDecoration, TextDecoration.underline);
      expect(
        _contrastRatio(resolved.anchor.color!, resolved.surface),
        greaterThanOrEqualTo(4.5),
      );

      final override = Style(
        color: const Color(0xFFB3261E),
        textDecoration: TextDecoration.none,
      );
      final overridden = await pumpWith(
        scheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF8A1C7C),
          brightness: Brightness.light,
        ),
        style: <String, Style>{'a': override},
      );
      expect(overridden.anchor, same(override));
    },
  );

  testWidgets('uses external mode and _blank, dropping rapid duplicate taps', (
    tester,
  ) async {
    final gate = Completer<bool>();
    var calls = 0;
    Uri? launchedUri;
    LaunchMode? modeValue;
    String? window;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PublicRichTextHtml(
            html:
                '<p><a href="HTTPS://example.test/path?a=1&amp;b=2">Abrir</a></p>',
            launcher:
                (
                  uri, {
                  required LaunchMode mode,
                  required String webOnlyWindowName,
                }) {
                  calls++;
                  launchedUri = uri;
                  modeValue = mode;
                  window = webOnlyWindowName;
                  return gate.future;
                },
          ),
        ),
      ),
    );
    await _tapRichText(tester, 'Abrir');
    await _tapRichText(tester, 'Abrir');
    expect(calls, 1);
    expect(launchedUri, Uri.parse('https://example.test/path?a=1&b=2'));
    expect(launchedUri?.query, 'a=1&b=2');
    expect(modeValue, LaunchMode.externalApplication);
    expect(window, '_blank');
    gate.complete(true);
    await tester.pump();
  });

  testWidgets('keeps one-in-flight launch state isolated per renderer', (
    tester,
  ) async {
    final firstGate = Completer<bool>();
    final secondGate = Completer<bool>();
    var firstCalls = 0;
    var secondCalls = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              PublicRichTextHtml(
                html:
                    '<p><a href="https://example.test/first">Primeiro</a></p>',
                launcher: (uri, {required mode, required webOnlyWindowName}) {
                  firstCalls++;
                  return firstGate.future;
                },
              ),
              PublicRichTextHtml(
                html:
                    '<p><a href="https://example.test/second">Segundo</a></p>',
                launcher: (uri, {required mode, required webOnlyWindowName}) {
                  secondCalls++;
                  return secondGate.future;
                },
              ),
            ],
          ),
        ),
      ),
    );

    await _tapRichText(tester, 'Primeiro');
    await _tapRichText(tester, 'Primeiro');
    await _tapRichText(tester, 'Segundo');
    expect(firstCalls, 1);
    expect(secondCalls, 1);
    firstGate.complete(true);
    secondGate.complete(true);
    await tester.pump();
  });

  testWidgets('shows failure feedback and never launches default-denied links', (
    tester,
  ) async {
    var calls = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PublicRichTextHtml(
            html:
                '<p><a href="javascript:alert(1)">Negado</a></p><p><a href="https://example.test">Falhar</a></p>',
            launcher: (uri, {required mode, required webOnlyWindowName}) {
              calls++;
              return Future.value(false);
            },
          ),
        ),
      ),
    );
    expect(_richText('Negado'), findsOneWidget);
    await _tapRichText(tester, 'Negado');
    await _tapRichText(tester, 'Falhar');
    await tester.pump();
    expect(calls, 1);
    expect(find.text('Não foi possível abrir o link.'), findsOneWidget);
  });

  testWidgets('shows failure feedback when the launcher throws', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PublicRichTextHtml(
            html: '<p><a href="https://example.test">Falhar</a></p>',
            launcher: (uri, {required mode, required webOnlyWindowName}) {
              throw StateError('platform failure');
            },
          ),
        ),
      ),
    );

    await _tapRichText(tester, 'Falhar');
    await tester.pump();
    expect(find.text('Não foi possível abrir o link.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('ignores failed completion after disposal', (tester) async {
    final gate = Completer<bool>();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PublicRichTextHtml(
            html: '<p><a href="https://example.test">link</a></p>',
            launcher: (uri, {required mode, required webOnlyWindowName}) =>
                gate.future,
          ),
        ),
      ),
    );
    await _tapRichText(tester, 'link');
    await tester.pumpWidget(const SizedBox.shrink());
    gate.complete(false);
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('reports a pending failure through the current messenger', (
    tester,
  ) async {
    final gate = Completer<bool>();
    final rendererKey = GlobalKey();
    final firstMessengerKey = GlobalKey<ScaffoldMessengerState>();
    final secondMessengerKey = GlobalKey<ScaffoldMessengerState>();
    Future<bool> launcher(
      Uri uri, {
      required LaunchMode mode,
      required String webOnlyWindowName,
    }) => gate.future;

    Widget buildApp({required bool useSecondMessenger}) => MaterialApp(
      home: Row(
        children: [
          Expanded(
            child: ScaffoldMessenger(
              key: firstMessengerKey,
              child: Scaffold(
                body: useSecondMessenger
                    ? const SizedBox.shrink()
                    : PublicRichTextHtml(
                        key: rendererKey,
                        html: '<p><a href="https://example.test">link</a></p>',
                        launcher: launcher,
                      ),
              ),
            ),
          ),
          Expanded(
            child: ScaffoldMessenger(
              key: secondMessengerKey,
              child: Scaffold(
                body: useSecondMessenger
                    ? PublicRichTextHtml(
                        key: rendererKey,
                        html: '<p><a href="https://example.test">link</a></p>',
                        launcher: launcher,
                      )
                    : const SizedBox.shrink(),
              ),
            ),
          ),
        ],
      ),
    );

    await tester.pumpWidget(buildApp(useSecondMessenger: false));
    await _tapRichText(tester, 'link');
    await tester.pumpWidget(buildApp(useSecondMessenger: true));
    gate.complete(false);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(
      find.descendant(
        of: find.byKey(secondMessengerKey),
        matching: find.text('Não foi possível abrir o link.'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(firstMessengerKey),
        matching: find.text('Não foi possível abrir o link.'),
      ),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('plain text has no launch callback', (tester) async {
    var calls = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PublicRichTextHtml(
            html: '<p>https://example.test/plain</p>',
            launcher: (uri, {required mode, required webOnlyWindowName}) async {
              calls++;
              return true;
            },
          ),
        ),
      ),
    );

    await _tapRichText(tester, 'https://example.test/plain');
    await tester.pump();
    expect(calls, 0);
  });
}

Finder _richText(String text) => find.byWidgetPredicate(
  (widget) => widget is RichText && widget.text.toPlainText() == text,
  description: 'RichText with exact text "$text"',
);

Future<void> _tapRichText(WidgetTester tester, String text) async {
  final finder = _richText(text);
  final paragraph = tester.renderObject<RenderParagraph>(finder);
  final boxes = paragraph.getBoxesForSelection(
    TextSelection(baseOffset: 0, extentOffset: text.length),
  );
  expect(boxes, isNotEmpty, reason: 'Expected rendered glyph box for "$text"');
  await tester.tapAt(paragraph.localToGlobal(boxes.first.toRect().center));
  await tester.pump();
}

double _contrastRatio(Color foreground, Color background) {
  final foregroundLuminance = foreground.computeLuminance();
  final backgroundLuminance = background.computeLuminance();
  final lighter = foregroundLuminance > backgroundLuminance
      ? foregroundLuminance
      : backgroundLuminance;
  final darker = foregroundLuminance > backgroundLuminance
      ? backgroundLuminance
      : foregroundLuminance;
  return (lighter + 0.05) / (darker + 0.05);
}
