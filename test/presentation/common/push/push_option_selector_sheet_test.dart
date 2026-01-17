import 'package:belluga_now/presentation/common/push/push_option_selector_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_handler/push_handler.dart';

void main() {
  testWidgets('CTA stays disabled until min selection is reached',
      (tester) async {
    final options = [
      OptionItem(value: 'a', label: 'A'),
      OptionItem(value: 'b', label: 'B'),
      OptionItem(value: 'c', label: 'C'),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: PushOptionSelectorSheet(
          title: 'Select',
          body: '',
          layout: 'list',
          gridColumns: 2,
          selectionMode: 'multi',
          options: options,
          minSelected: 2,
          maxSelected: 0,
          initialSelected: const [],
        ),
      ),
    );

    final buttonFinder = find.widgetWithText(ElevatedButton, 'Continuar');
    var button = tester.widget<ElevatedButton>(buttonFinder);
    expect(button.onPressed, isNull);

    await tester.tap(find.widgetWithText(CheckboxListTile, 'A'));
    await tester.pump();
    button = tester.widget<ElevatedButton>(buttonFinder);
    expect(button.onPressed, isNull);

    await tester.tap(find.widgetWithText(CheckboxListTile, 'B'));
    await tester.pump();
    button = tester.widget<ElevatedButton>(buttonFinder);
    expect(button.onPressed, isNotNull);
  });

  testWidgets('single selection replaces previous choice', (tester) async {
    final options = [
      OptionItem(value: 'a', label: 'A'),
      OptionItem(value: 'b', label: 'B'),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: PushOptionSelectorSheet(
          title: 'Select',
          body: '',
          layout: 'list',
          gridColumns: 2,
          selectionMode: 'single',
          options: options,
          minSelected: 0,
          maxSelected: 0,
          initialSelected: const [],
        ),
      ),
    );

    final buttonFinder = find.widgetWithText(ElevatedButton, 'Continuar');
    var button = tester.widget<ElevatedButton>(buttonFinder);
    expect(button.onPressed, isNull);

    await tester.tap(find.widgetWithText(CheckboxListTile, 'A'));
    await tester.pump();
    button = tester.widget<ElevatedButton>(buttonFinder);
    expect(button.onPressed, isNotNull);

    var firstTile = tester.widget<CheckboxListTile>(
      find.widgetWithText(CheckboxListTile, 'A'),
    );
    var secondTile = tester.widget<CheckboxListTile>(
      find.widgetWithText(CheckboxListTile, 'B'),
    );
    expect(firstTile.value, isTrue);
    expect(secondTile.value, isFalse);

    await tester.tap(find.widgetWithText(CheckboxListTile, 'B'));
    await tester.pump();

    firstTile = tester.widget<CheckboxListTile>(
      find.widgetWithText(CheckboxListTile, 'A'),
    );
    secondTile = tester.widget<CheckboxListTile>(
      find.widgetWithText(CheckboxListTile, 'B'),
    );
    expect(firstTile.value, isFalse);
    expect(secondTile.value, isTrue);
  });

  testWidgets('uses OptionItem.isSelected as initial selection', (tester) async {
    final options = [
      OptionItem(value: 'a', label: 'A'),
      OptionItem(value: 'b', label: 'B', isSelected: true),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: PushOptionSelectorSheet(
          title: 'Select',
          body: '',
          layout: 'list',
          gridColumns: 2,
          selectionMode: 'single',
          options: options,
          minSelected: 0,
          maxSelected: 0,
          initialSelected: const [],
        ),
      ),
    );

    var firstTile = tester.widget<CheckboxListTile>(
      find.widgetWithText(CheckboxListTile, 'A'),
    );
    var secondTile = tester.widget<CheckboxListTile>(
      find.widgetWithText(CheckboxListTile, 'B'),
    );
    expect(firstTile.value, isFalse);
    expect(secondTile.value, isTrue);
  });
}
