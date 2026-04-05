import 'dart:async';
import 'dart:typed_data';

import 'package:belluga_now/presentation/shared/widgets/image_palette_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
      'applies fallback scheme first and updates when derived theme resolves',
      (tester) async {
    final completer = Completer<ColorScheme>();
    final fallback = ColorScheme.fromSeed(
      seedColor: Colors.blue,
      brightness: Brightness.light,
    );
    final derived = ColorScheme.fromSeed(
      seedColor: Colors.deepOrange,
      brightness: Brightness.light,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: ImagePaletteTheme(
          imageProvider: MemoryImage(Uint8List.fromList(<int>[0])),
          fallbackScheme: fallback,
          schemeResolver: ({
            required imageProvider,
            required fallbackScheme,
          }) =>
              completer.future,
          builder: (context, scheme) => _ColorProbe(
            primary: Theme.of(context).colorScheme.primary,
            secondary: scheme.secondary,
          ),
        ),
      ),
    );

    expect(_textValue(tester, _ColorProbe.primaryKey),
        'primary:${fallback.primary.toARGB32()}');
    expect(_textValue(tester, _ColorProbe.secondaryKey),
        'secondary:${fallback.secondary.toARGB32()}');

    completer.complete(derived);
    await tester.pump();

    expect(_textValue(tester, _ColorProbe.primaryKey),
        'primary:${derived.primary.toARGB32()}');
    expect(_textValue(tester, _ColorProbe.secondaryKey),
        'secondary:${derived.secondary.toARGB32()}');
  });

  testWidgets('keeps fallback scheme when derived theme resolution throws',
      (tester) async {
    final fallback = ColorScheme.fromSeed(
      seedColor: Colors.blue,
      brightness: Brightness.dark,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: ImagePaletteTheme(
          imageProvider: MemoryImage(Uint8List.fromList(<int>[0])),
          fallbackScheme: fallback,
          schemeResolver: ({
            required imageProvider,
            required fallbackScheme,
          }) async {
            throw StateError('palette failure');
          },
          builder: (context, scheme) => _ColorProbe(
            primary: Theme.of(context).colorScheme.primary,
            secondary: scheme.secondary,
          ),
        ),
      ),
    );

    await tester.pump();

    expect(_textValue(tester, _ColorProbe.primaryKey),
        'primary:${fallback.primary.toARGB32()}');
    expect(_textValue(tester, _ColorProbe.secondaryKey),
        'secondary:${fallback.secondary.toARGB32()}');
  });

  testWidgets(
      'updates scaffold background to match the resolved scheme surface',
      (tester) async {
    final completer = Completer<ColorScheme>();
    final fallback = ColorScheme.fromSeed(
      seedColor: Colors.blue,
      brightness: Brightness.dark,
    );
    final derived = ColorScheme.fromSeed(
      seedColor: Colors.amber,
      brightness: Brightness.dark,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: ImagePaletteTheme(
          imageProvider: MemoryImage(Uint8List.fromList(<int>[0])),
          fallbackScheme: fallback,
          schemeResolver: ({
            required imageProvider,
            required fallbackScheme,
          }) =>
              completer.future,
          builder: (context, scheme) => Scaffold(
            body: _ColorProbe(
              primary: Theme.of(context).colorScheme.primary,
              secondary: scheme.secondary,
              scaffoldBackground: Theme.of(context).scaffoldBackgroundColor,
            ),
          ),
        ),
      ),
    );

    expect(
      _textValue(tester, _ColorProbe.scaffoldBackgroundKey),
      'scaffold:${fallback.surface.toARGB32()}',
    );

    completer.complete(derived);
    await tester.pump();

    expect(
      _textValue(tester, _ColorProbe.scaffoldBackgroundKey),
      'scaffold:${derived.surface.toARGB32()}',
    );
  });
}

String _textValue(WidgetTester tester, Key key) {
  final text = tester.widget<Text>(find.byKey(key));
  return text.data ?? '';
}

class _ColorProbe extends StatelessWidget {
  const _ColorProbe({
    required this.primary,
    required this.secondary,
    this.scaffoldBackground,
  });

  final Color primary;
  final Color secondary;
  final Color? scaffoldBackground;

  static const primaryKey = ValueKey<String>('image_palette_theme_primary');
  static const secondaryKey = ValueKey<String>('image_palette_theme_secondary');
  static const scaffoldBackgroundKey =
      ValueKey<String>('image_palette_theme_scaffold_background');

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('primary:${primary.toARGB32()}', key: primaryKey),
        Text('secondary:${secondary.toARGB32()}', key: secondaryKey),
        Text(
          'scaffold:${(scaffoldBackground ?? Colors.transparent).toARGB32()}',
          key: scaffoldBackgroundKey,
        ),
      ],
    );
  }
}
