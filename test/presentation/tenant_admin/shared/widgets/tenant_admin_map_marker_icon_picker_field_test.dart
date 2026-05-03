import 'package:belluga_now/presentation/shared/icons/map_marker_icon_catalog.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/widgets/tenant_admin_map_marker_icon_picker_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('icon picker lists every Boora font icon', (tester) async {
    final controller = TextEditingController(text: 'place');
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TenantAdminMapMarkerIconPickerField(
            controller: controller,
            labelText: 'Ícone',
          ),
        ),
      ),
    );

    await tester.tap(find.byTooltip('Selecionar ícone'));
    await tester.pumpAndSettle();

    expect(find.byType(FilterChip),
        findsNWidgets(MapMarkerIconToken.values.length));
    expect(find.text('Local'), findsWidgets);
    expect(find.text('Cinema'), findsOneWidget);
    expect(find.text('Promoção'), findsOneWidget);
    expect(find.text('Quiosque'), findsOneWidget);
    expect(find.text('Sorvete'), findsOneWidget);
    expect(find.text('Primeiros socorros'), findsOneWidget);
    expect(find.text('Ingresso alternativo'), findsOneWidget);
    expect(find.text('Convite'), findsOneWidget);
    expect(find.text('Convite alternativo'), findsOneWidget);
    expect(find.text('Confirmado'), findsOneWidget);

    for (final token in MapMarkerIconToken.values) {
      final chip = tester.widget<FilterChip>(
        find.widgetWithText(FilterChip, token.label),
      );
      expect(
        chip.showCheckmark,
        isFalse,
        reason: 'Selection must not replace the ${token.storageKey} glyph.',
      );
      expect(
        chip.label,
        isA<Row>()
            .having(
              (row) => row.children.whereType<Icon>().single.icon,
              'embedded icon',
              token.iconData,
            )
            .having(
              (row) => row.children.whereType<Text>().single.data,
              'label text',
              token.label,
            ),
      );
    }
  });
}
