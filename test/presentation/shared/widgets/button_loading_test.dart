import 'package:belluga_now/presentation/shared/widgets/button_loading.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('loading indicator keeps the resolved button foreground color',
      (tester) async {
    final theme = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF0057D8),
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Scaffold(
          body: Center(
            child: ButtonLoading(
              isLoading: true,
              label: 'Permitir localização',
              style: ElevatedButton.styleFrom(
                foregroundColor: theme.colorScheme.onPrimary,
              ),
            ),
          ),
        ),
      ),
    );

    final indicator =
        tester.widget<CircularProgressIndicator>(find.byType(CircularProgressIndicator));
    final label = tester.widget<Text>(find.text('Permitir localização'));

    expect(indicator.color, theme.colorScheme.onPrimary);
    expect(label.style?.color, theme.colorScheme.onPrimary);
  });
}
