import 'package:belluga_now/presentation/tenant_admin/shared/widgets/tenant_admin_confirmation_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('confirm action closes dialog and returns true', (tester) async {
    bool? result;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return FilledButton(
                onPressed: () async {
                  result = await showTenantAdminConfirmationDialog(
                    context: context,
                    title: 'Remove item',
                    message: 'Confirm remove?',
                    confirmLabel: 'Remove',
                  );
                },
                child: const Text('Open dialog'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open dialog'));
    await tester.pumpAndSettle();
    expect(find.text('Confirm remove?'), findsOneWidget);

    await tester.tap(find.text('Remove'));
    await tester.pumpAndSettle();

    expect(find.text('Confirm remove?'), findsNothing);
    expect(result, isTrue);
  });
}
